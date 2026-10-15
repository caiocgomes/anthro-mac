import AnthroCore
import Foundation

/// Inquérito montado a partir da tabela externa, com os registros descartados e o aviso de campos inválidos.
public struct ExternalImportResult: Equatable, Sendable {
    public var draft: ExchangeSurvey
    public var rowErrors: [ImportFieldError]
    public var hadFieldWarnings: Bool

    public init(draft: ExchangeSurvey, rowErrors: [ImportFieldError], hadFieldWarnings: Bool) {
        self.draft = draft
        self.rowErrors = rowErrors
        self.hadFieldWarnings = hadFieldWarnings
    }
}

/// `Survey.CreateSurveyFromExternalData` (design D10 e D11) sobre `Survey` e `SurveyRecord` da change 5.
public enum ExternalSurveyBuilder {
    public static let importedSectionID = "Imported"
    public static let importedSectionDescription = "Dados importados de arquivo externo."
    /// `_IMPORT_MANDATORYFIELDS` de `Survey`.
    static let mandatoryFields: [SurveyImportField] = [.sex]
    /// O original lista no máximo 10 registros descartados.
    static let maxRowErrors = 10
    /// `int.Parse` do original: acima disso o campo é inválido.
    static let maxInteger = Int(Int32.max)

    public static func build(table: ImportedTable, mapping: [SurveyImportField: String],
                             name: String) throws(ImportFailure) -> ExternalImportResult {
        let missing = mandatoryFields.filter { mapping[$0] == nil }
        guard missing.isEmpty else {
            throw .missingField(missing.map { ImportFieldError(line: 0, field: $0.rawValue) })
        }
        let mappedColumns = Set(mapping.values.filter { !$0.isEmpty })
        let extraColumns = table.columns.filter { !mappedColumns.contains($0) }
        var survey = Survey(name: name)
        if !extraColumns.isEmpty {
            let definition = AdditionalData(sections: [AdditionalDataSection(
                identifier: importedSectionID, description: importedSectionDescription,
                variables: extraColumns.map { AdditionalDataVariable(identifier: $0, kind: .text(nil)) })])
            survey.additionalDataDefinitionXML = AdditionalDataXML.encode(definition)
        }
        var records: [SurveyRecord] = []
        var rowErrors: [ImportFieldError] = []
        var warning = false
        for (index, row) in table.rows.enumerated() {
            func cell(_ field: SurveyImportField) -> String? {
                guard let column = mapping[field], let position = table.columns.firstIndex(of: column) else { return nil }
                return row.indices.contains(position) ? row[position] : ""
            }
            guard let sexText = cell(.sex), let sex = try? FieldParser.sex(sexText) else {
                if rowErrors.count < maxRowErrors {
                    rowErrors.append(ImportFieldError(line: index + 1, field: mapping[.sex] ?? SurveyImportField.sex.rawValue))
                }
                continue
            }
            var record = SurveyRecord(sex: sex)
            // Campo opcional inválido fica ausente e acende o aviso; o registro continua.
            func optional<T>(_ field: SurveyImportField, _ parse: (String) throws -> T?) -> T? {
                guard let text = cell(field) else { return nil }
                do {
                    return try parse(text)
                } catch {
                    warning = true
                    return nil
                }
            }
            record.visitDate = optional(.date) { try FieldParser.date($0, nullable: true) }
            record.cluster = optional(.cluster) { try FieldParser.unsignedInteger($0, nullable: true, max: maxInteger) }
            record.team = optional(.team) { try FieldParser.unsignedInteger($0, nullable: true, max: maxInteger) }
            record.displayID = optional(.displayID) { try FieldParser.unsignedInteger($0, nullable: true, max: maxInteger) }
            record.household = optional(.household) { try FieldParser.unsignedInteger($0, nullable: true, max: maxInteger) }
            if let text = cell(.weightingFactor) {
                // Mapeado e vazio ou inválido vale 0 com aviso; sem mapeamento fica o 1 do registro novo.
                if let factor = try? FieldParser.decimal(text, nullable: false, unsigned: true, truncateToPlaces: nil) {
                    record.weightingFactor = factor
                } else {
                    record.weightingFactor = 0
                    warning = true
                }
            }
            record.dateOfBirth = optional(.dateOfBirth) { try FieldParser.date($0, nullable: true) }
            record.ageInMonths = optional(.ageInMonths) {
                try FieldParser.decimal($0, nullable: true, unsigned: true, truncateToPlaces: nil)
            }
            record.weight = optional(.weight) {
                try FieldParser.decimal($0, nullable: true, unsigned: true, min: InputLimits.minWeight, max: InputLimits.maxWeight)
            }
            record.lengthOrHeight = optional(.height) {
                try FieldParser.decimal($0, nullable: true, unsigned: true, min: InputLimits.minLengthOrHeight,
                                        max: InputLimits.maxLengthOrHeight)
            }
            // Setter de `Record.Age`: com as duas datas, a idade lida é descartada (D18).
            if record.visitDate != nil, record.dateOfBirth != nil { record.ageInMonths = nil }
            let measure = optional(.isRecumbent) { try FieldParser.measureType($0) }
            if let measure {
                record.measuredRecumbent = measure
            } else if let days = SurveyRecordEvaluation.ageInDays(record) {
                record.measuredRecumbent = days < 731
            } else {
                record.measuredRecumbent = record.lengthOrHeight.map { $0 < 87 } ?? false
            }
            record.hasOedema = optional(.hasOedema) { try FieldParser.boolean($0, nullable: true) } ?? false
            if !extraColumns.isEmpty {
                let values = extraColumns.map { column -> AdditionalDataVariable in
                    let text = table.columns.firstIndex(of: column).flatMap { row.indices.contains($0) ? row[$0] : nil } ?? ""
                    return AdditionalDataVariable(identifier: column, kind: .text(text.isEmpty ? nil : text))
                }
                record.additionalDataXML = AdditionalDataXML.encode(AdditionalData(sections: [AdditionalDataSection(
                    identifier: importedSectionID, description: importedSectionDescription, variables: values)]))
            }
            records.append(record)
        }
        return ExternalImportResult(draft: ExchangeSurvey(survey: survey, records: records), rowErrors: rowErrors,
                                    hadFieldWarnings: warning)
    }
}
