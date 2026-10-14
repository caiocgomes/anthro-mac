import AnthroFeatures
import Foundation
import Testing

/// Cenários do painel de resultados compartilhado (capability anthropometric-calculator).
@Suite("anthropometric-calculator: IndicatorPanel")
struct IndicatorPanelTests {
    private func row(_ indicator: Indicator, in result: AnthropometricResult) throws -> IndicatorPanelRow {
        try #require(IndicatorPanel.rows(for: result).first { $0.indicator == indicator })
    }

    // Scenario: Z e percentil formatados
    @Test func zEPercentilFormatadosComVirgula() throws {
        let weight = try row(.weightForAge, in: fixtureResult(days: 2192, wfa: score("-2.35", "0.9")))
        #expect(weight.zScoreText == "-2,35")
        #expect(weight.percentileText == "0,9")
    }

    // Scenario: Percentil além de 3 DP
    @Test func percentilAlemDe3DPMostraND() throws {
        let bmi = try row(.bmiForAge, in: fixtureResult(days: 2192, bmi: score("3.50", nil)))
        #expect(bmi.zScoreText == "3,50")
        #expect(bmi.percentileText == "N/D")
    }

    // Scenario: Gravidade alta
    @Test func gravidadeAltaParaZMenos2v35() throws {
        #expect(try row(.weightForAge, in: fixtureResult(days: 2192, wfa: score("-2.35", "0.9"))).severity == .high)
    }

    // Scenario: Gravidade indefinida
    @Test func gravidadeIndefinidaParaZNulo() throws {
        #expect(try row(.lengthOrHeightForAge, in: fixtureResult(days: 2192, lhfa: noScore)).severity == .undefined)
    }

    // Scenario: Empate arredondado para par
    @Test func empateDaBarraArredondaParaPar() {
        #expect(IndicatorPanel.percentileBarValue(percentile: num("84.5"), zScore: num("1.02")) == 84)
        #expect(IndicatorPanel.percentileBarValue(percentile: num("85.5"), zScore: num("1.06")) == 86)
    }

    // Scenario: Barra sem percentil
    @Test func barraSemPercentilUsa100Zero50() {
        #expect(IndicatorPanel.percentileBarValue(percentile: nil, zScore: num("3.50")) == 100)
        #expect(IndicatorPanel.percentileBarValue(percentile: nil, zScore: num("-3.50")) == 0)
        #expect(IndicatorPanel.percentileBarValue(percentile: nil, zScore: nil) == 50)
    }
}
