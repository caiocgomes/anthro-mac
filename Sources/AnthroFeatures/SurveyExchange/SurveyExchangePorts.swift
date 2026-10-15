import AnthroIO

/// Origem dos inquéritos exportados (design D17).
public protocol SurveyExchangeSource {
    func surveysForExport(ids: [Int64]) throws -> [ExchangeSurvey]
}

/// Destino dos inquéritos importados de XML, gravados numa transação (design D12).
public protocol SurveyImportSink {
    func insertAll(_ surveys: [ExchangeSurvey]) throws -> Int
}

/// Editor que recebe o rascunho da importação externa, não salvo (design D12).
@MainActor
public protocol SurveyDraftPresenter: AnyObject {
    func presentDraft(_ draft: ExchangeSurvey)
}
