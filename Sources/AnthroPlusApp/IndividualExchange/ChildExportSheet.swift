import AnthroFeatures
import AppKit
import SwiftUI
import UniformTypeIdentifiers

/// `tsbChildrenExport_Click`: formato (XML, TXT ou CSV) e a pergunta sobre resultados, depois o local do arquivo.
struct ChildExportSheet: View {
    @Bindable var model: ChildExchangeModel
    let onFinished: (Error?) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var format: ChildExportFormat = .semicolonCSV

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(L10n.Exchange.exportTitle).font(.headline)
            Text("\(model.selectedChildIDs.count) \(L10n.Exchange.checkedChildren)").foregroundStyle(.secondary)
            Picker(L10n.Exchange.format, selection: $format) {
                Text(L10n.Exchange.formatXML).tag(ChildExportFormat.xml)
                Text(L10n.Exchange.formatTabText).tag(ChildExportFormat.tabText)
                Text(L10n.Exchange.formatCSV).tag(ChildExportFormat.semicolonCSV)
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
        panel.nameFieldStringValue = "\(L10n.Exchange.defaultExportName).\(format.fileExtension)"
        panel.allowedContentTypes = [UTType(filenameExtension: format.fileExtension) ?? .data]
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do {
            try model.export(format: format, to: url)
            dismiss()
            onFinished(nil)
        } catch {
            onFinished(error)
        }
    }
}
