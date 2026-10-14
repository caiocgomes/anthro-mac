import AnthroCore
import Foundation
import Observation

/// Gráfico de crescimento, port de `GraphDialog` (design D6 a D9).
@MainActor
@Observable
public final class GrowthChartModel {
    public let currentIndex: Int
    public private(set) var indicator: Indicator = .weightForAge
    public private(set) var mode: ChartDisplayMode = .zScore
    public private(set) var showMultiplePoints: Bool = false
    public private(set) var series: [ChartSeries] = []
    public private(set) var points: [MeasurementPoint] = []
    public private(set) var transitionMarker: TransitionMarker? = nil
    public private(set) var hasOutOfRangePoints: Bool = false
    public private(set) var fullXDomain: ClosedRange<Double> = 0...0
    public private(set) var fullYDomain: ClosedRange<Double> = 0...0
    public private(set) var visibleXDomain: ClosedRange<Double> = 0...0
    public private(set) var visibleYDomain: ClosedRange<Double> = 0...0

    public init(results: [AnthropometricResult], currentIndex: Int, indicator: Indicator, tables: GrowthReferenceTables, mode: ChartDisplayMode = .zScore) {
        self.currentIndex = 0
    }

    public var resultCount: Int { 0 }
    public var canShowMultiplePoints: Bool { false }
    public var showsConnectingLine: Bool { false }
    public var isEmpty: Bool { false }
    public var title: String { "" }
    public var xAxisTitle: String { "" }
    public var yAxisTitle: String { "" }
    public var legendText: String? { nil }

    public func setIndicator(_ indicator: Indicator) {}
    public func setMode(_ mode: ChartDisplayMode) {}
    public func setShowMultiplePoints(_ isOn: Bool) {}
    public func zoom(x: ClosedRange<Double>, y: ClosedRange<Double>) {}
    public func pan(byX dx: Double, byY dy: Double) {}
    public func resetZoom() {}
}
