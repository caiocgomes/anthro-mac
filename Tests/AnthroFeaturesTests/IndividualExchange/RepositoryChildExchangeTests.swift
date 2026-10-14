import AnthroCore
import AnthroFeatures
import AnthroIO
import AnthroStore
import Foundation
import Testing

/// Cenários da gravação da importação (change add-individual-import-export).
@MainActor
@Suite("individual-data-exchange: gravação da importação")
struct RepositoryChildExchangeTests {
    let db: AnthroDatabase
    let exchange: RepositoryChildExchange

    init() throws {
        db = try IAFixtures.makeDatabase()
        exchange = RepositoryChildExchange(database: db, children: ChildRepository(database: db), visits: VisitRepository(database: db),
                                           parents: ParentRepository(database: db), addresses: AddressRepository(database: db),
                                           templates: AdditionalDataTemplateRepository(database: db), engine: try AnthroEngine.shared())
    }

    private func count(_ table: String) throws -> Int64 {
        guard case .integer(let n) = try db.query("SELECT COUNT(*) AS n FROM \(table)").first?["n"] else { return -1 }
        return n
    }

    private var twoChildren: [ExchangeChild] {
        [ExchangeChild(displayID: 7, firstName: "Ana", dateOfBirth: day("2016-03-15"), sex: .girl,
                       mother: ExchangePerson(firstName: "Maria"), address: ExchangeAddress(place: "São Paulo"),
                       visits: [ExchangeVisit(date: day("2021-04-01"), weight: num("18.4"), height: num("110"))]),
         ExchangeChild(displayID: 9, firstName: "Bia", dateOfBirth: day("2017-01-20"), sex: .boy,
                       mother: ExchangePerson(firstName: "Joana"), father: ExchangePerson(firstName: "Paulo"),
                       address: ExchangeAddress(place: "Santos"),
                       visits: [ExchangeVisit(date: day("2021-04-02"), weight: num("16"), height: num("104"))])]
    }

    // Scenario: Duas crianças importadas
    @Test func duasCriancasImportadasPreservamDisplayID() throws {
        #expect(try exchange.insertAll(twoChildren) == 2)
        let stored = try ChildRepository(database: db).list(archived: false)
        #expect(stored.compactMap(\.displayID).sorted() == [7, 9])
        #expect(try count("children") == 2)
        #expect(try count("visits") == 2)
        #expect(try count("mothers") == 2)
        #expect(try count("fathers") == 1)
        #expect(try count("addresses") == 2)
    }

    // Scenario: Falha no meio da gravação
    @Test func falhaNoMeioDaGravacaoDesfazTudo() throws {
        try db.execute("""
            CREATE TRIGGER falha_na_segunda_crianca BEFORE INSERT ON children
            WHEN (SELECT COUNT(*) FROM children) >= 1
            BEGIN SELECT RAISE(ABORT, 'falha simulada na segunda criança'); END
            """)
        #expect(throws: (any Error).self) { try exchange.insertAll(twoChildren) }
        #expect(try count("children") == 0)
        #expect(try count("visits") == 0)
        #expect(try count("mothers") == 0)
        #expect(try count("fathers") == 0)
        #expect(try count("addresses") == 0)
    }
}
