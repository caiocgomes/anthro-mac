import AnthroFeatures
import Foundation
import Testing

/// Cenários do filtro iterativo da tabela de registros (change add-nutritional-survey).
@MainActor
@Suite("survey-management: filtro de registros")
struct SurveyFilterScenarioTests {
    let db: AnthroDatabase
    let engine: AnthroEngine

    init() throws {
        db = try SurveyFixtures.makeDatabase()
        engine = try AnthroEngine.shared()
    }

    private func detail(_ records: [SurveyRecord]) -> SurveyDetailModel {
        SurveyFixtures.detail(records, db: db, engine: engine)
    }

    private func filter(_ column: SurveyColumn, _ condition: FilterCondition, _ value1: String,
                        _ value2: String = "") -> SurveyFilter {
        SurveyFilter(column: .fixed(column), condition: condition, value1: value1, value2: value2)
    }

    private func weights(_ model: SurveyDetailModel) -> [Decimal?] {
        model.visibleRows.map(\.record.weight)
    }

    private func threeWeights() -> SurveyDetailModel {
        detail([SurveyFixtures.record(weight: "15"), SurveyFixtures.record(weight: "20"), SurveyFixtures.record(weight: "25")])
    }

    // Scenario: Maior ou igual em peso
    @Test func numericGreaterOrEqualFilterKeepsMatches() {
        let m = threeWeights()
        m.applyFilter(filter(.weight, .greaterOrEqual, "20"))
        #expect(weights(m) == [20, 25])
        #expect(m.recordCountLabel == "2 registro(s)")
        #expect(m.isFiltered)
    }

    // Scenario: Intervalo numérico sem limite superior
    @Test func numericRangeWithEmptyUpperExcludesNumbers() throws {
        let m = threeWeights()
        try #require(m.visibleRows.count == 3)
        m.applyFilter(filter(.weight, .range, "15", ""))
        #expect(m.visibleRows.isEmpty)
        #expect(m.recordCountLabel == "0 registro(s)")
    }

    // Scenario: Sexo sem diferenciar maiúsculas
    @Test func textEqualityIsCaseInsensitiveAndTrimsValue() {
        let m = detail([SurveyFixtures.record(sex: .girl), SurveyFixtures.record(sex: .boy), SurveyFixtures.record(sex: .girl)])
        m.applyFilter(filter(.sex, .equal, " feminino "))
        #expect(m.visibleRows.map(\.record.sex) == [.girl, .girl])
    }

    // Scenario: Célula vazia igual a vazio
    @Test func emptyCellEqualsEmptyValue() {
        let m = detail([SurveyFixtures.record(cluster: 3), SurveyFixtures.record(), SurveyFixtures.record(cluster: 5)])
        m.applyFilter(filter(.cluster, .equal, ""))
        #expect(m.visibleRows.map(\.record.cluster) == [nil])
    }

    // Scenario: Intervalo de datas com limite superior aberto
    @Test func dateRangeWithOpenUpperBound() {
        let m = detail([SurveyFixtures.record(visit: "2020-12-31"), SurveyFixtures.record(visit: "2021-01-01"),
                        SurveyFixtures.record()])
        m.applyFilter(filter(.surveyDate, .range, "01/01/2021", ""))
        #expect(m.visibleRows.map { $0.record.visitDate.map(ymd) } == ["2021-01-01"])
    }

    // Scenario: Comparação de data com valor inválido
    @Test func dateComparisonWithInvalidValueHidesAll() throws {
        let m = detail([SurveyFixtures.record(visit: "2020-12-31"), SurveyFixtures.record(visit: "2021-01-01"),
                        SurveyFixtures.record()])
        try #require(m.visibleRows.count == 3)
        m.applyFilter(filter(.surveyDate, .greaterOrEqual, "ontem"))
        #expect(m.visibleRows.isEmpty)
    }

    // Scenario: Dois filtros e limpeza
    @Test func iterativeFiltersNarrowAndClearRestores() {
        let m = detail([SurveyFixtures.record(sex: .girl, weight: "15"), SurveyFixtures.record(sex: .girl, weight: "22"),
                        SurveyFixtures.record(sex: .boy, weight: "25")])
        m.applyFilter(filter(.sex, .equal, "feminino"))
        m.applyFilter(filter(.weight, .greaterOrEqual, "20"))
        #expect(weights(m) == [22])
        m.clearFilter()
        #expect(m.visibleRows.count == 3)
        #expect(m.recordCountLabel == "3 registro(s)")
        #expect(m.isFiltered == false)
        #expect(m.sortColumn == nil)
    }

    // Scenario: Limpar sem filtro ativo
    @Test func clearWithoutFilterIsNoOp() {
        let m = threeWeights()
        m.clearFilter()
        #expect(weights(m) == [15, 20, 25])
        #expect(m.isFiltered == false)
    }
}
