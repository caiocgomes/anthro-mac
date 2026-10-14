# Proposal

## Why

Todo o valor do AnthroPlus para a pesquisa da Suzan está nos números: z-scores e percentis de peso, estatura e IMC para idade, calculados exatamente como o WHO AnthroPlus de Windows calcula. Sem um núcleo de cálculo portado com fidelidade e provado por testes de paridade, nenhuma tela posterior serve como instrumento de pesquisa citável. Esta change vem antes de qualquer interface.

## What Changes

- Embute no app as tabelas LMS públicas da OMS: padrões 2006 por dia (0 a 1856 dias) e referência 2007 por mês (60 a 229 meses; peso até 121), geradas a partir de `reference/who-tables/` por um script determinístico.
- Porta para Swift, no target `AnthroCore`, o algoritmo de `AnthroComputation` e `AnthroReferenceData` do original: idade em dias e meses, faixa etária, ajuste de 0,7 cm entre comprimento e altura, IMC exato, z-score LMS, ajuste além de $\pm 3$ DP para peso e IMC, percentil por Abramowitz e Stegun com coeficientes truncados, arredondamento meio para longe de zero, interpolação mensal, flags de plausibilidade e classificação de gravidade por cor.
- Emula a conversão double para decimal do .NET (15 dígitos significativos) nos mesmos pontos em que o C# converte.
- Gera as séries das curvas de crescimento (linhas de DP e de percentis) consumidas pelos gráficos das changes seguintes.
- Cria fixtures douradas com os pacotes R `anthro` e `anthroplus` da OMS e um teste de paridade sobre centenas de casos.

## Capabilities

### New Capabilities
- `growth-reference-data`: tabelas LMS embutidas, busca por dia e por mês, interpolação de meses fracionados, validação de integridade do recurso e geração das séries de curvas.
- `anthropometric-computation`: cálculo de idade, faixa, medida ajustada, IMC, z-scores, percentis, arredondamento, plausibilidade e gravidade de um atendimento.

### Modified Capabilities
- Nenhuma.

## Impact

- Código novo em `Sources/AnthroCore/` e `Tests/AnthroCoreTests/`; recurso `Sources/AnthroCore/Resources/who/*.csv`.
- Scripts `scripts/generate_who_tables.py` (uv + openpyxl) e `scripts/golden/generate_golden.R` (pacotes R `anthro` e `anthroplus` 1.1.0, instalados em biblioteca local do projeto `.rlib/`).
- Sem dependências Swift externas. Depende do `Package.swift` criado por `bootstrap-macos-app`.
- Todas as changes de interface (3 a 9) consomem a API pública deste target.
