import Foundation

/// z-score LMS e percentil, como `AnthroComputation.CalculateZandP` e `Centile` (design D1 e D7).
public enum ZScore {
    /// `((Y/M)^L - 1) / (L S)`; com `restricted` (peso e IMC), além de 3 DP (para mais ou para menos) usa a extensão linear entre SD2 e SD3.
    /// Potências em `Double` convertidas com 15 dígitos; valor não finito devolve `nil`.
    public static func lms(_ y: Decimal, _ lms: LMS, restricted: Bool) -> Decimal? {
        let l = lms.l, m = lms.m, s = lms.s
        guard m != 0, let power = power(y / m, l) else { return nil }
        // Ramo L == 0 do original: devolve (Y/M)^0. Não ocorre nas tabelas da OMS.
        var z = l != 0 ? (power - 1) / (l * s) : power
        guard restricted else { return z }
        func sd(_ k: Decimal) -> Decimal? {
            guard l != 0, let factor = self.power(l * s * k + 1, 1 / l) else { return nil }
            return m * factor
        }
        if z < -3 {
            guard let sd3neg = sd(-3), let sd2neg = sd(-2) else { return nil }
            z = -3 - (sd3neg - y) / (sd2neg - sd3neg)
        }
        if z > 3 {
            guard let sd2 = sd(2), let sd3 = sd(3) else { return nil }
            z = 3 + (y - sd3) / (sd3 - sd2)
        }
        return z
    }

    /// Aproximação de Abramowitz e Stegun com os coeficientes truncados do original; `nil` para |z| > 3.
    public static func centile(_ z: Decimal) -> Decimal? {
        if z > 3 || z < -3 { return nil }
        let x = abs(z)
        let t = 1 / (Decimal(string: "0.2316419")! * x + 1)
        let td = ClinicalRounding.double(t)
        guard let t2 = ClinicalRounding.decimal15(pow(td, 2)),
              let t3 = ClinicalRounding.decimal15(pow(td, 3)),
              let t4 = ClinicalRounding.decimal15(pow(td, 4)),
              let t5 = ClinicalRounding.decimal15(pow(td, 5)),
              let root = ClinicalRounding.decimal15((Double.pi * 2.0).squareRoot()),
              let density = ClinicalRounding.decimal15(exp((0.0 - pow(ClinicalRounding.double(x), 2.0)) / 2.0))
        else { return nil }
        let polynomial = Decimal(string: "0.31938")! * t
            - Decimal(string: "0.356563782")! * t2
            + Decimal(string: "1.781477937")! * t3
            - Decimal(string: "1.82125")! * t4
            + Decimal(string: "1.330274429")! * t5
        var p = 1 - 1 / root * density * polynomial
        p = z > 0 ? p * 100 : 100 - p * 100
        guard p >= 0, p <= 100 else { return nil }
        return p
    }

    /// `(decimal)Math.Pow((double)base, (double)exponent)`.
    private static func power(_ base: Decimal, _ exponent: Decimal) -> Decimal? {
        ClinicalRounding.decimal15(pow(ClinicalRounding.double(base), ClinicalRounding.double(exponent)))
    }
}
