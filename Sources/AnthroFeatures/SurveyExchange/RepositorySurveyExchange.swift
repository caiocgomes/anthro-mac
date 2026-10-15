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

    /// Os inquéritos na ordem pedida, com os registros na ordem da tabela.
    public func surveysForExport(ids: [Int64]) throws -> [ExchangeSurvey] {
        try ids.map { ExchangeSurvey(survey: try surveys.survey(id: $0), records: try surveys.records(surveyID: $0)) }
    }

    /// Todos os inquéritos numa só transação, como novos: um erro em qualquer um desfaz os anteriores (D12).
    public func insertAll(_ imported: [ExchangeSurvey]) throws -> Int {
        try database.transaction {
            for exchange in imported {
                var survey = exchange.survey
                survey.id = nil
                survey.isArchived = false
                let records = exchange.records.map { record -> SurveyRecord in
                    var copy = record
                    copy.id = nil
                    return copy
                }
                _ = try surveys.save(survey, records: records)
            }
            return imported.count
        }
    }
}
