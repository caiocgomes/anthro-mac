import AnthroCore
import AnthroIO
import Foundation
import Testing

/// Cenários do relatório TXT da criança (change add-individual-import-export).
@Suite("individual-data-exchange: relatório da criança")
struct ChildReportTests {
    /// Linhas com 12 campos separados por tabulação: o cabeçalho de visitas e as visitas.
    private func visitTable(_ text: String) -> [[String]] {
        text.components(separatedBy: "\r\n").map { $0.components(separatedBy: "\t") }.filter { $0.count == 12 }
    }

    // Scenario: Relatório com duas visitas
    @Test func relatorioComDuasVisitasNumeraLinhasEFormataCampos() {
        let child = ExchangeFixtures.ana(visits: [ExchangeFixtures.visit("2021-04-01", weight: "18.4", height: "110"),
                                                  ExchangeFixtures.visit("2021-10-01")])
        let table = visitTable(ChildReport.text(for: child))
        #expect(table.count == 3)
        guard table.count == 3 else { return }
        #expect(table[1].first == "1")
        #expect(table[2].first == "2")
        #expect(table[1][1] == "01/04/2021")
        #expect(table[1][2] == "AnthroPlus")
        #expect(table[1][3] == "18,4")
    }

    // Scenario: Idade formatada em anos e meses
    @Test func idadeFormatadaEmAnosEMesesTruncaMeses() {
        let child = ExchangeFixtures.ana(visits: [ExchangeFixtures.visit(daysAfterBirth: 1843, weight: "18", height: "110")])
        let line = visitTable(ChildReport.text(for: child)).dropFirst().first
        #expect(line?[7] == "5a 0m")
        #expect(line?[8] == "60,5")
    }

    // Scenario: Z-score indefinido no relatório
    @Test func zScoreIndefinidoNoRelatorioDeixaCampoVazio() {
        let results = ExchangeResults(weightForAgeZ: nil, lengthOrHeightForAgeZ: d("0.12"), bmiForAgeZ: nil, bmi: nil)
        let child = ExchangeFixtures.ana(visits: [ExchangeFixtures.visit(daysAfterBirth: 1843, weight: "18", height: "110",
                                                                         oedema: true, results: results)])
        let line = visitTable(ChildReport.text(for: child)).dropFirst().first
        #expect(line?.count == 12)
        #expect(line?[4] == "s")
        #expect(line?[9] == "")
        #expect(line?[10] == "0,12")
        #expect(line?[11] == "")
    }

    // Scenario: Bytes iniciais e quebras de linha
    @Test func bytesIniciaisEQuebrasDeLinhaDoRelatorioSaoUtf16BomECrlf() {
        let data = ChildReport.data(for: ExchangeFixtures.ana(visits: [ExchangeFixtures.visit("2021-04-01", weight: "18")]))
        #expect(Array(data.prefix(2)) == [0xFF, 0xFE])
        let text = String(data: data.dropFirst(2), encoding: .utf16LittleEndian) ?? ""
        #expect(text.contains("\r\n"))
        #expect(!text.replacingOccurrences(of: "\r\n", with: "").contains("\n"))
        #expect(!text.replacingOccurrences(of: "\r\n", with: "").contains("\r"))
    }

    // Scenario: Nome sugerido sem sobrenome
    @Test func nomeSugeridoSemSobrenomeOmiteVirgula() {
        #expect(ChildReport.suggestedFileName(for: ExchangeFixtures.ana(lastName: "")) == "Ana.txt")
    }
}
