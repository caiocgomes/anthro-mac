import Foundation

/// Limiares de prevalência de `AnalysisResult` (< -3, < -2, > +1, > +2 e > +3 DP).
public enum Threshold: CaseIterable, Sendable, Hashable {
    case belowMinus3, belowMinus2, abovePlus1, abovePlus2, abovePlus3
}

/// `AnalysisResult` do original com os indefinidos como `nil` e os IC como `ConfidenceInterval` (design D4).
public struct PrevalenceResult: Sendable, Equatable {
    public let count: Decimal
    public let oedemaCount: Decimal
    public let mean: Decimal?
    public let standardDeviation: Decimal?
    public let prevalences: [Threshold: Decimal]
    public let intervals: [Threshold: ConfidenceInterval]

    public init(count: Decimal, oedemaCount: Decimal, mean: Decimal?, standardDeviation: Decimal?,
                prevalences: [Threshold: Decimal], intervals: [Threshold: ConfidenceInterval]) {
        self.count = count
        self.oedemaCount = oedemaCount
        self.mean = mean
        self.standardDeviation = standardDeviation
        self.prevalences = prevalences
        self.intervals = intervals
    }

    public func prevalence(_ threshold: Threshold) -> Decimal? {
        prevalences[threshold]
    }

    public func interval(_ threshold: Threshold) -> ConfidenceInterval {
        intervals[threshold] ?? .notComputed
    }
}
