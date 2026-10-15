import AnthroCore
import Foundation

/// `Survey.ExportSurveyToDelimitedFile` (design D14 e D15).
public enum SurveyDelimitedExport {
    public static let baseColumns: [String] = []
    public static let resultColumns: [String] = []

    public static func data(_ survey: ExchangeSurvey, resultsEngine: AnthroEngine?, format: DelimitedFormat) -> Data { Data() }
}
