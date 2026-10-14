# Proposal

## Why

A Calculadora antropométrica é o módulo de uso mais imediato do AnthroPlus: no ambulatório, a Suzan informa datas, sexo, peso e medida e lê na hora z-score, percentil e gravidade de peso, estatura e IMC para idade, com o gráfico de crescimento ao lado. É também a primeira tela que prova, diante da usuária, que o núcleo portado em `port-anthro-engine` reproduz o original. O componente de gráfico nasce aqui porque a Avaliação individual e o Inquérito nutricional reutilizam o mesmo diálogo do original (`GraphDialog`).

## What Changes

- Tela da Calculadora no módulo `calculator` do app, com o comportamento de `ACMain`: datas de nascimento e de visita, data aproximada com dia sorteado, sexo, peso, medida, modo deitado ou em pé habilitado só abaixo de 11 meses, edema, IMC exibido e recálculo a cada alteração. Nada é salvo.
- Painel de resultados com o comportamento de `IndicatorDisplayPanel`: z-score com 2 casas, percentil com 1 casa, `N/D` para indefinido, cor de gravidade, barra de percentil e rótulo "Comprimento para idade" ou "Estatura para idade".
- Componente de gráfico de crescimento reutilizável com o comportamento de `GraphDialog`: curvas de DP ou de percentis, troca de indicador e de modo, um ou vários pontos de medida, zoom por área, deslocamento e reset, copiar imagem, exportar PNG ou PDF e imprimir.
- Strings pt-BR novas em `L10n` para a Calculadora e o gráfico.

## Capabilities

### New Capabilities
- `anthropometric-calculator`: entradas, regras de datas e de medida, recálculo, painel de resultados e navegação por Enter da Calculadora.
- `growth-charts`: modelo e exportação do gráfico de crescimento por indicador, modo z-score ou percentil, pontos de medida, faixa visível e interação de zoom.

### Modified Capabilities
- Nenhuma.

## Impact

- Código novo em `Sources/AnthroFeatures/Calculator/`, `Sources/AnthroFeatures/GrowthChart/`, `Sources/AnthroPlusApp/Calculator/` e `Sources/AnthroPlusApp/GrowthChart/`; testes em `Tests/AnthroFeaturesTests/`.
- Consome a API pública de `AnthroCore` (`AnthroEngine`, `GrowthCurves`, `SeverityClassifier`, `InputLimits`, `ClinicalRounding`) e a infraestrutura de `bootstrap-macos-app` (`AppSection.calculator`, `AppSettings.useEnterForNextControl`, `L10n`, `ClinicalFormat`).
- Depende de `bootstrap-macos-app` e `port-anthro-engine`. As changes `add-individual-assessment` e `add-nutritional-survey` reutilizam `GrowthChartModel`.
- Sem dependências externas: Swift Charts, AppKit (`NSPasteboard`, `NSPrintOperation`) e Core Graphics (`CGImageDestination`, `CGPDFContext`) do sistema.
