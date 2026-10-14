import AnthroCore
import AnthroFeatures
import AnthroStore
import Foundation
import Testing

/// Cenários do modelo de dados adicionais da avaliação individual e das visitas (change add-additional-data).
@MainActor
@Suite("additional-data: avaliação individual")
struct IndividualAdditionalDataScenarioTests {
    let db: AnthroDatabase
    let engine: AnthroEngine

    init() throws {
        db = try IAFixtures.makeDatabase()
        engine = try AnthroEngine.shared()
    }

    private func model() throws -> IndividualAdditionalDataModel {
        try IndividualAdditionalDataModel(repository: AdditionalDataTemplateRepository(database: db))
    }

    private func child(today: String) -> ChildDetailModel {
        ChildDetailModel(database: db, settings: IAFixtures.settings(), engine: engine,
                         today: { IAFixtures.date(today) }, randomDay: { $0.lowerBound })
    }

    // Scenario: Visita nova depois de editar o modelo
    @Test func newVisitGetsCurrentTemplateCopy() throws {
        let templates = try model()
        let editor = templates.makeEditor()
        editor.addSection()
        editor.setIdentifier("Escola")
        try templates.commit(editor)
        #expect(templates.dataForNewVisit().sections.count == 5)
        #expect(templates.dataForNewVisit().sections.last?.identifier == "Escola")

        let childID = try IAFixtures.insertChild(db, firstName: "Ana", dateOfBirth: "2015-01-01")
        let detail = child(today: "2021-04-01")
        try detail.open(childID: childID)
        let visit = try detail.makeVisitEditor(editing: nil).additionalData.result()
        #expect(visit.sections.count == 5)
        #expect(visit.sections.last?.identifier == "Escola")
    }

    // Scenario: Visita antiga não muda com o modelo
    @Test func savedVisitKeepsStructureAfterTemplateChange() throws {
        let childID = try IAFixtures.insertChild(db, firstName: "Ana", dateOfBirth: "2015-01-01")
        let detail = child(today: "2021-04-01")
        try detail.open(childID: childID)
        let visitEditor = detail.makeVisitEditor(editing: nil)
        visitEditor.weightText = "20"
        try detail.commitVisit(from: visitEditor)
        try detail.save()

        let templates = try model()
        let editor = templates.makeEditor()
        editor.selection = .section(3)
        editor.deleteSelected()
        try templates.commit(editor)

        let visits = try VisitRepository(database: db).visits(childID: childID)
        let stored = try AdditionalDataXML.decode(visits.first?.additionalDataXML)
        #expect(stored.sections.map(\.identifier).contains("Health"))
    }

    // Scenario: Cancelar a edição
    @Test func cancellingEditorKeepsTemplate() throws {
        let templates = try model()
        #expect(templates.template.sections.count == 4)
        let editor = templates.makeEditor()
        let food = try #require(editor.definition.sections.firstIndex { $0.identifier == "Food" })
        editor.selection = .section(food)
        editor.deleteSelected()
        #expect(editor.definition.sections.count == 3)
        // Cancelar é descartar o editor sem `commit`.
        #expect(templates.template.sections.count == 4)
        #expect(try AdditionalDataTemplateRepository(database: db).individualAssessmentTemplate().sections.count == 4)
    }
}
