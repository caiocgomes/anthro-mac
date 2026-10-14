import Foundation

/// Idade, resultado e IMC de um registro (`Record.AnthroResult`, `GetAgeInMonths`, `GetAgeInDays`, `GetBMI`, design D4).
/// Nascimento posterior à data da pesquisa, que no original lança exceção, vira idade desconhecida.
public enum SurveyRecordEvaluation {
    /// Idade digitada, senão a das datas; `nil` sem uma das datas.
    public static func ageInMonths(_ record: SurveyRecord) -> Decimal? {
        if let typed = record.ageInMonths { return typed }
        return datedAgeInDays(record).map(AgeMath.daysToMonths)
    }

    /// Idade digitada convertida por `MonthsToDays`, senão a diferença das datas.
    public static func ageInDays(_ record: SurveyRecord) -> Int? {
        if let typed = record.ageInMonths { return AgeMath.monthsToDays(typed) }
        return datedAgeInDays(record)
    }

    /// Pela idade em meses quando digitada, senão pelas datas; edema `nil` conta como sem edema.
    public static func result(_ record: SurveyRecord, engine: AnthroEngine) -> AnthropometricResult {
        let oedema = record.hasOedema ?? false
        if let typed = record.ageInMonths {
            return engine.result(ageInDays: nil, ageInMonths: typed, sex: record.sex, weight: record.weight,
                                 lengthOrHeight: record.lengthOrHeight, measuredRecumbent: record.measuredRecumbent,
                                 hasOedema: oedema)
        }
        let days = datedAgeInDays(record)
        return engine.result(ageInDays: days, ageInMonths: days.map(AgeMath.daysToMonths), sex: record.sex,
                             weight: record.weight, lengthOrHeight: record.lengthOrHeight,
                             measuredRecumbent: record.measuredRecumbent, hasOedema: oedema)
    }

    /// `GetBMI`: medida ajustada pela idade em dias, ou bruta sem idade, arredondado a 1 casa; `nil` sem peso, sem
    /// medida ou com edema.
    public static func displayedBMI(_ record: SurveyRecord) -> Decimal? {
        guard let weight = record.weight, let measure = record.lengthOrHeight, record.hasOedema != true else { return nil }
        let length = ageInDays(record).map {
            Anthropometry.adjustedLengthOrHeight(ageInDays: $0, value: measure, measuredRecumbent: record.measuredRecumbent).value
        } ?? measure
        return ClinicalRounding.round(Anthropometry.exactBMI(weight: weight, lengthOrHeight: length), places: 1)
    }

    private static func datedAgeInDays(_ record: SurveyRecord) -> Int? {
        guard let birth = record.dateOfBirth, let visit = record.visitDate else { return nil }
        return try? AgeMath.ageInDays(birth: birth, visit: visit)
    }
}
