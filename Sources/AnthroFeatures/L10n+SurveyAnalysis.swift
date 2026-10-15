extension L10n {
    /// Aba de resultados, gráficos e relatórios do Inquérito nutricional (design D11).
    public enum SurveyAnalysis {
        public static let recordsRequired = "A análise requer que o inquérito contenha pelo menos 12 registros válidos."
        public static let noData = "(Sem dados)"
        public static let missingCluster = "Erro: a variável cluster está vazia."
        public static let fileError = "Não foi possível salvar no arquivo indicado. Verifique se o arquivo existente não está em uso."
        public static let clusterQuestion = "Deseja realizar a análise por cluster?"
        public static let normalCurve = "Padrões de crescimento da OMS (nascimento a 60 meses), referência OMS 2007 (61 meses a 19 anos)"
        public static let allChildren = "Todas as crianças"
        public static let female = "Feminino"
        public static let male = "Masculino"
        public static let zScore = "z-score"
        public static let children = "Crianças"
        public static let meanZScore = "Média do z-score"
        public static let ageMonths = "Idade (meses)"
        public static let cluster = "Cluster"

        // Tela
        public static let tabRecords = "Registros"
        public static let tabResults = "Resultados"
        public static let indicator = "Indicador"
        public static let filter = "Filtro"
        public static let filterAllChildren = "Todas as crianças"
        public static let filterBySex = "Por sexo"
        public static let filterByCluster = "Por cluster"
        public static let filterByAgeGroup = "Por faixa etária"
        public static let restore = "Restaurar"
        public static let copyGraph = "Copiar gráfico"
        public static let printGraph = "Imprimir gráfico"
        public static let standardReport = "Relatório padrão com IC (Excel)"
        public static let estimatesReport = "Estimativas sem IC (Excel)"
        public static let reports = "Relatórios"
        public static let reportTitle = "Relatório"
        public static let yes = "Sim"
        public static let no = "Não"
        public static let cancel = "Cancelar"
        public static let close = "Fechar"
        public static let reportFailedTitle = "Não foi possível gerar o relatório"
        public static let reportNeedsSave = "Salve o inquérito antes de gerar o relatório: a análise usa os registros gravados."
        public static let zoomHint = "Arraste sobre o gráfico para ampliar."
    }

    /// Strings desta extensão, somadas a `L10n.allStrings`.
    static var surveyAnalysisStrings: [String] {
        let s = SurveyAnalysis.self
        return [s.recordsRequired, s.noData, s.missingCluster, s.fileError, s.clusterQuestion, s.normalCurve, s.allChildren, s.female,
                s.male, s.zScore, s.children, s.meanZScore, s.ageMonths, s.cluster, s.tabRecords, s.tabResults, s.indicator, s.filter,
                s.filterAllChildren, s.filterBySex, s.filterByCluster, s.filterByAgeGroup, s.restore, s.copyGraph, s.printGraph,
                s.standardReport, s.estimatesReport, s.reports, s.reportTitle, s.yes, s.no, s.cancel, s.close, s.reportFailedTitle,
                s.reportNeedsSave, s.zoomHint]
    }
}
