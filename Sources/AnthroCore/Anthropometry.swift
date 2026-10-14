import Foundation

/// Medida ajustada e IMC, como `GetAdjustedLengthOrHeight` e `ComputeExactBMI`.
public enum Anthropometry {
    private static let correction = Decimal(string: "0.7")!

    /// Abaixo de 731 dias é comprimento (em pé soma 0,7 cm); a partir de 731 dias é altura (deitado subtrai 0,7 cm).
    public static func adjustedLengthOrHeight(ageInDays: Int, value: Decimal, measuredRecumbent: Bool) -> (value: Decimal, isLength: Bool) {
        if ageInDays < 0 { return (value, measuredRecumbent) }
        if ageInDays < 731 {
            return (measuredRecumbent ? value : value + correction, true)
        }
        return (measuredRecumbent ? value - correction : value, false)
    }

    /// `peso / (medida / 100)^2`, com a potência em `Double` como no original; `nil` sem medidas positivas ou com IMC maior ou igual a 1000.
    public static func exactBMI(weight: Decimal, lengthOrHeight: Decimal) -> Decimal? {
        guard weight > 0, lengthOrHeight > 0 else { return nil }
        let meters = lengthOrHeight / 100
        guard let squared = ClinicalRounding.decimal15(pow(ClinicalRounding.double(meters), 2)) else { return nil }
        let bmi = weight / squared
        return bmi < 1000 ? bmi : nil
    }
}
