# Tasks

## 0. Red gate

- [x] 0.1 Write every scenario test from tests.md (`PrevalenceCalculatorTests.swift`, `ConfidenceIntervalTests.swift`, `ClusterCIGoldenTests.swift`, `SurveyAnalysisInputTests.swift`, `DensityEstimationTests.swift`, `MeanSDBarsTests.swift`, `StandardReportTests.swift`, `EstimatesReportTests.swift`, `ReportFileTests.swift`, `SurveyAnalysisModelTests.swift`, `ReportLauncherTests.swift`), os builders de `Support/` e stubs with the exact signatures from Interface Under Test (valores neutros de D15, no logic); inclui `scripts/golden/generate_cluster_ci_golden.R` (pacote `survey` em `.rlib/`, semente fixa, 200 desenhos, cabeçalho com versões) e o arquivo gerado `Tests/AnthroAnalysisTests/ClusterCIGolden.generated.swift`, idêntico em duas execuções, porque o teste de paridade o lê
- [x] 0.2 Run the scenario tests (`swift test --filter "AnthroAnalysisTests|AnthroIOTests|AnthroFeaturesTests"`); confirm each FAILS BY ASSERTION (not import, syntax or collection errors; testes que indexam linhas falham no `#require`); record each failure excerpt in the ledger; registrar a linha N/A rodando a checagem mecânica e anotando o código de saída diferente de 0
- [x] 0.3 Commit tests, stubs, support builders, the golden script and the generated fixture only as `test(red): add-survey-analysis`; write the SHA in the ledger
- [x] 0.4 STOP: show the user the failing tests and wait for explicit approval before implementing; na mesma parada, confirmar a Open Question do peso para idade acima de 108 meses (design.md) (aprovado pelo Caio em 15/10/2026; regra dos 108 meses: fidelidade ao original)

## 1. Prevalências (survey-analysis)

- [x] 1.1 Implementar `PrevalenceCalculator.compute` na ordem de D2 (pré-filtro do banco global, filtro de idade, fator negativo, edema, descarte de z nulo ou implausível, acumulação, média e DP em `Double` com `decimal15`, prevalências com `Round1`, IC simples provisório pelo passo 2.1), unit tests first (inner loop: soma ponderada, NaN do DP, denominador com edema); verified when [tests: dezRegistrosDeImcComZConhecidos, nenhumRegistroComZValido, estaturaParaIdadeDosDezRegistros, classificacaoDosIndicadoresSoNegativos, registrosComPesosDiferentes, umUnicoRegistroTemDpZero, fatorNegativoViraUm, fatorZeroNaoConta, umCasoDeEdemaEmImc, edemaNaoAfetaEstatura, umRegistroImplausivelFicaDeFora, todosImplausiveisDaoNZero, pesoAbaixoDoMinimoNasEstimativas, medidaAusenteNaoEFiltrada] pass
- [x] 1.2 Implementar o ramo dos 108 meses de peso para idade e dos 228 meses (passo 3 de D2), antes da guarda de cluster; verified when [tests: pesoParaIdadeComCriancasDe110Meses, osMesmosRegistrosEmImc] pass
- [x] 1.3 Implementar `filtered`, `byAgeGroups` (regra de faixa de `GetPrevalencesValuesByAgeGroups`, filtro de sexo, descarte de peso fora de 11 a 228 meses) e `byCluster` (agrupamento, ordenação, 61 a 228 meses, sem filtro de faixa); verified when [tests: faixasFixasDe61A228Meses, idadeDesconhecidaNaoEntraEmFaixa, tresMeninosEDuasMeninas, sexoSemRegistrosDaNZero, bordasDeIdadeDoTotal, soRegistrosComCluster, clustersForaDeOrdemSaemOrdenados, semRegistrosElegiveisPorCluster] pass
- [x] 1.4 Refactor `PrevalenceCalculator` (extrair o acumulador por limiar, nomes); `swift test` stays green

## 2. Intervalos de confiança (survey-analysis)

- [x] 2.1 Implementar `ConfidenceIntervals.simple` (Wald com correção de continuidade, corte em [0, 1], `Round1` do percentual, total 0 dá `.unavailable`); verified when [tests: icDasPrevalenciasDosDezRegistros, limiteSuperiorCortadoEm100, icSimplesComTotalZero] pass
- [x] 2.2 Copiar a tabela de `InitTStudentValues` para `TStudentTable.swift` e implementar `tStudent`; verified when [tests: valoresDaTabelaT, valoresForaDaTabelaT] pass
- [x] 2.3 Implementar `ConfidenceIntervals.improvedCluster` e ligar a correção em `compute` (registro do cluster no passo 6 de D2, dicionários por limiar, `AnalysisError.noClusterData`), unit tests first (inner loop: resíduos somam zero, guarda de proporção extrema); verified when [tests: quatroClustersDeCincoCriancas, proporcaoNulaNaoTemIcPorCluster, umUnicoClusterNaoTemIc, clusterSoComRegistroImplausivelContaEmC, registroSemClusterNaCorrecaoEIgnorado, pesoParaIdadeDeCriancasSemClusterLancaErro, populacaoVaziaComCorrecaoNaoLanca] pass
- [x] 2.4 Rodar a paridade com o pacote `survey` e investigar cada desenho divergente pela causa raiz antes de qualquer ajuste; verified when [tests: paridadeDoIcPorClusterComPacoteSurvey] pass
- [x] 2.5 Refactor `ConfidenceIntervals`; `swift test` stays green

## 3. Séries dos gráficos (survey-graphs)

- [x] 3.1 Implementar `DensityEstimation.normalCurve` (passo `Double` acumulado, constante 2.718281828); verified when [tests: curvaNormalComResolucao500, curvaNormalComResolucaoPequena] pass
- [x] 3.2 Implementar `DensityEstimation.zScores` (plausibilidade padrão do AnthroCore) e `epanechnikov` (média e DP sem ponderação, largura, grade em `Decimal`, fator não positivo vira 1, `DensityError.zeroBandwidth`); verified when [tests: dozeZComTamanhoPonderado50, dozeZComFator1, fatoresZeroContamComoUm, umUnicoZDaCurvaVazia, todosOsZIguaisLancamLarguraZero, limitePadraoDePlausibilidadeNaDensidade] pass
- [x] 3.3 Implementar `MeanSDBars.byAgeGroup` e `byCluster` (posições, rótulos, haste com sinal, contagem arredondada por faixa e truncada por cluster, faixa vazia sem barra); verified when [tests: duasFaixasComMediasDeSinaisOpostos, faixaVaziaENFracionado, barrasDeDoisClusters] pass
- [x] 3.4 Refactor `DensityEstimation` e `MeanSDBars`; `swift test` stays green

## 4. Relatórios (survey-reports)

- [x] 4.1 Implementar `ReportStrings` (pt-BR de D11) e `ReportFormat` (vírgula, sem zeros à direita, zero sem sinal, espaço para `nil`, `CIToString`); verified when [tests: intervalosCalculadosFormatados, valoresEspeciaisFormatados] pass
- [x] 4.2 Implementar `SurveyReportWriter.standardReport` linha a linha a partir de `CreateExcelReport` e `GetReportForIndicator` (conjuntos, cabeçalhos, total, faixas fixas, faixas do inquérito, regra de peso em branco, Conjunto 4, notas), unit tests first (inner loop: rótulo "Total (a-b)" com e sem o limite 61, fim da última faixa); verified when [tests: aberturaEConjuntosDoRelatorioSemCorrecao, relatorioComCorrecaoPorCluster, cabecalhoDeImcParaIdade, cabecalhoDeEstaturaNoConjuntoPorCluster, totalDeImcDasDezCriancas, totalSemCriancasDe61A228Meses, faixasFixasDeEstatura, pesoParaIdadeEmFaixaAcimaDe108Meses, faixaDe96MesesEPrimeiraEUltimaFaixas, pesoParaIdadeNaFaixaDe120Meses, estaturaNosQuatroClusters, inqueritoSemClusterTemSoCabecalho, contagemDeCriancasComEdema, notasDaCorrecaoPorCluster] pass
- [x] 4.3 Implementar `SurveyReportWriter.estimatesReport` a partir de `GetWHOReport` (metadados, 18 colunas e tabulação final, N de estatura, peso em branco, linha de N 0, Conjunto 4 com guarda de 2 resultados); verified when [tests: aberturaDoRelatorioDeEstimativas, estimativasSemNotasDeCluster, totalEFaixaDe5A9Anos, faixaSemCriancasNasEstimativas, pesoParaIdadeSemDadosAcimaDe108Meses, totalDosQuatroClustersNasEstimativas, estimativasSemClustersTemSoCabecalho] pass
- [x] 4.4 Implementar `SurveyReport.text` e `table`, `defaultFileName` e `write` (UTF-16LE com BOM, CRLF); verified when [tests: bytesENomesDoArquivo, linhasECelulasDaTabela, linhaVaziaNaTabelaTemUmaCelula] pass
- [x] 4.5 Refactor `SurveyReportWriter` (helpers de linha por indicador, sem mudar formatos); `swift test` stays green

## 5. Modelo e telas (survey-graphs, survey-reports)

- [ ] 5.1 Implementar `ReportLauncher` e `WorkspaceReportOpener` (Excel, Numbers, padrão); verified when [tests: excelInstaladoAbreNoExcel, nenhumaPlanilhaInstaladaUsaPadrao] pass
- [ ] 5.2 Implementar `SurveyAnalysisInput.records` sobre `SurveyRecord` e `SurveyOptions` da change 5 (idade por `SurveyRecordEvaluation.ageInMonths`, z arredondados de `SurveyRecordEvaluation.result`, `flagged` só por `SurveyPlausibility.isFlagged(_:result:options:)`, sem limites próprios), unit tests first (inner loop: idade informada versus datas); verified when [tests: limiteDeImcDoInqueritoExcluiRegistro, limiteDosPadroesNaoAfetaAReferencia] pass
- [ ] 5.3 Implementar a parte de gráficos de `SurveyAnalysisModel` (mínimo de 12 registros, séries de densidade com rótulos e cores, erro de largura zero esvazia, barras, "(Sem dados)", zoom e restauração, `canCopyGraph`) e `L10n+SurveyAnalysis.swift`; verified when [tests: criancaAbaixoDe61MesesNaDensidade, rotuloDeTodasAsCriancas, meninosComZIguaisEsvaziamOGrafico, nenhumClusterDaGraficoVazio, onzeRegistrosBloqueiamResultados, dozeRegistrosSemZLiberamResultados, zoomERestauracao, retanguloDegeneradoEIgnorado, graficoVazioNaoECopiado] pass
- [ ] 5.4 Implementar `SurveyAnalysisModel.exportReport` (gera, grava, abre, mapeia `AnalysisError.noClusterData` e erros de gravação para as mensagens de `L10n.SurveyAnalysis`); verified when [tests: nomeEmBrancoEDestinoSemPermissao, correcaoPedidaSemClustersMostraErro, correcaoPedidaComClustersGravaArquivo] pass
- [ ] 5.5 Implementar `SurveyResultsView` (Swift Charts, seletor de indicador e filtro, zoom por arraste, Restaurar, Copiar gráfico, Imprimir gráfico), `SurveyReportTableView` e os dois botões de relatório com a pergunta "Deseja realizar a análise por cluster?" na toolbar do inquérito aberto da change 5; verified when a checagem N/A de "Comandos presentes na interface" (`scripts/build-app.sh` e `grep -a -c` das duas strings) devolve código 0 e a inspeção visual da aba com o inquérito de dez crianças fica registrada em evidence.md
- [ ] 5.6 Refactor `SurveyAnalysisModel` e views (sem regra de negócio nas views); `swift test` stays green

## 6. Verification

- [ ] 6.1 Mutation check for survey-analysis: trocar `> 108` por `> 120` no ramo de peso para idade, ver `pesoParaIdadeComCriancasDe110Meses` falhar, reverter
- [ ] 6.2 Mutation check for survey-analysis: remover o termo $1/(2n)$ de `ConfidenceIntervals.simple`, ver `icDasPrevalenciasDosDezRegistros` falhar, reverter
- [ ] 6.3 Mutation check for survey-reports: usar "próximo limite - 1" também na última faixa fixa, ver `faixasFixasDeEstatura` falhar, reverter
- [ ] 6.4 Mutation check for survey-graphs: gerar a grade da curva normal por índice inteiro, ver `curvaNormalComResolucao500` falhar, reverter
- [ ] 6.5 Run the full suite fresh (`swift test`) e a checagem N/A (`scripts/build-app.sh` mais `grep -a -c`); all green, output free of errors and warnings

## Workflow follow-up

- Produce evidence.md (`openspec instructions evidence --change add-survey-analysis`) and reach `DECISION: PASS`
- Registrar em `docs/reverse-engineering-findings.md` as divergências de D7 e D14 e a regra dos 108 meses
- Archive the change
