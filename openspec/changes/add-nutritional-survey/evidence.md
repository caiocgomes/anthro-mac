# Evidence

## Red Gate Replay

- **Red commit**: `143cda8` (`git log --format=%h --grep='^test(red)' -n 1`); 14 commits depois dele no momento da checagem (`git rev-list --count 143cda8..HEAD`); nenhuma tarefa aberta em tasks.md.
- **How replayed**: worktree temporário em `143cda8` (`git worktree add --detach`), `swift test --filter ScenarioTests`, worktree removido em seguida. Os dois testes da migração foram reproduzidos também na fase 1, no mesmo worktree, com o SQL da migração 3 esvaziado, como descrito em Conventions de tests.md.
- **Result**: 82 testes de cenário; 80 falharam por asserção (`Expectation failed`), nenhum por erro lançado, falha de compilação ou queda do processo. Os 2 da migração (`migrationThreeCreatesSurveyTables`, `invalidSexIsRejectedByConstraint`) passam no SHA vermelho porque a migração 3 entrou nele como dado de partida (precedente da migração 2 na change 4, registrado em tests.md antes do vermelho); contra a migração vazia, os dois falharam por asserção (`tables ... .contains("surveys")` e `"no such table: surveys".contains("CHECK constraint failed")`). Trechos de cada falha no ledger de tests.md.
- **Portão vermelho**: registrado sem parada (tarefa 0.4), por decisão do Caio de 14/10/2026: a parada vale só para as changes que fixam números clínicos (`port-anthro-engine` e `add-survey-analysis`).

## Test Freeze

- **Command**: `git diff 143cda8..HEAD --stat -- Tests/AnthroCoreTests/SurveyOptionsScenarioTests.swift Tests/AnthroCoreTests/SurveyPlausibilityScenarioTests.swift Tests/AnthroCoreTests/SurveyRecordEvaluationScenarioTests.swift Tests/AnthroFeaturesTests/RecordEditorScenarioTests.swift Tests/AnthroFeaturesTests/SurveyDetailScenarioTests.swift Tests/AnthroFeaturesTests/SurveyFilterScenarioTests.swift Tests/AnthroFeaturesTests/SurveyModuleScenarioTests.swift Tests/AnthroFeaturesTests/SurveyOptionsEditorScenarioTests.swift Tests/AnthroFeaturesTests/SurveyTableScenarioTests.swift Tests/AnthroStoreTests/SurveyMigrationScenarioTests.swift Tests/AnthroStoreTests/SurveyRepositoryScenarioTests.swift`
- **Changes found**: nenhuma. `git diff 143cda8..HEAD --stat -- Tests/` lista só 8 arquivos novos de testes unitários do laço interno (`SurveyOptionsUnitTests`, `SurveyRecordUnitTests`, `SurveyRepositoryUnitTests`, `RecordEditorUnitTests`, `SurveyRecordRowUnitTests`, `SurveySortFilterUnitTests`, `SurveyOptionsEditorUnitTests`, `SurveyModuleUnitTests`); fixtures e cenários intactos. "Test Changes After Red" continua vazio.
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
- **Result**: 408 testes passaram, 0 falharam, 0 pulados (276 anteriores, 82 cenários e 50 unitários desta change, 2 deles da correção da verificação em `SheetGuardUnitTests`); código de saída 0. Rodada do zero depois do commit `83175ec`.
- **Output clean**: sim; nenhuma linha com `warning:` ou `error:` na saída do build e dos testes.
- **App**: `scripts/build-app.sh` terminou com código 0 (autoteste positivo), sem avisos, e `codesign --verify build/AnthroPlus.app` com código 0 (critério mecânico das tarefas 7.1 e 7.2), no build de `83175ec`. O app não estava aberto ao reconstruir o bundle.
- **Verificação manual (7.2, N/A não executável)**: não feita nesta sessão; a tela do Mac estava bloqueada e a regra do projeto é não enviar entrada sintética. Fica para o Caio: criar inquérito, incluir 3 registros, ordenar, filtrar, copiar para o Numbers, salvar, reabrir o app e conferir os dados.

## TDD Path

TDD path: superpowers

## OpenSpec Verify

`/opsx:verify add-nutritional-survey`, com uma revisão independente de código só de leitura focada na junção entre modelos e telas (o ponto em que a verificação da change 4 achou perda de dado).

| Dimension | Status |
|-----------|--------|
| Completeness | 37/37 tarefas; 35 requisitos ADDED, todos com implementação localizada |
| Correctness | 35/35 requisitos mapeados; 82/82 cenários com teste verde no ledger |
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

## Decision

DECISION: PASS
