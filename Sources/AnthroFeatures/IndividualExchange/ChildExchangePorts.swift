import AnthroCore
import AnthroIO

/// Origem das crianças exportadas e do modelo de dados adicionais (design D1).
public protocol ChildExchangeSource {
    func exchangeChildren(ids: [Int64], includeResults: Bool) throws -> [ExchangeChild]
    func additionalDataDefinition() throws -> AdditionalData
}

/// Destino das crianças importadas, gravadas numa transação (design D10).
public protocol ChildImportSink {
    func insertAll(_ children: [ExchangeChild]) throws -> Int
}
