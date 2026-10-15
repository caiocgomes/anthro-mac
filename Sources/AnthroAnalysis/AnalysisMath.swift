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

    /// `(double)decimal`, a mesma conversão do motor.
    static func double(_ value: Decimal) -> Double {
        ClinicalRounding.double(value)
    }

    /// O valor como o `decimal` do .NET o guarda: mantissa abaixo de $2^{96}$ e no máximo 28 casas, com arredondamento
    /// bancário. O `Decimal` do Swift guarda 38 dígitos, e a diferença muda a parada da grade da densidade.
    static func dotNetDecimal(_ value: Decimal) -> Decimal {
        let limit = Decimal(string: "79228162514264337593543950335")!
        var scale = 28
        while scale > 0, abs(value) * pow(Decimal(10), scale) > limit { scale -= 1 }
        var input = value
        var result = Decimal()
        NSDecimalRound(&result, &input, scale, .bankers)
        return result
    }

    /// `Round1` do original.
    static func round1(_ value: Decimal) -> Decimal {
        ClinicalRounding.round(value, places: 1) ?? value
    }
}
