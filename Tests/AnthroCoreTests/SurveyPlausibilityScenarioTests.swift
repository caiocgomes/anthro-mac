import AnthroCore
import Foundation
import Testing

/// Cenários de plausibilidade com os limites do inquérito (change add-nutritional-survey).
@Suite("survey-management: plausibilidade com os limites do inquérito")
struct SurveyPlausibilityScenarioTests {
    let engine: AnthroEngine

    init() throws {
        engine = try AnthroEngine.shared()
    }

    private func flagged(_ indicator: Indicator, _ result: AnthropometricResult,
                         _ options: SurveyOptions = literalSurveyOptions()) -> Bool {
        SurveyPlausibility.isFlagged(indicator, result: result, options: options)
    }

    // Scenario: Limite alterado nas opções
    @Test func surveyMaxBoundChangesWeightFlag() throws {
        let result = engine.at(days: 0, sex: .boy, weight: d("5.64"), height: nil)
        try #require(result.weightForAge.zScore == 4)
        var options = literalSurveyOptions()
        options.standardsMaxZ = [5, 6, 5]
        #expect(flagged(.weightForAge, result, options) == false)
        options.standardsMaxZ = [d("3.5"), 6, 5]
        #expect(flagged(.weightForAge, result, options) == true)
    }

    // Scenario: Faixa desconhecida
    @Test func unknownRangeFlagsAllIndicators() {
        let result = engine.at(days: nil, sex: .girl, weight: 18, height: 110)
        #expect(result.ageRange == .unknown)
        #expect(SurveyPlausibility.flag(result: result, options: literalSurveyOptions()) == .weightAndLengthOrHeightForAge)
        #expect(Indicator.allCases.allSatisfy { flagged($0, result) })
    }

    // Scenario: 109 meses sem peso
    @Test func weightForAgeAbove108MonthsIsNeverFlagged() {
        let result = engine.at(days: nil, months: 109, sex: .boy, weight: nil, height: 130)
        #expect(flagged(.weightForAge, result) == false)
        #expect(flagged(.bmiForAge, result) == true)
    }

    // Scenario: 108 meses sem peso
    @Test func weightForAgeAt108MonthsWithoutWeightIsFlagged() {
        let result = engine.at(days: nil, months: 108, sex: .boy, weight: nil, height: 130)
        #expect(flagged(.weightForAge, result) == true)
        #expect(SurveyPlausibility.flag(result: result, options: literalSurveyOptions()) == .weightForAge)
    }
}
