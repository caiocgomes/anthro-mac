import AnthroFeatures
import Foundation
import Testing

/// Laço interno da ordenação tipada (`Record.CompareTo`) e de `SurveyFilterEvaluator` (`NSMain.FilterRecords`).
@MainActor
@Suite("Ordenação e filtro da tabela: unidades")
struct SurveySortFilterUnitTests {
    let db: AnthroDatabase
    let engine: AnthroEngine

    init() throws {
        db = try SurveyFixtures.makeDatabase()
        engine = try AnthroEngine.shared()
    }

    private func names(_ m: SurveyDetailModel) -> [String?] {
        m.visibleRows.map(\.record.firstName)
    }

    // MARK: Comparadores

    @Test func sexSortsGirlsBeforeBoys() {
        let m = SurveyFixtures.detail([SurveyFixtures.record(sex: .boy, firstName: "B"),
                                       SurveyFixtures.record(sex: .girl, firstName: "G")], db: db, engine: engine)
        m.sort(by: .fixed(.sex))
        #expect(names(m) == ["G", "B"])
    }

    @Test func undefinedZGoesBeforeNegativeValuesButMissingWeightGoesLast() {
        let m = SurveyFixtures.detail([SurveyFixtures.record(sex: .boy, months: "72", weight: "19.20", firstName: "neg"),
                                       SurveyFixtures.record(sex: .boy, months: "72", firstName: "sem")], db: db, engine: engine)
        m.sort(by: .fixed(.weightForAgeZ))
        #expect(names(m) == ["sem", "neg"])
        m.clearFilter()
        m.sort(by: .fixed(.weight))
        #expect(names(m) == ["neg", "sem"])
    }

    @Test func nilOedemaSortsAfterFalseAndTrue() {
        let m = SurveyFixtures.detail([SurveyFixtures.record(firstName: "nil", oedema: nil),
                                       SurveyFixtures.record(firstName: "sim", oedema: true),
                                       SurveyFixtures.record(firstName: "não", oedema: false)], db: db, engine: engine)
        m.sort(by: .fixed(.oedema))
        #expect(names(m) == ["não", "sim", "nil"])
    }

    @Test func flagSortsByOriginalEnumOrder() {
        // none, P/I (sem peso), E/I (estatura 200), IMC/I (sem peso nem medida aos 109 meses: P/I não conta).
        let m = SurveyFixtures.detail([SurveyFixtures.record(sex: .boy, months: "72", weight: "20", height: "200", firstName: "E/I"),
                                       SurveyFixtures.record(sex: .boy, months: "109", height: "130", firstName: "IMC/I"),
                                       SurveyFixtures.record(sex: .boy, months: "72", height: "115", firstName: "P/I"),
                                       SurveyFixtures.record(sex: .boy, months: "72", weight: "20", height: "115", firstName: "ok")],
                                      db: db, engine: engine)
        m.sort(by: .fixed(.flag))
        #expect(names(m) == ["ok", "P/I", "E/I", "IMC/I"])
    }

    // MARK: Filtro

    private func keeps(_ cell: String, _ condition: FilterCondition, _ v1: String, _ v2: String = "") -> Bool {
        SurveyFilterEvaluator.keeps(cellText: cell, condition: condition, value1: v1, value2: v2)
    }

    @Test func numericBranchComparesNumbersWithCommaOrDot() {
        #expect(keeps("20,00", .equal, "20"))
        #expect(keeps("20,00", .notEqual, "20.5"))
        #expect(!keeps("20,00", .notEqual, "20"))
        #expect(keeps("20,00", .lessOrEqual, "20,0"))
        #expect(!keeps("20,01", .lessOrEqual, "20"))
        #expect(keeps("15", .range, "10", "15"))
        #expect(!keeps("16", .range, "10", "15"))
    }

    @Test func textBranchIgnoresCaseAndTrimsOnlyTheValue() {
        #expect(keeps("Masculino", .equal, "  MASCULINO "))
        #expect(!keeps("Masculino", .notEqual, "masculino"))
        #expect(keeps("E/I, P/I", .notEqual, "E/I"))
        #expect(keeps("", .equal, ""))
        #expect(!keeps("3", .equal, ""))
    }

    @Test func dateBranchComparesDatesAndHidesUnreadableCells() {
        #expect(keeps("01/04/2021", .greaterOrEqual, "31/03/2021"))
        #expect(!keeps("01/04/2021", .lessOrEqual, "31/03/2021"))
        #expect(!keeps("", .greaterOrEqual, "01/01/2020"))
        #expect(!keeps("XX/03/2016", .lessOrEqual, "01/01/2020"))
        #expect(keeps("01/04/2021", .range, "", "01/04/2021"))
        #expect(!keeps("02/04/2021", .range, "", "01/04/2021"))
        #expect(!keeps("01/04/2021", .range, "x", ""))
        #expect(!keeps("Sim", .range, "", ""))
    }
}
