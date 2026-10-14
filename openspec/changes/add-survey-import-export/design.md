# Design

## Context

No original, a troca de dados do Inquérito nutricional está em `reference/decompiled/bll/WHOAnthroPlus.BLL.Core/Survey.cs` (`ExportSurveyToDelimitedFile`, `ImportSurveysFromXML`, `ExportSurveysToXML`, `CreateSurveyFromExternalData`), `reference/decompiled/bll/WHOAnthroPlus.BLL.Core/Record.cs` (`GetAgeInMonths`, `GetAgeInDays`, `GetBMI`, `AnthroResult`), `reference/decompiled/bll/WHOAnthroPlus.BLL.Tools/ImportExport.cs` (`Delimited`, `DelimitedTextStream`, `External.ParseRECFile`, `External.ParseDBFFile`, `ParseField`), `reference/decompiled/exe/WHOAnthroPlus.PC.Forms/NSImportDialog.cs` (proposta de mapeamento) e `reference/decompiled/exe/WHOAnthroPlus.PC.Forms/NSMain.cs` (`importFromFileToolStripMenuItem_Click`, `tsbSurveyExport_Click`). Mensagens em `Texts.resx` e `Utils.DisplayImportError`, `DisplayImportWarningRows` e `DisplayImportWarningFields`.

Tipos reaproveitados, sem redefinição:
- change `add-individual-import-export` (7): `FieldWriter`, `FieldParser`, `DelimitedWriter`, `DelimitedFormat`, `ImportFailure`, `ImportFieldError`, `ImportFailureDetail`, `AdditionalValueText`, `ExchangeDefaults`;
- change `add-nutritional-survey` (5), em `AnthroCore/Survey`: `Survey`, `SurveyRecord`, `SurveyOptions` (`init(xml:)`, `xml()`), `SurveyRecordEvaluation` (`ageInMonths`, `ageInDays`, `result`, `displayedBMI`); em `AnthroStore`: `SurveyRepository`; em `AnthroFeatures`: o editor de inquérito;
- change `add-additional-data` (6), em `AnthroCore/AdditionalData`: `AdditionalData`, `AdditionalDataSection`, `AdditionalDataVariable`, `AdditionalDataXML`, `AdditionalDataColumns`.

Como `Survey` e `SurveyRecord` estão em `AnthroCore`, de que `AnthroIO` depende, esta change não tem estrutura de registro própria: o envelope `ExchangeSurvey` carrega o `Survey` e seus `SurveyRecord`. Não há arquivos reais de Epi Info, ENA, WHO Anthro ou AnthroPlus nesta máquina: as fixtures são construídas a partir do layout lido no código.

## Goals / Non-Goals

**Goals:**
- Ler TXT, CSV, REC, DBF e XML de inquéritos com as regras do original, e TXT e CSV vindos do Excel no Mac em pt-BR.
- Montar o inquérito importado exatamente como `CreateSurveyFromExternalData`, inclusive descarte de registros, avisos e derivação da medida.
- Exportar em XML, TXT e CSV no layout do original.

**Non-Goals:**
- Escrever REC ou DBF.
- Ler XLSX diretamente (a usuária salva como CSV).
- Codec próprio de opções do inquérito ou de dados adicionais (ficam com as changes 5 e 6).
- Guardar `CreatedBy` (multiusuário fora de escopo).

## Interface Under Test

| Entry point | Signature | File |
|-------------|-----------|------|
| Envelope | `public struct ExchangeSurvey: Equatable, Sendable { public var survey: Survey; public var records: [SurveyRecord]; public init(survey: Survey, records: [SurveyRecord]) }` | `Sources/AnthroIO/SurveyExchange/ExchangeSurvey.swift` |
| Tipo de arquivo | `public enum SurveyFileKind: Equatable, Sendable { case delimited(fallbackSeparator: Character), rec, dbf, xml; public static func forFileExtension(_ fileExtension: String) -> SurveyFileKind }` | `Sources/AnthroIO/SurveyExchange/SurveyFileKind.swift` |
| Texto | `public enum TextDecoding { public static func decode(_ data: Data) -> String }` | `Sources/AnthroIO/SurveyExchange/TextDecoding.swift` |
| Separador | `public enum SeparatorDetector { public static func detect(firstLine: String, fallback: Character) -> Character }` | `Sources/AnthroIO/SurveyExchange/SeparatorDetector.swift` |
| Tabela | `public struct ImportedTable: Equatable, Sendable { public var columns: [String]; public var rows: [[String]]; public init(columns: [String], rows: [[String]]) }` | `Sources/AnthroIO/SurveyExchange/ImportedTable.swift` |
| Delimitado | `public enum DelimitedParser { public static func parse(_ text: String, separator: Character) throws(ImportFailure) -> ImportedTable }` | `Sources/AnthroIO/SurveyExchange/DelimitedParser.swift` |
| REC | `public enum RECParser { public static func parse(_ text: String) throws(ImportFailure) -> ImportedTable }` | `Sources/AnthroIO/SurveyExchange/RECParser.swift` |
| DBF | `public enum DBFParser { public static func parse(_ data: Data) throws(ImportFailure) -> ImportedTable }` | `Sources/AnthroIO/SurveyExchange/DBFParser.swift` |
| Leitura externa | `public enum ExternalTableReader { public static func read(_ data: Data, kind: SurveyFileKind) throws(ImportFailure) -> ImportedTable }` (decodifica, detecta separador e chama o parser; `.xml` lança `invalidStructure`) | `Sources/AnthroIO/SurveyExchange/ExternalTableReader.swift` |
| Campos | `public enum SurveyImportField: String, CaseIterable, Sendable { case date = "Date", cluster = "Cluster", team = "Team", displayID = "DisplayID", household = "Household", weightingFactor = "WeightingFactor", dateOfBirth = "DateOfBirth", ageInMonths = "AgeInMonths", sex = "Sex", weight = "Weight", height = "Height", isRecumbent = "IsRecumbent", hasOedema = "HasOedema" }` | `Sources/AnthroIO/SurveyExchange/SurveyImportField.swift` |
| Proposta | `public enum ColumnAutoMapper { public static func propose(columns: [String]) -> [SurveyImportField: String] }` | `Sources/AnthroIO/SurveyExchange/ColumnAutoMapper.swift` |
| Montagem | `public struct ExternalImportResult: Equatable, Sendable { public var draft: ExchangeSurvey; public var rowErrors: [ImportFieldError]; public var hadFieldWarnings: Bool }` e `public enum ExternalSurveyBuilder { public static let importedSectionID: String /* "Imported" */; public static let importedSectionDescription: String /* "Dados importados de arquivo externo." */; public static func build(table: ImportedTable, mapping: [SurveyImportField: String], name: String) throws(ImportFailure) -> ExternalImportResult }` | `Sources/AnthroIO/SurveyExchange/ExternalSurveyBuilder.swift` |
| XML | `public enum SurveyXML { public static func data(_ surveys: [ExchangeSurvey], resultsEngine: AnthroEngine?) -> Data; public static func read(_ data: Data) throws(ImportFailure) -> [ExchangeSurvey] }` (`resultsEngine` `nil` exporta sem resultados) | `Sources/AnthroIO/SurveyExchange/SurveyXML.swift` |
| Delimitado de inquérito | `public enum SurveyDelimitedExport { public static let baseColumns: [String]; public static let resultColumns: [String]; public static func data(_ survey: ExchangeSurvey, resultsEngine: AnthroEngine?, format: DelimitedFormat) -> Data }` | `Sources/AnthroIO/SurveyExchange/SurveyDelimitedExport.swift` |
| Portas | `public protocol SurveyExchangeSource { func surveysForExport(ids: [Int64]) throws -> [ExchangeSurvey] }`, `public protocol SurveyImportSink { func insertAll(_ surveys: [ExchangeSurvey]) throws -> Int }` e `@MainActor public protocol SurveyDraftPresenter: AnyObject { func presentDraft(_ draft: ExchangeSurvey) }` | `Sources/AnthroFeatures/SurveyExchange/SurveyExchangePorts.swift` |
| Adaptador | `public struct RepositorySurveyExchange: SurveyExchangeSource, SurveyImportSink { public init(database: AnthroDatabase, surveys: SurveyRepository) }` | `Sources/AnthroFeatures/SurveyExchange/RepositorySurveyExchange.swift` |
| Modelo da tela | `public enum SurveyExportFormat: CaseIterable, Sendable { case xml, tabText, semicolonCSV }`, `public enum SurveyExportWarning: Equatable, Sendable { case onlyFirstSurveyExported }` e `@MainActor @Observable public final class SurveyExchangeModel { public enum Phase: Equatable { case idle, mapping(columns: [String], mapping: [SurveyImportField: String]), finished(warning: String?), failed(message: String) }; public init(source: any SurveyExchangeSource, sink: any SurveyImportSink, presenter: any SurveyDraftPresenter, engine: AnthroEngine); public private(set) var phase: Phase; public var selectedSurveyIDs: [Int64]; public var includeResults: Bool; public var canExport: Bool { get }; public func beginImport(from url: URL); public func setMapping(_ field: SurveyImportField, column: String?); public func confirmMapping(); public func cancelImport(); public func export(format: SurveyExportFormat, to url: URL) throws -> SurveyExportWarning?; public static func message(for failure: ImportFailure, fileName: String) -> String; public static func warningMessage(rowErrors: [ImportFieldError], hadFieldWarnings: Bool, fileName: String) -> String? }` | `Sources/AnthroFeatures/SurveyExchange/SurveyExchangeModel.swift` |

## Decisions

**D1. Tabela intermediária de texto.** Como o original (que converte tudo para `DataTable` de strings), TXT, CSV, REC e DBF viram `ImportedTable` e só então `ExternalSurveyBuilder` aplica o mapeamento. Cada leitor é testado isoladamente com fixtures pequenas.

**D2. Leitor pela extensão.** `NSMain` decide pelo sufixo em minúsculas e manda qualquer outro para `ImportSurveysFromXML`. Mantemos, inclusive o caso de extensão desconhecida tratada como XML.

**D3. Codificação na leitura.** O original lê texto com `StreamReader(..., Encoding.UTF8)`, que respeita BOM e troca bytes inválidos por U+FFFD; um CSV salvo pelo Excel de Windows em Windows-1252 perderia os acentos (`Jo?o`). `TextDecoding` respeita BOM UTF-8, UTF-16 LE e BE; sem BOM, decodifica UTF-8 estrito e, se falhar, Windows-1252. Escolhemos Windows-1252 como segunda opção porque é o formato de quem exporta CSV, DBF e REC em Windows, de onde vêm os arquivos de inquérito. O Excel para Mac atual oferece "CSV UTF-8", que cai no primeiro caso. Mac Roman não é detectado (risco abaixo).

**D4. Separador.** O original usa tabulação para `.txt` e ponto e vírgula para `.csv`, sem detectar. No Mac em pt-BR, o Excel grava CSV com ponto e vírgula, mas planilhas exportadas por outros sistemas usam vírgula. `SeparatorDetector` conta tabulação, ponto e vírgula e vírgula fora de aspas na primeira linha e escolhe o mais frequente; empate ou ausência usa o padrão do original para a extensão. Como `FieldParser` troca vírgula por ponto nos números (`ParseField`), `16,5` continua valendo 16.5 com ponto e vírgula como separador; esse parsing fica no `AnthroIO`, sem o parser de entrada de tela.

**D5. Cabeçalho sempre presente.** `ParseFile` é sempre chamado com `includeHeader: true`; o original não detecta cabeçalho. Mantemos a primeira linha como cabeçalho, com nomes `ColumnN` para vazios, repetidos e campos excedentes (`GetNextColumnHeader`). Uma detecção heurística erraria com cabeçalhos numéricos e mudaria o comportamento do original.

**D6. Linhas vazias e registros curtos.** No original, uma linha vazia no meio do arquivo vira um registro com um campo vazio, e um registro curto deixa células `DBNull`; o cast `(string)dataRow[coluna]` em `CreateSurveyFromExternalData` então lança `InvalidCastException`, e o arquivo inteiro cai como formato inválido. Aqui linhas vazias são ignoradas e células faltantes valem texto vazio. É divergência deliberada de robustez, sem efeito em arquivos que o original aceita.

**D7. REC como `ParseRECFile`.** Primeiro token da primeira linha é o número de campos; cada descritor tem nome no token 1 e largura no token 8; largura 0 é ignorada; linha de exatamente 79 caracteres perde o último (marcador de continuação) e continua na seguinte até completar a largura total; linha com menos de 2 caracteres não gera registro; valores sem espaço e NUL nas pontas. Qualquer falha vira `invalidStructure`.

**D8. DBF lido por bytes.** O original lê com `BinaryReader` e `ReadChars`, que decodifica UTF-8: com acentos em Latin-1, o número de bytes consumidos muda e os campos seguintes se desalinham. Lemos por bytes (largura do descritor), decodificamos cada valor com a regra de D3 e começamos os registros no deslocamento do tamanho do cabeçalho (em vez de um byte após os descritores), o que também cobre DBF com bytes extras no cabeçalho. Registros com marcador `*` (apagados) são ignorados, enquanto o original os importava; para dados de pesquisa, reaparecer um registro apagado é um erro silencioso. Ambas são divergências deliberadas, e a do registro apagado está nas questões abertas para confirmação da usuária.

**D9. Proposta de mapeamento literal.** `ColumnAutoMapper` copia a ordem de testes de `NSImportDialog`: primeiro nomes exatos, depois `WEIGHT` e `HEIGHT`/`LENGTH` como substring, depois `MEASURE` e `EDEMA`/`OEDEMA`; colunas posteriores sobrescrevem anteriores. Por isso `WEIGHTFACTOR` vira peso; o cenário fixa a peculiaridade. A usuária corrige na etapa de mapeamento.

**D10. Montagem em `SurveyRecord`, como `CreateSurveyFromExternalData`.** O resultado é um `Survey` novo (`id` `nil`, opções `.default`, nome do arquivo) com `SurveyRecord`s. Sexo obrigatório no mapeamento (linha 0, campo `Sex`); registro com sexo inválido descartado, erros listados até 10 com linha `j + 1`; demais campos inválidos viram ausentes com aviso; fator de ponderação 1 por padrão (o `init` de `SurveyRecord`), 0 com aviso se mapeado e inválido; peso e altura por `FieldParser.decimal` com os limites de `InputLimits` (0.9 a 275 kg, 38 a 230 cm, os mesmos literais do original) e truncamento a 2 casas, gravados em `weight` e `lengthOrHeight`; fora dos limites o valor fica ausente com aviso, como no original, e não gera `ImportFieldError` (no original, só sexo inválido e campo obrigatório não mapeado geram erros por campo); idade em meses sem truncamento em `ageInMonths`; data da medição em `visitDate`; medida em `measuredRecumbent`, derivada, quando não mapeada ou inválida, por `SurveyRecordEvaluation.ageInDays` menor que 731 ou, sem idade, por altura menor que 87; edema ausente vira `false` em `hasOedema`. Os valores não são aparados, como `ParseField` sem `Trim`. Nome, sobrenome e observação não são mapeáveis, como no original.

**D11. Colunas não mapeadas pelo codec da change 6.** Viram uma seção `AdditionalDataSection(identifier: "Imported", description: "Dados importados de arquivo externo.")` com uma `AdditionalDataVariable(identifier: coluna, kind: .text(nil))` por coluna, na ordem da tabela, gravada em `survey.additionalDataDefinitionXML` por `AdditionalDataXML.encode`; cada registro recebe em `additionalDataXML` a mesma seção com `.text(valor)`. O original grava a descrição `Data imported from external file.`. Sem colunas não mapeadas, a definição e os XML dos registros ficam `nil`.

**D12. Rascunho, não gravação.** Como `NSMain`, a importação externa abre o inquérito como novo, com o nome do arquivo sem extensão, e só grava quando a usuária salva no editor da change 5 (`SurveyDraftPresenter.presentDraft`). A importação XML grava direto (`item.ApplyDataChanges()`), aqui numa única transação de `RepositorySurveyExchange.insertAll`, que chama `SurveyRepository.save(_:records:)` para cada inquérito; o original gravava inquérito a inquérito.

**D13. XML de inquéritos.** Leitura com `XMLParser` e as regras de `ImportSurveysFromXML`: `Name` e os campos não anuláveis do registro obrigatórios, opcionais ausentes aceitos como vazios (mesma divergência de robustez da change 7, D7), `HC` no primeiro registro indicando idade em dias (formato do WHO Anthro), qualquer falha vira `invalidStructure`. `Options` vira `SurveyOptions(xml:)` e erro dele rejeita o arquivo; `Options` ausente dá `SurveyOptions.default`. `AdditionalDataDef` e `AdditionalData` não vazios precisam passar por `AdditionalDataXML.decode` sem erro e são guardados como o texto lido em `additionalDataDefinitionXML` e `additionalDataXML`. Escrita como `ExportSurveysToXML`, com `Options` de `survey.options.xml()`, `AdditionalDataDef` só quando houver definição e `AdditionalData` sempre presente no registro, com `<Data />` (de `AdditionalDataXML.encode(AdditionalData())`) quando não houver dados (mesmo motivo da change 7, D8).

**D14. Idade exportada com 10 casas.** `Age` vem de `SurveyRecordEvaluation.ageInMonths` (idade guardada ou dias / 30.4375, como `GetAgeInMonths`). O original escreve a precisão total do `decimal` (cerca de 28 dígitos) por `ToString()`; escrevemos 10 casas, arredondadas por `ClinicalRounding.round`: suficiente para que `AgeMath.monthsToDays` devolva o mesmo número de dias na releitura, sem depender da precisão de 38 dígitos do `Decimal` do Swift.

**D15. Resultados pela avaliação da change 5.** Com `resultsEngine`, WAZ, HAZ e BAZ vêm de `SurveyRecordEvaluation.result(record, engine:)` (`Record.AnthroResult`) e BMI de `SurveyRecordEvaluation.displayedBMI` (`Record.GetBMI`). Decimais, datas e codificação seguem a change 7: TXT e CSV com vírgula decimal, UTF-8 com BOM e CRLF; XML com ponto decimal; datas `dd-MM-yyyy 00:00:00`. Colunas de dados adicionais por `AdditionalDataColumns.structure(of: definição decodificada, forbiddenKeys: colunas fixas e de resultado)`, valores por `AdditionalValueText`.

**D16. `CreatedBy` fixo e descartado (desvio deliberado).** O original escreve o usuário logado em `CreatedBy` de inquérito e registro e preserva o valor do arquivo na importação (`SetCreatedByImport`). `Survey` e `SurveyRecord` da change 5 não guardam criador, porque o app é de usuário único. A exportação escreve sempre `ExchangeDefaults.createdBy` (`AnthroPlus`); a importação lê o atributo, mantém a obrigatoriedade do original no `CreatedBy` do registro (`isNullable: false`), para aceitar e recusar os mesmos arquivos, e descarta o valor.

**D17. Conversão entre envelope e domínio.** `ExchangeSurvey` não duplica campos: é `Survey` mais `[SurveyRecord]`, os tipos da change 5. O adaptador `RepositorySurveyExchange` só lê com `SurveyRepository.survey(id:)` e `records(surveyID:)` e grava com `save(_:records:)`, zerando `id` de inquérito e registros importados. `SurveyDraftPresenter` entrega o envelope ao editor da change 5, que o abre como `SurveyDetailModel(survey:records:...)` não salvo.

## Divergências entre ajuda e código

| Tema | Ajuda (`reference/original-help/NS.htm`) | Código | Decisão |
|------|------------------------------------------|--------|---------|
| Formatos importados | "*.DBF, *.CSV, *.REC, *.TXT or *.XML" | o leitor é escolhido pela extensão e qualquer outra extensão vai para o leitor XML | seguir o código; cenário "Extensão desconhecida vira XML" |
| Exportação de vários inquéritos | "export any survey ... *.CSV, *.TXT and *.XML" | TXT e CSV exportam só o primeiro marcado, com aviso | seguir o código; cenário "Dois inquéritos em CSV" |
| Separador do CSV | "CSV" | `';'` na leitura e na escrita | seguir o código na escrita; na leitura, detecção (D4) com `';'` como padrão |

## Risks / Trade-offs

- [Fixtures montadas a partir do código, não de arquivos reais] -> `survey.rec`, `survey.dbf` (gerado por um construtor de bytes nos testes) e `ns-two-surveys.xml` seguem campo a campo os leitores do original. Arquivos reais de Epi Info, ENA ou WHO Anthro, quando aparecerem, entram como fixtures adicionais.
- [CSV em Mac Roman] -> Decodificado como Windows-1252, troca alguns acentos. O Excel para Mac atual grava UTF-8 quando se escolhe "CSV UTF-8"; a tela de mapeamento mostra os nomes de coluna, e a usuária vê o problema antes de confirmar.
- [Divergências de robustez (D6, D8)] -> Só mudam o resultado de arquivos que o original rejeitava ou lia desalinhados; ficam registradas aqui e nos cenários.
- [Transação aninhada] -> `insertAll` abre uma transação e chama `SurveyRepository.save(_:records:)`, que pode abrir a sua. Exige que `AnthroDatabase.transaction` seja reentrante (`SAVEPOINT` quando já houver transação aberta); se a change 1 não garantir isso, `doisInqueritosGravadosNumaTransacao` falha no primeiro run.
- [Dependência das changes 5, 6 e 7] -> Toda lógica de formato fica em `AnthroIO`, atrás de `SurveyExchangeSource`, `SurveyImportSink` e `SurveyDraftPresenter`; os testes de gravação usam `RepositorySurveyExchange` real sobre banco temporário com as migrações 1, 3 e 4.

## Open Questions

- **Registros apagados em DBF (D8).** O original importa registros marcados como apagados; esta change os ignora. Muda o que é construído e precisa do OK da usuária antes do red gate. Specs, testes e tarefas foram escritos com a decisão de ignorar; se a usuária preferir a fidelidade, mudam o cenário "Registro apagado", o teste `registroApagadoNoDbfEhIgnorado` e a tarefa 2.3.
