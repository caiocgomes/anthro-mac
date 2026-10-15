import AnthroFeatures
import SwiftUI

/// `NSImportDialog`: um seletor de coluna por campo do inquérito, começando pela proposta automática. Confirmar só
/// fecha a folha; quem a abriu monta o rascunho depois, para que a pergunta sobre o inquérito aberto não apareça por
/// cima dela.
struct SurveyImportMappingSheet: View {
    let model: SurveyExchangeModel
    let onConfirm: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L10n.SurveyExchange.mappingTitle).font(.headline)
            Text(L10n.SurveyExchange.mappingHint)
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            if case .mapping(let columns, let mapping) = model.phase {
                Form {
                    ForEach(SurveyExchangeModel.importFields, id: \.self) { field in
                        Picker(L10n.SurveyExchange.label(field), selection: Binding(
                            get: { mapping[field] ?? "" },
                            set: { model.setMapping(field, column: $0.isEmpty ? nil : $0) })) {
                            Text(L10n.SurveyExchange.notMapped).tag("")
                            ForEach(columns, id: \.self) { Text($0).tag($0) }
                        }
                    }
                }
                .formStyle(.grouped)
                HStack {
                    Spacer()
                    Button(L10n.Survey.cancel, role: .cancel) { dismiss() }
                    .keyboardShortcut(.cancelAction)
                    Button(L10n.SurveyExchange.confirmImport) {
                        onConfirm()
                        dismiss()
                    }
                    .keyboardShortcut(.defaultAction)
                    .disabled(mapping[.sex] == nil)
                }
            }
        }
        .padding(20)
        .frame(width: 460, height: 560)
        .environment(\.locale, Locale(identifier: "pt_BR"))
    }
}
