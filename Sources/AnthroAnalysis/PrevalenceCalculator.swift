import AnthroCore
import Foundation

/// Resultado de um cluster; substitui o array estático `AnthroAnalysis.ClusterNumbers` do original (D4).
public struct ClusterPrevalence: Sendable, Equatable {
    public let cluster: Int
    public let result: PrevalenceResult

    public init(cluster: Int, result: PrevalenceResult) {
        self.cluster = cluster
        self.result = result
    }
}

/// `AnthroAnalysis.ComputePrevalences`, `GetPrevalencesValuesByAgeGroups`, `GetPrevalencesValuesByCluster` e
/// `GetFilteredRecords` (design D2).
public enum PrevalenceCalculator {
    /// Peso e estatura para idade só têm prevalências abaixo da mediana (`ComputeOnlyNegative`).
    public static func computeOnlyNegative(_ indicator: Indicator) -> Bool {
        indicator == .lengthOrHeightForAge || indicator == .weightForAge
    }

    /// `ComputePrevalences`, com as checagens na ordem do original (D2).
    public static func compute(_ population: [AnalysisRecord], indicator: Indicator, options: SurveyOptions,
                               analysisType: AnalysisType, isTotal: Bool, byCluster: Bool,
                               improvedClusterAnalysis: Bool) throws -> PrevalenceResult {
        let onlyNegative = computeOnlyNegative(indicator)
        let thresholds: [Threshold] = onlyNegative ? [.belowMinus3, .belowMinus2] : Threshold.allCases
        var accumulator = Accumulator(thresholds: thresholds, improved: improvedClusterAnalysis)
        for record in population {
            // 1. Banco global: medidas informadas fora dos limites de entrada.
            if analysisType == .whoGlobalDatabase {
                if let weight = record.weight, weight < InputLimits.minWeight || weight > InputLimits.maxWeight { continue }
                if let height = record.height, height < InputLimits.minLengthOrHeight || height > InputLimits.maxLengthOrHeight {
                    continue
                }
            }
            let age = record.ageInMonths
            // 2. Faixa etária: idade conhecida dentro das fronteiras do inquérito.
            if !byCluster && !isTotal {
                guard let age, let first = options.ageGroupBoundaries.first, let last = options.ageGroupBoundaries.last,
                      age >= Decimal(first), AnalysisMath.truncated(age) <= last else { continue }
            }
            // 3. Peso para idade acima de 108 meses, ou qualquer indicador acima de 228: entra em N sem z.
            if let age, (indicator == .weightForAge && AnalysisMath.truncated(age) > 108) || AnalysisMath.truncated(age) > 228 {
                if !isTotal || (age >= 11 && age <= 228) { accumulator.count += record.weightingFactor }
                continue
            }
            // 4. Com correção, registro sem cluster fica de fora.
            if improvedClusterAnalysis && record.cluster == nil { continue }
            // 5. Fator negativo vale 1.
            let factor = record.weightingFactor < 0 ? 1 : record.weightingFactor
            // 6. O cluster conta em C antes da checagem de edema e plausibilidade.
            if improvedClusterAnalysis, let cluster = record.cluster { accumulator.register(cluster) }
            // 7. Edema em peso ou IMC: denominador e numeradores de < -3 e < -2, sem média.
            if record.hasOedema == true && (indicator == .bmiForAge || indicator == .weightForAge) {
                accumulator.addOedema(factor: factor, cluster: record.cluster)
                continue
            }
            // 8. z indefinido, implausível ou, no total, idade fora de 11 a 228 meses.
            guard let z = record.zScores[indicator], !record.flagged.contains(indicator) else { continue }
            if isTotal, let age, age < 11 || age > 228 { continue }
            // 9. Acumula.
            accumulator.add(z: z, factor: factor, cluster: record.cluster)
        }
        return try accumulator.result(improved: improvedClusterAnalysis)
    }

    /// `GetPrevalencesValuesByAgeGroups(AndSex)`: cada registro na maior faixa cujo início não passa da idade; peso para
    /// idade descarta idade fora de 11 a 228 meses; uma análise por faixa, sem filtro de total.
    public static func byAgeGroups(_ records: [AnalysisRecord], indicator: Indicator, options: SurveyOptions,
                                   analysisType: AnalysisType, sex: Sex?, improvedClusterAnalysis: Bool) throws -> [PrevalenceResult] {
        let boundaries = options.ageGroupBoundaries
        guard boundaries.count > 1 else { return [] }
        var groups = Array(repeating: [AnalysisRecord](), count: boundaries.count - 1)
        for record in records {
            if let sex, record.sex != sex { continue }
            guard let age = record.ageInMonths else { continue }
            if indicator == .weightForAge && (age < 11 || age > 228) { continue }
            guard age >= Decimal(boundaries[0]) else { continue }
            if let index = (1..<boundaries.count).reversed().first(where: { age >= Decimal(boundaries[$0 - 1]) }) {
                groups[index - 1].append(record)
            }
        }
        return try groups.map {
            try compute($0, indicator: indicator, options: options, analysisType: analysisType, isTotal: false, byCluster: false,
                        improvedClusterAnalysis: improvedClusterAnalysis)
        }
    }

    /// `GetPrevalencesValuesByCluster`: registros com cluster de 61 a 228 meses, por cluster em ordem crescente, sem
    /// filtro de faixa e sem correção.
    public static func byCluster(_ records: [AnalysisRecord], indicator: Indicator, options: SurveyOptions,
                                 analysisType: AnalysisType) -> [ClusterPrevalence] {
        var groups: [Int: [AnalysisRecord]] = [:]
        for record in records {
            guard let cluster = record.cluster else { continue }
            // `GetValueOrDefault`: idade desconhecida vale 0 e fica de fora.
            let age = record.ageInMonths ?? 0
            guard age >= 61, age <= 228 else { continue }
            groups[cluster, default: []].append(record)
        }
        return groups.keys.sorted().map { cluster in
            // Sem correção o cálculo não lança.
            let result = (try? compute(groups[cluster]!, indicator: indicator, options: options, analysisType: analysisType,
                                       isTotal: false, byCluster: true, improvedClusterAnalysis: false))
                ?? PrevalenceResult(count: 0, oedemaCount: 0, mean: nil, standardDeviation: nil, prevalences: [:], intervals: [:])
            return ClusterPrevalence(cluster: cluster, result: result)
        }
    }

    /// `GetFilteredRecords`: 61 a 228 meses (idade desconhecida vale 0), do sexo pedido e, se pedido, com cluster.
    public static func filtered(_ records: [AnalysisRecord], sex: Sex?, onlyWithCluster: Bool) -> [AnalysisRecord] {
        records.filter { record in
            let age = record.ageInMonths ?? 0
            return age >= 61 && age <= 228 && (sex == nil || record.sex == sex) && (!onlyWithCluster || record.cluster != nil)
        }
    }
}

/// Somas de `ComputePrevalences`: N, N com edema, soma de z, numeradores por limiar e os mesmos valores por cluster.
private struct Accumulator {
    let thresholds: [Threshold]
    let improved: Bool
    var count: Decimal = 0
    var oedema: Decimal = 0
    var zSum: Decimal = 0
    var scores: [(z: Decimal, factor: Decimal)] = []
    var portions: [Threshold: Decimal] = [:]
    var clusterSizes: [Int: Int] = [:]
    var clusterTotals: [Int: Decimal] = [:]
    var clusterPortions: [Threshold: [Int: Decimal]] = [:]

    init(thresholds: [Threshold], improved: Bool) {
        self.thresholds = thresholds
        self.improved = improved
        for threshold in thresholds { portions[threshold] = 0 }
    }

    mutating func register(_ cluster: Int) {
        guard clusterSizes[cluster] == nil else { return }
        clusterSizes[cluster] = 0
        clusterTotals[cluster] = 0
        for threshold in thresholds { clusterPortions[threshold, default: [:]][cluster] = 0 }
    }

    mutating func addOedema(factor: Decimal, cluster: Int?) {
        oedema += factor
        count(.belowMinus3, factor, cluster)
        count(.belowMinus2, factor, cluster)
        if improved, let cluster {
            clusterSizes[cluster, default: 0] += 1
            clusterTotals[cluster, default: 0] += factor
        }
    }

    mutating func add(z: Decimal, factor: Decimal, cluster: Int?) {
        count += factor
        if improved, let cluster {
            clusterSizes[cluster, default: 0] += 1
            clusterTotals[cluster, default: 0] += factor
        }
        zSum += z * factor
        scores.append((z, factor))
        if z < -3 { count(.belowMinus3, factor, cluster) }
        if z < -2 { count(.belowMinus2, factor, cluster) }
        if thresholds.count > 2 {
            if z > 1 { count(.abovePlus1, factor, cluster) }
            if z > 2 { count(.abovePlus2, factor, cluster) }
            if z > 3 { count(.abovePlus3, factor, cluster) }
        }
    }

    private mutating func count(_ threshold: Threshold, _ factor: Decimal, _ cluster: Int?) {
        portions[threshold, default: 0] += factor
        if improved, let cluster { clusterPortions[threshold, default: [:]][cluster, default: 0] += factor }
    }

    /// Média e DP (D3), erro de correção sem cluster, IC e prevalências com `Round1`.
    func result(improved: Bool) throws -> PrevalenceResult {
        var mean: Decimal?
        var deviation: Decimal?
        if count > 0 {
            let average = zSum / count
            mean = average
            var squares = 0.0
            for score in scores {
                squares += pow(AnalysisMath.double(score.z - average), 2) * AnalysisMath.double(score.factor)
            }
            let value = (squares / (AnalysisMath.double(count) - 1)).squareRoot()
            // NaN vira 0 como no original; infinito (N - 1 = 0 com soma positiva) fica `nil` (D14a).
            deviation = value.isNaN ? 0 : ClinicalRounding.decimal15(value)
        }
        let total = oedema + count
        if improved && total > 0 && clusterSizes.isEmpty { throw AnalysisError.noClusterData }
        var intervals: [Threshold: ConfidenceInterval] = [:]
        var prevalences: [Threshold: Decimal] = [:]
        for threshold in thresholds {
            let portion = portions[threshold] ?? 0
            intervals[threshold] = improved
                ? ConfidenceIntervals.improvedCluster(portion: portion, total: total,
                                                      clusterPortions: clusterPortions[threshold] ?? [:],
                                                      clusterTotals: clusterTotals, clusterSizes: clusterSizes)
                : ConfidenceIntervals.simple(portion: portion, total: total)
            if count > 0 { prevalences[threshold] = AnalysisMath.round1(portion / total * 100) }
        }
        return PrevalenceResult(count: count, oedemaCount: oedema, mean: mean, standardDeviation: deviation,
                                prevalences: prevalences, intervals: intervals)
    }
}
