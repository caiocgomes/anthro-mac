import AnthroCore
import Foundation

/// `Survey.ExportSurveyToDelimitedFile` (design D14 e D15): 18 colunas na ordem original, resultados opcionais e as
/// colunas de dados adicionais da definição do inquérito; uma linha por registro.
public enum SurveyDelimitedExport {
    public static let baseColumns = [
        "Date", "Cluster", "Team", "DisplayID", "Household", "WeightingFactor", "FirstName", "LastName", "DateOfBirth",
        "DateOfBirthIsApprox", "Age", "Sex", "Weight", "Height", "IsRecumbent", "HasOedema", "Notes", "CreatedBy",
    ]
    public static let resultColumns = ["WAZ", "HAZ", "BAZ", "BMI"]

    /// Definição ou valores de dados adicionais ilegíveis saem sem colunas ou vazios: a gravação já valida os dois.
    public static func data(_ survey: ExchangeSurvey, resultsEngine: AnthroEngine?, format: DelimitedFormat) -> Data {
        let fixed = baseColumns + (resultsEngine == nil ? [] : resultColumns)
        let definition = (try? AdditionalDataXML.decode(survey.survey.additionalDataDefinitionXML)) ?? AdditionalData()
        // `GetDataStructure(list)`: as colunas já escritas são chaves proibidas.
        let additional = AdditionalDataColumns.structure(of: definition, forbiddenKeys: fixed)
        let rows = survey.records.map { record -> [String] in
            var row = fields(record)
            if let resultsEngine {
                row += SurveyXML.resultValues(record, engine: resultsEngine).map { FieldWriter.decimal($0.1, style: .comma) }
            }
            let values = additional.isEmpty ? nil : try? AdditionalDataXML.decode(record.additionalDataXML)
            row += additional.map { column in
                AdditionalValueText.text(values?.variable(section: column.sectionID, variable: column.variableID), style: .comma)
            }
            return row
        }
        let text = DelimitedWriter.write(header: fixed + additional.map(\.key), rows: rows, separator: format.separator)
        return DelimitedWriter.utf8WithBOM(text)
    }

    private static func fields(_ record: SurveyRecord) -> [String] {
        [FieldWriter.date(record.visitDate), FieldWriter.integer(record.cluster), FieldWriter.integer(record.team),
         FieldWriter.integer(record.displayID), FieldWriter.integer(record.household),
         FieldWriter.decimal(record.weightingFactor, style: .comma), FieldWriter.text(record.firstName),
         FieldWriter.text(record.lastName), FieldWriter.date(record.dateOfBirth),
         FieldWriter.boolean(record.dateOfBirthIsApprox), FieldWriter.decimal(SurveyXML.exportedAge(record), style: .comma),
         FieldWriter.sex(record.sex), FieldWriter.decimal(record.weight, style: .comma),
         FieldWriter.decimal(record.lengthOrHeight, style: .comma), FieldWriter.measureType(record.measuredRecumbent),
         FieldWriter.boolean(record.hasOedema ?? false), FieldWriter.text(record.notes), ExchangeDefaults.createdBy]
    }
}
