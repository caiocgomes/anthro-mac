import AnthroCore
import Foundation

/// Resultados da visita como `Visit.AnthroResult` e `Visit.GetBMI` (design D11).
public enum ExchangeResultsCalculator {
    public static func results(engine: AnthroEngine, sex: Sex, dateOfBirth: Date, visit: ExchangeVisit) -> ExchangeResults {
        ExchangeResults(weightForAgeZ: nil, lengthOrHeightForAgeZ: nil, bmiForAgeZ: nil, bmi: nil)
    }
}
