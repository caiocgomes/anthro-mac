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

    public var barRange: ClosedRange<Double>? { nil }

    public var isPositive: Bool { false }
}

/// `GetValuesForCandlePlotByAge` e `GetValuesForCandlePlotByCluster`.
public enum MeanSDBars {
    public static func byAgeGroup(_ records: [AnalysisRecord], indicator: Indicator, options: SurveyOptions) -> [MeanSDBar] {
        []
    }

    public static func byCluster(_ records: [AnalysisRecord], indicator: Indicator, options: SurveyOptions) -> [MeanSDBar] {
        []
    }
}
