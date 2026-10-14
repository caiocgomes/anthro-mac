import AnthroCore

/// As 19 colunas fixas da tabela de registros, na ordem de `dgvRecords_CellValueNeeded`.
public enum SurveyColumn: Int, CaseIterable, Sendable {
    case surveyDate, cluster, team, displayID, household, sex, dateOfBirth, ageInDays, ageInMonths, weight, oedema,
         recumbent, lengthOrHeight, weightForAgeZ, lengthOrHeightForAgeZ, bmiForAgeZ, flag, weightingFactor,
         estimatedDateOfBirth

    public var title: String {
        typealias C = L10n.Survey.Column
        return switch self {
        case .surveyDate: C.surveyDate
        case .cluster: C.cluster
        case .team: C.team
        case .displayID: C.displayID
        case .household: C.household
        case .sex: C.sex
        case .dateOfBirth: C.dateOfBirth
        case .ageInDays: C.ageInDays
        case .ageInMonths: C.ageInMonths
        case .weight: C.weight
        case .oedema: C.oedema
        case .recumbent: C.recumbent
        case .lengthOrHeight: C.lengthOrHeight
        case .weightForAgeZ: C.weightForAgeZ
        case .lengthOrHeightForAgeZ: C.lengthOrHeightForAgeZ
        case .bmiForAgeZ: C.bmiForAgeZ
        case .flag: C.flag
        case .weightingFactor: C.weightingFactor
        case .estimatedDateOfBirth: C.estimatedDateOfBirth
        }
    }

    /// Indicador da coluna de z, se for uma.
    var indicator: Indicator? {
        switch self {
        case .weightForAgeZ: .weightForAge
        case .lengthOrHeightForAgeZ: .lengthOrHeightForAge
        case .bmiForAgeZ: .bmiForAge
        default: nil
        }
    }
}

/// Coluna da tabela: as 19 fixas e as de dados adicionais da definição do inquérito.
public enum SurveyTableColumn: Hashable, Sendable {
    case fixed(SurveyColumn)
    case additional(AdditionalDataColumn)

    /// Fixas pelo título em pt-BR; adicionais pelo rótulo traduzido da variável mais o sufixo da chave (" 2"...).
    public var title: String {
        switch self {
        case .fixed(let column):
            column.title
        case .additional(let column):
            AdditionalDataLabels.display(column.variableID)
                + (column.key.hasPrefix(column.variableID) ? String(column.key.dropFirst(column.variableID.count)) : "")
        }
    }
}
