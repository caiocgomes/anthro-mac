import AnthroFeatures
import Foundation
import Testing

/// Laço interno da regra de fora do intervalo de `DrawMeasures` (tarefa 3.2).
@MainActor
@Suite("GrowthChartModel: limite de idade dos pontos")
struct GrowthChartRangeUnitTests {
    let tables: GrowthReferenceTables

    init() throws {
        tables = try GrowthReferenceTables.bundled()
    }

    private func bmiChart(_ result: AnthropometricResult) -> GrowthChartModel {
        GrowthChartModel(results: [result], currentIndex: 0, indicator: .bmiForAge, tables: tables)
    }

    /// 6970 dias são 228,99 meses; 6971 dias, 229,02.
    @Test func imcAte228MesesInteirosEntraE229Sai() {
        let inside = bmiChart(fixtureResult(days: 6970, bmi: score("0.10", "54.0")))
        #expect(inside.points.count == 1)
        #expect(inside.hasOutOfRangePoints == false)
        let outside = bmiChart(fixtureResult(days: 6971, bmi: score("0.10", "54.0")))
        #expect(outside.points.isEmpty)
        #expect(outside.hasOutOfRangePoints == true)
    }

    /// Idade desconhecida equivale ao `decimal.MinValue` do original: negativa, fora do intervalo.
    @Test func idadeDesconhecidaFicaForaDoIntervalo() {
        let unknown = AnthropometricResult(
            sex: .girl, ageInDays: nil, ageInMonths: nil, ageRange: .unknown, weight: 20, lengthOrHeight: 110,
            adjustedLengthOrHeight: 110, isLength: false, weightForAge: noScore, lengthOrHeightForAge: noScore,
            bmiForAge: score("0.10", "54.0"))
        let model = bmiChart(unknown)
        #expect(model.points.isEmpty)
        #expect(model.hasOutOfRangePoints == true)
    }

    /// Resultado sem z não conta como fora do intervalo, mesmo com idade acima do limite.
    @Test func semZNaoMarcaForaDoIntervalo() {
        let model = bmiChart(fixtureResult(days: 6971))
        #expect(model.hasOutOfRangePoints == false)
    }
}
