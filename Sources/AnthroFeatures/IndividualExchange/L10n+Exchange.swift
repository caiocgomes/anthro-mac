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
    }

    /// Strings desta extensão, somadas a `L10n.allStrings`.
    static var exchangeStrings: [String] {
        let e = Exchange.self, r = ChildReport.Labels.self
        return [e.importFailedPrefix, e.invalidStructure, e.missingField, e.invalidFieldValue, e.detail, e.line, e.element,
                e.attribute, e.unreadableFile, r.title, r.firstName, r.lastName, r.dateOfBirth, r.male, r.female, r.results,
                r.yearSuffix, r.monthSuffix, r.yes, r.no, r.footnote, r.untitledFileName] + r.columns
    }
}
