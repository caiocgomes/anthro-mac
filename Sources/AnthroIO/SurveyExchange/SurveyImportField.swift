/// Os 13 campos do inquérito que a importação externa mapeia (`Survey.Field`).
public enum SurveyImportField: String, CaseIterable, Sendable {
    case date = "Date"
    case cluster = "Cluster"
    case team = "Team"
    case displayID = "DisplayID"
    case household = "Household"
    case weightingFactor = "WeightingFactor"
    case dateOfBirth = "DateOfBirth"
    case ageInMonths = "AgeInMonths"
    case sex = "Sex"
    case weight = "Weight"
    case height = "Height"
    case isRecumbent = "IsRecumbent"
    case hasOedema = "HasOedema"
}
