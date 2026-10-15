import AnthroAnalysis
import AnthroCore
import AnthroIO
import Foundation
import Observation

public enum SeriesColor: Sendable, Equatable {
    case green, red, violet, blue
}

/// Uma curva do gráfico de densidade, com rótulo e cor.
public struct DensitySeries: Sendable, Equatable {
    public let label: String
    public let color: SeriesColor
    public let curve: DensityCurve

    public init(label: String, color: SeriesColor, curve: DensityCurve) {
        self.label = label
        self.color = color
        self.curve = curve
    }
}

/// Aba de resultados e relatórios do inquérito aberto (`tabNutriSurvey_Selected`, `tsComboFilter_SelectedIndexChanged`,
/// `tsbExportExcel_Click`, `tsbReportExcelGlobal_Click`).
@MainActor
@Observable
public final class SurveyAnalysisModel {
    public enum GraphFilter: CaseIterable, Sendable {
        case allChildren, bySex, byCluster, byAgeGroup
    }

    public enum Graph: Equatable {
        case empty(title: String)
        case density([DensitySeries])
        case bars([MeanSDBar], axisLabel: String)
    }

    public var indicator: Indicator = .weightForAge
    public var filter: GraphFilter = .allChildren
    public private(set) var graph: Graph = .empty(title: "")
    public private(set) var xDomain: ClosedRange<Double> = 0...0
    public private(set) var yDomain: ClosedRange<Double> = 0...0
    public private(set) var errorMessage: String?
    public private(set) var lastReport: SurveyReport?

    public init(records: [AnalysisRecord], options: SurveyOptions, surveyName: String, recordCount: Int) {}

    public func update(records: [AnalysisRecord], recordCount: Int) {}

    public var canShowGraphs: Bool { false }

    public var unavailableMessage: String? { nil }

    public func refreshGraph() {}

    public func zoom(x: ClosedRange<Double>, y: ClosedRange<Double>) {}

    public func resetZoom() {}

    public var canCopyGraph: Bool { false }

    public func exportReport(_ kind: SurveyReportKind, to url: URL, opener: ReportOpening) {}
}
