import AnthroCore
import AnthroStore
import Foundation
import Testing

/// Cenários de child-registry exercidos sobre `ChildRepository` e `OrphanCleanup` (change add-individual-assessment).
@Suite("child-registry: ChildRepository")
struct ChildRepositoryTests {
    let db: AnthroDatabase
    let repository: ChildRepository

    init() throws {
        db = try IAFixtures.makeDatabase()
        repository = ChildRepository(database: db)
    }

    private func lastNames(_ criteria: ChildSearchCriteria) throws -> [String?] {
        try repository.search(criteria).map(\.lastName)
    }

    // Scenario: Criança salva e reaberta
    @Test func childSavedAndReopenedKeepsAllFields() throws {
        let mother = try IAFixtures.insertMother(db, firstName: "Maria")
        let father = try IAFixtures.insertFather(db, firstName: "João")
        let address = try IAFixtures.insertAddress(db, streetInfo: "Rua A")
        let child = ChildRecord(displayID: 7, firstName: "Ana", lastName: "Silva", dateOfBirth: IAFixtures.date("2015-01-01"),
                                dateOfBirthIsApprox: true, sex: .girl, motherID: mother, fatherID: father,
                                addressID: address, notes: "Ambulatório", followUpDate: IAFixtures.date("2021-10-01"),
                                followUpInterval: 30, followUpRefTo: "Nutrição")
        let saved = try repository.save(child, visits: [])
        let reopened = try #require(try repository.child(id: saved.id ?? -1))
        #expect(reopened == saved)
        #expect(reopened.sex == .girl)
        #expect(reopened.dateOfBirthIsApprox == true)
        var expected = child
        expected.id = reopened.id
        #expect(reopened == expected)
    }

    // Scenario: Ordem e rótulo das linhas
    @Test func activeListOrdersByDisplayIDWithNilFirst() throws {
        try IAFixtures.insertChild(db, displayID: 2, firstName: "Ana", lastName: "Silva")
        try IAFixtures.insertChild(db, displayID: 1, firstName: "Bia", lastName: "Souza")
        try IAFixtures.insertChild(db, firstName: "Caio", lastName: "Lima")
        #expect(try repository.list(archived: false).map(\.listTitle) == ["Lima, Caio ()", "Souza, Bia (1)", "Silva, Ana (2)"])
    }

    // Scenario: Rótulo sem sobrenome
    @Test func listTitleWithoutLastName() {
        let child = ChildRecord(displayID: 5, firstName: "Dora", dateOfBirth: IAFixtures.date("2016-01-01"), sex: .girl)
        #expect(child.listTitle == "Dora (5)")
    }

    // Scenario: Excluir criança com visitas
    @Test func deletingChildRemovesItsVisits() throws {
        let child = try IAFixtures.insertChild(db, firstName: "Ana")
        try IAFixtures.insertVisit(db, childID: child, date: "2021-01-10", weight: "20")
        try IAFixtures.insertVisit(db, childID: child, date: "2021-09-01", weight: "21")
        try repository.delete([child])
        #expect(try IAFixtures.count(db, "visits") == 0)
        #expect(try IAFixtures.count(db, "children") == 0)
    }

    // Scenario: Mãe compartilhada por irmãos
    @Test func sharedMotherSurvivesUntilLastChildIsDeleted() throws {
        let mother = try IAFixtures.insertMother(db, firstName: "Maria", lastName: "Silva")
        let first = try IAFixtures.insertChild(db, firstName: "Ana", motherID: mother)
        let second = try IAFixtures.insertChild(db, firstName: "Bia", motherID: mother)
        try repository.delete([first])
        #expect(try IAFixtures.count(db, "children") == 1)
        #expect(try IAFixtures.count(db, "mothers") == 1)
        try repository.delete([second])
        #expect(try IAFixtures.count(db, "mothers") == 0)
    }

    // Scenario: Limpeza repetida preserva vinculados
    @Test func orphanCleanupIsIdempotentAndKeepsLinkedRecords() throws {
        try IAFixtures.insertMother(db, firstName: "Sem filhos")
        let linked = try IAFixtures.insertMother(db, firstName: "Com filho")
        try IAFixtures.insertChild(db, firstName: "Ana", motherID: linked)
        let first = try OrphanCleanup.run(in: db)
        #expect(first.mothers == 1)
        let second = try OrphanCleanup.run(in: db)
        #expect(second == OrphanCleanupResult(mothers: 0, fathers: 0, addresses: 0))
        #expect(try IAFixtures.count(db, "mothers", where: "mother_id = \(linked)") == 1)
        #expect(try IAFixtures.count(db, "mothers") == 1)
    }

    // Scenario: Prefixo com curinga
    @Test func searchByLastNamePrefixWildcard() throws {
        try IAFixtures.insertChild(db, displayID: 1, lastName: "Lopez")
        try IAFixtures.insertChild(db, displayID: 2, lastName: "lima")
        try IAFixtures.insertChild(db, displayID: 3, lastName: "Silva")
        #expect(try lastNames(ChildSearchCriteria(lastName: "L*")) == ["Lopez", "lima"])
    }

    // Scenario: Sem curinga é igualdade
    @Test func searchWithoutWildcardIsExactMatch() throws {
        try IAFixtures.insertChild(db, displayID: 1, lastName: "Lopez")
        #expect(try lastNames(ChildSearchCriteria(lastName: "lopez")) == ["Lopez"])
        #expect(try lastNames(ChildSearchCriteria(lastName: "Lop")) == [])
    }

    // Scenario: Curinga de um caractere
    @Test func questionMarkMatchesExactlyOneCharacter() throws {
        try IAFixtures.insertChild(db, displayID: 1, firstName: "Ana")
        try IAFixtures.insertChild(db, displayID: 2, firstName: "Anna")
        #expect(try repository.search(ChildSearchCriteria(firstName: "?na")).map(\.firstName) == ["Ana"])
    }

    // Scenario: Maiúsculas e acentos
    @Test func searchIgnoresCaseButNotAccents() throws {
        try IAFixtures.insertChild(db, displayID: 1, firstName: "Érica")
        #expect(try repository.search(ChildSearchCriteria(firstName: "érica")).count == 1)
        #expect(try repository.search(ChildSearchCriteria(firstName: "erica")).count == 0)
    }

    // Scenario: Criança arquivada fica fora da busca
    @Test func searchExcludesArchivedChildren() throws {
        try IAFixtures.insertChild(db, displayID: 1, lastName: "Lopez", archived: true)
        try IAFixtures.insertChild(db, displayID: 2, lastName: "Lopes")
        #expect(try lastNames(ChildSearchCriteria(lastName: "Lop*")) == ["Lopes"])
    }
}
