# Proposal

## Why

A pesquisa da Suzan acompanha crianças do ambulatório ao longo de várias consultas, e o módulo Avaliação individual do WHO AnthroPlus é onde esse acompanhamento longitudinal acontece: cadastro da criança, dos pais e do endereço, uma visita por data com peso, medida e edema, e o resultado de cada visita em z-score, percentil e cor de gravidade. Sem este módulo o app só calcula casos avulsos na Calculadora e não guarda o histórico que a pesquisa precisa.

## What Changes

- Cadastro de crianças com os campos do original (ID de exibição, nome, sobrenome, nascimento com marca de data aproximada, sexo obrigatório, notas, dados de acompanhamento) e vínculo opcional com mãe, pai e endereço, que podem ser compartilhados entre irmãos.
- Lista de crianças ativas ordenada pelo ID, marcação múltipla, arquivamento e restauração, visão do arquivo, exclusão com confirmação e remoção dos registros de mãe, pai e endereço que ficarem sem criança.
- Busca de crianças ativas por nome e sobrenome com curingas `*` e `?` sem diferenciar maiúsculas, por sexo, por faixa de ID e por faixa de nascimento.
- ID automático (maior ID existente mais 1) quando `AppSettings.autoAssignChildID` estiver ligado; ID manual editável quando estiver desligado.
- Visitas por data, uma por dia por criança: data (não anterior ao nascimento, fixa depois de criada), peso, medida, deitado ou em pé (escolha só abaixo de 11 meses), edema e notas; IMC exibido durante a edição.
- Campos numéricos com aviso inline: texto ilegível ou fora do intervalo fica fora do cálculo e bloqueia a gravação da visita ou do cadastro de mãe e pai (campo vazio é permitido), desvio deliberado do original para proteger o dado de pesquisa.
- Edição da criança e das suas visitas como unidade de trabalho: nada vai ao banco até Salvar; Cancelar descarta tudo; trocar de criança com alterações pendentes pergunta se salva.
- Resultado da visita selecionada (z-score, percentil e gravidade dos três indicadores via `AnthroEngine`) e a série de resultados de todas as visitas para o gráfico de crescimento da change `add-anthropometric-calculator`.
- Migração 2 do banco com as tabelas `children`, `visits`, `mothers`, `fathers` e `addresses`. A coluna `visits.additional_data` é criada aqui, mas o comportamento de dados adicionais é da change `add-additional-data`.
- Fora desta change: importação, exportação e relatório da criança (change `add-individual-import-export`), dados adicionais (change `add-additional-data`), listas geográficas SALB e de países, multiusuário.

## Capabilities

### New Capabilities
- `child-registry`: cadastro, listagem, busca, arquivamento, exclusão e ID automático de crianças, com mãe, pai e endereço vinculados e limpeza de órfãos.
- `visit-tracking`: visitas por data de cada criança, validação da entrada, unidade de trabalho com a criança, resultado antropométrico por visita e série de resultados para o gráfico.

### Modified Capabilities
- Nenhuma.

## Impact

- Código novo em `Sources/AnthroStore/` (migração 2, repositórios e casamento de nomes) e `Sources/AnthroFeatures/` (view models da lista, da ficha, do editor de visita e dos editores de mãe, pai e endereço); views em `Sources/AnthroPlusApp/IndividualAssessment/`.
- Testes em `Tests/AnthroStoreTests/` e `Tests/AnthroFeaturesTests/`, com banco SQLite em diretório temporário.
- Depende de `bootstrap-macos-app` (`AnthroDatabase`, `Migrations`, `AppSettings`, `L10n`, `ClinicalFormat`), de `port-anthro-engine` (`AnthroEngine`, `AnthropometricResult`, `SeverityClassifier`, `InputLimits`, `AgeMath`) e de `add-anthropometric-calculator` (`MeasurementInput`, `ApproximateBirthDate`, `AgeText` e `GrowthChartModel`).
- As changes `add-additional-data` e `add-individual-import-export` consomem as tabelas e os repositórios criados aqui.
