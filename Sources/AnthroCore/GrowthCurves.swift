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

/// Séries das curvas de crescimento, como `GetIndicatorDataCurves` (design D5).
public enum GrowthCurves {
    public static let zScoreOffsets: [Decimal] = []
    public static let percentileOffsets: [Decimal] = []

    public static func points(_ indicator: Indicator, sex: Sex, kind: CurveKind, tables: GrowthReferenceTables) -> [CurvePoint] {
        []
    }
}
