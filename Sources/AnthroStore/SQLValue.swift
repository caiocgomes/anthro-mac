import Foundation

/// Valor de coluna ou de parâmetro SQLite. `Decimal` vai como TEXT canônico e data como TEXT `yyyy-MM-dd` (design D3).
public enum SQLValue: Equatable, Sendable {
    case null
    case integer(Int64)
    case real(Double)
    case text(String)
    case blob(Data)

    private static let posix = Locale(identifier: "en_US_POSIX")

    public init(_ decimal: Decimal?) {
        guard let decimal else {
            self = .null
            return
        }
        self = .text(NSDecimalNumber(decimal: decimal).description(withLocale: Self.posix))
    }

    public init(_ date: Date?) {
        guard let date else {
            self = .null
            return
        }
        self = .text(Self.calendarDate(date))
    }

    public var decimalValue: Decimal? {
        switch self {
        case .text(let text): Decimal(string: text, locale: Self.posix)
        case .integer(let value): Decimal(value)
        case .real(let value): Decimal(value)
        case .null, .blob: nil
        }
    }

    /// Data de calendário (meia-noite UTC) a partir de TEXT `yyyy-MM-dd`; outro formato devolve `nil`.
    public var dateValue: Date? {
        guard case .text(let text) = self else { return nil }
        return Self.dateFormatter().date(from: text)
    }

    private static func calendarDate(_ date: Date) -> String {
        dateFormatter().string(from: date)
    }

    private static func dateFormatter() -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = posix
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = TimeZone(identifier: "UTC")
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.isLenient = false
        return formatter
    }
}
