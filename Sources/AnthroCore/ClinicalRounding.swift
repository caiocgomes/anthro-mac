import Foundation

/// Aritmética do original: arredondamento de `AnthroComputation.Round` e cast `(decimal)double` do .NET.
public enum ClinicalRounding {
    /// `sign(x) * floor(|x| * 10^p + 0.5) / 10^p`, meio para longe de zero; `nil` permanece `nil`.
    public static func round(_ x: Decimal?, places: Int) -> Decimal? {
        guard let x else { return nil }
        let scale = pow(Decimal(10), places)
        var shifted = abs(x) * scale + Decimal(string: "0.5")!
        var floored = Decimal()
        NSDecimalRound(&floored, &shifted, 0, .down)
        let magnitude = floored / scale
        return x < 0 ? -magnitude : magnitude
    }

    /// Conversão de `Double` para `Decimal` com 15 dígitos significativos (cast explícito do .NET Framework).
    /// Valor não finito devolve `nil`, como a `OverflowException` capturada em `CalculateZandP`.
    public static func decimal15(_ x: Double) -> Decimal? {
        guard x.isFinite else { return nil }
        return Decimal(string: String(format: "%.15g", x), locale: Locale(identifier: "en_US_POSIX"))
    }

    /// `Decimal` para `Double`, como `(double)decimal` do .NET.
    static func double(_ x: Decimal) -> Double {
        NSDecimalNumber(decimal: x).doubleValue
    }
}
