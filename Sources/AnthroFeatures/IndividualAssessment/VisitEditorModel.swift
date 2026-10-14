import AnthroCore
import AnthroStore
import Foundation
import Observation

/// Editor de visita (`IAVisitDialog`): data não anterior ao nascimento e fixa ao editar, escolha deitado ou em pé
/// abaixo de 11 meses, IMC e entrada numérica pelo helper compartilhado (design D2, D7, D8, D11).
@MainActor
@Observable
public final class VisitEditorModel {
    public var weightText: String = ""
    public var lengthOrHeightText: String = ""
    public var hasOedema: Bool = false
    public var notes: String = ""
    public let additionalData: AdditionalDataValuesModel

    private var storedDate: Date
    private var storedRecumbent: Bool = false

    @ObservationIgnored private let dateOfBirth: Date
    @ObservationIgnored private let sex: Sex?
    @ObservationIgnored private let existingDates: Set<Date>
    @ObservationIgnored private let editing: VisitRecord?
    @ObservationIgnored private let engine: AnthroEngine

    /// `Visit(Child)`: hoje, em pé, sem edema e sem medidas; nunca antes do nascimento.
    public init(dateOfBirth: Date, sex: Sex?, existingDates: Set<Date>, editing: VisitRecord?, engine: AnthroEngine,
                today: Date, newVisitAdditionalData: AdditionalData = AdditionalData()) {
        additionalData = AdditionalDataValuesModel(data: AdditionalData())
        self.dateOfBirth = IndividualAssessment.normalized(dateOfBirth)
        self.sex = sex
        self.existingDates = Set(existingDates.map(IndividualAssessment.normalized))
        self.editing = editing
        self.engine = engine
        storedDate = IndividualAssessment.normalized(editing?.date ?? today)
        if let editing {
            weightText = editing.weight.map { ClinicalFormat.string($0, places: 2) } ?? ""
            lengthOrHeightText = editing.lengthOrHeight.map { ClinicalFormat.string($0, places: 2) } ?? ""
            hasOedema = editing.hasOedema
            notes = editing.notes ?? ""
        } else if storedDate < self.dateOfBirth {
            storedDate = self.dateOfBirth
        }
        storedRecumbent = editing?.measuredRecumbent ?? false
        enforceMeasureRule()
    }

    /// `dtpDateOfVisit_ValueChanged`: não anterior ao nascimento; a data de uma visita existente não muda.
    public var date: Date {
        get { storedDate }
        set {
            guard editing == nil else { return }
            let proposed = IndividualAssessment.normalized(newValue)
            storedDate = proposed < dateOfBirth ? dateOfBirth : proposed
            enforceMeasureRule()
        }
    }

    public var isDateEditable: Bool { editing == nil }

    public var weightOutcome: MeasurementInput.Outcome {
        MeasurementInput.evaluate(weightText, range: IndividualAssessment.visitWeightRange, places: 2)
    }

    public var lengthOrHeightOutcome: MeasurementInput.Outcome {
        MeasurementInput.evaluate(lengthOrHeightText, range: IndividualAssessment.visitLengthOrHeightRange, places: 2)
    }

    public var weightWarning: String? {
        IndividualAssessment.warning(weightOutcome, range: IndividualAssessment.visitWeightRange)
    }

    public var lengthOrHeightWarning: String? {
        IndividualAssessment.warning(lengthOrHeightOutcome, range: IndividualAssessment.visitLengthOrHeightRange)
    }

    /// Peso ou medida ilegível ou fora do intervalo bloqueia a confirmação; vazio é permitido (D7).
    public var canSave: Bool {
        !IndividualAssessment.blocksSave(weightOutcome) && !IndividualAssessment.blocksSave(lengthOrHeightOutcome)
    }

    public var weight: Decimal? { weightOutcome.value }
    public var lengthOrHeight: Decimal? { lengthOrHeightOutcome.value }

    /// Só aceita deitado com a escolha habilitada (D11).
    public var measuredRecumbent: Bool {
        get { storedRecumbent }
        set { storedRecumbent = newValue && isMeasureChoiceEnabled }
    }

    /// `ageInMonths < 11m` na data da visita (D11).
    public var isMeasureChoiceEnabled: Bool {
        guard let days = ageInDays else { return false }
        return AgeMath.daysToMonths(days) < 11
    }

    public var bmiText: String {
        IndividualAssessment.visitBMIText(ageInDays: ageInDays, weight: weight, lengthOrHeight: lengthOrHeight,
                                          measuredRecumbent: measuredRecumbent, hasOedema: hasOedema)
    }

    /// `IAVisitDialog.SaveVisit`: recusa data repetida e medidas inválidas; notas sem espaços nas pontas; preserva os
    /// dados adicionais da visita reeditada (D17).
    public func makeVisit() throws -> VisitRecord {
        if editing == nil, existingDates.contains(where: { IndividualAssessment.sameDay($0, storedDate) }) {
            throw VisitValidationError.duplicateDate
        }
        guard canSave else { throw VisitValidationError.invalidMeasurement }
        return VisitRecord(childID: editing?.childID, date: storedDate, weight: weight, lengthOrHeight: lengthOrHeight,
                           measuredRecumbent: measuredRecumbent, hasOedema: hasOedema,
                           notes: IndividualAssessment.nullable(notes), additionalDataXML: editing?.additionalDataXML)
    }

    private var ageInDays: Int? {
        try? AgeMath.ageInDays(birth: dateOfBirth, visit: storedDate)
    }

    private func enforceMeasureRule() {
        if !isMeasureChoiceEnabled { storedRecumbent = false }
    }
}
