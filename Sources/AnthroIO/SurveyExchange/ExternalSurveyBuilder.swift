import AnthroCore

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

/// `Survey.CreateSurveyFromExternalData` (design D10 e D11).
public enum ExternalSurveyBuilder {
    public static let importedSectionID = ""
    public static let importedSectionDescription = ""

    public static func build(table: ImportedTable, mapping: [SurveyImportField: String],
                             name: String) throws(ImportFailure) -> ExternalImportResult {
        ExternalImportResult(draft: ExchangeSurvey(survey: Survey(), records: []), rowErrors: [], hadFieldWarnings: false)
    }
}
