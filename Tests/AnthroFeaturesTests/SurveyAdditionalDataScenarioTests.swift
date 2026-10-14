import AnthroCore
import AnthroFeatures
import AnthroStore
import Foundation
import Testing

/// Cenários dos dados adicionais no inquérito: definição, editor de registro e colunas (change add-additional-data).
@MainActor
@Suite("additional-data: inquérito")
struct SurveyAdditionalDataScenarioTests {
    let db: AnthroDatabase
    let engine: AnthroEngine

    init() throws {
        db = try SurveyFixtures.makeDatabase()
        engine = try AnthroEngine.shared()
    }

    private func detail(definition: String?, records: [SurveyRecord] = []) -> SurveyDetailModel {
        SurveyFixtures.detail(records, db: db, engine: engine,
                              survey: Survey(name: "Escola A", additionalDataDefinitionXML: definition,
                                             options: SurveyFixtures.literalOptions()))
    }

    private func record(_ xml: String) -> SurveyRecord {
        var record = SurveyFixtures.record(sex: .girl, visit: "2021-04-01", birth: "2015-01-01", weight: "20")
        record.additionalDataXML = xml
        return record
    }

    private static let schoolDefinition = #"<Data><Cat ID="Escola" Descr=""><Txt ID="Série" Descr=""></Txt></Cat></Data>"#
    private static let schoolRecord = #"<Data><Cat ID="Escola" Descr=""><Txt ID="Série" Descr="">3º ano</Txt></Cat></Data>"#

    // Scenario: Definição aplicada e salva
    @Test func surveyDefinitionIsAppliedMarkedAndSaved() throws {
        let m = detail(definition: nil)
        let editor = m.makeAdditionalDataDefinitionEditor()
        editor.addSection()
        editor.setIdentifier("Escola")
        editor.addVariable()
        editor.setIdentifier("Série")
        try m.applyAdditionalDataDefinition(editor)
        #expect(m.hasUnsavedChanges)
        try m.save()
        #expect(!m.hasUnsavedChanges)
        let id = try #require(m.survey.id)
        let reread = try SurveyRepository(database: db).survey(id: id)
        let definition = try AdditionalDataXML.decode(reread.additionalDataDefinitionXML)
        #expect(definition.sections.map(\.identifier) == ["Escola"])
        #expect(definition.variable(section: "Escola", variable: "Série")?.kind == .text(nil))
    }

    // Scenario: Registro antigo mantém seus dados
    @Test func existingRecordKeepsOldVariableAfterDefinitionChange() throws {
        let m = detail(definition: Self.schoolDefinition, records: [record(Self.schoolRecord)])
        let editor = m.makeAdditionalDataDefinitionEditor()
        editor.selection = .variable(section: 0, variable: 0)
        editor.setIdentifier("Turma")
        try m.applyAdditionalDataDefinition(editor)
        #expect(m.additionalDataDefinition.variable(section: "Escola", variable: "Turma") != nil)
        #expect(m.allRecords.first?.additionalDataXML == Self.schoolRecord)
    }

    // Scenario: Registro bloqueado por dado adicional inválido
    @Test func invalidAdditionalValueBlocksRecordSave() throws {
        let m = detail(definition: iaTemplateXML)
        let editor = m.makeNewRecordEditor()
        #expect(editor.canSave)
        let sport = try #require(editor.additionalData.fields.first { $0.sectionIndex == 1 && $0.variableIndex == 0 })
        editor.additionalData.setNumber("141", section: sport.sectionIndex, variable: sport.variableIndex)
        #expect(!editor.canSave)
        editor.additionalData.setNumber("", section: sport.sectionIndex, variable: sport.variableIndex)
        #expect(editor.canSave)
    }

    // Scenario: Registro novo com definição
    @Test func newRecordStoresValuesFromSurveyDefinition() throws {
        let m = detail(definition: Self.schoolDefinition)
        let editor = m.makeNewRecordEditor()
        editor.additionalData.setText("3º ano", section: 0, variable: 0)
        try m.commit(editor)
        try m.save()
        let id = try #require(m.survey.id)
        let stored = try SurveyRepository(database: db).records(surveyID: id)
        #expect(stored.map(\.additionalDataXML) == [Self.schoolRecord])
    }

    // Scenario: Registro existente com estrutura antiga
    @Test func existingRecordFormUsesRecordStructure() {
        let definition = #"<Data><Cat ID="Escola" Descr=""><Txt ID="Turma" Descr=""></Txt></Cat></Data>"#
        let m = detail(definition: definition, records: [record(Self.schoolRecord)])
        let editor = m.makeEditor(visibleIndex: 0)
        #expect(editor.additionalData.fields.map(\.label) == ["Série"])
    }

    // Scenario: Valores formatados
    @Test func additionalCellsRenderTextNumberAndDate() throws {
        let definition = #"<Data><Cat ID="Escola" Descr=""><Txt ID="Série" Descr=""></Txt><Num Min="" Max="" ID="Peso ao nascer" Descr="" /><Date ID="Data da escola" Descr="" /></Cat></Data>"#
        let values = #"<Data><Cat ID="Escola" Descr=""><Txt ID="Série" Descr="">3º ano</Txt><Num Min="" Max="" ID="Peso ao nascer" Descr="">3.25</Num><Date ID="Data da escola" Descr="">01-02-2021 00:00:00</Date></Cat></Data>"#
        let m = detail(definition: definition, records: [record(values)])
        let additional = m.columns.filter(\.isAdditional)
        let row = try #require(m.visibleRows.first)
        #expect(additional.map { row.text($0) } == ["3º ano", "3,25", "01/02/2021"])
    }

    // Scenario: Variável ausente no registro
    @Test func missingAdditionalVariableRendersEmpty() throws {
        let definition = #"<Data><Cat ID="Escola" Descr=""><Txt ID="Série" Descr=""></Txt><Txt ID="Turma" Descr=""></Txt></Cat></Data>"#
        let m = detail(definition: definition, records: [record(Self.schoolRecord)])
        let additional = m.columns.filter(\.isAdditional)
        let row = try #require(m.visibleRows.first)
        #expect(additional.map(\.title) == ["Série", "Turma"])
        #expect(additional.map { row.text($0) } == ["3º ano", ""])
    }

    // Scenario: Ordenação de data em ordem cronológica
    @Test func additionalDateColumnSortsChronologically() throws {
        let definition = #"<Data><Cat ID="Escola" Descr=""><Date ID="Início" Descr="" /></Cat></Data>"#
        func dated(_ text: String) -> SurveyRecord {
            record(#"<Data><Cat ID="Escola" Descr=""><Date ID="Início" Descr="">"# + text + "</Date></Cat></Data>")
        }
        let m = detail(definition: definition,
                       records: [dated("01-02-2021 00:00:00"), dated("15-01-2021 00:00:00"), dated("")])
        let column = try #require(m.columns.first { $0.isAdditional })
        m.sort(by: column)
        #expect(m.visibleRows.map { $0.text(column) } == ["15/01/2021", "01/02/2021", ""])
    }

    // Scenario: Filtro e cópia com coluna adicional
    @Test func additionalColumnIsFilterableAndCopied() throws {
        let definition = #"<Data><Cat ID="Escola" Descr=""><Num Min="" Max="" ID="Recreio" Descr="" /></Cat></Data>"#
        func recess(_ value: String) -> SurveyRecord {
            record(#"<Data><Cat ID="Escola" Descr=""><Num Min="" Max="" ID="Recreio" Descr="">"# + value + "</Num></Cat></Data>")
        }
        let m = detail(definition: definition, records: [recess("2"), recess("7"), recess("10")])
        let column = try #require(m.columns.first { $0.isAdditional })
        m.applyFilter(SurveyFilter(column: column, condition: .greaterOrEqual, value1: "7"))
        #expect(m.visibleRows.count == 2)
        let lines = m.clipboardText(selectedVisibleIndices: IndexSet(m.visibleRows.indices)).components(separatedBy: "\r\n")
        #expect(lines.first == fixedSurveyColumnTitles.map { $0 + "\t" }.joined() + "Recreio\t")
        #expect(lines.dropFirst().prefix(2).map { $0.hasSuffix("\t7\t") || $0.hasSuffix("\t10\t") } == [true, true])
    }
}
