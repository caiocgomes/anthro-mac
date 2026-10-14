# Proposal

## Why

O módulo de Inquérito nutricional só entrega valor para a pesquisa da Suzan quando transforma os registros em prevalências, médias, desvios-padrão e intervalos de confiança por faixa etária, sexo e cluster, com os mesmos números que o WHO AnthroPlus de Windows imprime nos relatórios. Sem essa análise portada com fidelidade, o inquérito é só uma planilha de z-scores, e a comparação com estudos que usaram o AnthroPlus deixa de valer.

## What Changes

- Porta para Swift, no target `AnthroAnalysis`, o `AnthroAnalysis.ComputePrevalences` do original: seleção dos registros com z plausível pelos limites do inquérito, edema contado como < -3 DP e < -2 DP em peso e IMC para idade, prevalências < -3, < -2, > +1, > +2 e > +3 DP, média e DP ponderados pelo fator de ponderação, N ponderado e a regra de peso para idade após 108 meses.
- Porta os dois intervalos de confiança de 95%: o simples (`ComputeCI`, Wald com correção de continuidade) e o corrigido por cluster (`ComputeImprovedClusterCI`, linearização com transformação logit e a tabela t de Student de 1 a 200 graus de liberdade).
- Porta o agrupamento por faixas etárias do inquérito, pelas faixas fixas 61-119, 120-179 e 180-228 meses, por sexo e por cluster.
- Gera, no target `AnthroIO`, o relatório padrão com IC 95% (com ou sem correção por cluster) e o relatório de estimativas sem IC no formato do banco global da OMS, como texto separado por tabulação com a mesma estrutura do `CreateExcelReport` do original e rótulos em pt-BR, gravado em arquivo, aberto no Excel ou no Numbers e mostrado numa tabela dentro do app.
- Gera as séries dos gráficos de resultados: densidade de Epanechnikov dos z-scores contra a curva normal padrão da OMS, e barras de média com DP por faixa etária e por cluster, desenhadas com Swift Charts.
- Acrescenta ao inquérito aberto (change `add-nutritional-survey`) os comandos de relatório e a aba de resultados, com o mínimo de 12 registros do original.

## Capabilities

### New Capabilities
- `survey-analysis`: cálculo de prevalências, média, DP, N ponderado e IC 95% simples e por cluster, por total, faixa etária, sexo e cluster.
- `survey-reports`: relatório padrão com IC e relatório de estimativas sem IC, em texto tabulado, arquivo, abertura externa e visualização no app.
- `survey-graphs`: densidade de Epanechnikov contra a normal padrão e barras de média com DP por faixa etária e por cluster.

### Modified Capabilities
- Nenhuma.

## Impact

- Código novo em `Sources/AnthroAnalysis/`, `Sources/AnthroIO/` (relatórios), `Sources/AnthroFeatures/` (`SurveyAnalysisModel`) e `Sources/AnthroPlusApp/` (views de resultados e relatórios); testes em `Tests/AnthroAnalysisTests/`, `Tests/AnthroIOTests/` e `Tests/AnthroFeaturesTests/`.
- Script `scripts/golden/generate_cluster_ci_golden.R`, que usa o pacote R `survey` como oráculo independente do IC por cluster.
- Depende de `port-anthro-engine` (z-scores e `Plausibility`), de `bootstrap-macos-app` (layout de targets, `L10n`, `ClinicalFormat`) e de `add-nutritional-survey` (`SurveyRepository`, `RecordRepository`, `SurveyOptions`, filtro de registros e a tela do inquérito).
- Sem dependências Swift externas.
