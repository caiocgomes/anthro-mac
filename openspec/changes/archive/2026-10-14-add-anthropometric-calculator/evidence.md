# Evidence

Gerado em 14/10/2026, 13h50; refeito às 14h05, depois da costura dos cinco anos e das correções da verificação. Pré-checagens: commit vermelho `c1d4d0f` encontrado por `git log --format=%h --grep='^test(red)' -n 1`; `git rev-list --count c1d4d0f..HEAD` = 13; tarefas não marcadas em `tasks.md` = 0. O portão 0.4 não parou, por aprovação prévia do usuário em 14/10/2026 (changes sem números clínicos seguem do vermelho ao verde), registrada na própria tarefa.

## Red Gate Replay

- **Red commit**: `c1d4d0f` (`test(red): add-anthropometric-calculator`)
- **How replayed**: worktree temporário destacado em `c1d4d0f` (`git worktree add --detach`), `swift test --filter AnthroFeaturesTests`, worktree removido em seguida.
- **Result**: 90 testes executados no alvo, 73 falharam e 17 passaram. O conjunto dos 73 que falharam é idêntico, nome a nome, às 73 linhas do Coverage Ledger (comparação por `diff` das listas ordenadas). Os 17 que passaram são testes anteriores da `bootstrap-macos-app` (`AppShellTests`, `ClinicalFormatTests`, `ClinicalFormatUnitTests`, `SelfTestUnitTests`). Todas as 111 ocorrências são de asserção (`Expectation failed` ou `#require`); nenhum erro capturado, de compilação ou fatal. Os dois cenários acrescentados depois (costura dos cinco anos) não existem no commit vermelho; o vermelho deles foi visto sobre o código de `10bfa36`, registrado no ledger e em "Test Changes After Red".

## Test Freeze

- **Command**: `git diff c1d4d0f..HEAD --stat -- Tests/AnthroFeaturesTests/CalculatorModelTests.swift Tests/AnthroFeaturesTests/ApproximateBirthDateTests.swift Tests/AnthroFeaturesTests/MeasurementInputTests.swift Tests/AnthroFeaturesTests/IndicatorPanelTests.swift Tests/AnthroFeaturesTests/GrowthChartModelTests.swift Tests/AnthroFeaturesTests/ChartExportTests.swift Tests/AnthroFeaturesTests/Support/ResultFixtures.swift`
- **Changes found**: em `GrowthChartModelTests.swift`, só o acréscimo de `pesoParaIdadeSemRetornoAos60Meses`, `percentisDeImcSemRetornoAos60Meses` e do helper `seriesGoingBack`, que correspondem à entrada de 14/10/2026 em tests.md "Test Changes After Red" (requisito "Costura entre padrões e referência", pedido do usuário depois da checagem manual); nenhuma asserção existente mudou. Nos demais arquivos de cenário, nenhuma mudança. Fora dos arquivos de cenário, mudaram só testes do laço interno: `AgeTextUnitTests`, `ApproximateBirthDateUnitTests` e `MeasurementInputUnitTests` (pedidos pelas tarefas 1.1 a 1.3, escritos antes do código; `ApproximateBirthDateUnitTests` ganhou `mesmoDiaReenviadoNaoSorteiaDeNovo` na tarefa 5.5), `GrowthChartRangeUnitTests` (tarefa 3.2) e `SelfTestUnitTests` (tarefa 5.3). Os acréscimos de 3.2, 5.3 e 5.5 estão nas entradas de 14/10/2026 em tests.md "Test Changes After Red"; a de 3.2 registra que esses testes vieram depois do código e foram validados por mutação.

## Mutation Checks

| Capability | Mutation applied | Test that caught it | Reverted |
|------------|------------------|---------------------|----------|
| anthropometric-calculator | `months < 11` trocado por `months < 61` em `CalculatorModel.isMeasurementChoiceEnabled` | `criancaDe30MesesSemEscolhaContraAAjuda` (escolha habilitada e deitado mantido aos 30 meses) | sim (`git checkout` do arquivo; `git status` limpo) |
| growth-charts | `weightUpperMonths = 108` trocado por `121` em `GrowthChartModel` | `pesoAos109MesesForaDoGrafico` (2 pontos no lugar de 1, sem aviso de fora do intervalo no eixo x) | sim (`git checkout` do arquivo; `git status` limpo) |
| growth-charts (laço interno 3.2) | `otherUpperMonths = 228` trocado por `229` | `imcAte228MesesInteirosEntraE229Sai` (ponto aos 229,03 meses desenhado) | sim |
| growth-charts (laço interno 3.2) | guarda de z `nil` movida para depois da checagem de idade | `semZNaoMarcaForaDoIntervalo` (resultado sem z marcou fora do intervalo) | sim |

## Full Suite

- **Command**: `swift package clean && swift test`
- **Result**: 182 passed, 0 failed, 0 skipped (75 de cenário e 11 do laço interno desta change, 58 da `port-anthro-engine`, 38 da `bootstrap-macos-app`), em `432166a`.
- **Output clean**: sim; build e testes sem `warning:` nem `error:`.
- **App**: `swift build -c release --product AnthroPlusApp` em `432166a` terminou sem avisos. `scripts/build-app.sh` terminou com código 0 no build com a correção dos campos (antes da guarda de mesmo dia, que não toca a view), com autoteste positivo (o `.app` carrega as tabelas da OMS de `Contents/Resources` e confere 1857 linhas de padrões por indicador e sexo) e negativo (sem o bundle de recursos o autoteste falha); `codesign --verify --strict build/AnthroPlus.app` passou.

## Checagem manual (tarefa 5.4)

Feita em 14/10/2026 no `build/AnthroPlus.app`, com a árvore de acessibilidade lida pelo REA (`observe_native_ui`) e capturas da janela:

- Abertura: nascimento 14/10/2020, visita 14/10/2026, "5a 11m (71m)", feminino, 20,00 kg, 115,00 cm, em pé com a escolha desabilitada, edema não, IMC 15,1.
- Caso "IMC de 20 kg e 110 cm aos seis anos": com 110 digitado e Enter, o campo passou a "110,00" e o IMC a "16,5"; painel com estatura -1,00 (selo dourado, porque $|z| \geq 1$) e IMC 0,75.
- Gráfico de IMC: sheet com as sete curvas de DP, marca de 24 meses com "COMPRIMENTO" e "ESTATURA", ponto atual com guias e legenda "Idade: 5a 11m (71m), z-score: ...", faixa x de 0 a 248 e y de 8 a 38.
- Zoom por arrasto: faixa visível passou a cerca de 64 a 190 meses e IMC 15 a 31, com as curvas recortadas na área do gráfico; "Restaurar" voltou à faixa completa.
- Exportar PDF: arquivo de 1 página, cabeçalho `%PDF-1.3`, 286 KB, com fundo branco e modo claro (renderizado e inspecionado).
- Ajustes feitos durante a checagem: borda nos campos de peso e medida, seletor de indicador sem truncamento, botões de ação como ícones com dica, e rótulos da marca de transição fora da área recortada.
- Costura dos cinco anos (pedido do usuário, "os graficos estão tendo umas quebrinhas estranhas"): as curvas faziam um "Z" aos 60 meses porque o mês 60 da referência era desenhado depois de 60,98 meses dos padrões, como no `GraphDialog`. Depois da correção, a captura do gráfico de IMC mostra as curvas sem retorno; resta o degrau real entre padrões 2006 e referência 2007 aos 61 meses (na menina, +0,24 no +3 DP e +0,13 no -3 DP) e o de comprimento para estatura aos 24 meses.
- Correção do aviso 1 da verificação (texto digitado não lido ao clicar em Picker segmentado): reproduzido no build anterior por ações de acessibilidade (peso "25" no campo, clique em "Masculino", IMC continuou 15,1 e z de peso calculado com 20 kg). A reexecução depois da correção não serve de prova: o valor posto por `AXValue` não chega ao estado do SwiftUI, e o usuário editava o campo de medida no mesmo instante. Fica para conferência manual: digitar o peso e clicar direto em outro controle.
- Não verificado manualmente: deslocamento com Shift, copiar e imprimir pela interface (a lógica tem testes em `GrowthChartModelTests` e `ChartExportTests`), e o avanço de foco com Enter em DatePicker, Toggle e Picker segmentado, que no macOS depende do acesso total por teclado. Durante a checagem, eventos de teclado sintéticos foram enviados para fora do app enquanto a máquina estava em uso; a automação foi interrompida e o usuário foi avisado.

## TDD Path

TDD path: superpowers

## OpenSpec Verify

Verificação pelo `openspec-verify-change` em 14/10/2026, sobre `64c61ee` (33 requisitos ADDED, 75 cenários):

- **CRITICAL**: nenhum. 33 de 33 requisitos com implementação e 75 de 75 cenários com teste; D1 a D13 e a Interface Under Test seguidos; fidelidade a `ACMain`, `IndicatorDisplayPanel` e `GraphDialog` conferida no C# decompilado.
- **WARNING 1** (texto digitado não entrava no cálculo ao clicar em Picker segmentado ou Toggle): corrigido em `432166a`; o setter de cada `Binding` da Calculadora lê os campos de texto antes de aplicar a mudança; D2 atualizado.
- **WARNING 2** (evidence desatualizado depois da costura): este arquivo foi refeito.
- **WARNING 3** (`tasks.md` e `evidence.md` sem commit): resolvido no commit de documentação desta change.
- **Sugestões tratadas**: IMC inteiro com 1 casa e visita que puxa o nascimento registrados como divergências no design; mesmo dia reenviado não sorteia de novo (`mesmoDiaReenviadoNaoSorteiaDeNovo`); texto do D10 corrigido para `PDFDocument.printOperation`; texto inicial dos campos derivado do modelo; duplo clique de restaurar removido; tarefa 3.6 acrescentada para a costura.

## Decision

DECISION: PASS
