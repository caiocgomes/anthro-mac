import AnthroFeatures
import Foundation
import Testing

/// Cenários do modelo da Calculadora (capability anthropometric-calculator).
@MainActor
@Suite("anthropometric-calculator: CalculatorModel")
struct CalculatorModelTests {
    let engine: AnthroEngine
    let tables: GrowthReferenceTables

    init() throws {
        tables = try GrowthReferenceTables.bundled()
        engine = AnthroEngine(tables: tables)
    }

    private func make(today: Date = day(2026, 10, 14), picker: DayPicker = DayPicker()) -> (CalculatorModel, AppSettings) {
        let name = "calc-test-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name)!
        defaults.removePersistentDomain(forName: name)
        let settings = AppSettings(defaults: defaults)
        let model = CalculatorModel(engine: engine, tables: tables, settings: settings, today: today,
                                    randomDay: { picker($0) })
        return (model, settings)
    }

    private func model(picker: DayPicker = DayPicker()) -> CalculatorModel {
        make(picker: picker).0
    }

    // MARK: Estado inicial

    // Scenario: Abertura com valores padrão
    @Test func aberturaComValoresPadraoUsaSeisAnosMeninaVinteQuilos() {
        let m = model()
        #expect(ymd(m.dateOfBirth) == "2020-10-14")
        #expect(ymd(m.dateOfVisit) == "2026-10-14")
        #expect(m.sex == .girl)
        #expect(m.weight == num("20.00"))
        #expect(m.lengthOrHeight == num("115.00"))
        #expect(m.hasOedema == false)
        #expect(m.isApproximateBirthDate == false)
        #expect(m.measuredRecumbent == false)
    }

    // Scenario: Nova calculadora não herda valores
    @Test func novaCalculadoraNaoHerdaValoresVoltaAVinteQuilos() {
        let first = model()
        first.setWeightText("30")
        #expect(first.weight == 30)
        let second = model()
        #expect(second.weight == num("20.00"))
    }

    // MARK: Idade exibida

    // Scenario: Seis anos de calendário mostram 71 meses
    @Test func seisAnosDeCalendarioMostram71Meses() {
        #expect(model().ageText == "Idade: 5a 11m (71m)")
    }

    // Scenario: Idade abaixo de um ano
    @Test func idadeAbaixoDeUmAnoMostraSoMeses() {
        let m = model()
        m.setDateOfBirth(day(2026, 5, 14))
        #expect(m.ageText == "Idade: 5m")
    }

    // MARK: Nascimento limitado pela visita

    // Scenario: Visita movida para antes do nascimento
    @Test func visitaMovidaParaAntesDoNascimentoPuxaNascimento() {
        let m = model()
        m.setDateOfVisit(day(2019, 1, 1))
        #expect(ymd(m.dateOfBirth) == "2019-01-01")
    }

    // Scenario: Nascimento informado depois da visita
    @Test func nascimentoInformadoDepoisDaVisitaFicaNaVisita() {
        let m = model()
        m.setDateOfBirth(day(2027, 1, 1))
        #expect(ymd(m.dateOfBirth) == "2026-10-14")
    }

    // MARK: Data de nascimento aproximada

    // Scenario: Sorteio em fevereiro de 2021
    @Test func sorteioEmFevereiroDe2021UsaIntervaloSemUltimoDia() {
        let picker = DayPicker()
        let m = model(picker: picker)
        m.setDateOfBirth(day(2021, 2, 10))
        m.setApproximateBirthDate(true)
        #expect(picker.ranges.last == 1..<28)
        #expect(ymd(m.dateOfBirth) == "2021-02-01")
    }

    // Scenario: Sorteio que ultrapassa a visita
    @Test func sorteioQueUltrapassaAVisitaFicaNaVisita() {
        let picker = DayPicker()
        picker.pick = { _ in 20 }
        let m = model(picker: picker)
        m.setDateOfBirth(day(2026, 10, 5))
        m.setApproximateBirthDate(true)
        #expect(ymd(m.dateOfBirth) == "2026-10-14")
    }

    // MARK: Dia bloqueado na data aproximada

    // Scenario: Troca de mês aceita com novo sorteio
    @Test func trocaDeMesAceitaComNovoSorteio() {
        let picker = DayPicker()
        let m = model(picker: picker)
        m.setDateOfBirth(day(2021, 2, 10))
        m.setApproximateBirthDate(true)
        picker.pick = { _ in 9 }
        m.setDateOfBirth(day(2021, 3, 1))
        #expect(picker.ranges.last == 1..<31)
        #expect(ymd(m.dateOfBirth) == "2021-03-09")
    }

    // Scenario: Troca de dia desfeita
    @Test func trocaDeDiaDesfeitaMantemDataAnterior() {
        let picker = DayPicker()
        let m = model(picker: picker)
        m.setDateOfBirth(day(2021, 2, 10))
        m.setApproximateBirthDate(true)
        m.setDateOfBirth(day(2021, 2, 15))
        #expect(ymd(m.dateOfBirth) == "2021-02-01")
    }

    // MARK: Modo de medida só abaixo de 11 meses

    // Scenario: Escolha habilitada com 334 dias
    @Test func escolhaHabilitadaCom334Dias() {
        let m = model()
        m.setDateOfBirth(day(2025, 11, 14))
        m.setMeasuredRecumbent(true)
        #expect(m.isMeasurementChoiceEnabled == true)
        #expect(m.measuredRecumbent == true)
    }

    // Scenario: Escolha desabilitada com 335 dias
    @Test func escolhaDesabilitadaCom335DiasForcaEmPe() {
        let m = model()
        m.setDateOfBirth(day(2025, 11, 14))
        m.setMeasuredRecumbent(true)
        #expect(m.isMeasurementChoiceEnabled == true)
        m.setDateOfBirth(day(2025, 11, 13))
        #expect(m.isMeasurementChoiceEnabled == false)
        #expect(m.measuredRecumbent == false)
    }

    // Scenario: Criança de 30 meses sem escolha, contra a ajuda
    @Test func criancaDe30MesesSemEscolhaContraAAjuda() {
        let m = model()
        m.setDateOfBirth(day(2025, 12, 14))
        m.setMeasuredRecumbent(true)
        #expect(m.measuredRecumbent == true)
        m.setDateOfBirth(day(2024, 4, 14))
        #expect(m.isMeasurementChoiceEnabled == false)
        #expect(m.measuredRecumbent == false)
    }

    // MARK: Campos de peso e medida

    // Scenario: Peso truncado, não arredondado
    @Test func pesoTruncadoNaoArredondado() {
        let m = model()
        m.setWeightText("20,129")
        #expect(m.weight == num("20.12"))
    }

    // Scenario: Valores fora dos limites
    @Test func valoresForaDosLimitesEsvaziamOCampo() {
        let m = model()
        m.setWeightText("25")
        #expect(m.weight == 25)
        m.setWeightText("300")
        #expect(m.weight == nil)
        m.setWeightText("25")
        m.setWeightText("")
        #expect(m.weight == nil)
        m.setLengthOrHeightText("37,99")
        #expect(m.lengthOrHeight == nil)
    }

    // MARK: Aviso inline de campo com problema

    // Scenario: Aviso de peso fora do intervalo
    @Test func avisoDePesoForaDoIntervalo() {
        let m = model()
        m.setWeightText("300")
        #expect(m.weight == nil)
        #expect(m.weightIssue == .outOfRange(num("0.9")...num("275")))
        #expect(m.weightIssue?.issueMessage == "Fora do intervalo: 0,90 a 275,00")
    }

    // Scenario: Aviso some com valor válido
    @Test func avisoSomeComValorValido() {
        let m = model()
        m.setWeightText("300")
        #expect(m.weightIssue == .outOfRange(num("0.9")...num("275")))
        m.setWeightText("25")
        #expect(m.weight == 25)
        #expect(m.weightIssue == nil)
    }

    // Scenario: Aviso de medida inválida
    @Test func avisoDeMedidaInvalida() {
        let m = model()
        m.setLengthOrHeightText("abc")
        #expect(m.lengthOrHeight == nil)
        #expect(m.lengthOrHeightIssue == .invalid)
        #expect(m.lengthOrHeightIssue?.issueMessage == "Valor inválido")
    }

    // MARK: IMC exibido

    // Scenario: IMC de 20 kg e 110 cm aos seis anos
    @Test func imcDe20kgE110cmAosSeisAnosMostra16v5() {
        let m = model()
        m.setWeightText("20")
        m.setLengthOrHeightText("110")
        #expect(m.bmiText == "16,5")
    }

    // Scenario: IMC indisponível
    @Test func imcIndisponivelMostraND() {
        let m = model()
        m.setHasOedema(true)
        #expect(m.bmiText == "N/D")
        m.setHasOedema(false)
        m.setWeightText("")
        #expect(m.bmiText == "N/D")
    }

    // MARK: Recálculo a cada alteração

    // Scenario: Troca de sexo
    @Test func trocaDeSexoRecalculaComOMotor() throws {
        let m = model()
        m.setSex(.boy)
        let expected = try engine.result(dateOfBirth: m.dateOfBirth, dateOfVisit: m.dateOfVisit, sex: m.sex,
                                         weight: m.weight, lengthOrHeight: m.lengthOrHeight,
                                         measuredRecumbent: m.measuredRecumbent, hasOedema: m.hasOedema)
        #expect(m.result.sex == .boy)
        #expect(m.result == expected)
    }

    // Scenario: Peso apagado
    @Test func pesoApagadoAnulaPesoEImcMantemEstatura() {
        let m = model()
        m.setWeightText("")
        #expect(m.result.lengthOrHeightForAge.zScore != nil)
        #expect(m.result.weightForAge.zScore == nil)
        #expect(m.result.bmiForAge.zScore == nil)
    }

    // MARK: Rótulo de comprimento ou estatura

    // Scenario: Seis anos mostra estatura
    @Test func seisAnosMostraEstaturaParaIdade() throws {
        let row = try #require(model().rows.first { $0.indicator == .lengthOrHeightForAge })
        #expect(row.title == "Estatura para idade")
    }

    // Scenario: Quinze meses medido em pé mostra comprimento
    @Test func quinzeMesesMedidoEmPeMostraComprimento() throws {
        let m = model()
        m.setDateOfBirth(day(2025, 7, 14))
        m.setLengthOrHeightText("80")
        let row = try #require(m.rows.first { $0.indicator == .lengthOrHeightForAge })
        #expect(row.title == "Comprimento para idade")
        #expect(m.result.adjustedLengthOrHeight == num("80.70"))
    }

    // MARK: Abrir o gráfico a partir do painel

    // Scenario: Gráfico de IMC
    @Test func graficoDeImcAbreComUmResultado() {
        let chart = model().makeChart(for: .bmiForAge)
        #expect(chart.indicator == .bmiForAge)
        #expect(chart.resultCount == 1)
        #expect(chart.currentIndex == 0)
        #expect(chart.canShowMultiplePoints == false)
    }

    // Scenario: Gráfico sem medida calculável
    @Test func graficoSemMedidaCalculavelFicaVazio() {
        let m = model()
        m.setDateOfBirth(day(2000, 1, 1))
        #expect(m.makeChart(for: .weightForAge).isEmpty == true)
    }

    // MARK: Enter avança para o próximo campo

    // Scenario: Do peso para a medida
    @Test func enterDoPesoVaiParaAMedida() {
        #expect(model().nextFocus(after: .weight) == .lengthOrHeight)
    }

    // Scenario: Modo de medida desabilitado é pulado
    @Test func enterPulaModoDeMedidaDesabilitado() {
        #expect(model().nextFocus(after: .lengthOrHeight) == .oedema)
    }

    // Scenario: Volta ao início e configuração desligada
    @Test func enterVoltaAoInicioEDesligadoMantemFoco() {
        let (m, settings) = make()
        #expect(m.nextFocus(after: .oedema) == .dateOfBirth)
        settings.useEnterForNextControl = false
        #expect(m.nextFocus(after: .oedema) == nil)
    }
}
