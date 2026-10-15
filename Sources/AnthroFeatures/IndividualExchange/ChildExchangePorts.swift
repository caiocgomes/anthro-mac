import AnthroCore
import AnthroIO
import Foundation

/// Origem das crianças exportadas e do modelo de dados adicionais (design D1).
public protocol ChildExchangeSource {
    func exchangeChildren(ids: [Int64], includeResults: Bool) throws -> [ExchangeChild]
    func additionalDataDefinition() throws -> AdditionalData
}

/// Falha da exportação com mensagem em pt-BR.
public enum ChildExchangeError: LocalizedError, Equatable {
    /// Visita com XML de dados adicionais que o codec não lê; exportar sem ele perderia os valores em silêncio.
    case unreadableAdditionalData(childName: String, visitDate: Date)

    public var errorDescription: String? {
        switch self {
        case .unreadableAdditionalData(let name, let date):
            let parts = Calendar.current.dateComponents([.year, .month, .day], from: date)
            let day = String(format: "%02d/%02d/%04d", parts.day ?? 1, parts.month ?? 1, parts.year ?? 1)
            return "\(L10n.Exchange.unreadableVisitPrefix) \(day) \(L10n.Exchange.unreadableVisitOf) \(name) "
                + L10n.Exchange.unreadableVisitSuffix
        }
    }
}

/// Destino das crianças importadas, gravadas numa transação (design D10).
public protocol ChildImportSink {
    func insertAll(_ children: [ExchangeChild]) throws -> Int
}
