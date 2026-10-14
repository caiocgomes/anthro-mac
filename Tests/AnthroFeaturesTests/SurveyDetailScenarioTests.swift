import AnthroFeatures
import Foundation
import Testing

/// Cenários do inquérito aberto: inclusão com IDs automáticos, descarte, opções e ordem (change add-nutritional-survey).
@MainActor
@Suite("survey-management: inquérito aberto")
struct SurveyDetailScenarioTests {
    let db: AnthroDatabase
    let engine: AnthroEngine

    init() throws {
        db = try SurveyFixtures.makeDatabase()
        engine = try AnthroEngine.shared()
    }

    private func detail(_ records: [SurveyRecord],
                        survey: Survey = Survey(name: "Escola A", options: SurveyFixtures.literalOptions())) -> SurveyDetailModel {
        SurveyFixtures.detail(records, db: db, engine: engine, survey: survey)
    }

    // MARK: Edição transacional

    // Scenario: Descartar alterações
    @Test func discardRestoresSavedRecords() throws {
        let surveyID = try SurveyFixtures.insertSurvey(db, name: "Escola A")
        var a = SurveyFixtures.record(firstName: "A")
        a.id = try SurveyFixtures.insertRecord(db, surveyID: surveyID, position: 0, firstName: "A")
        var b = SurveyFixtures.record(firstName: "B")
        b.id = try SurveyFixtures.insertRecord(db, surveyID: surveyID, position: 1, firstName: "B")
        let m = detail([a, b], survey: Survey(id: surveyID, name: "Escola A", options: SurveyFixtures.literalOptions()))
        let editor = m.makeNewRecordEditor()
        editor.firstName = "C"
        try m.commit(editor)
        try #require(m.allRecords.count == 3)
        #expect(m.hasUnsavedChanges)
        try m.discardChanges()
        #expect(m.allRecords.map(\.firstName) == ["A", "B"])
        #expect(m.visibleRows.count == 2)
        #expect(m.hasUnsavedChanges == false)
    }

    // Scenario: Ordem de inclusão
    @Test func recordsKeepInsertionOrder() throws {
        let m = detail([])
        for name in ["A", "B", "C"] {
            let editor = m.makeNewRecordEditor()
            editor.firstName = name
            try m.commit(editor)
        }
        try m.save()
        let id = try #require(m.survey.id)
        let repository = SurveyRepository(database: db)
        let reopened = SurveyDetailModel(survey: try repository.survey(id: id), records: try repository.records(surveyID: id),
                                         repository: repository, engine: engine, today: { day("2026-10-14") })
        #expect(reopened.visibleRows.map(\.record.firstName) == ["A", "B", "C"])
    }

    // MARK: Atribuição automática de IDs

    // Scenario: Próximo ID
    @Test func autoRecordIDIsMaxPlusOne() throws {
        let m = detail([SurveyFixtures.record(displayID: 3), SurveyFixtures.record(displayID: 7)])
        try m.commit(m.makeNewRecordEditor())
        #expect(m.allRecords.count == 3)
        #expect(m.allRecords.last?.displayID == 8)
    }

    // Scenario: Inquérito sem domicílios
    @Test func autoHouseholdStartsAtOne() throws {
        let m = detail([SurveyFixtures.record(), SurveyFixtures.record()])
        try m.commit(m.makeNewRecordEditor())
        #expect(m.allRecords.count == 3)
        #expect(m.allRecords.last?.household == 1)
    }

    // Scenario: Filtro ativo não reduz o próximo ID
    @Test func autoIDConsidersFilteredRecords() throws {
        let m = detail([SurveyFixtures.record(weight: "15", displayID: 3), SurveyFixtures.record(weight: "25", displayID: 7)])
        m.applyFilter(SurveyFilter(column: .fixed(.weight), condition: .lessOrEqual, value1: "20"))
        try #require(m.visibleRows.map(\.record.displayID) == [3])
        try m.commit(m.makeNewRecordEditor())
        #expect(m.allRecords.last?.displayID == 8)
    }

    // Scenario: Atribuição de conglomerado desligada
    @Test func clusterStaysNilWhenAutoIDOff() throws {
        let m = detail([SurveyFixtures.record(cluster: 4)])
        try m.commit(m.makeNewRecordEditor())
        #expect(m.allRecords.count == 2)
        #expect(m.allRecords.last?.cluster == nil)
    }

    // Scenario: Valor digitado com atribuição ligada
    @Test func typedIDWinsOverAutoID() throws {
        let m = detail([SurveyFixtures.record(displayID: 7)])
        let editor = m.makeNewRecordEditor()
        editor.setText("2", for: .displayID)
        try m.commit(editor)
        #expect(m.allRecords.count == 2)
        #expect(m.allRecords.last?.displayID == 2)
    }

    // MARK: Opções

    // Scenario: Aplicar recalcula flags
    @Test func applyingOptionsRecomputesHighlights() throws {
        let m = detail([SurveyFixtures.record(sex: .boy, visit: "2021-04-01", birth: "2021-04-01", weight: "5.64")])
        try #require(m.visibleRows.first?.isHighlighted(.fixed(.weightForAgeZ)) == false)
        let editor = m.makeOptionsEditor()
        editor.setZBound(text: "3,5", indicator: .weightForAge, range: .standards, isMax: true)
        try m.applyOptions(editor)
        #expect(m.visibleRows.first?.isHighlighted(.fixed(.weightForAgeZ)) == true)
        #expect(m.options.standardsMaxZ.first == num("3.5"))
        #expect(m.hasUnsavedChanges)
    }

    // Scenario: Cancelar descarta a atribuição automática
    @Test func cancellingOptionsEditorKeepsSurveyOptions() {
        let m = detail([])
        let editor = m.makeOptionsEditor()
        editor.autoIDCluster = true
        #expect(m.options.autoIDCluster == false)
        #expect(m.options.autoIDRecord == true)
        #expect(m.hasUnsavedChanges == false)
    }
}
