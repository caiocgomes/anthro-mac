import AnthroFeatures
import AppKit
import SwiftUI
import UniformTypeIdentifiers

/// `GraphDialog` como sheet redimensionável (design D11): indicador, modo, pontos, restaurar, copiar, exportar e imprimir.
struct GrowthChartSheet: View {
    let model: GrowthChartModel

    @Environment(\.dismiss) private var dismiss
    @State private var exportFailed = false

    var body: some View {
        VStack(spacing: 0) {
            toolbar
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
            Divider()
            GrowthChartView(model: model)
                .padding(16)
            Divider()
            HStack {
                Text(L10n.Chart.zoomHint)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Button(L10n.Chart.close) { dismiss() }
                    .keyboardShortcut(.cancelAction)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .frame(minWidth: 900, idealWidth: 1100, minHeight: 640, idealHeight: 760)
        .environment(\.locale, Locale(identifier: "pt_BR"))
        .alert(L10n.Chart.exportFailed, isPresented: $exportFailed) {
            Button("OK", role: .cancel) {}
        }
    }

    private var toolbar: some View {
        HStack(spacing: 14) {
            Picker(L10n.Chart.indicator, selection: Binding(get: { model.indicator }, set: { model.setIndicator($0) })) {
                ForEach(Indicator.allCases, id: \.self) { indicator in
                    Text(L10n.Indicators.title(indicator, isLength: nil)).tag(indicator)
                }
            }
            .fixedSize()
            Picker(L10n.Chart.mode, selection: Binding(get: { model.mode }, set: { model.setMode($0) })) {
                ForEach(ChartDisplayMode.allCases, id: \.self) { mode in
                    Text(mode.title).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .frame(width: 200)
            if model.canShowMultiplePoints {
                Toggle(L10n.Chart.multiplePoints,
                       isOn: Binding(get: { model.showMultiplePoints }, set: { model.setShowMultiplePoints($0) }))
                    .toggleStyle(.checkbox)
            }
            Spacer()
            Button { model.resetZoom() } label: {
                Label(L10n.Chart.resetZoom, systemImage: "arrow.up.left.and.down.right.magnifyingglass")
            }
            .help(L10n.Chart.resetZoom)
            Button { copy() } label: {
                Label(L10n.Chart.copy, systemImage: "doc.on.doc")
            }
            .help(L10n.Chart.copy)
            .disabled(model.isEmpty)
            Menu {
                Button(L10n.Chart.exportPDF) { export(as: .pdf) }
                Button(L10n.Chart.exportPNG) { export(as: .png) }
            } label: {
                Label(L10n.Chart.export, systemImage: "square.and.arrow.up")
            }
            .menuIndicator(.hidden)
            .fixedSize()
            .help(L10n.Chart.export)
            .disabled(model.isEmpty)
            Button { print() } label: {
                Label(L10n.Chart.print, systemImage: "printer")
            }
            .help(L10n.Chart.print)
            .disabled(model.isEmpty)
        }
        .labelStyle(.iconOnly)
    }

    // MARK: Cópia, exportação e impressão

    /// Cópia do gráfico em tamanho fixo, fundo branco e modo claro, para que a imagem não saia vazia nem escura.
    private func renderedImage() -> CGImage? {
        let content = GrowthChartView(model: model, isInteractive: false)
            .padding(24)
            .frame(width: 1200, height: 800)
            .background(Color.white)
            .environment(\.colorScheme, .light)
            .environment(\.locale, Locale(identifier: "pt_BR"))
        let renderer = ImageRenderer(content: content)
        renderer.scale = 2
        return renderer.cgImage
    }

    private func copy() {
        if !ChartExport.copy(renderedImage(), to: .general) { exportFailed = true }
    }

    private func export(as type: UTType) {
        guard let image = renderedImage(),
              let data = type == .pdf ? ChartExport.pdfData(image) : ChartExport.pngData(image) else {
            exportFailed = true
            return
        }
        let panel = NSSavePanel()
        panel.allowedContentTypes = [type]
        panel.canCreateDirectories = true
        panel.nameFieldStringValue = ChartExport.suggestedFileName(indicator: model.indicator, mode: model.mode, date: Date())
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do {
            try data.write(to: url, options: .atomic)
        } catch {
            exportFailed = true
        }
    }

    private func print() {
        guard let image = renderedImage(), let data = ChartExport.pdfData(image),
              let operation = ChartExport.printOperation(pdfData: data) else {
            exportFailed = true
            return
        }
        operation.run()
    }
}
