import AnthroAnalysis
import AnthroCore
import AnthroFeatures
import AnthroIO
import Foundation
import Testing

/// Cenários da aba de resultados e da exportação dos relatórios (change add-survey-analysis).
@MainActor
@Suite("survey-graphs e survey-reports: modelo da aba de resultados")
struct SurveyAnalysisModelTests {
    private typealias F = AnalysisModelFixtures

    private func model(_ records: [AnalysisRecord], name: String = "Escola A", indicator: Indicator = .bmiForAge,
                       filter: SurveyAnalysisModel.GraphFilter = .allChildren) -> SurveyAnalysisModel {
        let model = SurveyAnalysisModel(records: records, options: .default, surveyName: name, recordCount: records.count)
        model.indicator = indicator
        model.filter = filter
        model.refreshGraph()
        return model
    }

    private func series(_ graph: SurveyAnalysisModel.Graph) -> [DensitySeries] {
        if case .density(let series) = graph { return series }
        return []
    }

    // Scenario: Nome em branco e destino sem permissão
    @Test func nomeEmBrancoEDestinoSemPermissao() throws {
        #expect(SurveyReportWriter.defaultFileName(surveyName: "  ", kind: .estimates) == "Relatório_estimates.txt")
        let directory = try F.directory()
        try FileManager.default.setAttributes([.posixPermissions: 0o555], ofItemAtPath: directory.path)
        defer {
            try? FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: directory.path)
            try? FileManager.default.removeItem(at: directory)
        }
        let analysis = model(F.fourClusters(), name: "  ")
        analysis.exportReport(.estimates, to: directory.appendingPathComponent("relatorio.txt"), opener: RecordingReportOpener())
        #expect(analysis.errorMessage == "Não foi possível salvar no arquivo indicado. Verifique se o arquivo existente não está em uso.")
    }

    // Scenario: Correção pedida sem clusters
    @Test func correcaoPedidaSemClustersMostraErro() throws {
        let directory = try F.directory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("relatorio.txt")
        let analysis = model([F.record(age: 110, z: 0), F.record(age: 110, z: 0)])
        analysis.exportReport(.standard(improvedClusterAnalysis: true), to: url, opener: RecordingReportOpener())
        #expect(analysis.errorMessage == "Erro: a variável cluster está vazia.")
        #expect(!FileManager.default.fileExists(atPath: url.path))
    }

    // Scenario: Correção pedida com clusters
    @Test func correcaoPedidaComClustersGravaArquivo() throws {
        let directory = try F.directory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("relatorio.txt")
        let analysis = model(F.fourClusters())
        analysis.exportReport(.standard(improvedClusterAnalysis: true), to: url, opener: RecordingReportOpener())
        #expect(analysis.errorMessage == nil)
        #expect(FileManager.default.fileExists(atPath: url.path))
    }

    // Scenario: Criança abaixo de 61 meses
    @Test func criancaAbaixoDe61MesesNaDensidade() {
        let records = [F.record(age: 50, z: num("0.4"), sex: .girl)] + F.twelveZ.prefix(11).map { F.record(z: $0) }
        let all = model(records)
        #expect(series(all.graph).map(\.label) == [F.normalLabel, "Todas as crianças (n=12)"])
        let bySex = model(records, filter: .bySex)
        #expect(series(bySex.graph).map(\.label) == [F.normalLabel, "Masculino (n=11)"])
    }

    // Scenario: Rótulo de todas as crianças
    @Test func rotuloDeTodasAsCriancas() {
        let factors = Array(repeating: num("4"), count: 10) + [num("5"), num("5")]
        let records = zip(F.twelveZ, factors).map { F.record(z: $0, factor: $1) }
        let graph = series(model(records).graph)
        #expect(graph.map(\.label) == [F.normalLabel, "Todas as crianças (n=50)"])
        #expect(graph.map(\.color) == [.green, .red])
    }

    // Scenario: Meninos com z iguais
    @Test func meninosComZIguaisEsvaziamOGrafico() {
        let records = F.twelveZ.map { F.record(z: $0, sex: .girl) } + (0..<12).map { _ in F.record(z: num("0.5"), sex: .boy) }
        #expect(model(records, filter: .bySex).graph == .empty(title: "(Sem dados)"))
    }

    // Scenario: Nenhum cluster
    @Test func nenhumClusterDaGraficoVazio() {
        let records = F.twelveZ.map { F.record(z: $0) }
        #expect(MeanSDBars.byCluster(records, indicator: .bmiForAge, options: .default).isEmpty)
        #expect(model(records, filter: .byCluster).graph == .empty(title: "(Sem dados)"))
    }

    // Scenario: Onze registros
    @Test func onzeRegistrosBloqueiamResultados() {
        let analysis = model(F.withoutZ(11))
        #expect(!analysis.canShowGraphs)
        #expect(analysis.unavailableMessage == "A análise requer que o inquérito contenha pelo menos 12 registros válidos.")
    }

    // Scenario: Doze registros sem z
    @Test func dozeRegistrosSemZLiberamResultados() {
        let analysis = model(F.withoutZ(12))
        #expect(analysis.canShowGraphs)
        #expect(analysis.unavailableMessage == nil)
        #expect(analysis.graph == .empty(title: "(Sem dados)"))
    }

    // Scenario: Zoom e restauração
    @Test func zoomERestauracao() {
        let analysis = model(F.twelveZ.map { F.record(z: $0) })
        analysis.zoom(x: -2...2, y: 0...0.2)
        #expect(analysis.xDomain == -2...2)
        #expect(analysis.yDomain == 0...0.2)
        analysis.resetZoom()
        #expect(analysis.xDomain == -5...5)
        #expect(analysis.yDomain == 0...0.45)
    }

    // Scenario: Retângulo degenerado
    @Test func retanguloDegeneradoEIgnorado() {
        let analysis = model(F.twelveZ.map { F.record(z: $0) })
        analysis.zoom(x: 1...1, y: 0...0.2)
        #expect(analysis.xDomain == -5...5)
        #expect(analysis.yDomain == 0...0.45)
    }

    // Scenario: Gráfico vazio não é copiado
    @Test func graficoVazioNaoECopiado() {
        let analysis = model(F.withoutZ(12))
        #expect(analysis.graph == .empty(title: "(Sem dados)"))
        #expect(!analysis.canCopyGraph)
        analysis.update(records: F.twelveZ.map { F.record(z: $0) }, recordCount: 12)
        analysis.refreshGraph()
        #expect(analysis.canCopyGraph)
    }
}
