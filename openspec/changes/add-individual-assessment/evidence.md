# Evidence

Gerado em 14/10/2026. Pré-checagens: commit vermelho `c7e3cb1` encontrado por `git log --format=%h --grep='^test(red)' -n 1`; `git rev-list --count c7e3cb1..HEAD` = 16 (17 com o commit deste evidence); tarefas não marcadas em `tasks.md` = 0. O portão 0.4 não parou, por aprovação prévia do usuário em 14/10/2026 (changes sem números clínicos seguem do vermelho ao verde), e a decisão D4 (ID automático sobre o banco inteiro) foi confirmada pelo usuário no mesmo dia, ambas registradas na tarefa e no design.

## Red Gate Replay

- **Red commit**: `c7e3cb1` (`test(red): add-individual-assessment`)
- **How replayed**: worktree temporário destacado em `c7e3cb1` (`git worktree add --detach`), `swift test --filter 'ChildRepositoryTests|ParentAddressRepositoryTests|ChildDetailModelTests|ChildListModelTests|ParentAddressEditorTests|VisitEditorModelTests'`, worktree removido em seguida.
- **Result**: 67 testes executados, 67 falharam, 0 passaram. O conjunto dos que falharam é idêntico, nome a nome, às 67 linhas do Coverage Ledger (comparação por `diff` das listas ordenadas). Todas as 100 ocorrências são de asserção (`Expectation failed`, `#require` ou `#expect(throws:)` sem erro); nenhum erro capturado, de compilação ou fatal.

## Test Freeze

- **Command**: `git diff c7e3cb1..HEAD --stat -- Tests/AnthroStoreTests/IndividualAssessment/{ChildRepositoryTests,ParentAddressRepositoryTests,Support}.swift Tests/AnthroFeaturesTests/IndividualAssessment/{ChildDetailModelTests,ChildListModelTests,ParentAddressEditorTests,VisitEditorModelTests,Support}.swift`
- **Changes found**: nenhuma nos arquivos de cenário. Em `Tests/` mudaram só testes do laço interno, todos nas entradas de 14/10/2026 em tests.md "Test Changes After Red": `MigrationIndividualUnitTests` (1.1, validado por mutação), `SQLValueUnitTests` (1.2, teste de UTC da change 1 trocado pelo do calendário do usuário, visto falhando antes da correção), `RecordMappingUnitTests` (1.2, escrito depois do mapeamento e validado por mutação), `NameMatcherUnitTests` (2.1), `VisitEditorWarningUnitTests` (5.2) e `SectionGuardUnitTests` (7.1), os três vistos falhando antes do código, e `ModelSeamTests` (7.3, depois da verificação: 7 de 9 vistos falhando antes das correções; os outros 2 cobrem no nível da ficha comportamentos já certos no editor).

## Mutation Checks

| Capability | Mutation applied | Test that caught it | Reverted |
|------------|------------------|---------------------|----------|
| child-registry | `maxDisplayID()` com `WHERE is_archived = 0` | `autoDisplayIDIncludesArchivedChildren` | sim (`git checkout`; `git diff --quiet`) |
| child-registry | ancoragem `^...$` removida de `NameMatcher` | `searchWithoutWildcardIsExactMatch` | sim |
| visit-tracking | `< 11` trocado por `< 61` em `VisitEditorModel.isMeasureChoiceEnabled` | `measureChoiceForcedStandingFromElevenMonths` | sim |
| visit-tracking | `commitVisit` grava direto com `VisitRepository.replaceVisits` | `committedVisitPersistsOnlyWithChildSave` | sim |
| visit-tracking | `blocksSave` deixa passar `.outOfRange` (o `canSave` ignora e `makeVisit()` grava `nil`) | `visitWithOutOfRangeWeightCannotBeSaved` | sim |
| child-registry (laço interno 1.1) | `CHECK (sex IN (1, 2))` removido da migração 2 | `sexoForaDe1e2EhRecusadoPeloBanco` | sim |
| child-registry (laço interno 1.2) | códigos de sexo trocados no mapeamento | `sexoGravadoComo1Menino2Menina` | sim |

## Full Suite

- **Command**: `swift package clean && swift test`
- **Result**: 276 passed, 0 failed, 0 skipped: 67 de cenário e 27 do laço interno e da junção desta change (4 da migração, 2 de mapeamento, 6 do `NameMatcher`, 3 dos avisos da visita, 3 do guarda de seção, 9 da junção entre lista, ficha e editores; o de `SQLValue` substituiu um existente), mais os 182 das três changes anteriores.
- **Output clean**: sim; build e testes sem `warning:` nem `error:`.
- **App**: `scripts/build-app.sh` terminou com código 0 (autoteste positivo e negativo) e `codesign --verify --strict build/AnthroPlus.app` passou (critério da tarefa 7.1), no build de `653c47b`. As correções da 7.3 compilam sem avisos (`swift build` e a suíte acima); o `.app` não foi reconstruído com elas porque o app estava aberto em uso pelo usuário, e reconstruir o bundle sob um processo em execução pode derrubá-lo. O visual é N/A não executável pela tarefa; a conferência por captura feita em segundo plano mostrou a lista e a ficha vazias e levou a dois ajustes de layout (painéis em `HSplitView` com mínimos menores; altura total da janela). A última captura não foi possível porque a janela estava fora da tela; nenhuma entrada de teclado ou mouse foi enviada.

## TDD Path

TDD path: superpowers

## OpenSpec Verify

Verificação pelo `openspec-verify-change` em 14/10/2026, sobre `85bafec` (27 requisitos ADDED, 67 cenários, D1 a D18):

- **CRITICAL**: nenhum. 35 de 35 tarefas, 27 de 27 requisitos com implementação, 67 de 67 cenários com teste de mesmo nome; D10 (datas no calendário do usuário), D4, D14 e a unidade de trabalho conferidos sem perda nem duplicação de visita.
- **WARNINGs (7), todos corrigidos em `683a3d9` com teste de modelo em `ModelSeamTests` quando havia regra**: criança arquivada voltava à lista ativa ao salvar e o arquivo abria a ficha; arquivar ou excluir a criança aberta não perguntava nem fechava a ficha, e salvar uma criança excluída não dava erro; Cancelar descartava sem confirmação; "Salvar e seguir" não atualizava a lista; fechar a janela descartava a ficha sem perguntar (agora a sessão fica no `AppModel` e o encerramento pergunta); a limpeza de órfãos na exclusão apagava o cadastro ligado só ao rascunho (D6 corrigido; spec de exclusão emendada); pai ou mãe novos começavam com nascimento de hoje (D19).
- **SUGGESTIONs (8)**: tratadas a premissa falsa do D7 (ID e intervalo agora são campos numéricos), o nascimento padrão de seis anos (D19), a cobertura no nível da ficha de "Data repetida" e "Peso fora do limite", a ordem dos diálogos (`presenting:`) e as mensagens de erro de banco em pt-BR. Registradas como pendências em Risks: tela de opções do ID automático, calendário gregoriano fixo e linhas com data ilegível.

## Decision

DECISION: PASS
