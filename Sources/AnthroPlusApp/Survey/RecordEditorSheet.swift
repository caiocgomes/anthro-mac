import AnthroFeatures
import SwiftUI

/// `NSRecordDialog`: pesquisa e identificação, criança com datas ou idade, medidas com IMC, e notas.
struct RecordEditorSheet: View {
    @Bindable var editor: RecordEditorModel
    let isNew: Bool
    let surveyName: String
    let onCommit: (RecordEditorModel) throws -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 0) {
            Form {
                Section(L10n.Survey.identification) {
                    Toggle(L10n.Survey.hasSurveyDate, isOn: Binding(
                        get: { editor.visitDate != nil },
                        set: { editor.setVisitDate($0 ? (editor.visitDate ?? Date()) : nil) }))
                    if let visitDate = editor.visitDate {
                        DatePicker(L10n.Survey.surveyDate,
                                   selection: Binding(get: { visitDate }, set: { editor.setVisitDate($0) }),
                                   displayedComponents: .date)
                    }
                    numberField(L10n.Survey.cluster, .cluster, auto: .cluster)
                    numberField(L10n.Survey.team, .team, auto: .team)
                    numberField(L10n.Survey.recordID, .displayID, auto: .record)
                    numberField(L10n.Survey.household, .household, auto: .household)
                    numberField(L10n.Survey.weightingFactor, .weightingFactor, auto: nil)
                }
                Section(L10n.Survey.child) {
                    TextField(L10n.Survey.firstName, text: $editor.firstName)
                    TextField(L10n.Survey.lastName, text: $editor.lastName)
                    Picker(L10n.Calculator.sex, selection: $editor.sex) {
                        Text(L10n.Calculator.female).tag(Sex.girl)
                        Text(L10n.Calculator.male).tag(Sex.boy)
                    }
                    .pickerStyle(.segmented)
                    Toggle(L10n.Survey.unknownDateOfBirth, isOn: $editor.dateOfBirthUnknown)
                    DatePicker(L10n.Survey.dateOfBirth,
                               selection: Binding(get: { editor.dateOfBirth }, set: { editor.setDateOfBirth($0) }),
                               displayedComponents: .date)
                        .disabled(editor.dateOfBirthUnknown)
                    Toggle(L10n.Survey.approximateDate,
                           isOn: Binding(get: { editor.dateOfBirthIsApprox }, set: { editor.setDateOfBirthIsApprox($0) }))
                        .disabled(editor.dateOfBirthUnknown)
                    numberField(L10n.Survey.ageInMonths, .ageInMonths, auto: nil)
                        .disabled(!editor.isAgeEntryEnabled)
                    LabeledContent(L10n.Age.label) {
                        Text(editor.ageText).monospacedDigit()
                    }
                }
                Section(L10n.Survey.measurements) {
                    MeasurementField(title: L10n.IndividualAssessment.weight, unit: L10n.Calculator.kilograms,
                                     text: text(.weight), warning: editor.warnings[.weight])
                    MeasurementField(title: L10n.IndividualAssessment.lengthOrHeight, unit: L10n.Calculator.centimeters,
                                     text: text(.lengthOrHeight), warning: editor.warnings[.lengthOrHeight])
                    Picker(L10n.IndividualAssessment.measurement,
                           selection: Binding(get: { editor.measuredRecumbent }, set: { editor.setMeasuredRecumbent($0) })) {
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
                    TextField(L10n.Survey.notes, text: $editor.notes, axis: .vertical)
                        .lineLimit(2...4)
                }
            }
            .formStyle(.grouped)
            .datePickerStyle(.stepperField)
            HStack {
                Spacer()
                Button(L10n.Survey.cancel, role: .cancel) { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Button(L10n.Survey.confirm) { commit() }
                    .keyboardShortcut(.defaultAction)
                    .disabled(!editor.canSave)
            }
            .padding(16)
        }
        .frame(width: 540, height: 720)
        .environment(\.locale, Locale(identifier: "pt_BR"))
        .navigationTitle(isNew ? "\(L10n.Survey.newRecord): \(surveyName)" : L10n.Survey.editRecord)
        .alert(L10n.IndividualAssessment.saveFailed,
               isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private func text(_ field: RecordNumericField) -> Binding<String> {
        Binding(get: { editor.text(field) }, set: { editor.setText($0, for: field) })
    }

    /// Campo de ID ou fator: com atribuição automática ligada, o vazio mostra "Automático".
    private func numberField(_ title: String, _ field: RecordNumericField, auto: AutoIDField?) -> some View {
        LabeledContent(title) {
            VStack(alignment: .trailing, spacing: 4) {
                TextField(title, text: text(field),
                          prompt: auto.map { editor.isAutoAssigned($0) } == true ? Text(L10n.Survey.automatic) : nil)
                    .labelsHidden()
                    .textFieldStyle(.roundedBorder)
                    .multilineTextAlignment(.trailing)
                    .monospacedDigit()
                    .frame(width: 140)
                if let warning = editor.warnings[field] {
                    Label(warning, systemImage: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }
        }
    }

    private func commit() {
        do {
            try onCommit(editor)
            dismiss()
        } catch {
            errorMessage = SurveyErrorText.message(for: error)
        }
    }
}
