import AnthroCore
import AnthroIO
import AnthroStore

/// Adaptador entre o repositório de inquéritos e o envelope de troca (design D12 e D17).
public struct RepositorySurveyExchange: SurveyExchangeSource, SurveyImportSink {
    private let database: AnthroDatabase
    private let surveys: SurveyRepository

    public init(database: AnthroDatabase, surveys: SurveyRepository) {
        self.database = database
        self.surveys = surveys
    }

    public func surveysForExport(ids: [Int64]) throws -> [ExchangeSurvey] { [] }

    public func insertAll(_ surveys: [ExchangeSurvey]) throws -> Int { 0 }
}
