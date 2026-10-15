import AnthroCore
import Foundation

/// Casts do .NET usados na análise (o `AnthroCore` os guarda como internos).
enum AnalysisMath {
    /// Parte inteira, como `(int)decimal`.
    static func truncated(_ value: Decimal) -> Int {
        var input = value
        var result = Decimal()
        NSDecimalRound(&result, &input, 0, value < 0 ? .up : .down)
        return NSDecimalNumber(decimal: result).intValue
    }

    /// `(double)decimal`.
    static func double(_ value: Decimal) -> Double {
        NSDecimalNumber(decimal: value).doubleValue
    }

    /// `Round1` do original.
    static func round1(_ value: Decimal) -> Decimal {
        ClinicalRounding.round(value, places: 1) ?? value
    }
}
