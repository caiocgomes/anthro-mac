import Foundation

/// IC 95% de uma prevalência, em percentual; as sentinelas -1, -2 e `decimal.MinValue` do original viram casos (D4).
public enum ConfidenceInterval: Sendable, Equatable {
    case notComputed
    case interval(low: Decimal, high: Decimal)
    case unavailable
    case singleCluster
}
