import AnthroCore
import Foundation

/// Decimal a partir de texto com ponto, sem passar por Double.
func d(_ text: String) -> Decimal {
    Decimal(string: text, locale: Locale(identifier: "en_US_POSIX"))!
}

/// Data no calendário do usuário (o dia que a tela mostra), no horário pedido.
func localDate(_ year: Int, _ month: Int, _ day: Int, hour: Int = 12, minute: Int = 0) -> Date {
    Calendar.current.date(from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute))!
}

/// Arredonda um Double a 4 casas para comparar séries de curvas.
func round4(_ value: Double) -> Double {
    (value * 10_000).rounded() / 10_000
}

extension AnthroEngine {
    /// Atalho dos testes: idade em dias, medida em pé, sem edema.
    func at(days: Int?, months: Decimal? = nil, sex: Sex?, weight: Decimal?, height: Decimal?,
            recumbent: Bool = false, oedema: Bool = false) -> AnthropometricResult {
        result(ageInDays: days, ageInMonths: months, sex: sex, weight: weight, lengthOrHeight: height,
               measuredRecumbent: recumbent, hasOedema: oedema)
    }
}
