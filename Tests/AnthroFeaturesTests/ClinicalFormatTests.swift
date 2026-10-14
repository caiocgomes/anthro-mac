import AnthroFeatures
import Foundation
import Testing

/// Testes de cenário de números no padrão brasileiro (capability app-shell).
@Suite("app-shell: ClinicalFormat")
struct ClinicalFormatTests {
    private func dec(_ text: String) -> Decimal {
        Decimal(string: text, locale: Locale(identifier: "en_US_POSIX"))!
    }

    // Scenario: Formatação com vírgula
    @Test func formatacaoComVirgulaDecimal() {
        #expect(ClinicalFormat.string(dec("16.5"), places: 1) == "16,5")
        #expect(ClinicalFormat.string(dec("-2.35"), places: 2) == "-2,35")
        #expect(ClinicalFormat.string(0, places: 2) == "0,00")
    }

    // Scenario: Valor indefinido
    @Test func valorIndefinidoViraND() {
        #expect(ClinicalFormat.string(nil, places: 2) == "N/D")
    }

    // Scenario: Leitura de vírgula e ponto
    @Test func leituraAceitaVirgulaEPonto() {
        #expect(ClinicalFormat.parseDecimal("16,5") == dec("16.5"))
        #expect(ClinicalFormat.parseDecimal("16.5") == dec("16.5"))
        #expect(ClinicalFormat.parseDecimal(" 20 ") == dec("20"))
    }

    // Scenario: Texto inválido
    @Test func textoInvalidoNaoViraNumero() {
        #expect(ClinicalFormat.parseDecimal("1,2,3") == nil)
        #expect(ClinicalFormat.parseDecimal("1.2.3") == nil)
        #expect(ClinicalFormat.parseDecimal("abc") == nil)
        #expect(ClinicalFormat.parseDecimal("") == nil)
    }
}
