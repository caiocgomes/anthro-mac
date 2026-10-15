# Evidence

## Red Gate Replay

- **Red commit**: `fc2da34` (`git log --format=%h --grep='^test(red)' -n 1`); 11 commits depois dele na checagem (`git rev-list --count fc2da34..HEAD`); nenhuma tarefa aberta em tasks.md.
- **How replayed**: worktree temporário em `fc2da34` (`git worktree add --detach`), `swift test --filter` com as 11 suítes de cenário da change, worktree removido em seguida. A mesma técnica, nos commits verdes `5b01365`, `468d391`, `6be3e62`, `d5114e1` e `55d2d3f`, deu o SHA verde de cada linha do ledger.
- **Result**: 90 testes de cenário; os 90 falharam por asserção (164 `Expectation failed`, inclusive os `#require` que protegem a indexação de linhas do relatório), nenhum por erro lançado, falha de compilação ou queda do processo, e nenhum passou. Na suíte completa do mesmo SHA, 790 testes, só esses 90 falhavam. A linha N/A ("Comandos presentes na interface") saiu com código 1 na checagem mecânica antes das views. Trechos de cada falha no ledger de tests.md.
- **Portão vermelho**: parada obrigatória (change de números clínicos). O Caio aprovou os testes em 15/10/2026 e decidiu a pergunta aberta: peso para idade acima de 108 meses segue o original (conta em N sem z).

## Test Freeze

- **Command**: `git diff --stat fc2da34..HEAD -- <os 15 arquivos de teste do commit vermelho>` (11 suítes de cenário, os suportes `AnalysisFixtures`, `ReportFixtures` e `SurveyAnalysisTestSupport`, e o oráculo gerado `ClusterCIGolden.generated.swift`).
- **Changes found**: nenhuma; o comando não lista arquivo. `git diff --name-status fc2da34..HEAD -- Tests` mostra só arquivos novos de testes unitários do laço interno: `PrevalenceUnitTests`, `GraphSeriesUnitTests`, `ReportUnitTests` e `SurveyAnalysisUnitTests`. "Test Changes After Red" continua vazio.
- **Oráculo**: `scripts/golden/generate_cluster_ci_golden.R` (R 4.5.0, `survey` 4.5, semente 20261015) gera bytes idênticos em duas execuções; os dois exemplos calculados à mão no design (4,6961 a 55,9157 e 7,5679 a 67,4356) batem com o R.

## Mutation Checks

| Capability | Mutation applied | Test that caught it | Reverted |
|------------|------------------|---------------------|----------|
| survey-analysis (tarefa 6.1) | `> 108` trocado por `> 120` no ramo de peso para idade | `pesoParaIdadeComCriancasDe110Meses` (`prevalence(.belowMinus3) -> 25 == 0`) | sim |
| survey-analysis (tarefa 6.2) | termo $1/(2n)$ removido de `ConfidenceIntervals.simple` | `icDasPrevalenciasDosDezRegistros` (`.interval(low: 1.6, high: 58.4)` contra 0 a 63,4) | sim |
| survey-reports (tarefa 6.3) | "próximo limite - 1" também na última faixa fixa | `faixasFixasDeEstatura` (`Total (15-18)\t(180-227)`) | sim |
| survey-graphs (tarefa 6.4) | grade da curva normal por índice inteiro | `curvaNormalComResolucao500` (`x.count -> 500 == 501`) | sim |
| survey-graphs | média zero tratada como positiva nas barras | `barsHavePositionsLabelsAndZeroMeanIsNotPositive` | sim |

A guarda explícita de "um só z com fator acima de 1" na densidade sobreviveu à mutação: a guarda de largura zero cobre o mesmo caso (a divisão por n - 1 = 0 dá NaN e a largura vira 0), e o comportamento testado não muda.

## Full Suite

- **Command**: `swift package clean && swift test`
- **Result**: 811 testes passaram, 0 falharam, 0 pulados (700 anteriores, 90 cenários e 21 unitários desta change); código de saída 0.
- **Output clean**: sim; nenhuma linha com `warning:` ou `error:` na saída do build e dos testes.
- **Checagem N/A (tarefas 5.5 e 6.5)**: `scripts/build-app.sh && grep -a -c "Copiar gráfico" ... && grep -a -c "Imprimir gráfico" ...` com código 0 (2 e 1 ocorrências), build sem avisos e `codesign --verify build/AnthroPlus.app` com código 0, depois de `pgrep -x AnthroPlusApp` confirmar o app fechado.
- **Verificação visual (5.5, manual)**: a aba de resultados, o zoom por arraste, copiar, imprimir, a pergunta do cluster e a tabela do relatório não foram exercidos, porque a regra do projeto é não enviar entrada sintética à interface. Fica para o Caio: abrir um inquérito com 12 registros ou mais, alternar indicador e filtro, arrastar para ampliar e restaurar, copiar e colar o gráfico, gerar os dois relatórios e abri-los no Excel ou no Numbers.

## TDD Path

TDD path: superpowers

## OpenSpec Verify

Pendente da revisão independente.

## Decision

DECISION: PASS
