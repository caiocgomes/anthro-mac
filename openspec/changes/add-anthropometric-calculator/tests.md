# Tests

## Test Strategy

- **Framework**: swift-testing (`import Testing`, `@Test`, `#expect`, `#require`), com `@MainActor` nos testes de view model.
- **Full-suite command**: `swift test`
- **Conventions**: testes de cenário em `Tests/AnthroFeaturesTests/`, um arquivo por unidade (`CalculatorModelTests.swift`, `ApproximateBirthDateTests.swift`, `MeasurementInputTests.swift`, `IndicatorPanelTests.swift`, `GrowthChartModelTests.swift`, `ChartExportTests.swift`). O motor e as tabelas são reais (`AnthroEngine.shared()`, `GrowthReferenceTables.bundled()`), sem mocks. `AppSettings` usa `UserDefaults(suiteName:)` exclusivo por teste. O sorteador de dia é uma closure que registra o intervalo recebido e devolve o valor do cenário. Resultados com z conhecido para os testes de gráfico e de painel são construídos com o inicializador público de `AnthropometricResult` (exposto pela `port-anthro-engine`), em `Tests/AnthroFeaturesTests/Support/ResultFixtures.swift`. Datas de teste no calendário do usuário, ao meio-dia (`Calendar.current`), e comparadas por ano, mês e dia nesse calendário, porque o motor conta o dia de calendário que a tela mostra (decisão D8 da `port-anthro-engine`); meia-noite UTC cairia no dia anterior em São Paulo. Acesso a linhas e séries usa `try #require(...)`, para que stub vazio falhe por asserção e não por índice fora do intervalo. Quando o THEN espera um valor igual ao neutro do stub (falso, `nil`, domínio inalterado), o teste começa com uma asserção de guarda que o stub não satisfaz, indicada em **Expected red**.
- **Mutation tool**: manual.

## Spec-to-Test Mapping

### Capability: anthropometric-calculator

#### Scenario: Abertura com valores padrão
- **Test name**: `aberturaComValoresPadraoUsaSeisAnosMeninaVinteQuilos`
- **Test file**: `Tests/AnthroFeaturesTests/CalculatorModelTests.swift`
- **Level**: acceptance
- **Breaks if**: o estado inicial usa `AddYears(-5)`, sexo masculino ou peso 0.
- **Expected red**: expected dateOfBirth 2020-10-14, got 1970-01-01.

#### Scenario: Nova calculadora não herda valores
- **Test name**: `novaCalculadoraNaoHerdaValoresVoltaAVinteQuilos`
- **Test file**: `Tests/AnthroFeaturesTests/CalculatorModelTests.swift`
- **Level**: acceptance
- **Breaks if**: o modelo grava o último peso em `AppSettings` ou em estado estático e o restaura na criação.
- **Expected red**: expected weight 20.00, got nil.

#### Scenario: Seis anos de calendário mostram 71 meses
- **Test name**: `seisAnosDeCalendarioMostram71Meses`
- **Test file**: `Tests/AnthroFeaturesTests/CalculatorModelTests.swift`
- **Level**: acceptance
- **Breaks if**: a idade em texto arredonda os meses (72) em vez de truncar, ou usa anos de calendário.
- **Expected red**: expected "Idade: 5a 11m (71m)", got "".

#### Scenario: Idade abaixo de um ano
- **Test name**: `idadeAbaixoDeUmAnoMostraSoMeses`
- **Test file**: `Tests/AnthroFeaturesTests/CalculatorModelTests.swift`
- **Level**: acceptance
- **Breaks if**: o limite do formato longo vira `>= 0` e mostra "Idade: 0a 5m (5m)".
- **Expected red**: expected "Idade: 5m", got "".

#### Scenario: Visita movida para antes do nascimento
- **Test name**: `visitaMovidaParaAntesDoNascimentoPuxaNascimento`
- **Test file**: `Tests/AnthroFeaturesTests/CalculatorModelTests.swift`
- **Level**: acceptance
- **Breaks if**: `setDateOfVisit` deixa de aplicar o limite do nascimento.
- **Expected red**: expected dateOfBirth 2019-01-01, got 1970-01-01.

#### Scenario: Nascimento informado depois da visita
- **Test name**: `nascimentoInformadoDepoisDaVisitaFicaNaVisita`
- **Test file**: `Tests/AnthroFeaturesTests/CalculatorModelTests.swift`
- **Level**: acceptance
- **Breaks if**: `setDateOfBirth` aceita data posterior à visita.
- **Expected red**: expected dateOfBirth 2026-10-14, got 1970-01-01.

#### Scenario: Sorteio em fevereiro de 2021
- **Test name**: `sorteioEmFevereiroDe2021UsaIntervaloSemUltimoDia`
- **Test file**: `Tests/AnthroFeaturesTests/CalculatorModelTests.swift`
- **Level**: acceptance
- **Breaks if**: o intervalo passado ao sorteador vira `1..<29` (inclui o último dia) ou `1...28`.
- **Expected red**: expected recorded range 1..<28, got no call; expected dateOfBirth 2021-02-01, got 1970-01-01.

#### Scenario: Sorteio que ultrapassa a visita
- **Test name**: `sorteioQueUltrapassaAVisitaFicaNaVisita`
- **Test file**: `Tests/AnthroFeaturesTests/CalculatorModelTests.swift`
- **Level**: acceptance
- **Breaks if**: o limite da visita não é aplicado depois do sorteio em `setApproximateBirthDate`.
- **Expected red**: expected dateOfBirth 2026-10-14, got 1970-01-01.

#### Scenario: Helper nunca sorteia o último dia
- **Test name**: `helperNuncaSorteiaOUltimoDia`
- **Test file**: `Tests/AnthroFeaturesTests/ApproximateBirthDateTests.swift`
- **Level**: acceptance
- **Breaks if**: `randomized` passa `1..<(diasNoMês + 1)` ao sorteador e devolve 2021-02-28.
- **Expected red**: expected recorded range 1..<28 and 2021-02-27, got no call and 1970-01-01.

#### Scenario: Helper em fevereiro bissexto
- **Test name**: `helperEmFevereiroBissextoUsaIntervaloDe29`
- **Test file**: `Tests/AnthroFeaturesTests/ApproximateBirthDateTests.swift`
- **Level**: acceptance
- **Breaks if**: o número de dias do mês ignora ano bissexto (intervalo 1..<28).
- **Expected red**: expected recorded range 1..<29, got no call.

#### Scenario: Helper desfaz troca de dia
- **Test name**: `helperDesfazTrocaDeDiaSemSortear`
- **Test file**: `Tests/AnthroFeaturesTests/ApproximateBirthDateTests.swift`
- **Level**: acceptance
- **Breaks if**: `adjusted` sorteia em vez de devolver a data anterior quando o dia muda.
- **Expected red**: expected 2021-02-01, got 1970-01-01.

#### Scenario: Helper aceita troca de mês e sorteia de novo
- **Test name**: `helperAceitaTrocaDeMesESorteiaDeNovo`
- **Test file**: `Tests/AnthroFeaturesTests/ApproximateBirthDateTests.swift`
- **Level**: acceptance
- **Breaks if**: `adjusted` devolve a proposta sem sortear, ou usa os dias do mês anterior.
- **Expected red**: expected 2021-03-09 and recorded range 1..<31, got 1970-01-01 and no call.

#### Scenario: Helper sem data aproximada só limita pela visita
- **Test name**: `helperSemDataAproximadaSoLimitaPelaVisita`
- **Test file**: `Tests/AnthroFeaturesTests/ApproximateBirthDateTests.swift`
- **Level**: acceptance
- **Breaks if**: o limite superior deixa de ser aplicado sem data aproximada.
- **Expected red**: expected 2020-01-01, got 1970-01-01.

#### Scenario: Troca de mês aceita com novo sorteio
- **Test name**: `trocaDeMesAceitaComNovoSorteio`
- **Test file**: `Tests/AnthroFeaturesTests/CalculatorModelTests.swift`
- **Level**: acceptance
- **Breaks if**: a troca de mês com data aproximada não sorteia de novo, ou usa o número de dias do mês anterior.
- **Expected red**: expected dateOfBirth 2021-03-09 and last range 1..<31, got 1970-01-01 and no call.

#### Scenario: Troca de dia desfeita
- **Test name**: `trocaDeDiaDesfeitaMantemDataAnterior`
- **Test file**: `Tests/AnthroFeaturesTests/CalculatorModelTests.swift`
- **Level**: acceptance
- **Breaks if**: a comparação com o dia anterior é removida e a troca de dia é aceita.
- **Expected red**: expected dateOfBirth 2021-02-01, got 1970-01-01.

#### Scenario: Escolha habilitada com 334 dias
- **Test name**: `escolhaHabilitadaCom334Dias`
- **Test file**: `Tests/AnthroFeaturesTests/CalculatorModelTests.swift`
- **Level**: acceptance
- **Breaks if**: o limite vira `< 10` meses ou `<= 10`.
- **Expected red**: expected isMeasurementChoiceEnabled true, got false.

#### Scenario: Escolha desabilitada com 335 dias
- **Test name**: `escolhaDesabilitadaCom335DiasForcaEmPe`
- **Test file**: `Tests/AnthroFeaturesTests/CalculatorModelTests.swift`
- **Level**: acceptance
- **Breaks if**: o limite vira `<= 11` meses, ou a mudança de idade não força em pé.
- **Expected red**: guarda com 334 dias e deitado: expected isMeasurementChoiceEnabled true, got false.

#### Scenario: Criança de 30 meses sem escolha, contra a ajuda
- **Test name**: `criancaDe30MesesSemEscolhaContraAAjuda`
- **Test file**: `Tests/AnthroFeaturesTests/CalculatorModelTests.swift`
- **Level**: acceptance
- **Breaks if**: o limite segue a ajuda (`< 61` meses).
- **Expected red**: guarda com 10 meses (nascimento 2025-12-14) e deitado: expected measuredRecumbent true, got false.

#### Scenario: Peso truncado, não arredondado
- **Test name**: `pesoTruncadoNaoArredondado`
- **Test file**: `Tests/AnthroFeaturesTests/CalculatorModelTests.swift`
- **Level**: acceptance
- **Breaks if**: `MeasurementInput.parse` arredonda (20.13) em vez de truncar, ou não aceita vírgula.
- **Expected red**: expected weight 20.12, got nil.

#### Scenario: Valores fora dos limites
- **Test name**: `valoresForaDosLimitesEsvaziamOCampo`
- **Test file**: `Tests/AnthroFeaturesTests/CalculatorModelTests.swift`
- **Level**: acceptance
- **Breaks if**: valores fora de `InputLimits` são aceitos ou limitados ao máximo (275) em vez de esvaziar.
- **Expected red**: guarda com texto "25": expected weight 25, got nil.

#### Scenario: Helper trunca texto válido
- **Test name**: `helperTruncaTextoValido`
- **Test file**: `Tests/AnthroFeaturesTests/MeasurementInputTests.swift`
- **Level**: acceptance
- **Breaks if**: `evaluate` arredonda (20.13) ou rejeita o ponto como separador.
- **Expected red**: expected .value(20.12), got .empty.

#### Scenario: Helper aponta valor fora do intervalo
- **Test name**: `helperApontaValorForaDoIntervalo`
- **Test file**: `Tests/AnthroFeaturesTests/MeasurementInputTests.swift`
- **Level**: acceptance
- **Breaks if**: fora do intervalo é classificado como `.invalid`, ou o valor é limitado ao máximo.
- **Expected red**: expected .outOfRange(0.9...275), got .empty.

#### Scenario: Helper aponta texto inválido e vazio
- **Test name**: `helperApontaTextoInvalidoEVazio`
- **Test file**: `Tests/AnthroFeaturesTests/MeasurementInputTests.swift`
- **Level**: acceptance
- **Breaks if**: texto com dois separadores é aceito, ou espaços viram `.invalid` em vez de `.empty`.
- **Expected red**: expected .invalid, got .empty.

#### Scenario: Aviso de peso fora do intervalo
- **Test name**: `avisoDePesoForaDoIntervalo`
- **Test file**: `Tests/AnthroFeaturesTests/CalculatorModelTests.swift`
- **Level**: acceptance
- **Breaks if**: o modelo anula o peso sem registrar `weightIssue`, ou a mensagem usa ponto decimal.
- **Expected red**: expected weightIssue .outOfRange(0.9...275), got nil.

#### Scenario: Aviso some com valor válido
- **Test name**: `avisoSomeComValorValido`
- **Test file**: `Tests/AnthroFeaturesTests/CalculatorModelTests.swift`
- **Level**: acceptance
- **Breaks if**: `setWeightText` não limpa `weightIssue` quando o texto volta a ser válido.
- **Expected red**: guarda após "300": expected weightIssue .outOfRange(0.9...275), got nil.

#### Scenario: Aviso de medida inválida
- **Test name**: `avisoDeMedidaInvalida`
- **Test file**: `Tests/AnthroFeaturesTests/CalculatorModelTests.swift`
- **Level**: acceptance
- **Breaks if**: texto não numérico é tratado como vazio, sem aviso.
- **Expected red**: expected lengthOrHeightIssue .invalid, got nil.

#### Scenario: IMC de 20 kg e 110 cm aos seis anos
- **Test name**: `imcDe20kgE110cmAosSeisAnosMostra16v5`
- **Test file**: `Tests/AnthroFeaturesTests/CalculatorModelTests.swift`
- **Level**: acceptance
- **Breaks if**: o IMC usa a medida sem ajuste em padrões, ou é formatado com ponto.
- **Expected red**: expected "16,5", got "".

#### Scenario: IMC indisponível
- **Test name**: `imcIndisponivelMostraND`
- **Test file**: `Tests/AnthroFeaturesTests/CalculatorModelTests.swift`
- **Level**: acceptance
- **Breaks if**: o IMC é exibido com edema, ou o texto vazio substitui "N/D".
- **Expected red**: expected "N/D", got "".

#### Scenario: Troca de sexo
- **Test name**: `trocaDeSexoRecalculaComOMotor`
- **Test file**: `Tests/AnthroFeaturesTests/CalculatorModelTests.swift`
- **Level**: acceptance
- **Breaks if**: `setSex` não recalcula, ou o modelo passa `measuredRecumbent` invertido ao motor.
- **Expected red**: expected result.sex .boy, got nil.

#### Scenario: Peso apagado
- **Test name**: `pesoApagadoAnulaPesoEImcMantemEstatura`
- **Test file**: `Tests/AnthroFeaturesTests/CalculatorModelTests.swift`
- **Level**: acceptance
- **Breaks if**: texto vazio mantém o peso anterior em vez de `nil`.
- **Expected red**: expected lengthOrHeightForAge.zScore not nil, got nil.

#### Scenario: Z e percentil formatados
- **Test name**: `zEPercentilFormatadosComVirgula`
- **Test file**: `Tests/AnthroFeaturesTests/IndicatorPanelTests.swift`
- **Level**: acceptance
- **Breaks if**: o percentil é formatado com 2 casas ou o z com 1 casa.
- **Expected red**: `#require` da linha de peso falha: rows is empty.

#### Scenario: Percentil além de 3 DP
- **Test name**: `percentilAlemDe3DPMostraND`
- **Test file**: `Tests/AnthroFeaturesTests/IndicatorPanelTests.swift`
- **Level**: acceptance
- **Breaks if**: percentil `nil` vira "0,0" ou "100,0".
- **Expected red**: `#require` da linha de IMC falha: rows is empty.

#### Scenario: Gravidade alta
- **Test name**: `gravidadeAltaParaZMenos2v35`
- **Test file**: `Tests/AnthroFeaturesTests/IndicatorPanelTests.swift`
- **Level**: acceptance
- **Breaks if**: o painel classifica o z com sinal (sem valor absoluto) e devolve `.normal`.
- **Expected red**: `#require` da linha de peso falha: rows is empty.

#### Scenario: Gravidade indefinida
- **Test name**: `gravidadeIndefinidaParaZNulo`
- **Test file**: `Tests/AnthroFeaturesTests/IndicatorPanelTests.swift`
- **Level**: acceptance
- **Breaks if**: z `nil` é tratado como 0 e vira `.normal`.
- **Expected red**: `#require` da linha de estatura falha: rows is empty.

#### Scenario: Empate arredondado para par
- **Test name**: `empateDaBarraArredondaParaPar`
- **Test file**: `Tests/AnthroFeaturesTests/IndicatorPanelTests.swift`
- **Level**: acceptance
- **Breaks if**: `percentileBarValue` arredonda meio para cima (85 e 86) ou trunca (84 e 85).
- **Expected red**: expected 84 and 86, got 0 and 0.

#### Scenario: Barra sem percentil
- **Test name**: `barraSemPercentilUsa100Zero50`
- **Test file**: `Tests/AnthroFeaturesTests/IndicatorPanelTests.swift`
- **Level**: acceptance
- **Breaks if**: z `nil` cai no ramo de 0 em vez de 50, ou z > 3 cai em 0.
- **Expected red**: expected 100, got 0.

#### Scenario: Seis anos mostra estatura
- **Test name**: `seisAnosMostraEstaturaParaIdade`
- **Test file**: `Tests/AnthroFeaturesTests/CalculatorModelTests.swift`
- **Level**: acceptance
- **Breaks if**: o rótulo usa o modo de medida em vez de `result.isLength`.
- **Expected red**: `#require` da linha de estatura falha: rows is empty.

#### Scenario: Quinze meses medido em pé mostra comprimento
- **Test name**: `quinzeMesesMedidoEmPeMostraComprimento`
- **Test file**: `Tests/AnthroFeaturesTests/CalculatorModelTests.swift`
- **Level**: acceptance
- **Breaks if**: o rótulo é derivado de "em pé" (Estatura) e não de `isLength`.
- **Expected red**: `#require` da linha de estatura falha: rows is empty.

#### Scenario: Gráfico de IMC
- **Test name**: `graficoDeImcAbreComUmResultado`
- **Test file**: `Tests/AnthroFeaturesTests/CalculatorModelTests.swift`
- **Level**: acceptance
- **Breaks if**: `makeChart` ignora o indicador recebido ou passa mais de um resultado.
- **Expected red**: expected indicator .bmiForAge, got .weightForAge.

#### Scenario: Gráfico sem medida calculável
- **Test name**: `graficoSemMedidaCalculavelFicaVazio`
- **Test file**: `Tests/AnthroFeaturesTests/CalculatorModelTests.swift`
- **Level**: acceptance
- **Breaks if**: o gráfico desenha ponto para resultado fora dos limites.
- **Expected red**: expected isEmpty true, got false.

#### Scenario: Do peso para a medida
- **Test name**: `enterDoPesoVaiParaAMedida`
- **Test file**: `Tests/AnthroFeaturesTests/CalculatorModelTests.swift`
- **Level**: acceptance
- **Breaks if**: a ordem de foco troca medida e peso.
- **Expected red**: expected .lengthOrHeight, got nil.

#### Scenario: Modo de medida desabilitado é pulado
- **Test name**: `enterPulaModoDeMedidaDesabilitado`
- **Test file**: `Tests/AnthroFeaturesTests/CalculatorModelTests.swift`
- **Level**: acceptance
- **Breaks if**: `nextFocus` não consulta `isMeasurementChoiceEnabled`.
- **Expected red**: expected .oedema, got nil.

#### Scenario: Volta ao início e configuração desligada
- **Test name**: `enterVoltaAoInicioEDesligadoMantemFoco`
- **Test file**: `Tests/AnthroFeaturesTests/CalculatorModelTests.swift`
- **Level**: acceptance
- **Breaks if**: o último campo devolve `nil` com a configuração ligada (sem volta), ou a configuração desligada é ignorada.
- **Expected red**: expected .dateOfBirth, got nil.

### Capability: growth-charts

#### Scenario: Peso para idade sem linhas de 1 DP
- **Test name**: `pesoParaIdadeSemLinhasDe1DP`
- **Test file**: `Tests/AnthroFeaturesTests/GrowthChartModelTests.swift`
- **Level**: acceptance
- **Breaks if**: a condição que limita -1 e +1 DP ao IMC é removida (7 séries para peso).
- **Expected red**: expected 5 series labels, got [].

#### Scenario: IMC para idade com linhas de 1 DP
- **Test name**: `imcParaIdadeComLinhasDe1DP`
- **Test file**: `Tests/AnthroFeaturesTests/GrowthChartModelTests.swift`
- **Level**: acceptance
- **Breaks if**: a condição de -1 e +1 DP passa a excluir o IMC.
- **Expected red**: expected 7 series, got 0.

#### Scenario: Percentis de estatura para idade
- **Test name**: `percentisDeEstaturaParaIdade`
- **Test file**: `Tests/AnthroFeaturesTests/GrowthChartModelTests.swift`
- **Level**: acceptance
- **Breaks if**: os estilos de 15 e 85 viram `.sd2`, ou falta uma série.
- **Expected red**: expected labels ["3º", "15º", "50º", "85º", "97º"], got [].

#### Scenario: Percentil 50 sobre a mediana
- **Test name**: `percentil50SobreAMediana`
- **Test file**: `Tests/AnthroFeaturesTests/GrowthChartModelTests.swift`
- **Level**: acceptance
- **Breaks if**: a série "50º" usa o índice de offset errado de `percentileOffsets`.
- **Expected red**: `#require` da série "50º" falha: series is empty.

#### Scenario: Marca no gráfico de IMC
- **Test name**: `marcaDeTransicaoNoGraficoDeImc`
- **Test file**: `Tests/AnthroFeaturesTests/GrowthChartModelTests.swift`
- **Level**: acceptance
- **Breaks if**: a marca usa o último valor da série, ou x = 24.5.
- **Expected red**: `#require` de transitionMarker falha: nil.

#### Scenario: Peso para idade sem marca
- **Test name**: `pesoParaIdadeSemMarcaDeTransicao`
- **Test file**: `Tests/AnthroFeaturesTests/GrowthChartModelTests.swift`
- **Level**: acceptance
- **Breaks if**: a marca é criada para todos os indicadores.
- **Expected red**: guarda `series.count == 5`: expected 5, got 0.

#### Scenario: Faixa de peso para idade
- **Test name**: `faixaDosEixosDePesoParaIdade`
- **Test file**: `Tests/AnthroFeaturesTests/GrowthChartModelTests.swift`
- **Level**: acceptance
- **Breaks if**: o acréscimo de x para peso vira 20, ou o mínimo de y vira 8.
- **Expected red**: expected fullXDomain 0...130, got 0...0.

#### Scenario: Faixa de IMC para idade
- **Test name**: `faixaDosEixosDeImcParaIdade`
- **Test file**: `Tests/AnthroFeaturesTests/GrowthChartModelTests.swift`
- **Level**: acceptance
- **Breaks if**: o máximo fixo de 38 só vale no modo z-score, ou o acréscimo de x vira 10.
- **Expected red**: expected fullYDomain 8...38, got 0...0.

#### Scenario: Títulos de estatura para idade
- **Test name**: `titulosDosEixosDeEstaturaParaIdade`
- **Test file**: `Tests/AnthroFeaturesTests/GrowthChartModelTests.swift`
- **Level**: acceptance
- **Breaks if**: o título do eixo y de estatura vira "Peso (kg)".
- **Expected red**: expected "Idade (meses)", got "".

#### Scenario: Título do gráfico vazio
- **Test name**: `tituloDoGraficoVazioSemDados`
- **Test file**: `Tests/AnthroFeaturesTests/GrowthChartModelTests.swift`
- **Level**: acceptance
- **Breaks if**: gráfico sem pontos mantém o título da OMS.
- **Expected red**: expected "(Sem dados)", got "".

#### Scenario: Ponto de IMC
- **Test name**: `pontoDeImcUsaImcExatoDaMedidaAjustada`
- **Test file**: `Tests/AnthroFeaturesTests/GrowthChartModelTests.swift`
- **Level**: acceptance
- **Breaks if**: o y do IMC usa a medida não ajustada ou o IMC arredondado a 1 casa.
- **Expected red**: `#require` do primeiro ponto falha: points is empty.

#### Scenario: Resultado sem z omitido
- **Test name**: `resultadoSemZOmitidoDeixaGraficoVazio`
- **Test file**: `Tests/AnthroFeaturesTests/GrowthChartModelTests.swift`
- **Level**: acceptance
- **Breaks if**: a verificação de z `nil` é removida e o ponto entra com y do peso.
- **Expected red**: expected isEmpty true, got false.

#### Scenario: Peso aos 109 meses fora do gráfico
- **Test name**: `pesoAos109MesesForaDoGrafico`
- **Test file**: `Tests/AnthroFeaturesTests/GrowthChartModelTests.swift`
- **Level**: acceptance
- **Breaks if**: o limite de peso vira 121 ou 120 meses, ou o sufixo do eixo não é aplicado.
- **Expected red**: expected 1 point, got 0.

#### Scenario: Só pontos fora do intervalo
- **Test name**: `soPontosForaDoIntervaloDeixamGraficoVazio`
- **Test file**: `Tests/AnthroFeaturesTests/GrowthChartModelTests.swift`
- **Level**: acceptance
- **Breaks if**: com zero pontos o gráfico mantém curvas e título da OMS.
- **Expected red**: expected title "(Sem dados)", got "".

#### Scenario: Legenda no modo z-score
- **Test name**: `legendaNoModoZScore`
- **Test file**: `Tests/AnthroFeaturesTests/GrowthChartModelTests.swift`
- **Level**: acceptance
- **Breaks if**: a legenda usa ponto decimal ou omite a idade.
- **Expected red**: expected "Idade: 6a 0m (72m), z-score: -2,35", got nil.

#### Scenario: Legenda no modo percentil sem percentil
- **Test name**: `legendaNoModoPercentilSemPercentil`
- **Test file**: `Tests/AnthroFeaturesTests/GrowthChartModelTests.swift`
- **Level**: acceptance
- **Breaks if**: percentil `nil` é formatado como "0,0".
- **Expected red**: expected "Idade: 6a 0m (72m), Percentil: N/D", got nil.

#### Scenario: Legenda sem idade no nascimento
- **Test name**: `legendaSemIdadeNoNascimento`
- **Test file**: `Tests/AnthroFeaturesTests/GrowthChartModelTests.swift`
- **Level**: acceptance
- **Breaks if**: a condição `ageInDays > 0` vira `>= 0` e a legenda começa com "Idade: 0m".
- **Expected red**: expected "z-score: 0,00", got nil.

#### Scenario: Três visitas com vários pontos
- **Test name**: `tresVisitasComVariosPontos`
- **Test file**: `Tests/AnthroFeaturesTests/GrowthChartModelTests.swift`
- **Level**: acceptance
- **Breaks if**: os pontos são reordenados por idade, ou todos recebem `.current`.
- **Expected red**: expected 3 points, got 0.

#### Scenario: Ponto único entre três visitas
- **Test name**: `pontoUnicoEntreTresVisitas`
- **Test file**: `Tests/AnthroFeaturesTests/GrowthChartModelTests.swift`
- **Level**: acceptance
- **Breaks if**: o modo de ponto único desenha o índice 0 em vez do atual.
- **Expected red**: expected 1 point with resultIndex 2, got 0 points.

#### Scenario: Resultado único sem escolha
- **Test name**: `resultadoUnicoSemEscolhaDeVariosPontos`
- **Test file**: `Tests/AnthroFeaturesTests/GrowthChartModelTests.swift`
- **Level**: acceptance
- **Breaks if**: `setShowMultiplePoints(true)` é aceito com um único resultado.
- **Expected red**: guarda `points.count == 1`: expected 1, got 0.

#### Scenario: De peso para IMC
- **Test name**: `trocaDePesoParaImcRecalculaSeriesEFaixa`
- **Test file**: `Tests/AnthroFeaturesTests/GrowthChartModelTests.swift`
- **Level**: acceptance
- **Breaks if**: `setIndicator` não recalcula as séries ou mantém a faixa de peso.
- **Expected red**: expected 7 series, got 0.

#### Scenario: Troca de modo descarta o zoom
- **Test name**: `trocaDeModoDescartaOZoom`
- **Test file**: `Tests/AnthroFeaturesTests/GrowthChartModelTests.swift`
- **Level**: acceptance
- **Breaks if**: `setMode` preserva o domínio visível anterior.
- **Expected red**: guarda após o zoom: expected visibleXDomain 60...120, got 0...0.

#### Scenario: Zoom e restauração
- **Test name**: `zoomERestauracao`
- **Test file**: `Tests/AnthroFeaturesTests/GrowthChartModelTests.swift`
- **Level**: acceptance
- **Breaks if**: `resetZoom` não restaura y, ou `zoom` troca x por y.
- **Expected red**: expected visibleXDomain 60...120, got 0...0.

#### Scenario: Seleção degenerada ignorada
- **Test name**: `selecaoDegeneradaIgnorada`
- **Test file**: `Tests/AnthroFeaturesTests/GrowthChartModelTests.swift`
- **Level**: acceptance
- **Breaks if**: a checagem de largura zero é removida e o domínio vira 60...60.
- **Expected red**: guarda `fullXDomain == 0...130` no gráfico de peso: got 0...0.

#### Scenario: Deslocamento horizontal
- **Test name**: `deslocamentoHorizontalDe12Meses`
- **Test file**: `Tests/AnthroFeaturesTests/GrowthChartModelTests.swift`
- **Level**: acceptance
- **Breaks if**: `pan` desloca só o limite inferior, ou também desloca y.
- **Expected red**: expected visibleXDomain 72...132, got 0...0.

#### Scenario: Cópia em PNG
- **Test name**: `copiaEmPngParaAreaDeTransferencia`
- **Test file**: `Tests/AnthroFeaturesTests/ChartExportTests.swift`
- **Level**: integration
- **Breaks if**: a cópia grava só TIFF, sem o tipo PNG.
- **Expected red**: expected copy to return true, got false.

#### Scenario: Cópia sem imagem
- **Test name**: `copiaSemImagemNaoAlteraAreaDeTransferencia`
- **Test file**: `Tests/AnthroFeaturesTests/ChartExportTests.swift`
- **Level**: integration
- **Breaks if**: a cópia limpa a área de transferência (`clearContents`) antes de checar a imagem.
- **Expected red**: guarda com imagem válida: expected true, got false.

#### Scenario: Exportações válidas
- **Test name**: `exportacoesValidasPngPdfEImpressao`
- **Test file**: `Tests/AnthroFeaturesTests/ChartExportTests.swift`
- **Level**: integration
- **Breaks if**: o PDF é gerado com duas páginas ou o PNG com outro codec.
- **Expected red**: expected pngData not nil, got nil.

#### Scenario: Nome de arquivo sem barra
- **Test name**: `nomeDeArquivoSemBarra`
- **Test file**: `Tests/AnthroFeaturesTests/ChartExportTests.swift`
- **Level**: acceptance
- **Breaks if**: a troca de "/" por "-" é removida.
- **Expected red**: expected "Comprimento-estatura para idade - Percentil - 2026-10-14", got "".

#### Scenario: PDF inválido para impressão
- **Test name**: `pdfInvalidoParaImpressaoDevolveNil`
- **Test file**: `Tests/AnthroFeaturesTests/ChartExportTests.swift`
- **Level**: integration
- **Breaks if**: `printOperation` cria a operação sem validar o `PDFDocument`.
- **Expected red**: guarda com PDF válido de `pdfData`: expected operation not nil, got nil.

## Coverage Ledger

| Capability | Scenario | Test file | Test name | Breaks if | Red (SHA: failure) | Green (SHA) | State |
|------------|----------|-----------|-----------|-----------|--------------------|-------------|-------|
| anthropometric-calculator | Abertura com valores padrão | Tests/AnthroFeaturesTests/CalculatorModelTests.swift | aberturaComValoresPadraoUsaSeisAnosMeninaVinteQuilos | estado inicial com outros valores | c1d4d0f: `CalculatorModelTests.swift:36 Expectation failed: (ymd(m.dateOfBirth) -> "1969-12-31") == "2020-10-14"` | aa33b4f | green |
| anthropometric-calculator | Nova calculadora não herda valores | Tests/AnthroFeaturesTests/CalculatorModelTests.swift | novaCalculadoraNaoHerdaValoresVoltaAVinteQuilos | último peso persistido | c1d4d0f: `CalculatorModelTests.swift:50 Expectation failed: (first.weight -> nil) == 30` | aa33b4f | green |
| anthropometric-calculator | Seis anos de calendário mostram 71 meses | Tests/AnthroFeaturesTests/CalculatorModelTests.swift | seisAnosDeCalendarioMostram71Meses | meses arredondados | c1d4d0f: `CalculatorModelTests.swift:59 Expectation failed: (model().ageText -> "") == "Idade: 5a 11m (71m)"` | aa33b4f | green |
| anthropometric-calculator | Idade abaixo de um ano | Tests/AnthroFeaturesTests/CalculatorModelTests.swift | idadeAbaixoDeUmAnoMostraSoMeses | formato longo abaixo de 12 meses | c1d4d0f: `CalculatorModelTests.swift:66 Expectation failed: (m.ageText -> "") == "Idade: 5m"` | aa33b4f | green |
| anthropometric-calculator | Visita movida para antes do nascimento | Tests/AnthroFeaturesTests/CalculatorModelTests.swift | visitaMovidaParaAntesDoNascimentoPuxaNascimento | sem limite na visita | c1d4d0f: `CalculatorModelTests.swift:75 Expectation failed: (ymd(m.dateOfBirth) -> "1969-12-31") == "2019-01-01"` | aa33b4f | green |
| anthropometric-calculator | Nascimento informado depois da visita | Tests/AnthroFeaturesTests/CalculatorModelTests.swift | nascimentoInformadoDepoisDaVisitaFicaNaVisita | sem limite no nascimento | c1d4d0f: `CalculatorModelTests.swift:82 Expectation failed: (ymd(m.dateOfBirth) -> "1969-12-31") == "2026-10-14"` | aa33b4f | green |
| anthropometric-calculator | Sorteio em fevereiro de 2021 | Tests/AnthroFeaturesTests/CalculatorModelTests.swift | sorteioEmFevereiroDe2021UsaIntervaloSemUltimoDia | intervalo inclui o último dia | c1d4d0f: `CalculatorModelTests.swift:93 Expectation failed: (picker.ranges.last -> nil) == (1..<28 -> 1 ..< 28)` | aa33b4f | green |
| anthropometric-calculator | Sorteio que ultrapassa a visita | Tests/AnthroFeaturesTests/CalculatorModelTests.swift | sorteioQueUltrapassaAVisitaFicaNaVisita | sem limite após sorteio | c1d4d0f: `CalculatorModelTests.swift:104 Expectation failed: (ymd(m.dateOfBirth) -> "1969-12-31") == "2026-10-14"` | aa33b4f | green |
| anthropometric-calculator | Helper nunca sorteia o último dia | Tests/AnthroFeaturesTests/ApproximateBirthDateTests.swift | helperNuncaSorteiaOUltimoDia | intervalo inclui o último dia | c1d4d0f: `ApproximateBirthDateTests.swift:14 Expectation failed: (ranges -> []) == ([1..<28] -> [Range(1..<28)])` | 514a118 | green |
| anthropometric-calculator | Helper em fevereiro bissexto | Tests/AnthroFeaturesTests/ApproximateBirthDateTests.swift | helperEmFevereiroBissextoUsaIntervaloDe29 | ignora bissexto | c1d4d0f: `ApproximateBirthDateTests.swift:22 Expectation failed: (ranges -> []) == ([1..<29] -> [Range(1..<29)])` | 514a118 | green |
| anthropometric-calculator | Helper desfaz troca de dia | Tests/AnthroFeaturesTests/ApproximateBirthDateTests.swift | helperDesfazTrocaDeDiaSemSortear | sorteia em vez de desfazer | c1d4d0f: `ApproximateBirthDateTests.swift:31 Expectation failed: (ymd(result) -> "1969-12-31") == "2021-02-01"` | 514a118 | green |
| anthropometric-calculator | Helper aceita troca de mês e sorteia de novo | Tests/AnthroFeaturesTests/ApproximateBirthDateTests.swift | helperAceitaTrocaDeMesESorteiaDeNovo | não sorteia na troca de mês | c1d4d0f: `ApproximateBirthDateTests.swift:40 Expectation failed: (ranges -> []) == ([1..<31] -> [Range(1..<31)])` | 514a118 | green |
| anthropometric-calculator | Helper sem data aproximada só limita pela visita | Tests/AnthroFeaturesTests/ApproximateBirthDateTests.swift | helperSemDataAproximadaSoLimitaPelaVisita | sem limite superior | c1d4d0f: `ApproximateBirthDateTests.swift:50 Expectation failed: (ymd(earlier) -> "1969-12-31") == "2020-01-01"` | 514a118 | green |
| anthropometric-calculator | Troca de mês aceita com novo sorteio | Tests/AnthroFeaturesTests/CalculatorModelTests.swift | trocaDeMesAceitaComNovoSorteio | sem novo sorteio | c1d4d0f: `CalculatorModelTests.swift:117 Expectation failed: (picker.ranges.last -> nil) == (1..<31 -> 1 ..< 31)` | aa33b4f | green |
| anthropometric-calculator | Troca de dia desfeita | Tests/AnthroFeaturesTests/CalculatorModelTests.swift | trocaDeDiaDesfeitaMantemDataAnterior | troca de dia aceita | c1d4d0f: `CalculatorModelTests.swift:128 Expectation failed: (ymd(m.dateOfBirth) -> "1969-12-31") == "2021-02-01"` | aa33b4f | green |
| anthropometric-calculator | Escolha habilitada com 334 dias | Tests/AnthroFeaturesTests/CalculatorModelTests.swift | escolhaHabilitadaCom334Dias | limite < 10 meses | c1d4d0f: `CalculatorModelTests.swift:138 Expectation failed: (m.isMeasurementChoiceEnabled -> false) == true` | aa33b4f | green |
| anthropometric-calculator | Escolha desabilitada com 335 dias | Tests/AnthroFeaturesTests/CalculatorModelTests.swift | escolhaDesabilitadaCom335DiasForcaEmPe | limite <= 11 meses | c1d4d0f: `CalculatorModelTests.swift:147 Expectation failed: (m.isMeasurementChoiceEnabled -> false) == true` | aa33b4f | green |
| anthropometric-calculator | Criança de 30 meses sem escolha, contra a ajuda | Tests/AnthroFeaturesTests/CalculatorModelTests.swift | criancaDe30MesesSemEscolhaContraAAjuda | limite da ajuda (< 61) | c1d4d0f: `CalculatorModelTests.swift:158 Expectation failed: (m.measuredRecumbent -> false) == true` | aa33b4f | green |
| anthropometric-calculator | Peso truncado, não arredondado | Tests/AnthroFeaturesTests/CalculatorModelTests.swift | pesoTruncadoNaoArredondado | arredonda em vez de truncar | c1d4d0f: `CalculatorModelTests.swift:170 Expectation failed: (m.weight -> nil) == (num("20.12") -> 20.12)` | aa33b4f | green |
| anthropometric-calculator | Valores fora dos limites | Tests/AnthroFeaturesTests/CalculatorModelTests.swift | valoresForaDosLimitesEsvaziamOCampo | limita ao máximo | c1d4d0f: `CalculatorModelTests.swift:177 Expectation failed: (m.weight -> nil) == 25` | aa33b4f | green |
| anthropometric-calculator | Helper trunca texto válido | Tests/AnthroFeaturesTests/MeasurementInputTests.swift | helperTruncaTextoValido | arredonda | c1d4d0f: `MeasurementInputTests.swift:13 Expectation failed: (MeasurementInput.evaluate("20,129", range: weightRange) -> .empty) == (.value(num("20....` | ccbf73d | green |
| anthropometric-calculator | Helper aponta valor fora do intervalo | Tests/AnthroFeaturesTests/MeasurementInputTests.swift | helperApontaValorForaDoIntervalo | fora vira inválido | c1d4d0f: `MeasurementInputTests.swift:19 Expectation failed: (MeasurementInput.evaluate("300", range: weightRange) -> .empty) == (.outOfRange(weight...` | ccbf73d | green |
| anthropometric-calculator | Helper aponta texto inválido e vazio | Tests/AnthroFeaturesTests/MeasurementInputTests.swift | helperApontaTextoInvalidoEVazio | dois separadores aceitos | c1d4d0f: `MeasurementInputTests.swift:27 Expectation failed: (MeasurementInput.evaluate("12,3,4", range: lengthRange) -> .empty) == .invalid` | ccbf73d | green |
| anthropometric-calculator | Aviso de peso fora do intervalo | Tests/AnthroFeaturesTests/CalculatorModelTests.swift | avisoDePesoForaDoIntervalo | sem weightIssue | c1d4d0f: `CalculatorModelTests.swift:194 Expectation failed: (m.weightIssue -> nil) == (.outOfRange(num("0.9")...num("275")) -> .outOfRange(ClosedRa...` | aa33b4f | green |
| anthropometric-calculator | Aviso some com valor válido | Tests/AnthroFeaturesTests/CalculatorModelTests.swift | avisoSomeComValorValido | aviso não limpa | c1d4d0f: `CalculatorModelTests.swift:202 Expectation failed: (m.weightIssue -> nil) == (.outOfRange(num("0.9")...num("275")) -> .outOfRange(ClosedRa...` | aa33b4f | green |
| anthropometric-calculator | Aviso de medida inválida | Tests/AnthroFeaturesTests/CalculatorModelTests.swift | avisoDeMedidaInvalida | inválido tratado como vazio | c1d4d0f: `CalculatorModelTests.swift:213 Expectation failed: (m.lengthOrHeightIssue -> nil) == .invalid` | aa33b4f | green |
| anthropometric-calculator | IMC de 20 kg e 110 cm aos seis anos | Tests/AnthroFeaturesTests/CalculatorModelTests.swift | imcDe20kgE110cmAosSeisAnosMostra16v5 | formata com ponto | c1d4d0f: `CalculatorModelTests.swift:224 Expectation failed: (m.bmiText -> "") == "16,5"` | aa33b4f | green |
| anthropometric-calculator | IMC indisponível | Tests/AnthroFeaturesTests/CalculatorModelTests.swift | imcIndisponivelMostraND | IMC com edema | c1d4d0f: `CalculatorModelTests.swift:231 Expectation failed: (m.bmiText -> "") == "N/D"` | aa33b4f | green |
| anthropometric-calculator | Troca de sexo | Tests/AnthroFeaturesTests/CalculatorModelTests.swift | trocaDeSexoRecalculaComOMotor | sem recálculo | c1d4d0f: `CalculatorModelTests.swift:246 Expectation failed: (m.result.sex -> nil) == .boy` | aa33b4f | green |
| anthropometric-calculator | Peso apagado | Tests/AnthroFeaturesTests/CalculatorModelTests.swift | pesoApagadoAnulaPesoEImcMantemEstatura | texto vazio mantém peso | c1d4d0f: `CalculatorModelTests.swift:254 Expectation failed: (m.result.lengthOrHeightForAge.zScore -> nil) != nil` | aa33b4f | green |
| anthropometric-calculator | Z e percentil formatados | Tests/AnthroFeaturesTests/IndicatorPanelTests.swift | zEPercentilFormatadosComVirgula | casas trocadas | c1d4d0f: `IndicatorPanelTests.swift:9 Expectation failed: IndicatorPanel.rows(for: result).first { $0.indicator == indicator } -> nil` | fff4819 | green |
| anthropometric-calculator | Percentil além de 3 DP | Tests/AnthroFeaturesTests/IndicatorPanelTests.swift | percentilAlemDe3DPMostraND | nil vira número | c1d4d0f: `IndicatorPanelTests.swift:9 Expectation failed: IndicatorPanel.rows(for: result).first { $0.indicator == indicator } -> nil` | fff4819 | green |
| anthropometric-calculator | Gravidade alta | Tests/AnthroFeaturesTests/IndicatorPanelTests.swift | gravidadeAltaParaZMenos2v35 | sem valor absoluto | c1d4d0f: `IndicatorPanelTests.swift:9 Expectation failed: IndicatorPanel.rows(for: result).first { $0.indicator == indicator } -> nil` | fff4819 | green |
| anthropometric-calculator | Gravidade indefinida | Tests/AnthroFeaturesTests/IndicatorPanelTests.swift | gravidadeIndefinidaParaZNulo | nil tratado como 0 | c1d4d0f: `IndicatorPanelTests.swift:9 Expectation failed: IndicatorPanel.rows(for: result).first { $0.indicator == indicator } -> nil` | fff4819 | green |
| anthropometric-calculator | Empate arredondado para par | Tests/AnthroFeaturesTests/IndicatorPanelTests.swift | empateDaBarraArredondaParaPar | meio para cima | c1d4d0f: `IndicatorPanelTests.swift:38 Expectation failed: (IndicatorPanel.percentileBarValue(percentile: num("84.5"), zScore: num("1.02")) -> 0) ...` | fff4819 | green |
| anthropometric-calculator | Barra sem percentil | Tests/AnthroFeaturesTests/IndicatorPanelTests.swift | barraSemPercentilUsa100Zero50 | z nil em 0 | c1d4d0f: `IndicatorPanelTests.swift:44 Expectation failed: (IndicatorPanel.percentileBarValue(percentile: nil, zScore: num("3.50")) -> 0) == 100` | fff4819 | green |
| anthropometric-calculator | Seis anos mostra estatura | Tests/AnthroFeaturesTests/CalculatorModelTests.swift | seisAnosMostraEstaturaParaIdade | rótulo pelo modo de medida | c1d4d0f: `CalculatorModelTests.swift:263 Expectation failed: model().rows.first { $0.indicator == .lengthOrHeightForAge } -> nil` | aa33b4f | green |
| anthropometric-calculator | Quinze meses medido em pé mostra comprimento | Tests/AnthroFeaturesTests/CalculatorModelTests.swift | quinzeMesesMedidoEmPeMostraComprimento | rótulo por "em pé" | c1d4d0f: `CalculatorModelTests.swift:272 Expectation failed: m.rows.first { $0.indicator == .lengthOrHeightForAge } -> nil` | aa33b4f | green |
| anthropometric-calculator | Gráfico de IMC | Tests/AnthroFeaturesTests/CalculatorModelTests.swift | graficoDeImcAbreComUmResultado | indicador ignorado | c1d4d0f: `CalculatorModelTests.swift:282 Expectation failed: (chart.indicator -> .weightForAge) == .bmiForAge` | | red |
| anthropometric-calculator | Gráfico sem medida calculável | Tests/AnthroFeaturesTests/CalculatorModelTests.swift | graficoSemMedidaCalculavelFicaVazio | ponto fora dos limites desenhado | c1d4d0f: `CalculatorModelTests.swift:292 Expectation failed: (m.makeChart(for: .weightForAge).isEmpty -> false) == true` | | red |
| anthropometric-calculator | Do peso para a medida | Tests/AnthroFeaturesTests/CalculatorModelTests.swift | enterDoPesoVaiParaAMedida | ordem trocada | c1d4d0f: `CalculatorModelTests.swift:299 Expectation failed: (model().nextFocus(after: .weight) -> nil) == .lengthOrHeight` | aa33b4f | green |
| anthropometric-calculator | Modo de medida desabilitado é pulado | Tests/AnthroFeaturesTests/CalculatorModelTests.swift | enterPulaModoDeMedidaDesabilitado | ignora campo desabilitado | c1d4d0f: `CalculatorModelTests.swift:304 Expectation failed: (model().nextFocus(after: .lengthOrHeight) -> nil) == .oedema` | aa33b4f | green |
| anthropometric-calculator | Volta ao início e configuração desligada | Tests/AnthroFeaturesTests/CalculatorModelTests.swift | enterVoltaAoInicioEDesligadoMantemFoco | sem volta ou ignora configuração | c1d4d0f: `CalculatorModelTests.swift:310 Expectation failed: (m.nextFocus(after: .oedema) -> nil) == .dateOfBirth` | aa33b4f | green |
| growth-charts | Peso para idade sem linhas de 1 DP | Tests/AnthroFeaturesTests/GrowthChartModelTests.swift | pesoParaIdadeSemLinhasDe1DP | 1 DP para peso | c1d4d0f: `GrowthChartModelTests.swift:38 Expectation failed: (model.series.map(\.label) -> []) == ["-3 DP", "-2 DP", "Mediana", "+2 DP", "+3 DP"]` | | red |
| growth-charts | IMC para idade com linhas de 1 DP | Tests/AnthroFeaturesTests/GrowthChartModelTests.swift | imcParaIdadeComLinhasDe1DP | 1 DP excluído do IMC | c1d4d0f: `GrowthChartModelTests.swift:45 Expectation failed: (model.series.count -> 0) == 7` | | red |
| growth-charts | Percentis de estatura para idade | Tests/AnthroFeaturesTests/GrowthChartModelTests.swift | percentisDeEstaturaParaIdade | estilos trocados | c1d4d0f: `GrowthChartModelTests.swift:55 Expectation failed: (model.series.map(\.label) -> []) == ["3º", "15º", "50º", "85º", "97º"]` | | red |
| growth-charts | Percentil 50 sobre a mediana | Tests/AnthroFeaturesTests/GrowthChartModelTests.swift | percentil50SobreAMediana | offset errado | c1d4d0f: `GrowthChartModelTests.swift:30 Expectation failed: model.series.first { $0.label == label } -> nil` | | red |
| growth-charts | Marca no gráfico de IMC | Tests/AnthroFeaturesTests/GrowthChartModelTests.swift | marcaDeTransicaoNoGraficoDeImc | y do último ponto | c1d4d0f: `GrowthChartModelTests.swift:72 Expectation failed: (model -> AnthroFeatures.GrowthChartModel).transitionMarker -> nil -> nil` | | red |
| growth-charts | Peso para idade sem marca | Tests/AnthroFeaturesTests/GrowthChartModelTests.swift | pesoParaIdadeSemMarcaDeTransicao | marca em todos | c1d4d0f: `GrowthChartModelTests.swift:85 Expectation failed: (model.series.count -> 0) == 5` | | red |
| growth-charts | Faixa de peso para idade | Tests/AnthroFeaturesTests/GrowthChartModelTests.swift | faixaDosEixosDePesoParaIdade | acréscimo 20 para peso | c1d4d0f: `GrowthChartModelTests.swift:94 Expectation failed: (model.fullXDomain -> 0.0 ... 0.0) == (0...130 -> 0.0 ... 130.0)` | | red |
| growth-charts | Faixa de IMC para idade | Tests/AnthroFeaturesTests/GrowthChartModelTests.swift | faixaDosEixosDeImcParaIdade | máximo 38 só em z | c1d4d0f: `GrowthChartModelTests.swift:103 Expectation failed: (model.fullXDomain -> 0.0 ... 0.0) == (0...248 -> 0.0 ... 248.0)` | | red |
| growth-charts | Títulos de estatura para idade | Tests/AnthroFeaturesTests/GrowthChartModelTests.swift | titulosDosEixosDeEstaturaParaIdade | título y errado | c1d4d0f: `GrowthChartModelTests.swift:112 Expectation failed: (model.xAxisTitle -> "") == "Idade (meses)"` | | red |
| growth-charts | Título do gráfico vazio | Tests/AnthroFeaturesTests/GrowthChartModelTests.swift | tituloDoGraficoVazioSemDados | mantém título da OMS | c1d4d0f: `GrowthChartModelTests.swift:119 Expectation failed: (model.title -> "") == "(Sem dados)"` | | red |
| growth-charts | Ponto de IMC | Tests/AnthroFeaturesTests/GrowthChartModelTests.swift | pontoDeImcUsaImcExatoDaMedidaAjustada | medida sem ajuste | c1d4d0f: `GrowthChartModelTests.swift:127 Expectation failed: (chart([result], .bmiForAge).points -> []).first -> nil -> nil` | | red |
| growth-charts | Resultado sem z omitido | Tests/AnthroFeaturesTests/GrowthChartModelTests.swift | resultadoSemZOmitidoDeixaGraficoVazio | sem checagem de nil | c1d4d0f: `GrowthChartModelTests.swift:136 Expectation failed: (model.isEmpty -> false) == true` | | red |
| growth-charts | Peso aos 109 meses fora do gráfico | Tests/AnthroFeaturesTests/GrowthChartModelTests.swift | pesoAos109MesesForaDoGrafico | limite 121 | c1d4d0f: `GrowthChartModelTests.swift:145 Expectation failed: (model.points.count -> 0) == 1` | | red |
| growth-charts | Só pontos fora do intervalo | Tests/AnthroFeaturesTests/GrowthChartModelTests.swift | soPontosForaDoIntervaloDeixamGraficoVazio | mantém curvas | c1d4d0f: `GrowthChartModelTests.swift:154 Expectation failed: (model.isEmpty -> false) == true` | | red |
| growth-charts | Legenda no modo z-score | Tests/AnthroFeaturesTests/GrowthChartModelTests.swift | legendaNoModoZScore | ponto decimal | c1d4d0f: `GrowthChartModelTests.swift:163 Expectation failed: (model.legendText -> nil) == "Idade: 6a 0m (72m), z-score: -2,35"` | | red |
| growth-charts | Legenda no modo percentil sem percentil | Tests/AnthroFeaturesTests/GrowthChartModelTests.swift | legendaNoModoPercentilSemPercentil | nil vira 0,0 | c1d4d0f: `GrowthChartModelTests.swift:169 Expectation failed: (chart([result], .bmiForAge, mode: .percentile).legendText -> nil) == "Idade: 6a 0m (72...` | | red |
| growth-charts | Legenda sem idade no nascimento | Tests/AnthroFeaturesTests/GrowthChartModelTests.swift | legendaSemIdadeNoNascimento | condição >= 0 | c1d4d0f: `GrowthChartModelTests.swift:175 Expectation failed: (chart([result], .weightForAge).legendText -> nil) == "z-score: 0,00"` | | red |
| growth-charts | Três visitas com vários pontos | Tests/AnthroFeaturesTests/GrowthChartModelTests.swift | tresVisitasComVariosPontos | reordena por idade | c1d4d0f: `GrowthChartModelTests.swift:184 Expectation failed: (model.points.map(\.resultIndex) -> []) == [0, 1, 2]` | | red |
| growth-charts | Ponto único entre três visitas | Tests/AnthroFeaturesTests/GrowthChartModelTests.swift | pontoUnicoEntreTresVisitas | desenha índice 0 | c1d4d0f: `GrowthChartModelTests.swift:192 Expectation failed: (model.points.map(\.resultIndex) -> []) == [2]` | | red |
| growth-charts | Resultado único sem escolha | Tests/AnthroFeaturesTests/GrowthChartModelTests.swift | resultadoUnicoSemEscolhaDeVariosPontos | aceita vários com um | c1d4d0f: `GrowthChartModelTests.swift:199 Expectation failed: (model.points.count -> 0) == 1` | | red |
| growth-charts | De peso para IMC | Tests/AnthroFeaturesTests/GrowthChartModelTests.swift | trocaDePesoParaImcRecalculaSeriesEFaixa | sem recálculo | c1d4d0f: `GrowthChartModelTests.swift:211 Expectation failed: (model.series.count -> 0) == 7` | | red |
| growth-charts | Troca de modo descarta o zoom | Tests/AnthroFeaturesTests/GrowthChartModelTests.swift | trocaDeModoDescartaOZoom | preserva zoom | c1d4d0f: `GrowthChartModelTests.swift:219 Expectation failed: (model.visibleXDomain -> 0.0 ... 0.0) == (60...120 -> 60.0 ... 120.0)` | | red |
| growth-charts | Zoom e restauração | Tests/AnthroFeaturesTests/GrowthChartModelTests.swift | zoomERestauracao | reset sem y | c1d4d0f: `GrowthChartModelTests.swift:231 Expectation failed: (model.visibleXDomain -> 0.0 ... 0.0) == (60...120 -> 60.0 ... 120.0)` | | red |
| growth-charts | Seleção degenerada ignorada | Tests/AnthroFeaturesTests/GrowthChartModelTests.swift | selecaoDegeneradaIgnorada | aceita largura zero | c1d4d0f: `GrowthChartModelTests.swift:241 Expectation failed: (model.fullXDomain -> 0.0 ... 0.0) == (0...130 -> 0.0 ... 130.0)` | | red |
| growth-charts | Deslocamento horizontal | Tests/AnthroFeaturesTests/GrowthChartModelTests.swift | deslocamentoHorizontalDe12Meses | desloca só um limite | c1d4d0f: `GrowthChartModelTests.swift:253 Expectation failed: (model.visibleXDomain -> 0.0 ... 0.0) == (72...132 -> 72.0 ... 132.0)` | | red |
| growth-charts | Cópia em PNG | Tests/AnthroFeaturesTests/ChartExportTests.swift | copiaEmPngParaAreaDeTransferencia | só TIFF | c1d4d0f: `ChartExportTests.swift:35 Expectation failed: (ChartExport.copy(image(), to: board) -> false) == true` | | red |
| growth-charts | Cópia sem imagem | Tests/AnthroFeaturesTests/ChartExportTests.swift | copiaSemImagemNaoAlteraAreaDeTransferencia | limpa antes de checar | c1d4d0f: `ChartExportTests.swift:44 Expectation failed: (ChartExport.copy(image(), to: board) -> false) == true` | | red |
| growth-charts | Exportações válidas | Tests/AnthroFeaturesTests/ChartExportTests.swift | exportacoesValidasPngPdfEImpressao | PDF com duas páginas | c1d4d0f: `ChartExportTests.swift:52 Expectation failed: ChartExport.pngData(image() -> <CGImage 0xc1edac140> (DP)` | | red |
| growth-charts | Nome de arquivo sem barra | Tests/AnthroFeaturesTests/ChartExportTests.swift | nomeDeArquivoSemBarra | barra mantida | c1d4d0f: `ChartExportTests.swift:62 Expectation failed: (ChartExport.suggestedFileName(indicator: .lengthOrHeightForAge, mode: .percentile, dat...` | | red |
| growth-charts | PDF inválido para impressão | Tests/AnthroFeaturesTests/ChartExportTests.swift | pdfInvalidoParaImpressaoDevolveNil | sem validar PDF | c1d4d0f: `ChartExportTests.swift:68 Expectation failed: ChartExport.pdfData(image() -> <CGImage 0xc1edac000> (DP)` | | red |

## Test Changes After Red

<!-- Append-only. Vazio no planejamento. -->
