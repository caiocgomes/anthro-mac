import AnthroAnalysis
import AnthroCore
import Foundation
import Testing

/// Cenários de prevalências, média, DP, edema, plausibilidade, faixas e clusters (change add-survey-analysis).
@Suite("survey-analysis: prevalências")
struct PrevalenceCalculatorTests {
    private typealias F = AnalysisFixtures

    private func prevalences(_ result: PrevalenceResult) -> [Decimal?] {
        Threshold.allCases.map { result.prevalence($0) }
    }

    // Scenario: Dez registros de IMC com z conhecidos
    @Test func dezRegistrosDeImcComZConhecidos() throws {
        let result = try F.compute(F.tenRecords(), .bmiForAge)
        #expect(result.count == 10)
        #expect(prevalences(result) == [10, 30, 30, 20, 10])
    }

    // Scenario: Nenhum registro com z válido
    @Test func nenhumRegistroComZValido() throws {
        let result = try F.compute((0..<3).map { _ in F.record(z: nil) }, .bmiForAge)
        #expect(result.count == 0)
        #expect(prevalences(result) == [nil, nil, nil, nil, nil])
        #expect(result.mean == nil)
        #expect(result.standardDeviation == nil)
        #expect(result.interval(.belowMinus2) == .unavailable)
    }

    // Scenario: Estatura para idade dos dez registros
    @Test func estaturaParaIdadeDosDezRegistros() throws {
        let result = try F.compute(F.tenRecords(), .lengthOrHeightForAge)
        #expect(result.prevalence(.belowMinus3) == 10)
        #expect(result.prevalence(.belowMinus2) == 30)
        #expect(result.prevalence(.abovePlus1) == nil)
        #expect(result.interval(.abovePlus1) == .notComputed)
    }

    // Scenario: Classificação dos indicadores
    @Test func classificacaoDosIndicadoresSoNegativos() {
        #expect(PrevalenceCalculator.computeOnlyNegative(.weightForAge))
        #expect(PrevalenceCalculator.computeOnlyNegative(.lengthOrHeightForAge))
        #expect(!PrevalenceCalculator.computeOnlyNegative(.bmiForAge))
    }

    // Scenario: Registros com pesos diferentes
    @Test func registrosComPesosDiferentes() throws {
        let records = [F.record(z: d("-2.5"), factor: 2), F.record(z: 0), F.record(z: 1)]
        let result = try F.compute(records, .bmiForAge)
        #expect(result.count == 4)
        #expect(result.prevalence(.belowMinus2) == 50)
        #expect(result.mean == -1)
        #expect(ClinicalRounding.round(result.standardDeviation, places: 2) == d("1.78"))
    }

    // Scenario: Um único registro
    @Test func umUnicoRegistroTemDpZero() throws {
        let result = try F.compute([F.record(z: -1)], .bmiForAge)
        #expect(result.count == 1)
        #expect(result.mean == -1)
        #expect(result.standardDeviation == 0)
    }

    // Scenario: Fator negativo vira 1
    @Test func fatorNegativoViraUm() throws {
        let records = [F.record(z: d("-2.5"), factor: -3), F.record(z: 0), F.record(z: 1)]
        let result = try F.compute(records, .bmiForAge)
        #expect(result.count == 3)
        #expect(result.prevalence(.belowMinus2) == d("33.3"))
    }

    // Scenario: Fator zero não conta
    @Test func fatorZeroNaoConta() throws {
        let records = [F.record(z: d("-2.5"), factor: 0), F.record(z: 0), F.record(z: 1)]
        let result = try F.compute(records, .bmiForAge)
        #expect(result.count == 2)
        #expect(result.prevalence(.belowMinus2) == 0)
        #expect(result.mean == d("0.5"))
    }

    /// Nove registros com z (os dez sem o -3.5) e um com edema, cujo z de estatura é -2.5.
    private func withOedema() -> [AnalysisRecord] {
        F.tenZ.dropFirst().map { F.record(z: $0) }
            + [F.record(z: d("-2.5"), indicators: [.lengthOrHeightForAge], oedema: true)]
    }

    // Scenario: Um caso de edema em IMC
    @Test func umCasoDeEdemaEmImc() throws {
        let result = try F.compute(withOedema(), .bmiForAge)
        #expect(result.count == 9)
        #expect(result.oedemaCount == 1)
        #expect(result.prevalence(.belowMinus3) == 10)
        #expect(result.prevalence(.belowMinus2) == 30)
        #expect(ClinicalRounding.round(result.mean, places: 2) == d("0.16"))
        #expect(ClinicalRounding.round(result.standardDeviation, places: 2) == d("1.86"))
    }

    // Scenario: Edema não afeta estatura
    @Test func edemaNaoAfetaEstatura() throws {
        let result = try F.compute(withOedema(), .lengthOrHeightForAge)
        #expect(result.count == 10)
        #expect(result.oedemaCount == 0)
        #expect(result.prevalence(.belowMinus2) == 30)
        #expect(ClinicalRounding.round(result.mean, places: 2) == d("-0.11"))
    }

    // Scenario: Um registro implausível
    @Test func umRegistroImplausivelFicaDeFora() throws {
        let records = [F.record(z: d("-2.5")), F.record(z: 0, flagged: [.bmiForAge]), F.record(z: 1)]
        let result = try F.compute(records, .bmiForAge)
        #expect(result.count == 2)
        #expect(result.prevalence(.belowMinus2) == 50)
        #expect(result.mean == d("-0.75"))
    }

    // Scenario: Todos implausíveis
    @Test func todosImplausiveisDaoNZero() throws {
        let records = [F.record(z: 0, flagged: [.bmiForAge]), F.record(z: 1, flagged: [.bmiForAge])]
        let result = try F.compute(records, .bmiForAge)
        #expect(result.count == 0)
        #expect(result.prevalence(.belowMinus2) == nil)
        #expect(result.interval(.belowMinus2) == .unavailable)
    }

    private func around108Months() -> [AnalysisRecord] {
        [F.record(age: 100, z: d("-2.5")), F.record(age: 100, z: d("0.5")),
         F.record(age: 110, z: d("-3.2")), F.record(age: 110, z: 1)]
    }

    // Scenario: Peso para idade com crianças de 110 meses
    @Test func pesoParaIdadeComCriancasDe110Meses() throws {
        let result = try F.compute(around108Months(), .weightForAge)
        #expect(result.count == 4)
        #expect(result.prevalence(.belowMinus3) == 0)
        #expect(result.prevalence(.belowMinus2) == 25)
        #expect(result.mean == d("-0.5"))
    }

    // Scenario: Os mesmos registros em IMC
    @Test func osMesmosRegistrosEmImc() throws {
        let result = try F.compute(around108Months(), .bmiForAge)
        #expect(result.count == 4)
        #expect(result.prevalence(.belowMinus3) == 25)
        #expect(result.prevalence(.belowMinus2) == 50)
        #expect(result.mean == d("-1.05"))
    }

    // Scenario: Peso para idade de crianças sem cluster
    @Test func pesoParaIdadeDeCriancasSemClusterLancaErro() {
        let records = [F.record(age: 110, z: 0), F.record(age: 112, z: 0)]
        #expect(throws: AnalysisError.noClusterData) { _ = try F.compute(records, .weightForAge, improved: true) }
    }

    // Scenario: População vazia com correção
    @Test func populacaoVaziaComCorrecaoNaoLanca() throws {
        let result = try F.compute([], .lengthOrHeightForAge, improved: true)
        #expect(result.count == 0)
        #expect(result.interval(.belowMinus2) == .unavailable)
    }

    // Scenario: Faixas fixas de 61 a 228 meses
    @Test func faixasFixasDe61A228Meses() throws {
        let records = ["61", "119.9", "120", "228.5", "229", "60.9"].map { F.record(age: d($0), z: 0) }
        let results = try PrevalenceCalculator.byAgeGroups(records, indicator: .bmiForAge,
                                                           options: F.options(boundaries: [61, 120, 180, 228]),
                                                           analysisType: .standard, sex: nil, improvedClusterAnalysis: false)
        #expect(results.map(\.count) == [2, 1, 1])
    }

    // Scenario: Idade desconhecida
    @Test func idadeDesconhecidaNaoEntraEmFaixa() throws {
        let results = try PrevalenceCalculator.byAgeGroups([F.record(age: nil, z: 0)], indicator: .bmiForAge,
                                                           options: F.options(boundaries: [61, 120, 180, 228]),
                                                           analysisType: .standard, sex: nil, improvedClusterAnalysis: false)
        #expect(results.map(\.count) == [0, 0, 0])
    }

    // Scenario: Três meninos e duas meninas
    @Test func tresMeninosEDuasMeninas() throws {
        let records = (0..<3).map { _ in F.record(z: 0, sex: .boy) } + (0..<2).map { _ in F.record(z: 0, sex: .girl) }
            + [F.record(z: 0, sex: nil)]
        func counts(_ sex: Sex?) throws -> [Decimal] {
            try PrevalenceCalculator.byAgeGroups(records, indicator: .bmiForAge, options: F.options(boundaries: [61, 228]),
                                                 analysisType: .standard, sex: sex, improvedClusterAnalysis: false).map(\.count)
        }
        #expect(try counts(.boy) == [3])
        #expect(try counts(.girl) == [2])
        #expect(try counts(nil) == [6])
    }

    // Scenario: Sexo sem registros
    @Test func sexoSemRegistrosDaNZero() throws {
        let records = [F.record(z: 0, sex: .boy), F.record(z: 0, sex: .boy)]
        let results = try PrevalenceCalculator.byAgeGroups(records, indicator: .bmiForAge, options: F.options(boundaries: [61, 228]),
                                                           analysisType: .standard, sex: .girl, improvedClusterAnalysis: false)
        #expect(results.map(\.count) == [0])
    }

    // Scenario: Bordas de idade do total
    @Test func bordasDeIdadeDoTotal() {
        let records = ["60.99", "61", "228", "228.01"].map { F.record(age: d($0), z: 0) } + [F.record(age: nil, z: 0)]
        let kept = PrevalenceCalculator.filtered(records, sex: nil, onlyWithCluster: false)
        #expect(kept.map(\.ageInMonths) == [61, 228])
    }

    // Scenario: Só registros com cluster
    @Test func soRegistrosComCluster() {
        let records = [F.record(z: 0, cluster: 3), F.record(z: 0)]
        let kept = PrevalenceCalculator.filtered(records, sex: nil, onlyWithCluster: true)
        #expect(kept.map(\.cluster) == [3])
    }

    // Scenario: Clusters fora de ordem
    @Test func clustersForaDeOrdemSaemOrdenados() {
        let records = [7, 2, 7, 5].map { F.record(z: 0, cluster: $0) }
        let results = PrevalenceCalculator.byCluster(records, indicator: .bmiForAge, options: .default, analysisType: .standard)
        #expect(results.map(\.cluster) == [2, 5, 7])
        #expect(results.map(\.result.count) == [1, 1, 2])
    }

    // Scenario: Sem registros elegíveis
    @Test func semRegistrosElegiveisPorCluster() {
        let records = [F.record(age: 230, z: 0, cluster: 4), F.record(z: 0), F.record(z: 0, cluster: 9)]
        let results = PrevalenceCalculator.byCluster(records, indicator: .bmiForAge, options: .default, analysisType: .standard)
        #expect(results.map(\.cluster) == [9])
        #expect(results.map(\.result.count) == [1])
    }

    // Scenario: Peso abaixo do mínimo
    @Test func pesoAbaixoDoMinimoNasEstimativas() throws {
        let records = [F.record(z: d("-2.5"), weight: d("0.5")), F.record(z: 0, weight: 25)]
        let global = try F.compute(records, .bmiForAge, type: .whoGlobalDatabase)
        #expect(global.count == 1)
        #expect(global.prevalence(.belowMinus2) == 0)
        let standard = try F.compute(records, .bmiForAge, type: .standard)
        #expect(standard.count == 2)
        #expect(standard.prevalence(.belowMinus2) == 50)
    }

    // Scenario: Medida ausente não é filtrada
    @Test func medidaAusenteNaoEFiltrada() throws {
        let record = F.record(z: d("-2.5"), indicators: [.lengthOrHeightForAge], weight: nil, height: 120)
        let result = try F.compute([record], .lengthOrHeightForAge, type: .whoGlobalDatabase)
        #expect(result.count == 1)
        #expect(result.prevalence(.belowMinus2) == 100)
    }
}
