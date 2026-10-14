import AnthroStore
import Foundation
import Testing

/// Cenários da migração 4 (change add-additional-data).
@Suite("additional-data: migração 4")
struct AdditionalDataMigrationScenarioTests {
    // Scenario: Tabela criada e preenchida
    @Test func migrationFourCreatesTemplateTable() throws {
        let url = try temporaryDatabaseURL()
        let v3 = try AnthroDatabase.open(at: url, migrations: Migrations.all.filter { $0.version <= 3 })
        #expect(try v3.schemaVersion() == 3)
        v3.close()

        let db = try AnthroDatabase.open(at: url)
        defer { db.close() }
        #expect(try db.schemaVersion() >= 4)
        let tables = try db.query(
            "SELECT name FROM sqlite_master WHERE type = 'table' AND name = 'additional_data_templates'")
        #expect(tables.count == 1)
        guard tables.count == 1 else { return }
        let rows = try db.query("SELECT scope, xml FROM additional_data_templates")
        #expect(rows.map { $0["scope"] } == [.text("individualAssessment")])
        #expect(rows.first?["xml"] == .text(iaTemplateXML))
    }

    // Scenario: XML obrigatório
    @Test func templateXMLIsNotNull() throws {
        let db = try AnthroDatabase.open(at: try temporaryDatabaseURL())
        defer { db.close() }
        var message = "no error"
        do {
            try db.execute("INSERT INTO additional_data_templates(scope, xml) VALUES ('outro', NULL)")
        } catch StoreError.sqlite(_, let text) {
            message = text
        }
        #expect(message.contains("NOT NULL constraint failed"))
    }
}
