import AnthroCore
import Foundation
import Observation

/// Campos numéricos do editor de registro com intervalo e casas do controle de `NSRecordDialog` (design D11).
public enum RecordNumericField: Hashable, Sendable, CaseIterable {
    case weight, lengthOrHeight, ageInMonths, cluster, team, displayID, household, weightingFactor

    /// `decimal.MaxValue` do .NET, o máximo do fator de peso no original.
    static let decimalMaxValue = Decimal(string: "79228162514264337593543950335")!

    public var range: ClosedRange<Decimal> {
        switch self {
        case .weight: InputLimits.minWeight...InputLimits.maxWeight
        case .lengthOrHeight: InputLimits.minLengthOrHeight...InputLimits.maxLengthOrHeight
        case .ageInMonths: 0...2400
        case .cluster, .team, .displayID, .household: 0...2_147_483_647
        case .weightingFactor: 0...Self.decimalMaxValue
        }
    }

    public var places: Int {
        switch self {
        case .weight, .lengthOrHeight, .ageInMonths: 2
        case .cluster, .team, .displayID, .household: 0
        case .weightingFactor: 16
        }
    }
}

public enum AutoIDField: Hashable, Sendable, CaseIterable {
    case cluster, team, record, household
}

public enum RecordFieldIssue: Hashable, Sendable {
    case invalid(RecordNumericField)
    case outOfRange(RecordNumericField)
    case required(RecordNumericField)
}

public struct RecordValidationError: Error, Equatable {
    public let issues: Set<RecordFieldIssue>
}

/// Editor de registro do inquérito (`NSRecordDialog`): valores padrão do construtor, datas com nascimento limitado à
/// data da pesquisa, idade digitada só sem as duas datas, escolha deitado ou em pé abaixo de 11 meses, IMC e IDs
/// automáticos (`SaveRecord` com `Survey.GetNew*ID`, sobre todos os registros).
@MainActor
@Observable
public final class RecordEditorModel {
    public private(set) var visitDate: Date?
    public private(set) var dateOfBirth: Date
    /// `cbDateIsUnknown`: desmarcar também desmarca a data aproximada (`cbDateIsUnknown_CheckedChanged`).
    public var dateOfBirthUnknown: Bool {
        didSet {
            if !dateOfBirthUnknown { dateOfBirthIsApprox = false }
            refreshAge()
        }
    }
    public private(set) var dateOfBirthIsApprox: Bool
    public var firstName: String
    public var lastName: String
    public var notes: String
    public var sex: Sex
    public private(set) var measuredRecumbent: Bool
    public var hasOedema: Bool

    public let additionalData: AdditionalDataValuesModel

    private var texts: [RecordNumericField: String] = [:]

    @ObservationIgnored private let editing: SurveyRecord?
    @ObservationIgnored private let survey: Survey
    @ObservationIgnored private let existingRecords: [SurveyRecord]
    @ObservationIgnored private let randomDay: (Range<Int>) -> Int
    /// Texto e valor carregados do registro editado: texto intacto devolve o valor gravado, sem o arredondamento da tela.
    @ObservationIgnored private var loaded: [RecordNumericField: (text: String, value: Decimal)] = [:]

    public init(record: SurveyRecord?, survey: Survey, existingRecords: [SurveyRecord], engine: AnthroEngine, today: Date,
                randomDay: @escaping (Range<Int>) -> Int = { Int.random(in: $0) }) {
        editing = record
        self.survey = survey
        self.existingRecords = existingRecords
        self.randomDay = randomDay
        additionalData = AdditionalDataValuesModel(data: AdditionalData())
        let todayNoon = IndividualAssessment.normalized(today)
        visitDate = record?.visitDate.map(IndividualAssessment.normalized)
        // Registro novo: nascimento um ano antes de hoje; existente sem nascimento: a data da pesquisa ou hoje.
        let birth = record == nil
            ? Calendar.current.date(byAdding: .year, value: -1, to: todayNoon) ?? todayNoon
            : record?.dateOfBirth ?? record?.visitDate ?? todayNoon
        dateOfBirth = IndividualAssessment.normalized(birth)
        dateOfBirthUnknown = record != nil && record?.dateOfBirth == nil
        dateOfBirthIsApprox = record?.dateOfBirthIsApprox ?? false
        firstName = record?.firstName ?? ""
        lastName = record?.lastName ?? ""
        notes = record?.notes ?? ""
        sex = record?.sex ?? .girl
        measuredRecumbent = record?.measuredRecumbent ?? false
        hasOedema = record?.hasOedema == true
        let values: [RecordNumericField: Decimal?] = [
            .weight: record?.weight, .lengthOrHeight: record?.lengthOrHeight, .ageInMonths: record?.ageInMonths,
            .cluster: record?.cluster.map { Decimal($0) }, .team: record?.team.map { Decimal($0) },
            .displayID: record?.displayID.map { Decimal($0) }, .household: record?.household.map { Decimal($0) },
            .weightingFactor: record?.weightingFactor ?? 1,
        ]
        for case let (field, value?) in values {
            let text = Self.format(value, field)
            texts[field] = text
            loaded[field] = (text, value)
        }
        refreshAge()
    }

    // MARK: Campos numéricos

    public func text(_ field: RecordNumericField) -> String {
        texts[field] ?? ""
    }

    public func setText(_ text: String, for field: RecordNumericField) {
        texts[field] = text
        if field == .ageInMonths { refreshAge() }
    }

    public func outcome(_ field: RecordNumericField) -> MeasurementInput.Outcome {
        MeasurementInput.evaluate(text(field), range: field.range, places: field.places)
    }

    /// Valor para o cálculo; inválido, fora do intervalo ou vazio dão `nil`.
    public func value(_ field: RecordNumericField) -> Decimal? {
        if let loaded = loaded[field], loaded.text == text(field) { return loaded.value }
        if case .value(let value) = outcome(field) { return value }
        return nil
    }

    public var warnings: [RecordNumericField: String] {
        var warnings: [RecordNumericField: String] = [:]
        for issue in issues {
            switch issue {
            case .invalid(let field):
                warnings[field] = L10n.Calculator.invalidValue
            case .outOfRange(let field):
                let lower = ClinicalFormat.string(field.range.lowerBound, places: field.places)
                warnings[field] = field.range.upperBound == RecordNumericField.decimalMaxValue
                    ? "\(L10n.Survey.minimumPrefix) \(field.range.lowerBound)"
                    : "\(L10n.Calculator.outOfRangePrefix) \(lower) \(L10n.Calculator.rangeSeparator) "
                        + ClinicalFormat.string(field.range.upperBound, places: field.places)
            case .required(let field):
                warnings[field] = L10n.Survey.required
            }
        }
        return warnings
    }

    /// Texto ilegível ou fora do intervalo bloqueia; vazio é aceito, exceto no fator de peso (`IsNullable = false`).
    public var canSave: Bool {
        issues.isEmpty
    }

    private var issues: Set<RecordFieldIssue> {
        var issues: Set<RecordFieldIssue> = []
        for field in RecordNumericField.allCases {
            if let loaded = loaded[field], loaded.text == text(field) { continue }
            switch outcome(field) {
            case .invalid: issues.insert(.invalid(field))
            case .outOfRange: issues.insert(.outOfRange(field))
            case .empty where field == .weightingFactor: issues.insert(.required(field))
            case .empty, .value: break
            }
        }
        return issues
    }

    // MARK: Idade, medida e IMC

    /// `NSRecordDialog.RefreshAge`: idade inteira das datas, ou da idade digitada, ou "Idade: N/D".
    public var ageText: String {
        guard let months = wholeMonths else { return "\(L10n.Age.label): \(L10n.notAvailable)" }
        return AgeText.localized(months: months)
    }

    /// Só com idade desconhecida ou abaixo de 11 meses inteiros (D12).
    public var isMeasureChoiceEnabled: Bool {
        guard let months = wholeMonths else { return true }
        return months < 11
    }

    /// A idade em meses é digitada só sem data da pesquisa ou com nascimento desconhecido.
    public var isAgeEntryEnabled: Bool {
        !(visitDate != nil && !dateOfBirthUnknown)
    }

    /// `ComputeBMI`: medida ajustada pela idade das datas ou da digitada, bruta sem idade; "N/D" com edema ou campo vazio.
    public var bmiText: String {
        guard !hasOedema, let weight = value(.weight), let measure = value(.lengthOrHeight) else { return L10n.notAvailable }
        let days = datedAgeInDays ?? (isAgeEntryEnabled ? value(.ageInMonths).map(AgeMath.monthsToDays) : nil)
        let length = days.map {
            Anthropometry.adjustedLengthOrHeight(ageInDays: $0, value: measure, measuredRecumbent: measuredRecumbent).value
        } ?? measure
        let bmi = ClinicalRounding.round(Anthropometry.exactBMI(weight: weight, lengthOrHeight: length), places: 1)
        return ClinicalFormat.string(bmi, places: 1)
    }

    public func isAutoAssigned(_ field: AutoIDField) -> Bool {
        switch field {
        case .cluster: survey.options.autoIDCluster
        case .team: survey.options.autoIDTeam
        case .record: survey.options.autoIDRecord
        case .household: survey.options.autoIDHousehold
        }
    }

    // MARK: Datas e medida

    /// `dtpDateOfVisit_ValueChanged`: nascimento posterior à pesquisa passa a ser a data da pesquisa.
    public func setVisitDate(_ date: Date?) {
        visitDate = date.map(IndividualAssessment.normalized)
        if let visitDate, dateOfBirth > visitDate { dateOfBirth = visitDate }
        refreshAge()
    }

    /// Com data aproximada, o dia é sorteado de novo (D11); em todos os casos o nascimento não passa da pesquisa.
    public func setDateOfBirth(_ date: Date) {
        var proposed = IndividualAssessment.normalized(date)
        if dateOfBirthIsApprox { proposed = ApproximateBirthDate.randomized(proposed, randomDay: randomDay) }
        let adjusted = ApproximateBirthDate.adjusted(previous: dateOfBirth, proposed: proposed, isApprox: false,
                                                     upperBound: visitDate ?? .distantFuture, randomDay: randomDay)
        dateOfBirth = IndividualAssessment.normalized(adjusted)
        refreshAge()
    }

    /// `cbDateIsApprox_CheckedChanged`: marcar sorteia o dia em `1..<diasNoMês` e aplica o limite da pesquisa.
    public func setDateOfBirthIsApprox(_ approx: Bool) {
        dateOfBirthIsApprox = approx
        if approx {
            dateOfBirth = IndividualAssessment.approximated(dateOfBirth, upperBound: visitDate ?? .distantFuture,
                                                            randomDay: randomDay)
        }
        refreshAge()
    }

    public func setMeasuredRecumbent(_ recumbent: Bool) {
        measuredRecumbent = recumbent && isMeasureChoiceEnabled
    }

    // MARK: Registro

    /// `NSRecordDialog.SaveRecord`: textos sem espaços nas pontas, IDs automáticos para campos vazios com a opção ligada,
    /// idade digitada descartada com as duas datas; o registro novo copia a definição de dados adicionais do inquérito.
    public func makeRecord() throws -> SurveyRecord {
        let issues = issues
        guard issues.isEmpty else { throw RecordValidationError(issues: issues) }
        var record = editing ?? SurveyRecord()
        record.visitDate = visitDate
        record.weightingFactor = value(.weightingFactor) ?? 1
        record.cluster = identifier(.cluster, auto: survey.options.autoIDCluster, \.cluster)
        record.team = identifier(.team, auto: survey.options.autoIDTeam, \.team)
        record.displayID = identifier(.displayID, auto: survey.options.autoIDRecord, \.displayID)
        record.household = identifier(.household, auto: survey.options.autoIDHousehold, \.household)
        record.firstName = IndividualAssessment.nullable(firstName)
        record.lastName = IndividualAssessment.nullable(lastName)
        record.sex = sex
        record.dateOfBirth = dateOfBirthUnknown ? nil : dateOfBirth
        record.dateOfBirthIsApprox = dateOfBirthIsApprox && !dateOfBirthUnknown
        record.ageInMonths = isAgeEntryEnabled ? value(.ageInMonths) : nil
        record.weight = value(.weight)
        record.lengthOrHeight = value(.lengthOrHeight)
        record.measuredRecumbent = measuredRecumbent
        // Edema `nil` de um registro gravado fica `nil` se continuar desmarcado; registro novo grava falso.
        record.hasOedema = hasOedema ? true : (editing != nil && editing?.hasOedema == nil ? nil : false)
        record.notes = IndividualAssessment.nullable(notes)
        record.additionalDataXML = editing?.additionalDataXML ?? survey.additionalDataDefinitionXML ?? "<Data />"
        return record
    }

    // MARK: Privado

    private var datedAgeInDays: Int? {
        guard let visitDate, !dateOfBirthUnknown else { return nil }
        return try? AgeMath.ageInDays(birth: dateOfBirth, visit: visitDate)
    }

    /// Parte inteira dos meses, das datas ou da idade digitada.
    private var wholeMonths: Int? {
        if let days = datedAgeInDays { return AgeText.wholeMonths(AgeMath.daysToMonths(days)) }
        guard isAgeEntryEnabled, let typed = value(.ageInMonths) else { return nil }
        return AgeText.wholeMonths(typed)
    }

    /// `RefreshAge`: com as duas datas a idade digitada some; a partir de 11 meses a medida passa a em pé.
    private func refreshAge() {
        if !isAgeEntryEnabled, !(texts[.ageInMonths] ?? "").isEmpty { texts[.ageInMonths] = "" }
        if !isMeasureChoiceEnabled, measuredRecumbent { measuredRecumbent = false }
    }

    /// `GetNew*ID`: maior valor entre os registros existentes mais 1, só para campo vazio com a opção ligada.
    private func identifier(_ field: RecordNumericField, auto: Bool, _ keyPath: KeyPath<SurveyRecord, Int?>) -> Int? {
        if let typed = value(field) { return NSDecimalNumber(decimal: typed).intValue }
        guard auto else { return nil }
        return (existingRecords.compactMap { $0[keyPath: keyPath] }.max() ?? 0) + 1
    }

    /// Texto inicial do campo: casas fixas para medidas e idade, inteiro para IDs, casas próprias no fator de peso.
    private static func format(_ value: Decimal, _ field: RecordNumericField) -> String {
        switch field {
        case .weight, .lengthOrHeight, .ageInMonths: ClinicalFormat.string(value, places: 2)
        case .cluster, .team, .displayID, .household, .weightingFactor: "\(value)".replacingOccurrences(of: ".", with: ",")
        }
    }
}
