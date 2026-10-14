import AnthroCore
import Foundation

/// Linha da tabela de registros: resultado e flags calculados uma vez com as opções correntes (design D5, formatos de
/// `dgvRecords_CellValueNeeded`).
public struct SurveyRecordRow: Sendable, Equatable {
    public let record: SurveyRecord
    public let result: AnthropometricResult
    private let flaggedIndicators: Set<Indicator>
    public let flag: PlausibilityFlag
    /// Dados adicionais do registro; XML ilegível conta como sem dados (células vazias).
    private let additionalValues: AdditionalData

    public init(record: SurveyRecord, engine: AnthroEngine, options: SurveyOptions) {
        self.record = record
        let result = SurveyRecordEvaluation.result(record, engine: engine)
        self.result = result
        flaggedIndicators = Set(Indicator.allCases.filter {
            SurveyPlausibility.isFlagged($0, result: result, options: options)
        })
        flag = SurveyPlausibility.flag(result: result, options: options)
        additionalValues = (try? AdditionalDataXML.decode(record.additionalDataXML)) ?? AdditionalData()
    }

    public func text(_ column: SurveyTableColumn) -> String {
        switch column {
        case .fixed(let fixed): text(fixed)
        case .additional(let column): additionalText(column)
        }
    }

    /// Idade calculada das datas (cinza no original); idade digitada não é derivada.
    public func isDerived(_ column: SurveyTableColumn) -> Bool {
        guard case .fixed(let fixed) = column, fixed == .ageInDays || fixed == .ageInMonths else { return false }
        return record.ageInMonths == nil && SurveyRecordEvaluation.ageInDays(record) != nil
    }

    /// `SetCellBackColor`: z existente e implausível pelos limites do inquérito.
    public func isHighlighted(_ column: SurveyTableColumn) -> Bool {
        guard case .fixed(let fixed) = column, let indicator = fixed.indicator else { return false }
        return result.score(indicator).zScore != nil && flaggedIndicators.contains(indicator)
    }

    func isFlagged(_ indicator: Indicator) -> Bool {
        flaggedIndicators.contains(indicator)
    }

    // MARK: Células

    private func text(_ column: SurveyColumn) -> String {
        switch column {
        case .surveyDate: record.visitDate.map(Self.date) ?? ""
        case .cluster: record.cluster.map(String.init) ?? ""
        case .team: record.team.map(String.init) ?? ""
        case .displayID: record.displayID.map(String.init) ?? ""
        case .household: record.household.map(String.init) ?? ""
        case .sex: record.sex == .girl ? L10n.Calculator.female : L10n.Calculator.male
        case .dateOfBirth: record.dateOfBirth.map { record.dateOfBirthIsApprox ? Self.approximateDate($0) : Self.date($0) } ?? ""
        case .ageInDays: ageInDaysText
        case .ageInMonths: SurveyRecordEvaluation.ageInMonths(record).map { Self.decimal($0, places: 2) } ?? ""
        case .weight: record.weight.map { Self.decimal($0, places: 2) } ?? ""
        case .oedema: Self.yesNo(record.hasOedema == true)
        case .recumbent: Self.yesNo(record.measuredRecumbent)
        case .lengthOrHeight: record.lengthOrHeight.map { Self.decimal($0, places: 2) } ?? ""
        case .weightForAgeZ: zText(.weightForAge)
        case .lengthOrHeightForAgeZ: zText(.lengthOrHeightForAge)
        case .bmiForAgeZ: zText(.bmiForAge)
        case .flag: Self.flagText(flag)
        case .weightingFactor: "\(record.weightingFactor)".replacingOccurrences(of: ".", with: ",")
        case .estimatedDateOfBirth: Self.yesNo(record.dateOfBirthIsApprox)
        }
    }

    /// Variável do registro com a seção e o identificador da coluna (`FindSection`, `FindVariable`).
    func additionalVariable(_ column: AdditionalDataColumn) -> AdditionalDataVariable? {
        additionalValues.variable(section: column.sectionID, variable: column.variableID)
    }

    /// `dgvRecords_CellValueNeeded` a partir da coluna 19: texto como está, número com vírgula e as casas que tiver,
    /// data dd/MM/aaaa; variável ausente ou sem valor fica vazia.
    private func additionalText(_ column: AdditionalDataColumn) -> String {
        switch additionalVariable(column)?.kind {
        case .text(let value): value ?? ""
        case .number(let value, _, _): value.map { "\($0)".replacingOccurrences(of: ".", with: ",") } ?? ""
        case .date(let value): value.map(Self.date) ?? ""
        case nil: ""
        }
    }

    /// Idade digitada: `Round(meses * 30.4375, 0)`; sem ela, os dias das datas.
    private var ageInDaysText: String {
        if let typed = record.ageInMonths {
            return ClinicalRounding.round(typed * Decimal(string: "30.4375")!, places: 0).map { "\($0)" } ?? ""
        }
        return SurveyRecordEvaluation.ageInDays(record).map(String.init) ?? ""
    }

    private func zText(_ indicator: Indicator) -> String {
        result.score(indicator).zScore.map { ClinicalFormat.string($0, places: 2) } ?? ""
    }

    private static func decimal(_ value: Decimal, places: Int) -> String {
        ClinicalFormat.string(ClinicalRounding.round(value, places: places), places: places)
    }

    private static func yesNo(_ value: Bool) -> String {
        value ? L10n.Calculator.yes : L10n.Calculator.no
    }

    /// `Utils.GetLocalizedFlagName`: estatura antes de peso quando as duas falham.
    static func flagText(_ flag: PlausibilityFlag) -> String {
        typealias S = L10n.Survey
        return switch flag {
        case .none: ""
        case .weightForAge: S.flagWeightForAge
        case .lengthOrHeightForAge: S.flagLengthOrHeightForAge
        case .weightAndLengthOrHeightForAge: "\(S.flagLengthOrHeightForAge), \(S.flagWeightForAge)"
        case .bmiForAge: S.flagBMIForAge
        }
    }

    /// `ToShortDateString` em pt-BR, no dia de calendário do usuário.
    static func date(_ date: Date) -> String {
        let parts = Calendar.current.dateComponents([.year, .month, .day], from: date)
        return String(format: "%02d/%02d/%04d", parts.day!, parts.month!, parts.year!)
    }

    /// Padrão curto com o dia trocado por "XX" (`ShortDatePattern.Replace('d', 'X')`).
    static func approximateDate(_ date: Date) -> String {
        let parts = Calendar.current.dateComponents([.year, .month], from: date)
        return String(format: "XX/%02d/%04d", parts.month!, parts.year!)
    }
}
