import AnthroFeatures
import SwiftUI

/// Campo numérico com o aviso do intervalo, mostrado fora da edição para não piscar enquanto se digita (D7).
struct MeasurementField: View {
    let title: String
    let unit: String
    @Binding var text: String
    let warning: String?
    @FocusState private var focused: Bool

    var body: some View {
        LabeledContent(title) {
            VStack(alignment: .trailing, spacing: 4) {
                HStack(spacing: 6) {
                    TextField(title, text: $text)
                        .labelsHidden()
                        .textFieldStyle(.roundedBorder)
                        .multilineTextAlignment(.trailing)
                        .monospacedDigit()
                        .frame(width: 96)
                        .focused($focused)
                    Text(unit).foregroundStyle(.secondary).frame(width: 22, alignment: .leading)
                }
                if let warning, !focused {
                    Label(warning, systemImage: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundStyle(.orange)
                        .multilineTextAlignment(.trailing)
                }
            }
        }
    }
}

/// `IAVisitDialog`: data, peso, medida, deitado ou em pé, edema, notas e IMC, com gráfico da visita ainda não
/// confirmada (`tsbMMGraph_Click`).
struct VisitEditorSheet: View {
    @Bindable var editor: VisitEditorModel
    let tables: GrowthReferenceTables
    let onCommit: (VisitEditorModel) throws -> Void
    let chartInput: (VisitRecord, Indicator) -> GrowthChartInput

    @Environment(\.dismiss) private var dismiss
    @State private var errorMessage: String?
    @State private var chart: ChartPresentation?

    var body: some View {
        VStack(spacing: 0) {
            Form {
                Section {
                    DatePicker(L10n.IndividualAssessment.visitDate, selection: $editor.date, displayedComponents: .date)
                        .disabled(!editor.isDateEditable)
                    MeasurementField(title: L10n.IndividualAssessment.weight, unit: L10n.Calculator.kilograms,
                                     text: $editor.weightText, warning: editor.weightWarning)
                    MeasurementField(title: L10n.IndividualAssessment.lengthOrHeight, unit: L10n.Calculator.centimeters,
                                     text: $editor.lengthOrHeightText, warning: editor.lengthOrHeightWarning)
                    Picker(L10n.IndividualAssessment.measurement, selection: $editor.measuredRecumbent) {
                        Text(L10n.IndividualAssessment.recumbent).tag(true)
                        Text(L10n.IndividualAssessment.standing).tag(false)
                    }
                    .pickerStyle(.segmented)
                    .disabled(!editor.isMeasureChoiceEnabled)
                    .help(L10n.Calculator.measurementHint)
                    Picker(L10n.IndividualAssessment.oedema, selection: $editor.hasOedema) {
                        Text(L10n.IndividualAssessment.no).tag(false)
                        Text(L10n.IndividualAssessment.yes).tag(true)
                    }
                    .pickerStyle(.segmented)
                    LabeledContent(L10n.IndividualAssessment.bmi) {
                        Text(editor.bmiText).monospacedDigit().fontWeight(.medium)
                    }
                    TextField(L10n.IndividualAssessment.notes, text: $editor.notes, axis: .vertical)
                        .lineLimit(2...4)
                }
            }
            .formStyle(.grouped)
            .datePickerStyle(.stepperField)
            HStack {
                Button { openChart() } label: {
                    Label(L10n.IndividualAssessment.showChart, systemImage: "chart.xyaxis.line")
                }
                .disabled(!editor.canSave)
                Spacer()
                Button(L10n.IndividualAssessment.cancel, role: .cancel) { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Button(L10n.IndividualAssessment.confirm) { commit() }
                    .keyboardShortcut(.defaultAction)
                    .disabled(!editor.canSave)
            }
            .padding(16)
        }
        .frame(width: 520)
        .environment(\.locale, Locale(identifier: "pt_BR"))
        .navigationTitle(editor.isDateEditable ? L10n.IndividualAssessment.newVisit : L10n.IndividualAssessment.editVisit)
        .sheet(item: $chart) { GrowthChartSheet(model: $0.model) }
        .alert(L10n.IndividualAssessment.saveFailed,
               isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private func commit() {
        do {
            try onCommit(editor)
            dismiss()
        } catch {
            errorMessage = IAErrorText.message(for: error)
        }
    }

    private func openChart() {
        do {
            let input = chartInput(try editor.makeVisit(), .weightForAge)
            chart = ChartPresentation(model: GrowthChartModel(results: input.results, currentIndex: input.currentIndex,
                                                              indicator: input.indicator, tables: tables))
        } catch {
            errorMessage = IAErrorText.message(for: error)
        }
    }
}

/// `IAParentDialog`: gravado na hora, altura e peso com aviso, IMC truncado e nascimento opcional.
struct ParentEditorSheet: View {
    let kind: ParentKind
    @Bindable var editor: ParentEditorModel
    let onSaved: (ParentRecord) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 0) {
            Form {
                Section {
                    TextField(L10n.IndividualAssessment.firstName, text: $editor.firstName)
                    TextField(L10n.IndividualAssessment.lastName, text: $editor.lastName)
                    MeasurementField(title: L10n.IndividualAssessment.height, unit: L10n.Calculator.centimeters,
                                     text: $editor.heightText, warning: editor.heightWarning)
                    MeasurementField(title: L10n.IndividualAssessment.weight, unit: L10n.Calculator.kilograms,
                                     text: $editor.weightText, warning: editor.weightWarning)
                    LabeledContent(L10n.IndividualAssessment.bmi) {
                        Text(editor.bmiText).monospacedDigit().fontWeight(.medium)
                    }
                }
                Section {
                    Toggle(L10n.IndividualAssessment.unknownDateOfBirth, isOn: $editor.dateOfBirthUnknown)
                    if !editor.dateOfBirthUnknown {
                        DatePicker(L10n.IndividualAssessment.dateOfBirth, selection: $editor.dateOfBirth,
                                   displayedComponents: .date)
                        Toggle(L10n.IndividualAssessment.approximateDate, isOn: $editor.dateOfBirthIsApprox)
                    }
                    TextField(L10n.IndividualAssessment.notes, text: $editor.notes, axis: .vertical)
                        .lineLimit(2...4)
                }
            }
            .formStyle(.grouped)
            .datePickerStyle(.stepperField)
            SheetButtons(canSave: editor.canSave, onCancel: { dismiss() }, onSave: save)
        }
        .frame(width: 500)
        .environment(\.locale, Locale(identifier: "pt_BR"))
        .navigationTitle(kind == .mother ? L10n.IndividualAssessment.mother : L10n.IndividualAssessment.father)
        .alert(L10n.IndividualAssessment.saveFailed,
               isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private func save() {
        do {
            onSaved(try editor.save())
            dismiss()
        } catch {
            errorMessage = IAErrorText.message(for: error)
        }
    }
}

/// `IAAddressDialog` sem as listas SALB: campos livres, gravado na hora.
struct AddressEditorSheet: View {
    @Bindable var editor: AddressEditorModel
    let onSaved: (AddressRecord) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 0) {
            Form {
                TextField(L10n.IndividualAssessment.streetInfo, text: $editor.streetInfo)
                TextField(L10n.IndividualAssessment.place, text: $editor.place)
                TextField(L10n.IndividualAssessment.zip, text: $editor.zip)
                TextField(L10n.IndividualAssessment.district, text: $editor.district)
                TextField(L10n.IndividualAssessment.province, text: $editor.province)
                TextField(L10n.IndividualAssessment.state, text: $editor.state)
                TextField(L10n.IndividualAssessment.country, text: $editor.country)
                TextField(L10n.IndividualAssessment.phoneNumber, text: $editor.phoneNumber)
                TextField(L10n.IndividualAssessment.email, text: $editor.email)
            }
            .formStyle(.grouped)
            SheetButtons(canSave: true, onCancel: { dismiss() }, onSave: save)
        }
        .frame(width: 480)
        .navigationTitle(L10n.IndividualAssessment.address)
        .alert(L10n.IndividualAssessment.saveFailed,
               isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private func save() {
        do {
            onSaved(try editor.save())
            dismiss()
        } catch {
            errorMessage = IAErrorText.message(for: error)
        }
    }
}

private struct SheetButtons: View {
    let canSave: Bool
    let onCancel: () -> Void
    let onSave: () -> Void

    var body: some View {
        HStack {
            Spacer()
            Button(L10n.IndividualAssessment.cancel, role: .cancel, action: onCancel)
                .keyboardShortcut(.cancelAction)
            Button(L10n.IndividualAssessment.save, action: onSave)
                .keyboardShortcut(.defaultAction)
                .disabled(!canSave)
        }
        .padding(16)
    }
}

/// Resultado de `ComboSearch.DoSearch` pronto para a lista.
struct LookupItems {
    enum State {
        case tooMany
        case none
        case items([(id: Int64, title: String)])
    }

    let state: State

    init<Item>(_ outcome: LookupSearchOutcome<Item>, _ describe: (Item) -> (Int64?, String)) {
        switch outcome {
        case .tooManyResults: state = .tooMany
        case .noResults: state = .none
        case .results(let items):
            state = .items(items.compactMap { item in
                let (id, title) = describe(item)
                return id.map { (id: $0, title: title) }
            })
        }
    }
}

/// Busca de mãe, pai ou endereço já cadastrados (`ComboSearch`): texto contido, até 50 resultados.
struct LookupSheet: View {
    let title: String
    let search: (String) throws -> LookupItems
    let onPick: (Int64) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var text = ""
    @State private var items = LookupItems.State.items([])

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title).font(.headline)
            TextField(L10n.IndividualAssessment.searchPlaceholder, text: $text)
                .textFieldStyle(.roundedBorder)
                .onSubmit(refresh)
            Group {
                switch items {
                case .tooMany:
                    Text(L10n.IndividualAssessment.tooManyResults).foregroundStyle(.secondary)
                case .none:
                    Text(L10n.IndividualAssessment.noResults).foregroundStyle(.secondary)
                case .items(let rows):
                    List(rows, id: \.id) { row in
                        Button(row.title) {
                            onPick(row.id)
                            dismiss()
                        }
                        .buttonStyle(.plain)
                    }
                    .listStyle(.inset)
                }
            }
            .frame(height: 260)
            HStack {
                Spacer()
                Button(L10n.IndividualAssessment.cancel, role: .cancel) { dismiss() }
                    .keyboardShortcut(.cancelAction)
            }
        }
        .padding(16)
        .frame(width: 460)
        .onAppear(perform: refresh)
        .onChange(of: text) { refresh() }
    }

    private func refresh() {
        items = (try? search(text))?.state ?? .none
    }
}
