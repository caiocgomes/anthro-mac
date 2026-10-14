import AnthroFeatures
import Foundation

/// Decimal a partir de texto com ponto.
func num(_ text: String) -> Decimal {
    Decimal(string: text, locale: Locale(identifier: "en_US_POSIX"))!
}

/// Data no calendário do usuário, ao meio-dia (o dia que a tela mostra).
func day(_ year: Int, _ month: Int, _ dayOfMonth: Int) -> Date {
    Calendar.current.date(from: DateComponents(year: year, month: month, day: dayOfMonth, hour: 12))!
}

/// "AAAA-MM-DD" no calendário do usuário.
func ymd(_ date: Date) -> String {
    let parts = Calendar.current.dateComponents([.year, .month, .day], from: date)
    return String(format: "%04d-%02d-%02d", parts.year!, parts.month!, parts.day!)
}

func score(_ z: String?, _ p: String? = nil) -> IndicatorScore {
    IndicatorScore(zScore: z.map(num), percentile: p.map(num))
}

let noScore = IndicatorScore(zScore: nil, percentile: nil)

/// Resultado com z conhecido, montado pelo inicializador público de `AnthropometricResult`.
func fixtureResult(
    days: Int, sex: Sex = .girl, weight: Decimal? = 20, lengthOrHeight: Decimal? = 110,
    adjusted: Decimal? = nil, isLength: Bool = false,
    wfa: IndicatorScore = noScore, lhfa: IndicatorScore = noScore, bmi: IndicatorScore = noScore
) -> AnthropometricResult {
    AnthropometricResult(
        sex: sex, ageInDays: days, ageInMonths: Decimal(days) / num("30.4375"),
        ageRange: days <= 1856 ? .standards : .reference,
        weight: weight, lengthOrHeight: lengthOrHeight, adjustedLengthOrHeight: adjusted ?? lengthOrHeight,
        isLength: isLength, weightForAge: wfa, lengthOrHeightForAge: lhfa, bmiForAge: bmi
    )
}

/// Sorteador de dia que registra os intervalos recebidos.
final class DayPicker {
    var ranges: [Range<Int>] = []
    var pick: (Range<Int>) -> Int = { $0.lowerBound }

    func callAsFunction(_ range: Range<Int>) -> Int {
        ranges.append(range)
        return pick(range)
    }
}
