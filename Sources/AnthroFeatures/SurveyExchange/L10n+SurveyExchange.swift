import AnthroIO

extension L10n {
    /// Mensagens e rótulos da importação e exportação do Inquérito nutricional (`Utils.DisplayImportWarningRows`,
    /// `DisplayImportWarningFields`, `NSImportDialog`, `tsbSurveyExport_Click`).
    public enum SurveyExchange {
        /// "O arquivo '{arquivo}' foi importado, mas ..."
        public static let filePrefix = "O arquivo"
        public static let rowsIgnored = "foi importado, mas uma ou mais linhas foram ignoradas por campos obrigatórios ausentes ou inválidos."
        public static let fieldsInvalid = "foi importado, mas um ou mais campos estavam ausentes ou continham valores inválidos."
        public static let alsoFieldsInvalid = "Além disso, um ou mais campos estavam ausentes ou continham valores inválidos."
        /// "Detalhes: linha {n}, campo '{coluna}'. linha {m}, ..." (`_MsgImport_InfoDetails`).
        public static let details = "Detalhes:"
        public static let field = "campo"

        // Tela
        public static let importSurvey = "Importar…"
        public static let exportSurveys = "Exportar…"
        public static let mappingTitle = "Associar colunas do arquivo"
        public static let mappingHint = "Escolha a coluna do arquivo para cada campo do AnthroPlus. O sexo é obrigatório; as colunas sem campo viram dados adicionais."
        public static let notMapped = "(nenhuma)"
        public static let confirmImport = "Importar"
        public static let exportTitle = "Exportar inquéritos"
        public static let checkedSurveys = "inquérito(s) marcado(s)"
        public static let onlyFirstExported = "TXT e CSV guardam um inquérito por arquivo: só o primeiro inquérito marcado foi exportado. Use XML para exportar todos."
        public static let importedTitle = "Importação concluída"
        public static let importedXML = "Os inquéritos do arquivo foram gravados."
        public static let draftOpened = "O inquérito importado foi aberto e ainda não está gravado: confira e salve."
        public static let exportNeedsSave = "O inquérito aberto está marcado e tem alterações não salvas. Salve o inquérito antes de exportar."
        public static let exportDone = "Exportação concluída"
        public static let defaultExportName = "Inquéritos"

        /// Rótulo de cada campo na folha de associação.
        public static func label(_ field: SurveyImportField) -> String {
            switch field {
            case .date: Survey.Column.surveyDate
            case .cluster: Survey.Column.cluster
            case .team: Survey.Column.team
            case .displayID: Survey.Column.displayID
            case .household: Survey.Column.household
            case .weightingFactor: Survey.Column.weightingFactor
            case .dateOfBirth: Survey.Column.dateOfBirth
            case .ageInMonths: Survey.ageInMonths
            case .sex: Survey.Column.sex
            case .weight: Survey.Column.weight
            case .height: Calculator.lengthOrHeight
            case .isRecumbent: Survey.Column.recumbent
            case .hasOedema: Survey.Column.oedema
            }
        }
    }

    /// Strings desta extensão, somadas a `L10n.allStrings`.
    static var surveyExchangeStrings: [String] {
        let s = SurveyExchange.self
        return [s.filePrefix, s.rowsIgnored, s.fieldsInvalid, s.alsoFieldsInvalid, s.details, s.field, s.importSurvey, s.exportSurveys,
                s.mappingTitle, s.mappingHint, s.notMapped, s.confirmImport, s.exportTitle, s.checkedSurveys,
                s.onlyFirstExported, s.importedTitle, s.importedXML, s.draftOpened, s.exportNeedsSave, s.exportDone,
                s.defaultExportName]
    }
}
