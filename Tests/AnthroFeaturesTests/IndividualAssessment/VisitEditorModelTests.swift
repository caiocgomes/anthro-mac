import AnthroFeatures
import Foundation
import Testing

/// Cenários de visit-tracking exercidos sobre `VisitEditorModel`.
@MainActor
@Suite("visit-tracking: VisitEditorModel")
struct VisitEditorModelTests {
    let engine: AnthroEngine

    init() throws {
        engine = try AnthroEngine.shared()
    }

    private func editor(birth: String = "2015-01-01", sex: Sex? = .girl, existing: [String] = [],
                        editing: VisitRecord? = nil, today: String = "2021-09-01") -> VisitEditorModel {
        VisitEditorModel(dateOfBirth: IAFixtures.date(birth), sex: sex, existingDates: Set(existing.map(IAFixtures.date)),
                         editing: editing, engine: engine, today: IAFixtures.date(today))
    }

    private func num(_ text: String) -> Decimal {
        Decimal(string: text)!
    }

    // MARK: Valores iniciais e data

    // Scenario: Valores iniciais de uma nova visita
    @Test func newVisitStartsTodayStandingWithoutOedema() {
        let e = editor(birth: "2015-01-01", today: "2021-09-01")
        #expect(IAFixtures.ymd(e.date) == "2021-09-01")
        #expect(e.measuredRecumbent == false)
        #expect(e.hasOedema == false)
        #expect(e.weightText == "")
        #expect(e.lengthOrHeightText == "")
        #expect(e.notes == "")
    }

    // Scenario: Hoje anterior ao nascimento
    @Test func newVisitDateNeverBeforeBirth() {
        let e = editor(birth: "2021-09-05", today: "2021-09-01")
        #expect(IAFixtures.ymd(e.date) == "2021-09-05")
    }

    // Scenario: Data anterior ao nascimento
    @Test func visitDateClampedToBirth() {
        let e = editor(birth: "2015-01-01")
        e.date = IAFixtures.date("2014-12-31")
        #expect(IAFixtures.ymd(e.date) == "2015-01-01")
    }

    // Scenario: Data de visita existente
    @Test func existingVisitDateIsFrozen() {
        let visit = VisitRecord(childID: 1, date: IAFixtures.date("2021-09-01"), weight: 21)
        let e = editor(existing: ["2021-09-01"], editing: visit)
        #expect(e.isDateEditable == false)
        e.date = IAFixtures.date("2021-09-02")
        #expect(IAFixtures.ymd(e.date) == "2021-09-01")
    }

    // Scenario: Data repetida
    @Test func duplicateVisitDateIsRejected() {
        let e = editor(existing: ["2021-09-01"], today: "2021-09-01")
        e.weightText = "21"
        #expect(throws: VisitValidationError.duplicateDate) { try e.makeVisit() }
    }

    // MARK: Peso e medida

    // Scenario: Peso com três casas
    @Test func visitWeightIsTruncatedToTwoPlaces() {
        let e = editor()
        e.weightText = "21,567"
        #expect(e.weight == num("21.56"))
    }

    // Scenario: Limites inclusivos aceitos
    @Test func visitMeasuresAcceptInclusiveLimits() {
        let e = editor()
        e.weightText = "275"
        e.lengthOrHeightText = "38"
        #expect(e.weight == 275)
        #expect(e.lengthOrHeight == 38)
        #expect(e.weightWarning == nil)
        #expect(e.lengthOrHeightWarning == nil)
    }

    // Scenario: Fora do limite fica fora do cálculo
    @Test func visitMeasureOutOfRangeIsExcludedFromCalculation() {
        let e = editor()
        e.weightText = "300"
        e.lengthOrHeightText = "110"
        #expect(e.weightOutcome == .outOfRange(num("0.9")...275))
        #expect(e.weight == nil)
        #expect(e.weightWarning != nil)
        #expect(e.bmiText == "N/D")
    }

    // Scenario: Peso fora do limite bloqueia a visita
    @Test func visitWithOutOfRangeWeightCannotBeSaved() {
        let e = editor()
        e.weightText = "300"
        e.lengthOrHeightText = "110"
        #expect(e.canSave == false)
        #expect(throws: VisitValidationError.invalidMeasurement) { try e.makeVisit() }
    }

    // Scenario: Medida ilegível bloqueia a visita
    @Test func visitWithInvalidLengthCannotBeSaved() {
        let e = editor()
        e.weightText = "20"
        e.lengthOrHeightText = "abc"
        #expect(e.lengthOrHeightOutcome == .invalid)
        #expect(e.canSave == false)
        #expect(throws: VisitValidationError.invalidMeasurement) { try e.makeVisit() }
    }

    // Scenario: Peso vazio é permitido
    @Test func visitWithEmptyWeightCanBeSaved() throws {
        let e = editor(today: "2021-09-01")
        e.weightText = ""
        e.lengthOrHeightText = "110"
        #expect(e.canSave == true)
        let visit = try e.makeVisit()
        #expect(IAFixtures.ymd(visit.date) == "2021-09-01")
        #expect(visit.weight == nil)
        #expect(visit.lengthOrHeight == 110)
    }

    // MARK: Deitado ou em pé

    // Scenario: Visita aos 10 meses
    @Test func measureChoiceEnabledUnderElevenMonths() {
        let e = editor(birth: "2020-01-01", today: "2020-11-01")
        #expect(e.isMeasureChoiceEnabled == true)
        e.measuredRecumbent = true
        #expect(e.measuredRecumbent == true)
    }

    // Scenario: Visita aos 11 meses com medida deitada marcada
    @Test func measureChoiceForcedStandingFromElevenMonths() {
        let e = editor(birth: "2020-01-01", today: "2020-11-01")
        e.measuredRecumbent = true
        e.date = IAFixtures.date("2020-12-01")
        #expect(e.isMeasureChoiceEnabled == false)
        #expect(e.measuredRecumbent == false)
    }

    // MARK: IMC

    // Scenario: IMC exibido
    @Test func visitBMIShownWithOneDecimal() {
        let e = editor(birth: "2015-01-01", today: "2021-09-01")
        e.weightText = "21,60"
        e.lengthOrHeightText = "118,92"
        #expect(e.bmiText == "15,3")
    }

    // Scenario: IMC com edema
    @Test func visitBMIHiddenWithOedema() {
        let e = editor(birth: "2015-01-01", today: "2021-09-01")
        e.weightText = "21,60"
        e.lengthOrHeightText = "118,92"
        e.hasOedema = true
        #expect(e.bmiText == "N/D")
    }
}
