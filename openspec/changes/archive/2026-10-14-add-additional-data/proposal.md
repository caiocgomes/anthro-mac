# Proposal

## Why

A pesquisa da Suzan não se resume a peso e altura: o modelo teórico dela cruza antropometria com variáveis de contexto (comportamento alimentar, atividade física, escolaridade, adesão), e o WHO AnthroPlus permite anexar essas variáveis a cada visita e a cada registro de inquérito por meio dos "dados adicionais". Sem essa capacidade, as variáveis extras ficariam numa planilha separada, com risco de desalinhar criança e medida. Esta change vem depois da avaliação individual (change 4) e do inquérito (change 5), porque dá estrutura ao XML que essas changes já gravam sem interpretar.

## What Changes

- Modelo de dados adicionais com seções e variáveis de texto, número (com mínimo e máximo opcionais) e data, como `AdditionalData`, `Section`, `Text`, `Num` e `Date` do original.
- Leitura e escrita do XML `<Data><Cat><Txt|Num|Date>` byte a byte compatível com `AdditionalData.GetXML`, inclusive o formato de data `dd-MM-yyyy HH:mm:ss`.
- Modelo padrão da avaliação individual (`IAAdditionalDataTemplate`: Maturation, Physical activity, Food, Health), guardado no banco pela migração 4, editável pelo menu "Gerenciar dados adicionais" e copiado para cada visita nova.
- Definição por inquérito (`Survey.AdditionalDataDef`), editável no inquérito aberto e copiada para cada registro novo.
- Editor de definição com as regras de `AdditionalDataDialog`: incluir seção e variável, trocar tipo, mínimo e máximo coerentes, excluir, identificador obrigatório.
- Formulário de valores nas telas de visita e de registro, com validação de número e limites.
- Colunas de dados adicionais na tabela do inquérito (`GetDataStructure`), com formatação, ordenação, filtro e cópia.
- Rótulos em pt-BR para os identificadores do modelo padrão, mantendo os identificadores originais em inglês no XML.

## Capabilities

### New Capabilities
- `additional-data`: estrutura, XML, modelo padrão da avaliação individual, definição por inquérito, editor de definição, entrada de valores e colunas na tabela do inquérito.

### Modified Capabilities
- Nenhuma. As integrações com `child-registry`, `visit-tracking` e `survey-management` são requisitos novos desta capability; os requisitos daquelas não mudam.

## Impact

- Código novo em `Sources/AnthroCore/AdditionalData/`, `Sources/AnthroStore/` (`AdditionalDataTemplateRepository`, `Migrations/Migration004_additional_data.swift`), `Sources/AnthroFeatures/AdditionalData/` e `Sources/AnthroPlusApp/AdditionalData/`.
- Alterações em código das changes 4 e 5: `VisitEditorModel` e `RecordEditorModel` ganham a propriedade `additionalData`; `SurveyDetailModel` ganha a edição da definição e as colunas; `SurveyTableColumn` ganha o caso `.additional`.
- Testes em `Tests/AnthroCoreTests`, `Tests/AnthroStoreTests` e `Tests/AnthroFeaturesTests`.
- Depende de `bootstrap-macos-app`, `add-individual-assessment` (`VisitRepository`, coluna de dados adicionais das visitas) e `add-nutritional-survey`.
