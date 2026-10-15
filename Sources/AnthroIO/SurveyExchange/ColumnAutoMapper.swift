/// Proposta de mapeamento de `NSImportDialog` (design D9), na ordem de testes do original e com o nome em maiúsculas:
/// nomes exatos, depois `WEIGHT` contido (peso), `HEIGHT` ou `LENGTH` contidos (altura), e por fim `MEASURE`, `EDEMA` e
/// `OEDEMA` exatos; uma coluna posterior sobrescreve a anterior. Por isso `WEIGHTFACTOR` vira peso.
public enum ColumnAutoMapper {
    public static func propose(columns: [String]) -> [SurveyImportField: String] {
        var mapping: [SurveyImportField: String] = [:]
        for column in columns {
            let name = column.uppercased()
            switch name {
            case "SURVDATE", "SURVEYDATE": mapping[.date] = column
            case "CLUSTER": mapping[.cluster] = column
            case "TEAM": mapping[.team] = column
            case "ID": mapping[.displayID] = column
            case "HH", "HOUSEHOLD": mapping[.household] = column
            case "WT FACTOR": mapping[.weightingFactor] = column
            case "DOB", "BIRTHDAT", "BIRTHDATE": mapping[.dateOfBirth] = column
            case "AGE", "MONTHS": mapping[.ageInMonths] = column
            case "SEX": mapping[.sex] = column
            default:
                if name.contains("WEIGHT") {
                    mapping[.weight] = column
                } else if name.contains("HEIGHT") || name.contains("LENGTH") {
                    mapping[.height] = column
                } else if name == "MEASURE" {
                    mapping[.isRecumbent] = column
                } else if name == "EDEMA" || name == "OEDEMA" {
                    mapping[.hasOedema] = column
                }
            }
        }
        return mapping
    }
}
