import Foundation

/// Leitura de campos numéricos como `NumericUpDownX` (helper compartilhado pelas changes 3 a 6).
public enum MeasurementInput {
    public enum Outcome: Equatable, Sendable {
        case empty
        case value(Decimal)
        case invalid
        case outOfRange(ClosedRange<Decimal>)

        public var issueMessage: String? {
            nil
        }
    }

    public static func evaluate(_ text: String, range: ClosedRange<Decimal>, places: Int = 2) -> Outcome {
        .empty
    }

    public static func parse(_ text: String, range: ClosedRange<Decimal>) -> Decimal? {
        nil
    }

    public static func truncate(_ value: Decimal, places: Int) -> Decimal {
        0
    }
}
