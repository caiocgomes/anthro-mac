# Tests

## Test Strategy

- **Framework**: swift-testing (`import Testing`, `@Test`, `#expect`, `#require`), Swift 6.1.
- **Full-suite command**: `swift test`
- **Conventions**: testes de cenário em `Tests/AnthroAnalysisTests/`, `Tests/AnthroIOTests/` e `Tests/AnthroFeaturesTests/`, um arquivo por grupo de requisitos; só a API pública da Interface Under Test (sem `@testable`). Registros construídos à mão por builders em `Tests/AnthroAnalysisTests/Support/AnalysisFixtures.swift` e `Tests/AnthroIOTests/Support/ReportFixtures.swift` (`tenChildren()`, `fourClusters()`, `record(age:z:...)`), já que targets de teste não compartilham código; opções sempre a partir de `SurveyOptions.default` da change 5, alterando só `ageGroupBoundaries` ou um limite de z. Os testes de consumo de `SurveyPlausibility` usam `SurveyRecord` reais e `AnthroEngine.shared()`, sem dublê. `Decimal` comparado por igualdade exata; `Double` por erro absoluto declarado no teste. Linhas de relatório comparadas como strings literais com `\t`; antes de indexar linhas, `#require(report.lines.count > i)`. A fixture dourada do IC por cluster é código Swift gerado (`ClusterCIGolden.generated.swift`), sem recurso no `Package.swift`. O modelo `@MainActor` é testado em funções `@MainActor`. `ReportOpening` é substituído por um dublê que registra chamadas (dependência externa: NSWorkspace), nunca o código sob teste.
- **Mutation tool**: manual (aplicar a mutação de "Breaks if", ver o teste falhar, reverter).

## Cálculos de referência

Todos os valores esperados abaixo foram calculados à mão e conferidos por uma emulação descartável em Python do C# decompilado (`decimal` com 28 e com 38 dígitos, conversões `double` para `decimal` com 15 dígitos), e o IC por cluster também pelo pacote R `survey` 4.5.

- **Dez registros** (z -3.5, -2.5, -2.1, -1.0, 0.0, 0.5, 1.2, 2.2, 3.1, 0.0; fator 1): < -3 = 1/10 = 10; < -2 = 3/10 = 30; > +1 = 3/10 = 30 (1.2, 2.2, 3.1); > +2 = 20; > +3 = 10. Média = (-9.1 + 7.0)/10 = -0.21. $\sum (z + 0.21)^2$ = 39.609; DP = $\sqrt{39.609/9}$ = 2.0978560 (2.1 com `Round2`).
- **IC simples dos dez**: $p = 0.3$: $1.96\sqrt{0.021} + 0.05$ = 0.3340310, intervalo (0, 0.6340) = (0, 63.4). $p = 0.1$: 0.2359419, (0, 33.6). $p = 0.2$: 0.2979226, (0, 49.8).
- **Pesos 2, 1, 1** (z -2.5, 0, 1): N = 4; média = -4/4 = -1; $\sum w (z - m)^2$ = 2(2.25) + 1 + 4 = 9.5; DP = $\sqrt{9.5/3}$ = 1.7795130 (1.78). IC de $p = 0.5$, $n = 4$: $1.96 \cdot 0.25 + 0.125$ = 0.615, cortado em (0, 1).
- **Edema em IMC** (9 com z, sem o -3.5, mais 1 com edema): < -3 = 1/10; < -2 = 3/10 (-2.5, -2.1 e o edema); média = 1.4/9 = 0.1556 (0.16); DP = 1.8568193 (1.86). **Estatura** com z -2.5 no registro com edema: N = 10, < -2 = 3/10, média = (1.4 - 2.5)/10 = -0.11.
- **Peso aos 110 meses**: N = 4 (dois com z, dois só no N); < -2 = 1/4 = 25; média = (-2.5 + 0.5)/4 = -0.5. **IMC** com os mesmos z: < -3 = 1/4, < -2 = 2/4, média = -4.2/4 = -1.05.
- **Quatro clusters** (5 por cluster, 1, 2, 0 e 1 casos de z -2.5): $C = 4$, $\bar n = 5$, $\bar y = 1$, $p = 0.2$; $u_c$ = 0, 0.2, -0.2, 0; $\sum u^2$ = 0.08; $s = \sqrt{0.08/12}$ = 0.0816497; $t_3$ = 3.18244630528371; meia-largura no logit = 1.6240490; $\mathrm{logit}(0.2)$ = -1.3862944; limites 0.046961 e 0.559157, isto é (4.7, 55.9). R: `svyciprop(method = "logit")` dá (4.6961, 55.9157).
- **Quinto cluster só com implausível**: $C = 5$, $\bar n = 4$, $\bar y = 0.8$; $u_c$ = 0, 0.25, -0.25, 0, 0; $s = \sqrt{0.125/20}$ = 0.0790569; $t_4$ = 2.7764451051978; meia-largura = 1.3718660; limites 0.059627 e 0.496393, isto é (6, 49.6).
- **Clusters no relatório** (IC simples por cluster, $n = 5$): $p = 0$ dá (0, 10); $p = 0.2$ dá $1.96\sqrt{0.032} + 0.1$ = 0.4506, (0, 65.1); $p = 0.4$ dá (0, 92.9). Total com cluster, $n = 20$: $p = 0$ dá (0, 2.5); $p = 0.2$ dá (0, 40).
- **Densidade dos doze z**: média 0; $\sum z^2$ = 15.125; $s = \sqrt{15.125/11}$ = 1.1726039; $12^{0.2}$ = 1.6437518; $h$ = 0.6420334. Com fatores 4 e 5: $W$ = 50, passo 0.2, 51 pontos; em $x = 0$ só entram $|z| \leq 1$ ($|u| < \sqrt 5$), somando 9.67500 / (50 h) = 0.301381. Com fator 1: $W$ = 12, passo 10/12, grade de -5 até o primeiro ponto não menor que 5 + passo, 14 pontos (o 14º, 5.8333, entra porque a soma acumulada de 13 passos truncados fica abaixo de 5 + passo nas duas precisões); y no ponto mais próximo de 0 = 0.292832.
- **Normal com resolução 500**: passo `Double` 0.02 acumulado; o 501º x é 4.99999999999996 < 5, por isso 501 pontos; y(-5) = $2.718281828^{-12.5}/\sqrt{2\pi}$ = 1.4867195178726e-6; máximo 0.3989422804.
- **Barras**: z -1 e -2 dão média -1.5 e DP $\sqrt{0.5}$ = 0.7071068, haste em -2.2071; z 1 e 2 dão 1.5 e 2.2071. Fator 1.5: `Round(1.5, 0)` = 2 por faixa, `(int)1.5` = 1 por cluster.

## Spec-to-Test Mapping

### Capability: survey-analysis

#### Scenario: Dez registros de IMC com z conhecidos
- **Test name**: dezRegistrosDeImcComZConhecidos
- **Test file**: Tests/AnthroAnalysisTests/PrevalenceCalculatorTests.swift
- **Level**: acceptance
- **Breaks if**: os limiares viram faixas exclusivas (> +1 deixa de incluir os casos > +2 e > +3, dando 10 em vez de 30).
- **Expected red**: expected count 10 and prevalences [10, 30, 30, 20, 10], got count 0 and prevalences [:]

#### Scenario: Nenhum registro com z válido
- **Test name**: nenhumRegistroComZValido
- **Test file**: Tests/AnthroAnalysisTests/PrevalenceCalculatorTests.swift
- **Level**: acceptance
- **Breaks if**: com N = 0 o IC deixa de ser calculado com total 0 (deveria dar `.unavailable`) ou a prevalência vira 0 em vez de `nil`.
- **Expected red**: expected interval(.belowMinus2) == .unavailable, got .notComputed

#### Scenario: Estatura para idade dos dez registros
- **Test name**: estaturaParaIdadeDosDezRegistros
- **Test file**: Tests/AnthroAnalysisTests/PrevalenceCalculatorTests.swift
- **Level**: acceptance
- **Breaks if**: `computeOnlyNegative` devolve `false` para estatura, calculando > +1.
- **Expected red**: expected prevalence(.belowMinus3) == 10, got nil

#### Scenario: Classificação dos indicadores
- **Test name**: classificacaoDosIndicadoresSoNegativos
- **Test file**: Tests/AnthroAnalysisTests/PrevalenceCalculatorTests.swift
- **Level**: acceptance
- **Breaks if**: peso para idade sai da lista de indicadores só negativos.
- **Expected red**: expected computeOnlyNegative(.weightForAge) == true, got false

#### Scenario: Registros com pesos diferentes
- **Test name**: registrosComPesosDiferentes
- **Test file**: Tests/AnthroAnalysisTests/PrevalenceCalculatorTests.swift
- **Level**: acceptance
- **Breaks if**: a média divide pelo número de registros (3) em vez da soma dos fatores (4), ou o DP ignora o fator.
- **Expected red**: expected count 4, mean -1, round(sd, 2) 1.78, got count 0, mean nil

#### Scenario: Um único registro
- **Test name**: umUnicoRegistroTemDpZero
- **Test file**: Tests/AnthroAnalysisTests/PrevalenceCalculatorTests.swift
- **Level**: acceptance
- **Breaks if**: o NaN de 0/0 não é convertido em 0 (DP `nil` ou crash).
- **Expected red**: expected standardDeviation 0, got nil

#### Scenario: Fator negativo vira 1
- **Test name**: fatorNegativoViraUm
- **Test file**: Tests/AnthroAnalysisTests/PrevalenceCalculatorTests.swift
- **Level**: acceptance
- **Breaks if**: a substituição de fator negativo é removida (N = -1).
- **Expected red**: expected count 3 and prevalence(.belowMinus2) 33.3, got count 0 and nil

#### Scenario: Fator zero não conta
- **Test name**: fatorZeroNaoConta
- **Test file**: Tests/AnthroAnalysisTests/PrevalenceCalculatorTests.swift
- **Level**: acceptance
- **Breaks if**: a regra de substituição usa `<= 0` em vez de `< 0`.
- **Expected red**: expected count 2, prevalence(.belowMinus2) 0, mean 0.5, got count 0, nil, nil

#### Scenario: Um caso de edema em IMC
- **Test name**: umCasoDeEdemaEmImc
- **Test file**: Tests/AnthroAnalysisTests/PrevalenceCalculatorTests.swift
- **Level**: acceptance
- **Breaks if**: o edema deixa de somar ao numerador de < -3 ou entra na média.
- **Expected red**: expected count 9, oedemaCount 1, prevalences < -3 10 and < -2 30, mean 0.16, got count 0, oedemaCount 0

#### Scenario: Edema não afeta estatura
- **Test name**: edemaNaoAfetaEstatura
- **Test file**: Tests/AnthroAnalysisTests/PrevalenceCalculatorTests.swift
- **Level**: acceptance
- **Breaks if**: o ramo de edema passa a valer para estatura para idade.
- **Expected red**: expected count 10, oedemaCount 0, prevalence(.belowMinus2) 30, mean -0.11, got count 0

#### Scenario: Um registro implausível
- **Test name**: umRegistroImplausivelFicaDeFora
- **Test file**: Tests/AnthroAnalysisTests/PrevalenceCalculatorTests.swift
- **Level**: acceptance
- **Breaks if**: a checagem de `flagged` é removida.
- **Expected red**: expected count 2, prevalence(.belowMinus2) 50, mean -0.75, got count 0

#### Scenario: Todos implausíveis
- **Test name**: todosImplausiveisDaoNZero
- **Test file**: Tests/AnthroAnalysisTests/PrevalenceCalculatorTests.swift
- **Level**: acceptance
- **Breaks if**: com N = 0 o IC não é calculado com total 0.
- **Expected red**: expected interval(.belowMinus2) == .unavailable, got .notComputed

#### Scenario: Peso para idade com crianças de 110 meses
- **Test name**: pesoParaIdadeComCriancasDe110Meses
- **Test file**: Tests/AnthroAnalysisTests/PrevalenceCalculatorTests.swift
- **Level**: acceptance
- **Breaks if**: o limite 108 vira 120 (o z -3.2 entraria), ou os registros acima de 108 meses deixam de somar a N.
- **Expected red**: expected count 4, prevalence(.belowMinus2) 25, mean -0.5, got count 0

#### Scenario: Os mesmos registros em IMC
- **Test name**: osMesmosRegistrosEmImc
- **Test file**: Tests/AnthroAnalysisTests/PrevalenceCalculatorTests.swift
- **Level**: acceptance
- **Breaks if**: a regra dos 108 meses passa a valer para todos os indicadores.
- **Expected red**: expected count 4, prevalences < -3 25 and < -2 50, mean -1.05, got count 0

#### Scenario: IC das prevalências dos dez registros
- **Test name**: icDasPrevalenciasDosDezRegistros
- **Test file**: Tests/AnthroAnalysisTests/ConfidenceIntervalTests.swift
- **Level**: acceptance
- **Breaks if**: a correção de continuidade $1/(2n)$ é removida (limite superior 58.4 em vez de 63.4).
- **Expected red**: expected .interval(low: 0, high: 63.4), got .notComputed

#### Scenario: Limite superior cortado em 100
- **Test name**: limiteSuperiorCortadoEm100
- **Test file**: Tests/AnthroAnalysisTests/ConfidenceIntervalTests.swift
- **Level**: acceptance
- **Breaks if**: o corte em 1 é removido (limite 111.5).
- **Expected red**: expected .interval(low: 0, high: 100), got .notComputed

#### Scenario: Total zero
- **Test name**: icSimplesComTotalZero
- **Test file**: Tests/AnthroAnalysisTests/ConfidenceIntervalTests.swift
- **Level**: acceptance
- **Breaks if**: total 0 cai na fórmula (divisão por zero) em vez de devolver `.unavailable`.
- **Expected red**: expected .unavailable, got .notComputed

#### Scenario: Quatro clusters de cinco crianças
- **Test name**: quatroClustersDeCincoCriancas
- **Test file**: Tests/AnthroAnalysisTests/ConfidenceIntervalTests.swift
- **Level**: acceptance
- **Breaks if**: o erro usa $C^2$ em vez de $C(C-1)$, ou t de $C$ em vez de $C - 1$ graus de liberdade.
- **Expected red**: expected prevalence 20 and .interval(low: 4.7, high: 55.9), got nil and .notComputed

#### Scenario: Paridade com o pacote R survey
- **Test name**: paridadeDoIcPorClusterComPacoteSurvey
- **Test file**: Tests/AnthroAnalysisTests/ClusterCIGoldenTests.swift
- **Level**: acceptance
- **Breaks if**: a transformação logit é trocada por Wald na escala de proporção.
- **Expected red**: expected 200 designs within 0.1 and at least 198 identical, got 0 identical (every interval .notComputed)

#### Scenario: Proporção nula
- **Test name**: proporcaoNulaNaoTemIcPorCluster
- **Test file**: Tests/AnthroAnalysisTests/ConfidenceIntervalTests.swift
- **Level**: acceptance
- **Breaks if**: a guarda $p \leq 0.00005$ é removida (logit de 0 vira menos infinito).
- **Expected red**: expected interval(.belowMinus3) == .unavailable, got .notComputed

#### Scenario: Um único cluster
- **Test name**: umUnicoClusterNaoTemIc
- **Test file**: Tests/AnthroAnalysisTests/ConfidenceIntervalTests.swift
- **Level**: acceptance
- **Breaks if**: t para 0 graus de liberdade devolve 1.96 em vez de `nil`.
- **Expected red**: expected prevalence 40 and .singleCluster, got nil and .notComputed

#### Scenario: Valores da tabela
- **Test name**: valoresDaTabelaT
- **Test file**: Tests/AnthroAnalysisTests/ConfidenceIntervalTests.swift
- **Level**: acceptance
- **Breaks if**: a tabela fica deslocada de uma linha (t de 3 lê o valor de 2).
- **Expected red**: expected 3.18244630528371 and 1.97189622363389, got nil and nil

#### Scenario: Fora da tabela
- **Test name**: valoresForaDaTabelaT
- **Test file**: Tests/AnthroAnalysisTests/ConfidenceIntervalTests.swift
- **Level**: acceptance
- **Breaks if**: acima de 200 o código devolve `nil` ou o último valor da tabela.
- **Expected red**: expected tStudent(201) == 1.96, got nil

#### Scenario: Cluster só com registro implausível
- **Test name**: clusterSoComRegistroImplausivelContaEmC
- **Test file**: Tests/AnthroAnalysisTests/ConfidenceIntervalTests.swift
- **Level**: acceptance
- **Breaks if**: o cluster é registrado só depois da checagem de plausibilidade ($C$ = 4, IC 4.7 a 55.9).
- **Expected red**: expected count 20 and .interval(low: 6, high: 49.6), got count 0 and .notComputed

#### Scenario: Registro sem cluster na correção
- **Test name**: registroSemClusterNaCorrecaoEIgnorado
- **Test file**: Tests/AnthroAnalysisTests/ConfidenceIntervalTests.swift
- **Level**: acceptance
- **Breaks if**: a guarda "com correção, descarte sem cluster" é removida (N = 21).
- **Expected red**: expected count 20 and .interval(low: 4.7, high: 55.9), got count 0 and .notComputed

#### Scenario: Peso para idade de crianças sem cluster
- **Test name**: pesoParaIdadeDeCriancasSemClusterLancaErro
- **Test file**: Tests/AnthroAnalysisTests/PrevalenceCalculatorTests.swift
- **Level**: acceptance
- **Breaks if**: a checagem de "sem dados de cluster" é removida ou feita antes do ramo dos 108 meses.
- **Expected red**: expected error AnalysisError.noClusterData, got no error

#### Scenario: População vazia com correção
- **Test name**: populacaoVaziaComCorrecaoNaoLanca
- **Test file**: Tests/AnthroAnalysisTests/PrevalenceCalculatorTests.swift
- **Level**: acceptance
- **Breaks if**: o erro é lançado sempre que não há clusters, mesmo com N + N com edema = 0.
- **Expected red**: expected interval(.belowMinus2) == .unavailable, got .notComputed

#### Scenario: Faixas fixas de 61 a 228 meses
- **Test name**: faixasFixasDe61A228Meses
- **Test file**: Tests/AnthroAnalysisTests/PrevalenceCalculatorTests.swift
- **Level**: acceptance
- **Breaks if**: o descarte por parte inteira acima do último limite usa a idade decimal (228.5 seria descartado) ou o agrupamento usa `>` em vez de `>=`.
- **Expected red**: expected counts [2, 1, 1], got []

#### Scenario: Idade desconhecida
- **Test name**: idadeDesconhecidaNaoEntraEmFaixa
- **Test file**: Tests/AnthroAnalysisTests/PrevalenceCalculatorTests.swift
- **Level**: acceptance
- **Breaks if**: idade `nil` é tratada como 0 e cai na primeira faixa.
- **Expected red**: expected 3 results with count 0, got 0 results

#### Scenario: Três meninos e duas meninas
- **Test name**: tresMeninosEDuasMeninas
- **Test file**: Tests/AnthroAnalysisTests/PrevalenceCalculatorTests.swift
- **Level**: acceptance
- **Breaks if**: o filtro de sexo é ignorado ou o registro sem sexo é descartado também sem filtro.
- **Expected red**: expected counts boys 3, girls 2, all 6, got empty results

#### Scenario: Sexo sem registros
- **Test name**: sexoSemRegistrosDaNZero
- **Test file**: Tests/AnthroAnalysisTests/PrevalenceCalculatorTests.swift
- **Level**: acceptance
- **Breaks if**: faixas sem registros são omitidas da lista.
- **Expected red**: expected 1 result with count 0, got 0 results

#### Scenario: Bordas de idade do total
- **Test name**: bordasDeIdadeDoTotal
- **Test file**: Tests/AnthroAnalysisTests/PrevalenceCalculatorTests.swift
- **Level**: acceptance
- **Breaks if**: o filtro usa parte inteira (228.01 entraria) ou `>` 61 (61 sairia).
- **Expected red**: expected ages [61, 228], got []

#### Scenario: Só registros com cluster
- **Test name**: soRegistrosComCluster
- **Test file**: Tests/AnthroAnalysisTests/PrevalenceCalculatorTests.swift
- **Level**: acceptance
- **Breaks if**: `onlyWithCluster` é ignorado.
- **Expected red**: expected clusters [3], got []

#### Scenario: Clusters fora de ordem
- **Test name**: clustersForaDeOrdemSaemOrdenados
- **Test file**: Tests/AnthroAnalysisTests/PrevalenceCalculatorTests.swift
- **Level**: acceptance
- **Breaks if**: a ordenação dos números de cluster é removida (ordem de aparição 7, 2, 5).
- **Expected red**: expected clusters [2, 5, 7] with counts [1, 1, 2], got []

#### Scenario: Sem registros elegíveis
- **Test name**: semRegistrosElegiveisPorCluster
- **Test file**: Tests/AnthroAnalysisTests/PrevalenceCalculatorTests.swift
- **Level**: acceptance
- **Breaks if**: o filtro de 61 a 228 meses da análise por cluster é removido (cluster 4 apareceria).
- **Expected red**: expected [ClusterPrevalence(cluster: 9, count 1)], got []

#### Scenario: Peso abaixo do mínimo
- **Test name**: pesoAbaixoDoMinimoNasEstimativas
- **Test file**: Tests/AnthroAnalysisTests/PrevalenceCalculatorTests.swift
- **Level**: acceptance
- **Breaks if**: o pré-filtro de medidas passa a valer também para a análise padrão, ou deixa de valer para a do banco global.
- **Expected red**: expected global count 1 and standard count 2, got 0 and 0

#### Scenario: Medida ausente não é filtrada
- **Test name**: medidaAusenteNaoEFiltrada
- **Test file**: Tests/AnthroAnalysisTests/PrevalenceCalculatorTests.swift
- **Level**: acceptance
- **Breaks if**: peso `nil` é tratado como 0 e cai abaixo de 0.9.
- **Expected red**: expected count 1 and prevalence(.belowMinus2) 100, got count 0 and nil

#### Scenario: Limite de IMC do inquérito exclui registro
- **Test name**: limiteDeImcDoInqueritoExcluiRegistro
- **Test file**: Tests/AnthroFeaturesTests/SurveyAnalysisInputTests.swift
- **Level**: integration
- **Breaks if**: `SurveyAnalysisInput` deixa de chamar `SurveyPlausibility.isFlagged` com as opções do inquérito (ou passa `SurveyOptions.default`), e o z 2.00 continua no N.
- **Expected red**: expected count 2 with default options and count 1 with referenceMaxZ[BMI] = 1.0, got count 0 and 0 (adapter stub returns no records)
- **Nota**: a função `SurveyPlausibility` em si é coberta pelos cenários da change `add-nutritional-survey` (requisitos de plausibilidade e "Peso para idade acima de 108 meses nunca é implausível"); aqui só se verifica o consumo. Linha usada: IMC de referência, menino, 96 meses, L = -1.4629, M = 15.7368, S = 0.09526; 26.60 kg e 130 cm dão IMC 15.7396 e z 0.0019; 33.25 kg dão IMC 19.6746 e z 1.9999.

#### Scenario: Limite dos padrões não afeta a referência
- **Test name**: limiteDosPadroesNaoAfetaAReferencia
- **Test file**: Tests/AnthroFeaturesTests/SurveyAnalysisInputTests.swift
- **Level**: integration
- **Breaks if**: o adaptador monta as flags com a lista de limites da faixa errada (padrões no lugar de referência) em vez de delegar a `SurveyPlausibility` com o resultado do registro.
- **Expected red**: expected count 2 and prevalence(.abovePlus1) 50, got count 0 and nil

### Capability: survey-reports

#### Scenario: Abertura e conjuntos do relatório sem correção
- **Test name**: aberturaEConjuntosDoRelatorioSemCorrecao
- **Test file**: Tests/AnthroIOTests/StandardReportTests.swift
- **Level**: acceptance
- **Breaks if**: o asterisco depois da linha de tabelas some, ou o Conjunto 4 deixa de sair sem correção.
- **Expected red**: #require(report.lines.count > 3) failed: lines.count is 0

#### Scenario: Relatório com correção por cluster
- **Test name**: relatorioComCorrecaoPorCluster
- **Test file**: Tests/AnthroIOTests/StandardReportTests.swift
- **Level**: acceptance
- **Breaks if**: o Conjunto 4 é gerado também com correção, ou as notas "-) " e ".) " são omitidas.
- **Expected red**: #require(report.lines.count >= 2) failed: lines.count is 0

#### Scenario: Cabeçalho de IMC para idade
- **Test name**: cabecalhoDeImcParaIdade
- **Test file**: Tests/AnthroIOTests/StandardReportTests.swift
- **Level**: acceptance
- **Breaks if**: IMC usa o cabeçalho só negativo (sem as colunas > +1, > +2, > +3).
- **Expected red**: expected line "Faixas etárias\t\tN\tIMC para idade (%)" present, got no lines

#### Scenario: Cabeçalho de estatura no conjunto por cluster
- **Test name**: cabecalhoDeEstaturaNoConjuntoPorCluster
- **Test file**: Tests/AnthroIOTests/StandardReportTests.swift
- **Level**: acceptance
- **Breaks if**: o Conjunto 4 mantém "Anos" e "Meses" no cabeçalho de colunas.
- **Expected red**: expected line "Cluster\t\tN\tComprimento/estatura para idade (%)" present, got no lines

#### Scenario: Total de IMC das dez crianças
- **Test name**: totalDeImcDasDezCriancas
- **Test file**: Tests/AnthroIOTests/StandardReportTests.swift
- **Level**: acceptance
- **Breaks if**: o rótulo do total usa o primeiro limite das faixas (0) em vez do limite 61, ou o total de peso deixa de sair em branco.
- **Expected red**: expected the BMI total line string, got no lines

#### Scenario: Total sem crianças de 61 a 228 meses
- **Test name**: totalSemCriancasDe61A228Meses
- **Test file**: Tests/AnthroIOTests/StandardReportTests.swift
- **Level**: acceptance
- **Breaks if**: a população do total deixa de ser filtrada por 61 a 228 meses.
- **Expected red**: expected line "Total\t\t0" in height section, got no lines

#### Scenario: Faixas fixas de estatura
- **Test name**: faixasFixasDeEstatura
- **Test file**: Tests/AnthroIOTests/StandardReportTests.swift
- **Level**: acceptance
- **Breaks if**: o fim da última faixa fixa usa "próximo - 1" (180-227) ou as faixas vazias imprimem N 0.
- **Expected red**: expected three sliced lines, got no lines

#### Scenario: Peso para idade em faixa acima de 108 meses
- **Test name**: pesoParaIdadeEmFaixaAcimaDe108Meses
- **Test file**: Tests/AnthroIOTests/StandardReportTests.swift
- **Level**: acceptance
- **Breaks if**: a regra de linha vazia de peso (início acima de 108) é removida.
- **Expected red**: expected line "Total (10-14)\t(120-179)\t" in weight section, got no lines

#### Scenario: Faixa de 96 meses e primeira e última faixas
- **Test name**: faixaDe96MesesEPrimeiraEUltimaFaixas
- **Test file**: Tests/AnthroIOTests/StandardReportTests.swift
- **Level**: acceptance
- **Breaks if**: a última faixa usa "próximo - 1" (228-227) ou os anos usam arredondamento em vez de divisão inteira.
- **Expected red**: expected lines "8\t(96-107)\t10...", "0\t(0-5)\t", "19\t(228-228)\t", got no lines

#### Scenario: Peso para idade na faixa de 120 meses
- **Test name**: pesoParaIdadeNaFaixaDe120Meses
- **Test file**: Tests/AnthroIOTests/StandardReportTests.swift
- **Level**: acceptance
- **Breaks if**: a regra de peso em branco é aplicada só às faixas fixas.
- **Expected red**: expected line "10\t(120-131)\t" in weight section, got no lines

#### Scenario: Intervalos calculados
- **Test name**: intervalosCalculadosFormatados
- **Test file**: Tests/AnthroIOTests/ReportFileTests.swift
- **Level**: acceptance
- **Breaks if**: o formato usa ponto decimal ou mantém zeros à direita ("100,0%").
- **Expected red**: expected "(4,7%, 55,9%)", got ""

#### Scenario: Valores especiais
- **Test name**: valoresEspeciaisFormatados
- **Test file**: Tests/AnthroIOTests/ReportFileTests.swift
- **Level**: acceptance
- **Breaks if**: `nil` vira string vazia em vez de espaço, ou zero negativo sai "-0".
- **Expected red**: expected "(-, -)", got ""

#### Scenario: Estatura nos quatro clusters
- **Test name**: estaturaNosQuatroClusters
- **Test file**: Tests/AnthroIOTests/StandardReportTests.swift
- **Level**: acceptance
- **Breaks if**: as linhas de cluster usam IC com correção, ou o cluster 3 (sem casos) é omitido por prevalência 0.
- **Expected red**: expected five cluster-set lines, got no lines

#### Scenario: Inquérito sem cluster
- **Test name**: inqueritoSemClusterTemSoCabecalho
- **Test file**: Tests/AnthroIOTests/StandardReportTests.swift
- **Level**: acceptance
- **Breaks if**: a linha "Total" do conjunto por cluster é impressa com N 0.
- **Expected red**: #require(set4 height header found) failed

#### Scenario: Contagem de crianças com edema
- **Test name**: contagemDeCriancasComEdema
- **Test file**: Tests/AnthroIOTests/StandardReportTests.swift
- **Level**: acceptance
- **Breaks if**: a contagem de edema usa só os registros de 61 a 228 meses (no teste, um dos dois registros com edema tem 40 meses, então a contagem filtrada daria 1).
- **Expected red**: expected oedema-count line with 2, got no lines

#### Scenario: Notas da correção por cluster
- **Test name**: notasDaCorrecaoPorCluster
- **Test file**: Tests/AnthroIOTests/StandardReportTests.swift
- **Level**: acceptance
- **Breaks if**: a ordem das duas notas é invertida.
- **Expected red**: #require(report.lines.count >= 2) failed: lines.count is 0

#### Scenario: Abertura do relatório de estimativas
- **Test name**: aberturaDoRelatorioDeEstimativas
- **Test file**: Tests/AnthroIOTests/EstimatesReportTests.swift
- **Level**: acceptance
- **Breaks if**: as quatro linhas de metadados (País, Referência, Nível administrativo, Mês e ano) somem ou perdem os dois-pontos.
- **Expected red**: #require(report.lines.count >= 8) failed: lines.count is 0

#### Scenario: Estimativas sem notas de cluster
- **Test name**: estimativasSemNotasDeCluster
- **Test file**: Tests/AnthroIOTests/EstimatesReportTests.swift
- **Level**: acceptance
- **Breaks if**: as notas de correção por cluster entram nas estimativas.
- **Expected red**: #require(report.lines.last != nil) failed

#### Scenario: Total e faixa de 5 a 9 anos
- **Test name**: totalEFaixaDe5A9Anos
- **Test file**: Tests/AnthroIOTests/EstimatesReportTests.swift
- **Level**: acceptance
- **Breaks if**: o peso deixa de sair em branco no total sem cluster, ou a tabulação final das linhas some.
- **Expected red**: expected the two Set 1 lines, got no lines

#### Scenario: Faixa sem crianças
- **Test name**: faixaSemCriancasNasEstimativas
- **Test file**: Tests/AnthroIOTests/EstimatesReportTests.swift
- **Level**: acceptance
- **Breaks if**: a linha de N = 0 perde a tabulação final (15 em vez de 16 tabulações).
- **Expected red**: expected line "Total (10-14)\t(120-179)\t0" + 16 tabs, got no lines

#### Scenario: Peso para idade sem dados acima de 108 meses
- **Test name**: pesoParaIdadeSemDadosAcimaDe108Meses
- **Test file**: Tests/AnthroIOTests/EstimatesReportTests.swift
- **Level**: acceptance
- **Breaks if**: a regra "quatro valores de peso iguais a 0 deixam o peso em branco" é removida (sairiam "0\t0\t0\t0").
- **Expected red**: #require(line starting "10\t(120-131)") failed

#### Scenario: Total dos quatro clusters
- **Test name**: totalDosQuatroClustersNasEstimativas
- **Test file**: Tests/AnthroIOTests/EstimatesReportTests.swift
- **Level**: acceptance
- **Breaks if**: o total por cluster deixa o peso em branco como o total sem cluster.
- **Expected red**: expected a line starting "Total\t\t20\t0\t20\t", got no lines

#### Scenario: Estimativas sem clusters
- **Test name**: estimativasSemClustersTemSoCabecalho
- **Test file**: Tests/AnthroIOTests/EstimatesReportTests.swift
- **Level**: acceptance
- **Breaks if**: a guarda "menos de 2 resultados no conjunto por cluster" é removida (sairia uma linha Total com N 0).
- **Expected red**: #require(set 4 heading found) failed

#### Scenario: Bytes e nomes do arquivo
- **Test name**: bytesENomesDoArquivo
- **Test file**: Tests/AnthroIOTests/ReportFileTests.swift
- **Level**: integration
- **Breaks if**: a gravação usa UTF-8 ou quebra de linha LF.
- **Expected red**: #require(file exists) failed: write did not create the file

#### Scenario: Nome em branco e destino sem permissão
- **Test name**: nomeEmBrancoEDestinoSemPermissao
- **Test file**: Tests/AnthroFeaturesTests/SurveyAnalysisModelTests.swift
- **Level**: integration
- **Breaks if**: o nome do inquérito não é aparado antes do teste de vazio, ou o erro de gravação é engolido sem mensagem.
- **Expected red**: expected defaultFileName "Relatório_estimates.txt", got ""

#### Scenario: Excel instalado
- **Test name**: excelInstaladoAbreNoExcel
- **Test file**: Tests/AnthroFeaturesTests/ReportLauncherTests.swift
- **Level**: acceptance
- **Breaks if**: a ordem de preferência põe o Numbers antes do Excel.
- **Expected red**: expected opened with "com.microsoft.Excel", got nil and no open call

#### Scenario: Nenhuma planilha instalada
- **Test name**: nenhumaPlanilhaInstaladaUsaPadrao
- **Test file**: Tests/AnthroFeaturesTests/ReportLauncherTests.swift
- **Level**: acceptance
- **Breaks if**: sem Excel nem Numbers o lançador não abre nada.
- **Expected red**: expected one open call with application nil, got zero calls

#### Scenario: Linhas e células da tabela
- **Test name**: linhasECelulasDaTabela
- **Test file**: Tests/AnthroIOTests/StandardReportTests.swift
- **Level**: acceptance
- **Breaks if**: a tabela descarta linhas vazias ou divide por vírgula.
- **Expected red**: expected table.count == lines.count > 0 and a 15-cell BMI total row, got 0 rows

#### Scenario: Linha vazia na tabela
- **Test name**: linhaVaziaNaTabelaTemUmaCelula
- **Test file**: Tests/AnthroIOTests/StandardReportTests.swift
- **Level**: acceptance
- **Breaks if**: a divisão omite subsequências vazias e gera linha sem células.
- **Expected red**: #require(report.table.count > 2) failed: table.count is 0

#### Scenario: Correção pedida sem clusters
- **Test name**: correcaoPedidaSemClustersMostraErro
- **Test file**: Tests/AnthroFeaturesTests/SurveyAnalysisModelTests.swift
- **Level**: integration
- **Breaks if**: `AnalysisError.noClusterData` não é mapeado para a mensagem, ou o arquivo é gravado mesmo assim.
- **Expected red**: expected errorMessage "Erro: a variável cluster está vazia.", got nil

#### Scenario: Correção pedida com clusters
- **Test name**: correcaoPedidaComClustersGravaArquivo
- **Test file**: Tests/AnthroFeaturesTests/SurveyAnalysisModelTests.swift
- **Level**: integration
- **Breaks if**: o modelo não chama `SurveyReportWriter.write` depois de gerar o relatório.
- **Expected red**: expected file to exist at destination, got missing file

### Capability: survey-graphs

#### Scenario: Resolução 500
- **Test name**: curvaNormalComResolucao500
- **Test file**: Tests/AnthroAnalysisTests/DensityEstimationTests.swift
- **Level**: acceptance
- **Breaks if**: a grade é gerada por índice inteiro (500 pontos) em vez de acumular o passo `Double`, ou a constante vira `M_E`.
- **Expected red**: expected 501 points, got 0

#### Scenario: Resolução pequena
- **Test name**: curvaNormalComResolucaoPequena
- **Test file**: Tests/AnthroAnalysisTests/DensityEstimationTests.swift
- **Level**: acceptance
- **Breaks if**: a condição de parada vira `x <= 5` (11 pontos).
- **Expected red**: expected 10 points and last x 4, got 0 points

#### Scenario: Doze z com tamanho ponderado 50
- **Test name**: dozeZComTamanhoPonderado50
- **Test file**: Tests/AnthroAnalysisTests/DensityEstimationTests.swift
- **Level**: acceptance
- **Breaks if**: a largura usa o DP ponderado ou o divisor usa o número de z em vez do tamanho ponderado.
- **Expected red**: expected sampleSize 50, 51 points, y(0) 0.301381, got sampleSize 0, 0 points

#### Scenario: Doze z com fator 1
- **Test name**: dozeZComFator1
- **Test file**: Tests/AnthroAnalysisTests/DensityEstimationTests.swift
- **Level**: acceptance
- **Breaks if**: o passo deixa de ser $10/\min(W, 50)$ (fixo em 0.2) ou a parada vira `x < 5`.
- **Expected red**: expected 14 points, got 0

#### Scenario: Fatores zero contam como 1
- **Test name**: fatoresZeroContamComoUm
- **Test file**: Tests/AnthroAnalysisTests/DensityEstimationTests.swift
- **Level**: acceptance
- **Breaks if**: fator 0 entra como 0 (tamanho 0, curva vazia).
- **Expected red**: expected sampleSize 12 and 14 points, got 0 and 0

#### Scenario: Um único z
- **Test name**: umUnicoZDaCurvaVazia
- **Test file**: Tests/AnthroAnalysisTests/DensityEstimationTests.swift
- **Level**: acceptance
- **Breaks if**: a guarda de tamanho 1 é removida (divisão por $n - 1 = 0$).
- **Expected red**: expected sampleSize 1, got 0

#### Scenario: Todos os z iguais
- **Test name**: todosOsZIguaisLancamLarguraZero
- **Test file**: Tests/AnthroAnalysisTests/DensityEstimationTests.swift
- **Level**: acceptance
- **Breaks if**: largura zero devolve curva vazia ou NaN em vez de lançar.
- **Expected red**: expected error DensityError.zeroBandwidth, got no error

#### Scenario: Limite padrão de plausibilidade
- **Test name**: limitePadraoDePlausibilidadeNaDensidade
- **Test file**: Tests/AnthroAnalysisTests/DensityEstimationTests.swift
- **Level**: acceptance
- **Breaks if**: a seleção usa os limites do inquérito (`flagged`) em vez dos padrões do AnthroCore.
- **Expected red**: expected zScores [4.9], got []

#### Scenario: Criança abaixo de 61 meses
- **Test name**: criancaAbaixoDe61MesesNaDensidade
- **Test file**: Tests/AnthroFeaturesTests/SurveyAnalysisModelTests.swift
- **Level**: integration
- **Breaks if**: a densidade de todas as crianças passa a filtrar 61 a 228 meses, ou a por sexo deixa de filtrar.
- **Expected red**: expected allChildren selection [0.4] and girls selection [], got []

#### Scenario: Rótulo de todas as crianças
- **Test name**: rotuloDeTodasAsCriancas
- **Test file**: Tests/AnthroFeaturesTests/SurveyAnalysisModelTests.swift
- **Level**: acceptance
- **Breaks if**: o n do rótulo usa a contagem de z (12) em vez do tamanho ponderado arredondado (50).
- **Expected red**: expected .density with labels [normal, "Todas as crianças (n=50)"], got .empty(title: "")

#### Scenario: Meninos com z iguais
- **Test name**: meninosComZIguaisEsvaziamOGrafico
- **Test file**: Tests/AnthroFeaturesTests/SurveyAnalysisModelTests.swift
- **Level**: acceptance
- **Breaks if**: o erro de largura zero de uma série é engolido e o gráfico mostra só as meninas.
- **Expected red**: expected .empty(title: "(Sem dados)"), got .empty(title: "")

#### Scenario: Duas faixas com médias de sinais opostos
- **Test name**: duasFaixasComMediasDeSinaisOpostos
- **Test file**: Tests/AnthroAnalysisTests/MeanSDBarsTests.swift
- **Level**: acceptance
- **Breaks if**: a haste vira $m + DP$ em vez de $\mathrm{sinal}(m)(|m| + DP)$ (dá -0.7929 na faixa negativa), ou a cor ignora o sinal da média.
- **Expected red**: #require(bar "96-107") failed: bars is empty

#### Scenario: Faixa vazia e N fracionado
- **Test name**: faixaVaziaENFracionado
- **Test file**: Tests/AnthroAnalysisTests/MeanSDBarsTests.swift
- **Level**: acceptance
- **Breaks if**: a contagem por faixa trunca (1) em vez de arredondar (2), ou a faixa vazia ganha média 0.
- **Expected red**: #require(bar "96-107") failed: bars is empty

#### Scenario: Dois clusters
- **Test name**: barrasDeDoisClusters
- **Test file**: Tests/AnthroAnalysisTests/MeanSDBarsTests.swift
- **Level**: acceptance
- **Breaks if**: a contagem por cluster arredonda (2) em vez de truncar (1), ou a ordem segue a aparição.
- **Expected red**: expected labels ["2", "5"] and counts [2, 1], got []

#### Scenario: Nenhum cluster
- **Test name**: nenhumClusterDaGraficoVazio
- **Test file**: Tests/AnthroFeaturesTests/SurveyAnalysisModelTests.swift
- **Level**: acceptance
- **Breaks if**: com soma de contagens menor que 1 o modelo mostra eixo vazio em vez de "(Sem dados)".
- **Expected red**: expected .empty(title: "(Sem dados)"), got .empty(title: "")

#### Scenario: Onze registros
- **Test name**: onzeRegistrosBloqueiamResultados
- **Test file**: Tests/AnthroFeaturesTests/SurveyAnalysisModelTests.swift
- **Level**: acceptance
- **Breaks if**: o mínimo vira 11 ou passa a contar só registros válidos.
- **Expected red**: expected unavailableMessage "A análise requer que o inquérito contenha pelo menos 12 registros válidos.", got nil

#### Scenario: Doze registros sem z
- **Test name**: dozeRegistrosSemZLiberamResultados
- **Test file**: Tests/AnthroFeaturesTests/SurveyAnalysisModelTests.swift
- **Level**: acceptance
- **Breaks if**: o mínimo conta só registros com z válido.
- **Expected red**: expected canShowGraphs true, got false

#### Scenario: Zoom e restauração
- **Test name**: zoomERestauracao
- **Test file**: Tests/AnthroFeaturesTests/SurveyAnalysisModelTests.swift
- **Level**: acceptance
- **Breaks if**: `resetZoom` restaura o domínio do último zoom ou y de 0 a 1.
- **Expected red**: expected xDomain -2...2 after zoom, got 0...0

#### Scenario: Retângulo degenerado
- **Test name**: retanguloDegeneradoEIgnorado
- **Test file**: Tests/AnthroFeaturesTests/SurveyAnalysisModelTests.swift
- **Level**: acceptance
- **Breaks if**: o zoom aceita largura zero.
- **Expected red**: expected xDomain -5...5, got 0...0

#### Scenario: Comandos presentes na interface
- **Test name**: N/A (non-executable)
- **Test file**: scripts/build-app.sh
- **Level**: integration
- **Breaks if**: os comandos "Copiar gráfico" e "Imprimir gráfico" são removidos de `SurveyResultsView`.
- **Expected red**: N/A (non-executable): checagem mecânica `scripts/build-app.sh && grep -a -c "Copiar gráfico" build/AnthroPlus.app/Contents/MacOS/AnthroPlusApp && grep -a -c "Imprimir gráfico" build/AnthroPlus.app/Contents/MacOS/AnthroPlusApp`, que devolve código diferente de 0 antes da implementação das views.

#### Scenario: Gráfico vazio não é copiado
- **Test name**: graficoVazioNaoECopiado
- **Test file**: Tests/AnthroFeaturesTests/SurveyAnalysisModelTests.swift
- **Level**: acceptance
- **Breaks if**: `canCopyGraph` fica sempre `true`, ou sempre `false`.
- **Expected red**: expected canCopyGraph true after density data, got false

## Coverage Ledger

| Capability | Scenario | Test file | Test name | Breaks if | Red (SHA: failure) | Green (SHA) | State |
|------------|----------|-----------|-----------|-----------|--------------------|-------------|-------|
| survey-analysis | Dez registros de IMC com z conhecidos | Tests/AnthroAnalysisTests/PrevalenceCalculatorTests.swift | dezRegistrosDeImcComZConhecidos | limiares exclusivos em vez de cumulativos | fc2da34: PrevalenceCalculatorTests.swift:18:9: Expectation failed: (result.count -> 0) == 10 | | red |
| survey-analysis | Nenhum registro com z válido | Tests/AnthroAnalysisTests/PrevalenceCalculatorTests.swift | nenhumRegistroComZValido | IC com N = 0 não calculado | fc2da34: PrevalenceCalculatorTests.swift:29:9: Expectation failed: (result.interval(.belowMinus2) -> .notComputed) == .unavailable | | red |
| survey-analysis | Estatura para idade dos dez registros | Tests/AnthroAnalysisTests/PrevalenceCalculatorTests.swift | estaturaParaIdadeDosDezRegistros | estatura deixa de ser só negativa | fc2da34: PrevalenceCalculatorTests.swift:35:9: Expectation failed: (result.prevalence(.belowMinus3) -> nil) == 10 | | red |
| survey-analysis | Classificação dos indicadores | Tests/AnthroAnalysisTests/PrevalenceCalculatorTests.swift | classificacaoDosIndicadoresSoNegativos | peso sai da lista só negativa | fc2da34: PrevalenceCalculatorTests.swift:43:9: Expectation failed: PrevalenceCalculator.computeOnlyNegative(.weightForAge) | | red |
| survey-analysis | Registros com pesos diferentes | Tests/AnthroAnalysisTests/PrevalenceCalculatorTests.swift | registrosComPesosDiferentes | média sem ponderação | fc2da34: PrevalenceCalculatorTests.swift:52:9: Expectation failed: (result.count -> 0) == 4 | | red |
| survey-analysis | Um único registro | Tests/AnthroAnalysisTests/PrevalenceCalculatorTests.swift | umUnicoRegistroTemDpZero | NaN não vira 0 | fc2da34: PrevalenceCalculatorTests.swift:61:9: Expectation failed: (result.count -> 0) == 1 | | red |
| survey-analysis | Fator negativo vira 1 | Tests/AnthroAnalysisTests/PrevalenceCalculatorTests.swift | fatorNegativoViraUm | substituição removida | fc2da34: PrevalenceCalculatorTests.swift:70:9: Expectation failed: (result.count -> 0) == 3 | | red |
| survey-analysis | Fator zero não conta | Tests/AnthroAnalysisTests/PrevalenceCalculatorTests.swift | fatorZeroNaoConta | regra `<= 0` | fc2da34: PrevalenceCalculatorTests.swift:78:9: Expectation failed: (result.count -> 0) == 2 | | red |
| survey-analysis | Um caso de edema em IMC | Tests/AnthroAnalysisTests/PrevalenceCalculatorTests.swift | umCasoDeEdemaEmImc | edema fora do numerador | fc2da34: PrevalenceCalculatorTests.swift:92:9: Expectation failed: (result.count -> 0) == 9 | | red |
| survey-analysis | Edema não afeta estatura | Tests/AnthroAnalysisTests/PrevalenceCalculatorTests.swift | edemaNaoAfetaEstatura | ramo de edema em estatura | fc2da34: PrevalenceCalculatorTests.swift:103:9: Expectation failed: (result.count -> 0) == 10 | | red |
| survey-analysis | Um registro implausível | Tests/AnthroAnalysisTests/PrevalenceCalculatorTests.swift | umRegistroImplausivelFicaDeFora | checagem de flag removida | fc2da34: PrevalenceCalculatorTests.swift:113:9: Expectation failed: (result.count -> 0) == 2 | | red |
| survey-analysis | Todos implausíveis | Tests/AnthroAnalysisTests/PrevalenceCalculatorTests.swift | todosImplausiveisDaoNZero | IC com N = 0 não calculado | fc2da34: PrevalenceCalculatorTests.swift:124:9: Expectation failed: (result.interval(.belowMinus2) -> .notComputed) == .unavailable | | red |
| survey-analysis | Peso para idade com crianças de 110 meses | Tests/AnthroAnalysisTests/PrevalenceCalculatorTests.swift | pesoParaIdadeComCriancasDe110Meses | limite 108 vira 120 | fc2da34: PrevalenceCalculatorTests.swift:135:9: Expectation failed: (result.count -> 0) == 4 | | red |
| survey-analysis | Os mesmos registros em IMC | Tests/AnthroAnalysisTests/PrevalenceCalculatorTests.swift | osMesmosRegistrosEmImc | regra 108 em todo indicador | fc2da34: PrevalenceCalculatorTests.swift:144:9: Expectation failed: (result.count -> 0) == 4 | | red |
| survey-analysis | IC das prevalências dos dez registros | Tests/AnthroAnalysisTests/ConfidenceIntervalTests.swift | icDasPrevalenciasDosDezRegistros | sem correção de continuidade | fc2da34: ConfidenceIntervalTests.swift:14:9: Expectation failed: (result.interval(.belowMinus2) -> .notComputed) == (.interval(low: 0, high: d("63.4")) -> .... | | red |
| survey-analysis | Limite superior cortado em 100 | Tests/AnthroAnalysisTests/ConfidenceIntervalTests.swift | limiteSuperiorCortadoEm100 | sem corte em 1 | fc2da34: ConfidenceIntervalTests.swift:20:9: Expectation failed: (ConfidenceIntervals.simple(portion: 2, total: 4) -> .notComputed) == .interval(low: 0, hig... | | red |
| survey-analysis | Total zero | Tests/AnthroAnalysisTests/ConfidenceIntervalTests.swift | icSimplesComTotalZero | total 0 na fórmula | fc2da34: ConfidenceIntervalTests.swift:25:9: Expectation failed: (ConfidenceIntervals.simple(portion: 0, total: 0) -> .notComputed) == .unavailable | | red |
| survey-analysis | Quatro clusters de cinco crianças | Tests/AnthroAnalysisTests/ConfidenceIntervalTests.swift | quatroClustersDeCincoCriancas | $C^2$ ou t de C | fc2da34: ConfidenceIntervalTests.swift:31:9: Expectation failed: (result.prevalence(.belowMinus2) -> nil) == 20 | | red |
| survey-analysis | Paridade com o pacote R survey | Tests/AnthroAnalysisTests/ClusterCIGoldenTests.swift | paridadeDoIcPorClusterComPacoteSurvey | Wald no lugar de logit | fc2da34: ClusterCIGoldenTests.swift:44:9: Expectation failed: (far -> ["desenho 0: notComputed", "desenho 1: notComputed", "desenho 2: notComputed", "desenh... | | red |
| survey-analysis | Proporção nula | Tests/AnthroAnalysisTests/ConfidenceIntervalTests.swift | proporcaoNulaNaoTemIcPorCluster | guarda de p extremo removida | fc2da34: ConfidenceIntervalTests.swift:38:9: Expectation failed: (result.interval(.belowMinus3) -> .notComputed) == .unavailable | | red |
| survey-analysis | Um único cluster | Tests/AnthroAnalysisTests/ConfidenceIntervalTests.swift | umUnicoClusterNaoTemIc | t(0) = 1.96 | fc2da34: ConfidenceIntervalTests.swift:45:9: Expectation failed: (result.prevalence(.belowMinus2) -> nil) == 40 | | red |
| survey-analysis | Valores da tabela | Tests/AnthroAnalysisTests/ConfidenceIntervalTests.swift | valoresDaTabelaT | tabela deslocada | fc2da34: ConfidenceIntervalTests.swift:51:9: Expectation failed: (ConfidenceIntervals.tStudent(degreesOfFreedom: 3) -> nil) == (d("3.18244630528371") -> 3.1... | | red |
| survey-analysis | Fora da tabela | Tests/AnthroAnalysisTests/ConfidenceIntervalTests.swift | valoresForaDaTabelaT | acima de 200 vira nil | fc2da34: ConfidenceIntervalTests.swift:57:9: Expectation failed: (ConfidenceIntervals.tStudent(degreesOfFreedom: 201) -> nil) == (d("1.96") -> 1.96) | | red |
| survey-analysis | Cluster só com registro implausível | Tests/AnthroAnalysisTests/ConfidenceIntervalTests.swift | clusterSoComRegistroImplausivelContaEmC | cluster registrado depois da flag | fc2da34: ConfidenceIntervalTests.swift:65:9: Expectation failed: (result.count -> 0) == 20 | | red |
| survey-analysis | Registro sem cluster na correção | Tests/AnthroAnalysisTests/ConfidenceIntervalTests.swift | registroSemClusterNaCorrecaoEIgnorado | guarda sem cluster removida | fc2da34: ConfidenceIntervalTests.swift:73:9: Expectation failed: (result.count -> 0) == 20 | | red |
| survey-analysis | Peso para idade de crianças sem cluster | Tests/AnthroAnalysisTests/PrevalenceCalculatorTests.swift | pesoParaIdadeDeCriancasSemClusterLancaErro | checagem de erro removida | fc2da34: PrevalenceCalculatorTests.swift:153:9: Expectation failed: an error was expected but none was thrown | | red |
| survey-analysis | População vazia com correção | Tests/AnthroAnalysisTests/PrevalenceCalculatorTests.swift | populacaoVaziaComCorrecaoNaoLanca | erro lançado sempre | fc2da34: PrevalenceCalculatorTests.swift:160:9: Expectation failed: (result.interval(.belowMinus2) -> .notComputed) == .unavailable | | red |
| survey-analysis | Faixas fixas de 61 a 228 meses | Tests/AnthroAnalysisTests/PrevalenceCalculatorTests.swift | faixasFixasDe61A228Meses | descarte por idade decimal | fc2da34: PrevalenceCalculatorTests.swift:169:9: Expectation failed: (results.map(\.count) -> []) == [2, 1, 1] | | red |
| survey-analysis | Idade desconhecida | Tests/AnthroAnalysisTests/PrevalenceCalculatorTests.swift | idadeDesconhecidaNaoEntraEmFaixa | idade nil vira 0 | fc2da34: PrevalenceCalculatorTests.swift:177:9: Expectation failed: (results.map(\.count) -> []) == [0, 0, 0] | | red |
| survey-analysis | Três meninos e duas meninas | Tests/AnthroAnalysisTests/PrevalenceCalculatorTests.swift | tresMeninosEDuasMeninas | filtro de sexo ignorado | fc2da34: PrevalenceCalculatorTests.swift:188:9: Expectation failed: try counts(.boy) == [3] | | red |
| survey-analysis | Sexo sem registros | Tests/AnthroAnalysisTests/PrevalenceCalculatorTests.swift | sexoSemRegistrosDaNZero | faixas vazias omitidas | fc2da34: PrevalenceCalculatorTests.swift:198:9: Expectation failed: (results.map(\.count) -> []) == [0] | | red |
| survey-analysis | Bordas de idade do total | Tests/AnthroAnalysisTests/PrevalenceCalculatorTests.swift | bordasDeIdadeDoTotal | filtro por parte inteira | fc2da34: PrevalenceCalculatorTests.swift:205:9: Expectation failed: (kept.map(\.ageInMonths) -> []) == ([61, 228] -> [Optional(61), Optional(228)]) | | red |
| survey-analysis | Só registros com cluster | Tests/AnthroAnalysisTests/PrevalenceCalculatorTests.swift | soRegistrosComCluster | onlyWithCluster ignorado | fc2da34: PrevalenceCalculatorTests.swift:212:9: Expectation failed: (kept.map(\.cluster) -> []) == ([3] -> [Optional(3)]) | | red |
| survey-analysis | Clusters fora de ordem | Tests/AnthroAnalysisTests/PrevalenceCalculatorTests.swift | clustersForaDeOrdemSaemOrdenados | sem ordenação | fc2da34: PrevalenceCalculatorTests.swift:219:9: Expectation failed: (results.map(\.cluster) -> []) == [2, 5, 7] | | red |
| survey-analysis | Sem registros elegíveis | Tests/AnthroAnalysisTests/PrevalenceCalculatorTests.swift | semRegistrosElegiveisPorCluster | sem filtro 61 a 228 | fc2da34: PrevalenceCalculatorTests.swift:227:9: Expectation failed: (results.map(\.cluster) -> []) == [9] | | red |
| survey-analysis | Peso abaixo do mínimo | Tests/AnthroAnalysisTests/PrevalenceCalculatorTests.swift | pesoAbaixoDoMinimoNasEstimativas | pré-filtro no tipo errado | fc2da34: PrevalenceCalculatorTests.swift:235:9: Expectation failed: (global.count -> 0) == 1 | | red |
| survey-analysis | Medida ausente não é filtrada | Tests/AnthroAnalysisTests/PrevalenceCalculatorTests.swift | medidaAusenteNaoEFiltrada | nil tratado como 0 | fc2da34: PrevalenceCalculatorTests.swift:246:9: Expectation failed: (result.count -> 0) == 1 | | red |
| survey-analysis | Limite de IMC do inquérito exclui registro | Tests/AnthroFeaturesTests/SurveyAnalysisInputTests.swift | limiteDeImcDoInqueritoExcluiRegistro | adaptador sem `SurveyPlausibility` com as opções | fc2da34: SurveyAnalysisInputTests.swift:32:9: Expectation failed: (standard.count -> 0) == 2 | | red |
| survey-analysis | Limite dos padrões não afeta a referência | Tests/AnthroFeaturesTests/SurveyAnalysisInputTests.swift | limiteDosPadroesNaoAfetaAReferencia | flags com a faixa errada | fc2da34: SurveyAnalysisInputTests.swift:46:9: Expectation failed: (result.count -> 0) == 2 | | red |
| survey-reports | Abertura e conjuntos do relatório sem correção | Tests/AnthroIOTests/StandardReportTests.swift | aberturaEConjuntosDoRelatorioSemCorrecao | Conjunto 4 ausente sem correção | fc2da34: StandardReportTests.swift:23:13: Expectation failed: (report.lines.count -> 0) > 3 | | red |
| survey-reports | Relatório com correção por cluster | Tests/AnthroIOTests/StandardReportTests.swift | relatorioComCorrecaoPorCluster | Conjunto 4 com correção | fc2da34: StandardReportTests.swift:32:13: Expectation failed: (report.lines.count -> 0) >= 2 | | red |
| survey-reports | Cabeçalho de IMC para idade | Tests/AnthroIOTests/StandardReportTests.swift | cabecalhoDeImcParaIdade | IMC com cabeçalho só negativo | fc2da34: StandardReportTests.swift:40:25: Expectation failed: R.set(try standard(R.tenChildren()), R.set1) -> nil | | red |
| survey-reports | Cabeçalho de estatura no conjunto por cluster | Tests/AnthroIOTests/StandardReportTests.swift | cabecalhoDeEstaturaNoConjuntoPorCluster | anos e meses no Conjunto 4 | fc2da34: StandardReportTests.swift:48:25: Expectation failed: R.set(try standard(R.fourClusters()), R.set4) -> nil | | red |
| survey-reports | Total de IMC das dez crianças | Tests/AnthroIOTests/StandardReportTests.swift | totalDeImcDasDezCriancas | rótulo com limite 0 | fc2da34: StandardReportTests.swift:57:9: Expectation failed: (R.table(report, set: R.set1, header: R.bmiHeader)?.first -> nil) == ("Total (5-19)\t(61-228)\t... | | red |
| survey-reports | Total sem crianças de 61 a 228 meses | Tests/AnthroIOTests/StandardReportTests.swift | totalSemCriancasDe61A228Meses | total sem filtro de idade | fc2da34: StandardReportTests.swift:65:9: Expectation failed: (R.table(report, set: R.set1, header: R.heightHeader)?.first -> nil) == ("Total\t\t0" -> "Total... | | red |
| survey-reports | Faixas fixas de estatura | Tests/AnthroIOTests/StandardReportTests.swift | faixasFixasDeEstatura | fim da última faixa - 1 | fc2da34: StandardReportTests.swift:70:24: Expectation failed: R.table(try standard(R.tenChildren()), set: R.set1, header: R.heightHeader) -> nil | | red |
| survey-reports | Peso para idade em faixa acima de 108 meses | Tests/AnthroIOTests/StandardReportTests.swift | pesoParaIdadeEmFaixaAcimaDe108Meses | regra de peso em branco removida | fc2da34: StandardReportTests.swift:79:9: Expectation failed: (R.table(report, set: R.set1, header: R.weightHeader)?.contains("Total (10-14)\t(120-179)\t") -... | | red |
| survey-reports | Faixa de 96 meses e primeira e última faixas | Tests/AnthroIOTests/StandardReportTests.swift | faixaDe96MesesEPrimeiraEUltimaFaixas | última faixa com - 1 | fc2da34: StandardReportTests.swift:84:24: Expectation failed: R.table(try standard(R.tenChildren()), set: R.set1, header: R.bmiHeader) -> nil | | red |
| survey-reports | Peso para idade na faixa de 120 meses | Tests/AnthroIOTests/StandardReportTests.swift | pesoParaIdadeNaFaixaDe120Meses | regra só nas faixas fixas | fc2da34: StandardReportTests.swift:93:9: Expectation failed: (R.table(report, set: R.set1, header: R.weightHeader)?.contains("10\t(120-131)\t") -> nil) == true | | red |
| survey-reports | Intervalos calculados | Tests/AnthroIOTests/ReportFileTests.swift | intervalosCalculadosFormatados | ponto decimal ou zeros à direita | fc2da34: ReportFileTests.swift:12:9: Expectation failed: (ReportFormat.interval(.interval(low: d("4.7"), high: d("55.9"))) -> "") == "(4,7%, 55,9%)" | | red |
| survey-reports | Valores especiais | Tests/AnthroIOTests/ReportFileTests.swift | valoresEspeciaisFormatados | nil vazio ou "-0" | fc2da34: ReportFileTests.swift:18:9: Expectation failed: (ReportFormat.interval(.unavailable) -> "") == "(-, -)" | | red |
| survey-reports | Estatura nos quatro clusters | Tests/AnthroIOTests/StandardReportTests.swift | estaturaNosQuatroClusters | IC com correção nas linhas | fc2da34: StandardReportTests.swift:99:9: Expectation failed: (R.table(report, set: R.set4, header: "Cluster\t\tN\tComprimento/estatura para idade (%)") -> n... | | red |
| survey-reports | Inquérito sem cluster | Tests/AnthroIOTests/StandardReportTests.swift | inqueritoSemClusterTemSoCabecalho | Total com N 0 impresso | fc2da34: StandardReportTests.swift:110:25: Expectation failed: R.set(try standard(R.tenChildren()), R.set4) -> nil | | red |
| survey-reports | Contagem de crianças com edema | Tests/AnthroIOTests/StandardReportTests.swift | contagemDeCriancasComEdema | contagem filtrada | fc2da34: StandardReportTests.swift:120:9: Expectation failed: (report.lines -> []).contains("Número de crianças com edema: 2 (este número pode ser usado par... | | red |
| survey-reports | Notas da correção por cluster | Tests/AnthroIOTests/StandardReportTests.swift | notasDaCorrecaoPorCluster | ordem das notas invertida | fc2da34: StandardReportTests.swift:127:13: Expectation failed: (report.lines.count -> 0) >= 2 | | red |
| survey-reports | Abertura do relatório de estimativas | Tests/AnthroIOTests/EstimatesReportTests.swift | aberturaDoRelatorioDeEstimativas | metadados ausentes | fc2da34: EstimatesReportTests.swift:19:13: Expectation failed: (report.lines.count -> 0) >= 8 | | red |
| survey-reports | Estimativas sem notas de cluster | Tests/AnthroIOTests/EstimatesReportTests.swift | estimativasSemNotasDeCluster | notas de cluster nas estimativas | fc2da34: EstimatesReportTests.swift:29:24: Expectation failed: (report.lines -> []).last -> nil -> nil | | red |
| survey-reports | Total e faixa de 5 a 9 anos | Tests/AnthroIOTests/EstimatesReportTests.swift | totalEFaixaDe5A9Anos | peso no total sem cluster ou sem tab final | fc2da34: EstimatesReportTests.swift:36:25: Expectation failed: R.set(try estimates(R.tenChildren()), R.set1) -> nil | | red |
| survey-reports | Faixa sem crianças | Tests/AnthroIOTests/EstimatesReportTests.swift | faixaSemCriancasNasEstimativas | 15 tabulações | fc2da34: EstimatesReportTests.swift:43:25: Expectation failed: R.set(try estimates(R.tenChildren()), R.set1) -> nil | | red |
| survey-reports | Peso para idade sem dados acima de 108 meses | Tests/AnthroIOTests/EstimatesReportTests.swift | pesoParaIdadeSemDadosAcimaDe108Meses | regra dos quatro zeros removida | fc2da34: EstimatesReportTests.swift:50:25: Expectation failed: R.set(try estimates(records), R.set1) -> nil | | red |
| survey-reports | Total dos quatro clusters | Tests/AnthroIOTests/EstimatesReportTests.swift | totalDosQuatroClustersNasEstimativas | peso em branco no total por cluster | fc2da34: EstimatesReportTests.swift:61:25: Expectation failed: R.set(try estimates(R.fourClusters()), R.set4) -> nil | | red |
| survey-reports | Estimativas sem clusters | Tests/AnthroIOTests/EstimatesReportTests.swift | estimativasSemClustersTemSoCabecalho | guarda de 2 resultados removida | fc2da34: EstimatesReportTests.swift:70:25: Expectation failed: R.set(try estimates(R.tenChildren()), R.set4) -> nil | | red |
| survey-reports | Bytes e nomes do arquivo | Tests/AnthroIOTests/ReportFileTests.swift | bytesENomesDoArquivo | UTF-8 ou LF | fc2da34: ReportFileTests.swift:33:24: Expectation failed: try? Data(contentsOf: url) -> nil | | red |
| survey-reports | Nome em branco e destino sem permissão | Tests/AnthroFeaturesTests/SurveyAnalysisModelTests.swift | nomeEmBrancoEDestinoSemPermissao | nome não aparado ou erro engolido | fc2da34: SurveyAnalysisModelTests.swift:30:9: Expectation failed: (SurveyReportWriter.defaultFileName(surveyName: " ", kind: .estimates) -> "") == "Relatóri... | | red |
| survey-reports | Excel instalado | Tests/AnthroFeaturesTests/ReportLauncherTests.swift | excelInstaladoAbreNoExcel | Numbers antes do Excel | fc2da34: ReportLauncherTests.swift:16:9: Expectation failed: (ReportLauncher.open(file, using: opener) -> nil) == "com.microsoft.Excel" | | red |
| survey-reports | Nenhuma planilha instalada | Tests/AnthroFeaturesTests/ReportLauncherTests.swift | nenhumaPlanilhaInstaladaUsaPadrao | nada é aberto | fc2da34: ReportLauncherTests.swift:25:9: Expectation failed: (opener.opened.count -> 0) == 1 | | red |
| survey-reports | Linhas e células da tabela | Tests/AnthroIOTests/StandardReportTests.swift | linhasECelulasDaTabela | linhas vazias descartadas | fc2da34: StandardReportTests.swift:136:13: Expectation failed: !((report.lines -> []).isEmpty -> true -> true) | | red |
| survey-reports | Linha vazia na tabela | Tests/AnthroIOTests/StandardReportTests.swift | linhaVaziaNaTabelaTemUmaCelula | subsequências vazias omitidas | fc2da34: StandardReportTests.swift:149:13: Expectation failed: (report.table.count -> 0) > 2 | | red |
| survey-reports | Correção pedida sem clusters | Tests/AnthroFeaturesTests/SurveyAnalysisModelTests.swift | correcaoPedidaSemClustersMostraErro | erro sem mensagem | fc2da34: SurveyAnalysisModelTests.swift:49:9: Expectation failed: (analysis.errorMessage -> nil) == "Erro: a variável cluster está vazia." | | red |
| survey-reports | Correção pedida com clusters | Tests/AnthroFeaturesTests/SurveyAnalysisModelTests.swift | correcaoPedidaComClustersGravaArquivo | write não chamado | fc2da34: SurveyAnalysisModelTests.swift:61:9: Expectation failed: (FileManager.default -> <NSFileManager: 0x10188cce0>).fileExists(atPath: url.path -> "/var... | | red |
| survey-graphs | Resolução 500 | Tests/AnthroAnalysisTests/DensityEstimationTests.swift | curvaNormalComResolucao500 | grade por índice inteiro | fc2da34: DensityEstimationTests.swift:24:9: Expectation failed: (curve.x.count -> 0) == 501 | | red |
| survey-graphs | Resolução pequena | Tests/AnthroAnalysisTests/DensityEstimationTests.swift | curvaNormalComResolucaoPequena | parada `x <= 5` | fc2da34: DensityEstimationTests.swift:35:9: Expectation failed: (curve.x.count -> 0) == 10 | | red |
| survey-graphs | Doze z com tamanho ponderado 50 | Tests/AnthroAnalysisTests/DensityEstimationTests.swift | dozeZComTamanhoPonderado50 | DP ponderado na largura | fc2da34: DensityEstimationTests.swift:42:9: Expectation failed: (curve.sampleSize -> 0) == 50 | | red |
| survey-graphs | Doze z com fator 1 | Tests/AnthroAnalysisTests/DensityEstimationTests.swift | dozeZComFator1 | passo fixo 0.2 | fc2da34: DensityEstimationTests.swift:53:9: Expectation failed: (curve.sampleSize -> 0) == 12 | | red |
| survey-graphs | Fatores zero contam como 1 | Tests/AnthroAnalysisTests/DensityEstimationTests.swift | fatoresZeroContamComoUm | fator 0 como 0 | fc2da34: DensityEstimationTests.swift:62:9: Expectation failed: (curve.sampleSize -> 0) == 12 | | red |
| survey-graphs | Um único z | Tests/AnthroAnalysisTests/DensityEstimationTests.swift | umUnicoZDaCurvaVazia | guarda de tamanho 1 removida | fc2da34: DensityEstimationTests.swift:70:9: Expectation failed: (curve.sampleSize -> 0) == 1 | | red |
| survey-graphs | Todos os z iguais | Tests/AnthroAnalysisTests/DensityEstimationTests.swift | todosOsZIguaisLancamLarguraZero | largura zero sem erro | fc2da34: DensityEstimationTests.swift:75:9: Expectation failed: an error was expected but none was thrown | | red |
| survey-graphs | Limite padrão de plausibilidade | Tests/AnthroAnalysisTests/DensityEstimationTests.swift | limitePadraoDePlausibilidadeNaDensidade | limites do inquérito na densidade | fc2da34: DensityEstimationTests.swift:84:9: Expectation failed: (DensityEstimation.zScores(records, indicator: .bmiForAge).zScores -> []) == ([d("4.9")] -> ... | | red |
| survey-graphs | Criança abaixo de 61 meses | Tests/AnthroFeaturesTests/SurveyAnalysisModelTests.swift | criancaAbaixoDe61MesesNaDensidade | filtro de idade trocado | fc2da34: SurveyAnalysisModelTests.swift:68:9: Expectation failed: (series(all.graph).map(\.label) -> []) == ([F.normalLabel, "Todas as crianças (n=12)"] -> ... | | red |
| survey-graphs | Rótulo de todas as crianças | Tests/AnthroFeaturesTests/SurveyAnalysisModelTests.swift | rotuloDeTodasAsCriancas | n pela contagem de z | fc2da34: SurveyAnalysisModelTests.swift:78:9: Expectation failed: (graph.map(\.label) -> []) == ([F.normalLabel, "Todas as crianças (n=50)"] -> ["Padrões de... | | red |
| survey-graphs | Meninos com z iguais | Tests/AnthroFeaturesTests/SurveyAnalysisModelTests.swift | meninosComZIguaisEsvaziamOGrafico | erro de série engolido | fc2da34: SurveyAnalysisModelTests.swift:85:9: Expectation failed: (model(records, filter: .bySex).graph -> .empty(title: "")) == .empty(title: "(Sem dados)") | | red |
| survey-graphs | Duas faixas com médias de sinais opostos | Tests/AnthroAnalysisTests/MeanSDBarsTests.swift | duasFaixasComMediasDeSinaisOpostos | haste $m + DP$ | fc2da34: MeanSDBarsTests.swift:19:28: Expectation failed: bars.first { $0.label == "96-107" } -> nil | | red |
| survey-graphs | Faixa vazia e N fracionado | Tests/AnthroAnalysisTests/MeanSDBarsTests.swift | faixaVaziaENFracionado | contagem truncada por faixa | fc2da34: MeanSDBarsTests.swift:33:26: Expectation failed: bars.first { $0.label == "96-107" } -> nil | | red |
| survey-graphs | Dois clusters | Tests/AnthroAnalysisTests/MeanSDBarsTests.swift | barrasDeDoisClusters | contagem arredondada por cluster | fc2da34: MeanSDBarsTests.swift:45:9: Expectation failed: (bars.map(\.label) -> []) == ["2", "5"] | | red |
| survey-graphs | Nenhum cluster | Tests/AnthroFeaturesTests/SurveyAnalysisModelTests.swift | nenhumClusterDaGraficoVazio | eixo vazio sem título | fc2da34: SurveyAnalysisModelTests.swift:92:9: Expectation failed: (model(records, filter: .byCluster).graph -> .empty(title: "")) == .empty(title: "(Sem dad... | | red |
| survey-graphs | Onze registros | Tests/AnthroFeaturesTests/SurveyAnalysisModelTests.swift | onzeRegistrosBloqueiamResultados | mínimo 11 | fc2da34: SurveyAnalysisModelTests.swift:99:9: Expectation failed: (analysis.unavailableMessage -> nil) == "A análise requer que o inquérito contenha pelo me... | | red |
| survey-graphs | Doze registros sem z | Tests/AnthroFeaturesTests/SurveyAnalysisModelTests.swift | dozeRegistrosSemZLiberamResultados | mínimo só com válidos | fc2da34: SurveyAnalysisModelTests.swift:105:9: Expectation failed: (analysis -> AnthroFeatures.SurveyAnalysisModel).canShowGraphs -> false | | red |
| survey-graphs | Zoom e restauração | Tests/AnthroFeaturesTests/SurveyAnalysisModelTests.swift | zoomERestauracao | reset para o último zoom | fc2da34: SurveyAnalysisModelTests.swift:114:9: Expectation failed: (analysis.xDomain -> 0.0 ... 0.0) == (-2...2 -> -2.0 ... 2.0) | | red |
| survey-graphs | Retângulo degenerado | Tests/AnthroFeaturesTests/SurveyAnalysisModelTests.swift | retanguloDegeneradoEIgnorado | largura zero aceita | fc2da34: SurveyAnalysisModelTests.swift:125:9: Expectation failed: (analysis.xDomain -> 0.0 ... 0.0) == (-5...5 -> -5.0 ... 5.0) | | red |
| survey-graphs | Comandos presentes na interface | scripts/build-app.sh | N/A (non-executable) | comandos removidos da view | fc2da34: `scripts/build-app.sh && grep -a -c "Copiar gráfico" ... && grep -a -c "Imprimir gráfico" ...` saiu com código 1 (strings ausentes do binário) | | N/A (non-executable) |
| survey-graphs | Gráfico vazio não é copiado | Tests/AnthroFeaturesTests/SurveyAnalysisModelTests.swift | graficoVazioNaoECopiado | canCopyGraph constante | fc2da34: SurveyAnalysisModelTests.swift:132:9: Expectation failed: (analysis.graph -> .empty(title: "")) == .empty(title: "(Sem dados)") | | red |

## Test Changes After Red
