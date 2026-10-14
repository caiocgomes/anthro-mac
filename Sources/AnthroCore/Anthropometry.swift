import Foundation

public enum Anthropometry {
    public static func adjustedLengthOrHeight(ageInDays: Int, value: Decimal, measuredRecumbent: Bool) -> (value: Decimal, isLength: Bool) {
        (0, false)
    }

    public static func exactBMI(weight: Decimal, lengthOrHeight: Decimal) -> Decimal? {
        0
    }
}
