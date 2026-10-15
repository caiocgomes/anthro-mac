import AnthroAnalysis
import AnthroCore
import AnthroFeatures
import Foundation
import Testing

/// Consumo de `SurveyPlausibility` pela entrada da análise (change add-survey-analysis).
@Suite("survey-analysis: limites do inquérito na entrada")
struct SurveyAnalysisInputTests {
    /// Dois meninos com idade informada de 96 meses e 130 cm: 26.60 kg dão IMC com z 0.00 e 33.25 kg, z 2.00.
    private func boys() -> [SurveyRecord] {
        ["26.60", "33.25"].map { weight in
            var record = SurveyRecord(sex: .boy)
            record.ageInMonths = 96
            record.lengthOrHeight = 130
            record.weight = num(weight)
            record.measuredRecumbent = false
            record.hasOedema = false
            return record
        }
    }

    private func bmi(_ options: SurveyOptions) throws -> PrevalenceResult {
        let records = SurveyAnalysisInput.records(from: boys(), options: options, engine: try AnthroEngine.shared())
        return try PrevalenceCalculator.compute(records, indicator: .bmiForAge, options: options, analysisType: .standard,
                                                isTotal: true, byCluster: false, improvedClusterAnalysis: false)
    }

    // Scenario: Limite de IMC do inquérito exclui registro
    @Test func limiteDeImcDoInqueritoExcluiRegistro() throws {
        let standard = try bmi(.default)
        #expect(standard.count == 2)
        #expect(standard.prevalence(.abovePlus1) == 50)
        var strict = SurveyOptions.default
        strict.referenceMaxZ[Indicator.bmiForAge.rawValue] = 1
        let limited = try bmi(strict)
        #expect(limited.count == 1)
        #expect(limited.prevalence(.abovePlus1) == 0)
    }

    // Scenario: Limite dos padrões não afeta a referência
    @Test func limiteDosPadroesNaoAfetaAReferencia() throws {
        var options = SurveyOptions.default
        options.standardsMaxZ[Indicator.bmiForAge.rawValue] = 1
        let result = try bmi(options)
        #expect(result.count == 2)
        #expect(result.prevalence(.abovePlus1) == 50)
    }
}
