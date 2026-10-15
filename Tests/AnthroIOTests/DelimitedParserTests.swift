import AnthroIO
import Foundation
import Testing

/// Cenários da leitura de campos, cabeçalho e linhas do texto delimitado (change add-survey-import-export).
@Suite("survey-data-exchange: texto delimitado")
struct DelimitedParserTests {
    private func parse(_ text: String) throws(ImportFailure) -> ImportedTable {
        try DelimitedParser.parse(text, separator: ";")
    }

    // Scenario: Campo entre aspas com separador
    @Test func campoEntreAspasComSeparadorFicaInteiro() throws {
        #expect(try parse("Nome;Sex\r\n\"Silva; Ana\";2\r\n").rows == [["Silva; Ana", "2"]])
    }

    // Scenario: Espaço inicial e aspas duplicadas
    @Test func espacoInicialEAspasDuplicadasSaoTratados() throws {
        #expect(try parse("A;B\r\n 15;\"a\"\"b\"\r\n").rows == [["15", "a\"b"]])
    }

    // Scenario: Quebra de linha dentro de aspas
    @Test func quebraDeLinhaDentroDeAspasMantemUmRegistro() throws {
        #expect(try parse("Nome;Sex\n\"Ana\nMaria\";2\n").rows == [["Ana\nMaria", "2"]])
    }

    // Scenario: Nomes vazios e repetidos
    @Test func nomesVaziosERepetidosViramColumnN() throws {
        #expect(try parse("Sex;;Sex\r\n1;2;3\r\n").columns == ["Sex", "Column1", "Column2"])
    }

    // Scenario: Registro mais longo que o cabeçalho
    @Test func registroMaisLongoQueOCabecalhoCriaColuna() throws {
        let table = try parse("A;B;C\r\n1;2;3;4\r\n")
        #expect(table.columns == ["A", "B", "C", "Column1"])
        #expect(table.rows == [["1", "2", "3", "4"]])
    }

    // Scenario: Arquivo vazio
    @Test func arquivoVazioFalhaComFormatoInvalido() {
        expectInvalidStructure { () throws(ImportFailure) in _ = try parse("") }
    }

    // Scenario: Linha vazia no meio do arquivo
    @Test func linhaVaziaNoMeioDoArquivoEhIgnorada() throws {
        #expect(try parse("Sex;Weight\r\n1;16\r\n\r\n2;17\r\n").rows == [["1", "16"], ["2", "17"]])
    }

    // Scenario: Registro curto
    @Test func registroCurtoCompletaComTextoVazio() throws {
        #expect(try parse("Sex;Weight;Height\r\n1;16,5\r\n").rows == [["1", "16,5", ""]])
    }
}
