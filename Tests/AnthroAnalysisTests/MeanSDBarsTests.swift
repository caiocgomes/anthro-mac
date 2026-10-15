import AnthroAnalysis
import AnthroCore
import Foundation
import Testing

/// Cenários das barras de média e DP por faixa etária e por cluster (change add-survey-analysis).
@Suite("survey-graphs: barras de média e DP")
struct MeanSDBarsTests {
    private typealias F = AnalysisFixtures

    private func rounded(_ value: Double?, _ places: Int) -> Double? {
        value.map { ($0 * pow(10, Double(places))).rounded() / pow(10, Double(places)) }
    }

    // Scenario: Duas faixas com médias de sinais opostos
    @Test func duasFaixasComMediasDeSinaisOpostos() throws {
        let records = [F.record(z: -1), F.record(z: -2), F.record(age: 108, z: 1), F.record(age: 108, z: 2)]
        let bars = MeanSDBars.byAgeGroup(records, indicator: .bmiForAge, options: .default)
        let negative = try #require(bars.first { $0.label == "96-107" })
        #expect(negative.barRange == -1.5...0)
        #expect(rounded(negative.whiskerEnd, 4) == -2.2071)
        #expect(negative.count == 2)
        #expect(!negative.isPositive)
        let positive = try #require(bars.first { $0.label == "108-119" })
        #expect(positive.barRange == 0...1.5)
        #expect(rounded(positive.whiskerEnd, 4) == 2.2071)
        #expect(positive.isPositive)
    }

    // Scenario: Faixa vazia e N fracionado
    @Test func faixaVaziaENFracionado() throws {
        let bars = MeanSDBars.byAgeGroup([F.record(z: 1, factor: d("1.5"))], indicator: .bmiForAge, options: .default)
        let filled = try #require(bars.first { $0.label == "96-107" })
        #expect(filled.count == 2)
        let empty = try #require(bars.first { $0.label == "228-228" })
        #expect(empty.mean == nil)
        #expect(empty.whiskerEnd == nil)
        #expect(empty.count == 0)
    }

    // Scenario: Dois clusters
    @Test func barrasDeDoisClusters() {
        let records = [F.record(z: 1, cluster: 5, factor: d("1.5")), F.record(z: -1, cluster: 2), F.record(z: 0, cluster: 2)]
        let bars = MeanSDBars.byCluster(records, indicator: .bmiForAge, options: .default)
        #expect(bars.map(\.label) == ["2", "5"])
        #expect(bars.map(\.count) == [2, 1])
    }
}
