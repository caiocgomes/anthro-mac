import AnthroCore
import Foundation
import Observation

/// Gráfico de crescimento, port de `GraphDialog` (design D6 a D9).
@MainActor
@Observable
public final class GrowthChartModel {
    public let currentIndex: Int
    public private(set) var indicator: Indicator
    public private(set) var mode: ChartDisplayMode
    public private(set) var showMultiplePoints: Bool = false
    public private(set) var series: [ChartSeries] = []
    public private(set) var points: [MeasurementPoint] = []
    public private(set) var transitionMarker: TransitionMarker? = nil
    public private(set) var hasOutOfRangePoints: Bool = false
    public private(set) var fullXDomain: ClosedRange<Double> = 0...0
    public private(set) var fullYDomain: ClosedRange<Double> = 0...0
    public private(set) var visibleXDomain: ClosedRange<Double> = 0...0
    public private(set) var visibleYDomain: ClosedRange<Double> = 0...0

    @ObservationIgnored private let results: [AnthropometricResult]
    @ObservationIgnored private let tables: GrowthReferenceTables

    /// `REF_UPPERAGELIMITMONTHS_W4A` inlinado em `DrawMeasures`; os demais indicadores vão até 228 meses.
    private static let weightUpperMonths = 108
    private static let otherUpperMonths = 228

    public init(results: [AnthropometricResult], currentIndex: Int, indicator: Indicator, tables: GrowthReferenceTables,
                mode: ChartDisplayMode = .zScore) {
        self.results = results
        self.currentIndex = currentIndex
        self.indicator = indicator
        self.mode = mode
        self.tables = tables
        redraw()
    }

    public var resultCount: Int { results.count }

    /// `InitToolStrip`: a escolha só aparece com mais de um resultado.
    public var canShowMultiplePoints: Bool { results.count > 1 }

    public var showsConnectingLine: Bool { showMultiplePoints && points.count > 1 }

    public var isEmpty: Bool { points.isEmpty }

    public var title: String { isEmpty ? L10n.Chart.noData : L10n.Chart.title }

    public var xAxisTitle: String {
        hasOutOfRangePoints && !isEmpty ? L10n.Chart.xAxis + L10n.Chart.outOfRangeSuffix : L10n.Chart.xAxis
    }

    public var yAxisTitle: String {
        switch indicator {
        case .weightForAge: L10n.Chart.weightAxis
        case .lengthOrHeightForAge: L10n.Chart.lengthOrHeightAxis
        case .bmiForAge: L10n.Chart.bmiAxis
        }
    }

    /// Legenda do ponto atual (`verticalLine.Label` de `DrawMeasures`); `nil` se o ponto atual não foi desenhado.
    public var legendText: String? {
        guard points.contains(where: { $0.resultIndex == currentIndex }) else { return nil }
        let result = results[currentIndex]
        var text = ""
        if let days = result.ageInDays, days > 0 {
            text = AgeText.localized(months: AgeText.wholeMonths(AgeMath.daysToMonths(days))) + ", "
        }
        let score = result.score(indicator)
        switch mode {
        case .zScore:
            text += "\(L10n.Chart.legendZScore): \(ClinicalFormat.string(score.zScore, places: 2))"
        case .percentile:
            text += "\(L10n.Chart.legendPercentile): \(ClinicalFormat.string(score.percentile, places: 1))"
        }
        return text
    }

    public func setIndicator(_ indicator: Indicator) {
        self.indicator = indicator
        redraw()
    }

    public func setMode(_ mode: ChartDisplayMode) {
        self.mode = mode
        redraw()
    }

    public func setShowMultiplePoints(_ isOn: Bool) {
        showMultiplePoints = isOn && canShowMultiplePoints
        redraw()
    }

    /// `RubberBandSelection`; seleção com largura ou altura zero é ignorada.
    public func zoom(x: ClosedRange<Double>, y: ClosedRange<Double>) {
        guard x.upperBound > x.lowerBound, y.upperBound > y.lowerBound else { return }
        visibleXDomain = x
        visibleYDomain = y
    }

    /// `HorizontalDrag` e `VerticalDrag`.
    public func pan(byX dx: Double, byY dy: Double) {
        visibleXDomain = (visibleXDomain.lowerBound + dx)...(visibleXDomain.upperBound + dx)
        visibleYDomain = (visibleYDomain.lowerBound + dy)...(visibleYDomain.upperBound + dy)
    }

    /// `OriginalDimensions`.
    public func resetZoom() {
        visibleXDomain = fullXDomain
        visibleYDomain = fullYDomain
    }

    // MARK: Desenho

    /// `RefreshGraph`: curvas, faixas e pontos novos; o zoom é descartado.
    private func redraw() {
        let curves = curveSeries()
        let lastX = curves.first?.points.last?.x ?? 0
        fullXDomain = 0...(lastX + (indicator == .weightForAge ? 10 : 20))
        let lowerY = Self.ordinateWorldMin(indicator)
        let upperY = indicator == .bmiForAge ? 38 : (curves.last?.points.map(\.y).max() ?? lowerY)
        fullYDomain = lowerY...max(upperY, lowerY)
        resetZoom()

        let (measured, outOfRange) = measurementPoints()
        points = measured
        hasOutOfRangePoints = outOfRange
        if measured.isEmpty {
            // `gSurface.Clear()`.
            series = []
            transitionMarker = nil
        } else {
            series = curves
            transitionMarker = marker(lowest: curves.first)
        }
    }

    /// `DrawIndicatorGraph`: no z-score, -1 e +1 DP só para IMC; no percentil, 3º a 97º.
    private func curveSeries() -> [ChartSeries] {
        let sex = results.indices.contains(currentIndex) ? (results[currentIndex].sex ?? .girl) : .girl
        let kind: CurveKind = mode == .zScore ? .zScore : .percentile
        let curvePoints = GrowthCurves.points(indicator, sex: sex, kind: kind, tables: tables)
        let lines: [(index: Int, label: String, style: CurveStyle)]
        switch mode {
        case .zScore:
            let sd = L10n.Chart.standardDeviation
            var all: [(Int, String, CurveStyle)] = [
                (0, "-3 \(sd)", .sd3), (1, "-2 \(sd)", .sd2), (2, "-1 \(sd)", .sd1), (3, L10n.Chart.median, .median),
                (4, "+1 \(sd)", .sd1), (5, "+2 \(sd)", .sd2), (6, "+3 \(sd)", .sd3),
            ]
            if indicator != .bmiForAge {
                all.removeAll { $0.2 == .sd1 }
            }
            lines = all
        case .percentile:
            let styles: [CurveStyle] = [.sd2, .sd1, .median, .sd1, .sd2]
            lines = L10n.Chart.percentileLabels.enumerated().map { ($0.offset, $0.element, styles[$0.offset]) }
        }
        return lines.map { line in
            ChartSeries(id: line.index, label: line.label, style: line.style,
                        points: curvePoints.map { ChartXY(x: $0.xMonths, y: $0.values[line.index]) })
        }
    }

    /// Marca de 24 meses de estatura e IMC, na altura do primeiro ponto da curva mais baixa.
    private func marker(lowest: ChartSeries?) -> TransitionMarker? {
        guard indicator != .weightForAge, let y = lowest?.points.first?.y else { return nil }
        return TransitionMarker(x: 24, y: y, leftLabel: L10n.Chart.lengthMarker, leftX: 23.5,
                                rightLabel: L10n.Chart.heightMarker, rightX: 24.5)
    }

    /// `DrawMeasures`.
    private func measurementPoints() -> (points: [MeasurementPoint], outOfRange: Bool) {
        var points: [MeasurementPoint] = []
        var outOfRange = false
        let upperMonths = indicator == .weightForAge ? Self.weightUpperMonths : Self.otherUpperMonths
        for (index, result) in results.enumerated() {
            guard showMultiplePoints || index == currentIndex else { continue }
            guard result.score(indicator).zScore != nil else { continue }
            guard let months = result.ageInMonths, months >= 0,
                  AgeText.wholeMonths(months) <= upperMonths else {
                outOfRange = true
                continue
            }
            guard let y = plottedValue(result) else { continue }
            points.append(MeasurementPoint(resultIndex: index, x: Self.double(months), y: Self.double(y),
                                           guideStyle: index == currentIndex ? .current : .other))
        }
        return (points, outOfRange)
    }

    private func plottedValue(_ result: AnthropometricResult) -> Decimal? {
        switch indicator {
        case .weightForAge:
            return result.weight
        case .lengthOrHeightForAge:
            return result.adjustedLengthOrHeight
        case .bmiForAge:
            guard let weight = result.weight, let adjusted = result.adjustedLengthOrHeight else { return nil }
            return Anthropometry.exactBMI(weight: weight, lengthOrHeight: adjusted)
        }
    }

    /// `GetOrdinateWorldMin`.
    private static func ordinateWorldMin(_ indicator: Indicator) -> Double {
        switch indicator {
        case .weightForAge: 0
        case .lengthOrHeightForAge: 40
        case .bmiForAge: 8
        }
    }

    /// `(double)decimal`, arredondado corretamente a partir da representação decimal completa.
    private static func double(_ value: Decimal) -> Double {
        Double(value.description) ?? NSDecimalNumber(decimal: value).doubleValue
    }
}
