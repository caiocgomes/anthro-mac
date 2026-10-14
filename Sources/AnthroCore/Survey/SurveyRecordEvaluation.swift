import Foundation

/// Idade, resultado e IMC de um registro (`Record.AnthroResult`, `GetAgeInMonths`, `GetAgeInDays`, `GetBMI`).
public enum SurveyRecordEvaluation {
    public static func ageInMonths(_ record: SurveyRecord) -> Decimal? {
        nil
    }

    public static func ageInDays(_ record: SurveyRecord) -> Int? {
        nil
    }

    public static func result(_ record: SurveyRecord, engine: AnthroEngine) -> AnthropometricResult {
        engine.result(ageInDays: nil, ageInMonths: nil, sex: nil, weight: nil, lengthOrHeight: nil,
                      measuredRecumbent: false, hasOedema: false)
    }

    public static func displayedBMI(_ record: SurveyRecord) -> Decimal? {
        nil
    }
}
