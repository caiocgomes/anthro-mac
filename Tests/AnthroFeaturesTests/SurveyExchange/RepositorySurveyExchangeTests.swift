import AnthroCore
import AnthroFeatures
import AnthroIO
import AnthroStore
import Foundation
import Testing

/// Cenário da gravação da importação XML (change add-survey-import-export).
@MainActor
@Suite("survey-data-exchange: gravação da importação")
struct RepositorySurveyExchangeTests {
    // Scenario: Falha na gravação do segundo inquérito
    @Test func falhaNaGravacaoDoSegundoInqueritoDesfazTudo() throws {
        let db = try SurveyFixtures.makeDatabase()
        let exchange = RepositorySurveyExchange(database: db, surveys: SurveyRepository(database: db))
        let surveys = [ExchangeSurvey(survey: Survey(name: "Escola A"), records: [SurveyRecord(sex: .girl), SurveyRecord(sex: .boy)]),
                       ExchangeSurvey(survey: Survey(name: "Escola B"), records: [SurveyRecord(sex: .girl)])]
        try db.execute("""
            CREATE TRIGGER falha_no_segundo_inquerito BEFORE INSERT ON surveys
            WHEN (SELECT COUNT(*) FROM surveys) >= 1
            BEGIN SELECT RAISE(ABORT, 'falha simulada no segundo inquérito'); END
            """)
        #expect(throws: (any Error).self) { try exchange.insertAll(surveys) }
        #expect(try SurveyExchangeTestFiles.count(db, "surveys") == 0)
        #expect(try SurveyExchangeTestFiles.count(db, "records") == 0)
    }
}
