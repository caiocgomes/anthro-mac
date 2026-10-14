import AnthroCore
import Foundation

/// Intervalos próprios da Avaliação individual (`IAParentDialog.InitializeComponent`, design D7).
public enum IndividualAssessment {
    public static let parentHeightRange: ClosedRange<Decimal> = 50...300
    public static let parentWeightRange: ClosedRange<Decimal> = 10...1000

    /// Intervalos da visita (`IAVisitDialog`, `InputLimits`).
    static let visitWeightRange = InputLimits.minWeight...InputLimits.maxWeight
    static let visitLengthOrHeightRange = InputLimits.minLengthOrHeight...InputLimits.maxLengthOrHeight

    /// Aviso do campo numérico com o intervalo aceito; `nil` para campo vazio ou válido (design D7).
    static func warning(_ outcome: MeasurementInput.Outcome, range: ClosedRange<Decimal>) -> String? {
        switch outcome {
        case .invalid:
            let lower = ClinicalFormat.string(range.lowerBound, places: 2)
            let upper = ClinicalFormat.string(range.upperBound, places: 2)
            return "\(L10n.IndividualAssessment.invalidWithRangePrefix) \(lower) \(L10n.Calculator.rangeSeparator) \(upper)"
        case .outOfRange:
            return outcome.issueMessage
        case .empty, .value:
            return nil
        }
    }

    /// Valor que bloqueia a gravação: ilegível ou fora do intervalo (política única entre changes, D7).
    static func blocksSave(_ outcome: MeasurementInput.Outcome) -> Bool {
        switch outcome {
        case .invalid, .outOfRange: true
        case .empty, .value: false
        }
    }

    /// Dia de calendário do usuário ao meio-dia (design D10).
    static func normalized(_ date: Date) -> Date {
        let calendar = Calendar.current
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        return calendar.date(from: DateComponents(year: parts.year, month: parts.month, day: parts.day, hour: 12)) ?? date
    }

    /// Marcar data aproximada: sorteia o dia do mês (`ApproximateBirthDate.randomized`) e aplica o limite superior.
    static func approximated(_ birth: Date, upperBound: Date, randomDay: (Range<Int>) -> Int) -> Date {
        let drawn = ApproximateBirthDate.randomized(birth, randomDay: randomDay)
        let calendar = Calendar.current
        return normalized(calendar.startOfDay(for: drawn) > calendar.startOfDay(for: upperBound) ? upperBound : drawn)
    }

    static func sameDay(_ a: Date, _ b: Date) -> Bool {
        Calendar.current.isDate(a, inSameDayAs: b)
    }

    /// Texto opcional sem espaços nas pontas, vazio como `nil` (`Utils.TextToNullableString`).
    static func nullable(_ text: String) -> String? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    /// IMC exibido da visita: medida ajustada pela idade, arredondado a 1 casa; "N/D" com edema ou campo vazio (D8).
    static func visitBMIText(ageInDays: Int?, weight: Decimal?, lengthOrHeight: Decimal?, measuredRecumbent: Bool,
                             hasOedema: Bool) -> String {
        guard !hasOedema, let weight, let lengthOrHeight, let ageInDays else { return L10n.notAvailable }
        let adjusted = Anthropometry.adjustedLengthOrHeight(ageInDays: ageInDays, value: lengthOrHeight,
                                                           measuredRecumbent: measuredRecumbent).value
        let bmi = Anthropometry.exactBMI(weight: weight, lengthOrHeight: adjusted)
        return ClinicalFormat.string(ClinicalRounding.round(bmi, places: 1), places: 1)
    }
}
