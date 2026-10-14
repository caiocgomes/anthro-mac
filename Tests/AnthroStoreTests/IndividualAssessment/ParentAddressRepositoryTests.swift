import AnthroStore
import Foundation
import Testing

/// Cenários de child-registry exercidos sobre `ParentRepository` e `AddressRepository`.
@Suite("child-registry: ParentRepository e AddressRepository")
struct ParentAddressRepositoryTests {
    let db: AnthroDatabase

    init() throws {
        db = try IAFixtures.makeDatabase()
    }

    // Scenario: Rótulo de endereço
    @Test func addressDisplayNameJoinsFilledFields() throws {
        try IAFixtures.insertAddress(db, place: "Outro 1")
        try IAFixtures.insertAddress(db, place: "Outro 2")
        let saved = try AddressRepository(database: db)
            .save(AddressRecord(streetInfo: "Rua A, 10", place: "São Paulo", country: "Brasil"))
        #expect(saved.id == 3)
        #expect(saved.displayName == "Rua A, 10, São Paulo - Brasil (3)")
    }

    // Scenario: Endereço vazio
    @Test func emptyAddressShowsNoDataLabel() throws {
        for index in 1...3 { try IAFixtures.insertAddress(db, place: "Outro \(index)") }
        let saved = try AddressRepository(database: db).save(AddressRecord())
        #expect(saved.id == 4)
        #expect(saved.displayName == "(Sem dados) (4)")
    }

    // Scenario: Mãe encontrada por trecho do sobrenome
    @Test func motherSearchMatchesSubstringIgnoringCase() throws {
        try IAFixtures.insertMother(db, firstName: "Maria", lastName: "Silva")
        try IAFixtures.insertMother(db, firstName: "Joana", lastName: "Souza")
        let outcome = try ParentRepository(database: db).search(kind: .mother, text: "sil")
        guard case .results(let mothers) = outcome else {
            Issue.record("esperava .results, veio \(outcome)")
            return
        }
        #expect(mothers.map(\.displayName) == ["Silva, Maria (1)"])
    }

    // Scenario: Resultados demais
    @Test func lookupSearchReportsTooManyResults() throws {
        for index in 1...51 { try IAFixtures.insertMother(db, firstName: "Mãe \(index)") }
        #expect(try ParentRepository(database: db).search(kind: .mother, text: "") == .tooManyResults)
    }

    // Scenario: Nenhum resultado
    @Test func lookupSearchReportsNoResults() throws {
        try IAFixtures.insertAddress(db, streetInfo: "Rua A", place: "São Paulo", country: "Brasil")
        #expect(try AddressRepository(database: db).search(text: "xyz") == .noResults)
    }
}
