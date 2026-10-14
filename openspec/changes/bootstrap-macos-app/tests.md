# Tests

## Test Strategy

- **Framework**: swift-testing (`import Testing`, `@Test`, `#expect`, `#require`), Swift 6.1.
- **Full-suite command**: `swift test`
- **Conventions**: testes de cenário em `Tests/AnthroFeaturesTests/` (app-shell) e `Tests/AnthroStoreTests/` (local-data-store). `UserDefaults(suiteName: "test-\(UUID())")` isolado por teste; bancos em `FileManager.default.temporaryDirectory/anthro-tests/<UUID>/`, removidos ao fim. Datas injetadas por `now`. Testes de `@MainActor` marcados com `@MainActor`. Stubs do portão vermelho: retornos opcionais devolvem valor neutro não nulo (`URL(fileURLWithPath: "/dev/null")`, `0`, `""`), propriedades guardadas começam no primeiro caso do enum ou `false`, funções `throws` não lançam, métodos de efeito não fazem nada.
- **Mutation tool**: manual.
- **Checagens não executáveis**: build limpo, produto inexistente e bundle `.app` são verificados por comandos de shell registrados no ledger, porque `swift test` não deve rodar `swift build -c release` dentro da suíte.

## Spec-to-Test Mapping

### Capability: app-shell

#### Scenario: Build e testes num clone limpo
- **Test name**: N/A (non-executable)
- **Test file**: mechanical check: `git clone . /tmp/anthro-clean && cd /tmp/anthro-clean && swift build && swift test`, ambos com código 0
- **Level**: integration
- **Breaks if**: um target depende de framework ausente nas Command Line Tools, ou um arquivo de teste fica fora de um target.
- **Expected red**: N/A (non-executable)

#### Scenario: Produto inexistente
- **Test name**: N/A (non-executable)
- **Test file**: mechanical check: `swift build --product AnthroPlusMac; test $? -ne 0`
- **Level**: integration
- **Breaks if**: o executável é renomeado sem atualizar `scripts/build-app.sh`.
- **Expected red**: N/A (non-executable)

#### Scenario: Bundle gerado e assinado
- **Test name**: N/A (non-executable)
- **Test file**: mechanical check: `scripts/build-app.sh && /usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' build/AnthroPlus.app/Contents/Info.plist | grep -qx local.suzan.anthroplus && codesign --verify build/AnthroPlus.app && build/AnthroPlus.app/Contents/MacOS/AnthroPlusApp --self-test`
- **Level**: integration
- **Breaks if**: o script não copia `AnthroPlus_AnthroCore.bundle` para `Contents/Resources` (o autoteste falha) ou esquece o `codesign`.
- **Expected red**: N/A (non-executable)

#### Scenario: Arquivo de versão ausente
- **Test name**: N/A (non-executable)
- **Test file**: mechanical check: `mv VERSION /tmp/VERSION.bak; scripts/build-app.sh 2>err.txt; test $? -eq 2 && grep -q VERSION err.txt; mv /tmp/VERSION.bak VERSION`
- **Level**: integration
- **Breaks if**: o script usa versão padrão silenciosa quando `VERSION` falta.
- **Expected red**: N/A (non-executable)

#### Scenario: Primeira abertura
- **Test name**: primeiraAberturaMostraCalculadora
- **Test file**: Tests/AnthroFeaturesTests/AppShellTests.swift
- **Level**: acceptance
- **Breaks if**: a ordem de `AppSection.allCases` muda, ou um título fica em inglês.
- **Expected red**: expected titles ["Calculadora antropométrica", "Avaliação individual", "Inquérito nutricional"], got ["", "", ""]

#### Scenario: Reabertura lembra a seção
- **Test name**: reaberturaLembraASecao
- **Test file**: Tests/AnthroFeaturesTests/AppShellTests.swift
- **Level**: acceptance
- **Breaks if**: `select` não grava `lastSection`, ou `AppModel.init` ignora `lastSection`.
- **Expected red**: expected .nutritionalSurvey, got .calculator

#### Scenario: Atalho válido
- **Test name**: atalhoValidoSelecionaModulo
- **Test file**: Tests/AnthroFeaturesTests/AppShellTests.swift
- **Level**: acceptance
- **Breaks if**: o atalho usa índice base 0 (⌘2 abriria o Inquérito).
- **Expected red**: expected true and .individualAssessment, got false and .calculator

#### Scenario: Atalho fora do intervalo
- **Test name**: atalhoForaDoIntervaloNaoMudaSelecao
- **Test file**: Tests/AnthroFeaturesTests/AppShellTests.swift
- **Level**: acceptance
- **Breaks if**: número fora do intervalo cai no último módulo (`min(n, 3)`).
- **Expected red**: expected .individualAssessment after select and shortcut 4, got .calculator (o `select` do stub não faz nada)

#### Scenario: Valores padrão
- **Test name**: configuracoesTemValoresPadraoDoOriginal
- **Test file**: Tests/AnthroFeaturesTests/AppShellTests.swift
- **Level**: acceptance
- **Breaks if**: `autoAssignChildID` passa a ter padrão `false` (o original usa `IAAutoID = True`).
- **Expected red**: expected useEnterForNextControl true, got false

#### Scenario: Valor alterado sobrevive a nova instância
- **Test name**: configuracaoAlteradaSobreviveANovaInstancia
- **Test file**: Tests/AnthroFeaturesTests/AppShellTests.swift
- **Level**: acceptance
- **Breaks if**: as propriedades guardam só em memória, ou a chave de `lastSection` difere entre leitura e escrita.
- **Expected red**: expected lastSection .individualAssessment, got .calculator

#### Scenario: Catálogo sem buracos
- **Test name**: catalogoDeTextosSemBuracos
- **Test file**: Tests/AnthroFeaturesTests/AppShellTests.swift
- **Level**: acceptance
- **Breaks if**: uma string nova é acrescentada como `""` provisório, ou `notAvailable` volta a ser `"N/A"`.
- **Expected red**: expected more than 20 strings and notAvailable "N/D", got 0 strings

#### Scenario: Nome do app
- **Test name**: nomeDoAppEAnthroPlus
- **Test file**: Tests/AnthroFeaturesTests/AppShellTests.swift
- **Level**: acceptance
- **Breaks if**: o nome é trocado para "WHO AnthroPlus", que sugere produto oficial da OMS.
- **Expected red**: expected "AnthroPlus", got ""

#### Scenario: Formatação com vírgula
- **Test name**: formatacaoComVirgulaDecimal
- **Test file**: Tests/AnthroFeaturesTests/ClinicalFormatTests.swift
- **Level**: acceptance
- **Breaks if**: o formatador usa `Locale.current` (num Mac em inglês daria "16.5") ou omite zeros à direita.
- **Expected red**: expected ["16,5", "-2,35", "0,00"], got ["", "", ""]

#### Scenario: Valor indefinido
- **Test name**: valorIndefinidoViraND
- **Test file**: Tests/AnthroFeaturesTests/ClinicalFormatTests.swift
- **Level**: acceptance
- **Breaks if**: `nil` é formatado como "0,00".
- **Expected red**: expected "N/D", got ""

#### Scenario: Leitura de vírgula e ponto
- **Test name**: leituraAceitaVirgulaEPonto
- **Test file**: Tests/AnthroFeaturesTests/ClinicalFormatTests.swift
- **Level**: acceptance
- **Breaks if**: o parser só aceita ponto, ou não remove espaços.
- **Expected red**: expected [16.5, 16.5, 20], got [0, 0, 0]

#### Scenario: Texto inválido
- **Test name**: textoInvalidoNaoViraNumero
- **Test file**: Tests/AnthroFeaturesTests/ClinicalFormatTests.swift
- **Level**: acceptance
- **Breaks if**: o parser troca todas as vírgulas por ponto e lê "1.2.3" como 1.2.
- **Expected red**: expected [nil, nil, nil], got [0, 0, 0]

#### Scenario: Conteúdo do Sobre
- **Test name**: sobreAtribuiAOMS
- **Test file**: Tests/AnthroFeaturesTests/AppShellTests.swift
- **Level**: acceptance
- **Breaks if**: a atribuição perde a versão do original ou as referências omitem um dos padrões.
- **Expected red**: expected attribution containing "WHO AnthroPlus 1.0.4", got ""

#### Scenario: Versão ausente no bundle
- **Test name**: versaoAusenteViraDesenvolvimento
- **Test file**: Tests/AnthroFeaturesTests/AppShellTests.swift
- **Level**: acceptance
- **Breaks if**: a ausência da chave devolve string vazia ou derruba o app com `!`.
- **Expected red**: expected "desenvolvimento", got ""

### Capability: local-data-store

#### Scenario: Primeira abertura cria diretório e banco
- **Test name**: primeiraAberturaCriaDiretorioEBanco
- **Test file**: Tests/AnthroStoreTests/LocalDataStoreTests.swift
- **Level**: integration
- **Breaks if**: `openOnLaunch` abre o banco sem criar o diretório intermediário.
- **Expected red**: expected state .ready and file exists, got state .closed

#### Scenario: Diretório sem permissão de escrita
- **Test name**: diretorioSemPermissaoFalha
- **Test file**: Tests/AnthroStoreTests/LocalDataStoreTests.swift
- **Level**: integration
- **Breaks if**: o erro do `createDirectory` é engolido e o estado fica `.ready` com banco em memória.
- **Expected red**: expected state .failed(non-empty), got .closed

#### Scenario: Banco novo chega à última versão
- **Test name**: bancoNovoChegaAUltimaVersao
- **Test file**: Tests/AnthroStoreTests/LocalDataStoreTests.swift
- **Level**: integration
- **Breaks if**: as migrações são aplicadas fora de ordem ou `user_version` não é gravado.
- **Expected red**: expected schemaVersion 2, got 0

#### Scenario: Migração com defeito
- **Test name**: migracaoComDefeitoFazRollback
- **Test file**: Tests/AnthroStoreTests/LocalDataStoreTests.swift
- **Level**: integration
- **Breaks if**: `user_version` é gravado antes de executar o SQL da migração, fora da transação.
- **Expected red**: expected thrown StoreError.migrationFailed(version: 2, ...), got no error

#### Scenario: Pragmas ativos
- **Test name**: pragmasDeChaveEstrangeiraEWal
- **Test file**: Tests/AnthroStoreTests/LocalDataStoreTests.swift
- **Level**: integration
- **Breaks if**: `PRAGMA foreign_keys = ON` é omitido (padrão do SQLite é desligado).
- **Expected red**: expected "1" and "wal", got nil and nil

#### Scenario: Arquivo corrompido
- **Test name**: arquivoCorrompidoNaoESobrescrito
- **Test file**: Tests/AnthroStoreTests/LocalDataStoreTests.swift
- **Level**: integration
- **Breaks if**: `open` recria o arquivo quando a abertura falha.
- **Expected red**: expected state .corrupted, got .closed

#### Scenario: Backup com nome datado
- **Test name**: backupComNomeDatado
- **Test file**: Tests/AnthroStoreTests/LocalDataStoreTests.swift
- **Level**: integration
- **Breaks if**: o nome usa fuso local ou formato com hífen na hora.
- **Expected red**: expected Backups/anthroplus-20261014-103005.sqlite, got /dev/null

#### Scenario: Rotação dos backups
- **Test name**: rotacaoMantemDezBackups
- **Test file**: Tests/AnthroStoreTests/LocalDataStoreTests.swift
- **Level**: integration
- **Breaks if**: a rotação ordena por nome de arquivo em ordem decrescente e apaga o mais novo.
- **Expected red**: expected oldest backup removed and new backup present, got oldest still present

#### Scenario: Primeira abertura sem banco
- **Test name**: primeiraAberturaSemBancoNaoFazBackup
- **Test file**: Tests/AnthroStoreTests/LocalDataStoreTests.swift
- **Level**: integration
- **Breaks if**: o backup cria um arquivo vazio quando não há banco.
- **Expected red**: expected nil, got /dev/null

#### Scenario: Restauração com backup disponível
- **Test name**: restauracaoUsaBackupMaisRecente
- **Test file**: Tests/AnthroStoreTests/LocalDataStoreTests.swift
- **Level**: integration
- **Breaks if**: a restauração escolhe o primeiro backup em ordem alfabética, o mais antigo.
- **Expected red**: expected app_meta row from newest backup and state .ready, got corrupted file untouched

#### Scenario: Sem backup para restaurar
- **Test name**: semBackupLancaErro
- **Test file**: Tests/AnthroStoreTests/LocalDataStoreTests.swift
- **Level**: integration
- **Breaks if**: sem backup, a restauração cria banco vazio e declara `.ready`.
- **Expected red**: expected thrown StoreError.backupNotFound, got no error

#### Scenario: Cópia exportada
- **Test name**: copiaExportadaAbreComMesmaVersao
- **Test file**: Tests/AnthroStoreTests/LocalDataStoreTests.swift
- **Level**: integration
- **Breaks if**: a cópia é feita com `FileManager.copyItem` sem incluir o WAL, perdendo transações recentes.
- **Expected red**: expected file at destination, got no file

#### Scenario: Destino já existe
- **Test name**: destinoExistenteNaoESobrescrito
- **Test file**: Tests/AnthroStoreTests/LocalDataStoreTests.swift
- **Level**: integration
- **Breaks if**: a exportação remove o destino antes de copiar.
- **Expected red**: expected thrown error, got no error

#### Scenario: Transação aninhada confirma com a externa
- **Test name**: transacaoAninhadaConfirmaComAExterna
- **Test file**: Tests/AnthroStoreTests/LocalDataStoreTests.swift
- **Level**: integration
- **Breaks if**: a chamada aninhada emite `BEGIN` de novo (o SQLite lança "cannot start a transaction within a transaction") ou o contador não volta a 0.
- **Expected red**: expected transactionDepth 2 inside the nested call, got 0

#### Scenario: Erro na aninhada capturado pela externa
- **Test name**: erroNaAninhadaDesfazSoOTrechoDela
- **Test file**: Tests/AnthroStoreTests/LocalDataStoreTests.swift
- **Level**: integration
- **Breaks if**: o erro na aninhada faz `ROLLBACK` da transação inteira (A some) ou não faz `ROLLBACK TO` (B fica).
- **Expected red**: expected rows [A, C] without B, got no rows (o `execute` do stub não grava)

#### Scenario: Erro propagado desfaz tudo
- **Test name**: erroPropagadoDesfazTudo
- **Test file**: Tests/AnthroStoreTests/LocalDataStoreTests.swift
- **Level**: integration
- **Breaks if**: a externa faz `COMMIT` mesmo com erro propagado pela aninhada.
- **Expected red**: expected row B visible inside the nested call, got 0 rows (o `execute` do stub não grava e o `query` devolve vazio)

## Coverage Ledger

| Capability | Scenario | Test file | Test name | Breaks if | Red (SHA: failure) | Green (SHA) | State |
|------------|----------|-----------|-----------|-----------|--------------------|-------------|-------|
| app-shell | Build e testes num clone limpo | shell | N/A (non-executable): clone + `swift build` + `swift test` | framework ausente | | | N/A (non-executable) |
| app-shell | Produto inexistente | shell | N/A (non-executable): `swift build --product AnthroPlusMac` falha | executável renomeado | | | N/A (non-executable) |
| app-shell | Bundle gerado e assinado | shell | N/A (non-executable): PlistBuddy + `codesign --verify` + `--self-test` | bundle de recursos não copiado | | | N/A (non-executable) |
| app-shell | Arquivo de versão ausente | shell | N/A (non-executable): código 2 e stderr com VERSION | versão padrão silenciosa | | | N/A (non-executable) |
| app-shell | Primeira abertura | AppShellTests.swift | primeiraAberturaMostraCalculadora | ordem ou idioma dos títulos | | | planned |
| app-shell | Reabertura lembra a seção | AppShellTests.swift | reaberturaLembraASecao | lastSection não gravado | | | planned |
| app-shell | Atalho válido | AppShellTests.swift | atalhoValidoSelecionaModulo | índice base 0 | | | planned |
| app-shell | Atalho fora do intervalo | AppShellTests.swift | atalhoForaDoIntervaloNaoMudaSelecao | clamp no último módulo | | | planned |
| app-shell | Valores padrão | AppShellTests.swift | configuracoesTemValoresPadraoDoOriginal | padrão false | | | planned |
| app-shell | Valor alterado sobrevive a nova instância | AppShellTests.swift | configuracaoAlteradaSobreviveANovaInstancia | só em memória | | | planned |
| app-shell | Catálogo sem buracos | AppShellTests.swift | catalogoDeTextosSemBuracos | string vazia | | | planned |
| app-shell | Nome do app | AppShellTests.swift | nomeDoAppEAnthroPlus | nome oficial da OMS | | | planned |
| app-shell | Formatação com vírgula | ClinicalFormatTests.swift | formatacaoComVirgulaDecimal | Locale.current | | | planned |
| app-shell | Valor indefinido | ClinicalFormatTests.swift | valorIndefinidoViraND | nil vira 0,00 | | | planned |
| app-shell | Leitura de vírgula e ponto | ClinicalFormatTests.swift | leituraAceitaVirgulaEPonto | só ponto | | | planned |
| app-shell | Texto inválido | ClinicalFormatTests.swift | textoInvalidoNaoViraNumero | vírgulas viram ponto | | | planned |
| app-shell | Conteúdo do Sobre | AppShellTests.swift | sobreAtribuiAOMS | atribuição sem versão | | | planned |
| app-shell | Versão ausente no bundle | AppShellTests.swift | versaoAusenteViraDesenvolvimento | string vazia | | | planned |
| local-data-store | Primeira abertura cria diretório e banco | LocalDataStoreTests.swift | primeiraAberturaCriaDiretorioEBanco | diretório não criado | | | planned |
| local-data-store | Diretório sem permissão de escrita | LocalDataStoreTests.swift | diretorioSemPermissaoFalha | erro engolido | | | planned |
| local-data-store | Banco novo chega à última versão | LocalDataStoreTests.swift | bancoNovoChegaAUltimaVersao | user_version não gravado | | | planned |
| local-data-store | Migração com defeito | LocalDataStoreTests.swift | migracaoComDefeitoFazRollback | versão gravada fora da transação | | | planned |
| local-data-store | Pragmas ativos | LocalDataStoreTests.swift | pragmasDeChaveEstrangeiraEWal | foreign_keys omitido | | | planned |
| local-data-store | Arquivo corrompido | LocalDataStoreTests.swift | arquivoCorrompidoNaoESobrescrito | arquivo recriado | | | planned |
| local-data-store | Backup com nome datado | LocalDataStoreTests.swift | backupComNomeDatado | fuso local | | | planned |
| local-data-store | Rotação dos backups | LocalDataStoreTests.swift | rotacaoMantemDezBackups | apaga o mais novo | | | planned |
| local-data-store | Primeira abertura sem banco | LocalDataStoreTests.swift | primeiraAberturaSemBancoNaoFazBackup | backup vazio | | | planned |
| local-data-store | Restauração com backup disponível | LocalDataStoreTests.swift | restauracaoUsaBackupMaisRecente | escolhe o mais antigo | | | planned |
| local-data-store | Sem backup para restaurar | LocalDataStoreTests.swift | semBackupLancaErro | banco vazio criado | | | planned |
| local-data-store | Cópia exportada | LocalDataStoreTests.swift | copiaExportadaAbreComMesmaVersao | cópia sem WAL | | | planned |
| local-data-store | Destino já existe | LocalDataStoreTests.swift | destinoExistenteNaoESobrescrito | destino removido | | | planned |
| local-data-store | Transação aninhada confirma com a externa | LocalDataStoreTests.swift | transacaoAninhadaConfirmaComAExterna | BEGIN aninhado | | | planned |
| local-data-store | Erro na aninhada capturado pela externa | LocalDataStoreTests.swift | erroNaAninhadaDesfazSoOTrechoDela | rollback total | | | planned |
| local-data-store | Erro propagado desfaz tudo | LocalDataStoreTests.swift | erroPropagadoDesfazTudo | commit com erro | | | planned |

## Test Changes After Red

<!-- Append-only. Vazio no planejamento. -->
