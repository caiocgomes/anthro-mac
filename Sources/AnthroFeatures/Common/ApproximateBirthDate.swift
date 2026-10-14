import Foundation

/// Data de nascimento aproximada, como o ramo aproximado de `ACMain` (helper compartilhado pelas changes 3 a 6),
/// sempre no calendário do usuário.
public enum ApproximateBirthDate {
    /// Mantém ano e mês e troca o dia pelo sorteio em `1..<diasNoMês`, como `Random.Next(1, DaysInMonth)`:
    /// o último dia do mês nunca sai.
    public static func randomized(_ date: Date, randomDay: (Range<Int>) -> Int) -> Date {
        let calendar = Calendar.current
        var parts = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
        let daysInMonth = calendar.range(of: .day, in: .month, for: date)?.count ?? 28
        parts.day = randomDay(1..<daysInMonth)
        return calendar.date(from: parts) ?? date
    }

    /// Com data aproximada, desfaz a troca de dia e sorteia novo dia na troca de mês ou ano
    /// (`dtpDateOfBirth_ValueChanged`); o mesmo dia reenviado não sorteia, porque o `DateTimePicker` não dispara
    /// `ValueChanged` sem mudança. Em todos os casos o resultado não passa do limite superior (a visita).
    public static func adjusted(previous: Date, proposed: Date, isApprox: Bool, upperBound: Date,
                                randomDay: (Range<Int>) -> Int) -> Date {
        let calendar = Calendar.current
        var result = proposed
        if isApprox, !calendar.isDate(proposed, inSameDayAs: previous) {
            let previousDay = calendar.component(.day, from: previous)
            result = calendar.component(.day, from: proposed) != previousDay
                ? previous
                : randomized(proposed, randomDay: randomDay)
        }
        return calendar.startOfDay(for: result) > calendar.startOfDay(for: upperBound) ? upperBound : result
    }
}
