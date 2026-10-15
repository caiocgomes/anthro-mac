import AnthroCore
import Foundation
import Testing

/// Testes de cenário da capability anthropometric-computation (change port-anthro-engine).
@Suite("anthropometric-computation")
struct AnthropometricComputationTests {
    let engine: AnthroEngine
    let tables: GrowthReferenceTables

    init() throws {
        tables = try GrowthReferenceTables.bundled()
        engine = AnthroEngine(tables: tables)
    }

    private func r(_ value: Decimal?, _ places: Int) -> Decimal? {
        ClinicalRounding.round(value, places: places)
    }

    private var weightBoyDay0: LMS {
        tables.standardsLMS(.weightForAge, sex: .boy, ageInDays: 0) ?? LMS(l: 0, m: 0, s: 0)
    }

    // MARK: Idade em dias e em meses

    // Scenario: Idade de uma criança de cinco anos
    @Test func idadeDeUmaCriancaDeCincoAnos() throws {
        let days = try AgeMath.ageInDays(birth: localDate(2016, 3, 15, hour: 23, minute: 30),
                                         visit: localDate(2021, 4, 1, hour: 0, minute: 30))
        #expect(days == 1843)
        #expect(AgeMath.daysToMonths(1843) == Decimal(1843) / d("30.4375"))
    }

    // Scenario: Nascimento depois da visita
    @Test func nascimentoDepoisDaVisita() {
        #expect(throws: AnthroError.birthAfterVisit) {
            try AgeMath.ageInDays(birth: localDate(2021, 4, 2), visit: localDate(2021, 4, 1))
        }
    }

    // MARK: Conversão de meses para dias

    // Scenario: Meses fracionados
    @Test func mesesFracionadosViramDias() {
        #expect(AgeMath.monthsToDays(d("61.5")) == 1872)
    }

    // Scenario: Dois anos exatos
    @Test func doisAnosExatosViram731Dias() {
        #expect(AgeMath.monthsToDays(24) == 731)
    }

    // MARK: Faixa etária do cálculo

    // Scenario: Último dia dos padrões e primeiro da referência
    @Test func ultimoDiaDosPadroesEPrimeiroDaReferencia() {
        #expect(AgeMath.ageRange(days: 1856, months: AgeMath.daysToMonths(1856)) == .standards)
        #expect(AgeMath.ageRange(days: 1857, months: AgeMath.daysToMonths(1857)) == .reference)
        #expect(engine.at(days: 1856, sex: .boy, weight: 18, height: 110).ageRange == .standards)
        #expect(engine.at(days: 1857, sex: .boy, weight: 18, height: 110).ageRange == .reference)
    }

    // Scenario: Última idade válida e primeira fora dos limites
    @Test func ultimaIdadeValidaEPrimeiraForaDosLimites() {
        #expect(engine.at(days: 6970, sex: .boy, weight: 60, height: 170).ageRange == .reference)
        let off = engine.at(days: 6971, sex: .boy, weight: 60, height: 170)
        #expect(off.ageRange == .offLimits)
        for indicator in Indicator.allCases {
            #expect(off.score(indicator) == IndicatorScore(zScore: nil, percentile: nil), "\(indicator)")
        }
    }

    // MARK: Sexo ou idade desconhecidos

    // Scenario: Sexo ausente
    @Test func sexoAusenteZeraResultados() {
        let result = engine.at(days: 2000, sex: nil, weight: 18, height: 110)
        for indicator in Indicator.allCases {
            #expect(result.score(indicator) == IndicatorScore(zScore: nil, percentile: nil), "\(indicator)")
        }
    }

    // Scenario: Idade ausente
    @Test func idadeAusenteDaFaixaDesconhecida() {
        let result = engine.at(days: nil, months: nil, sex: .girl, weight: 18, height: nil)
        #expect(result.ageRange == .unknown)
        for indicator in Indicator.allCases {
            #expect(result.score(indicator).zScore == nil, "\(indicator)")
        }
    }

    // MARK: Ajuste entre comprimento e altura

    // Scenario: Comprimento medido em pé
    @Test func comprimentoMedidoEmPeSoma07() {
        let adjusted = Anthropometry.adjustedLengthOrHeight(ageInDays: 730, value: d("80.00"), measuredRecumbent: false)
        #expect(adjusted.value == d("80.70"))
        #expect(adjusted.isLength == true)
    }

    // Scenario: Altura medida deitada
    @Test func alturaMedidaDeitadaSubtrai07() {
        let adjusted = Anthropometry.adjustedLengthOrHeight(ageInDays: 731, value: d("90.00"), measuredRecumbent: true)
        #expect(adjusted.value == d("89.30"))
        #expect(adjusted.isLength == false)
    }

    // Scenario: Referência ignora o modo de medida
    @Test func referenciaIgnoraOModoDeMedida() {
        let result = engine.at(days: 2000, sex: .boy, weight: 18, height: d("110.00"), recumbent: true)
        #expect(result.adjustedLengthOrHeight == d("110.00"))
    }

    // MARK: Arredondamento das entradas

    // Scenario: Peso com três casas
    @Test func pesoComTresCasasArredondaAntes() {
        #expect(engine.at(days: 2000, sex: .girl, weight: d("20.005"), height: 110).weight == d("20.01"))
    }

    // Scenario: Peso ausente
    @Test func pesoAusenteZeraPesoEImc() {
        let result = engine.at(days: 2000, sex: .girl, weight: nil, height: 110)
        #expect(result.weight == nil)
        #expect(result.weightForAge.zScore == nil)
        #expect(result.bmiForAge.zScore == nil)
    }

    // MARK: IMC exato

    // Scenario: IMC de 20 kg e 110 cm
    @Test func imcDe20KgE110Cm() {
        let bmi = Anthropometry.exactBMI(weight: 20, lengthOrHeight: 110)
        #expect(r(bmi, 13) == d("16.5289256198347"))
        #expect(r(bmi, 1) == d("16.5"))
    }

    // Scenario: IMC absurdo
    @Test func imcAbsurdoEIndefinido() {
        #expect(Anthropometry.exactBMI(weight: 275, lengthOrHeight: 1) == nil)
    }

    // MARK: Z-score de estatura para idade

    // Scenario: Estatura em +2 DP
    @Test func estaturaEmMais2Dp() {
        let result = engine.at(days: nil, months: 61, sex: .boy, weight: nil, height: d("119.447544216"))
        #expect(result.lengthOrHeightForAge.zScore == d("2.00"))
    }

    // Scenario: Estatura além de +3 DP não é ajustada
    @Test func estaturaAlemDe3DpNaoEAjustada() {
        let result = engine.at(days: nil, months: 61, sex: .boy, weight: nil, height: d("128.630388432"))
        #expect(result.lengthOrHeightForAge.zScore == d("4.00"))
    }

    // Scenario: Medida inválida
    @Test func medidaInvalidaZeraEstatura() {
        let result = engine.at(days: 2000, sex: .girl, weight: 18, height: d("0.5"))
        #expect(result.lengthOrHeightForAge == IndicatorScore(zScore: nil, percentile: nil))
    }

    // MARK: Z-score ajustado de peso e IMC

    // Scenario: Peso acima de +3 DP
    @Test func pesoAcimaDe3DpUsaAjuste() {
        #expect(r(ZScore.lms(d("5.641924702067"), weightBoyDay0, restricted: true), 2) == d("4.00"))
    }

    // Scenario: Peso abaixo de -3 DP
    @Test func pesoAbaixoDeMenos3DpUsaAjuste() {
        #expect(r(ZScore.lms(d("1.701303187307"), weightBoyDay0, restricted: true), 2) == d("-4.00"))
    }

    // Scenario: Peso dentro de 3 DP
    @Test func pesoNaMedianaDaZeroEPercentil50() throws {
        let z = try #require(ZScore.lms(d("3.3464"), weightBoyDay0, restricted: true))
        #expect(r(z, 2) == d("0.00"))
        #expect(r(ZScore.centile(z), 1) == d("50.0"))
    }

    // MARK: Edema e peso mínimo

    // Scenario: Criança com edema
    @Test func criancaComEdemaZeraPesoEImc() {
        let result = engine.at(days: 2000, sex: .girl, weight: 18, height: 110, oedema: true)
        #expect(result.weightForAge.zScore == nil)
        #expect(result.bmiForAge.zScore == nil)
        #expect(result.lengthOrHeightForAge.zScore != nil)
    }

    // Scenario: Peso abaixo do mínimo
    @Test func pesoAbaixoDoMinimoZeraPeso() {
        #expect(engine.at(days: 0, sex: .boy, weight: d("0.85"), height: nil).weightForAge.zScore == nil)
    }

    // MARK: Peso para idade só até 121 meses

    // Scenario: Última idade com peso para idade
    @Test func ultimaIdadeComPesoParaIdade() {
        let result = engine.at(days: 3682, sex: .boy, weight: 32, height: 138)
        #expect(result.weightForAge == IndicatorScore(zScore: d("0.16"), percentile: d("56.4")))
    }

    // Scenario: Primeira idade sem peso para idade
    @Test func primeiraIdadeSemPesoParaIdade() {
        let result = engine.at(days: 3683, sex: .boy, weight: 32, height: 138)
        #expect(result.weightForAge.zScore == nil)
        #expect(result.lengthOrHeightForAge.zScore != nil)
        #expect(result.bmiForAge.zScore != nil)
    }

    // MARK: Percentil a partir do z-score

    // Scenario: Percentis de z conhecidos
    @Test func percentisDeZConhecidos() {
        #expect(r(ZScore.centile(1), 1) == d("84.1"))
        #expect(r(ZScore.centile(-2), 1) == d("2.3"))
        #expect(r(ZScore.centile(3), 1) == d("99.9"))
    }

    // Scenario: Percentil além de 3 DP
    @Test func percentilAlemDe3DpEIndefinido() {
        #expect(ZScore.centile(d("3.0001")) == nil)
        #expect(ZScore.centile(d("-3.01")) == nil)
    }

    // MARK: Arredondamento clínico

    // Scenario: Empates longe de zero (MODIFIED pela change add-survey-analysis: só os empates positivos)
    @Test func empatesArredondamLongeDeZero() {
        #expect(r(d("2.345"), 2) == d("2.35"))
        #expect(r(d("0.125"), 2) == d("0.13"))
    }

    // Scenario: Empate negativo vai para zero (change add-survey-analysis: o piso do original age sobre o valor com sinal)
    @Test func empateNegativoVaiParaZero() {
        #expect(r(d("-2.345"), 2) == d("-2.34"))
        #expect(r(d("-1.235"), 2) == d("-1.23"))
    }

    // Scenario: Valor indefinido
    @Test func valorIndefinidoContinuaIndefinido() {
        #expect(r(nil, 2) == nil)
    }

    // MARK: Conversão de Double para Decimal

    // Scenario: Soma binária imprecisa
    @Test func somaBinariaImprecisaViraDecimalExato() {
        #expect(ClinicalRounding.decimal15(0.1 + 0.2) == d("0.3"))
    }

    // Scenario: Valor não finito
    @Test func valorNaoFinitoViraNil() {
        #expect(ClinicalRounding.decimal15(.infinity) == nil)
    }

    // MARK: Flags de plausibilidade

    // Scenario: Limites dos intervalos
    @Test func limitesDosIntervalosDePlausibilidade() {
        #expect(Plausibility.isFlagged(.weightForAge, z: d("5.00")) == false)
        #expect(Plausibility.isFlagged(.weightForAge, z: d("5.01")) == true)
        #expect(Plausibility.isFlagged(.lengthOrHeightForAge, z: d("6.00")) == false)
        #expect(Plausibility.isFlagged(.lengthOrHeightForAge, z: d("6.01")) == true)
        #expect(Plausibility.isFlagged(.bmiForAge, z: d("-5.00")) == false)
        #expect(Plausibility.isFlagged(.bmiForAge, z: d("-5.01")) == true)
    }

    // Scenario: Peso e estatura implausíveis ao mesmo tempo
    @Test func pesoEEstaturaImplausiveisAoMesmoTempo() {
        let result = AnthropometricResult(
            sex: .boy, ageInDays: 2000, ageInMonths: AgeMath.daysToMonths(2000), ageRange: .reference,
            weight: 18, lengthOrHeight: 110, adjustedLengthOrHeight: 110, isLength: false,
            weightForAge: IndicatorScore(zScore: d("-6.5"), percentile: nil),
            lengthOrHeightForAge: IndicatorScore(zScore: d("6.5"), percentile: nil),
            bmiForAge: IndicatorScore(zScore: d("7.0"), percentile: nil)
        )
        #expect(Plausibility.flag(for: result) == .weightAndLengthOrHeightForAge)
    }

    // MARK: Classificação de gravidade

    // Scenario: Fronteiras das faixas
    @Test func fronteirasDasFaixasDeGravidade() {
        #expect(SeverityClassifier.severity(d("0.99")) == .normal)
        #expect(SeverityClassifier.severity(d("1.00")) == .moderate)
        #expect(SeverityClassifier.severity(d("2.00")) == .high)
        #expect(SeverityClassifier.severity(d("3.00")) == .extreme)
    }

    // Scenario: Negativo extremo e indefinido
    @Test func negativoExtremoEIndefinido() {
        #expect(SeverityClassifier.severity(d("-3.50")) == .extreme)
        #expect(SeverityClassifier.severity(nil) == .undefined)
    }

    // MARK: Paridade com os pacotes R da OMS (caso fora do domínio do oráculo)

    // Scenario: Peso para idade aos 121 meses informados
    @Test func pesoParaIdadeAos121MesesInformados() {
        let result = engine.at(days: nil, months: 121, sex: .boy, weight: d("45.04"), height: nil)
        #expect(result.weightForAge == IndicatorScore(zScore: d("2.00"), percentile: d("97.7")))
    }
}
