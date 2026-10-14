# Tasks

## 0. Red gate

- [x] 0.1 Write every scenario test from tests.md (`AppShellTests.swift`, `ClinicalFormatTests.swift`, `LocalDataStoreTests.swift`) and stubs with the exact signatures from Interface Under Test (neutral return values per tests.md Test Strategy, no logic); inclui `Package.swift` com os seis targets e os targets de teste, `git init` e `.gitignore` (`.build/`, `build/`, `.rlib/`, `reference/decompiled/`, `*.exe`), porque sem o manifesto os testes não compilam
- [x] 0.2 Run the scenario tests (`swift test`); confirm each FAILS BY ASSERTION (not import, syntax or collection errors); record each failure excerpt in the ledger
- [x] 0.3 Commit tests, stubs and manifest only as `test(red): bootstrap-macos-app`; write the SHA in the ledger
- [x] 0.4 STOP: show the user the failing tests and wait for explicit approval before implementing

## 1. Shell do app (app-shell)

- [x] 1.1 Implementar `AppSection`, `AppSettings` (chaves estáveis em `UserDefaults`) e `AppModel` (seleção, atalhos, gravação de `lastSection`); verified when [tests: primeiraAberturaMostraCalculadora, reaberturaLembraASecao, atalhoValidoSelecionaModulo, atalhoForaDoIntervaloNaoMudaSelecao, configuracoesTemValoresPadraoDoOriginal, configuracaoAlteradaSobreviveANovaInstancia] pass
- [x] 1.2 Implementar `L10n` (pt-BR, `allStrings`, `About`) e `AboutInfo`; verified when [tests: catalogoDeTextosSemBuracos, nomeDoAppEAnthroPlus, sobreAtribuiAOMS, versaoAusenteViraDesenvolvimento] pass
- [x] 1.3 Implementar `ClinicalFormat` com `Locale(identifier: "pt_BR")` fixo, unit tests first (inner loop: negativo zero, muitas casas, separador de milhar ausente); verified when [tests: formatacaoComVirgulaDecimal, valorIndefinidoViraND, leituraAceitaVirgulaEPonto, textoInvalidoNaoViraNumero] pass
- [x] 1.4 Implementar as views SwiftUI em `AnthroPlusApp`: `NavigationSplitView` com sidebar dos três módulos (estado vazio com título), toolbar, comandos ⌘1 a ⌘3 ligados a `AppModel.handleShortcut`, janela Sobre, tela de banco corrompido com botão "Restaurar último backup", e o modo `--self-test`; verificado pelo build e pela checagem manual de abertura da janela registrada no ledger
- [x] 1.5 Implementar `scripts/build-app.sh` (release, montagem do bundle, cópia de `*.bundle`, `Info.plist`, `iconutil`, `codesign` ad-hoc, `--install`, código 2 sem `VERSION`), `VERSION` e `assets/AppIcon.iconset/`; verified when as quatro checagens não executáveis de app-shell passam e ficam registradas no ledger
- [x] 1.6 Refactor `AnthroFeatures` (nomes, agrupamento de `L10n`); `swift test` stays green

## 2. Banco local (local-data-store)

- [x] 2.1 Implementar `SQLValue`, `Row`, `StoreError` e `AnthroDatabase` (abertura, pragmas, `execute`, `query` com bind de parâmetros, `transaction`, `integrityCheck`, `pragma`, `backup(to:)` pela API `sqlite3_backup_*`), unit tests first (inner loop: bind de Decimal como TEXT, data `yyyy-MM-dd`, NULL); verified when [tests: pragmasDeChaveEstrangeiraEWal] pass
- [x] 2.2 Implementar `transaction` reentrante com contador de profundidade e `SAVEPOINT` (design D4b); verified when [tests: transacaoAninhadaConfirmaComAExterna, erroNaAninhadaDesfazSoOTrechoDela, erroPropagadoDesfazTudo] pass
- [x] 2.3 Implementar `Migration`, `Migrations.all` com a migração 1 (`app_meta(key TEXT PRIMARY KEY, value TEXT NOT NULL)`, linha `created_at`) e o executor por `user_version` em transação; verified when [tests: bancoNovoChegaAUltimaVersao, migracaoComDefeitoFazRollback] pass
- [x] 2.4 Implementar `BackupManager` (nome em UTC, rotação por data de criação codificada no nome, `restoreLatest` guardando o arquivo corrompido); verified when [tests: backupComNomeDatado, rotacaoMantemDezBackups, primeiraAberturaSemBancoNaoFazBackup] pass
- [x] 2.5 Implementar `StoreController` (ordem: diretório, backup, abertura, integridade, migração; estados `.ready`, `.corrupted`, `.failed`; `restoreLatestBackup`; `exportCopy` sem sobrescrever); verified when [tests: primeiraAberturaCriaDiretorioEBanco, diretorioSemPermissaoFalha, arquivoCorrompidoNaoESobrescrito, restauracaoUsaBackupMaisRecente, semBackupLancaErro, copiaExportadaAbreComMesmaVersao, destinoExistenteNaoESobrescrito] pass
- [x] 2.6 Refactor `AnthroDatabase` e `StoreController` (tratamento de erro único do SQLite, fechamento de statements); `swift test` stays green

## 3. Verification

- [x] 3.1 Mutation check for app-shell: trocar `Locale(identifier: "pt_BR")` por `Locale(identifier: "en_US")` em `ClinicalFormat`, ver `formatacaoComVirgulaDecimal` falhar, reverter
- [x] 3.2 Mutation check for local-data-store: mover a gravação de `user_version` para antes do SQL da migração e fora da transação, ver `migracaoComDefeitoFazRollback` falhar, reverter
- [x] 3.3 Run the full suite fresh (`swift test`) and the four mechanical checks of app-shell; all green, output free of errors and warnings

## Workflow follow-up

- Produce evidence.md (`openspec instructions evidence --change bootstrap-macos-app`) and reach `DECISION: PASS`
- Archive the change
