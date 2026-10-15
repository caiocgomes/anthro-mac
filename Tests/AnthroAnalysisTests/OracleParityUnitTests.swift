import AnthroAnalysis
import AnthroCore
import Foundation
import Testing

/// Casos achados pela revisão com o código do original compilado em .NET (oráculo em `rr9/net` do scratchpad).
@Suite("survey-analysis: paridade com o oráculo .NET (unitários)")
struct OracleParityUnitTests {
    private typealias F = AnalysisFixtures

    /// `(double)decimal` do .NET é o double mais próximo; `NSDecimalNumber.doubleValue` erra alguns ULP e, na raiz, o
    /// limite cruza a casa decimal.
    @Test func simpleIntervalMatchesTheOracleAtTheDecimalBoundary() {
        #expect(ConfidenceIntervals.simple(portion: 24, total: 72) == .interval(low: d("21.7"), high: d("44.9")))
        #expect(ConfidenceIntervals.simple(portion: 48, total: 72) == .interval(low: d("55.1"), high: d("78.3")))
    }

    /// Contagem de pontos da grade da densidade para tamanhos ponderados de 2 a 50, como o `decimal` de 96 bits do .NET.
    @Test func densityGridCountsMatchTheDotNetDecimal() throws {
        let expected = [2: 3, 3: 4, 4: 5, 5: 6, 6: 7, 7: 8, 8: 9, 9: 11, 10: 11, 11: 12, 12: 14, 13: 15, 14: 15, 15: 16, 16: 17,
                        17: 18, 18: 19, 19: 20, 20: 21, 21: 22, 22: 24, 23: 24, 24: 25, 25: 26, 26: 28, 27: 28, 28: 30, 29: 31,
                        30: 32, 31: 32, 32: 33, 33: 35, 34: 35, 35: 37, 36: 37, 37: 38, 38: 40, 39: 41, 40: 41, 41: 42, 42: 43,
                        43: 45, 44: 45, 45: 47, 46: 48, 47: 49, 48: 50, 49: 50, 50: 51]
        var wrong: [String] = []
        for (size, count) in expected.sorted(by: { $0.key < $1.key }) {
            let zScores = (0..<size).map { Decimal($0 % 7) - 3 }
            let curve = try DensityEstimation.epanechnikov(zScores: zScores, weights: Array(repeating: 1, count: size))
            if curve.x.count != count { wrong.append("\(size): \(curve.x.count) em vez de \(count)") }
        }
        #expect(wrong.isEmpty, "\(wrong)")
    }

    /// Média negativa em empate: -1.235 sai -1.23 no original (`Floor` sobre o valor com sinal).
    @Test func negativeTiedMeanRoundsUpLikeTheOriginal() throws {
        let result = try F.compute([F.record(z: d("-1.23")), F.record(z: d("-1.24"))], .bmiForAge)
        #expect(result.mean == d("-1.235"))
        #expect(ClinicalRounding.round(result.mean, places: 2) == d("-1.23"))
    }
}
