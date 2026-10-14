import AnthroFeatures
import SwiftUI

/// Valores de dados adicionais dentro do `Form` das folhas de visita e de registro (`CreateAddDataControls`): uma
/// seção por seção dos dados, com campos de texto, número com aviso e data opcional.
struct AdditionalDataFormSection: View {
    let model: AdditionalDataValuesModel

    var body: some View {
        ForEach(groups, id: \.index) { group in
            Section {
                ForEach(group.fields) { field in
                    row(field)
                }
            } header: {
                Text("\(L10n.AddData.formSection): \(group.title)")
            } footer: {
                if let description = group.description {
                    Text(description).font(.caption).foregroundStyle(.secondary)
                }
            }
        }
    }

    private struct Group {
        let index: Int
        let title: String
        let description: String?
        var fields: [AdditionalDataValuesModel.Field]
    }

    /// Campos agrupados pela seção de origem, na ordem da definição.
    private var groups: [Group] {
        var groups: [Group] = []
        for field in model.fields {
            if groups.last?.index == field.sectionIndex {
                groups[groups.count - 1].fields.append(field)
            } else {
                groups.append(Group(index: field.sectionIndex, title: field.sectionTitle,
                                    description: field.sectionDescription, fields: [field]))
            }
        }
        return groups
    }

    @ViewBuilder private func row(_ field: AdditionalDataValuesModel.Field) -> some View {
        switch field.kind {
        case .text:
            TextField(field.label, text: Binding(
                get: { model.displayText(section: field.sectionIndex, variable: field.variableIndex) },
                set: { model.setText($0, section: field.sectionIndex, variable: field.variableIndex) }))
                .help(field.hint ?? "")
        case .number:
            AdditionalNumberField(model: model, field: field)
        case .date:
            AdditionalDateField(model: model, field: field)
        }
    }
}

/// Número digitado como texto: cada tecla vai ao modelo, e o texto só é reescrito com 2 casas ao sair do campo, para
/// não mudar o número enquanto se digita.
private struct AdditionalNumberField: View {
    let model: AdditionalDataValuesModel
    let field: AdditionalDataValuesModel.Field

    @State private var text = ""
    @FocusState private var focused: Bool

    var body: some View {
        LabeledContent(field.label) {
            VStack(alignment: .trailing, spacing: 4) {
                TextField(field.label, text: $text)
                    .labelsHidden()
                    .textFieldStyle(.roundedBorder)
                    .multilineTextAlignment(.trailing)
                    .monospacedDigit()
                    .frame(width: 140)
                    .focused($focused)
                    .onAppear { text = current }
                    .onChange(of: text) { _, newValue in
                        if focused { model.setNumber(newValue, section: field.sectionIndex, variable: field.variableIndex) }
                    }
                    .onChange(of: focused) { _, isFocused in if !isFocused { text = current } }
                if let warning = model.warnings[field.id] {
                    Label(warning, systemImage: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }
        }
        .help(field.hint ?? "")
    }

    private var current: String {
        model.displayText(section: field.sectionIndex, variable: field.variableIndex)
    }
}

/// Data opcional (`NullableDateTimePicker`): marcar "Informar data" mostra o seletor.
private struct AdditionalDateField: View {
    let model: AdditionalDataValuesModel
    let field: AdditionalDataValuesModel.Field

    var body: some View {
        let date = model.date(section: field.sectionIndex, variable: field.variableIndex)
        LabeledContent(field.label) {
            HStack {
                Toggle(L10n.AddData.informDate, isOn: Binding(
                    get: { date != nil },
                    set: { model.setDate($0 ? (date ?? Date()) : nil, section: field.sectionIndex,
                                         variable: field.variableIndex) }))
                if let date {
                    DatePicker(field.label, selection: Binding(
                        get: { date },
                        set: { model.setDate($0, section: field.sectionIndex, variable: field.variableIndex) }),
                               displayedComponents: .date)
                        .labelsHidden()
                }
            }
        }
        .help(field.hint ?? "")
    }
}
