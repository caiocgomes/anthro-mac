import AnthroFeatures
import Foundation
import Testing

/// Cenários de child-registry exercidos sobre `ChildListModel`.
@MainActor
@Suite("child-registry: ChildListModel")
struct ChildListModelTests {
    let db: AnthroDatabase

    init() throws {
        db = try IAFixtures.makeDatabase()
    }

    private func list() -> ChildListModel {
        ChildListModel(database: db, settings: IAFixtures.settings())
    }

    // Scenario: Arquivar duas de três crianças
    @Test func archivingMovesCheckedChildrenToArchive() throws {
        let ana = try IAFixtures.insertChild(db, displayID: 1, firstName: "Ana")
        let bia = try IAFixtures.insertChild(db, displayID: 2, firstName: "Bia")
        try IAFixtures.insertChild(db, displayID: 3, firstName: "Caio", sex: 1)
        try IAFixtures.insertVisit(db, childID: ana, date: "2021-09-01", weight: "21")
        try IAFixtures.insertVisit(db, childID: bia, date: "2021-09-01", weight: "22")
        let model = list()
        try model.load()
        model.checkedIDs = [ana, bia]
        try model.archiveChecked()
        #expect(model.rows.count == 1)
        try model.showArchive()
        #expect(model.rows.count == 2)
        #expect(try IAFixtures.count(db, "visits") == 2)
    }

    // Scenario: Restaurar sem marcação
    @Test func archiveModeExposesOnlyRestoreAndBack() throws {
        try IAFixtures.insertChild(db, displayID: 1, firstName: "Ana", archived: true)
        let model = list()
        try model.load()
        try model.showArchive()
        #expect(model.mode == .archive)
        model.checkedIDs = []
        #expect(model.canRestore == false)
        #expect(model.canCreate == false)
        #expect(model.canDelete == false)
        #expect(model.canSearch == false)
        #expect(model.canArchive == false)
    }

    // Scenario: Mãe sem filhos é removida
    @Test func moduleLoadRemovesOrphanParentsAndAddresses() throws {
        try IAFixtures.insertMother(db, firstName: "Sem filhos")
        let linked = try IAFixtures.insertMother(db, firstName: "Com filho")
        try IAFixtures.insertChild(db, displayID: 1, firstName: "Ana", motherID: linked)
        try list().load()
        #expect(try IAFixtures.count(db, "mothers") == 1)
        #expect(try IAFixtures.count(db, "mothers", where: "mother_id = \(linked)") == 1)
    }

    // Scenario: Faixas de ID e de nascimento
    @Test func searchCombinesSexIDRangeAndBirthRange() throws {
        var ids: [Int: Int64] = [:]
        for (displayID, birth) in [(1, "2015-01-01"), (2, "2015-06-01"), (4, "2016-01-01"), (5, "2017-01-01")] {
            ids[displayID] = try IAFixtures.insertChild(db, displayID: displayID, firstName: "Menina \(displayID)",
                                                       dateOfBirth: birth, sex: 2)
        }
        try IAFixtures.insertChild(db, displayID: 3, firstName: "Menino 3", dateOfBirth: "2015-08-01", sex: 1)
        let model = list()
        try model.load()
        try model.search(ChildSearchCriteria(sex: .girl, displayIDFrom: 2, displayIDTo: 4,
                                             dateOfBirthFrom: IAFixtures.date("2015-06-01"),
                                             dateOfBirthTo: IAFixtures.date("2016-01-01")))
        #expect(model.rows.map(\.id) == [ids[2]!, ids[4]!])
        #expect(model.mode == .searchResults)
    }

    // Scenario: Critérios vazios
    @Test func emptyCriteriaClearsSearch() throws {
        try IAFixtures.insertChild(db, displayID: 1, firstName: "Ana", lastName: "Silva")
        try IAFixtures.insertChild(db, displayID: 2, firstName: "Bia", lastName: "Souza")
        try IAFixtures.insertChild(db, displayID: 3, firstName: "Caio", lastName: "Lima", sex: 1)
        let model = list()
        try model.load()
        try model.search(ChildSearchCriteria(lastName: "S*"))
        try model.search(ChildSearchCriteria())
        #expect(model.mode == .active)
        #expect(model.rows.count == 3)
    }
}
