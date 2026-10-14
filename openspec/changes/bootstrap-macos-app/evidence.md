# Evidence

Pré-checagens (14/10/2026, 12h): commit vermelho `2a22a33` encontrado por `git log --format=%h --grep='^test(red)' -n 1`; `git rev-list --count 2a22a33..HEAD` = 11; tarefas não marcadas em `tasks.md` = 0.

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

- **Command**: `swift test` (depois de `rm -rf .build` e build limpo)
- **Result**: 38 passed, 0 failed, 0 skipped (30 de cenário e 8 do laço interno)
- **Output clean**: sim; build e testes sem `warning:` nem `error:`.
- **Checagens não executáveis** (ledger de app-shell, commit `daba3d4`): clone limpo com `swift build` e `swift test` em código 0; `swift build --product AnthroPlusMac` em código 1; `scripts/build-app.sh` gera o bundle com `CFBundleIdentifier` `local.suzan.anthroplus`, `codesign --verify` ok, `--self-test` em código 0, e o autoteste falha num `.app` sem o bundle de recursos; sem `VERSION`, o script sai com 2 e cita `VERSION` em stderr.

## TDD Path

TDD path: superpowers

## OpenSpec Verify

`openspec-verify-change` executado em 14/10/2026:

- **CRITICAL**: nenhum. 19 de 19 tarefas; 15 requisitos ADDED com implementação encontrada; 34 cenários cobertos (30 por teste, 4 por checagem de shell).
- **WARNING 1**: `Sources/AnthroPlusApp/DatabaseExporter.swift:17` apaga um arquivo existente depois que o usuário confirma "Substituir" no painel de salvar, e então chama `exportCopy(to:)`. A API cumpre "sem sobrescrever arquivo existente", mas a tela sobrescreve com confirmação. Recomendação: ajustar o texto do requisito "Exportar cópia do banco" para "sem sobrescrever arquivo existente sem confirmação do usuário", ou remover a remoção e mostrar erro; decisão da usuária (convenção do Mac favorece a primeira).
- **WARNING 2**: inspeção visual da janela pendente. A janela abre (CGWindowList: 1100 por 720), mas a captura de tela e a árvore de acessibilidade pelo REA foram negadas porque o Warp não tem Gravação de Tela nem Acessibilidade.
- **SUGGESTION**: `Sources/AnthroFeatures/Exports.swift` usa `@_exported import` (atributo sublinhado do Swift) para manter o app dependendo só de `AnthroFeatures`, como pede o design D1. Alternativa estável: declarar `AnthroCore` e `AnthroStore` como dependências diretas do executável em `Package.swift`.

## Decision

DECISION: PASS
