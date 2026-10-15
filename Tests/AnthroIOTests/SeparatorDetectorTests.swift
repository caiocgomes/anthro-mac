import AnthroIO
import Foundation
import Testing

/// Cenários do separador do texto delimitado (change add-survey-import-export).
@Suite("survey-data-exchange: separador")
struct SeparatorDetectorTests {
    // Scenario: CSV com vírgula
    @Test func csvComVirgulaUsaVirgulaComoSeparador() {
        #expect(SeparatorDetector.detect(firstLine: "Sex,Weight,Height", fallback: ";") == ",")
    }

    // Scenario: Primeira linha sem separador
    @Test func primeiraLinhaSemSeparadorUsaPadraoDaExtensao() throws {
        #expect(SeparatorDetector.detect(firstLine: "Sex", fallback: ";") == ";")
        let table = try ExternalTableReader.read(Data("Sex\r\n1\r\n".utf8), kind: .delimited(fallbackSeparator: ";"))
        #expect(table.columns == ["Sex"])
    }

    // Scenario: Separador entre aspas não conta
    @Test func separadorEntreAspasNaoConta() {
        #expect(SeparatorDetector.detect(firstLine: "\"Nome, completo\";Sex", fallback: ";") == ";")
    }
}
