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
    /// Todas as migrações do app, em ordem crescente de versão. Reservadas: 2 avaliação individual,
    /// 3 inquérito, 4 dados adicionais (design D3).
    public static var all: [Migration] {
        [.appMeta, Migrations.individual]
    }
}

extension AnthroDatabase {
    /// Aplica, em ordem crescente, as migrações com versão maior que `user_version`; cada uma numa
    /// transação que também grava a nova versão (design D4).
    func migrate(_ migrations: [Migration]) throws {
        let current = try schemaVersion()
        for migration in migrations.sorted(by: { $0.version < $1.version }) where migration.version > current {
            do {
                try transaction {
                    try executeScript(migration.sql)
                    try executeScript("PRAGMA user_version = \(migration.version)")
                }
            } catch {
                throw StoreError.migrationFailed(version: migration.version, message: String(describing: error))
            }
        }
    }
}
