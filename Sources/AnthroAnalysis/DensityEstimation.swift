import AnthroCore
import Foundation

/// Pontos de uma curva de densidade, com o tamanho ponderado da amostra.
public struct DensityCurve: Sendable, Equatable {
    public let x: [Double]
    public let y: [Double]
    public let sampleSize: Decimal

    public init(x: [Double], y: [Double], sampleSize: Decimal) {
        self.x = x
        self.y = y
        self.sampleSize = sampleSize
    }
}

/// A divisão por zero do original quando todos os z são iguais (largura zero).
public enum DensityError: Error, Equatable {
    case zeroBandwidth
}

/// `GetZScoresForIndicator`, `GetEpanechnikovDensityPoints` e `GetNormalCurvePoints`.
public enum DensityEstimation {
    public static func zScores(_ records: [AnalysisRecord], indicator: Indicator) -> (zScores: [Decimal], weights: [Decimal]) {
        ([], [])
    }

    public static func epanechnikov(zScores: [Decimal], weights: [Decimal]) throws -> DensityCurve {
        DensityCurve(x: [], y: [], sampleSize: 0)
    }

    public static func normalCurve(resolution: Int) -> DensityCurve {
        DensityCurve(x: [], y: [], sampleSize: 0)
    }
}
