/// Todas as strings visíveis do app, em pt-BR (design D6).
public enum L10n {
    public static let appName = "AnthroPlus"
    /// Valor indefinido, equivalente a `Texts._Value_NA` do original.
    public static let notAvailable = "N/D"

    public enum Section {
        public static let calculator = "Calculadora antropométrica"
        public static let individualAssessment = "Avaliação individual"
        public static let nutritionalSurvey = "Inquérito nutricional"
        public static let emptyStateMessage = "Este módulo ainda está em construção."
    }

    public enum Menu {
        public static let modules = "Módulos"
        public static let about = "Sobre o AnthroPlus"
        public static let exportDatabase = "Exportar cópia do banco de dados…"
        public static let sheetOpenTitle = "Há uma janela de edição aberta"
        public static let sheetOpenMessage = "Confirme ou cancele a edição antes de sair do AnthroPlus."
    }

    public enum Store {
        public static let corruptedTitle = "O banco de dados está danificado"
        public static let corruptedMessage = "O arquivo de dados não pôde ser lido. O AnthroPlus guarda uma cópia de segurança a cada abertura; restaure a mais recente para continuar."
        public static let restoreLatestBackup = "Restaurar último backup"
        public static let failedTitle = "Não foi possível abrir o banco de dados"
        public static let noBackupFound = "Nenhum backup foi encontrado."
        public static let exportFailed = "Não foi possível exportar a cópia do banco de dados."
        public static let exportDone = "Cópia do banco de dados exportada."
        public static let defaultExportName = "AnthroPlus-copia.sqlite"
    }

    public enum About {
        public static let title = "Sobre o AnthroPlus"
        public static let versionLabel = "Versão"
        public static let attribution = "Reconstrução para macOS do WHO AnthroPlus 1.0.4, software da Organização Mundial da Saúde (OMS) para avaliar o crescimento de crianças e adolescentes."
        public static let references = "Referências: Padrões de Crescimento Infantil da OMS 2006 (0 a 5 anos) e Referência de Crescimento da OMS 2007 (5 a 19 anos)."
        public static let disclaimer = "Este aplicativo não é distribuído pela OMS."
        public static let developmentVersion = "desenvolvimento"
    }

    public enum SelfTest {
        public static let ok = "Autoteste concluído: recursos encontrados."
        public static let missingResources = "Autoteste falhou: diretório de recursos 'who' do AnthroCore não encontrado."
        public static let missingTables = "Autoteste falhou: tabelas da OMS não carregaram:"
        public static let wrongRowCount = "Autoteste falhou: tabelas da OMS com número de linhas diferente de 1857:"
    }

    /// Lista todas as strings do catálogo, para o teste de completude.
    public static var allStrings: [String] {
        [
            appName, notAvailable,
            Section.calculator, Section.individualAssessment, Section.nutritionalSurvey, Section.emptyStateMessage,
            Menu.modules, Menu.about, Menu.exportDatabase, Menu.sheetOpenTitle, Menu.sheetOpenMessage,
            Store.corruptedTitle, Store.corruptedMessage, Store.restoreLatestBackup, Store.failedTitle,
            Store.noBackupFound, Store.exportFailed, Store.exportDone, Store.defaultExportName,
            About.title, About.versionLabel, About.attribution, About.references, About.disclaimer,
            About.developmentVersion,
            SelfTest.ok, SelfTest.missingResources, SelfTest.missingTables, SelfTest.wrongRowCount,
        ] + anthroStrings + individualAssessmentStrings + surveyStrings + additionalDataStrings + exchangeStrings + surveyExchangeStrings + surveyAnalysisStrings
    }
}
