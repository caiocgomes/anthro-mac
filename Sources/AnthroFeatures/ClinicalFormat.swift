import Foundation

/// Números no padrão brasileiro: vírgula decimal, casas fixas, "N/D" para indefinido (design D7).
public enum ClinicalFormat {
    public static func string(_ value: Decimal?, places: Int, locale: Locale = Locale(identifier: "pt_BR")) -> String {
        ""
    }

    public static func parseDecimal(_ text: String) -> Decimal? {
        0
    }
}
