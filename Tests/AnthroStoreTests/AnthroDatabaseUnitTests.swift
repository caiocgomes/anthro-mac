import AnthroStore
import Foundation
import Testing

/// Laço interno de `AnthroDatabase` (tasks 2.1 a 2.3).
@Suite("AnthroDatabase: unidades")
struct AnthroDatabaseUnitTests {
    private func tempURL() throws -> URL {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("anthro-tests", isDirectory: true)
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("u.sqlite")
    }

    @Test func nuloEDecimalFazemIdaEVoltaPeloBanco() throws {
        let url = try tempURL()
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }
        let db = try AnthroDatabase.open(at: url, migrations: [])
        defer { db.close() }
        try db.execute("CREATE TABLE m(peso TEXT, nota TEXT)")
        try db.execute("INSERT INTO m(peso, nota) VALUES (?, ?)", [SQLValue(Decimal(string: "20.01")!), .null])
        let row = try #require(try db.query("SELECT peso, typeof(peso) AS tipo, nota FROM m").first)
        #expect(row["peso"].decimalValue == Decimal(string: "20.01")!)
        #expect(row["tipo"] == .text("text"))
        #expect(row["nota"] == .null)
        #expect(row["coluna_inexistente"] == .null)
        #expect(db.lastInsertRowID() == 1)
    }
}
