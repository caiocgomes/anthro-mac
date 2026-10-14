extension L10n {
    /// Textos do módulo Inquérito nutricional.
    public enum Survey {
        public static let required = "Campo obrigatório"
        /// "Valor mínimo: {mín}", para campos sem limite superior prático (fator de peso).
        public static let minimumPrefix = "Valor mínimo:"
    }

    /// Strings desta extensão, somadas a `L10n.allStrings`.
    static var surveyStrings: [String] {
        let s = Survey.self
        return [s.required, s.minimumPrefix]
    }
}
