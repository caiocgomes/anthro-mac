import AnthroAnalysis
import AnthroCore
import Foundation
import Testing

/// Cenários da curva normal e da densidade de Epanechnikov (change add-survey-analysis).
@Suite("survey-graphs: densidade")
struct DensityEstimationTests {
    private typealias F = AnalysisFixtures

    private func rounded(_ value: Double, _ places: Int) -> Double {
        (value * pow(10, Double(places))).rounded() / pow(10, Double(places))
    }

    /// y no ponto da grade mais próximo de `x`.
    private func y(_ curve: DensityCurve, at x: Double) throws -> Double {
        let index = try #require(curve.x.indices.min { abs(curve.x[$0] - x) < abs(curve.x[$1] - x) })
        return curve.y[index]
    }

    // Scenario: Resolução 500
    @Test func curvaNormalComResolucao500() throws {
        let curve = DensityEstimation.normalCurve(resolution: 500)
        #expect(curve.x.count == 501)
        #expect(curve.y.count == 501)
        try #require(!curve.x.isEmpty)
        #expect(curve.x[0] == -5)
        #expect(abs(curve.y[0] - 1.48671951787e-6) < 1e-15)
        #expect(rounded(curve.y.max() ?? 0, 8) == 0.39894228)
    }

    // Scenario: Resolução pequena
    @Test func curvaNormalComResolucaoPequena() {
        let curve = DensityEstimation.normalCurve(resolution: 10)
        #expect(curve.x.count == 10)
        #expect(curve.x.last == 4)
    }

    // Scenario: Doze z com tamanho ponderado 50
    @Test func dozeZComTamanhoPonderado50() throws {
        let curve = try DensityEstimation.epanechnikov(zScores: F.twelveZ, weights: Array(repeating: 4, count: 10) + [5, 5])
        #expect(curve.sampleSize == 50)
        #expect(curve.x.count == 51)
        #expect(curve.x.first == -5)
        #expect(curve.x.last.map { rounded($0, 10) } == 5)
        #expect(rounded(try y(curve, at: 0), 6) == 0.301381)
        #expect(try y(curve, at: -5) == 0)
    }

    // Scenario: Doze z com fator 1
    @Test func dozeZComFator1() throws {
        let curve = try DensityEstimation.epanechnikov(zScores: F.twelveZ, weights: Array(repeating: 1, count: 12))
        #expect(curve.sampleSize == 12)
        #expect(curve.x.count == 14)
        #expect(curve.x.last.map { rounded($0, 4) } == 5.8333)
        #expect(rounded(try y(curve, at: 0), 6) == 0.292832)
    }

    // Scenario: Fatores zero contam como 1
    @Test func fatoresZeroContamComoUm() throws {
        let curve = try DensityEstimation.epanechnikov(zScores: F.twelveZ, weights: Array(repeating: 0, count: 12))
        #expect(curve.sampleSize == 12)
        #expect(curve.x.count == 14)
    }

    // Scenario: Um único z
    @Test func umUnicoZDaCurvaVazia() throws {
        let curve = try DensityEstimation.epanechnikov(zScores: [d("0.3")], weights: [1])
        #expect(curve.x.isEmpty)
        #expect(curve.sampleSize == 1)
    }

    // Scenario: Todos os z iguais
    @Test func todosOsZIguaisLancamLarguraZero() {
        #expect(throws: DensityError.zeroBandwidth) {
            _ = try DensityEstimation.epanechnikov(zScores: Array(repeating: d("0.5"), count: 12),
                                                   weights: Array(repeating: 1, count: 12))
        }
    }

    // Scenario: Limite padrão de plausibilidade
    @Test func limitePadraoDePlausibilidadeNaDensidade() {
        let records = [F.record(z: d("5.5")), F.record(z: d("4.9"))]
        #expect(DensityEstimation.zScores(records, indicator: .bmiForAge).zScores == [d("4.9")])
    }
}
