import AnthroFeatures
import SwiftUI

struct AdditionalDataEditorPresentation: Identifiable {
    let id = UUID()
    let editor: AdditionalDataEditorModel
}

/// `AdditionalDataDialog`: árvore de seções e variáveis (sempre expandida, como `ExpandAll`) e o painel do item
/// selecionado; nada sai do editor antes de Aplicar (design D7).
struct AdditionalDataEditorSheet: View {
    @Bindable var editor: AdditionalDataEditorModel
    let title: String
    let onApply: (AdditionalDataEditorModel) throws -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                VStack(spacing: 0) {
                    tree
                    Divider()
                    treeActions
                }
                .frame(width: 280)
                Divider()
                ScrollView {
                    editionPanel
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                // O painel é refeito a cada seleção, para que os campos mostrem o item escolhido.
                .id(selectionKey)
            }
            Divider()
            HStack {
                Spacer()
                Button(L10n.AddData.cancel, role: .cancel) { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Button(L10n.AddData.apply) { apply() }
                    .keyboardShortcut(.defaultAction)
            }
            .padding(16)
        }
        .frame(width: 720, height: 520)
        .environment(\.locale, Locale(identifier: "pt_BR"))
        .navigationTitle(title)
        .alert(title, isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "")
        }
    }

    // MARK: Árvore

    private var tree: some View {
        List(selection: Binding(get: { selectionKey }, set: { editor.selection = Self.selection(from: $0) })) {
            if editor.definition.sections.isEmpty {
                Text(L10n.AddData.emptyDefinition).foregroundStyle(.secondary)
            }
            ForEach(Array(editor.definition.sections.enumerated()), id: \.offset) { sectionIndex, section in
                Label(Self.title(section.identifier), systemImage: "folder")
                    .tag(Optional("s:\(sectionIndex)"))
                ForEach(Array(section.variables.enumerated()), id: \.offset) { variableIndex, variable in
                    Label(Self.title(variable.identifier), systemImage: Self.symbol(variable.kind))
                        .padding(.leading, 18)
                        .tag(Optional("v:\(sectionIndex):\(variableIndex)"))
                }
            }
        }
        .listStyle(.inset)
    }

    private var treeActions: some View {
        HStack(spacing: 8) {
            Button { editor.addSection() } label: { Label(L10n.AddData.newSection, systemImage: "folder.badge.plus") }
            Button { editor.addVariable() } label: { Label(L10n.AddData.newVariable, systemImage: "plus") }
                .disabled(!editor.canAddVariable)
            Spacer()
            Button(role: .destructive) { editor.deleteSelected() } label: {
                Label(L10n.AddData.delete, systemImage: "trash")
            }
            .labelStyle(.iconOnly)
            .help(L10n.AddData.delete)
            .disabled(editor.selection == nil)
        }
        .labelStyle(.titleAndIcon)
        .controlSize(.small)
        .padding(8)
    }

    // MARK: Painel do item

    @ViewBuilder private var editionPanel: some View {
        if let item = selectedItem {
            Form {
                TrimmedTextField(title: L10n.AddData.identifier, initial: item.identifier) { editor.setIdentifier($0) }
                Text(L10n.AddData.identifierHint).font(.caption).foregroundStyle(.secondary)
                TrimmedTextField(title: L10n.AddData.description, initial: item.description ?? "") {
                    editor.setDescription($0)
                }
                if let kind = item.kind {
                    Picker(L10n.AddData.kind, selection: Binding(get: { Self.choice(kind) }, set: { editor.setKind($0) })) {
                        Text(L10n.AddData.text).tag(AdditionalDataEditorModel.KindChoice.text)
                        Text(L10n.AddData.number).tag(AdditionalDataEditorModel.KindChoice.number)
                        Text(L10n.AddData.date).tag(AdditionalDataEditorModel.KindChoice.date)
                    }
                    .pickerStyle(.segmented)
                    if case .number(_, let minimum, let maximum) = kind {
                        LimitField(title: L10n.AddData.minimum, value: minimum) { editor.setMinimum($0) }
                        LimitField(title: L10n.AddData.maximum, value: maximum) { editor.setMaximum($0) }
                    }
                }
            }
            .formStyle(.grouped)
        } else {
            ContentUnavailableView(L10n.AddData.noSelection, systemImage: "list.bullet.indent")
        }
    }

    /// Identificador, descrição e tipo do item selecionado (`kind` só para variáveis).
    private var selectedItem: (identifier: String, description: String?, kind: AdditionalDataVariable.Kind?)? {
        let sections = editor.definition.sections
        switch editor.selection {
        case .section(let s) where sections.indices.contains(s):
            return (sections[s].identifier, sections[s].description, nil)
        case .variable(let s, let v) where sections.indices.contains(s) && sections[s].variables.indices.contains(v):
            let variable = sections[s].variables[v]
            return (variable.identifier, variable.description, variable.kind)
        default:
            return nil
        }
    }

    private var selectionKey: String? {
        switch editor.selection {
        case .section(let s): "s:\(s)"
        case .variable(let s, let v): "v:\(s):\(v)"
        case nil: nil
        }
    }

    private static func selection(from key: String?) -> AdditionalDataEditorModel.Selection? {
        guard let parts = key?.split(separator: ":") else { return nil }
        let numbers = parts.dropFirst().compactMap { Int($0) }
        switch (parts.first, numbers.count) {
        case ("s", 1): return .section(numbers[0])
        case ("v", 2): return .variable(section: numbers[0], variable: numbers[1])
        default: return nil
        }
    }

    private static func title(_ identifier: String) -> String {
        identifier.isEmpty ? L10n.AddData.unnamed : AdditionalDataLabels.display(identifier)
    }

    private static func symbol(_ kind: AdditionalDataVariable.Kind) -> String {
        switch kind {
        case .text: "textformat"
        case .number: "number"
        case .date: "calendar"
        }
    }

    private static func choice(_ kind: AdditionalDataVariable.Kind) -> AdditionalDataEditorModel.KindChoice {
        switch kind {
        case .text: .text
        case .number: .number
        case .date: .date
        }
    }

    private func apply() {
        do {
            try onApply(editor)
            dismiss()
        } catch {
            errorMessage = IAErrorText.message(for: error)
        }
    }
}

/// Texto que vai ao modelo a cada tecla; o modelo apara, mas o campo mantém o que foi digitado, como `txtID`.
private struct TrimmedTextField: View {
    let title: String
    let initial: String
    let onChange: (String) -> Void

    @State private var text = ""
    @FocusState private var focused: Bool

    var body: some View {
        // Só a digitação envia, no próprio setter: mostrar o item não pode aparar um identificador lido de arquivo.
        TextField(title, text: Binding(get: { text }, set: { newValue in
            text = newValue
            if focused { onChange(newValue) }
        }))
            .focused($focused)
            .onAppear { text = initial }
    }
}

/// Mínimo ou máximo: número válido ou vazio vai ao modelo; ao sair do campo, mostra o valor vigente (que o modelo pode
/// ter ajustado ao outro limite).
private struct LimitField: View {
    let title: String
    let value: Decimal?
    let onChange: (Decimal?) -> Void

    @State private var text = ""
    @FocusState private var focused: Bool

    var body: some View {
        LabeledContent(title) {
            TextField(title, text: Binding(get: { text }, set: { newValue in
                text = newValue
                guard focused else { return }
                if newValue.trimmingCharacters(in: .whitespaces).isEmpty {
                    onChange(nil)
                } else if let number = ClinicalFormat.parseDecimal(newValue) {
                    onChange(number)
                }
            }), prompt: Text(L10n.AddData.noLimit))
                .labelsHidden()
                .textFieldStyle(.roundedBorder)
                .multilineTextAlignment(.trailing)
                .monospacedDigit()
                .frame(width: 140)
                .focused($focused)
                .onAppear { text = Self.format(value) }
                .onChange(of: focused) { _, isFocused in if !isFocused { text = Self.format(value) } }
                .onChange(of: value) { _, newValue in if !focused { text = Self.format(newValue) } }
        }
    }

    private static func format(_ value: Decimal?) -> String {
        value.map { "\($0)".replacingOccurrences(of: ".", with: ",") } ?? ""
    }
}

/// Mensagens em pt-BR dos erros do editor e do formulário de dados adicionais.
enum AdditionalDataErrorText {
    static func knownMessage(for error: Error) -> String? {
        switch error {
        case AdditionalDataEditorError.emptyIdentifier:
            L10n.AddData.emptyIdentifier
        case AdditionalDataEditorError.duplicateIdentifier(let section, let variable?):
            "\(L10n.AddData.duplicatePrefix) \(section) / \(variable)"
        case AdditionalDataEditorError.duplicateIdentifier(let section, nil):
            "\(L10n.AddData.duplicatePrefix) \(section)"
        case is AdditionalDataValueError:
            L10n.AddData.invalidValues
        default:
            nil
        }
    }
}
