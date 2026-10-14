import AnthroFeatures
import Foundation
import Testing

/// Cenários do gráfico de crescimento (capability growth-charts).
@MainActor
@Suite("growth-charts: GrowthChartModel")
struct GrowthChartModelTests {
    let tables: GrowthReferenceTables

    init() throws {
        tables = try GrowthReferenceTables.bundled()
    }

    private func chart(_ results: [AnthropometricResult], index: Int = 0, _ indicator: Indicator,
                       mode: ChartDisplayMode = .zScore) -> GrowthChartModel {
        GrowthChartModel(results: results, currentIndex: index, indicator: indicator, tables: tables, mode: mode)
    }

    /// Menina de 6 anos com z definido nos três indicadores.
    private func girl(days: Int = 2192, wfa: String = "0.50") -> AnthropometricResult {
        fixtureResult(days: days, sex: .girl, wfa: score(wfa, "69.1"), lhfa: score("0.10", "54.0"), bmi: score("0.20", "57.9"))
    }

    private func boy(days: Int = 2192) -> AnthropometricResult {
        fixtureResult(days: days, sex: .boy, wfa: score("0.50", "69.1"), lhfa: score("0.10", "54.0"), bmi: score("0.20", "57.9"))
    }

    private func series(_ label: String, in model: GrowthChartModel) throws -> ChartSeries {
        try #require(model.series.first { $0.label == label })
    }

    // MARK: Curvas de desvio-padrão

    // Scenario: Peso para idade sem linhas de 1 DP
    @Test func pesoParaIdadeSemLinhasDe1DP() {
        let model = chart([girl()], .weightForAge)
        #expect(model.series.map(\.label) == ["-3 DP", "-2 DP", "Mediana", "+2 DP", "+3 DP"])
        #expect(model.series.map(\.style) == [.sd3, .sd2, .median, .sd2, .sd3])
    }

    // Scenario: IMC para idade com linhas de 1 DP
    @Test func imcParaIdadeComLinhasDe1DP() throws {
        let model = chart([boy()], .bmiForAge)
        #expect(model.series.count == 7)
        #expect(try series("-1 DP", in: model).style == .sd1)
        #expect(try series("+1 DP", in: model).style == .sd1)
    }

    // MARK: Curvas de percentis

    // Scenario: Percentis de estatura para idade
    @Test func percentisDeEstaturaParaIdade() {
        let model = chart([boy()], .lengthOrHeightForAge, mode: .percentile)
        #expect(model.series.map(\.label) == ["3º", "15º", "50º", "85º", "97º"])
        #expect(model.series.map(\.style) == [.sd2, .sd1, .median, .sd1, .sd2])
    }

    // Scenario: Percentil 50 sobre a mediana
    @Test func percentil50SobreAMediana() throws {
        let percentile = try series("50º", in: chart([girl()], .bmiForAge, mode: .percentile))
        let median = try series("Mediana", in: chart([girl()], .bmiForAge, mode: .zScore))
        #expect(!percentile.points.isEmpty)
        #expect(percentile.points.map(\.y) == median.points.map(\.y))
    }

    // MARK: Marca de transição entre comprimento e estatura

    // Scenario: Marca no gráfico de IMC
    @Test func marcaDeTransicaoNoGraficoDeImc() throws {
        let model = chart([boy()], .bmiForAge)
        let marker = try #require(model.transitionMarker)
        let lowest = try #require(try series("-3 DP", in: model).points.first)
        #expect(marker.x == 24)
        #expect(marker.y == lowest.y)
        #expect(marker.leftLabel == "COMPRIMENTO")
        #expect(marker.leftX == 23.5)
        #expect(marker.rightLabel == "ESTATURA")
        #expect(marker.rightX == 24.5)
    }

    // Scenario: Peso para idade sem marca
    @Test func pesoParaIdadeSemMarcaDeTransicao() {
        let model = chart([girl()], .weightForAge)
        #expect(model.series.count == 5)
        #expect(model.transitionMarker == nil)
    }

    // MARK: Faixa dos eixos

    // Scenario: Faixa de peso para idade
    @Test func faixaDosEixosDePesoParaIdade() throws {
        let model = chart([girl()], .weightForAge)
        #expect(model.fullXDomain == 0...130)
        #expect(model.fullYDomain.lowerBound == 0)
        let top = try #require(try series("+3 DP", in: model).points.map(\.y).max())
        #expect(model.fullYDomain.upperBound == top)
    }

    // Scenario: Faixa de IMC para idade
    @Test func faixaDosEixosDeImcParaIdade() {
        let model = chart([girl()], .bmiForAge, mode: .percentile)
        #expect(model.fullXDomain == 0...248)
        #expect(model.fullYDomain == 8...38)
    }

    // MARK: Títulos do gráfico e dos eixos

    // Scenario: Títulos de estatura para idade
    @Test func titulosDosEixosDeEstaturaParaIdade() {
        let model = chart([girl()], .lengthOrHeightForAge)
        #expect(model.xAxisTitle == "Idade (meses)")
        #expect(model.yAxisTitle == "Comprimento/estatura (cm)")
    }

    // Scenario: Título do gráfico vazio
    @Test func tituloDoGraficoVazioSemDados() {
        let model = chart([fixtureResult(days: 2192)], .weightForAge)
        #expect(model.title == "(Sem dados)")
    }

    // MARK: Valor plotado de cada medida

    // Scenario: Ponto de IMC
    @Test func pontoDeImcUsaImcExatoDaMedidaAjustada() throws {
        let result = fixtureResult(days: 2192, weight: 20, lengthOrHeight: 110, adjusted: 110, bmi: score("0.50", "69.1"))
        let point = try #require(chart([result], .bmiForAge).points.first)
        #expect(point.x == 2192 / 30.4375)
        #expect(abs(point.y - 16.5289256198347) < 1e-12)
    }

    // Scenario: Resultado sem z omitido
    @Test func resultadoSemZOmitidoDeixaGraficoVazio() {
        let model = chart([fixtureResult(days: 2192, wfa: noScore)], .weightForAge)
        #expect(model.points.isEmpty)
        #expect(model.isEmpty == true)
    }

    // MARK: Limite de idade dos pontos

    // Scenario: Peso aos 109 meses fora do gráfico
    @Test func pesoAos109MesesForaDoGrafico() {
        let model = chart([girl(days: 3317), girl(days: 3318)], .weightForAge)
        model.setShowMultiplePoints(true)
        #expect(model.points.count == 1)
        #expect(model.points.first?.resultIndex == 0)
        #expect(model.hasOutOfRangePoints == true)
        #expect(model.xAxisTitle == "Idade (meses) (valor(es) fora do intervalo)")
    }

    // Scenario: Só pontos fora do intervalo
    @Test func soPontosForaDoIntervaloDeixamGraficoVazio() {
        let model = chart([girl(days: 3318)], .weightForAge)
        #expect(model.isEmpty == true)
        #expect(model.title == "(Sem dados)")
    }

    // MARK: Ponto atual e legenda

    // Scenario: Legenda no modo z-score
    @Test func legendaNoModoZScore() {
        let model = chart([girl(days: 2192, wfa: "-2.35")], .weightForAge)
        #expect(model.legendText == "Idade: 6a 0m (72m), z-score: -2,35")
    }

    // Scenario: Legenda no modo percentil sem percentil
    @Test func legendaNoModoPercentilSemPercentil() {
        let result = fixtureResult(days: 2192, bmi: score("3.50", nil))
        #expect(chart([result], .bmiForAge, mode: .percentile).legendText == "Idade: 6a 0m (72m), Percentil: N/D")
    }

    // Scenario: Legenda sem idade no nascimento
    @Test func legendaSemIdadeNoNascimento() {
        let result = fixtureResult(days: 0, weight: num("3.35"), lengthOrHeight: 50, wfa: score("0.00", "50.0"))
        #expect(chart([result], .weightForAge).legendText == "z-score: 0,00")
    }

    // MARK: Um ponto ou vários pontos

    // Scenario: Três visitas com vários pontos
    @Test func tresVisitasComVariosPontos() {
        let model = chart([girl(days: 2192), girl(days: 2557), girl(days: 2922)], index: 1, .weightForAge)
        model.setShowMultiplePoints(true)
        #expect(model.points.map(\.resultIndex) == [0, 1, 2])
        #expect(model.showsConnectingLine == true)
        #expect(model.points.filter { $0.guideStyle == .current }.map(\.resultIndex) == [1])
    }

    // Scenario: Ponto único entre três visitas
    @Test func pontoUnicoEntreTresVisitas() {
        let model = chart([girl(days: 2192), girl(days: 2557), girl(days: 2922)], index: 2, .weightForAge)
        #expect(model.points.map(\.resultIndex) == [2])
        #expect(model.showsConnectingLine == false)
    }

    // Scenario: Resultado único sem escolha
    @Test func resultadoUnicoSemEscolhaDeVariosPontos() {
        let model = chart([girl()], .weightForAge)
        #expect(model.points.count == 1)
        model.setShowMultiplePoints(true)
        #expect(model.canShowMultiplePoints == false)
        #expect(model.showMultiplePoints == false)
    }

    // MARK: Troca de indicador e de modo

    // Scenario: De peso para IMC
    @Test func trocaDePesoParaImcRecalculaSeriesEFaixa() {
        let model = chart([girl()], .weightForAge)
        model.setIndicator(.bmiForAge)
        #expect(model.series.count == 7)
        #expect(model.visibleYDomain == 8...38)
    }

    // Scenario: Troca de modo descarta o zoom
    @Test func trocaDeModoDescartaOZoom() {
        let model = chart([girl()], .weightForAge)
        model.zoom(x: 60...120, y: 10...30)
        #expect(model.visibleXDomain == 60...120)
        model.setMode(.percentile)
        #expect(model.visibleXDomain == model.fullXDomain)
        #expect(model.visibleYDomain == model.fullYDomain)
    }

    // MARK: Zoom por área, deslocamento e restauração

    // Scenario: Zoom e restauração
    @Test func zoomERestauracao() {
        let model = chart([girl()], .weightForAge)
        model.zoom(x: 60...120, y: 10...30)
        #expect(model.visibleXDomain == 60...120)
        #expect(model.visibleYDomain == 10...30)
        model.resetZoom()
        #expect(model.visibleXDomain == model.fullXDomain)
        #expect(model.visibleYDomain == model.fullYDomain)
    }

    // Scenario: Seleção degenerada ignorada
    @Test func selecaoDegeneradaIgnorada() {
        let model = chart([girl()], .weightForAge)
        #expect(model.fullXDomain == 0...130)
        let (x, y) = (model.visibleXDomain, model.visibleYDomain)
        model.zoom(x: 60...60, y: 10...30)
        #expect(model.visibleXDomain == x)
        #expect(model.visibleYDomain == y)
    }

    // Scenario: Deslocamento horizontal
    @Test func deslocamentoHorizontalDe12Meses() {
        let model = chart([girl()], .weightForAge)
        model.zoom(x: 60...120, y: 10...30)
        model.pan(byX: 12, byY: 0)
        #expect(model.visibleXDomain == 72...132)
        #expect(model.visibleYDomain == 10...30)
    }
}
