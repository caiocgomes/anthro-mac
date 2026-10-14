import AnthroFeatures
import Foundation
import Testing

/// Cenários da tabela de registros: formatos, destaque, ordenação, cópia e seleção (change add-nutritional-survey).
@MainActor
@Suite("survey-management: tabela de registros")
struct SurveyTableScenarioTests {
    let db: AnthroDatabase
    let engine: AnthroEngine

    init() throws {
        db = try SurveyFixtures.makeDatabase()
        engine = try AnthroEngine.shared()
    }

    private func row(_ record: SurveyRecord) -> SurveyRecordRow {
        SurveyRecordRow(record: record, engine: engine, options: SurveyFixtures.literalOptions())
    }

    private func detail(_ records: [SurveyRecord]) -> SurveyDetailModel {
        SurveyFixtures.detail(records, db: db, engine: engine)
    }

    private func cell(_ row: SurveyRecordRow, _ column: SurveyColumn) -> String {
        row.text(.fixed(column))
    }

    private func weights(_ model: SurveyDetailModel) -> [Decimal?] {
        model.visibleRows.map(\.record.weight)
    }

    // MARK: Formatos e destaque

    // Scenario: Linha completa
    @Test func fullRowRendersOriginalFormats() {
        let r = row(SurveyFixtures.record(sex: .girl, visit: "2021-04-01", birth: "2016-03-15", approx: true,
                                          weight: "18.5", height: "110", oedema: nil))
        let columns: [SurveyColumn] = [.surveyDate, .dateOfBirth, .ageInDays, .ageInMonths, .weight, .oedema, .recumbent,
                                       .lengthOrHeight, .weightingFactor, .estimatedDateOfBirth]
        #expect(columns.map { cell(r, $0) }
            == ["01/04/2021", "XX/03/2016", "1843", "60,55", "18,50", "Não", "Não", "110,00", "1", "Sim"])
    }

    // Scenario: Valores ausentes
    @Test func missingValuesRenderAsEmptyText() {
        let r = row(SurveyFixtures.record(sex: .girl, birth: "2016-03-15"))
        #expect(cell(r, .surveyDate) == "")
        #expect(cell(r, .cluster) == "")
        #expect(cell(r, .weight) == "")
        #expect(cell(r, .weightForAgeZ) == "")
        #expect(cell(r, .sex) == "Feminino")
    }

    // Scenario: Idade digitada
    @Test func typedAgeRendersDaysAndIsNotDerived() {
        let r = row(SurveyFixtures.record(months: "61.5"))
        #expect(cell(r, .ageInDays) == "1872")
        #expect(cell(r, .ageInMonths) == "61,50")
        #expect(r.isDerived(.fixed(.ageInDays)) == false)
        #expect(r.isDerived(.fixed(.ageInMonths)) == false)
    }

    // Scenario: Idade derivada das datas
    @Test func computedAgeRendersAsDerived() {
        let r = row(SurveyFixtures.record(visit: "2021-04-01", birth: "2016-03-15"))
        #expect(cell(r, .ageInDays) == "1843")
        #expect(cell(r, .ageInMonths) == "60,55")
        #expect(r.isDerived(.fixed(.ageInDays)))
        #expect(r.isDerived(.fixed(.ageInMonths)))
    }

    // Scenario: z de estatura implausível
    @Test func implausibleHeightZIsHighlightedWithFlagText() {
        let r = row(SurveyFixtures.record(sex: .boy, months: "72", weight: "24", height: "148"))
        #expect(cell(r, .weightForAgeZ) == "1,14")
        #expect(cell(r, .lengthOrHeightForAgeZ) == "6,51")
        #expect(cell(r, .bmiForAgeZ) == "-4,32")
        #expect(r.isHighlighted(.fixed(.lengthOrHeightForAgeZ)))
        #expect(r.isHighlighted(.fixed(.weightForAgeZ)) == false)
        #expect(r.isHighlighted(.fixed(.bmiForAgeZ)) == false)
        #expect(cell(r, .flag) == "E/I")
        #expect(r.flag == .lengthOrHeightForAge)
    }

    // Scenario: z ausente sem destaque visível
    @Test func missingWeightZIsNotHighlightedButFlagged() {
        let r = row(SurveyFixtures.record(sex: .girl, visit: "2021-06-23", birth: "2016-01-01", height: "110"))
        #expect(cell(r, .weightForAgeZ) == "")
        #expect(r.isHighlighted(.fixed(.weightForAgeZ)) == false)
        #expect(cell(r, .flag) == "P/I")
    }

    // MARK: Ordenação

    // Scenario: Três cliques no peso
    @Test func threeClicksSortAscendingThenReverseTwice() {
        let m = detail([SurveyFixtures.record(weight: "20"), SurveyFixtures.record(), SurveyFixtures.record(weight: "15")])
        m.sort(by: .fixed(.weight))
        #expect(weights(m) == [15, 20, nil])
        #expect(m.sortAscending == true)
        m.sort(by: .fixed(.weight))
        #expect(weights(m) == [nil, 20, 15])
        #expect(m.sortAscending == false)
        m.sort(by: .fixed(.weight))
        #expect(weights(m) == [15, 20, nil])
        #expect(m.sortAscending == true)
        #expect(m.sortColumn == .fixed(.weight))
    }

    // Scenario: z indefinido ordenado primeiro
    @Test func undefinedZSortsAsSmallest() {
        let m = detail([SurveyFixtures.record(sex: .boy, months: "72", weight: "23.52"),
                        SurveyFixtures.record(sex: .boy, months: "72"),
                        SurveyFixtures.record(sex: .boy, months: "72", weight: "19.20")])
        m.sort(by: .fixed(.weightForAgeZ))
        #expect(m.visibleRows.map(\.result.weightForAge.zScore) == [nil, num("-0.5"), 1])
    }

    // Scenario: Troca de coluna recomeça em ordem crescente
    @Test func newSortColumnRestartsAscending() {
        let m = detail([SurveyFixtures.record(weight: "20", height: "110"), SurveyFixtures.record(weight: "15", height: "120"),
                        SurveyFixtures.record(weight: "25", height: "100")])
        m.sort(by: .fixed(.weight))
        m.sort(by: .fixed(.weight))
        #expect(weights(m) == [25, 20, 15])
        m.sort(by: .fixed(.lengthOrHeight))
        #expect(m.sortColumn == .fixed(.lengthOrHeight))
        #expect(m.sortAscending == true)
        #expect(m.visibleRows.map(\.record.lengthOrHeight) == [100, 110, 120])
    }

    // MARK: Cópia

    // Scenario: Duas linhas selecionadas
    @Test func clipboardHasHeaderAndSelectedRowsInTableOrder() {
        let m = detail([SurveyFixtures.record(visit: "2021-04-01"), SurveyFixtures.record(visit: "2021-04-02"),
                        SurveyFixtures.record(visit: "2021-04-03")])
        let text = m.clipboardText(selectedVisibleIndices: [2, 0])
        #expect(text.hasSuffix("\t\r\n"))
        let lines = Array(text.components(separatedBy: "\r\n").dropLast())
        #expect(lines.count == 3)
        #expect(lines.allSatisfy { $0.hasSuffix("\t") })
        #expect(lines.first == SurveyColumn.allCases.map { $0.title + "\t" }.joined())
        #expect(lines.dropFirst().first?.hasPrefix("01/04/2021\t") == true)
        #expect(lines.dropFirst(2).first?.hasPrefix("03/04/2021\t") == true)
    }

    // Scenario: Nenhuma linha selecionada
    @Test func clipboardWithoutSelectionHasOnlyHeader() {
        let m = detail([SurveyFixtures.record(visit: "2021-04-01")])
        #expect(SurveyColumn.allCases.count == 19)
        #expect(SurveyColumn.allCases.allSatisfy { !$0.title.isEmpty })
        let header = SurveyColumn.allCases.map { $0.title + "\t" }.joined() + "\r\n"
        #expect(m.clipboardText(selectedVisibleIndices: []) == header)
    }

    // MARK: Seleção

    // Scenario: Linha selecionada
    @Test func selectingRowExposesResultAndSeverity() throws {
        let m = detail([SurveyFixtures.record(sex: .boy, months: "72", height: "128.27")])
        m.select(visibleIndex: 0)
        let selected = try #require(m.selectedResult)
        #expect(selected == m.visibleRows.first?.result)
        #expect(selected.lengthOrHeightForAge.zScore == num("2.5"))
        #expect(m.severity(.lengthOrHeightForAge) == .high)
    }

    // Scenario: Seleção removida
    @Test func deletingSelectedRowClearsResult() throws {
        let m = detail([SurveyFixtures.record(sex: .boy, months: "72", height: "128.27"),
                        SurveyFixtures.record(sex: .girl, months: "72", height: "120")])
        m.select(visibleIndex: 0)
        try #require(m.selectedResult != nil)
        m.deleteRecords(visibleIndices: [0])
        #expect(m.selectedResult == nil)
        #expect(m.severity(.lengthOrHeightForAge) == .undefined)
    }
}
