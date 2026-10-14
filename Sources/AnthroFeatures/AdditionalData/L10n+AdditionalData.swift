extension L10n {
    /// Textos dos dados adicionais (o nome evita sombrear o tipo `AdditionalData` dentro de `L10n`).
    public enum AddData {
        /// "Valor mínimo: {mín}" e "Valor máximo: {máx}", para variáveis com um só limite.
        public static let minimumPrefix = "Valor mínimo:"
        public static let maximumPrefix = "Valor máximo:"
    }

    /// Strings desta extensão, somadas a `L10n.allStrings`.
    static var additionalDataStrings: [String] {
        let a = AddData.self
        return [a.minimumPrefix, a.maximumPrefix]
    }
}
