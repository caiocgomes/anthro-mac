# Evidence

## Red Gate Replay

- **Red commit**: `143cda8` (`git log --format=%h --grep='^test(red)' -n 1`); 14 commits depois dele no momento da checagem (`git rev-list --count 143cda8..HEAD`); nenhuma tarefa aberta em tasks.md.
- **How replayed**: worktree temporário em `143cda8` (`git worktree add --detach`), `swift test --filter ScenarioTests`, worktree removido em seguida. Os dois testes da migração foram reproduzidos também na fase 1, no mesmo worktree, com o SQL da migração 3 esvaziado, como descrito em Conventions de tests.md.
- **Result**: 82 testes de cenário; 80 falharam por asserção (`Expectation failed`), nenhum por erro lançado, falha de compilação ou queda do processo. Os 2 da migração (`migrationThreeCreatesSurveyTables`, `invalidSexIsRejectedByConstraint`) passam no SHA vermelho porque a migração 3 entrou nele como dado de partida (precedente da migração 2 na change 4, registrado em tests.md antes do vermelho); contra a migração vazia, os dois falharam por asserção (`tables ... .contains("surveys")` e `"no such table: surveys".contains("CHECK constraint failed")`). Trechos de cada falha no ledger de tests.md.
- **Portão vermelho**: registrado sem parada (tarefa 0.4), por decisão do Caio de 14/10/2026: a parada vale só para as changes que fixam números clínicos (`port-anthro-engine` e `add-survey-analysis`).

## Test Freeze

- **Command**: `git diff 143cda8..HEAD --stat -- Tests/AnthroCoreTests/SurveyOptionsScenarioTests.swift Tests/AnthroCoreTests/SurveyPlausibilityScenarioTests.swift Tests/AnthroCoreTests/SurveyRecordEvaluationScenarioTests.swift Tests/AnthroFeaturesTests/RecordEditorScenarioTests.swift Tests/AnthroFeaturesTests/SurveyDetailScenarioTests.swift Tests/AnthroFeaturesTests/SurveyFilterScenarioTests.swift Tests/AnthroFeaturesTests/SurveyModuleScenarioTests.swift Tests/AnthroFeaturesTests/SurveyOptionsEditorScenarioTests.swift Tests/AnthroFeaturesTests/SurveyTableScenarioTests.swift Tests/AnthroStoreTests/SurveyMigrationScenarioTests.swift Tests/AnthroStoreTests/SurveyRepositoryScenarioTests.swift`
- **Changes found**: nenhuma. `git diff 143cda8..HEAD --stat -- Tests/` lista só 9 arquivos novos de testes unitários do laço interno (`SurveyOptionsUnitTests`, `SurveyRecordUnitTests`, `SurveyRepositoryUnitTests`, `RecordEditorUnitTests`, `SurveyRecordRowUnitTests`, `SurveySortFilterUnitTests`, `SurveyOptionsEditorUnitTests`, `SurveyModuleUnitTests` e `SheetGuardUnitTests`, este da correção da verificação); fixtures e cenários intactos. "Test Changes After Red" continua vazio.
- **Ajuste anterior ao vermelho**: `MigrationIndividualUnitTests` (teste unitário da change 4, não cenário desta) passou a esperar `schemaVersion() >= 2` em vez de `== 2`, porque registrar a migração 3 muda a versão do banco novo; está no commit vermelho.

## Mutation Checks

| Capability | Mutation applied | Test that caught it | Reverted |
|------------|------------------|---------------------|----------|
| survey-management | `referenceWeightForAgeUpperMonths` de 108 para 120 em `SurveyPlausibility` | `weightForAgeAbove108MonthsIsNeverFlagged` (`flagged(.weightForAge, result) -> true == false`) | sim (`git checkout`) |
| survey-management | ramo de intervalo de datas de `SurveyFilterEvaluator` devolvendo `false` incondicionalmente | `dateRangeWithOpenUpperBound` (`[] == ["2021-01-01"]`) | sim |
| survey-management | booleanos de `SurveyOptions.xml()` como `true`/`false` minúsculos | `defaultOptionsSerializeToExactXML` | sim |
| survey-management (migração, tarefa 2.1) | `CHECK (sex IN (1, 2))` removido da migração 3 | `invalidSexIsRejectedByConstraint` (`"no error".contains("CHECK constraint failed")`) | sim |

## Full Suite

- **Command**: `swift package clean && swift test`
- **Result**: 408 testes passaram, 0 falharam, 0 pulados (276 anteriores, 82 cenários e 50 unitários desta change, 2 deles da correção da verificação em `SheetGuardUnitTests`); código de saída 0. Rodada do zero depois do commit `83175ec` e de novo em `d5c1bf1`, na segunda verificação, com o mesmo resultado.
- **Output clean**: sim; nenhuma linha com `warning:` ou `error:` na saída do build e dos testes.
- **App**: `scripts/build-app.sh` terminou com código 0 (autoteste positivo), sem avisos, e `codesign --verify build/AnthroPlus.app` com código 0 (critério mecânico das tarefas 7.1 e 7.2), no build de `83175ec`. O app não estava aberto ao reconstruir o bundle. O bundle atual em `build/` saiu às 16h26min53s de 14/10/2026, depois da última alteração em `Sources/` (`SurveyListView.swift`, 16h26min03s, commit `d5c1bf1`); nenhum arquivo de `Sources/` é mais novo que ele, e `codesign --verify` voltou a dar 0 na segunda verificação.
- **Verificação manual (7.2, N/A não executável)**: não feita nesta sessão; a tela do Mac estava bloqueada e a regra do projeto é não enviar entrada sintética. Fica para o Caio: criar inquérito, incluir 3 registros, ordenar, filtrar, copiar para o Numbers, salvar, reabrir o app e conferir os dados.

## TDD Path

TDD path: superpowers

## OpenSpec Verify

`/opsx:verify add-nutritional-survey`, com uma revisão independente de código só de leitura focada na junção entre modelos e telas (o ponto em que a verificação da change 4 achou perda de dado).

| Dimension | Status |
|-----------|--------|
| Completeness | 37/37 tarefas; 39 requisitos ADDED, todos com implementação localizada |
| Correctness | 39/39 requisitos mapeados; 82/82 cenários com teste verde no ledger |
| Coherence | D1 a D13 seguidas; decisões novas da implementação registradas em D14 |

- **CRITICAL**: nenhum.
- **WARNING, corrigidos nesta verificação** (commit `83175ec`):
  - Folha de edição aberta (novo registro, opções) e ⌘1 a ⌘3 ou ⌘Q: o menu continua ativo com a folha anexada, o guarda do módulo não enxerga o que está na folha e o registro digitado se perdia sem pergunta (o mesmo caminho existia nas folhas da ficha da Avaliação individual). Agora `AppModel.isEditingInSheet` bloqueia a troca de módulo e o atalho (`SheetGuardUnitTests`), o menu Módulos fica desabilitado e encerrar avisa e cancela. A ligação nas views (modificador `editingSheet()` com o `AppModel` no ambiente) compila, mas não foi exercida na interface.
  - Editor de opções: campos de limite de z e de faixas só confirmavam ao sair do foco, e Aplicar podia ignorar o último número; e, com linhas identificadas por índice, um campo em foco podia mostrar o valor de outra faixa depois de remover uma. Os campos agora enviam ao editor durante a digitação (sem reescrever valores gravados ao abrir a folha) e as linhas são recriadas ao incluir ou remover faixa. Sem teste automatizado (camada de view).
- **WARNING, corrigido depois da revisão**: na lista de inquéritos, o nome era o rótulo da caixa de marcação, e no macOS clicar no nome marcava a caixa em vez de abrir o inquérito. Agora a caixa não tem rótulo e o nome fica ao lado, como na lista de crianças. Sem teste automatizado (camada de view).
- **WARNING, latente e encaminhado**: registro com nascimento, data da pesquisa e idade em meses perderia a idade digitada ao ser reeditado. Hoje é inalcançável (o editor nunca grava os dois); a importação da change 8 pode produzi-lo, e a regra de normalização na importação ficou em D14.
- **SUGGESTION**: se a gravação der certo e só a releitura da lista falhar, a mensagem diz que não foi possível salvar, embora o dado esteja gravado (`SurveyDetailPane.save`, `SurveyModuleModel.settle`).
- **Conferido e correto pela revisão**: ida e volta de registro existente pelo editor sem mudança, chaves estáveis e `editorKeys` no inquérito aberto, seleção da tabela zerada a cada mudança da lista visível, `save()` atribuindo ids por posição, repositório transacional com exclusão dos registros removidos e ordem por `position`, ciclo de pendências do módulo (inclusive falha ao salvar e inquérito nunca salvo) e a reatribuição do guarda do `AppModel` pelos hosts.
- **Não verificado**: comportamento visual e de teclado da interface (tarefa 7.2, N/A não executável), inclusive o `DatePicker` com campo digitado pela metade; fica com a conferência manual do Caio.

### Segunda verificação (14/10/2026, 19h20, em `d5c1bf1`)

- **Conferência mecânica**: o delta tem 39 requisitos ADDED e 82 cenários (a primeira passada registrou 35 requisitos por erro de contagem; todo requisito tem cenário, então nenhum ficou sem mapa). Cada cenário tem entrada em tests.md, a função de teste existe no arquivo indicado e a linha do ledger está verde com SHA posterior a `143cda8` e contido em `HEAD`. Nenhum arquivo de cenário ou fixture mudou depois do vermelho.
- **Sexo no banco**: `SurveyRepositoryUnitTests` confere o valor cru da coluna `sex` (menino 1, menina 2, convenção D3), o que uma ida e volta sozinha não pegaria; a ordenação usa o enum do motor (`girl = 0`, `boy = 1`), menina antes de menino, como D6.
- **Desempenho com 500 registros** (risco do design): medido com um teste temporário, apagado em seguida, sobre 500 registros de 60 a 120 meses mais 1 incluído pelo editor, só na camada de modelo (a renderização da `Table` não entra). Em release: carga 76 ms, inclusão 0,3 ms, ordenação por z de IMC 5 ms, aplicar opções (recalcula as 501 linhas) 73 ms, cópia das 501 linhas 48 ms, texto e destaque de todas as células 47 ms, salvar 84 ms. Em debug, nenhum passo passou de 89 ms. Não há otimização a fazer. Não ficou teste permanente: o design dizia "medir no teste de integração", mas a medição nunca entrou em tasks.md.
- **Ligações das views revistas por leitura**: ⌘C por `onCopyCommand` na tabela; ordenação pelo cabeçalho por um `sortOrder` que só repassa a coluna clicada a `sort(by:)`, e o indicador sai ao limpar o filtro porque `sortColumn` volta a `nil`; as três folhas do inquérito com `editingSheet()`; `d5c1bf1` só separa a caixa do nome na lista. Continuam sem teste automatizado e sem exercício na interface.
- **Resultado**: nenhum CRITICAL e nenhum WARNING novo; a SUGGESTION da mensagem de gravação continua aberta. Cobertura de cenários parcialmente verificada na camada de view (7.2 pendente).

## Decision

DECISION: PASS
