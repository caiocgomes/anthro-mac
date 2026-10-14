import AnthroFeatures
import Charts
import SwiftUI

/// Gráfico de crescimento em Swift Charts, desenhado a partir de `GrowthChartModel` (design D6 a D9).
struct GrowthChartView: View {
    let model: GrowthChartModel
    /// Desligado na cópia renderizada para exportação.
    var isInteractive = true

    @State private var selection: CGRect?
    @State private var lastPan: CGSize = .zero

    /// `_CURPOINTLINECOLOR`, `_OTHERPOINTLINECOLOR` e `_VLINECOLOR` de `GraphDialog`.
    private static let currentGuide = Color(red: 192 / 255, green: 16 / 255, blue: 16 / 255)
    private static let otherGuide = Color(red: 128 / 255, green: 128 / 255, blue: 128 / 255).opacity(96 / 255)
    private static let transitionLine = Color(red: 192 / 255, green: 192 / 255, blue: 192 / 255)
    private static let navy = Color(red: 0, green: 0, blue: 128 / 255)

    var body: some View {
        VStack(spacing: 6) {
            Text(model.title)
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            if model.isEmpty {
                Spacer()
            } else {
                chart
            }
        }
    }

    private var chart: some View {
        Chart {
            ForEach(model.series) { series in
                ForEach(Array(series.points.enumerated()), id: \.offset) { _, point in
                    LineMark(x: .value("x", point.x), y: .value("y", point.y), series: .value("curva", series.label))
                        .foregroundStyle(Self.color(series.style))
                        .lineStyle(StrokeStyle(lineWidth: 2))
                        .interpolationMethod(.linear)
                }
                if let last = series.points.last {
                    PointMark(x: .value("x", last.x), y: .value("y", last.y))
                        .opacity(0)
                        .annotation(position: .trailing, alignment: .leading, spacing: 4) {
                            Text(series.label)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Self.color(series.style))
                        }
                }
            }

            if let marker = model.transitionMarker {
                RuleMark(x: .value("x", marker.x))
                    .foregroundStyle(Self.transitionLine)
                    .lineStyle(StrokeStyle(lineWidth: 2.3))
            }

            ForEach(Array(model.points.enumerated()), id: \.offset) { _, point in
                let color = point.guideStyle == .current ? Self.currentGuide : Self.otherGuide
                RuleMark(x: .value("x", point.x))
                    .foregroundStyle(color)
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [2, 3]))
                RuleMark(y: .value("y", point.y))
                    .foregroundStyle(color)
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [2, 3]))
            }

            if model.showsConnectingLine {
                ForEach(Array(model.points.enumerated()), id: \.offset) { _, point in
                    LineMark(x: .value("x", point.x), y: .value("y", point.y), series: .value("curva", "medidas"))
                        .foregroundStyle(Self.navy.opacity(160 / 255))
                        .lineStyle(StrokeStyle(lineWidth: 2))
                }
            }

            ForEach(Array(model.points.enumerated()), id: \.offset) { _, point in
                PointMark(x: .value("x", point.x), y: .value("y", point.y))
                    .symbol(.circle)
                    .symbolSize(64)
                    .foregroundStyle(Self.navy)
            }
        }
        .chartXScale(domain: model.visibleXDomain)
        .chartYScale(domain: model.visibleYDomain)
        .chartXAxis {
            AxisMarks(values: .stride(by: 12)) { _ in
                AxisGridLine()
                AxisTick(length: 8)
                AxisValueLabel()
            }
            AxisMarks(values: .stride(by: 1)) { _ in
                AxisTick(length: 4)
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { _ in
                AxisGridLine()
                AxisTick()
                AxisValueLabel()
            }
        }
        .chartXAxisLabel(model.xAxisTitle, position: .bottom, alignment: .center)
        .chartYAxisLabel(model.yAxisTitle, position: .leading, alignment: .center)
        .chartLegend(.hidden)
        .chartPlotStyle { plot in
            plot.clipped()
        }
        .overlay(alignment: .topLeading) { legend }
        .chartOverlay { proxy in
            GeometryReader { geometry in
                ZStack(alignment: .topLeading) {
                    markerLabels(proxy: proxy, geometry: geometry)
                    if isInteractive {
                        interactionLayer(proxy: proxy, geometry: geometry)
                    }
                }
            }
        }
    }

    // MARK: Legenda e rótulos

    @ViewBuilder
    private var legend: some View {
        if let text = model.legendText {
            HStack(spacing: 8) {
                Rectangle()
                    .fill(Self.currentGuide)
                    .frame(width: 18, height: 2)
                Text(text).font(.callout.monospacedDigit())
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(.background.opacity(0.85), in: RoundedRectangle(cornerRadius: 6))
            .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(Color.gray.opacity(0.4)))
            .padding(.leading, 64)
            .padding(.top, 12)
        }
    }

    /// "COMPRIMENTO" à esquerda e "ESTATURA" à direita da linha de 24 meses, na altura da curva mais baixa.
    /// Ficam fora da área recortada do gráfico para que o rótulo da esquerda não seja cortado no eixo.
    @ViewBuilder
    private func markerLabels(proxy: ChartProxy, geometry: GeometryProxy) -> some View {
        if let marker = model.transitionMarker, let plotFrame = proxy.plotFrame,
           model.visibleXDomain.contains(marker.x), model.visibleYDomain.contains(marker.y),
           let x = proxy.position(forX: marker.x), let y = proxy.position(forY: marker.y) {
            let plot = geometry[plotFrame]
            let origin = CGPoint(x: plot.minX + x, y: plot.minY + y)
            markerLabel(marker.leftLabel)
                .fixedSize()
                .frame(width: 200, alignment: .trailing)
                .position(x: origin.x - 6 - 100, y: origin.y - 10)
            markerLabel(marker.rightLabel)
                .fixedSize()
                .frame(width: 200, alignment: .leading)
                .position(x: origin.x + 6 + 100, y: origin.y - 10)
        }
    }

    private func markerLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 12, weight: .bold))
            .foregroundStyle(Self.otherGuide)
            .allowsHitTesting(false)
    }

    /// `_SD3COLOR` preto (primário no modo escuro, D12), `_SD2COLOR` vermelho, `_SD1COLOR` Goldenrod, `_MCOLOR` verde.
    static func color(_ style: CurveStyle) -> Color {
        switch style {
        case .sd3: .primary
        case .sd2: .red
        case .sd1: Color(red: 218 / 255, green: 165 / 255, blue: 32 / 255)
        case .median: Color(red: 0, green: 128 / 255, blue: 0)
        }
    }

    // MARK: Zoom e deslocamento

    /// Arrastar seleciona a área de zoom (`RubberBandSelection`); com Shift, desloca (`HorizontalDrag`, `VerticalDrag`).
    private func interactionLayer(proxy: ChartProxy, geometry: GeometryProxy) -> some View {
        let plot = proxy.plotFrame.map { geometry[$0] } ?? .zero
        let pan = DragGesture(minimumDistance: 2)
            .modifiers(.shift)
            .onChanged { value in
                let step = CGSize(width: value.translation.width - lastPan.width,
                                  height: value.translation.height - lastPan.height)
                lastPan = value.translation
                guard plot.width > 0, plot.height > 0 else { return }
                let x = model.visibleXDomain, y = model.visibleYDomain
                model.pan(byX: -Double(step.width / plot.width) * (x.upperBound - x.lowerBound),
                          byY: Double(step.height / plot.height) * (y.upperBound - y.lowerBound))
            }
            .onEnded { _ in lastPan = .zero }
        let zoom = DragGesture(minimumDistance: 2)
            .onChanged { value in
                selection = CGRect(x: min(value.startLocation.x, value.location.x),
                                   y: min(value.startLocation.y, value.location.y),
                                   width: abs(value.location.x - value.startLocation.x),
                                   height: abs(value.location.y - value.startLocation.y))
            }
            .onEnded { value in
                selection = nil
                let start = CGPoint(x: value.startLocation.x - plot.minX, y: value.startLocation.y - plot.minY)
                let end = CGPoint(x: value.location.x - plot.minX, y: value.location.y - plot.minY)
                guard let x0 = proxy.value(atX: start.x, as: Double.self), let x1 = proxy.value(atX: end.x, as: Double.self),
                      let y0 = proxy.value(atY: start.y, as: Double.self), let y1 = proxy.value(atY: end.y, as: Double.self)
                else { return }
                model.zoom(x: min(x0, x1)...max(x0, x1), y: min(y0, y1)...max(y0, y1))
            }
        return Rectangle()
            .fill(.clear)
            .contentShape(Rectangle())
            .gesture(pan.exclusively(before: zoom))
            .overlay(alignment: .topLeading) {
                if let selection {
                    Rectangle()
                        .fill(Color.accentColor.opacity(0.12))
                        .overlay(Rectangle().strokeBorder(Color.accentColor, style: StrokeStyle(lineWidth: 1, dash: [4, 3])))
                        .frame(width: selection.width, height: selection.height)
                        .offset(x: selection.minX, y: selection.minY)
                        .allowsHitTesting(false)
                }
            }
    }
}
