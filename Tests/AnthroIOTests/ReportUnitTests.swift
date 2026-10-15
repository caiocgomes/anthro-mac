import AnthroAnalysis
import AnthroCore
import AnthroIO
import Foundation
import Testing

@Suite("survey-reports: laço interno do relatório (unitários)")
struct ReportUnitTests {
    private typealias R = ReportFixtures

    private func options(_ boundaries: [Int]) -> SurveyOptions {
        var options = SurveyOptions.default
        options.ageGroupBoundaries = boundaries
        return options
    }

    /// Sem o limite 61 nas faixas, o rótulo do total usa o índice 0, como o original; a população continua 61 a 228.
    @Test func totalLabelUsesTheIndexOf61OrZero() throws {
        let without61 = try SurveyReportWriter.standardReport(records: R.tenChildren(), options: options([0, 60, 120, 228]),
                                                              improvedClusterAnalysis: false)
        #expect(R.table(without61, set: R.set1, header: R.heightHeader)?.first?.hasPrefix("Total (0-19)\t(0-228)\t10\t") == true)
        let with61 = try SurveyReportWriter.standardReport(records: R.tenChildren(), options: options([0, 61, 120, 228]),
                                                           improvedClusterAnalysis: false)
        #expect(R.table(with61, set: R.set1, header: R.heightHeader)?.first?.hasPrefix("Total (5-19)\t(61-228)\t10\t") == true)
    }

    /// A última faixa do inquérito termina no último limite; as outras, no seguinte menos 1.
    @Test func lastSurveyGroupEndsAtTheLastBoundary() throws {
        let report = try SurveyReportWriter.standardReport(records: R.tenChildren(), options: options([61, 96, 120]),
                                                           improvedClusterAnalysis: false)
        let rows = try #require(R.table(report, set: R.set1, header: R.heightHeader))
        #expect(rows.contains { $0.hasPrefix("5\t(61-95)\t") })
        #expect(rows.contains { $0.hasPrefix("8\t(96-120)\t10\t") })
    }

    @Test func fractionalCountsAreRoundedAndDecimalsLoseTrailingZeros() throws {
        let records = [AnalysisRecord(ageInMonths: 96, sex: .boy, weightingFactor: d("1.5"), zScores: [.lengthOrHeightForAge: 1]),
                       AnalysisRecord(ageInMonths: 96, sex: .boy, weightingFactor: 1, zScores: [.lengthOrHeightForAge: 0])]
        let report = try SurveyReportWriter.standardReport(records: records, options: .default, improvedClusterAnalysis: false)
        let total = try #require(R.table(report, set: R.set1, header: R.heightHeader)?.first)
        #expect(total.hasPrefix("Total (5-19)\t(61-228)\t3\t0\t"))
        #expect(total.hasSuffix("\t0,6\t0,63"))
        #expect(ReportFormat.number(d("2.10")) == "2,1")
        #expect(ReportFormat.number(d("-0.21")) == "-0,21")
        #expect(ReportFormat.interval(.notComputed) == "(-, -)")
    }

    @Test func textEndsEveryLineWithCRLF() {
        let report = SurveyReport(kind: .estimates, lines: ["a", "", "b\tc"])
        #expect(report.text == "a\r\n\r\nb\tc\r\n")
        #expect(report.table == [["a"], [""], ["b", "c"]])
    }
}
