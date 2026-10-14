import AnthroCore
import AnthroIO
import Foundation
import Testing

/// Cenários dos resultados incluídos na exportação (change add-individual-import-export).
@Suite("individual-data-exchange: resultados exportados")
struct ExchangeResultsCalculatorTests {
    let engine: AnthroEngine

    init() throws {
        engine = try AnthroEngine.shared()
    }

    // Scenario: IMC exportado usa a medida ajustada
    @Test func imcExportadoUsaAMedidaAjustadaEmQualquerIdade() {
        let visit = ExchangeFixtures.visit(daysAfterBirth: 2000, weight: "20", height: "110", recumbent: true)
        let results = ExchangeResultsCalculator.results(engine: engine, sex: .girl, dateOfBirth: day("2016-03-15"), visit: visit)
        #expect(results.bmi == d("16.7"))
    }

    // Scenario: Resultados com edema
    @Test func resultadosComEdemaMantemSoEstatura() {
        let visit = ExchangeFixtures.visit(daysAfterBirth: 1843, weight: "18", height: "110", oedema: true)
        let results = ExchangeResultsCalculator.results(engine: engine, sex: .girl, dateOfBirth: day("2016-03-15"), visit: visit)
        #expect(results.lengthOrHeightForAgeZ != nil)
        #expect(results.weightForAgeZ == nil)
        #expect(results.bmiForAgeZ == nil)
        #expect(results.bmi == nil)
    }
}
