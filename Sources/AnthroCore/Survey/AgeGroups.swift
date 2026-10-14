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
    public static func groups(fromBoundaries boundaries: [Int]) -> [AgeGroup] {
        []
    }
}
