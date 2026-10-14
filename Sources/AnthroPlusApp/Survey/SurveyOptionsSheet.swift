import AnthroFeatures
import SwiftUI

/// `NSOptionsDialog` redesenhado (design D10): atribuição automática, faixas etárias e limites de z; nada muda no
/// inquérito antes de Aplicar.
struct SurveyOptionsSheet: View {
    @Bindable var editor: SurveyOptionsEditorModel
    let onApply: (SurveyOptionsEditorModel) throws -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var errorMessage: String?
    /// Muda a cada restauração para recriar os campos de z com os valores novos.
    @State private var generation = 0

    var body: some View {
        VStack(spacing: 0) {
            Form {
                Section(L10n.Survey.autoIDSection) {
                    Toggle(L10n.Survey.cluster, isOn: $editor.autoIDCluster)
                    Toggle(L10n.Survey.team, isOn: $editor.autoIDTeam)
                    Toggle(L10n.Survey.recordID, isOn: $editor.autoIDRecord)
                    Toggle(L10n.Survey.household, isOn: $editor.autoIDHousehold)
                }
                Section(L10n.Survey.ageGroupsSection) {
                    ForEach(Array(editor.lowerBounds.indices), id: \.self) { index in
                        ageGroupRow(index)
                    }
                    HStack {
                        Button(L10n.Survey.addAgeGroup) { editor.addAgeGroup() }
                            .disabled(editor.lowerBounds.count >= 21)
                        Spacer()
                    }
                }
                Section(L10n.Survey.zBoundsSection) {
                    Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 8) {
                        GridRow {
                            Text("")
                            Text(L10n.Survey.standards).font(.caption).gridCellColumns(2)
                            Text(L10n.Survey.reference).font(.caption).gridCellColumns(2)
                        }
                        GridRow {
                            Text("")
                            Text(L10n.Survey.minimum).font(.caption2).foregroundStyle(.secondary)
                            Text(L10n.Survey.maximum).font(.caption2).foregroundStyle(.secondary)
                            Text(L10n.Survey.minimum).font(.caption2).foregroundStyle(.secondary)
                            Text(L10n.Survey.maximum).font(.caption2).foregroundStyle(.secondary)
                        }
                        ForEach(Indicator.allCases, id: \.self) { indicator in
                            GridRow {
                                Text(L10n.Indicators.title(indicator, isLength: nil))
                                ZBoundField(editor: editor, indicator: indicator, range: .standards, isMax: false)
                                ZBoundField(editor: editor, indicator: indicator, range: .standards, isMax: true)
                                ZBoundField(editor: editor, indicator: indicator, range: .reference, isMax: false)
                                ZBoundField(editor: editor, indicator: indicator, range: .reference, isMax: true)
                            }
                        }
                    }
                    .id(generation)
                }
            }
            .formStyle(.grouped)
            HStack {
                Button(L10n.Survey.resetDefaults) {
                    editor.resetToDefaults()
                    generation += 1
                }
                Spacer()
                Button(L10n.Survey.cancel, role: .cancel) { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Button(L10n.Survey.apply) { apply() }
                    .keyboardShortcut(.defaultAction)
            }
            .padding(16)
        }
        .frame(width: 720, height: 680)
        .environment(\.locale, Locale(identifier: "pt_BR"))
        .navigationTitle(L10n.Survey.optionsTitle)
        .alert(L10n.Survey.optionsTitle,
               isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private func ageGroupRow(_ index: Int) -> some View {
        let isLast = index == editor.lowerBounds.count - 1
        let upper = isLast ? editor.lastUpperBound : editor.lowerBounds[index + 1] - 1
        return HStack {
            Text("\(L10n.Survey.ageGroup) \(index + 1)").frame(width: 70, alignment: .leading)
            TextField("", value: Binding(get: { editor.lowerBounds[index] }, set: { editor.setLowerBound($0, at: index) }),
                      format: .number)
                .labelsHidden()
                .textFieldStyle(.roundedBorder)
                .frame(width: 70)
            Text(L10n.Survey.upTo)
            if isLast {
                TextField("", value: $editor.lastUpperBound, format: .number)
                    .labelsHidden()
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 70)
            } else {
                Text("\(upper)").monospacedDigit().frame(width: 70, alignment: .leading)
            }
            Spacer()
            Button { editor.removeAgeGroup(at: index) } label: {
                Image(systemName: "minus.circle")
            }
            .buttonStyle(.borderless)
            .help(L10n.Survey.removeAgeGroup)
        }
    }

    private func apply() {
        do {
            try onApply(editor)
            dismiss()
        } catch {
            errorMessage = SurveyErrorText.message(for: error)
        }
    }
}

/// Limite de z digitado como texto; a avaliação (e o ajuste mínimo e máximo de `CheckZRanges`) acontece ao sair do
/// campo ou confirmar, para não reescrever o número enquanto se digita.
private struct ZBoundField: View {
    let editor: SurveyOptionsEditorModel
    let indicator: Indicator
    let range: AgeRange
    let isMax: Bool

    @State private var text = ""
    @FocusState private var focused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            TextField("", text: $text)
                .labelsHidden()
                .textFieldStyle(.roundedBorder)
                .multilineTextAlignment(.trailing)
                .monospacedDigit()
                .frame(width: 70)
                .focused($focused)
                .onSubmit(commit)
                .onChange(of: focused) { _, isFocused in if !isFocused { commit() } }
            if let message = editor.zBoundOutcome(indicator, range: range, isMax: isMax).issueMessage {
                Text(message).font(.caption2).foregroundStyle(.orange).frame(width: 120, alignment: .leading)
            }
        }
        .onAppear { text = formatted }
    }

    private var formatted: String {
        ClinicalFormat.string(editor.zBound(indicator, range: range, isMax: isMax), places: 1)
    }

    private func commit() {
        editor.setZBound(text: text, indicator: indicator, range: range, isMax: isMax)
        if case .value = editor.zBoundOutcome(indicator, range: range, isMax: isMax) { text = formatted }
    }
}
