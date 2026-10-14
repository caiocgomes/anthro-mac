import Foundation

/// Ponto de uma série de curvas: x em meses e um valor por linha (DP ou percentil), em ordem crescente.
public struct CurvePoint: Sendable, Equatable {
    public let xMonths: Double
    public let values: [Double]

    public init(xMonths: Double, values: [Double]) {
        self.xMonths = xMonths
        self.values = values
    }
}

public enum CurveKind: Sendable {
    case zScore
    case percentile
}

/// Séries das curvas de crescimento, como `GetIndicatorDataCurves` e `GetStdOrRefCurvePointArrays` (design D5):
/// padrões a cada 4 dias (x = dias / 30.4375), seguidos da referência mensal até 120 meses (peso) ou 228 meses.
public enum GrowthCurves {
    /// Linhas de -3 a +3 DP.
    public static let zScoreOffsets: [Decimal] = [-3, -2, -1, 0, 1, 2, 3]
    /// Percentis 3, 15, 50, 85 e 97.
    public static let percentileOffsets: [Decimal] = [
        Decimal(string: "-1.88")!, Decimal(string: "-1.036")!, 0, Decimal(string: "1.036")!, Decimal(string: "1.88")!,
    ]

    public static func points(_ indicator: Indicator, sex: Sex, kind: CurveKind, tables: GrowthReferenceTables) -> [CurvePoint] {
        let offsets = (kind == .zScore ? zScoreOffsets : percentileOffsets).map(ClinicalRounding.double)
        func values(_ lms: LMS) -> [Double] {
            let l = ClinicalRounding.double(lms.l), m = ClinicalRounding.double(lms.m), s = ClinicalRounding.double(lms.s)
            return offsets.map { k in m * pow(1 + l * s * k, 1 / l) }
        }
        var points: [CurvePoint] = []
        for day in stride(from: 0, through: 1856, by: 4) {
            guard let lms = tables.standardsLMS(indicator, sex: sex, ageInDays: day) else { continue }
            points.append(CurvePoint(xMonths: Double(day) / 30.4375, values: values(lms)))
        }
        let lastMonth = indicator == .weightForAge ? 120 : 228
        for month in 60...lastMonth {
            guard let lms = tables.referenceLMS(indicator, sex: sex, ageInMonths: Decimal(month)) else { continue }
            points.append(CurvePoint(xMonths: Double(month), values: values(lms)))
        }
        return points
    }
}
