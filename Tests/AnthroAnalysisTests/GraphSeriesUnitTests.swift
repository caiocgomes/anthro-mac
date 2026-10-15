import AnthroAnalysis
import AnthroCore
import Foundation
import Testing

@Suite("survey-graphs: séries (unitários)")
struct GraphSeriesUnitTests {
    private typealias F = AnalysisFixtures

    /// Um só z com fator 3: o original divide por n - 1 = 0, a mesma exceção capturada da largura zero.
    @Test func singleZWithLargeFactorThrowsLikeZeroBandwidth() {
        #expect(throws: DensityError.zeroBandwidth) { _ = try DensityEstimation.epanechnikov(zScores: [1], weights: [3]) }
        #expect(throws: Never.self) { _ = try DensityEstimation.epanechnikov(zScores: [], weights: []) }
    }

    @Test func densityIntegratesToAboutOne() throws {
        let curve = try DensityEstimation.epanechnikov(zScores: F.twelveZ, weights: Array(repeating: 4, count: 10) + [5, 5])
        let area = zip(curve.x.dropFirst(), zip(curve.y, curve.y.dropFirst())).enumerated().reduce(0.0) { sum, item in
            let width = item.element.0 - curve.x[item.offset]
            return sum + width * (item.element.1.0 + item.element.1.1) / 2
        }
        #expect(abs(area - 1) < 0.01)
    }

    @Test func barsHavePositionsLabelsAndZeroMeanIsNotPositive() throws {
        let bars = MeanSDBars.byAgeGroup([F.record(z: 0)], indicator: .bmiForAge, options: .default)
        #expect(bars.count == 21)
        #expect(bars.first?.label == "0-5")
        #expect(bars.map(\.position) == Array(1...21))
        let zero = try #require(bars.first { $0.label == "96-107" })
        #expect(zero.mean == 0)
        #expect(zero.barRange == 0...0)
        #expect(!zero.isPositive)
        #expect(zero.whiskerEnd == 0)
        let clusters = MeanSDBars.byCluster([F.record(z: 1, cluster: 3), F.record(z: 2, cluster: 1)], indicator: .bmiForAge,
                                            options: .default)
        #expect(clusters.map(\.position) == [0, 1])
        #expect(clusters.map(\.label) == ["1", "3"])
    }

    @Test func normalCurvePeaksAtZero() throws {
        let curve = DensityEstimation.normalCurve(resolution: 10)
        let peak = try #require(curve.y.indices.max { curve.y[$0] < curve.y[$1] })
        #expect(curve.x[peak] == 0)
    }
}
