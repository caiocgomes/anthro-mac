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
    public static func computeOnlyNegative(_ indicator: Indicator) -> Bool { false }

    public static func compute(_ population: [AnalysisRecord], indicator: Indicator, options: SurveyOptions,
                               analysisType: AnalysisType, isTotal: Bool, byCluster: Bool,
                               improvedClusterAnalysis: Bool) throws -> PrevalenceResult {
        PrevalenceResult(count: 0, oedemaCount: 0, mean: nil, standardDeviation: nil, prevalences: [:], intervals: [:])
    }

    public static func byAgeGroups(_ records: [AnalysisRecord], indicator: Indicator, options: SurveyOptions,
                                   analysisType: AnalysisType, sex: Sex?, improvedClusterAnalysis: Bool) throws -> [PrevalenceResult] {
        []
    }

    public static func byCluster(_ records: [AnalysisRecord], indicator: Indicator, options: SurveyOptions,
                                 analysisType: AnalysisType) -> [ClusterPrevalence] {
        []
    }

    public static func filtered(_ records: [AnalysisRecord], sex: Sex?, onlyWithCluster: Bool) -> [AnalysisRecord] {
        []
    }
}
