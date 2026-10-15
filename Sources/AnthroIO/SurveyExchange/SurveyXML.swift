import AnthroCore
import Foundation

/// `Survey.ExportSurveysToXML` e `Survey.ImportSurveysFromXML` (design D13 a D16).
public enum SurveyXML {
    public static func data(_ surveys: [ExchangeSurvey], resultsEngine: AnthroEngine?) -> Data { Data() }

    public static func read(_ data: Data) throws(ImportFailure) -> [ExchangeSurvey] { [] }
}
