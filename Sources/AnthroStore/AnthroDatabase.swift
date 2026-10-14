import Foundation

/// Conexão SQLite do app (design D2, D4 e D4b).
public final class AnthroDatabase: @unchecked Sendable {
    private init() {}

    /// `~/Library/Application Support/AnthroPlus`.
    public static func defaultDirectory() -> URL {
        URL(fileURLWithPath: "/dev/null")
    }

    public static func open(at url: URL, migrations: [Migration] = Migrations.all) throws -> AnthroDatabase {
        AnthroDatabase()
    }

    public func schemaVersion() throws -> Int {
        0
    }

    public func execute(_ sql: String, _ params: [SQLValue] = []) throws {}

    public func query(_ sql: String, _ params: [SQLValue] = []) throws -> [Row] {
        []
    }

    public func lastInsertRowID() -> Int64 {
        0
    }

    public func transaction<T>(_ body: () throws -> T) throws -> T {
        try body()
    }

    public var transactionDepth: Int {
        0
    }

    public func integrityCheck() throws -> Bool {
        false
    }

    public func pragma(_ name: String) throws -> String? {
        ""
    }

    public func backup(to url: URL) throws {}

    public func close() {}
}
