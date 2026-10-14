import Foundation

/// Idade em texto, como `Utils.GetLocalizedAgeFromMonths`: "Idade: 5a 11m (71m)" ou "Idade: 5m".
public enum AgeText {
    public static func localized(months: Int) -> String {
        let label = L10n.Age.label, year = L10n.Age.yearSuffix, month = L10n.Age.monthSuffix
        if months >= 12 {
            return "\(label): \(months / 12)\(year) \(months % 12)\(month) (\(months)\(month))"
        }
        return "\(label): \(months)\(month)"
    }

    /// Parte inteira dos meses, como o cast `(int)ageInMonths` do original.
    static func wholeMonths(_ months: Decimal) -> Int {
        NSDecimalNumber(decimal: MeasurementInput.truncate(months, places: 0)).intValue
    }
}
