/// As 19 colunas fixas da tabela de registros, na ordem de `dgvRecords_CellValueNeeded`.
public enum SurveyColumn: Int, CaseIterable, Sendable {
    case surveyDate, cluster, team, displayID, household, sex, dateOfBirth, ageInDays, ageInMonths, weight, oedema,
         recumbent, lengthOrHeight, weightForAgeZ, lengthOrHeightForAgeZ, bmiForAgeZ, flag, weightingFactor,
         estimatedDateOfBirth

    public var title: String {
        ""
    }
}

/// Coluna da tabela; as colunas de dados adicionais chegam na change add-additional-data.
public enum SurveyTableColumn: Hashable, Sendable {
    case fixed(SurveyColumn)
}
