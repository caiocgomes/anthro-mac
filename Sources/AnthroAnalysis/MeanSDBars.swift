import AnthroCore
import Foundation

/// Barra de média com haste de DP (`CandlePlot` do original).
public struct MeanSDBar: Sendable, Equatable {
    public let position: Int
    public let label: String
    public let mean: Double?
    public let whiskerEnd: Double?
    public let count: Int

    public init(position: Int, label: String, mean: Double?, whiskerEnd: Double?, count: Int) {
        self.position = position
        self.label = label
        self.mean = mean
        self.whiskerEnd = whiskerEnd
        self.count = count
    }

    /// De 0 até a média; sem média, sem barra.
    public var barRange: ClosedRange<Double>? {
        mean.map { $0 < 0 ? $0...0 : 0...$0 }
    }

    /// Média positiva (`BullishColor`, tomate); zero ou negativa, preta.
    public var isPositive: Bool { (mean ?? 0) > 0 }
}

/// `GetValuesForCandlePlotByAge` e `GetValuesForCandlePlotByCluster`, com a haste até $\mathrm{sinal}(m)(|m| + DP)$.
public enum MeanSDBars {
    /// Uma barra por faixa, na posição 1 a k, com contagem arredondada; faixa sem registros fica sem média (D14b).
    public static func byAgeGroup(_ records: [AnalysisRecord], indicator: Indicator, options: SurveyOptions) -> [MeanSDBar] {
        let results = (try? PrevalenceCalculator.byAgeGroups(records, indicator: indicator, options: options, analysisType: .standard,
                                                             sex: nil, improvedClusterAnalysis: false)) ?? []
        let groups = AgeGroups.groups(fromBoundaries: options.ageGroupBoundaries)
        return zip(groups, results).enumerated().map { index, pair in
            bar(position: index + 1, label: "\(pair.0.lowerMonths)-\(pair.0.upperMonths)", result: pair.1,
                count: NSDecimalNumber(decimal: ClinicalRounding.round(pair.1.count, places: 0) ?? 0).intValue)
        }
    }

    /// Uma barra por cluster de 61 a 228 meses, em ordem crescente, na posição 0 a k - 1, com a parte inteira de N.
    public static func byCluster(_ records: [AnalysisRecord], indicator: Indicator, options: SurveyOptions) -> [MeanSDBar] {
        PrevalenceCalculator.byCluster(records, indicator: indicator, options: options, analysisType: .standard)
            .enumerated().map { index, cluster in
                bar(position: index, label: "\(cluster.cluster)", result: cluster.result,
                    count: AnalysisMath.truncated(cluster.result.count))
            }
    }

    private static func bar(position: Int, label: String, result: PrevalenceResult, count: Int) -> MeanSDBar {
        let mean = result.mean.map(AnalysisMath.double)
        let deviation = AnalysisMath.double(result.standardDeviation ?? 0)
        let whisker = mean.map { $0 < 0 ? -(abs($0) + deviation) : abs($0) + deviation }
        return MeanSDBar(position: position, label: label, mean: mean, whiskerEnd: whisker, count: count)
    }
}
