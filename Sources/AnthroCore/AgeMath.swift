import Foundation

/// Idade e faixa etária, como `AnthroComputation.GetAgeInDays`, `DaysToMonths`, `MonthsToDays` e o início de
/// `GetAnthroResult` (design D8).
public enum AgeMath {
    private static let daysInMonth = Decimal(string: "30.4375")!

    private static let utc: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }()

    /// Dias entre os dias de calendário (no calendário do usuário) do nascimento e da visita.
    public static func ageInDays(birth: Date, visit: Date) throws -> Int {
        func calendarDay(_ date: Date) -> Date {
            let parts = Calendar.current.dateComponents([.year, .month, .day], from: date)
            return utc.date(from: parts)!
        }
        let days = utc.dateComponents([.day], from: calendarDay(birth), to: calendarDay(visit)).day!
        guard days >= 0 else { throw AnthroError.birthAfterVisit }
        return days
    }

    public static func daysToMonths(_ days: Int) -> Decimal {
        Decimal(days) / daysInMonth
    }

    /// `Round(meses * 30.4375, 0)`; 24 meses viram 731 dias.
    public static func monthsToDays(_ months: Decimal) -> Int {
        if months == 24 { return 731 }
        let days = ClinicalRounding.round(months * daysInMonth, places: 0) ?? 0
        return NSDecimalNumber(decimal: days).intValue
    }

    /// Padrões até 1856 dias; referência acima; fora dos limites com dias negativos ou parte inteira dos meses acima de 228.
    public static func ageRange(days: Int, months: Decimal) -> AgeRange {
        if days < 0 || truncated(months) > 228 { return .offLimits }
        return days <= 1856 ? .standards : .reference
    }

    /// Parte inteira, como o cast `(int)decimal` do .NET.
    static func truncated(_ value: Decimal) -> Int {
        var input = value
        var result = Decimal()
        NSDecimalRound(&result, &input, 0, value < 0 ? .up : .down)
        return NSDecimalNumber(decimal: result).intValue
    }
}
