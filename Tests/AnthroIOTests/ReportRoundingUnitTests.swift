import AnthroAnalysis
import AnthroCore
import AnthroIO
import Foundation
import Testing

@Suite("survey-reports: arredondamento do original (unitários)")
struct ReportRoundingUnitTests {
    /// Duas crianças com z -1.23 e -1.24: o original imprime média "-1,23".
    @Test func negativeTiedMeanIsPrintedLikeTheOriginal() throws {
        let records = ["-1.23", "-1.24"].map { AnalysisRecord(ageInMonths: 96, sex: .boy, zScores: [.lengthOrHeightForAge: d($0)]) }
        let report = try SurveyReportWriter.standardReport(records: records, options: .default, improvedClusterAnalysis: false)
        let total = try #require(ReportFixtures.table(report, set: ReportFixtures.set1, header: ReportFixtures.heightHeader)?.first)
        #expect(total.hasSuffix("\t-1,23\t0,01"))
    }
}
