import AnthroIO

extension L10n {
    /// Rótulos do relatório da criança (definidos em `ChildReport.Labels`, no `AnthroIO`) e mensagens de importação e
    /// exportação da Avaliação individual (`Utils.DisplayImportError`, design D12).
    public enum Exchange {
        public typealias Report = ChildReport.Labels

        /// "Não foi possível importar o arquivo '{arquivo}':" seguido do motivo.
        public static let importFailedPrefix = "Não foi possível importar o arquivo"
        public static let invalidStructure = "o formato do arquivo é inválido."
        public static let missingField = "um ou mais campos obrigatórios estão ausentes."
        public static let invalidFieldValue = "um ou mais campos obrigatórios contêm valores inválidos."
        /// "Detalhe: linha {n}, elemento {e}, atributo {a}."
        public static let detail = "Detalhe:"
        public static let line = "linha"
        public static let element = "elemento"
        public static let attribute = "atributo"
        public static let unreadableFile = "o arquivo não pôde ser lido."

        // Tela
        public static let menu = "Importar e exportar"
        public static let importChildren = "Importar crianças (XML)…"
        public static let exportChildren = "Exportar crianças marcadas…"
        public static let childReport = "Relatório da criança…"
        public static let exportTitle = "Exportar crianças"
        public static let format = "Formato"
        public static let formatXML = "XML"
        public static let formatTabText = "TXT (tabulação)"
        public static let formatCSV = "CSV (ponto e vírgula)"
        public static let includeResults = "Incluir resultados (z-scores e IMC)"
        public static let export = "Exportar…"
        public static let cancel = "Cancelar"
        public static let checkedChildren = "criança(s) marcada(s)"
        public static let importedTitle = "Importação concluída"
        /// "{n} criança(s) importada(s)."
        public static let importedSuffix = "criança(s) importada(s)."
        public static let importFailedTitle = "Falha na importação"
        public static let fileErrorTitle = "Não foi possível gravar o arquivo"
        public static let reportNeedsSave = "Salve a ficha da criança antes de gerar o relatório."
        public static let defaultExportName = "Crianças"
    }

    /// Strings desta extensão, somadas a `L10n.allStrings`.
    static var exchangeStrings: [String] {
        let e = Exchange.self, r = ChildReport.Labels.self
        return [e.importFailedPrefix, e.invalidStructure, e.missingField, e.invalidFieldValue, e.detail, e.line, e.element,
                e.attribute, e.unreadableFile, e.menu, e.importChildren, e.exportChildren, e.childReport, e.exportTitle,
                e.format, e.formatXML, e.formatTabText, e.formatCSV, e.includeResults, e.export, e.cancel,
                e.checkedChildren, e.importedTitle, e.importedSuffix, e.importFailedTitle, e.fileErrorTitle,
                e.reportNeedsSave, e.defaultExportName, r.title, r.firstName, r.lastName, r.dateOfBirth, r.male, r.female, r.results,
                r.yearSuffix, r.monthSuffix, r.yes, r.no, r.footnote, r.untitledFileName] + r.columns
    }
}
