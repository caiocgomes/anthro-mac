import AnthroCore
import Foundation

/// Resultados da visita como `Visit.AnthroResult` e `Visit.GetBMI` (design D11): z-scores do motor pelas datas, e IMC
/// com a medida ajustada pela idade em qualquer faixa, arredondado a 1 casa, só com peso, medida e sem edema.
public enum ExchangeResultsCalculator {
    public static func results(engine: AnthroEngine, sex: Sex, dateOfBirth: Date, visit: ExchangeVisit) -> ExchangeResults {
        guard let result = try? engine.result(dateOfBirth: dateOfBirth, dateOfVisit: visit.date, sex: sex,
                                              weight: visit.weight, lengthOrHeight: visit.height,
                                              measuredRecumbent: visit.isRecumbent, hasOedema: visit.hasOedema),
              let ageInDays = try? AgeMath.ageInDays(birth: dateOfBirth, visit: visit.date)
        else { return ExchangeResults(weightForAgeZ: nil, lengthOrHeightForAgeZ: nil, bmiForAgeZ: nil, bmi: nil) }
        var bmi: Decimal?
        if let weight = visit.weight, let height = visit.height, !visit.hasOedema {
            let adjusted = Anthropometry.adjustedLengthOrHeight(ageInDays: ageInDays, value: height,
                                                                measuredRecumbent: visit.isRecumbent).value
            bmi = ClinicalRounding.round(Anthropometry.exactBMI(weight: weight, lengthOrHeight: adjusted), places: 1)
        }
        return ExchangeResults(weightForAgeZ: result.score(.weightForAge).zScore,
                               lengthOrHeightForAgeZ: result.score(.lengthOrHeightForAge).zScore,
                               bmiForAgeZ: result.score(.bmiForAge).zScore, bmi: bmi)
    }
}
