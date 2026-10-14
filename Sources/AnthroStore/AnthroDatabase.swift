import Foundation
import SQLite3

private let transientDestructor = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

/// Conexão SQLite do app (design D2, D4 e D4b). Usada só pela thread principal.
public final class AnthroDatabase: @unchecked Sendable {
    public let url: URL
    private var handle: OpaquePointer?
    private var depth = 0

    private init(handle: OpaquePointer, url: URL) {
        self.handle = handle
        self.url = url
    }

    deinit {
        close()
    }

    /// `~/Library/Application Support/AnthroPlus`.
    public static func defaultDirectory() -> URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("AnthroPlus", isDirectory: true)
    }

    /// Abre (ou cria) o banco, ativa `foreign_keys` e WAL, confere a integridade e aplica as migrações pendentes.
    /// Arquivo que não é banco SQLite ou que falha no `integrity_check` lança `StoreError.corrupted`.
    public static func open(at url: URL, migrations: [Migration] = Migrations.all) throws -> AnthroDatabase {
        var raw: OpaquePointer?
        let code = sqlite3_open_v2(url.path, &raw, SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE, nil)
        guard code == SQLITE_OK, let raw else {
            let message = raw.map { String(cString: sqlite3_errmsg($0)) } ?? "sqlite3_open_v2 falhou"
            sqlite3_close_v2(raw)
            throw StoreError.sqlite(code: code, message: message)
        }
        sqlite3_busy_timeout(raw, 2000)
        let database = AnthroDatabase(handle: raw, url: url)
        do {
            try database.executeScript("PRAGMA foreign_keys = ON; PRAGMA journal_mode = WAL;")
            guard try database.integrityCheck() else {
                throw StoreError.corrupted(details: "integrity_check não devolveu ok")
            }
            try database.migrate(migrations)
        } catch let StoreError.sqlite(code, message) where Self.isCorruption(code) {
            database.close()
            throw StoreError.corrupted(details: message)
        } catch {
            database.close()
            throw error
        }
        return database
    }

    public func schemaVersion() throws -> Int {
        guard case .integer(let version) = try firstValue("PRAGMA user_version") else { return 0 }
        return Int(version)
    }

    /// Executa uma única instrução com parâmetros posicionais (`?`).
    public func execute(_ sql: String, _ params: [SQLValue] = []) throws {
        let statement = try prepare(sql, params)
        defer { sqlite3_finalize(statement) }
        while true {
            let code = sqlite3_step(statement)
            if code == SQLITE_DONE { return }
            if code != SQLITE_ROW { throw lastError(code) }
        }
    }

    public func query(_ sql: String, _ params: [SQLValue] = []) throws -> [Row] {
        let statement = try prepare(sql, params)
        defer { sqlite3_finalize(statement) }
        var rows: [Row] = []
        while true {
            let code = sqlite3_step(statement)
            if code == SQLITE_DONE { return rows }
            guard code == SQLITE_ROW else { throw lastError(code) }
            var values: [String: SQLValue] = [:]
            for index in 0..<sqlite3_column_count(statement) {
                values[String(cString: sqlite3_column_name(statement, index))] = Self.columnValue(statement, index)
            }
            rows.append(Row(values: values))
        }
    }

    public func lastInsertRowID() -> Int64 {
        sqlite3_last_insert_rowid(handle)
    }

    /// Transação reentrante (design D4b): a externa usa `BEGIN IMMEDIATE`/`COMMIT`; cada aninhada, um `SAVEPOINT`.
    /// Erro desfaz só o trecho do nível em que ocorreu e é propagado.
    public func transaction<T>(_ body: () throws -> T) throws -> T {
        let level = depth
        try executeScript(level == 0 ? "BEGIN IMMEDIATE" : "SAVEPOINT sp_\(level)")
        depth += 1
        let result: T
        do {
            result = try body()
        } catch {
            depth -= 1
            rollback(level: level)
            throw error
        }
        depth -= 1
        do {
            try executeScript(level == 0 ? "COMMIT" : "RELEASE sp_\(level)")
        } catch {
            rollback(level: level)
            throw error
        }
        return result
    }

    private func rollback(level: Int) {
        try? executeScript(level == 0 ? "ROLLBACK" : "ROLLBACK TO sp_\(level); RELEASE sp_\(level)")
    }

    /// Nível de aninhamento atual: 0 fora de transação, 1 na externa, 2 na primeira aninhada.
    public var transactionDepth: Int {
        depth
    }

    public func integrityCheck() throws -> Bool {
        try firstValue("PRAGMA integrity_check") == .text("ok")
    }

    /// Valor do pragma como texto (`"1"`, `"wal"`), ou `nil` se o pragma não devolve linha.
    public func pragma(_ name: String) throws -> String? {
        switch try firstValue("PRAGMA \(name)") {
        case .integer(let value): String(value)
        case .real(let value): String(value)
        case .text(let value): value
        case .null, .blob, nil: nil
        }
    }

    /// Cópia consistente pela API de backup online do SQLite, incluindo o que ainda está no WAL.
    public func backup(to url: URL) throws {
        guard let handle else { throw StoreError.sqlite(code: SQLITE_MISUSE, message: "banco fechado") }
        try Self.copy(from: handle, to: url)
    }

    public func close() {
        guard let handle else { return }
        sqlite3_close_v2(handle)
        self.handle = nil
    }

    // MARK: Uso interno do módulo

    /// Copia um arquivo de banco sem aplicar pragmas nem migrações, abrindo a origem só para leitura.
    static func backupFile(at source: URL, to destination: URL) throws {
        var raw: OpaquePointer?
        let code = sqlite3_open_v2(source.path, &raw, SQLITE_OPEN_READONLY, nil)
        defer { sqlite3_close_v2(raw) }
        guard code == SQLITE_OK, let raw else {
            throw StoreError.sqlite(code: code, message: raw.map { String(cString: sqlite3_errmsg($0)) } ?? "falha ao abrir")
        }
        try copy(from: raw, to: destination)
    }

    /// Executa SQL com várias instruções (usado por pragmas e migrações).
    func executeScript(_ sql: String) throws {
        var errorMessage: UnsafeMutablePointer<CChar>?
        let code = sqlite3_exec(handle, sql, nil, nil, &errorMessage)
        guard code == SQLITE_OK else {
            let message = errorMessage.map { String(cString: $0) } ?? String(cString: sqlite3_errmsg(handle))
            sqlite3_free(errorMessage)
            throw StoreError.sqlite(code: code, message: message)
        }
    }

    static func isCorruption(_ code: Int32) -> Bool {
        let primary = code & 0xFF
        return primary == SQLITE_NOTADB || primary == SQLITE_CORRUPT
    }

    // MARK: Privado

    private static func copy(from source: OpaquePointer, to destination: URL) throws {
        var target: OpaquePointer?
        let openCode = sqlite3_open_v2(destination.path, &target, SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE, nil)
        defer { sqlite3_close_v2(target) }
        guard openCode == SQLITE_OK, let target else {
            throw StoreError.sqlite(code: openCode, message: "falha ao criar \(destination.lastPathComponent)")
        }
        guard let backup = sqlite3_backup_init(target, "main", source, "main") else {
            throw StoreError.sqlite(code: sqlite3_errcode(target), message: String(cString: sqlite3_errmsg(target)))
        }
        let stepCode = sqlite3_backup_step(backup, -1)
        sqlite3_backup_finish(backup)
        guard stepCode == SQLITE_DONE else {
            throw StoreError.sqlite(code: stepCode, message: String(cString: sqlite3_errmsg(target)))
        }
    }

    private func prepare(_ sql: String, _ params: [SQLValue]) throws -> OpaquePointer {
        guard let handle else { throw StoreError.sqlite(code: SQLITE_MISUSE, message: "banco fechado") }
        var statement: OpaquePointer?
        let code = sqlite3_prepare_v2(handle, sql, -1, &statement, nil)
        guard code == SQLITE_OK, let statement else { throw lastError(code) }
        for (offset, value) in params.enumerated() {
            let index = Int32(offset + 1)
            let bindCode: Int32
            switch value {
            case .null: bindCode = sqlite3_bind_null(statement, index)
            case .integer(let number): bindCode = sqlite3_bind_int64(statement, index, number)
            case .real(let number): bindCode = sqlite3_bind_double(statement, index, number)
            case .text(let text): bindCode = sqlite3_bind_text(statement, index, text, -1, transientDestructor)
            case .blob(let data):
                bindCode = data.withUnsafeBytes {
                    sqlite3_bind_blob(statement, index, $0.baseAddress, Int32($0.count), transientDestructor)
                }
            }
            guard bindCode == SQLITE_OK else {
                sqlite3_finalize(statement)
                throw lastError(bindCode)
            }
        }
        return statement
    }

    private func firstValue(_ sql: String) throws -> SQLValue? {
        let statement = try prepare(sql, [])
        defer { sqlite3_finalize(statement) }
        let code = sqlite3_step(statement)
        if code == SQLITE_DONE { return nil }
        guard code == SQLITE_ROW else { throw lastError(code) }
        return Self.columnValue(statement, 0)
    }

    private static func columnValue(_ statement: OpaquePointer, _ index: Int32) -> SQLValue {
        switch sqlite3_column_type(statement, index) {
        case SQLITE_INTEGER: return .integer(sqlite3_column_int64(statement, index))
        case SQLITE_FLOAT: return .real(sqlite3_column_double(statement, index))
        case SQLITE_TEXT: return .text(String(cString: sqlite3_column_text(statement, index)))
        case SQLITE_BLOB:
            let count = Int(sqlite3_column_bytes(statement, index))
            guard count > 0, let bytes = sqlite3_column_blob(statement, index) else { return .blob(Data()) }
            return .blob(Data(bytes: bytes, count: count))
        default: return .null
        }
    }

    private func lastError(_ code: Int32) -> StoreError {
        .sqlite(code: code, message: handle.map { String(cString: sqlite3_errmsg($0)) } ?? "banco fechado")
    }
}
