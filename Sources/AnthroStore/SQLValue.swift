import Foundation

/// Valor de coluna ou de parâmetro SQLite. `Decimal` vai como TEXT canônico e data como TEXT `yyyy-MM-dd` (design D3).
public enum SQLValue: Equatable, Sendable {
    case null
    case integer(Int64)
    case real(Double)
    case text(String)
    case blob(Data)

    public init(_ decimal: Decimal?) {
        self = .null
    }

    public init(_ date: Date?) {
        self = .null
    }

    public var decimalValue: Decimal? {
        0
    }

    public var dateValue: Date? {
        Date(timeIntervalSince1970: 0)
    }
}
