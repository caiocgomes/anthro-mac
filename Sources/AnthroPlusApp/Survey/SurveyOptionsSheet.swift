import AnthroFeatures
import SwiftUI

/// `NSOptionsDialog` redesenhado (design D10): atribuição automática, faixas etárias e limites de z; nada muda no
/// inquérito antes de Aplicar.
struct SurveyOptionsSheet: View {
    @Bindable var editor: SurveyOptionsEditorModel
    let onApply: (SurveyOptionsEditorModel) throws -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var errorMessage: String?
    /// Muda a cada restauração e a cada faixa incluída ou removida, para recriar os campos com os valores vigentes.
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
                    .id(generation)
                    HStack {
                        Button(L10n.Survey.addAgeGroup) {
                            editor.addAgeGroup()
                            generation += 1
                        }
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
            MonthField(value: editor.lowerBounds[index]) { editor.setLowerBound($0, at: index) }
            Text(L10n.Survey.upTo)
            if isLast {
                MonthField(value: editor.lastUpperBound) { editor.lastUpperBound = $0 }
            } else {
                Text("\(upper)").monospacedDigit().frame(width: 70, alignment: .leading)
            }
            Spacer()
            Button {
                editor.removeAgeGroup(at: index)
                // As linhas são identificadas pelo índice: recriá-las evita que um campo em foco mostre o valor de outro.
                generation += 1
            } label: {
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

/// Limite de z digitado como texto. Cada alteração vai ao editor na hora (com o ajuste mínimo e máximo de
/// `CheckZRanges`), para que Aplicar nunca ignore o último valor; o texto só é reescrito com o valor vigente ao sair do
/// campo, para não mudar o número enquanto se digita.
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
                .onChange(of: text) { _, newValue in
                    // Só a digitação envia: abrir a folha não pode reescrever um limite gravado com mais casas.
                    if focused { editor.setZBound(text: newValue, indicator: indicator, range: range, isMax: isMax) }
                }
                .onSubmit(reformat)
                .onChange(of: focused) { _, isFocused in if !isFocused { reformat() } }
            if let message = editor.zBoundOutcome(indicator, range: range, isMax: isMax).issueMessage {
                Text(message).font(.caption2).foregroundStyle(.orange).frame(width: 120, alignment: .leading)
            }
        }
        .onAppear { text = formatted }
    }

    private var formatted: String {
        ClinicalFormat.string(editor.zBound(indicator, range: range, isMax: isMax), places: 1)
    }

    private func reformat() {
        if case .value = editor.zBoundOutcome(indicator, range: range, isMax: isMax) { text = formatted }
    }
}

/// Mês inteiro de uma faixa etária; números válidos vão ao editor na hora, e o texto volta ao valor vigente ao sair.
private struct MonthField: View {
    let value: Int
    let onChange: (Int) -> Void

    @State private var text = ""
    @FocusState private var focused: Bool

    var body: some View {
        TextField("", text: $text)
            .labelsHidden()
            .textFieldStyle(.roundedBorder)
            .multilineTextAlignment(.trailing)
            .monospacedDigit()
            .frame(width: 70)
            .focused($focused)
            .onChange(of: text) { _, newValue in
                if focused, let number = Int(newValue.trimmingCharacters(in: .whitespaces)) { onChange(number) }
            }
            .onChange(of: focused) { _, isFocused in if !isFocused { text = String(value) } }
            .onChange(of: value) { _, newValue in if !focused { text = String(newValue) } }
            .onAppear { text = String(value) }
    }
}
