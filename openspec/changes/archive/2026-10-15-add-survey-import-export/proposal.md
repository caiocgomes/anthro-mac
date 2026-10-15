# Proposal

## Why

O Inquérito nutricional quase nunca nasce digitado no app: as medidas das crianças chegam em planilhas do Excel, em arquivos do Epi Info ou do ENA (DBF, REC) e em XML do WHO Anthro. O original aceita esses formatos com um mapeamento de colunas e devolve os dados em XML, TXT e CSV. Sem isso, a Suzan teria de redigitar centenas de registros e não conseguiria levar resultados ao R, nem trocar inquéritos com quem usa o AnthroPlus de Windows.

## What Changes

- Importação de inquéritos de TXT, CSV, REC (Epi Info) e DBF (XBase) por uma tabela intermediária de colunas de texto, com as regras de `Delimited.ParseStream`, `DelimitedTextStream`, `External.ParseRECFile` e `External.ParseDBFFile`.
- Detecção de codificação (BOM, UTF-8, Windows-1252) e de separador (tabulação, ponto e vírgula ou vírgula) para arquivos vindos do Excel no Mac em pt-BR.
- Proposta automática de mapeamento de colunas para os 13 campos do inquérito (`NSImportDialog`), ajustável pela usuária, e montagem do inquérito com `Survey.CreateSurveyFromExternalData`: sexo obrigatório, linhas com sexo inválido descartadas e listadas (até 10), avisos para campos opcionais inválidos, derivação da medida deitada e colunas não mapeadas guardadas como dados adicionais.
- O inquérito importado e exportado é o `Survey` com seus `SurveyRecord` da change `add-nutritional-survey`, envolto num envelope de troca; opções e dados adicionais usam os codecs das changes 5 e 6. `CreatedBy` é escrito fixo e descartado na leitura, porque o app não tem multiusuário.
- O inquérito importado de arquivo externo abre como rascunho não salvo, com o nome do arquivo.
- Importação de XML do Anthro/AnthroPlus (`Survey.ImportSurveysFromXML`), inclusive o formato do WHO Anthro com idade em dias, gravada numa transação.
- Exportação de inquéritos em XML (`ExportSurveysToXML`) e do inquérito selecionado em TXT e CSV (`ExportSurveyToDelimitedFile`), com resultados opcionais e colunas de dados adicionais.

## Capabilities

### New Capabilities
- `survey-data-exchange`: leitura de TXT, CSV, REC, DBF e XML de inquéritos, mapeamento de colunas, montagem do inquérito importado e exportação de inquéritos em XML, TXT e CSV.

### Modified Capabilities
- Nenhuma.

## Impact

- Código novo em `Sources/AnthroIO/SurveyExchange/` e `Sources/AnthroFeatures/SurveyExchange/` (`SurveyExchangeModel` e adaptador de repositório); testes em `Tests/AnthroIOTests/` e `Tests/AnthroFeaturesTests/SurveyExchange/`, fixtures em `Tests/AnthroIOTests/Fixtures/`.
- Reaproveita da change `add-individual-import-export` `FieldWriter`, `FieldParser`, `DelimitedWriter`, `DelimitedFormat`, `ImportFailure`, `ImportFieldError`, `ImportFailureDetail`, `AdditionalValueText` e `ExchangeDefaults`, e depende dela.
- Depende de `add-nutritional-survey` (`Survey`, `SurveyRecord`, `SurveyOptions` com `init(xml:)` e `xml()`, `SurveyRecordEvaluation`, `SurveyRepository` e o editor de inquérito que recebe o rascunho), `add-additional-data` (`AdditionalData`, `AdditionalDataSection`, `AdditionalDataVariable`, `AdditionalDataXML`, `AdditionalDataColumns`), `bootstrap-macos-app` (grafo de targets, `AnthroDatabase.transaction`, `L10n`) e `port-anthro-engine` (`AnthroEngine`, `AgeMath`, `ClinicalRounding`, `InputLimits`).
- Sem dependências externas.
