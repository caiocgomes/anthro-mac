import AnthroStore
import Foundation
import Testing

/// Laço interno da migração 2 (tarefa 1.1 da add-individual-assessment).
@Suite("Migração 2: unidades")
struct MigrationIndividualUnitTests {
    private func freshURL() throws -> URL {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("anthro-ia-tests", isDirectory: true)
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory.appendingPathComponent("anthroplus.sqlite")
    }

    @Test func bancoNovoFicaNaVersao2ComAsCincoTabelas() throws {
        let db = try AnthroDatabase.open(at: try freshURL())
        #expect(try db.schemaVersion() >= 2)
        let tables = try db.query("SELECT name FROM sqlite_master WHERE type = 'table' ORDER BY name")
            .compactMap { row -> String? in if case .text(let name) = row["name"] { name } else { nil } }
        #expect(Set(["addresses", "children", "fathers", "mothers", "visits"]).isSubset(of: Set(tables)))
    }

    @Test func migracaoRodaSobreBancoNaVersao1PreservandoDados() throws {
        let url = try freshURL()
        let v1 = try AnthroDatabase.open(at: url, migrations: Migrations.all.filter { $0.version == 1 })
        #expect(try v1.schemaVersion() == 1)
        try v1.execute("INSERT INTO app_meta(key, value) VALUES ('probe', 'v1')")
        v1.close()
        let v2 = try AnthroDatabase.open(at: url)
        #expect(try v2.schemaVersion() >= 2)
        #expect(try v2.query("SELECT value FROM app_meta WHERE key = 'probe'").first?["value"] == .text("v1"))
    }

    @Test func sexoForaDe1e2EhRecusadoPeloBanco() throws {
        let db = try AnthroDatabase.open(at: try freshURL())
        #expect(throws: StoreError.self) {
            try db.execute("INSERT INTO children(date_of_birth, sex) VALUES ('2015-01-01', 0)")
        }
    }

    @Test func visitaRepetidaNaMesmaDataEhRecusadaPeloBanco() throws {
        let db = try AnthroDatabase.open(at: try freshURL())
        try db.execute("INSERT INTO children(date_of_birth, sex) VALUES ('2015-01-01', 2)")
        try db.execute("INSERT INTO visits(child_id, date) VALUES (1, '2021-09-01')")
        #expect(throws: StoreError.self) { try db.execute("INSERT INTO visits(child_id, date) VALUES (1, '2021-09-01')") }
    }
}
