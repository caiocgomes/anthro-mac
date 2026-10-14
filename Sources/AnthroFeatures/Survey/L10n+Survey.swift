extension L10n {
    /// Textos do módulo Inquérito nutricional.
    public enum Survey {
        public static let required = "Campo obrigatório"
        /// "Valor mínimo: {mín}", para campos sem limite superior prático (fator de peso).
        public static let minimumPrefix = "Valor mínimo:"

        /// Abreviações de `_Label_W4AZ`, `_Label_LH4AZ` e `_Label_BMI4AZ` usadas na coluna de flag.
        public static let flagWeightForAge = "P/I"
        public static let flagLengthOrHeightForAge = "E/I"
        public static let flagBMIForAge = "IMC/I"
        /// `NSMain_LabelNbRecords`: "{n} registro(s)".
        public static let recordCountSuffix = "registro(s)"

        public enum Filter {
            public static let range = "Intervalo"
        }

        /// Títulos das 19 colunas (`colSurveyDate.HeaderText` a `colEDOB.HeaderText`).
        public enum Column {
            public static let surveyDate = "Data da pesquisa"
            public static let cluster = "Conglomerado"
            public static let team = "Equipe"
            public static let displayID = "ID"
            public static let household = "Domicílio"
            public static let sex = "Sexo"
            public static let dateOfBirth = "Data de nascimento"
            public static let ageInDays = "Idade (d)"
            public static let ageInMonths = "Idade (m)"
            public static let weight = "Peso (kg)"
            public static let oedema = "Edema"
            public static let recumbent = "Deitado"
            public static let lengthOrHeight = "Estatura (cm)"
            public static let weightForAgeZ = "z P/I"
            public static let lengthOrHeightForAgeZ = "z E/I"
            public static let bmiForAgeZ = "z IMC/I"
            public static let flag = "Flag"
            public static let weightingFactor = "Fator de peso"
            public static let estimatedDateOfBirth = "Nascimento estimado"
        }
    }

    /// Strings desta extensão, somadas a `L10n.allStrings`.
    static var surveyStrings: [String] {
        let s = Survey.self, c = Survey.Column.self
        return [
            s.required, s.minimumPrefix, s.flagWeightForAge, s.flagLengthOrHeightForAge, s.flagBMIForAge,
            s.recordCountSuffix, s.Filter.range,
            c.surveyDate, c.cluster, c.team, c.displayID, c.household, c.sex, c.dateOfBirth, c.ageInDays, c.ageInMonths,
            c.weight, c.oedema, c.recumbent, c.lengthOrHeight, c.weightForAgeZ, c.lengthOrHeightForAgeZ, c.bmiForAgeZ,
            c.flag, c.weightingFactor, c.estimatedDateOfBirth,
        ]
    }
}
