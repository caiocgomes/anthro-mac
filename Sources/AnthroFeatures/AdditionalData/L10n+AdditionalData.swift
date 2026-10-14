extension L10n {
    /// Textos dos dados adicionais (o nome evita sombrear o tipo `AdditionalData` dentro de `L10n`).
    public enum AddData {
        /// "Valor mínimo: {mín}" e "Valor máximo: {máx}", para variáveis com um só limite.
        public static let minimumPrefix = "Valor mínimo:"
        public static let maximumPrefix = "Valor máximo:"

        public static let manage = "Gerenciar dados adicionais"
        public static let surveyButton = "Dados adicionais"
        public static let formSection = "Dados adicionais"
        public static let templateTitle = "Dados adicionais da avaliação individual"
        public static let definitionTitle = "Dados adicionais do inquérito"
        public static let newSection = "Nova seção"
        public static let newVariable = "Nova variável"
        public static let delete = "Excluir"
        public static let identifier = "Identificador"
        public static let description = "Descrição"
        public static let kind = "Tipo"
        public static let text = "Texto"
        public static let number = "Número"
        public static let date = "Data"
        public static let minimum = "Mínimo"
        public static let maximum = "Máximo"
        public static let noLimit = "Sem limite"
        public static let unnamed = "(sem identificador)"
        public static let noSelection = "Selecione uma seção ou variável, ou inclua uma seção."
        public static let emptyDefinition = "Nenhuma seção definida."
        public static let identifierHint = "O identificador é gravado como digitado; os do modelo padrão aparecem traduzidos."
        public static let informDate = "Informar data"
        public static let apply = "Aplicar"
        public static let cancel = "Cancelar"
        /// `AdditionalDataDialog_MsgInvalidID`.
        public static let emptyIdentifier = "Toda seção e toda variável precisam de um identificador."
        /// "Identificador repetido: {seção}" ou "{seção} / {variável}".
        public static let duplicatePrefix = "Identificador repetido:"
        public static let invalidValues = "Há dados adicionais inválidos. Corrija os campos marcados."
    }

    /// Strings desta extensão, somadas a `L10n.allStrings`.
    static var additionalDataStrings: [String] {
        let a = AddData.self
        return [a.minimumPrefix, a.maximumPrefix, a.manage, a.surveyButton, a.formSection, a.templateTitle,
                a.definitionTitle, a.newSection, a.newVariable, a.delete, a.identifier, a.description, a.kind, a.text,
                a.number, a.date, a.minimum, a.maximum, a.noLimit, a.unnamed, a.noSelection, a.emptyDefinition,
                a.identifierHint, a.informDate, a.apply, a.cancel, a.emptyIdentifier, a.duplicatePrefix, a.invalidValues]
    }
}
