# Tasks

## 0. Red gate

- [ ] 0.1 Write every scenario test from tests.md (`CalculatorModelTests.swift`, `ApproximateBirthDateTests.swift`, `MeasurementInputTests.swift`, `IndicatorPanelTests.swift`, `GrowthChartModelTests.swift`, `ChartExportTests.swift`, mais `Support/ResultFixtures.swift`) and stubs with the exact signatures from Interface Under Test (neutral return values, no logic)
- [ ] 0.2 Run the scenario tests with `swift test --filter AnthroFeaturesTests`; confirm each FAILS BY ASSERTION (not import, syntax or collection errors); record each failure excerpt in the ledger
- [ ] 0.3 Commit tests and stubs only as `test(red): add-anthropometric-calculator`; write the SHA in the ledger
- [ ] 0.4 STOP: show the user the failing tests and wait for explicit approval before implementing

## 1. Utilitários compartilhados

- [ ] 1.1 Implement `AgeText.localized(months:)` (port de `Utils.GetLocalizedAgeFromMonths`) e as strings pt-BR de `L10n+Anthro.swift`, unit tests first (inner loop); verified when [tests: seisAnosDeCalendarioMostram71Meses, idadeAbaixoDeUmAnoMostraSoMeses] and their unit tests pass
- [ ] 1.2 Implement o helper compartilhado `MeasurementInput` (`Outcome`, `issueMessage`, `evaluate`, `parse`, `truncate`; port de `NumericUpDownX.CheckValidValue` e `AnthroComputation.SymetricCrop`), unit tests first (inner loop); verified when [tests: helperTruncaTextoValido, helperApontaValorForaDoIntervalo, helperApontaTextoInvalidoEVazio] and their unit tests pass
- [ ] 1.3 Implement o helper compartilhado `ApproximateBirthDate.randomized` e `adjusted` (port do ramo aproximado de `ACMain.dtpDateOfBirth_ValueChanged` e `cbDateIsApprox_CheckStateChanged`), unit tests first (inner loop) para a aritmética de calendário em UTC; verified when [tests: helperNuncaSorteiaOUltimoDia, helperEmFevereiroBissextoUsaIntervaloDe29, helperDesfazTrocaDeDiaSemSortear, helperAceitaTrocaDeMesESorteiaDeNovo, helperSemDataAproximadaSoLimitaPelaVisita] and their unit tests pass
- [ ] 1.4 Implement `IndicatorPanel.rows(for:)` e `percentileBarValue` (port de `IndicatorDisplayPanel.DisplayResult` e `SetZLabelColor`); verified when [tests: zEPercentilFormatadosComVirgula, percentilAlemDe3DPMostraND, gravidadeAltaParaZMenos2v35, gravidadeIndefinidaParaZNulo, empateDaBarraArredondaParaPar, barraSemPercentilUsa100Zero50] pass
- [ ] 1.5 Refactor `Sources/AnthroFeatures/Common/` e `IndicatorPanel/`; full suite stays green (`swift test`)

## 2. Modelo da Calculadora

- [ ] 2.1 Implement estado inicial e recálculo de `CalculatorModel` (port de `ACMain()`, `ACMain_Load`, `UpdateIndicators`); verified when [tests: aberturaComValoresPadraoUsaSeisAnosMeninaVinteQuilos, novaCalculadoraNaoHerdaValoresVoltaAVinteQuilos, trocaDeSexoRecalculaComOMotor, pesoApagadoAnulaPesoEImcMantemEstatura] pass
- [ ] 2.2 Implement limites de datas e data aproximada no `CalculatorModel`, delegando a `ApproximateBirthDate` com sorteador injetado (port de `dtpDateOfVisit_ValueChanged`, `dtpDateOfBirth_ValueChanged`, `cbDateIsApprox_CheckStateChanged`); verified when [tests: visitaMovidaParaAntesDoNascimentoPuxaNascimento, nascimentoInformadoDepoisDaVisitaFicaNaVisita, sorteioEmFevereiroDe2021UsaIntervaloSemUltimoDia, sorteioQueUltrapassaAVisitaFicaNaVisita, trocaDeMesAceitaComNovoSorteio, trocaDeDiaDesfeitaMantemDataAnterior] pass
- [ ] 2.3 Implement modo de medida por idade (port de `ACMain.RefreshAge`); verified when [tests: escolhaHabilitadaCom334Dias, escolhaDesabilitadaCom335DiasForcaEmPe, criancaDe30MesesSemEscolhaContraAAjuda] pass
- [ ] 2.4 Implement campos de peso e medida com `MeasurementInput.evaluate`, valor `nil` para o cálculo e `weightIssue`/`lengthOrHeightIssue` para o aviso inline (política única, D2); verified when [tests: pesoTruncadoNaoArredondado, valoresForaDosLimitesEsvaziamOCampo, avisoDePesoForaDoIntervalo, avisoSomeComValorValido, avisoDeMedidaInvalida] pass
- [ ] 2.5 Implement texto do IMC, linhas do painel e rótulo de comprimento ou estatura; verified when [tests: imcDe20kgE110cmAosSeisAnosMostra16v5, imcIndisponivelMostraND, seisAnosMostraEstaturaParaIdade, quinzeMesesMedidoEmPeMostraComprimento] pass
- [ ] 2.6 Implement `nextFocus(after:)` (port de `FormX.PreFilterMessage` com a ordem de tabulação de `ACMain`) e `makeChart(for:)`; verified when [tests: enterDoPesoVaiParaAMedida, enterPulaModoDeMedidaDesabilitado, enterVoltaAoInicioEDesligadoMantemFoco, graficoDeImcAbreComUmResultado, graficoSemMedidaCalculavelFicaVazio] pass (os dois testes de gráfico dependem do grupo 3 e ficam verdes ao fim dele)
- [ ] 2.7 Refactor `Sources/AnthroFeatures/Calculator/`; full suite stays green (`swift test`)

## 3. Modelo do gráfico de crescimento

- [ ] 3.1 Implement séries de DP e de percentis, marca de transição, faixas e títulos (port de `GraphDialog.DrawIndicatorGraph` e `GetOrdinateWorldMin`); verified when [tests: pesoParaIdadeSemLinhasDe1DP, imcParaIdadeComLinhasDe1DP, percentisDeEstaturaParaIdade, percentil50SobreAMediana, marcaDeTransicaoNoGraficoDeImc, pesoParaIdadeSemMarcaDeTransicao, faixaDosEixosDePesoParaIdade, faixaDosEixosDeImcParaIdade, titulosDosEixosDeEstaturaParaIdade] pass
- [ ] 3.2 Implement pontos, limite de idade, gráfico vazio e legenda (port de `GraphDialog.DrawMeasures`), unit tests first (inner loop) para a regra de fora do intervalo; verified when [tests: tituloDoGraficoVazioSemDados, pontoDeImcUsaImcExatoDaMedidaAjustada, resultadoSemZOmitidoDeixaGraficoVazio, pesoAos109MesesForaDoGrafico, soPontosForaDoIntervaloDeixamGraficoVazio, legendaNoModoZScore, legendaNoModoPercentilSemPercentil, legendaSemIdadeNoNascimento] and their unit tests pass
- [ ] 3.3 Implement ponto único ou vários pontos e troca de indicador e de modo (port de `InitToolStrip` e `RefreshGraph`); verified when [tests: tresVisitasComVariosPontos, pontoUnicoEntreTresVisitas, resultadoUnicoSemEscolhaDeVariosPontos, trocaDePesoParaImcRecalculaSeriesEFaixa, trocaDeModoDescartaOZoom] pass
- [ ] 3.4 Implement zoom, deslocamento e restauração (interações `RubberBandSelection`, `HorizontalDrag`, `VerticalDrag`, `OriginalDimensions`); verified when [tests: zoomERestauracao, selecaoDegeneradaIgnorada, deslocamentoHorizontalDe12Meses] pass
- [ ] 3.5 Refactor `Sources/AnthroFeatures/GrowthChart/`; full suite stays green (`swift test`)

## 4. Exportação do gráfico

- [ ] 4.1 Implement `ChartExport.pngData`, `pdfData`, `copy(_:to:)`, `printOperation(pdfData:)` e `suggestedFileName` (substitui `CopyToClipboard` e `Print` do NPlot); verified when [tests: copiaEmPngParaAreaDeTransferencia, copiaSemImagemNaoAlteraAreaDeTransferencia, exportacoesValidasPngPdfEImpressao, nomeDeArquivoSemBarra, pdfInvalidoParaImpressaoDevolveNil] pass
- [ ] 4.2 Refactor `ChartExport.swift`; full suite stays green (`swift test`)

## 5. Views SwiftUI

- [ ] 5.1 Implement `CalculatorView` e `IndicatorPanelView` em `Sources/AnthroPlusApp/Calculator/`, ligando campos a `@FocusState` com `nextFocus(after:)`, aviso inline de `weightIssue` e `lengthOrHeightIssue` com `issueMessage`, cores de `Severity` (D12) e botões de gráfico; ligar a seção `.calculator` da view raiz criada por `bootstrap-macos-app`; verified when `swift build` e `scripts/build-app.sh` terminam com código 0 e `codesign --verify build/AnthroPlus.app` passa
- [ ] 5.2 Implement `GrowthChartView` (Swift Charts com `chartXScale`/`chartYScale` nos domínios visíveis, `chartOverlay` para seleção e deslocamento com Shift) e `GrowthChartSheet` com a toolbar de indicador, modo, pontos, restaurar, copiar (`ImageRenderer` e `ChartExport.copy`), exportar e imprimir; verified when `swift build` e `scripts/build-app.sh` terminam com código 0
- [ ] 5.3 Checagem manual registrada no evidence.md: abrir o app, preencher o caso "IMC de 20 kg e 110 cm aos seis anos", conferir "16,5", abrir o gráfico de IMC, fazer zoom, restaurar e exportar PDF; full suite stays green (`swift test`)

## 6. Verification

- [ ] 6.1 Mutation check for anthropometric-calculator: trocar o limite de `ageInMonths < 11` por `< 61` em `CalculatorModel`, ver `criancaDe30MesesSemEscolhaContraAAjuda` falhar, reverter
- [ ] 6.2 Mutation check for growth-charts: trocar o limite de peso de `> 108` por `> 121` em `GrowthChartModel`, ver `pesoAos109MesesForaDoGrafico` falhar, reverter
- [ ] 6.3 Run the full suite fresh (`swift test`); all green, output free of errors and warnings

## Workflow follow-up

- Produce evidence.md (`openspec instructions evidence --change add-anthropometric-calculator`) and reach `DECISION: PASS`
- Archive the change
- Commits de autoria do usuário, sem linha Co-Authored-By
