# Proposal

## Why

A Avaliação individual só serve à pesquisa da Suzan se os dados saem do app de forma que o R leia e que outro AnthroPlus (inclusive o de Windows, usado por coautores) importe sem perda. O original oferece relatório TXT por criança, exportação de crianças em XML, TXT e CSV e importação de XML; sem esses caminhos, as medidas das 300 a 500 crianças ficam presas no Mac e a análise estatística depende de redigitação.

## What Changes

- Relatório TXT da criança aberta, com cabeçalho, uma linha por visita (medidas, idade, z-scores) e nota de rodapé, no layout de `IAMain.GenerateChildReport`, em pt-BR e UTF-16 com BOM.
- Exportação das crianças marcadas em XML, TXT (tabulação) e CSV (ponto e vírgula), com os nomes de coluna, a ordem, a codificação de valores e o esquema XML de `Child.ExportChildrenToDelimitedFile` e `Child.ExportChildrenToXML`, opcionalmente com os resultados WAZ, HAZ, BAZ e IMC, mais as colunas de dados adicionais.
- Importação de crianças a partir de XML do Anthro/AnthroPlus, com as regras de `Child.ImportChildrenFromXML` e `CheckImportedVisitDates`: validação de cada atributo, truncamento de textos e medidas, rejeição do arquivo inteiro diante de valor inválido e gravação numa única transação. `CreatedBy` e níveis SALB do original são lidos e descartados, e a exportação escreve `CreatedBy` fixo, porque o app não tem multiusuário nem listas SALB.
- Escritores e leitores de campo compartilhados (`FieldWriter`, `FieldParser`, `DelimitedWriter`) no target `AnthroIO`, reaproveitados pela change `add-survey-import-export`. Dados adicionais usam o modelo, o codec XML e o layout de colunas da change `add-additional-data`, sem codec próprio.
- Mensagens de erro de importação em pt-BR equivalentes a `Utils.DisplayImportError`, com detalhe do elemento e do atributo que falhou.

## Capabilities

### New Capabilities
- `individual-data-exchange`: relatório TXT da criança, exportação de crianças em XML, TXT e CSV, importação de crianças em XML e as regras de codificação e leitura de campos usadas nessas trocas.

### Modified Capabilities
- Nenhuma.

## Impact

- Código novo em `Sources/AnthroIO/Exchange/` (estruturas de troca, campos, escritor delimitado, XML de crianças, relatório) e `Sources/AnthroFeatures/IndividualExchange/` (`ChildExchangeModel` e adaptador de repositórios); testes em `Tests/AnthroIOTests/` e `Tests/AnthroFeaturesTests/IndividualExchange/`, fixtures em `Tests/AnthroIOTests/Fixtures/`.
- Depende de `bootstrap-macos-app` (`AnthroDatabase.transaction`, `L10n`, grafo de targets em que `AnthroIO` depende de `AnthroCore` e não de `AnthroStore`), `port-anthro-engine` (`AnthroEngine`, `Anthropometry`, `AgeMath`, `ClinicalRounding`, `InputLimits`), `add-individual-assessment` (`ChildRecord`, `VisitRecord`, `ParentRecord`, `AddressRecord` e seus repositórios) e `add-additional-data` (`AdditionalData`, `AdditionalDataXML`, `AdditionalDataColumns`, `AdditionalDataTemplateRepository`).
- Sem dependências externas: XML lido com `XMLParser` do Foundation.
