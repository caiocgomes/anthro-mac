# Design

## Context

O projeto está vazio: só o instalador original, `reference/` e a OpenSpec. A máquina tem Swift 6.1 com Command Line Tools, sem Xcode; um spike confirmou que SwiftPM compila um executável SwiftUI com Swift Charts e que `swift test` roda swift-testing. Sem Xcode não há asset catalog (`actool`), String Catalog compilado nem assinatura com Developer ID. O app roda num único Mac, o da Suzan, e guarda dados de pesquisa de 300 a 500 crianças, por isso a segurança do arquivo de dados pesa mais que qualquer conveniência.

## Goals / Non-Goals

**Goals:**
- `Package.swift` com os seis targets do layout do projeto e seus targets de teste, todos compilando desde a primeira change.
- Script que monta `build/AnthroPlus.app` instalável, com ícone e assinatura ad-hoc.
- Janela principal com sidebar dos três módulos, toolbar e atalhos, em pt-BR.
- Banco SQLite local com migrações versionadas, checagem de integridade, backup automático ao abrir e restauração.
- Formatação e leitura de números no padrão brasileiro (vírgula decimal).

**Non-Goals:**
- Conteúdo dos módulos (changes 3 a 9). Nesta change cada módulo mostra um estado vazio com título.
- Notarização, Developer ID, atualização automática, sincronização em nuvem.
- Localização além de pt-BR.

## Interface Under Test

| Entry point | Signature | File |
|-------------|-----------|------|
| Seção | `public enum AppSection: String, CaseIterable, Sendable, Codable { case calculator, individualAssessment, nutritionalSurvey; public var title: String; public var systemImage: String; public var shortcutNumber: Int }` | `Sources/AnthroFeatures/AppSection.swift` |
| Configurações | `@MainActor @Observable public final class AppSettings { public init(defaults: UserDefaults); public var useEnterForNextControl: Bool; public var autoAssignChildID: Bool; public var lastSection: AppSection }` | `Sources/AnthroFeatures/AppSettings.swift` |
| Modelo do app | `@MainActor @Observable public final class AppModel { public init(settings: AppSettings, store: StoreController); public var selectedSection: AppSection; public func select(_ section: AppSection); public func handleShortcut(number: Int) -> Bool }` | `Sources/AnthroFeatures/AppModel.swift` |
| Textos | `public enum L10n { public static let appName: String; public static let notAvailable: String; public static var allStrings: [String] { get }; public enum Section { ... }; public enum About { public static let attribution: String; public static let references: String } }` (todas as strings visíveis, pt-BR) | `Sources/AnthroFeatures/L10n.swift` |
| Formato clínico | `public enum ClinicalFormat { public static func string(_ value: Decimal?, places: Int, locale: Locale = Locale(identifier: "pt_BR")) -> String; public static func parseDecimal(_ text: String) -> Decimal? }` | `Sources/AnthroFeatures/ClinicalFormat.swift` |
| Valor SQL | `public enum SQLValue: Equatable, Sendable { case null, integer(Int64), real(Double), text(String), blob(Data); public init(_ decimal: Decimal?); public init(_ date: Date?); public var decimalValue: Decimal?; public var dateValue: Date? }` | `Sources/AnthroStore/SQLValue.swift` |
| Linha | `public struct Row: Sendable { public subscript(_ column: String) -> SQLValue { get } }` | `Sources/AnthroStore/Row.swift` |
| Migração | `public struct Migration: Sendable { public let version: Int; public let name: String; public let sql: String; public init(version: Int, name: String, sql: String) }` e `public enum Migrations { public static var all: [Migration] { get } }` | `Sources/AnthroStore/Migrations.swift` |
| Erros | `public enum StoreError: Error, Equatable { case sqlite(code: Int32, message: String); case corrupted(details: String); case migrationFailed(version: Int, message: String); case backupNotFound }` | `Sources/AnthroStore/StoreError.swift` |
| Banco | `public final class AnthroDatabase: @unchecked Sendable { public static func defaultDirectory() -> URL; public static func open(at url: URL, migrations: [Migration] = Migrations.all) throws -> AnthroDatabase; public func schemaVersion() throws -> Int; public func execute(_ sql: String, _ params: [SQLValue] = []) throws; public func query(_ sql: String, _ params: [SQLValue] = []) throws -> [Row]; public func lastInsertRowID() -> Int64; public func transaction<T>(_ body: () throws -> T) throws -> T; public var transactionDepth: Int { get }; public func integrityCheck() throws -> Bool; public func pragma(_ name: String) throws -> String?; public func backup(to url: URL) throws; public func close() }` | `Sources/AnthroStore/AnthroDatabase.swift` |
| Backups | `public enum BackupManager { public static func backupOnLaunch(databaseURL: URL, backupsDirectory: URL, keep: Int = 10, now: Date) throws -> URL?; public static func backups(in directory: URL) -> [URL]; public static func restoreLatest(from directory: URL, to databaseURL: URL) throws -> URL }` | `Sources/AnthroStore/BackupManager.swift` |
| Abertura | `@MainActor @Observable public final class StoreController { public init(directory: URL, now: @escaping () -> Date = Date.init); public enum State: Equatable { case closed, ready, corrupted(String), failed(String) }; public private(set) var state: State; public private(set) var database: AnthroDatabase?; public func openOnLaunch(); public func restoreLatestBackup() throws; public func exportCopy(to url: URL) throws }` | `Sources/AnthroStore/StoreController.swift` |
| Sobre | `public enum AboutInfo { public static func version(bundle: Bundle) -> String }` (devolve `CFBundleShortVersionString` ou `"desenvolvimento"`) | `Sources/AnthroFeatures/AboutInfo.swift` |
| Autoteste | `AnthroPlusApp --self-test`: confere que o diretório de recursos `who` do bundle do `AnthroCore` é encontrado (nesta change ele só contém `README.txt`; a change 2 passa a carregar `GrowthReferenceTables.bundled()`) e sai com código 0, ou 1 com a causa em stderr, sem abrir janela | `Sources/AnthroPlusApp/AnthroPlusApp.swift` |
| Build | `scripts/build-app.sh [--install]` (código 0 em sucesso; `--install` copia para `/Applications`, ou `~/Applications` sem permissão) | `scripts/build-app.sh` |

## Decisions

**D1. Seis targets desde o início.** `Package.swift` declara, já com `resources: [.copy("Resources/who")]` no `AnthroCore` (só um `README.txt` nesta change, para que o bundle de recursos exista e o script de build seja testado desde já), `AnthroCore`, `AnthroStore`, `AnthroIO`, `AnthroAnalysis`, `AnthroFeatures` e o executável `AnthroPlusApp`, cada um com um arquivo mínimo, mais os targets de teste. Grafo de dependências fixado aqui: `AnthroStore`, `AnthroIO` e `AnthroAnalysis` dependem de `AnthroCore`; `AnthroFeatures` depende dos quatro; `AnthroPlusApp` depende de `AnthroFeatures`; cada `Tests/<Target>Tests` depende do seu target (e `AnthroFeaturesTests` também de `AnthroStore` para bancos temporários). `AnthroIO` não depende de `AnthroStore`: conversa com os repositórios por protocolos (portas) definidos nele mesmo. As changes seguintes só acrescentam arquivos, sem disputar edições no manifesto. Alternativa descartada: cada change criar seu target, o que gera conflitos de merge no `Package.swift`.

**D2. SQLite do sistema, sem dependência externa.** `import SQLite3` (libsqlite3 do macOS) com um wrapper fino. GRDB seria mais confortável, mas adiciona dependência e build mais lento sem ganho para um único usuário. `PRAGMA foreign_keys = ON` e `journal_mode = WAL` em toda abertura.

**D3. Convenções de persistência para as changes seguintes.** `Decimal` é gravado como TEXT na forma canônica (`description` com ponto), para não perder casas; datas como TEXT `yyyy-MM-dd`; instantes como TEXT ISO 8601 UTC; booleanos como INTEGER 0/1; sexo como INTEGER 1 = menino, 2 = menina (convenção da OMS). Numeração das migrações reservada: 1 `app_meta` (esta change), 2 avaliação individual (change 4), 3 inquérito (change 5), 4 dados adicionais (change 6). Cada change acrescenta `Sources/AnthroStore/Migrations/Migration00N_<nome>.swift` e o registra em `Migrations.all`.

**D4. Migrações por `PRAGMA user_version`.** Cada migração pendente roda dentro de uma transação que também grava o novo `user_version`; falha faz rollback e lança `StoreError.migrationFailed`, deixando a versão anterior intacta.

**D4b. Transações reentrantes.** Repositórios das changes 4 a 6 abrem transação em `save`, e os adaptadores de importação das changes 7 e 8 envolvem vários `save` numa transação única. Como o SQLite não aceita `BEGIN` aninhado, `transaction` mantém um contador: profundidade 0 abre com `BEGIN IMMEDIATE`, profundidades maiores criam `SAVEPOINT sp_<n>`; erro faz `ROLLBACK TO sp_<n>` e `RELEASE` (ou `ROLLBACK` na externa) e é propagado. O banco é usado só pela thread principal (`StoreController` é `@MainActor`), então o contador não precisa de trava.

**D5. Backup ao abrir, antes de migrar.** `StoreController.openOnLaunch()` faz, nesta ordem: cria o diretório, roda `BackupManager.backupOnLaunch` se o banco já existir (cópia pela API de backup online do SQLite para `Backups/anthroplus-AAAAMMDD-HHMMSS.sqlite`, mantendo os 10 mais recentes), abre, roda `integrity_check` e migra. Integridade falha leva ao estado `.corrupted`, e a UI oferece restaurar o backup mais recente. Assim uma migração com defeito nunca destrói o único exemplar dos dados.

**D6. Strings em enum Swift, não String Catalog.** Sem Xcode, `.xcstrings` não é compilado pelo SwiftPM de forma confiável. `L10n` concentra todas as strings em pt-BR; um teste garante que nenhuma está vazia. Se um dia houver segundo idioma, `L10n` vira a fachada de um catálogo.

**D7. Números no padrão brasileiro.** `ClinicalFormat.string` formata com casas fixas (`16,5`, `-2,35`) e devolve `L10n.notAvailable` (`"N/D"`) para `nil`, equivalente a `Texts._Value_NA` do original. `parseDecimal` aceita vírgula ou ponto como separador decimal e rejeita texto com dois separadores. O valor recebido já vem arredondado pelo `AnthroCore`; o formatador não arredonda de novo.

**D8. Bundle montado à mão.** `scripts/build-app.sh` roda `swift build -c release --product AnthroPlusApp`, monta `build/AnthroPlus.app/Contents/{MacOS,Resources}`, copia os bundles de recurso do SwiftPM (`*.bundle`), escreve `Info.plist` (`CFBundleIdentifier` `local.suzan.anthroplus`, `CFBundleName` AnthroPlus, `LSMinimumSystemVersion` 14.0, `CFBundleShortVersionString` lido de `VERSION`), gera `AppIcon.icns` com `iconutil` a partir de `assets/AppIcon.iconset/` e assina com `codesign --force --deep --sign -`. A primeira abertura em outro Mac pede clique direito e Abrir; no Mac da Suzan basta uma vez.

**D9. Atalhos.** ⌘1, ⌘2 e ⌘3 selecionam os módulos, na ordem de `AppSection.allCases`. A seção ativa é lembrada em `AppSettings.lastSection` e restaurada na próxima abertura.

## Risks / Trade-offs

- [Recursos do SwiftPM não encontrados dentro do .app montado à mão] -> O script copia `AnthroPlus_AnthroCore.bundle` para `Contents/Resources`; um teste de fumaça do script abre o executável com `--self-test`, que carrega as tabelas e sai com código 0.
- [Backup em cada abertura ocupa disco] -> Banco de 500 crianças fica na casa de poucos MB; 10 cópias são desprezíveis.
- [Sem Xcode, sem previews nem inspeção visual automática] -> Lógica toda nos view models testáveis; verificação visual vira checagem manual registrada como N/A (non-executable) com critério mecânico (build e `codesign --verify` passam).

## Open Questions

- Nenhuma que mude o que será construído.
