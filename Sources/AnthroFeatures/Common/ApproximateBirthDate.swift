import Foundation

/// Data de nascimento aproximada, como o ramo aproximado de `ACMain` (helper compartilhado pelas changes 3 a 6).
public enum ApproximateBirthDate {
    public static func randomized(_ date: Date, randomDay: (Range<Int>) -> Int) -> Date {
        Date(timeIntervalSince1970: 0)
    }

    public static func adjusted(previous: Date, proposed: Date, isApprox: Bool, upperBound: Date, randomDay: (Range<Int>) -> Int) -> Date {
        Date(timeIntervalSince1970: 0)
    }
}
