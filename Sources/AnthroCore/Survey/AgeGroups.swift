/// Faixa etária do inquérito em meses inteiros, limites inclusivos.
public struct AgeGroup: Sendable, Equatable {
    public let lowerMonths: Int
    public let upperMonths: Int

    public init(lowerMonths: Int, upperMonths: Int) {
        self.lowerMonths = lowerMonths
        self.upperMonths = upperMonths
    }
}

public enum AgeGroups {
    /// Fronteiras $b_0, ..., b_n$ dão $n$ faixas: $b_k$ a $b_{k+1} - 1$, e a última de $b_{n-1}$ a $b_n$
    /// (`NSOptionsDialog.Init`).
    public static func groups(fromBoundaries boundaries: [Int]) -> [AgeGroup] {
        guard boundaries.count >= 2 else { return [] }
        let last = boundaries.count - 2
        return (0...last).map { k in
            AgeGroup(lowerMonths: boundaries[k], upperMonths: k == last ? boundaries[k + 1] : boundaries[k + 1] - 1)
        }
    }
}
