import AnthroCore
import AnthroStore
import Foundation
import Testing

/// Laço interno do mapeamento de registros (tarefa 1.2 da add-individual-assessment).
@Suite("Mapeamento de registros: unidades")
struct RecordMappingUnitTests {
    @Test func sexoGravadoComo1Menino2Menina() throws {
        let db = try IAFixtures.makeDatabase()
        let repository = ChildRepository(database: db)
        let boy = try repository.save(ChildRecord(dateOfBirth: IAFixtures.date("2015-01-01"), sex: .boy), visits: [])
        let girl = try repository.save(ChildRecord(dateOfBirth: IAFixtures.date("2015-01-01"), sex: .girl), visits: [])
        #expect(try db.query("SELECT sex FROM children ORDER BY child_id").map { $0["sex"] } == [.integer(1), .integer(2)])
        #expect(try repository.child(id: boy.id!)?.sex == .boy)
        #expect(try repository.child(id: girl.id!)?.sex == .girl)
    }

    @Test func visitaGravadaERelidaSemPerda() throws {
        let db = try IAFixtures.makeDatabase()
        let child = try IAFixtures.insertChild(db)
        let visit = VisitRecord(childID: child, date: IAFixtures.date("2021-09-01"), weight: Decimal(string: "21.60"),
                                lengthOrHeight: Decimal(string: "118.92"), measuredRecumbent: true, hasOedema: true,
                                notes: "retorno", additionalDataXML: "<dados/>")
        try VisitRepository(database: db).replaceVisits(childID: child, with: [visit])
        #expect(try db.query("SELECT date, weight FROM visits").first.map { [$0["date"], $0["weight"]] }
                == [.text("2021-09-01"), .text("21.6")])
        #expect(try VisitRepository(database: db).visits(childID: child) == [visit])
    }
}
