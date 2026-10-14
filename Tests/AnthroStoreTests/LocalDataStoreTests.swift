import AnthroStore
import Foundation
import Testing

/// Testes de cenário da capability local-data-store (change bootstrap-macos-app).
@MainActor
@Suite("local-data-store")
struct LocalDataStoreTests {
    private struct Boom: Error {}

    private let fm = FileManager.default

    /// Diretório temporário novo, ainda não criado.
    private func freshRoot() -> URL {
        fm.temporaryDirectory
            .appendingPathComponent("anthro-tests", isDirectory: true)
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
    }

    private func createdRoot() throws -> URL {
        let root = freshRoot()
        try fm.createDirectory(at: root, withIntermediateDirectories: true)
        return root
    }

    private func utc(_ iso: String) -> Date {
        ISO8601DateFormatter().date(from: iso)!
    }

    /// Só a migração 1 (`app_meta`), para que os testes não dependam das migrações das changes seguintes.
    private var baseMigrations: [Migration] {
        Migrations.all.filter { $0.version == 1 }
    }

    /// Cria um banco válido com a linha `probe` em `app_meta`.
    private func makeDatabase(at url: URL, probe: String) throws {
        let db = try AnthroDatabase.open(at: url, migrations: baseMigrations)
        try db.execute("INSERT OR REPLACE INTO app_meta(key, value) VALUES (?, ?)", [.text("probe"), .text(probe)])
        db.close()
    }

    private func probe(in db: AnthroDatabase) throws -> SQLValue {
        try db.query("SELECT value FROM app_meta WHERE key = ?", [.text("probe")]).first?["value"] ?? .null
    }

    private func junk() -> Data {
        Data(repeating: 0xAB, count: 8192)
    }

    private func names(in db: AnthroDatabase) throws -> [SQLValue] {
        try db.query("SELECT name FROM t ORDER BY name").map { $0["name"] }
    }

    private func count(_ db: AnthroDatabase, name: String) throws -> Int64 {
        let value = try db.query("SELECT count(*) AS n FROM t WHERE name = ?", [.text(name)]).first?["n"]
        if case .integer(let n) = value { return n }
        return -1
    }

    // MARK: Local do banco de dados

    // Scenario: Primeira abertura cria diretório e banco
    @Test func primeiraAberturaCriaDiretorioEBanco() throws {
        #expect(AnthroDatabase.defaultDirectory().path.hasSuffix("Library/Application Support/AnthroPlus"))

        let dir = freshRoot().appendingPathComponent("AnthroPlus", isDirectory: true)
        defer { try? fm.removeItem(at: dir.deletingLastPathComponent()) }
        let store = StoreController(directory: dir)
        store.openOnLaunch()
        #expect(store.state == .ready)
        #expect(fm.fileExists(atPath: dir.appendingPathComponent("anthroplus.sqlite").path))
    }

    // Scenario: Diretório sem permissão de escrita
    @Test func diretorioSemPermissaoFalha() throws {
        let parent = try createdRoot()
        try fm.setAttributes([.posixPermissions: 0o555], ofItemAtPath: parent.path)
        defer {
            try? fm.setAttributes([.posixPermissions: 0o755], ofItemAtPath: parent.path)
            try? fm.removeItem(at: parent)
        }
        let dir = parent.appendingPathComponent("AnthroPlus", isDirectory: true)
        let store = StoreController(directory: dir)
        store.openOnLaunch()
        guard case .failed(let message) = store.state else {
            Issue.record("expected state .failed, got \(store.state)")
            return
        }
        #expect(!message.isEmpty)
        #expect(!fm.fileExists(atPath: dir.path))
    }

    // MARK: Migrações versionadas

    // Scenario: Banco novo chega à última versão
    @Test func bancoNovoChegaAUltimaVersao() throws {
        let root = try createdRoot()
        defer { try? fm.removeItem(at: root) }
        let second = Migration(version: 2, name: "teste", sql: "CREATE TABLE t2(x INTEGER);")
        let db = try AnthroDatabase.open(at: root.appendingPathComponent("a.sqlite"), migrations: baseMigrations + [second])
        defer { db.close() }
        #expect(try db.schemaVersion() == 2)
        #expect(try db.query("SELECT name FROM sqlite_master WHERE type = 'table' AND name = 'app_meta'").count == 1)
    }

    // Scenario: Migração com defeito
    @Test func migracaoComDefeitoFazRollback() throws {
        let root = try createdRoot()
        defer { try? fm.removeItem(at: root) }
        let url = root.appendingPathComponent("a.sqlite")
        try AnthroDatabase.open(at: url, migrations: baseMigrations).close()

        let broken = Migration(version: 2, name: "defeito", sql: "CREATE TABLE criada_antes(x INTEGER); ISTO NAO E SQL;")
        do {
            let db = try AnthroDatabase.open(at: url, migrations: baseMigrations + [broken])
            db.close()
            Issue.record("expected StoreError.migrationFailed(version: 2, ...), got no error")
        } catch let error as StoreError {
            guard case .migrationFailed(let version, _) = error else {
                Issue.record("expected .migrationFailed, got \(error)")
                return
            }
            #expect(version == 2)
        }

        let reopened = try AnthroDatabase.open(at: url, migrations: baseMigrations)
        defer { reopened.close() }
        #expect(try reopened.schemaVersion() == 1)
        #expect(try reopened.query("SELECT name FROM sqlite_master WHERE name = 'criada_antes'").isEmpty)
    }

    // MARK: Integridade ao abrir

    // Scenario: Pragmas ativos
    @Test func pragmasDeChaveEstrangeiraEWal() throws {
        let root = try createdRoot()
        defer { try? fm.removeItem(at: root) }
        let db = try AnthroDatabase.open(at: root.appendingPathComponent("a.sqlite"))
        defer { db.close() }
        #expect(try db.pragma("foreign_keys") == "1")
        #expect(try db.pragma("journal_mode") == "wal")
    }

    // Scenario: Arquivo corrompido
    @Test func arquivoCorrompidoNaoESobrescrito() throws {
        let dir = try createdRoot()
        defer { try? fm.removeItem(at: dir) }
        let dbURL = dir.appendingPathComponent("anthroplus.sqlite")
        try junk().write(to: dbURL)

        let store = StoreController(directory: dir)
        store.openOnLaunch()
        guard case .corrupted = store.state else {
            Issue.record("expected state .corrupted, got \(store.state)")
            return
        }
        #expect(try Data(contentsOf: dbURL) == junk())
    }

    // MARK: Backup automático ao abrir

    // Scenario: Backup com nome datado
    @Test func backupComNomeDatado() throws {
        let dir = try createdRoot()
        defer { try? fm.removeItem(at: dir) }
        let dbURL = dir.appendingPathComponent("anthroplus.sqlite")
        try makeDatabase(at: dbURL, probe: "42")
        let backups = dir.appendingPathComponent("Backups", isDirectory: true)

        let result = try BackupManager.backupOnLaunch(
            databaseURL: dbURL, backupsDirectory: backups, keep: 10, now: utc("2026-10-14T10:30:05Z")
        )
        #expect(result?.lastPathComponent == "anthroplus-20261014-103005.sqlite")

        let copy = try AnthroDatabase.open(at: backups.appendingPathComponent("anthroplus-20261014-103005.sqlite"), migrations: [])
        defer { copy.close() }
        #expect(try probe(in: copy) == .text("42"))
    }

    // Scenario: Rotação dos backups
    @Test func rotacaoMantemDezBackups() throws {
        let dir = try createdRoot()
        defer { try? fm.removeItem(at: dir) }
        let dbURL = dir.appendingPathComponent("anthroplus.sqlite")
        try makeDatabase(at: dbURL, probe: "atual")
        let backups = dir.appendingPathComponent("Backups", isDirectory: true)
        try fm.createDirectory(at: backups, withIntermediateDirectories: true)
        // A rotação decide pelo nome; o conteúdo dos backups antigos não é aberto.
        for day in 1...10 {
            let name = String(format: "anthroplus-202610%02d-000000.sqlite", day)
            try Data("backup antigo \(day)".utf8).write(to: backups.appendingPathComponent(name))
        }

        _ = try BackupManager.backupOnLaunch(
            databaseURL: dbURL, backupsDirectory: backups, keep: 10, now: utc("2026-10-14T10:30:05Z")
        )
        let names = BackupManager.backups(in: backups).map(\.lastPathComponent)
        #expect(names.count == 10)
        #expect(!names.contains("anthroplus-20261001-000000.sqlite"))
        #expect(names.contains("anthroplus-20261002-000000.sqlite"))
        #expect(names.contains("anthroplus-20261014-103005.sqlite"))
    }

    // Scenario: Primeira abertura sem banco
    @Test func primeiraAberturaSemBancoNaoFazBackup() throws {
        let dir = try createdRoot()
        defer { try? fm.removeItem(at: dir) }
        let backups = dir.appendingPathComponent("Backups", isDirectory: true)
        let result = try BackupManager.backupOnLaunch(
            databaseURL: dir.appendingPathComponent("anthroplus.sqlite"),
            backupsDirectory: backups, keep: 10, now: utc("2026-10-14T10:30:05Z")
        )
        #expect(result == nil)
        let contents = (try? fm.contentsOfDirectory(atPath: backups.path)) ?? []
        #expect(contents.isEmpty)
    }

    // MARK: Restauração do último backup

    // Scenario: Restauração com backup disponível
    @Test func restauracaoUsaBackupMaisRecente() throws {
        let dir = try createdRoot()
        defer { try? fm.removeItem(at: dir) }
        let backups = dir.appendingPathComponent("Backups", isDirectory: true)
        try fm.createDirectory(at: backups, withIntermediateDirectories: true)
        try makeDatabase(at: backups.appendingPathComponent("anthroplus-20261011-080000.sqlite"), probe: "b1")
        try makeDatabase(at: backups.appendingPathComponent("anthroplus-20261013-080000.sqlite"), probe: "b3")
        try makeDatabase(at: backups.appendingPathComponent("anthroplus-20261012-080000.sqlite"), probe: "b2")
        let dbURL = dir.appendingPathComponent("anthroplus.sqlite")
        try junk().write(to: dbURL)

        let store = StoreController(directory: dir, now: { self.utc("2026-10-14T10:30:05Z") })
        store.openOnLaunch()
        try store.restoreLatestBackup()

        #expect(store.state == .ready)
        let db = try #require(store.database)
        #expect(try probe(in: db) == .text("b3"))
        let files = try fm.contentsOfDirectory(atPath: dir.path)
        #expect(files.contains("anthroplus.corrupted-20261014-103005.sqlite"))
    }

    // Scenario: Sem backup para restaurar
    @Test func semBackupLancaErro() throws {
        let dir = try createdRoot()
        defer { try? fm.removeItem(at: dir) }
        try junk().write(to: dir.appendingPathComponent("anthroplus.sqlite"))

        let store = StoreController(directory: dir)
        store.openOnLaunch()
        #expect(throws: StoreError.backupNotFound) {
            try store.restoreLatestBackup()
        }
        guard case .corrupted = store.state else {
            Issue.record("expected state .corrupted, got \(store.state)")
            return
        }
    }

    // MARK: Exportar cópia do banco

    // Scenario: Cópia exportada
    @Test func copiaExportadaAbreComMesmaVersao() throws {
        let dir = try createdRoot()
        defer { try? fm.removeItem(at: dir) }
        let store = StoreController(directory: dir)
        store.openOnLaunch()
        let db = try #require(store.database)
        try db.execute("INSERT OR REPLACE INTO app_meta(key, value) VALUES (?, ?)", [.text("probe"), .text("recente")])

        let destination = dir.appendingPathComponent("copia.sqlite")
        try store.exportCopy(to: destination)
        #expect(fm.fileExists(atPath: destination.path))
        let copy = try AnthroDatabase.open(at: destination, migrations: [])
        defer { copy.close() }
        #expect(try copy.schemaVersion() == db.schemaVersion())
        #expect(try probe(in: copy) == .text("recente"))
    }

    // Scenario: Destino já existe
    @Test func destinoExistenteNaoESobrescrito() throws {
        let dir = try createdRoot()
        defer { try? fm.removeItem(at: dir) }
        let store = StoreController(directory: dir)
        store.openOnLaunch()
        _ = try #require(store.database)

        let destination = dir.appendingPathComponent("existente.sqlite")
        try Data("conteúdo anterior".utf8).write(to: destination)
        let before = try fm.attributesOfItem(atPath: destination.path)

        #expect(throws: (any Error).self) {
            try store.exportCopy(to: destination)
        }
        let after = try fm.attributesOfItem(atPath: destination.path)
        #expect((after[.size] as? Int) == (before[.size] as? Int))
        #expect((after[.modificationDate] as? Date) == (before[.modificationDate] as? Date))
    }

    // MARK: Transações aninhadas

    private func makeTableDatabase(root: URL) throws -> AnthroDatabase {
        let db = try AnthroDatabase.open(at: root.appendingPathComponent("t.sqlite"), migrations: baseMigrations)
        try db.execute("CREATE TABLE t(name TEXT NOT NULL)")
        return db
    }

    // Scenario: Transação aninhada confirma com a externa
    @Test func transacaoAninhadaConfirmaComAExterna() throws {
        let root = try createdRoot()
        defer { try? fm.removeItem(at: root) }
        let db = try makeTableDatabase(root: root)
        defer { db.close() }

        var depthInside = -1
        try db.transaction {
            try db.execute("INSERT INTO t(name) VALUES (?)", [.text("A")])
            try db.transaction {
                depthInside = db.transactionDepth
                try db.execute("INSERT INTO t(name) VALUES (?)", [.text("B")])
            }
        }
        #expect(depthInside == 2)
        #expect(db.transactionDepth == 0)
        #expect(try names(in: db) == [.text("A"), .text("B")])
    }

    // Scenario: Erro na aninhada capturado pela externa
    @Test func erroNaAninhadaDesfazSoOTrechoDela() throws {
        let root = try createdRoot()
        defer { try? fm.removeItem(at: root) }
        let db = try makeTableDatabase(root: root)
        defer { db.close() }

        try db.transaction {
            try db.execute("INSERT INTO t(name) VALUES (?)", [.text("A")])
            do {
                try db.transaction {
                    try db.execute("INSERT INTO t(name) VALUES (?)", [.text("B")])
                    throw Boom()
                }
            } catch is Boom {}
            try db.execute("INSERT INTO t(name) VALUES (?)", [.text("C")])
        }
        #expect(try names(in: db) == [.text("A"), .text("C")])
    }

    // Scenario: Erro propagado desfaz tudo
    @Test func erroPropagadoDesfazTudo() throws {
        let root = try createdRoot()
        defer { try? fm.removeItem(at: root) }
        let db = try makeTableDatabase(root: root)
        defer { db.close() }

        var visibleB: Int64 = -1
        #expect(throws: Boom.self) {
            try db.transaction {
                try db.execute("INSERT INTO t(name) VALUES (?)", [.text("A")])
                try db.transaction {
                    try db.execute("INSERT INTO t(name) VALUES (?)", [.text("B")])
                    visibleB = try count(db, name: "B")
                    throw Boom()
                }
            }
        }
        #expect(visibleB == 1)
        #expect(try names(in: db).isEmpty)
        #expect(db.transactionDepth == 0)
    }
}
