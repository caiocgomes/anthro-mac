import AnthroCore
import Foundation

public enum FieldParseError: Error, Equatable, Sendable {
    case missing, invalid, outOfRange
}

/// `ImportExport.ParseField`: leitura de cada atributo com nulos, limites e truncamento. Atributo ausente vale como
/// vazio quando o campo aceita nulo (design D7) e é `.missing` quando não aceita.
public enum FieldParser {
    public static func boolean(_ text: String?, nullable: Bool) throws(FieldParseError) -> Bool? {
        guard let text = try present(text, nullable: nullable) else { return nil }
        switch text.lowercased() {
        case "1", "y", "true", "yes": return true
        case "0", "n", "false", "no": return false
        default: throw .invalid
        }
    }

    /// Menino: `1`, `m`, `male`, `true`; menina: `0`, `2`, `f`, `female`, `false`, sem diferenciar maiúsculas.
    public static func sex(_ text: String?) throws(FieldParseError) -> Sex {
        guard let text else { throw .missing }
        switch text.lowercased() {
        case "1", "m", "male", "true": return .boy
        case "0", "2", "f", "female", "false": return .girl
        default: throw .invalid
        }
    }

    /// Deitado: `1`, `l`, `true`; em pé: `0`, `h`, `false`.
    public static func measureType(_ text: String?) throws(FieldParseError) -> Bool {
        guard let text else { throw .missing }
        switch text.lowercased() {
        case "1", "l", "true": return true
        case "0", "h", "false": return false
        default: throw .invalid
        }
    }

    /// `dd-MM-yyyy HH:mm:ss`, depois a lista fixa que substitui o `DateTime.Parse` da cultura do Windows e por fim os
    /// 8 primeiros caracteres como `yyyyMMdd` (design D5); a hora é descartada e o dia vira o meio-dia local. Os limites
    /// comparam dias.
    public static func date(_ text: String?, nullable: Bool, notBefore: Date? = nil,
                            notAfter: Date? = nil) throws(FieldParseError) -> Date? {
        guard let text = try present(text, nullable: nullable) else { return nil }
        guard let date = parseDate(text) else { throw .invalid }
        if let notBefore, date < noon(notBefore) { throw .outOfRange }
        if let notAfter, date > noon(notAfter) { throw .outOfRange }
        return date
    }

    /// Vírgula trocada por ponto, truncamento a `truncateToPlaces` casas em direção a zero (`SymetricCrop`) e só então
    /// os limites; `unsigned` recusa negativos.
    public static func decimal(_ text: String?, nullable: Bool, unsigned: Bool, min: Decimal? = nil, max: Decimal? = nil,
                               truncateToPlaces: Int? = 2) throws(FieldParseError) -> Decimal? {
        guard let text = try present(text, nullable: nullable) else { return nil }
        let normalized = text.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: ",", with: ".")
        guard normalized.range(of: #"^[+-]?([0-9]+(\.[0-9]*)?|\.[0-9]+)$"#, options: .regularExpression) != nil,
              let parsed = Decimal(string: normalized, locale: Locale(identifier: "en_US_POSIX")) else { throw .invalid }
        let value = truncateToPlaces.map { truncate(parsed, places: $0) } ?? parsed
        if let min, value < min { throw .outOfRange }
        if unsigned, value < 0 { throw .outOfRange }
        if let max, value > max { throw .outOfRange }
        return value
    }

    public static func unsignedInteger(_ text: String?, nullable: Bool, min: Int? = nil,
                                       max: Int? = nil) throws(FieldParseError) -> Int? {
        guard let text = try present(text, nullable: nullable) else { return nil }
        guard let value = Int(text.trimmingCharacters(in: .whitespaces)) else { throw .invalid }
        if let min, value < min { throw .outOfRange }
        if value < 0 { throw .outOfRange }
        if let max, value > max { throw .outOfRange }
        return value
    }

    /// Texto além de `maxLength` é cortado, não rejeitado; vazio de campo não anulável fica vazio.
    public static func text(_ text: String?, nullable: Bool, maxLength: Int? = nil) throws(FieldParseError) -> String? {
        guard let text = try present(text, nullable: nullable) else { return nil }
        guard let maxLength, text.count > maxLength else { return text }
        return String(text.prefix(maxLength))
    }

    /// `AnthroComputation.SymetricCrop`: trunca em direção a zero.
    public static func truncate(_ value: Decimal, places: Int) -> Decimal {
        var input = value
        var result = Decimal()
        NSDecimalRound(&result, &input, places, value < 0 ? .up : .down)
        return result
    }

    // MARK: Privado

    /// `isNullable && textValue.Length == 0` dá nulo; ausente em campo obrigatório é `.missing`.
    private static func present(_ text: String?, nullable: Bool) throws(FieldParseError) -> String? {
        guard let text else {
            if nullable { return nil }
            throw .missing
        }
        if nullable && text.isEmpty { return nil }
        return text
    }

    private static let fallbackFormats = ["dd/MM/yyyy", "dd/MM/yyyy HH:mm:ss", "yyyy-MM-dd", "yyyy-MM-dd'T'HH:mm:ss",
                                          "dd-MM-yyyy"]

    private static func parseDate(_ text: String) -> Date? {
        for format in ["dd-MM-yyyy HH:mm:ss"] + fallbackFormats {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.calendar = Calendar(identifier: .gregorian)
            formatter.timeZone = .current
            formatter.isLenient = false
            formatter.dateFormat = format
            if let date = formatter.date(from: text) { return noon(date) }
        }
        let prefix = text.prefix(8)
        guard prefix.count == 8, prefix.allSatisfy(\.isASCII), prefix.allSatisfy(\.isNumber),
              let year = Int(prefix.prefix(4)), let month = Int(prefix.dropFirst(4).prefix(2)),
              let day = Int(prefix.dropFirst(6)) else { return nil }
        return validDay(year, month, day)
    }

    /// Meio-dia do dia de calendário do usuário.
    private static func noon(_ date: Date) -> Date {
        let parts = Calendar.current.dateComponents([.year, .month, .day], from: date)
        return Calendar.current.date(from: DateComponents(year: parts.year, month: parts.month, day: parts.day, hour: 12))
            ?? date
    }

    private static func validDay(_ year: Int, _ month: Int, _ day: Int) -> Date? {
        guard let date = Calendar.current.date(from: DateComponents(year: year, month: month, day: day, hour: 12)) else {
            return nil
        }
        let parts = Calendar.current.dateComponents([.year, .month, .day], from: date)
        return parts.year == year && parts.month == month && parts.day == day ? date : nil
    }
}
