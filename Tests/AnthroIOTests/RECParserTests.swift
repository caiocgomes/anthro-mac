import AnthroIO
import Foundation
import Testing

/// Cenários da leitura de REC do Epi Info (change add-survey-import-export).
@Suite("survey-data-exchange: REC")
struct RECParserTests {
    // Scenario: REC com dois registros
    @Test func recComDoisRegistrosLeLargurasFixas() throws {
        let text = String(decoding: try ExchangeFixtures.fixture("survey.rec"), as: UTF8.self)
        let table = try RECParser.parse(text)
        #expect(table.columns == ["SEX", "WEIGHT", "HEIGHT"])
        #expect(table.rows == [["1", "16.50", "110.0"], ["0", "12.30", "95.4"]])
    }

    // Scenario: Registro em duas linhas físicas
    @Test func registroRecEmDuasLinhasFisicasEhJuntado() throws {
        let text = "2\nNOTES 6 1 6 1 0 0 80 0 0\nSEX 6 2 6 1 0 0 1 0 0\n" + String(repeating: "a", count: 78) + "~\nbb1\n"
        let table = try RECParser.parse(text)
        #expect(table.rows == [[String(repeating: "a", count: 78) + "bb", "1"]])
    }

    // Scenario: Descritor de campo incompleto
    @Test func descritorRecIncompletoFalha() {
        expectInvalidStructure { () throws(ImportFailure) in _ = try RECParser.parse("1\nSEX 6 1\n1\n") }
    }
}
