import Foundation

/// `ComputeCI`, `ComputeImprovedClusterCI` e `GetTStudentValue` (design D5).
public enum ConfidenceIntervals {
    public static func simple(portion: Decimal, total: Decimal) -> ConfidenceInterval { .notComputed }

    public static func improvedCluster(portion: Decimal, total: Decimal, clusterPortions: [Int: Decimal],
                                       clusterTotals: [Int: Decimal], clusterSizes: [Int: Int]) -> ConfidenceInterval {
        .notComputed
    }

    public static func tStudent(degreesOfFreedom: Int) -> Decimal? { nil }
}
