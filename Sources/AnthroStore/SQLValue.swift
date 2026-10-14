import Foundation

/// Valor de coluna ou de parâmetro SQLite. `Decimal` vai como TEXT canônico e data como TEXT `yyyy-MM-dd` do dia de
/// calendário do usuário (design D3 da change 1; fuso no D10 da add-individual-assessment).
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

    /// Dia de calendário do usuário a partir de TEXT `yyyy-MM-dd`, ao meio-dia local (a normalização dos modelos);
    /// outro formato ou dia inexistente devolve `nil`.
    public var dateValue: Date? {
        guard case .text(let text) = self else { return nil }
        let parts = text.split(separator: "-", omittingEmptySubsequences: false)
        guard parts.count == 3, parts[0].count == 4, parts[1].count == 2, parts[2].count == 2,
              let year = Int(parts[0]), let month = Int(parts[1]), let day = Int(parts[2]) else { return nil }
        let components = DateComponents(year: year, month: month, day: day, hour: 12)
        let calendar = Calendar.current
        guard let date = calendar.date(from: components),
              calendar.dateComponents([.year, .month, .day], from: date) == DateComponents(year: year, month: month, day: day)
        else { return nil }
        return date
    }

    /// `yyyy-MM-dd` do dia de calendário do usuário em que a data cai.
    private static func calendarDate(_ date: Date) -> String {
        let parts = Calendar.current.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", parts.year!, parts.month!, parts.day!)
    }
}
