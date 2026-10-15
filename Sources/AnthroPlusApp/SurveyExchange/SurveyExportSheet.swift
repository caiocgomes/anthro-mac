import AnthroFeatures
import AppKit
import SwiftUI
import UniformTypeIdentifiers

/// `tsbSurveyExport_Click`: formato (XML, TXT ou CSV) e a pergunta sobre resultados, depois o local do arquivo.
struct SurveyExportSheet: View {
    @Bindable var model: SurveyExchangeModel
    let onFinished: (Result<SurveyExportWarning?, Error>) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var format: SurveyExportFormat = .semicolonCSV

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(L10n.SurveyExchange.exportTitle).font(.headline)
            Text("\(model.selectedSurveyIDs.count) \(L10n.SurveyExchange.checkedSurveys)").foregroundStyle(.secondary)
            Picker(L10n.Exchange.format, selection: $format) {
                Text(L10n.Exchange.formatXML).tag(SurveyExportFormat.xml)
                Text(L10n.Exchange.formatTabText).tag(SurveyExportFormat.tabText)
                Text(L10n.Exchange.formatCSV).tag(SurveyExportFormat.semicolonCSV)
            }
            .pickerStyle(.radioGroup)
            Toggle(L10n.Exchange.includeResults, isOn: $model.includeResults)
            HStack {
                Spacer()
                Button(L10n.Exchange.cancel, role: .cancel) { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Button(L10n.Exchange.export) { export() }
                    .keyboardShortcut(.defaultAction)
                    .disabled(!model.canExport)
            }
        }
        .padding(20)
        .frame(width: 380)
        .environment(\.locale, Locale(identifier: "pt_BR"))
    }

    private func export() {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = "\(L10n.SurveyExchange.defaultExportName).\(format.fileExtension)"
        panel.allowedContentTypes = [UTType(filenameExtension: format.fileExtension) ?? .data]
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do {
            let warning = try model.export(format: format, to: url)
            dismiss()
            onFinished(.success(warning))
        } catch {
            onFinished(.failure(error))
        }
    }
}
