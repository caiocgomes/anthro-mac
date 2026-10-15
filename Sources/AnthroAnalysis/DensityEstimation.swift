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
    /// z com os limites padrão de plausibilidade do AnthroCore (não os do inquérito) e o fator de cada registro.
    public static func zScores(_ records: [AnalysisRecord], indicator: Indicator) -> (zScores: [Decimal], weights: [Decimal]) {
        var zScores: [Decimal] = []
        var weights: [Decimal] = []
        for record in records {
            guard let z = record.zScores[indicator], !Plausibility.isFlagged(indicator, z: z) else { continue }
            zScores.append(z)
            weights.append(record.weightingFactor)
        }
        return (zScores, weights)
    }

    /// Núcleo de Epanechnikov com largura $0.9\,s/n^{0.2}$ (média e $s$ sem ponderação), fator não positivo valendo 1 e
    /// grade de -5 em passos de $10/\min(W, 50)$ enquanto x < 5 + passo, em `Decimal` como o original.
    public static func epanechnikov(zScores: [Decimal], weights: [Decimal]) throws -> DensityCurve {
        let factors = weights.map { $0 > 0 ? $0 : 1 }
        let size = factors.reduce(0, +)
        guard size != 0, size != 1 else { return DensityCurve(x: [], y: [], sampleSize: size) }
        // Com um só z e fator acima de 1, o original divide por n - 1 = 0: a mesma exceção da largura zero.
        guard zScores.count > 1 else { throw DensityError.zeroBandwidth }
        let mean = zScores.reduce(0, +) / Decimal(zScores.count)
        var squares: Decimal = 0
        for z in zScores { squares += decimal15(pow(AnalysisMath.double(z - mean), 2)) }
        let deviation = decimal15(AnalysisMath.double(squares / Decimal(zScores.count - 1)).squareRoot())
        let bandwidth = Decimal(string: "0.9")! * deviation / decimal15(pow(Double(zScores.count), 0.2))
        guard bandwidth != 0 else { throw DensityError.zeroBandwidth }
        let step = 10 / min(size, 50)
        let rootFive = decimal15(5.0.squareRoot())
        var xs: [Double] = []
        var ys: [Double] = []
        var x: Decimal = -5
        while x < 5 + step {
            var sum: Decimal = 0
            for (z, factor) in zip(zScores, factors) {
                let u = (x - z) / bandwidth
                if abs(u) < rootFive {
                    sum += factor * (Decimal(string: "0.75")! * (1 - Decimal(string: "0.2")! * decimal15(pow(AnalysisMath.double(u), 2)))
                        / rootFive)
                }
            }
            ys.append(AnalysisMath.double(sum / (size * bandwidth)))
            xs.append(AnalysisMath.double(x))
            x += step
        }
        return DensityCurve(x: xs, y: ys, sampleSize: size)
    }

    /// Normal padrão com a constante de Euler truncada do original e passo `Double` acumulado de -5 enquanto x < 5.
    public static func normalCurve(resolution: Int) -> DensityCurve {
        let step = 10.0 / Double(resolution)
        var xs: [Double] = []
        var ys: [Double] = []
        var x = -5.0
        while x < 5.0 {
            ys.append(pow(2.718281828, -x * x / 2) / (Double.pi * 2).squareRoot())
            xs.append(x)
            x += step
        }
        return DensityCurve(x: xs, y: ys, sampleSize: 0)
    }

    /// `(decimal)double`; os valores daqui são sempre finitos.
    private static func decimal15(_ value: Double) -> Decimal {
        ClinicalRounding.decimal15(value) ?? 0
    }
}
