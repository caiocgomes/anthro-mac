# Proposal

## Why

A pesquisa da Suzan mede 300 a 500 crianças em um ou poucos momentos de coleta, um registro por criança, exatamente o caso de uso do módulo Inquérito nutricional do WHO AnthroPlus. Sem ele, ela teria de digitar cada criança na calculadora ou manter a coleta numa planilha à parte, sem z-scores, flags de plausibilidade nem conferência visual. Esta change entrega o cadastro e a revisão dos dados do inquérito; análise, relatórios, gráficos e importação vêm nas changes 8 e 9, que dependem dela.

## What Changes

- Lista de inquéritos com criação, nome obrigatório, notas, arquivamento, restauração e exclusão (com os registros), em ordem de nome, como `NSMain` e `Survey`.
- Edição transacional do inquérito aberto: inclusões, edições e exclusões de registros, nome, notas e opções ficam pendentes até Salvar, com aviso ao trocar de inquérito ou fechar, como `NSMain.AskForSave`.
- Editor de registro com os campos de `Records` (data da pesquisa, conglomerado, equipe, ID, domicílio, fator de peso, nome, nascimento exato, aproximado ou desconhecido com idade em meses, sexo, peso, medida, deitado ou em pé, edema, notas), limites de entrada, IMC calculado e atribuição automática de IDs (`Survey.GetNew*ID`).
- Resultado antropométrico de cada registro pelo `AnthroEngine`, com flags de plausibilidade que usam os limites de z do próprio inquérito (`Record.IsFlagged`, incluindo a regra de peso para idade acima de 108 meses).
- Tabela de registros com as 19 colunas do original, destaque de z implausível, ordenação por coluna, filtro iterativo (`NSFilterDialog`, `NSMain.FilterRecords`), limpeza do filtro, contagem e cópia das linhas selecionadas para a área de transferência em formato de planilha.
- Opções do inquérito (`SurveyOptions`): atribuição automática de IDs, faixas etárias, limites de z para padrões e referência, restauração dos padrões, persistência em XML compatível com o original, inclusive as chaves legadas do Anthro II.
- Migração 3 do banco com as tabelas `surveys` e `records`.
- **Fora desta change:** importação e exportação (change 8), análise, relatórios e gráficos (change 9), estrutura de dados adicionais (change 6; aqui o XML de dados adicionais é guardado e copiado sem interpretação).

## Capabilities

### New Capabilities
- `survey-management`: inquéritos, registros, opções, tabela de registros com ordenação, filtro e cópia, flags de plausibilidade por inquérito e persistência local.

### Modified Capabilities
- Nenhuma.

## Impact

- Código novo em `Sources/AnthroCore/Survey/` (modelos de domínio e regras puras, consumidos também pelas changes 8 e 9), `Sources/AnthroStore/` (`SurveyRepository`, `Migration003_survey.swift`), `Sources/AnthroFeatures/Survey/` (view models) e `Sources/AnthroPlusApp/Survey/` (views SwiftUI com `Table`).
- Testes em `Tests/AnthroCoreTests`, `Tests/AnthroStoreTests` e `Tests/AnthroFeaturesTests`.
- Depende de `bootstrap-macos-app` (banco, `L10n`, `ClinicalFormat`, `StoreController`) e de `port-anthro-engine` (`AnthroEngine`, `PlausibilityFlag`, `SeverityClassifier`). Pressupõe que `AnthroStore`, `AnthroIO` e `AnthroAnalysis` dependam de `AnthroCore` no `Package.swift`.
