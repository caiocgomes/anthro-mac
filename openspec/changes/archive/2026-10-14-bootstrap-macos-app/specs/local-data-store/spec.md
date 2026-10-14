# Spec Delta

## ADDED Requirements

### Requirement: Local do banco de dados
O sistema SHALL guardar o banco em `~/Library/Application Support/AnthroPlus/anthroplus.sqlite`, criando o diretório na primeira abertura, e SHALL reaproveitar o arquivo existente nas aberturas seguintes.

#### Scenario: Primeira abertura cria diretório e banco
- **WHEN** `StoreController.openOnLaunch()` roda com um diretório que ainda não existe
- **THEN** o diretório e `anthroplus.sqlite` passam a existir e `state` é `.ready`

#### Scenario: Diretório sem permissão de escrita
- **WHEN** `StoreController.openOnLaunch()` roda com um diretório pai somente leitura
- **THEN** `state` é `.failed` com mensagem não vazia e nenhum arquivo é criado

### Requirement: Migrações versionadas
O sistema SHALL aplicar em ordem crescente as migrações com versão maior que `PRAGMA user_version`, cada uma numa transação que grava a nova versão; uma migração que falha SHALL desfazer suas alterações e lançar `StoreError.migrationFailed` com o número dela.

#### Scenario: Banco novo chega à última versão
- **WHEN** `AnthroDatabase.open` abre um arquivo novo com as migrações 1 e 2
- **THEN** `schemaVersion()` é 2 e a tabela `app_meta` existe

#### Scenario: Migração com defeito
- **WHEN** um banco na versão 1 é aberto com uma migração 2 cujo SQL é inválido
- **THEN** a abertura lança `StoreError.migrationFailed(version: 2, ...)` e, ao reabrir só com a migração 1, `schemaVersion()` continua 1

### Requirement: Integridade ao abrir
Ao abrir, o sistema SHALL ativar `foreign_keys` e `journal_mode = WAL`, rodar `PRAGMA integrity_check` e, se o resultado não for `ok`, entrar no estado `.corrupted` sem migrar.

#### Scenario: Pragmas ativos
- **WHEN** o banco é aberto
- **THEN** `pragma("foreign_keys")` é `"1"` e `pragma("journal_mode")` é `"wal"`

#### Scenario: Arquivo corrompido
- **WHEN** `openOnLaunch()` encontra um `anthroplus.sqlite` com bytes aleatórios
- **THEN** `state` é `.corrupted` e o arquivo corrompido não é sobrescrito

### Requirement: Backup automático ao abrir
Antes de migrar, se o banco já existir, o sistema SHALL copiá-lo pela API de backup do SQLite para `Backups/anthroplus-AAAAMMDD-HHMMSS.sqlite` e SHALL manter só os 10 backups mais recentes.

#### Scenario: Backup com nome datado
- **WHEN** `backupOnLaunch` roda às 2026-10-14 10:30:05 UTC com um banco existente
- **THEN** existe `Backups/anthroplus-20261014-103005.sqlite` e ele abre com as mesmas linhas de `app_meta` do original

#### Scenario: Rotação dos backups
- **WHEN** já existem 10 backups e `backupOnLaunch` roda mais uma vez
- **THEN** continuam existindo 10 backups e o mais antigo foi removido

#### Scenario: Primeira abertura sem banco
- **WHEN** `backupOnLaunch` roda sem `anthroplus.sqlite` no diretório
- **THEN** a função devolve `nil` e o diretório `Backups` não recebe arquivo

### Requirement: Restauração do último backup
No estado `.corrupted`, o sistema SHALL restaurar o backup mais recente sobre o banco, guardando o arquivo corrompido como `anthroplus.corrupted-AAAAMMDD-HHMMSS.sqlite`, e SHALL lançar `StoreError.backupNotFound` se não houver backup.

#### Scenario: Restauração com backup disponível
- **WHEN** `restoreLatestBackup()` roda no estado `.corrupted` com 3 backups
- **THEN** o banco passa a ter o conteúdo do backup mais recente, o arquivo corrompido foi renomeado e `state` é `.ready`

#### Scenario: Sem backup para restaurar
- **WHEN** `restoreLatestBackup()` roda no estado `.corrupted` sem nenhum backup
- **THEN** a chamada lança `StoreError.backupNotFound` e `state` continua `.corrupted`

### Requirement: Exportar cópia do banco
O sistema SHALL gravar uma cópia consistente do banco aberto num caminho escolhido pelo usuário. `exportCopy(to:)` SHALL recusar destino existente; a tela só substitui um arquivo existente depois que o usuário confirma a substituição no painel de salvar do macOS.

#### Scenario: Cópia exportada
- **WHEN** `exportCopy(to:)` recebe um caminho livre com o banco aberto
- **THEN** o arquivo existe, abre como SQLite e tem o mesmo `schemaVersion()` do banco aberto

#### Scenario: Destino já existe
- **WHEN** `exportCopy(to:)` recebe o caminho de um arquivo existente
- **THEN** a chamada lança erro e o arquivo existente fica com o mesmo tamanho e a mesma data de modificação

### Requirement: Transações aninhadas
`AnthroDatabase.transaction` SHALL ser reentrante: a transação mais externa usa `BEGIN IMMEDIATE`/`COMMIT`, e cada chamada aninhada usa `SAVEPOINT`/`RELEASE`; um erro dentro de uma chamada aninhada SHALL desfazer só o trecho dela (`ROLLBACK TO`) e ser propagado.

#### Scenario: Transação aninhada confirma com a externa
- **WHEN** uma transação insere a linha A e, dentro dela, uma transação aninhada insere a linha B
- **THEN** `transactionDepth` vale 2 dentro da aninhada, 0 depois do retorno, e as linhas A e B existem

#### Scenario: Erro na aninhada capturado pela externa
- **WHEN** a transação aninhada insere B e lança erro, e a externa captura o erro e insere C
- **THEN** existem as linhas A e C e não existe a linha B

#### Scenario: Erro propagado desfaz tudo
- **WHEN** a transação aninhada insere B e lança erro que a externa não captura
- **THEN** dentro da aninhada, antes do erro, a linha B é visível numa consulta; depois, a chamada externa lança o mesmo erro e nenhuma das linhas A e B existe
