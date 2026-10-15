import AnthroAnalysis
import AnthroCore
import Foundation

/// `NSMain.CreateExcelReport`, `GetReportForIndicator` e `GetWHOReport` (design D8 a D11).
public enum SurveyReportWriter {
    public static func standardReport(records: [AnalysisRecord], options: SurveyOptions,
                                      improvedClusterAnalysis: Bool) throws -> SurveyReport {
        SurveyReport(kind: .standard(improvedClusterAnalysis: improvedClusterAnalysis), lines: [])
    }

    public static func estimatesReport(records: [AnalysisRecord], options: SurveyOptions) throws -> SurveyReport {
        SurveyReport(kind: .estimates, lines: [])
    }

    public static func defaultFileName(surveyName: String, kind: SurveyReportKind) -> String { "" }

    public static func write(_ report: SurveyReport, to url: URL) throws {}
}
