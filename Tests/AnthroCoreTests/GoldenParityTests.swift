import AnthroCore
import Foundation
import Testing

/// Paridade com as fixtures geradas pelos pacotes R da OMS (scripts/golden/generate_golden.R).
@Suite("anthropometric-computation: paridade")
struct GoldenParityTests {
    private struct GoldenCase {
        let id: Int
        let sex: Sex
        let ageDays: Int?
        let ageMonths: Decimal?
        let weight: Decimal
        let lengthOrHeight: Decimal
        let recumbent: Bool
        let oedema: Bool
        let expected: [Indicator: Decimal?]
    }

    private struct Comparison {
        var maxDifference: Decimal = 0
        var identical = 0
        var divergences: [String] = []
    }

    private func load(_ name: String) throws -> [GoldenCase] {
        let url = try #require(Bundle.module.url(forResource: name, withExtension: "csv", subdirectory: "Fixtures"))
        let lines = try String(contentsOf: url, encoding: .utf8)
            .split(whereSeparator: \.isNewline)
            .map(String.init)
            .filter { !$0.hasPrefix("#") }
        let header = lines[0].split(separator: ",").map(String.init)
        func optionalDecimal(_ text: String) -> Decimal? { text == "NA" ? nil : d(text) }
        return lines.dropFirst().map { line in
            let cells = line.split(separator: ",", omittingEmptySubsequences: false).map(String.init)
            let row = Dictionary(uniqueKeysWithValues: zip(header, cells))
            return GoldenCase(
                id: Int(row["id"]!)!,
                sex: row["sex"] == "1" ? .boy : .girl,
                ageDays: row["age_days"] == "NA" ? nil : Int(row["age_days"]!),
                ageMonths: optionalDecimal(row["age_months"]!),
                weight: d(row["weight"]!),
                lengthOrHeight: d(row["lenhei"]!),
                recumbent: row["measure"] == "l",
                oedema: row["oedema"] == "y",
                expected: [
                    .weightForAge: optionalDecimal(row["z_wfa"]!),
                    .lengthOrHeightForAge: optionalDecimal(row["z_lhfa"]!),
                    .bmiForAge: optionalDecimal(row["z_bfa"]!),
                ]
            )
        }
    }

    private func compare(_ cases: [GoldenCase], engine: AnthroEngine) -> Comparison {
        var comparison = Comparison()
        for golden in cases {
            let result = engine.result(
                ageInDays: golden.ageDays, ageInMonths: golden.ageMonths, sex: golden.sex,
                weight: golden.weight, lengthOrHeight: golden.lengthOrHeight,
                measuredRecumbent: golden.recumbent, hasOedema: golden.oedema
            )
            var caseIdentical = true
            for indicator in Indicator.allCases {
                let expected = golden.expected[indicator] ?? nil
                let actual = result.score(indicator).zScore
                switch (expected, actual) {
                case (nil, nil):
                    continue
                case let (e?, a?):
                    let difference = abs(e - a)
                    comparison.maxDifference = max(comparison.maxDifference, difference)
                    if difference != 0 {
                        caseIdentical = false
                        comparison.divergences.append("caso \(golden.id) \(indicator): R \(e), app \(a)")
                    }
                default:
                    caseIdentical = false
                    comparison.maxDifference = max(comparison.maxDifference, 99)
                    comparison.divergences.append("caso \(golden.id) \(indicator): R \(String(describing: expected)), app \(String(describing: actual))")
                }
            }
            if caseIdentical { comparison.identical += 1 }
        }
        return comparison
    }

    // Scenario: Fixture de padrões
    @Test func fixtureDePadroesBateComAnthro() throws {
        let cases = try load("golden-standards")
        try #require(cases.count == 600)
        let comparison = compare(cases, engine: try AnthroEngine.shared())
        #expect(comparison.maxDifference <= d("0.01"), "\(comparison.divergences.prefix(10))")
        #expect(comparison.identical >= 594, "\(comparison.divergences.count) divergências: \(comparison.divergences.prefix(10))")
    }

    // Scenario: Fixture de referência
    @Test func fixtureDeReferenciaBateComAnthroplus() throws {
        let cases = try load("golden-reference")
        try #require(cases.count == 600)
        let comparison = compare(cases, engine: try AnthroEngine.shared())
        #expect(comparison.maxDifference <= d("0.01"), "\(comparison.divergences.prefix(10))")
        #expect(comparison.identical >= 594, "\(comparison.divergences.count) divergências: \(comparison.divergences.prefix(10))")
    }
}
