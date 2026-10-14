/// Migração de esquema identificada por `PRAGMA user_version` (design D3 e D4).
public struct Migration: Sendable {
    public let version: Int
    public let name: String
    public let sql: String

    public init(version: Int, name: String, sql: String) {
        self.version = version
        self.name = name
        self.sql = sql
    }
}

public enum Migrations {
    /// Todas as migrações do app, em ordem crescente de versão.
    public static var all: [Migration] {
        []
    }
}
