import AnthroCore
import Foundation
import Testing

/// Cenários do resultado antropométrico de um registro do inquérito (change add-nutritional-survey).
@Suite("survey-management: resultado do registro")
struct SurveyRecordEvaluationScenarioTests {
    let engine: AnthroEngine

    init() throws {
        engine = try AnthroEngine.shared()
    }

    // Scenario: Nascimento desconhecido com idade digitada
    @Test func unknownBirthUsesTypedMonthsForResult() {
        var record = SurveyRecord(sex: .boy)
        record.ageInMonths = d("61.5")
        record.lengthOrHeight = 110
        let result = SurveyRecordEvaluation.result(record, engine: engine)
        #expect(result.ageInDays == 1872)
        #expect(result.ageRange == .reference)
    }

    // Scenario: Estatura na mediana pela idade em meses
    @Test func heightAtMedianByTypedMonthsHasZeroZ() {
        var record = SurveyRecord(sex: .boy)
        record.ageInMonths = 61
        record.lengthOrHeight = d("110.26")
        #expect(SurveyRecordEvaluation.result(record, engine: engine).lengthOrHeightForAge.zScore == 0)
    }

    // Scenario: Registro sem idade
    @Test func recordWithoutAgeHasUnknownRange() {
        var record = SurveyRecord(sex: .girl)
        record.dateOfBirth = localDate(2016, 1, 1)
        record.weight = 18
        let result = SurveyRecordEvaluation.result(record, engine: engine)
        #expect(result.ageRange == .unknown)
        #expect(result.weightForAge.zScore == nil)
        #expect(result.lengthOrHeightForAge.zScore == nil)
        #expect(result.bmiForAge.zScore == nil)
        #expect(result.weight == d("18.00"))
    }
}
