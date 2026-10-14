import Foundation

/// Números no padrão brasileiro: vírgula decimal, casas fixas, "N/D" para indefinido (design D7).
public enum ClinicalFormat {
    public static func string(_ value: Decimal?, places: Int, locale: Locale = Locale(identifier: "pt_BR")) -> String {
        guard let value else { return L10n.notAvailable }
        let formatter = NumberFormatter()
        formatter.locale = locale
        formatter.numberStyle = .decimal
        formatter.usesGroupingSeparator = false
        formatter.minimumFractionDigits = places
        formatter.maximumFractionDigits = places
        return formatter.string(from: value as NSDecimalNumber) ?? L10n.notAvailable
    }

    /// Aceita vírgula ou ponto como separador decimal; rejeita mais de um separador e texto não numérico.
    public static func parseDecimal(_ text: String) -> Decimal? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalized = trimmed.replacingOccurrences(of: ",", with: ".")
        guard normalized.range(of: #"^[+-]?([0-9]+(\.[0-9]*)?|\.[0-9]+)$"#, options: .regularExpression) != nil else {
            return nil
        }
        return Decimal(string: normalized, locale: Locale(identifier: "en_US_POSIX"))
    }
}
