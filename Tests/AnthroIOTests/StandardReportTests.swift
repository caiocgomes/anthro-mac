import AnthroAnalysis
import AnthroCore
import AnthroIO
import Foundation
import Testing

/// Cenários do relatório padrão com IC (change add-survey-analysis).
@Suite("survey-reports: relatório padrão")
struct StandardReportTests {
    private typealias R = ReportFixtures

    private func standard(_ records: [AnalysisRecord], improved: Bool = false) throws -> SurveyReport {
        try SurveyReportWriter.standardReport(records: records, options: .default, improvedClusterAnalysis: improved)
    }

    private func ofAge(_ months: Decimal, count: Int, weightZ: Decimal) -> [AnalysisRecord] {
        (0..<count).map { _ in R.record(age: months, z: weightZ, indicators: [.weightForAge]) }
    }

    // Scenario: Abertura e conjuntos do relatório sem correção
    @Test func aberturaEConjuntosDoRelatorioSemCorrecao() throws {
        let report = try standard(R.tenChildren())
        try #require(report.lines.count > 3)
        #expect(Array(report.lines.prefix(4)) == ["Análise padrão do inquérito nutricional",
                                                  "Tabelas detalhadas com intervalos de confiança de 95%*", "", R.set1])
        #expect(report.lines.filter { [R.set2, R.set3, R.set4].contains($0) } == [R.set2, R.set3, R.set4])
    }

    // Scenario: Relatório com correção por cluster
    @Test func relatorioComCorrecaoPorCluster() throws {
        let report = try standard(R.fourClusters(), improved: true)
        try #require(report.lines.count >= 2)
        #expect(!report.lines.contains(R.set4))
        #expect(report.lines[report.lines.count - 2].hasPrefix("-) "))
        #expect(report.lines[report.lines.count - 1].hasPrefix(".) "))
    }

    // Scenario: Cabeçalho de IMC para idade
    @Test func cabecalhoDeImcParaIdade() throws {
        let lines = try #require(R.set(try standard(R.tenChildren()), R.set1))
        let index = try #require(lines.firstIndex(of: R.bmiHeader))
        try #require(lines.count > index + 1)
        #expect(lines[index + 1] == "Anos\tMeses\t\t% < -3DP\t(IC 95%)\t% < -2DP\t(IC 95%)\t% > +1DP\t(IC 95%)\t% > +2DP\t(IC 95%)\t% > +3DP\t(IC 95%)\tMédia\tDP")
    }

    // Scenario: Cabeçalho de estatura no conjunto por cluster
    @Test func cabecalhoDeEstaturaNoConjuntoPorCluster() throws {
        let lines = try #require(R.set(try standard(R.fourClusters()), R.set4))
        let index = try #require(lines.firstIndex(of: "Cluster\t\tN\tComprimento/estatura para idade (%)"))
        try #require(lines.count > index + 1)
        #expect(lines[index + 1] == "\t\t\t% < -3DP\t(IC 95%)\t% < -2DP\t(IC 95%)\tMédia\tDP")
    }

    // Scenario: Total de IMC das dez crianças
    @Test func totalDeImcDasDezCriancas() throws {
        let report = try standard(R.tenChildren())
        #expect(R.table(report, set: R.set1, header: R.bmiHeader)?.first
            == "Total (5-19)\t(61-228)\t10\t10\t(0%, 33,6%)\t30\t(0%, 63,4%)\t30\t(0%, 63,4%)\t20\t(0%, 49,8%)\t10\t(0%, 33,6%)\t-0,21\t2,1")
        #expect(R.table(report, set: R.set1, header: R.weightHeader)?.first == "Total (5-19)\t(61-228)\t\t\t\t\t\t\t")
    }

    // Scenario: Total sem crianças de 61 a 228 meses
    @Test func totalSemCriancasDe61A228Meses() throws {
        let report = try standard((0..<3).map { _ in R.record(age: 40, z: 0) })
        #expect(R.table(report, set: R.set1, header: R.heightHeader)?.first == "Total\t\t0")
    }

    // Scenario: Faixas fixas de estatura
    @Test func faixasFixasDeEstatura() throws {
        let rows = try #require(R.table(try standard(R.tenChildren()), set: R.set1, header: R.heightHeader))
        try #require(rows.count >= 4)
        #expect(Array(rows[1...3]) == ["Total (5-9)\t(61-119)\t10\t10\t(0%, 33,6%)\t30\t(0%, 63,4%)\t-0,21\t2,1",
                                       "Total (10-14)\t(120-179)\t", "Total (15-19)\t(180-228)\t"])
    }

    // Scenario: Peso para idade em faixa acima de 108 meses
    @Test func pesoParaIdadeEmFaixaAcimaDe108Meses() throws {
        let report = try standard(ofAge(130, count: 4, weightZ: d("-2.5")))
        #expect(R.table(report, set: R.set1, header: R.weightHeader)?.contains("Total (10-14)\t(120-179)\t") == true)
    }

    // Scenario: Faixa de 96 meses e primeira e última faixas
    @Test func faixaDe96MesesEPrimeiraEUltimaFaixas() throws {
        let rows = try #require(R.table(try standard(R.tenChildren()), set: R.set1, header: R.bmiHeader))
        #expect(rows.contains("8\t(96-107)\t10\t10\t(0%, 33,6%)\t30\t(0%, 63,4%)\t30\t(0%, 63,4%)\t20\t(0%, 49,8%)\t10\t(0%, 33,6%)\t-0,21\t2,1"))
        #expect(rows.contains("0\t(0-5)\t"))
        #expect(rows.contains("19\t(228-228)\t"))
    }

    // Scenario: Peso para idade na faixa de 120 meses
    @Test func pesoParaIdadeNaFaixaDe120Meses() throws {
        let report = try standard(ofAge(125, count: 4, weightZ: d("-2.5")))
        #expect(R.table(report, set: R.set1, header: R.weightHeader)?.contains("10\t(120-131)\t") == true)
    }

    // Scenario: Estatura nos quatro clusters
    @Test func estaturaNosQuatroClusters() throws {
        let report = try standard(R.fourClusters())
        #expect(R.table(report, set: R.set4, header: "Cluster\t\tN\tComprimento/estatura para idade (%)") == [
            "Total\t\t20\t0\t(0%, 2,5%)\t20\t(0%, 40%)\t-0,5\t1,03",
            "1\t\t5\t0\t(0%, 10%)\t20\t(0%, 65,1%)\t-0,5\t1,12",
            "2\t\t5\t0\t(0%, 10%)\t40\t(0%, 92,9%)\t-1\t1,37",
            "3\t\t5\t0\t(0%, 10%)\t0\t(0%, 10%)\t0\t0",
            "4\t\t5\t0\t(0%, 10%)\t20\t(0%, 65,1%)\t-0,5\t1,12",
        ])
    }

    // Scenario: Inquérito sem cluster
    @Test func inqueritoSemClusterTemSoCabecalho() throws {
        let lines = try #require(R.set(try standard(R.tenChildren()), R.set4))
        let index = try #require(lines.firstIndex(of: "Cluster\t\tN\tComprimento/estatura para idade (%)"))
        try #require(lines.count > index + 2)
        #expect(lines[index + 2] == "")
    }

    // Scenario: Contagem de crianças com edema
    @Test func contagemDeCriancasComEdema() throws {
        let records = R.tenChildren() + [R.record(z: nil, oedema: true), R.record(age: 40, z: nil, oedema: true)]
        let report = try standard(records)
        #expect(report.lines.contains("Número de crianças com edema: 2 (este número pode ser usado para calcular a prevalência de desnutrição edematosa na amostra)"))
        #expect(report.lines.last?.hasPrefix("**) ") == true)
    }

    // Scenario: Notas da correção por cluster
    @Test func notasDaCorrecaoPorCluster() throws {
        let report = try standard(R.fourClusters(), improved: true)
        try #require(report.lines.count >= 2)
        #expect(report.lines[report.lines.count - 2].hasPrefix("-) Não há IC 95% para prevalências (p)"))
        #expect(report.lines[report.lines.count - 1] == ".) Nº de clusters = 1; o IC não pode ser calculado.")
    }

    // Scenario: Linhas e células da tabela
    @Test func linhasECelulasDaTabela() throws {
        let report = try standard(R.tenChildren())
        #expect(report.table.count == report.lines.count)
        try #require(!report.lines.isEmpty)
        let start = try #require(report.lines.firstIndex(of: R.set1))
        let header = try #require(report.lines[start...].firstIndex(of: R.bmiHeader))
        try #require(report.table.count > header + 2)
        let row = report.table[header + 2]
        #expect(row.count == 15)
        #expect(row.first == "Total (5-19)")
        #expect(row.last == "2,1")
    }

    // Scenario: Linha vazia na tabela
    @Test func linhaVaziaNaTabelaTemUmaCelula() throws {
        let report = try standard(R.tenChildren())
        try #require(report.table.count > 2)
        #expect(report.table[2] == [""])
    }
}
