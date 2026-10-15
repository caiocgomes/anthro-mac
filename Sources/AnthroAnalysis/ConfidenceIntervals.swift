import AnthroCore
import Foundation

/// `ComputeCI`, `ComputeImprovedClusterCI` e `GetTStudentValue` (design D5); limites em percentual com 1 casa.
public enum ConfidenceIntervals {
    /// Wald com correção de continuidade, $p \pm (1.96\sqrt{p(1-p)/n} + 1/(2n))$, cortado em [0, 1].
    public static func simple(portion: Decimal, total: Decimal) -> ConfidenceInterval {
        guard total != 0 else { return .unavailable }
        let p = portion / total
        let root = ClinicalRounding.decimal15(AnalysisMath.double(p * (1 - p) / total).squareRoot()) ?? 0
        let half = Decimal(string: "1.96")! * root + 1 / (2 * total)
        return percent(low: max(p - half, 0), high: min(p + half, 1))
    }

    /// Linearização da razão com logit e t de Student com C - 1 graus de liberdade; os dicionários têm todo cluster
    /// registrado, inclusive os que só tiveram registros descartados.
    public static func improvedCluster(portion: Decimal, total: Decimal, clusterPortions: [Int: Decimal],
                                       clusterTotals: [Int: Decimal], clusterSizes: [Int: Int]) -> ConfidenceInterval {
        guard total != 0 else { return .unavailable }
        // A `ArgumentException` de tamanhos diferentes é inalcançável (D14d).
        precondition(clusterPortions.count == clusterTotals.count && clusterTotals.count == clusterSizes.count)
        let clusters = clusterSizes.count
        guard let t = tStudent(degreesOfFreedom: clusters - 1) else { return .singleCluster }
        let meanTotal = total / Decimal(clusters)
        let meanPortion = portion / Decimal(clusters)
        let p = meanPortion / meanTotal
        guard p > Decimal(string: "0.00005")!, p < Decimal(string: "0.99995")! else { return .unavailable }
        var squares: Decimal = 0
        for (cluster, value) in clusterPortions {
            let residual = value / meanTotal - (clusterTotals[cluster] ?? 0) * meanPortion / (meanTotal * meanTotal)
            squares += residual * residual
        }
        let error = ClinicalRounding.decimal15(AnalysisMath.double(squares / Decimal(clusters * (clusters - 1))).squareRoot()) ?? 0
        let half = t * error / (p * (1 - p))
        let center = ClinicalRounding.decimal15(Foundation.log(AnalysisMath.double(p / (1 - p)))) ?? 0
        func expit(_ x: Decimal) -> Decimal {
            1 / ((ClinicalRounding.decimal15(Foundation.exp(AnalysisMath.double(-x))) ?? 0) + 1)
        }
        return percent(low: expit(center - half), high: expit(center + half))
    }

    /// Tabela de `InitTStudentValues` de 1 a 200; 1.96 acima; `nil` para 0 ou menos.
    public static func tStudent(degreesOfFreedom: Int) -> Decimal? {
        if TStudentTable.values.indices.contains(degreesOfFreedom - 1) { return TStudentTable.values[degreesOfFreedom - 1] }
        return degreesOfFreedom > 0 ? Decimal(string: "1.96")! : nil
    }

    private static func percent(low: Decimal, high: Decimal) -> ConfidenceInterval {
        .interval(low: AnalysisMath.round1(low * 100), high: AnalysisMath.round1(high * 100))
    }
}
