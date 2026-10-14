import Foundation

public enum PlausibilityFlag: Sendable {
    case none
    case weightForAge
    case lengthOrHeightForAge
    case weightAndLengthOrHeightForAge
    case bmiForAge
}

/// Limites padrão de plausibilidade, como `IsFlaggedUsingDefault` e `GetFlagUsingDefault`
/// (os mesmos para padrões e referência: peso -6 a 5, estatura -6 a 6, IMC -5 a 5).
public enum Plausibility {
    static func bounds(_ indicator: Indicator) -> (min: Decimal, max: Decimal) {
        switch indicator {
        case .weightForAge: (-6, 5)
        case .lengthOrHeightForAge: (-6, 6)
        case .bmiForAge: (-5, 5)
        }
    }

    /// Implausível quando indefinido ou fora do intervalo do indicador.
    public static func isFlagged(_ indicator: Indicator, z: Decimal?) -> Bool {
        guard let z else { return true }
        let (min, max) = bounds(indicator)
        return z < min || z > max
    }

    /// Ordem do original: peso e estatura, peso, estatura, IMC, nenhum.
    public static func flag(for result: AnthropometricResult) -> PlausibilityFlag {
        let weight = isFlagged(.weightForAge, z: result.weightForAge.zScore)
        let length = isFlagged(.lengthOrHeightForAge, z: result.lengthOrHeightForAge.zScore)
        if weight && length { return .weightAndLengthOrHeightForAge }
        if weight { return .weightForAge }
        if length { return .lengthOrHeightForAge }
        if isFlagged(.bmiForAge, z: result.bmiForAge.zScore) { return .bmiForAge }
        return .none
    }
}
