@testable import AnthroAnalysis
import AnthroCore
import Foundation
import Testing

@Suite("survey-analysis: laço interno das prevalências (unitários)")
struct PrevalenceUnitTests {
    private typealias F = AnalysisFixtures

    @Test func fractionalFactorsAreSummed() throws {
        let result = try F.compute([F.record(z: d("-2.5"), factor: d("0.5")), F.record(z: 0, factor: d("1.5"))], .bmiForAge)
        #expect(result.count == 2)
        #expect(result.prevalence(.belowMinus2) == 25)
        #expect(result.mean == d("-0.625"))
    }

    /// D14a: N - 1 = 0 com soma de quadrados positiva (o original estoura ao converter infinito para `decimal`).
    @Test func infiniteDeviationBecomesNil() throws {
        let result = try F.compute([F.record(z: -1, factor: d("0.5")), F.record(z: 1, factor: d("0.5"))], .bmiForAge)
        #expect(result.count == 1)
        #expect(result.standardDeviation == nil)
    }

    /// Só edema: N = 0 deixa as prevalências `nil` (o original testa `PopCount > 0`), mas o IC usa N + N com edema.
    @Test func onlyOedemaKeepsPrevalencesNilButComputesTheInterval() throws {
        let result = try F.compute([F.record(z: nil, oedema: true), F.record(z: nil, oedema: true)], .weightForAge)
        #expect(result.count == 0)
        #expect(result.oedemaCount == 2)
        #expect(result.prevalence(.belowMinus2) == nil)
        #expect(result.interval(.belowMinus2) == .interval(low: d("75"), high: 100))
    }

    @Test func totalExcludesAgesOutsideElevenTo228Months() throws {
        let result = try F.compute([F.record(age: 10, z: -3), F.record(age: d("228.5"), z: 0), F.record(z: 1)], .bmiForAge)
        #expect(result.count == 1)
        #expect(result.mean == 1)
    }

    @Test func groupAnalysisDropsAgesOutsideTheBoundaries() throws {
        let options = F.options(boundaries: [61, 120])
        let records = [F.record(age: 60, z: 0), F.record(age: d("120.9"), z: 0), F.record(age: 121, z: 0), F.record(age: nil, z: 0)]
        let result = try PrevalenceCalculator.compute(records, indicator: .bmiForAge, options: options, analysisType: .standard,
                                                      isTotal: false, byCluster: false, improvedClusterAnalysis: false)
        #expect(result.count == 1)
    }

    @Test func globalDatabaseDropsHeightsOutsideTheLimits() throws {
        let records = [F.record(z: 0, height: d("231")), F.record(z: 0, height: d("37.9")), F.record(z: 0, height: 120)]
        #expect(try F.compute(records, .bmiForAge, type: .whoGlobalDatabase).count == 1)
    }

    @Test func truncationAndDoubleHelpersFollowTheDotNetCasts() {
        #expect(AnalysisMath.truncated(d("108.99")) == 108)
        #expect(AnalysisMath.truncated(d("-1.5")) == -1)
        #expect(AnalysisMath.double(d("0.1")) == 0.1)
    }
}
