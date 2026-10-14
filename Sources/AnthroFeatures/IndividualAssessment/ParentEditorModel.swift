import AnthroCore
import AnthroStore
import Foundation
import Observation

/// Editor de mãe ou pai (`IAParentDialog`): gravado na hora (D3), medidas em 50 a 300 cm e 10 a 1000 kg com bloqueio
/// de gravação (D7), IMC truncado (D8), nascimento opcional e não posterior a hoje (D10).
@MainActor
@Observable
public final class ParentEditorModel {
    public var firstName: String = ""
    public var lastName: String = ""
    public var notes: String = ""
    public var heightText: String = ""
    public var weightText: String = ""
    public var dateOfBirthUnknown: Bool = false

    private var storedBirth: Date
    private var storedApprox: Bool = false

    @ObservationIgnored private let kind: ParentKind
    @ObservationIgnored private let database: AnthroDatabase
    @ObservationIgnored private let editing: ParentRecord?
    @ObservationIgnored private let today: () -> Date
    @ObservationIgnored private let randomDay: (Range<Int>) -> Int

    public init(kind: ParentKind, database: AnthroDatabase, editing: ParentRecord?, today: @escaping () -> Date = { Date() },
                randomDay: @escaping (Range<Int>) -> Int = { Int.random(in: $0) }) {
        self.kind = kind
        self.database = database
        self.editing = editing
        self.today = today
        self.randomDay = randomDay
        storedBirth = IndividualAssessment.normalized(editing?.dateOfBirth ?? today())
        storedApprox = editing?.dateOfBirthIsApprox ?? false
        dateOfBirthUnknown = editing != nil && editing?.dateOfBirth == nil
        firstName = editing?.firstName ?? ""
        lastName = editing?.lastName ?? ""
        notes = editing?.notes ?? ""
        heightText = editing?.height.map { ClinicalFormat.string($0, places: 2) } ?? ""
        weightText = editing?.weight.map { ClinicalFormat.string($0, places: 2) } ?? ""
    }

    public var heightOutcome: MeasurementInput.Outcome {
        MeasurementInput.evaluate(heightText, range: IndividualAssessment.parentHeightRange, places: 2)
    }

    public var weightOutcome: MeasurementInput.Outcome {
        MeasurementInput.evaluate(weightText, range: IndividualAssessment.parentWeightRange, places: 2)
    }

    public var heightWarning: String? {
        IndividualAssessment.warning(heightOutcome, range: IndividualAssessment.parentHeightRange)
    }

    public var weightWarning: String? {
        IndividualAssessment.warning(weightOutcome, range: IndividualAssessment.parentWeightRange)
    }

    public var canSave: Bool {
        !IndividualAssessment.blocksSave(heightOutcome) && !IndividualAssessment.blocksSave(weightOutcome)
    }

    /// Nascimento limitado a hoje, com a regra da data aproximada (D9, D10).
    public var dateOfBirth: Date {
        get { storedBirth }
        set {
            let adjusted = ApproximateBirthDate.adjusted(previous: storedBirth, proposed: IndividualAssessment.normalized(newValue),
                                                         isApprox: storedApprox, upperBound: upperBound,
                                                         randomDay: randomDay)
            storedBirth = IndividualAssessment.normalized(adjusted)
        }
    }

    public var dateOfBirthIsApprox: Bool {
        get { storedApprox }
        set {
            storedApprox = newValue
            guard newValue else { return }
            storedBirth = IndividualAssessment.approximated(storedBirth, upperBound: upperBound, randomDay: randomDay)
        }
    }

    /// `IAParentDialog.RefreshBMI`: `SymetricCrop(ComputeExactBMI(peso, altura), 1)`, sem medida ajustada (D8).
    public var bmiText: String {
        guard let weight = weightOutcome.value, let height = heightOutcome.value,
              let bmi = Anthropometry.exactBMI(weight: weight, lengthOrHeight: height) else { return L10n.notAvailable }
        return ClinicalFormat.string(MeasurementInput.truncate(bmi, places: 1), places: 1)
    }

    @discardableResult public func save() throws -> ParentRecord {
        guard canSave else { throw ParentValidationError.invalidMeasurement }
        let record = ParentRecord(
            id: editing?.id, kind: kind, firstName: IndividualAssessment.nullable(firstName),
            lastName: IndividualAssessment.nullable(lastName), height: heightOutcome.value, weight: weightOutcome.value,
            dateOfBirth: dateOfBirthUnknown ? nil : storedBirth,
            dateOfBirthIsApprox: dateOfBirthUnknown ? false : storedApprox, notes: IndividualAssessment.nullable(notes))
        return try ParentRepository(database: database).save(record)
    }

    private var upperBound: Date {
        IndividualAssessment.normalized(today())
    }
}
