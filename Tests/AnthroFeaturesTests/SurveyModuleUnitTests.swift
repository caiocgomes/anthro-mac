import AnthroFeatures
import Foundation
import Testing

/// Laço interno de `SurveyModuleModel`: junção entre lista, inquérito aberto e a pergunta de alterações pendentes.
@MainActor
@Suite("SurveyModuleModel: junção com pendências")
struct SurveyModuleUnitTests {
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

    private func name(_ id: Int64) throws -> SQLValue? {
        try SurveyFixtures.row(db, "surveys", where: "id = \(id)")?["name"]
    }

    @Test func archivingWithPendingEditsAsksAndSavesFirst() throws {
        let a = try SurveyFixtures.insertSurvey(db, name: "Escola A")
        let m = try module()
        #expect(try m.open(id: a) == .done)
        try #require(m.openSurvey).name = "Escola A revisada"
        m.list.checkedIDs = [a]
        #expect(try m.archiveChecked() == .needsDecision)
        #expect(m.pendingAction == .archive)
        #expect(try SurveyFixtures.row(db, "surveys", where: "id = \(a)")?["is_archived"] == .integer(0))
        try m.resolvePending(.save)
        #expect(try name(a) == .text("Escola A revisada"))
        #expect(try SurveyFixtures.row(db, "surveys", where: "id = \(a)")?["is_archived"] == .integer(1))
        #expect(m.openSurvey == nil)
        #expect(m.list.surveys.isEmpty)
    }

    @Test func cancellingArchiveKeepsEverything() throws {
        let a = try SurveyFixtures.insertSurvey(db, name: "Escola A")
        let m = try module()
        _ = try m.open(id: a)
        try #require(m.openSurvey).name = "Escola A revisada"
        m.list.checkedIDs = [a]
        _ = try m.archiveChecked()
        try m.resolvePending(.cancel)
        #expect(m.openSurvey?.hasUnsavedChanges == true)
        #expect(m.list.surveys.map(\.name) == ["Escola A"])
    }

    @Test func moduleGuardReflectsOpenSurveyAndDiscardReverts() throws {
        let a = try SurveyFixtures.insertSurvey(db, name: "Escola A")
        let m = try module()
        #expect(m.hasUnsavedChanges == false)
        _ = try m.open(id: a)
        try #require(m.openSurvey).name = "Outro nome"
        #expect(m.hasUnsavedChanges)
        #expect(try m.proceedAfterUnsavedChanges(.cancel) == false)
        #expect(try m.proceedAfterUnsavedChanges(.discard))
        #expect(m.openSurvey?.name == "Escola A")
        #expect(m.hasUnsavedChanges == false)
    }

    @Test func closingWithDiscardLeavesDatabaseUntouched() throws {
        let a = try SurveyFixtures.insertSurvey(db, name: "Escola A")
        let m = try module()
        _ = try m.open(id: a)
        try #require(m.openSurvey).name = "Outro nome"
        #expect(m.requestClose() == .needsDecision)
        try m.resolvePending(.discard)
        #expect(m.openSurvey == nil)
        #expect(try name(a) == .text("Escola A"))
    }

    @Test func creatingASurveyOpensAnEmptyOneWithDefaultOptions() throws {
        let m = try module()
        #expect(m.createSurvey() == .done)
        let created = try #require(m.openSurvey)
        #expect(created.survey.id == nil)
        #expect(created.name == "")
        #expect(created.options.ageGroupBoundaries == SurveyFixtures.literalAgeBoundaries)
        #expect(created.allRecords.isEmpty)
    }

    @Test func savingThroughGuardPersistsAndReloadsList() throws {
        let m = try module()
        _ = m.createSurvey()
        try #require(m.openSurvey).name = "Escola Nova"
        #expect(try m.proceedAfterUnsavedChanges(.save))
        #expect(m.list.surveys.map(\.name) == ["Escola Nova"])
    }
}
