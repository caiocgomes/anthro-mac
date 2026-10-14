import Foundation

/// Leitura de campos numéricos como `NumericUpDownX` (helper compartilhado pelas changes 3 a 6, design D2):
/// vazio, inválido ou fora do intervalo esvaziam o campo (`CheckValidValue` + `SetToNull`); valor válido é
/// truncado às casas do campo (`AnthroComputation.SymetricCrop`).
public enum MeasurementInput {
    public enum Outcome: Equatable, Sendable {
        case empty
        case value(Decimal)
        case invalid
        case outOfRange(ClosedRange<Decimal>)

        /// Mensagem do aviso inline; `nil` quando o campo está vazio ou válido.
        public var issueMessage: String? {
            switch self {
            case .invalid:
                return L10n.Calculator.invalidValue
            case .outOfRange(let range):
                let lower = ClinicalFormat.string(range.lowerBound, places: 2)
                let upper = ClinicalFormat.string(range.upperBound, places: 2)
                return "\(L10n.Calculator.outOfRangePrefix) \(lower) \(L10n.Calculator.rangeSeparator) \(upper)"
            case .empty, .value:
                return nil
            }
        }

        var value: Decimal? {
            if case .value(let value) = self { return value }
            return nil
        }
    }

    /// O limite é testado sobre o valor digitado, antes do truncamento, como `CheckValidValue`.
    public static func evaluate(_ text: String, range: ClosedRange<Decimal>, places: Int = 2) -> Outcome {
        if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return .empty }
        guard let number = ClinicalFormat.parseDecimal(text) else { return .invalid }
        guard range.contains(number) else { return .outOfRange(range) }
        return .value(truncate(number, places: places))
    }

    public static func parse(_ text: String, range: ClosedRange<Decimal>) -> Decimal? {
        evaluate(text, range: range).value
    }

    /// `SymetricCrop`: trunca em direção a zero.
    public static func truncate(_ value: Decimal, places: Int) -> Decimal {
        var input = value
        var result = Decimal()
        NSDecimalRound(&result, &input, places, value < 0 ? .up : .down)
        return result
    }
}
