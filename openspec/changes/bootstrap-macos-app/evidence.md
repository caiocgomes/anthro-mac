# Evidence

Regenerado em 14/10/2026, 12h25, depois das correções da verificação. Pré-checagens: commit vermelho `2a22a33` encontrado por `git log --format=%h --grep='^test(red)' -n 1`; `git rev-list --count 2a22a33..HEAD` = 15; tarefas não marcadas em `tasks.md` = 0.

## Red Gate Replay

- **Red commit**: `2a22a33` (`test(red): bootstrap-macos-app`)
- **How replayed**: worktree temporário destacado em `2a22a33` (`git worktree add --detach`), `swift test` no worktree, worktree removido em seguida.
- **Result**: 30 testes de cenário executados, 30 falharam, 0 passaram, 0 erros capturados ou fatais; todas as falhas são `Expectation failed`, `Issue recorded` ou `#require` (falha por asserção). As 4 linhas N/A do ledger são checagens de shell e não entram no replay.

## Test Freeze

- **Command**: `git diff 2a22a33..HEAD --stat -- Tests/AnthroFeaturesTests/AppShellTests.swift Tests/AnthroFeaturesTests/ClinicalFormatTests.swift Tests/AnthroStoreTests/LocalDataStoreTests.swift`
- **Changes found**: nenhuma. A correção da preparação de `rotacaoMantemDezBackups` (backups falsos escritos direto, em vez de copiados de um banco que o stub não cria) aconteceu antes do commit vermelho e já está nele. Arquivos de teste acrescentados depois do vermelho são do laço interno (`ClinicalFormatUnitTests`, `SQLValueUnitTests`, `AnthroDatabaseUnitTests`, `BackupManagerUnitTests`, `SelfTestUnitTests`), cada um visto falhando antes do código.

## Mutation Checks

| Capability | Mutation applied | Test that caught it | Reverted |
|------------|------------------|---------------------|----------|
| app-shell | `Locale(identifier: "pt_BR")` trocado por `"en_US"` no padrão de `ClinicalFormat.string` | `formatacaoComVirgulaDecimal` (esperado "16,5", recebido "16.5") | sim (`git diff` vazio no arquivo) |
| local-data-store | gravação de `PRAGMA user_version` movida para antes do SQL da migração e para fora da transação | `migracaoComDefeitoFazRollback` (esperado `schemaVersion() == 1` após migração com defeito) | sim (`git diff` vazio no arquivo) |

## Full Suite

- **Command**: `swift test` (depois de `rm -rf .build` e build limpo, no commit `7be18d7`)
- **Result**: 38 passed, 0 failed, 0 skipped (30 de cenário e 8 do laço interno)
- **Output clean**: sim; build e testes sem `warning:` nem `error:`.
- **Checagens não executáveis** (ledger de app-shell, commit `daba3d4`; `scripts/build-app.sh` repetido em `7f90b7f` com o mesmo resultado): clone limpo com `swift build` e `swift test` em código 0; `swift build --product AnthroPlusMac` em código 1; `scripts/build-app.sh` gera o bundle com `CFBundleIdentifier` `local.suzan.anthroplus`, `codesign --verify` ok, `--self-test` em código 0, e o autoteste falha num `.app` sem o bundle de recursos; sem `VERSION`, o script sai com 2 e cita `VERSION` em stderr.

## TDD Path

TDD path: superpowers

## OpenSpec Verify

`/opsx:verify bootstrap-macos-app` executado em 14/10/2026 (12h07) e correções aplicadas em seguida:

- **CRITICAL**: nenhum. 19 de 19 tarefas; 15 requisitos ADDED com implementação; 34 cenários cobertos (30 por teste, 4 por checagem de shell).
- **WARNING resolvido 1**: o nome "Calculadora antropométrica" aparecia cortado na sidebar. `RootView.swift` passou a `navigationSplitViewColumnWidth(min: 280, ideal: 300, max: 380)`; o mínimo é necessário porque o macOS restaura a largura salva da execução anterior. Conferido por captura do REA (`ev_48e96fd210210a5bef2fb573003a9a5301b270d64b1092d441166ea21fb31d89`): nome inteiro visível.
- **WARNING resolvido 2**: a tela de exportação substitui arquivo depois da confirmação do painel de salvar, e o requisito proibia substituir. Emenda de spec (design D10): `exportCopy(to:)` recusa destino existente (teste inalterado) e a tela só substitui com a confirmação do macOS.
- **Verificação visual**: janela capturada pelo REA com Gravação de Tela e Acessibilidade liberadas ao Warp. Árvore de acessibilidade (`ev_d357e067b942936d96bf72b832df4a8638ff8e6e9edfd14dcb02a22571d10a09`) com os três módulos, o estado vazio e a toolbar; app reaberto na seção salva, como em `reaberturaLembraASecao`.
- **SUGGESTION mantida**: `Sources/AnthroFeatures/Exports.swift` usa `@_exported import` para o app depender só de `AnthroFeatures` (design D1). Alternativa estável: dependências diretas do executável em `Package.swift`.

## Decision

DECISION: PASS
