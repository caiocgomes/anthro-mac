import Foundation

public enum PlausibilityFlag: Sendable {
    case none
    case weightForAge
    case lengthOrHeightForAge
    case weightAndLengthOrHeightForAge
    case bmiForAge
}

public enum Plausibility {
    public static func isFlagged(_ indicator: Indicator, z: Decimal?) -> Bool {
        false
    }

    public static func flag(for result: AnthropometricResult) -> PlausibilityFlag {
        .none
    }
}
