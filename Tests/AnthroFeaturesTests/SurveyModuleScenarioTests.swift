import AnthroFeatures
import Foundation
import Testing

/// Cenários da lista de inquéritos e da troca com alterações pendentes (change add-nutritional-survey).
@MainActor
@Suite("survey-management: lista e ciclo dos inquéritos")
struct SurveyModuleScenarioTests {
    let db: AnthroDatabase
    let engine: AnthroEngine

    init() throws {
        db = try SurveyFixtures.makeDatabase()
        engine = try AnthroEngine.shared()
    }

    private func module() throws -> SurveyModuleModel {
        let m = SurveyModuleModel(repository: SurveyRepository(database: db), engine: engine, today: { day("2026-10-14") })
        try m.list.reload()
        return m
    }

    private func names(_ m: SurveyModuleModel) -> [String] {
        m.list.surveys.map(\.name)
    }

    // Scenario: Ações dependem da marcação
    @Test func archiveAndDeleteDependOnCheckedSurveys() throws {
        let a = try SurveyFixtures.insertSurvey(db, name: "Escola A")
        try SurveyFixtures.insertSurvey(db, name: "Escola B")
        let m = try module()
        try #require(m.list.surveys.count == 2)
        m.list.checkedIDs = [a]
        #expect(m.list.canArchive)
        #expect(m.list.canDelete)
        m.list.checkedIDs = []
        #expect(m.list.canArchive == false)
        #expect(m.list.canDelete == false)
    }

    // Scenario: Arquivar e restaurar
    @Test func archiveThenRestoreMovesSurveyBetweenLists() throws {
        let a = try SurveyFixtures.insertSurvey(db, name: "Escola A")
        try SurveyFixtures.insertSurvey(db, name: "Escola B")
        let m = try module()
        m.list.checkedIDs = [a]
        try m.archiveChecked()
        #expect(names(m) == ["Escola B"])
        try m.list.showArchive(true)
        #expect(names(m) == ["Escola A"])
        m.list.checkedIDs = [a]
        #expect(m.list.canRestore)
        try m.list.restoreChecked()
        #expect(names(m).isEmpty)
        try m.list.showArchive(false)
        #expect(names(m) == ["Escola A", "Escola B"])
        #expect(try SurveyFixtures.row(db, "surveys", where: "id = \(a)")?["is_archived"] == .integer(0))
    }

    // Scenario: Arquivar o inquérito aberto
    @Test func archivingOpenSurveyClosesDetail() throws {
        let a = try SurveyFixtures.insertSurvey(db, name: "Escola A")
        let m = try module()
        _ = try m.open(id: a)
        try #require(m.openSurvey != nil)
        m.list.checkedIDs = [a]
        try m.archiveChecked()
        #expect(m.openSurvey == nil)
    }

    // Scenario: Exclusão do inquérito aberto
    @Test func deletingOpenSurveyClosesDetail() throws {
        let a = try SurveyFixtures.insertSurvey(db, name: "Escola A")
        let m = try module()
        _ = try m.open(id: a)
        try #require(m.openSurvey != nil)
        m.list.checkedIDs = [a]
        try m.deleteChecked()
        #expect(m.openSurvey == nil)
        #expect(try SurveyFixtures.count(db, "surveys") == 0)
    }

    // Scenario: Salvar antes de abrir outro inquérito
    @Test func saveDecisionPersistsThenOpensOtherSurvey() throws {
        let a = try SurveyFixtures.insertSurvey(db, name: "Escola A")
        let b = try SurveyFixtures.insertSurvey(db, name: "Escola B")
        let m = try module()
        _ = try m.open(id: a)
        let current = try #require(m.openSurvey)
        current.name = "Escola A revisada"
        #expect(try m.open(id: b) == .needsDecision)
        #expect(m.pendingAction == .open(b))
        try m.resolvePending(.save)
        #expect(try SurveyFixtures.row(db, "surveys", where: "id = \(a)")?["name"] == .text("Escola A revisada"))
        #expect(m.openSurvey?.survey.id == b)
        #expect(m.pendingAction == nil)
    }

    // Scenario: Cancelar a troca
    @Test func cancelDecisionKeepsCurrentSurveyDirty() throws {
        let a = try SurveyFixtures.insertSurvey(db, name: "Escola A")
        let b = try SurveyFixtures.insertSurvey(db, name: "Escola B")
        let m = try module()
        _ = try m.open(id: a)
        let current = try #require(m.openSurvey)
        current.name = "Escola A revisada"
        #expect(try m.open(id: b) == .needsDecision)
        try m.resolvePending(.cancel)
        #expect(m.openSurvey?.survey.id == a)
        #expect(m.openSurvey?.survey.name == "Escola A")
        #expect(m.openSurvey?.hasUnsavedChanges == true)
        #expect(m.pendingAction == nil)
    }
}
