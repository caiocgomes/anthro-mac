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
            public static let title = "Filtrar registros"
            public static let column = "Coluna"
            public static let condition = "Condição"
            public static let value = "Valor"
            public static let upTo = "até"
            public static let apply = "Filtrar"
            public static let hint = "O filtro atua sobre os registros visíveis; filtros seguidos se somam."
        }

        // Lista de inquéritos
        public static let surveys = "Inquéritos"
        public static let archive = "Arquivo"
        public static let newSurvey = "Novo inquérito"
        public static let archiveAction = "Arquivar"
        public static let restore = "Restaurar"
        public static let delete = "Excluir"
        public static let viewArchive = "Ver arquivo"
        public static let backToActive = "Voltar aos inquéritos"
        public static let checkedCount = "marcados"
        public static let emptyList = "Nenhum inquérito"
        public static let deleteSurveysTitle = "Excluir os inquéritos marcados?"
        public static let deleteSurveysMessage = "Os inquéritos e todos os seus registros serão apagados. Não dá para desfazer."

        // Inquérito aberto
        public static let noSurveyOpen = "Nenhum inquérito aberto"
        public static let noSurveyOpenHint = "Crie um inquérito ou abra um da lista."
        public static let name = "Nome do inquérito"
        public static let notes = "Notas"
        public static let untitled = "Inquérito novo"
        public static let save = "Salvar"
        public static let discard = "Descartar alterações"
        public static let options = "Opções"
        public static let newRecord = "Novo registro"
        public static let editRecord = "Editar registro"
        public static let deleteRecords = "Excluir registros"
        public static let filter = "Filtrar"
        public static let clearFilter = "Remover filtro"
        public static let copy = "Copiar"
        public static let noRecordSelected = "Selecione um registro para ver os resultados."
        public static let unsavedTitle = "Salvar as alterações deste inquérito?"
        public static let unsavedMessage = "Há alterações no inquérito ou nos registros que ainda não foram gravadas."
        public static let discardTitle = "Descartar as alterações deste inquérito?"
        public static let discardMessage = "O inquérito e os registros voltam ao que está gravado no banco."
        public static let deleteRecordsTitle = "Excluir os registros selecionados?"
        public static let deleteRecordsMessage = "Os registros saem do inquérito e são apagados do banco ao salvar."
        public static let nameRequired = "Dê um nome ao inquérito antes de salvar."
        public static let invalidFields = "Corrija os campos marcados antes de confirmar."

        // Editor de registro
        public static let surveyDate = "Data da pesquisa"
        public static let hasSurveyDate = "Data da pesquisa informada"
        public static let identification = "Identificação"
        public static let cluster = "Conglomerado"
        public static let team = "Equipe"
        public static let recordID = "ID"
        public static let household = "Domicílio"
        public static let weightingFactor = "Fator de peso"
        public static let automatic = "Automático"
        public static let child = "Criança"
        public static let firstName = "Nome"
        public static let lastName = "Sobrenome"
        public static let dateOfBirth = "Data de nascimento"
        public static let approximateDate = "Data aproximada"
        public static let unknownDateOfBirth = "Nascimento desconhecido"
        public static let ageInMonths = "Idade (meses)"
        public static let measurements = "Medidas"
        public static let confirm = "Confirmar"
        public static let cancel = "Cancelar"

        // Opções
        public static let optionsTitle = "Opções do inquérito"
        public static let autoIDSection = "Atribuição automática de IDs"
        public static let ageGroupsSection = "Faixas etárias (meses)"
        public static let ageGroup = "Faixa"
        public static let upTo = "a"
        public static let addAgeGroup = "Adicionar faixa"
        public static let removeAgeGroup = "Remover faixa"
        public static let zBoundsSection = "Limites de z para plausibilidade"
        public static let standards = "Padrões (até 60 meses)"
        public static let reference = "Referência (61 meses ou mais)"
        public static let minimum = "Mínimo"
        public static let maximum = "Máximo"
        public static let resetDefaults = "Restaurar padrões"
        public static let apply = "Aplicar"
        public static let tooFewAgeGroups = "Defina ao menos duas faixas etárias."
        public static let inconsistentAgeGroups = "As faixas etárias estão inconsistentes: os limites inferiores devem crescer, de 0 a 228 meses."
        public static let invalidZBounds = "Corrija os limites de z marcados antes de aplicar."

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
            s.recordCountSuffix, s.Filter.range, s.Filter.title, s.Filter.column, s.Filter.condition, s.Filter.value,
            s.Filter.upTo, s.Filter.apply, s.Filter.hint,
            s.surveys, s.archive, s.newSurvey, s.archiveAction, s.restore, s.delete, s.viewArchive, s.backToActive,
            s.checkedCount, s.emptyList, s.deleteSurveysTitle, s.deleteSurveysMessage,
            s.noSurveyOpen, s.noSurveyOpenHint, s.name, s.notes, s.untitled, s.save, s.discard, s.options, s.newRecord,
            s.editRecord, s.deleteRecords, s.filter, s.clearFilter, s.copy, s.noRecordSelected, s.unsavedTitle,
            s.unsavedMessage, s.discardTitle, s.discardMessage, s.deleteRecordsTitle, s.deleteRecordsMessage,
            s.nameRequired, s.invalidFields,
            s.surveyDate, s.hasSurveyDate, s.identification, s.cluster, s.team, s.recordID, s.household,
            s.weightingFactor, s.automatic, s.child, s.firstName, s.lastName, s.dateOfBirth, s.approximateDate,
            s.unknownDateOfBirth, s.ageInMonths, s.measurements, s.confirm, s.cancel,
            s.optionsTitle, s.autoIDSection, s.ageGroupsSection, s.ageGroup, s.upTo, s.addAgeGroup, s.removeAgeGroup,
            s.zBoundsSection, s.standards, s.reference, s.minimum, s.maximum, s.resetDefaults, s.apply,
            s.tooFewAgeGroups, s.inconsistentAgeGroups, s.invalidZBounds,
            c.surveyDate, c.cluster, c.team, c.displayID, c.household, c.sex, c.dateOfBirth, c.ageInDays, c.ageInMonths,
            c.weight, c.oedema, c.recumbent, c.lengthOrHeight, c.weightForAgeZ, c.lengthOrHeightForAgeZ, c.bmiForAgeZ,
            c.flag, c.weightingFactor, c.estimatedDateOfBirth,
        ]
    }
}
