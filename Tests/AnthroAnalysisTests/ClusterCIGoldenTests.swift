import AnthroAnalysis
import AnthroCore
import Foundation
import Testing

/// Paridade do IC por cluster com o pacote R `survey` (design D6).
@Suite("survey-analysis: paridade do IC por cluster")
struct ClusterCIGoldenTests {
    /// Registros de 96 meses do desenho: estatura com z -2.5 para caso e 0 para não caso, no cluster e com o fator dados.
    private func records(_ design: String) -> [AnalysisRecord] {
        design.split(separator: ";").enumerated().flatMap { cluster, records in
            records.split(separator: ",").map { item -> AnalysisRecord in
                let parts = item.split(separator: "@")
                let factor = parts.count > 1 ? d(String(parts[1])) : 1
                return AnalysisFixtures.record(z: parts[0] == "1" ? d("-2.5") : 0, indicators: [.lengthOrHeightForAge],
                                               cluster: cluster + 1, factor: factor)
            }
        }
    }

    /// Arredondamento a 1 casa, meio para longe de zero, como o relatório.
    private func round1(_ value: Double) -> Decimal {
        ClinicalRounding.round(Decimal(string: String(format: "%.6f", value))!, places: 1)!
    }

    // Scenario: Paridade com o pacote R survey
    @Test func paridadeDoIcPorClusterComPacoteSurvey() throws {
        let designs = ClusterCIGolden.designs
        #expect(designs.count == 200)
        var identical = 0
        var far: [String] = []
        for (index, design) in designs.enumerated() {
            let result = try AnalysisFixtures.compute(records(design.records), .lengthOrHeightForAge, improved: true)
            guard case .interval(let low, let high) = result.interval(.belowMinus2) else {
                far.append("desenho \(index): \(result.interval(.belowMinus2))")
                continue
            }
            let ours = (NSDecimalNumber(decimal: low).doubleValue, NSDecimalNumber(decimal: high).doubleValue)
            if abs(ours.0 - design.low) > 0.1 || abs(ours.1 - design.high) > 0.1 {
                far.append("desenho \(index): (\(low), \(high)) contra (\(design.low), \(design.high))")
            }
            if low == round1(design.low), high == round1(design.high) { identical += 1 }
        }
        #expect(far.isEmpty, "\(far.prefix(5))")
        #expect(identical >= 198)
    }
}
