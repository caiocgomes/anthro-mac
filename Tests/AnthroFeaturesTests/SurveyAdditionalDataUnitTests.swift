import AnthroCore
import AnthroFeatures
import AnthroStore
import Foundation
import Testing

@MainActor
@Suite("additional-data: inquérito (unitários)")
struct SurveyAdditionalDataUnitTests {
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

    private func record(_ inner: String) -> SurveyRecord {
        var record = SurveyFixtures.record(sex: .girl, visit: "2021-04-01", birth: "2015-01-01", weight: "20")
        record.additionalDataXML = #"<Data><Cat ID="C" Descr="">"# + inner + "</Cat></Data>"
        return record
    }

    @Test func defaultTemplateGivesTwentySixColumnsWithTranslatedTitles() {
        let m = detail(definition: iaTemplateXML)
        #expect(m.columns.count == 26)
        #expect(m.columns.filter(\.isAdditional).map(\.title).prefix(3) == ["Menarca/espermarca", "Autorreferido", "Esporte"])
    }

    @Test func repeatedKeyTitleKeepsTheSuffix() {
        let m = detail(definition: #"<Data><Cat ID="A" Descr=""><Txt ID="Sexo" Descr=""></Txt></Cat></Data>"#)
        #expect(m.columns.last?.title == "Sexo 2")
    }

    @Test func discardRestoresSavedDefinitionAndColumns() throws {
        let m = detail(definition: #"<Data><Cat ID="A" Descr=""><Txt ID="x" Descr=""></Txt></Cat></Data>"#)
        let editor = m.makeAdditionalDataDefinitionEditor()
        editor.selection = .section(0)
        editor.deleteSelected()
        try m.applyAdditionalDataDefinition(editor)
        #expect(m.columns.count == 19)
        try m.discardChanges()
        #expect(m.columns.count == 20)
        #expect(m.additionalDataDefinition.section("A") != nil)
        #expect(!m.hasUnsavedChanges)
    }

    @Test func removingTheSortedColumnClearsTheSortIndicator() throws {
        let m = detail(definition: #"<Data><Cat ID="A" Descr=""><Txt ID="x" Descr=""></Txt></Cat></Data>"#)
        let column = try #require(m.columns.last)
        m.sort(by: column)
        #expect(m.sortColumn == column)
        let editor = m.makeAdditionalDataDefinitionEditor()
        editor.selection = .section(0)
        editor.deleteSelected()
        try m.applyAdditionalDataDefinition(editor)
        #expect(m.sortColumn == nil)
    }

    @Test func mixedKindsSortNumbersThenDatesThenTextsThenMissing() throws {
        let m = detail(definition: #"<Data><Cat ID="C" Descr=""><Txt ID="v" Descr=""></Txt></Cat></Data>"#, records: [
            record(#"<Txt ID="v" Descr="">beta</Txt>"#),
            record(#"<Date ID="v" Descr="">01-02-2021 00:00:00</Date>"#),
            record(""),
            record(#"<Num Min="" Max="" ID="v" Descr="">10</Num>"#),
            record(#"<Txt ID="v" Descr="">Alfa</Txt>"#),
            record(#"<Num Min="" Max="" ID="v" Descr="">9.5</Num>"#),
        ])
        let column = try #require(m.columns.last)
        m.sort(by: column)
        #expect(m.visibleRows.map { $0.text(column) } == ["9,5", "10", "01/02/2021", "Alfa", "beta", ""])
    }

    @Test func unreadableRecordXMLRendersEmptyCells() throws {
        var broken = record("")
        broken.additionalDataXML = #"<Data><Cat ID="C" /></Data>"#
        let m = detail(definition: #"<Data><Cat ID="C" Descr=""><Txt ID="v" Descr=""></Txt></Cat></Data>"#, records: [broken])
        let column = try #require(m.columns.last)
        #expect(m.visibleRows.first?.text(column) == "")
    }

    @Test func applyingAnUnchangedDefinitionKeepsTheStoredText() throws {
        for stored in [#"<Data><Cat ID="A" Descr=""><Num Min="0,5" Max="" ID="n" Descr="" /></Cat></Data>"#,
                       #"<Data><Cat ID="A" /></Data>"#] {
            let m = detail(definition: stored)
            try m.applyAdditionalDataDefinition(m.makeAdditionalDataDefinitionEditor())
            #expect(!m.hasUnsavedChanges, "\(stored)")
            m.name = "Escola B"
            try m.save()
            let id = try #require(m.survey.id)
            #expect(try SurveyRepository(database: db).survey(id: id).additionalDataDefinitionXML == stored)
        }
    }
}

