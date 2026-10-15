import AnthroAnalysis
import AnthroCore
import Foundation
import Testing

/// Cenários dos IC 95% simples e corrigido por cluster e da tabela t (change add-survey-analysis).
@Suite("survey-analysis: intervalos de confiança")
struct ConfidenceIntervalTests {
    private typealias F = AnalysisFixtures

    // Scenario: IC das prevalências dos dez registros
    @Test func icDasPrevalenciasDosDezRegistros() throws {
        let result = try F.compute(F.tenRecords(), .bmiForAge)
        #expect(result.interval(.belowMinus2) == .interval(low: 0, high: d("63.4")))
        #expect(result.interval(.belowMinus3) == .interval(low: 0, high: d("33.6")))
    }

    // Scenario: Limite superior cortado em 100
    @Test func limiteSuperiorCortadoEm100() {
        #expect(ConfidenceIntervals.simple(portion: 2, total: 4) == .interval(low: 0, high: 100))
    }

    // Scenario: Total zero
    @Test func icSimplesComTotalZero() {
        #expect(ConfidenceIntervals.simple(portion: 0, total: 0) == .unavailable)
    }

    // Scenario: Quatro clusters de cinco crianças
    @Test func quatroClustersDeCincoCriancas() throws {
        let result = try F.compute(F.fourClusters(), .lengthOrHeightForAge, improved: true)
        #expect(result.prevalence(.belowMinus2) == 20)
        #expect(result.interval(.belowMinus2) == .interval(low: d("4.7"), high: d("55.9")))
    }

    // Scenario: Proporção nula
    @Test func proporcaoNulaNaoTemIcPorCluster() throws {
        let result = try F.compute(F.fourClusters(), .lengthOrHeightForAge, improved: true)
        #expect(result.interval(.belowMinus3) == .unavailable)
    }

    // Scenario: Um único cluster
    @Test func umUnicoClusterNaoTemIc() throws {
        let records = (0..<5).map { F.record(z: $0 < 2 ? d("-2.5") : 0, cluster: 1) }
        let result = try F.compute(records, .lengthOrHeightForAge, improved: true)
        #expect(result.prevalence(.belowMinus2) == 40)
        #expect(result.interval(.belowMinus2) == .singleCluster)
    }

    // Scenario: Valores da tabela
    @Test func valoresDaTabelaT() {
        #expect(ConfidenceIntervals.tStudent(degreesOfFreedom: 3) == d("3.18244630528371"))
        #expect(ConfidenceIntervals.tStudent(degreesOfFreedom: 200) == d("1.97189622363389"))
    }

    // Scenario: Fora da tabela
    @Test func valoresForaDaTabelaT() {
        #expect(ConfidenceIntervals.tStudent(degreesOfFreedom: 201) == d("1.96"))
        #expect(ConfidenceIntervals.tStudent(degreesOfFreedom: 0) == nil)
    }

    // Scenario: Cluster só com registro implausível
    @Test func clusterSoComRegistroImplausivelContaEmC() throws {
        let records = F.fourClusters() + [F.record(z: 0, cluster: 5, flagged: [.lengthOrHeightForAge])]
        let result = try F.compute(records, .lengthOrHeightForAge, improved: true)
        #expect(result.count == 20)
        #expect(result.interval(.belowMinus2) == .interval(low: 6, high: d("49.6")))
    }

    // Scenario: Registro sem cluster na correção
    @Test func registroSemClusterNaCorrecaoEIgnorado() throws {
        let records = F.fourClusters() + [F.record(z: d("-2.5"))]
        let result = try F.compute(records, .lengthOrHeightForAge, improved: true)
        #expect(result.count == 20)
        #expect(result.interval(.belowMinus2) == .interval(low: d("4.7"), high: d("55.9")))
    }
}
