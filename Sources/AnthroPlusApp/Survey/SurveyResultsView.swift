import AnthroFeatures
import AppKit
import Charts
import SwiftUI

/// Aba de resultados do inquérito (`tabNutriSurvey`, índice 1): indicador, filtro, gráfico com zoom por arraste e os
/// comandos Restaurar, Copiar gráfico e Imprimir gráfico (`tsbCopyGraph`, `tsbPrintGraph`).
struct SurveyResultsView: View {
    @Bindable var model: SurveyAnalysisModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            controls
            if let message = model.unavailableMessage {
                ContentUnavailableView(message, systemImage: "chart.bar.xaxis")
            } else {
                SurveyGraphChart(graph: model.graph, xDomain: model.xDomain, yDomain: model.yDomain) { x, y in
                    model.zoom(x: x, y: y)
                }
                Text(L10n.SurveyAnalysis.zoomHint).font(.caption).foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .onAppear { model.refreshGraph() }
        .onChange(of: model.indicator) { _, _ in model.refreshGraph() }
        .onChange(of: model.filter) { _, _ in model.refreshGraph() }
    }

    private var controls: some View {
        HStack(spacing: 12) {
            Picker(L10n.SurveyAnalysis.indicator, selection: $model.indicator) {
                Text(L10n.Indicators.weightForAge).tag(Indicator.weightForAge)
                Text(L10n.Indicators.lengthOrHeightForAge).tag(Indicator.lengthOrHeightForAge)
                Text(L10n.Indicators.bmiForAge).tag(Indicator.bmiForAge)
            }
            .frame(maxWidth: 320)
            Picker(L10n.SurveyAnalysis.filter, selection: $model.filter) {
                Text(L10n.SurveyAnalysis.filterAllChildren).tag(SurveyAnalysisModel.GraphFilter.allChildren)
                Text(L10n.SurveyAnalysis.filterBySex).tag(SurveyAnalysisModel.GraphFilter.bySex)
                Text(L10n.SurveyAnalysis.filterByCluster).tag(SurveyAnalysisModel.GraphFilter.byCluster)
                Text(L10n.SurveyAnalysis.filterByAgeGroup).tag(SurveyAnalysisModel.GraphFilter.byAgeGroup)
            }
            .frame(maxWidth: 260)
            Spacer()
            Button { model.resetZoom() } label: {
                Label(L10n.SurveyAnalysis.restore, systemImage: "arrow.uturn.backward")
            }
            Button { copyGraph() } label: {
                Label(L10n.SurveyAnalysis.copyGraph, systemImage: "doc.on.doc")
            }
            Button { printGraph() } label: {
                Label(L10n.SurveyAnalysis.printGraph, systemImage: "printer")
            }
        }
        .labelStyle(.titleAndIcon)
        .controlSize(.small)
        .disabled(model.unavailableMessage != nil)
        .environment(\.locale, Locale(identifier: "pt_BR"))
    }

    /// O gráfico atual numa vista fixa, para imagem e impressão.
    private var snapshot: some View {
        SurveyGraphChart(graph: model.graph, xDomain: model.xDomain, yDomain: model.yDomain, onZoom: nil)
            .frame(width: 900, height: 560)
            .padding(16)
            .background(Color.white)
            .environment(\.colorScheme, .light)
    }

    /// Copia o gráfico como imagem; gráfico vazio não é copiado (`canCopyGraph`).
    private func copyGraph() {
        guard model.canCopyGraph else { return }
        let renderer = ImageRenderer(content: snapshot)
        renderer.scale = 2
        guard let image = renderer.nsImage else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.writeObjects([image])
    }

    private func printGraph() {
        guard model.canCopyGraph else { return }
        let view = NSHostingView(rootView: snapshot)
        view.frame = NSRect(x: 0, y: 0, width: 932, height: 592)
        let info = NSPrintInfo.shared
        info.orientation = .landscape
        info.horizontalPagination = .fit
        info.verticalPagination = .fit
        NSPrintOperation(view: view, printInfo: info).run()
    }
}

/// Densidade contra a normal, ou barras de média com haste de DP, com zoom por retângulo de arraste.
struct SurveyGraphChart: View {
    let graph: SurveyAnalysisModel.Graph
    let xDomain: ClosedRange<Double>
    let yDomain: ClosedRange<Double>
    let onZoom: ((ClosedRange<Double>, ClosedRange<Double>) -> Void)?

    @State private var dragRect: CGRect?

    private static let tomato = Color(red: 1, green: 0.388, blue: 0.278)

    var body: some View {
        switch graph {
        case .empty(let title):
            Text(title).foregroundStyle(.secondary).frame(maxWidth: .infinity, maxHeight: .infinity)
        case .density(let series):
            zoomable(density(series))
        case .bars(let bars, let axisLabel):
            zoomable(barsChart(bars, axisLabel: axisLabel))
        }
    }

    private func color(_ color: SeriesColor) -> Color {
        switch color {
        case .green: .green
        case .red: .red
        case .violet: .purple
        case .blue: .blue
        }
    }

    private func density(_ series: [DensitySeries]) -> some View {
        Chart {
            ForEach(Array(series.enumerated()), id: \.offset) { index, line in
                ForEach(Array(zip(line.curve.x, line.curve.y).enumerated()), id: \.offset) { _, point in
                    LineMark(x: .value(L10n.SurveyAnalysis.zScore, point.0), y: .value(L10n.SurveyAnalysis.children, point.1),
                             series: .value("Série", line.label))
                        .foregroundStyle(by: .value("Série", line.label))
                        .lineStyle(StrokeStyle(lineWidth: index == 0 ? 3 : 2))
                }
            }
        }
        .chartForegroundStyleScale(domain: series.map(\.label), range: series.map { color($0.color) })
        .chartLegend(position: .top, alignment: .trailing)
        .chartXScale(domain: xDomain)
        .chartYScale(domain: yDomain)
        .chartXAxisLabel(L10n.SurveyAnalysis.zScore, alignment: .center)
        .chartYAxisLabel(L10n.SurveyAnalysis.children)
        .chartYAxis {
            AxisMarks { value in
                AxisGridLine()
                AxisTick()
                AxisValueLabel {
                    if let share = value.as(Double.self) { Text(share, format: .percent.precision(.fractionLength(0))) }
                }
            }
        }
        .chartPlotStyle { $0.clipped() }
    }

    private func barsChart(_ bars: [MeanSDBar], axisLabel: String) -> some View {
        Chart {
            RuleMark(y: .value(L10n.SurveyAnalysis.meanZScore, 0)).foregroundStyle(.black)
            ForEach(bars, id: \.position) { bar in
                barMarks(bar, axisLabel: axisLabel)
            }
        }
        .chartXScale(domain: xDomain)
        .chartYScale(domain: yDomain)
        .chartXAxis { barAxis(bars) }
        .chartXAxisLabel(axisLabel, alignment: .center)
        .chartYAxisLabel(L10n.SurveyAnalysis.meanZScore)
        .chartPlotStyle { $0.clipped() }
    }

    /// Barra de 0 até a média (tomate se positiva, preta se negativa), haste até sinal(m)(|m| + DP) e "n=N" na ponta.
    @ChartContentBuilder
    private func barMarks(_ bar: MeanSDBar, axisLabel: String) -> some ChartContent {
        let x = Double(bar.position)
        let yLabel = L10n.SurveyAnalysis.meanZScore
        if let range = bar.barRange {
            RectangleMark(xStart: .value(axisLabel, x - 0.35), xEnd: .value(axisLabel, x + 0.35),
                          yStart: .value(yLabel, range.lowerBound), yEnd: .value(yLabel, range.upperBound))
                .foregroundStyle(bar.isPositive ? Self.tomato : Color.black)
        }
        if let mean = bar.mean, let end = bar.whiskerEnd {
            RuleMark(x: .value(axisLabel, x), yStart: .value(yLabel, mean), yEnd: .value(yLabel, end))
                .foregroundStyle(Color.gray)
        }
        PointMark(x: .value(axisLabel, x), y: .value(yLabel, bar.whiskerEnd ?? 0))
            .opacity(0)
            .annotation(position: (bar.whiskerEnd ?? 0) < 0 ? .bottom : .top) {
                Text("n=\(bar.count)").font(.caption2)
            }
    }

    private func barAxis(_ bars: [MeanSDBar]) -> some AxisContent {
        AxisMarks(values: bars.map { Double($0.position) }) { value in
            AxisValueLabel {
                if let position = value.as(Double.self), let bar = bars.first(where: { Double($0.position) == position }) {
                    Text(bar.label).font(.caption2)
                }
            }
        }
    }

    /// Retângulo de seleção por arraste (`RubberBandSelection`), convertido para os valores dos eixos.
    @ViewBuilder
    private func zoomable(_ chart: some View) -> some View {
        if let onZoom {
            chart.chartOverlay { proxy in
                GeometryReader { geometry in
                    Rectangle().fill(.clear).contentShape(Rectangle())
                        .gesture(DragGesture(minimumDistance: 4)
                            .onChanged { value in
                                dragRect = CGRect(x: min(value.startLocation.x, value.location.x),
                                                  y: min(value.startLocation.y, value.location.y),
                                                  width: abs(value.location.x - value.startLocation.x),
                                                  height: abs(value.location.y - value.startLocation.y))
                            }
                            .onEnded { value in
                                dragRect = nil
                                guard let plot = proxy.plotFrame.map({ geometry[$0] }) else { return }
                                let start = CGPoint(x: value.startLocation.x - plot.origin.x, y: value.startLocation.y - plot.origin.y)
                                let end = CGPoint(x: value.location.x - plot.origin.x, y: value.location.y - plot.origin.y)
                                guard let x0 = proxy.value(atX: start.x, as: Double.self), let x1 = proxy.value(atX: end.x, as: Double.self),
                                      let y0 = proxy.value(atY: start.y, as: Double.self), let y1 = proxy.value(atY: end.y, as: Double.self)
                                else { return }
                                onZoom(min(x0, x1)...max(x0, x1), min(y0, y1)...max(y0, y1))
                            })
                    if let dragRect {
                        Rectangle().stroke(Color.accentColor, lineWidth: 1)
                            .background(Color.accentColor.opacity(0.1))
                            .frame(width: dragRect.width, height: dragRect.height)
                            .position(x: dragRect.midX, y: dragRect.midY)
                            .allowsHitTesting(false)
                    }
                }
            }
        } else {
            chart
        }
    }
}

/// Relatório gerado mostrado no app: uma linha por linha do texto e uma célula por campo (`SurveyReport.table`).
struct SurveyReportTableView: View {
    let title: String
    let table: [[String]]

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title).font(.headline)
            ScrollView([.horizontal, .vertical]) {
                Grid(alignment: .leading, horizontalSpacing: 14, verticalSpacing: 3) {
                    ForEach(Array(table.enumerated()), id: \.offset) { _, row in
                        GridRow {
                            ForEach(Array(row.enumerated()), id: \.offset) { _, cell in
                                Text(cell).font(.system(size: 11)).fixedSize()
                            }
                        }
                    }
                }
                .textSelection(.enabled)
                .padding(10)
            }
            .background(Color(nsColor: .textBackgroundColor))
            .border(Color.secondary.opacity(0.3))
            HStack {
                Spacer()
                Button(L10n.SurveyAnalysis.close) { dismiss() }
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(16)
        .frame(minWidth: 860, idealWidth: 1000, minHeight: 560, idealHeight: 700)
    }
}
