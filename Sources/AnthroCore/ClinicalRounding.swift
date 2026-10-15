import Foundation

/// Aritmética do original: arredondamento de `AnthroComputation.Round` e cast `(decimal)double` do .NET.
public enum ClinicalRounding {
    /// `AnthroComputation.Round`: `Sign(x) * Abs(Floor(x * 10^p + 0.5)) / 10^p`. O piso age sobre o valor com sinal,
    /// então o empate positivo vai para longe de zero e o negativo vai para zero (-2.345 dá -2.34); `nil` permanece `nil`.
    public static func round(_ x: Decimal?, places: Int) -> Decimal? {
        guard let x else { return nil }
        let scale = pow(Decimal(10), places)
        var shifted = x * scale + Decimal(string: "0.5")!
        var floored = Decimal()
        NSDecimalRound(&floored, &shifted, 0, .down)
        let magnitude = abs(floored) / scale
        return x < 0 ? -magnitude : magnitude
    }

    /// Conversão de `Double` para `Decimal` com 15 dígitos significativos (cast explícito do .NET Framework).
    /// Valor não finito devolve `nil`, como a `OverflowException` capturada em `CalculateZandP`.
    public static func decimal15(_ x: Double) -> Decimal? {
        guard x.isFinite else { return nil }
        return Decimal(string: String(format: "%.15g", x), locale: Locale(identifier: "en_US_POSIX"))
    }

    /// `Decimal` para `Double` como `(double)decimal` do .NET: o `Double` mais próximo. `NSDecimalNumber.doubleValue`
    /// erra alguns ULP, e numa raiz o limite do IC chegava a cruzar a casa decimal (24 em 72 dava 21,8 em vez de 21,7).
    public static func double(_ x: Decimal) -> Double {
        Double("\(x)") ?? NSDecimalNumber(decimal: x).doubleValue
    }
}
