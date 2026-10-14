extension L10n {
    /// Textos do módulo Avaliação individual.
    public enum IndividualAssessment {
        public static let yes = "Sim"
        public static let no = "Não"
        /// "Valor inválido; intervalo aceito: {mín} a {máx}" (design D7).
        public static let invalidWithRangePrefix = "Valor inválido; intervalo aceito:"
        public static let children = "Crianças"
        public static let archive = "Arquivo"
        public static let searchResults = "Resultados da busca"
        public static let newChild = "Nova criança"
        public static let search = "Buscar"
        public static let clearSearch = "Limpar busca"
        public static let archiveAction = "Arquivar"
        public static let restore = "Restaurar"
        public static let delete = "Excluir"
        public static let backToList = "Voltar à lista"
        public static let child = "Criança"
        public static let displayID = "ID"
        public static let firstName = "Nome"
        public static let lastName = "Sobrenome"
        public static let dateOfBirth = "Data de nascimento"
        public static let approximateDate = "Data aproximada"
        public static let sex = "Sexo"
        public static let notes = "Notas"
        public static let mother = "Mãe"
        public static let father = "Pai"
        public static let address = "Endereço"
        public static let followUp = "Acompanhamento"
        public static let followUpDate = "Data do retorno"
        public static let followUpInterval = "Intervalo (dias)"
        public static let followUpRefTo = "Encaminhado a"
        public static let visits = "Visitas"
        public static let visitDate = "Data"
        public static let weight = "Peso (kg)"
        public static let lengthOrHeight = "Comprimento/estatura (cm)"
        public static let oedema = "Edema"
        public static let recumbent = "Deitado"
        public static let standing = "Em pé"
        public static let measurement = "Medida"
        public static let height = "Altura (cm)"
        public static let bmi = "IMC"
        public static let newVisit = "Nova visita"
        public static let editVisit = "Editar visita"
        public static let deleteVisits = "Excluir visitas"
        public static let showChart = "Gráfico"
        public static let result = "Resultado da visita"
        public static let noVisitSelected = "Nenhuma visita selecionada"
        public static let save = "Salvar"
        public static let cancel = "Cancelar"
        public static let discard = "Descartar"
        public static let select = "Escolher"
        public static let new = "Novo"
        public static let edit = "Editar"
        public static let none = "Nenhum"
        public static let unknownDateOfBirth = "Nascimento desconhecido"
        public static let streetInfo = "Logradouro"
        public static let place = "Local"
        public static let zip = "CEP"
        public static let district = "Distrito"
        public static let province = "Província"
        public static let state = "Estado"
        public static let country = "País"
        public static let phoneNumber = "Telefone"
        public static let email = "E-mail"
        public static let tooManyResults = "(Resultados demais; refine a busca)"
        public static let noResults = "(Nenhum resultado)"
        public static let emptyList = "Nenhuma criança"
        public static let noChildOpen = "Escolha uma criança na lista ou crie uma nova."
        public static let unsavedTitle = "Salvar as alterações desta criança?"
        public static let unsavedMessage = "Há alterações na ficha ou nas visitas que ainda não foram gravadas."
        public static let deleteChildrenTitle = "Excluir as crianças marcadas?"
        public static let deleteChildrenMessage = "As crianças e todas as suas visitas serão apagadas. Não dá para desfazer."
        public static let deleteVisitsTitle = "Excluir as visitas selecionadas?"
        public static let deleteVisitsMessage = "As visitas saem da ficha e são apagadas do banco ao salvar a criança."
        public static let sexRequired = "Informe o sexo da criança antes de salvar."
        public static let duplicateDate = "Já existe uma visita nesta data."
        public static let invalidMeasurement = "Corrija os campos marcados antes de salvar."
        public static let saveFailed = "Não foi possível salvar."
        public static let searchTitle = "Buscar crianças"
        public static let idFrom = "ID de"
        public static let idTo = "até"
        public static let birthFrom = "Nascimento de"
        public static let birthTo = "até"
        public static let any = "Qualquer"
        public static let wildcardHint = "Use * para qualquer sequência e ? para um caractere."
        public static let checkedCount = "marcadas"
    }

    static var individualAssessmentStrings: [String] {
        let e = IndividualAssessment.self
        return [
            e.yes, e.no, e.invalidWithRangePrefix, e.children, e.archive, e.searchResults, e.newChild, e.search,
            e.clearSearch, e.archiveAction, e.restore, e.delete, e.backToList, e.child, e.displayID, e.firstName,
            e.lastName, e.dateOfBirth, e.approximateDate, e.sex, e.notes, e.mother, e.father, e.address, e.followUp,
            e.followUpDate, e.followUpInterval, e.followUpRefTo, e.visits, e.visitDate, e.weight, e.lengthOrHeight,
            e.oedema, e.recumbent, e.standing, e.measurement, e.height, e.bmi, e.newVisit, e.editVisit, e.deleteVisits,
            e.showChart, e.result, e.noVisitSelected, e.save, e.cancel, e.discard, e.select, e.new, e.edit, e.none,
            e.unknownDateOfBirth, e.streetInfo, e.place, e.zip, e.district, e.province, e.state, e.country,
            e.phoneNumber, e.email, e.tooManyResults, e.noResults, e.emptyList, e.noChildOpen, e.unsavedTitle,
            e.unsavedMessage, e.deleteChildrenTitle, e.deleteChildrenMessage, e.deleteVisitsTitle,
            e.deleteVisitsMessage, e.sexRequired, e.duplicateDate, e.invalidMeasurement, e.saveFailed, e.searchTitle,
            e.idFrom, e.idTo, e.birthFrom, e.birthTo, e.any, e.wildcardHint, e.checkedCount,
        ]
    }
}
