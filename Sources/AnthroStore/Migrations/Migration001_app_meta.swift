extension Migration {
    /// Versão 1: metadados do banco (design D3).
    static let appMeta = Migration(
        version: 1,
        name: "app_meta",
        sql: """
        CREATE TABLE app_meta(key TEXT PRIMARY KEY, value TEXT NOT NULL);
        INSERT INTO app_meta(key, value) VALUES ('created_at', strftime('%Y-%m-%dT%H:%M:%SZ', 'now'));
        """
    )
}
