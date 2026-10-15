import AnthroAnalysis
import AnthroCore
import AnthroIO
import Foundation
import Testing

/// Cenários do relatório de estimativas sem IC (change add-survey-analysis).
@Suite("survey-reports: relatório de estimativas")
struct EstimatesReportTests {
    private typealias R = ReportFixtures

    private func estimates(_ records: [AnalysisRecord]) throws -> SurveyReport {
        try SurveyReportWriter.estimatesReport(records: records, options: .default)
    }

    // Scenario: Abertura do relatório de estimativas
    @Test func aberturaDoRelatorioDeEstimativas() throws {
        let report = try estimates(R.tenChildren())
        try #require(report.lines.count >= 8)
        #expect(Array(report.lines.prefix(8)) == [
            "Relatório de crescimento e estado nutricional de crianças e adolescentes*", "", "País:", "Referência:",
            "Nível administrativo:", "Mês e ano do inquérito:", "", R.set1,
        ])
    }

    // Scenario: Estimativas sem notas de cluster
    @Test func estimativasSemNotasDeCluster() throws {
        let report = try estimates(R.fourClusters())
        let last = try #require(report.lines.last)
        #expect(!report.lines.contains { $0.hasPrefix("-) ") })
        #expect(last.hasPrefix("**) "))
    }

    // Scenario: Total e faixa de 5 a 9 anos
    @Test func totalEFaixaDe5A9Anos() throws {
        let lines = try #require(R.set(try estimates(R.tenChildren()), R.set1))
        #expect(lines.contains("Total (5-19)\t(61-228)\t10\t\t\t\t\t10\t30\t-0,21\t2,1\t10\t30\t30\t20\t10\t-0,21\t2,1\t"))
        #expect(lines.contains("Total (5-9)\t(61-119)\t10\t10\t30\t-0,21\t2,1\t10\t30\t-0,21\t2,1\t10\t30\t30\t20\t10\t-0,21\t2,1\t"))
    }

    // Scenario: Faixa sem crianças
    @Test func faixaSemCriancasNasEstimativas() throws {
        let lines = try #require(R.set(try estimates(R.tenChildren()), R.set1))
        #expect(lines.contains("Total (10-14)\t(120-179)\t0" + String(repeating: "\t", count: 16)))
    }

    // Scenario: Peso para idade sem dados acima de 108 meses
    @Test func pesoParaIdadeSemDadosAcimaDe108Meses() throws {
        let records = (0..<4).map { _ in R.record(age: 130, z: d("-2.5")) }
        let lines = try #require(R.set(try estimates(records), R.set1))
        let line = try #require(lines.first { $0.hasPrefix("10\t(120-131)") })
        let cells = line.split(separator: "\t", omittingEmptySubsequences: false).map(String.init)
        try #require(cells.count > 8)
        #expect(cells[2] == "4")
        #expect(Array(cells[3...6]) == ["", "", "", ""])
        #expect(cells[8] == "100")
    }

    // Scenario: Total dos quatro clusters
    @Test func totalDosQuatroClustersNasEstimativas() throws {
        let lines = try #require(R.set(try estimates(R.fourClusters()), R.set4))
        #expect(lines.contains { $0.hasPrefix("Total\t\t20\t0\t20\t") })
        for cluster in 1...4 {
            #expect(lines.contains { $0.hasPrefix("\(cluster)\t\t5\t") }, "cluster \(cluster)")
        }
    }

    // Scenario: Estimativas sem clusters
    @Test func estimativasSemClustersTemSoCabecalho() throws {
        let lines = try #require(R.set(try estimates(R.tenChildren()), R.set4))
        #expect(lines.filter { !$0.isEmpty }.count == 2)
        #expect(lines.first?.hasPrefix("Cluster\t\tN\t") == true)
    }
}
