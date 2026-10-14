import AnthroFeatures
import SwiftUI

/// Tela da Calculadora: entradas à esquerda, resultados à direita (design D1 a D5).
struct CalculatorView: View {
    let model: CalculatorModel

    @State private var weightText = "20,00"
    @State private var lengthOrHeightText = "115,00"
    @State private var chart: ChartPresentation?
    @FocusState private var focus: CalculatorField?

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            inputs
                .frame(minWidth: 380, idealWidth: 420, maxWidth: 460)
            Divider()
            ScrollView {
                IndicatorPanelView(rows: model.rows) { indicator in
                    commitTextFields()
                    chart = ChartPresentation(model: model.makeChart(for: indicator))
                }
                .padding(20)
            }
            .frame(minWidth: 420, maxWidth: .infinity)
        }
        .environment(\.locale, Locale(identifier: "pt_BR"))
        .onChange(of: focus) { previous, _ in
            if previous == .weight { commitWeight() }
            if previous == .lengthOrHeight { commitLengthOrHeight() }
        }
        .sheet(item: $chart) { presentation in
            GrowthChartSheet(model: presentation.model)
        }
    }

    // MARK: Entradas

    private var inputs: some View {
        Form {
            Section(L10n.Calculator.child) {
                DatePicker(L10n.Calculator.dateOfBirth, selection: binding(\.dateOfBirth, model.setDateOfBirth),
                           in: ...model.dateOfVisit, displayedComponents: .date)
                    .focused($focus, equals: .dateOfBirth)
                    .onKeyPress(.return) { advance(from: .dateOfBirth) }
                Toggle(L10n.Calculator.approximateDate, isOn: binding(\.isApproximateBirthDate, model.setApproximateBirthDate))
                    .focused($focus, equals: .approximateDate)
                    .onKeyPress(.return) { advance(from: .approximateDate) }
                DatePicker(L10n.Calculator.dateOfVisit, selection: binding(\.dateOfVisit, model.setDateOfVisit),
                           displayedComponents: .date)
                    .focused($focus, equals: .dateOfVisit)
                    .onKeyPress(.return) { advance(from: .dateOfVisit) }
                LabeledContent(L10n.Age.label) {
                    Text(ageValue).monospacedDigit().fontWeight(.medium)
                }
                Picker(L10n.Calculator.sex, selection: binding(\.sex, model.setSex)) {
                    Text(L10n.Calculator.male).tag(Sex.boy)
                    Text(L10n.Calculator.female).tag(Sex.girl)
                }
                .pickerStyle(.segmented)
                .focused($focus, equals: .sex)
                .onKeyPress(.return) { advance(from: .sex) }
            }

            Section(L10n.Calculator.measurements) {
                measurementField(L10n.Calculator.weight, unit: L10n.Calculator.kilograms, text: $weightText,
                                 issue: model.weightIssue, field: .weight, commit: commitWeight)
                measurementField(L10n.Calculator.lengthOrHeight, unit: L10n.Calculator.centimeters,
                                 text: $lengthOrHeightText, issue: model.lengthOrHeightIssue, field: .lengthOrHeight,
                                 commit: commitLengthOrHeight)
                Picker(L10n.Calculator.measurement, selection: binding(\.measuredRecumbent, model.setMeasuredRecumbent)) {
                    Text(L10n.Calculator.recumbent).tag(true)
                    Text(L10n.Calculator.standing).tag(false)
                }
                .pickerStyle(.segmented)
                .disabled(!model.isMeasurementChoiceEnabled)
                .help(L10n.Calculator.measurementHint)
                .focused($focus, equals: .measurement)
                .onKeyPress(.return) { advance(from: .measurement) }
                Picker(L10n.Calculator.oedema, selection: binding(\.hasOedema, model.setHasOedema)) {
                    Text(L10n.Calculator.no).tag(false)
                    Text(L10n.Calculator.yes).tag(true)
                }
                .pickerStyle(.segmented)
                .focused($focus, equals: .oedema)
                .onKeyPress(.return) { advance(from: .oedema) }
                LabeledContent(L10n.Calculator.bmi) {
                    Text(model.bmiText).monospacedDigit().fontWeight(.medium)
                }
            }
        }
        .formStyle(.grouped)
        .datePickerStyle(.stepperField)
    }

    private func measurementField(_ title: String, unit: String, text: Binding<String>, issue: MeasurementInput.Outcome?,
                                  field: CalculatorField, commit: @escaping () -> Void) -> some View {
        LabeledContent(title) {
            VStack(alignment: .trailing, spacing: 4) {
                HStack(spacing: 6) {
                    TextField(title, text: text)
                        .labelsHidden()
                        .textFieldStyle(.roundedBorder)
                        .multilineTextAlignment(.trailing)
                        .monospacedDigit()
                        .frame(width: 96)
                        .focused($focus, equals: field)
                        .onSubmit {
                            commit()
                            _ = advance(from: field)
                        }
                    Text(unit).foregroundStyle(.secondary).frame(width: 22, alignment: .leading)
                }
                if let message = issue?.issueMessage {
                    Label(message, systemImage: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }
        }
    }

    // MARK: Ações

    /// "Idade: 5a 11m (71m)" sem o rótulo, que já está à esquerda.
    private var ageValue: String {
        let prefix = "\(L10n.Age.label): "
        return model.ageText.hasPrefix(prefix) ? String(model.ageText.dropFirst(prefix.count)) : model.ageText
    }

    /// Lê o campo ao sair dele ou com Enter, como `NumericUpDownX`, e mostra o valor truncado.
    private func commitWeight() {
        model.setWeightText(weightText)
        if let weight = model.weight { weightText = ClinicalFormat.string(weight, places: 2) }
    }

    private func commitLengthOrHeight() {
        model.setLengthOrHeightText(lengthOrHeightText)
        if let value = model.lengthOrHeight { lengthOrHeightText = ClinicalFormat.string(value, places: 2) }
    }

    private func commitTextFields() {
        commitWeight()
        commitLengthOrHeight()
    }

    private func advance(from field: CalculatorField) -> KeyPress.Result {
        guard let next = model.nextFocus(after: field) else { return .ignored }
        focus = next
        return .handled
    }

    private func binding<Value>(_ keyPath: KeyPath<CalculatorModel, Value>,
                                _ set: @escaping (Value) -> Void) -> Binding<Value> {
        Binding(get: { model[keyPath: keyPath] }, set: { set($0) })
    }
}

/// Gráfico aberto a partir do painel.
struct ChartPresentation: Identifiable {
    let id = UUID()
    let model: GrowthChartModel
}
