# Spec Delta

## ADDED Requirements

### Requirement: Prevalências por limiar de z-score
O sistema SHALL calcular, para IMC para idade, as prevalências de z < -3, z < -2, z > +1, z > +2 e z > +3 como soma dos fatores de ponderação dos registros no limiar dividida por (N + N com edema), vezes 100, arredondada a 1 casa, como `AnthroAnalysis.ComputePrevalences`. Com N igual a 0 as prevalências, a média e o DP SHALL ser `nil`.

#### Scenario: Dez registros de IMC com z conhecidos
- **WHEN** o sistema analisa IMC para idade de 10 registros de 96 meses, fator 1, sem edema, com z -3.5, -2.5, -2.1, -1.0, 0.0, 0.5, 1.2, 2.2, 3.1 e 0.0
- **THEN** N = 10 e as prevalências são 10 (< -3), 30 (< -2), 30 (> +1), 20 (> +2) e 10 (> +3)

#### Scenario: Nenhum registro com z válido
- **WHEN** o sistema analisa IMC para idade de 3 registros de 96 meses cujo z de IMC é `nil`
- **THEN** N = 0, as cinco prevalências são `nil`, a média é `nil`, o DP é `nil` e o IC de < -2 é `.unavailable`

### Requirement: Indicadores avaliados só abaixo da mediana
Para peso para idade e estatura para idade, o sistema SHALL calcular só as prevalências de z < -3 e z < -2 e seus IC; as prevalências acima da mediana SHALL ser `nil` e seus IC `.notComputed`, como `ComputeOnlyNegative`.

#### Scenario: Estatura para idade dos dez registros
- **WHEN** o sistema analisa estatura para idade dos mesmos 10 registros, com os mesmos z
- **THEN** as prevalências < -3 e < -2 são 10 e 30, a prevalência > +1 é `nil` e o IC de > +1 é `.notComputed`

#### Scenario: Classificação dos indicadores
- **WHEN** o sistema consulta `computeOnlyNegative` para os três indicadores
- **THEN** o resultado é `true` para peso e estatura para idade e `false` para IMC para idade

### Requirement: Média e desvio-padrão ponderados
O sistema SHALL calcular a média como $\sum z_i w_i / N$ e o DP como $\sqrt{\sum w_i (z_i - \bar z)^2 / (N - 1)}$ em `Double`, convertido para `Decimal` com 15 dígitos, usando os z já arredondados a 2 casas; DP indefinido por divisão (NaN) SHALL valer 0.

#### Scenario: Registros com pesos diferentes
- **WHEN** o sistema analisa IMC de 3 registros de 96 meses com z -2.5 (fator 2), 0 (fator 1) e 1 (fator 1)
- **THEN** N = 4, a prevalência < -2 é 50, a média é -1 e o DP arredondado a 2 casas é 1.78

#### Scenario: Um único registro
- **WHEN** o sistema analisa IMC de 1 registro de 96 meses com z -1 e fator 1
- **THEN** N = 1, a média é -1 e o DP é 0

### Requirement: Fator de ponderação negativo
Antes de somar um registro com z, o sistema SHALL substituir fator de ponderação negativo por 1; fator igual a 0 SHALL permanecer 0.

#### Scenario: Fator negativo vira 1
- **WHEN** o sistema analisa IMC de 3 registros de 96 meses com z -2.5 (fator -3), 0 (fator 1) e 1 (fator 1)
- **THEN** N = 3 e a prevalência < -2 é 33.3

#### Scenario: Fator zero não conta
- **WHEN** o sistema analisa IMC de 3 registros de 96 meses com z -2.5 (fator 0), 0 (fator 1) e 1 (fator 1)
- **THEN** N = 2, a prevalência < -2 é 0 e a média é 0.5

### Requirement: Edema nos indicadores dependentes do peso
Para peso e IMC para idade, registro com edema SHALL somar seu fator ao N com edema e aos numeradores de < -3 e < -2, sem entrar na média nem no DP; o denominador das prevalências SHALL ser N + N com edema. Em estatura para idade o edema SHALL ser ignorado.

#### Scenario: Um caso de edema em IMC
- **WHEN** o sistema analisa IMC de 9 registros de 96 meses com z -2.5, -2.1, -1.0, 0.0, 0.5, 1.2, 2.2, 3.1 e 0.0, mais 1 registro com edema
- **THEN** N = 9, N com edema = 1, as prevalências < -3 e < -2 são 10 e 30, a média arredondada é 0.16 e o DP arredondado é 1.86

#### Scenario: Edema não afeta estatura
- **WHEN** o sistema analisa estatura dos mesmos registros, em que o registro com edema tem z de estatura -2.5
- **THEN** N = 10, N com edema = 0, a prevalência < -2 é 30 e a média arredondada é -0.11

### Requirement: Exclusão de z indefinido ou implausível
O sistema SHALL ignorar, no cálculo de um indicador, o registro sem edema cujo z seja `nil` ou que esteja marcado como implausível para esse indicador na entrada da análise.

#### Scenario: Um registro implausível
- **WHEN** o sistema analisa IMC de 3 registros de 96 meses com z -2.5, 0 (implausível) e 1
- **THEN** N = 2, a prevalência < -2 é 50 e a média é -0.75

#### Scenario: Todos implausíveis
- **WHEN** o sistema analisa IMC de 2 registros de 96 meses, ambos implausíveis
- **THEN** N = 0, a prevalência < -2 é `nil` e o IC de < -2 é `.unavailable`

### Requirement: Peso para idade após 108 meses
Em peso para idade, registro com idade cuja parte inteira em meses passa de 108 SHALL somar seu fator a N sem contribuir com z para prevalências, média ou DP, como o ramo `(int)age > 108` de `ComputePrevalences`; o mesmo vale para qualquer indicador acima de 228 meses.

#### Scenario: Peso para idade com crianças de 110 meses
- **WHEN** o sistema analisa peso para idade de registros com z -2.5 e 0.5 aos 100 meses e z -3.2 e 1.0 aos 110 meses
- **THEN** N = 4, a prevalência < -3 é 0, a prevalência < -2 é 25 e a média é -0.5

#### Scenario: Os mesmos registros em IMC
- **WHEN** o sistema analisa IMC para idade dos mesmos quatro registros, com os mesmos z
- **THEN** N = 4, a prevalência < -3 é 25, a prevalência < -2 é 50 e a média é -1.05

### Requirement: Intervalo de confiança simples
Sem correção por cluster, o sistema SHALL calcular o IC 95% de uma proporção $p$ com total $n$ como $p \pm (1.96 \sqrt{p(1-p)/n} + 1/(2n))$, limitado a [0, 1], em percentual arredondado a 1 casa, como `ComputeCI`; com $n = 0$ o IC SHALL ser `.unavailable`.

#### Scenario: IC das prevalências dos dez registros
- **WHEN** o sistema analisa IMC dos 10 registros com z -3.5, -2.5, -2.1, -1.0, 0.0, 0.5, 1.2, 2.2, 3.1 e 0.0
- **THEN** o IC de < -2 é `.interval(low: 0, high: 63.4)` e o IC de < -3 é `.interval(low: 0, high: 33.6)`

#### Scenario: Limite superior cortado em 100
- **WHEN** o sistema calcula o IC simples com porção 2 e total 4
- **THEN** o IC é `.interval(low: 0, high: 100)`

#### Scenario: Total zero
- **WHEN** o sistema calcula o IC simples com porção 0 e total 0
- **THEN** o IC é `.unavailable`

### Requirement: Intervalo de confiança corrigido por cluster
Com correção por cluster, o sistema SHALL calcular $p$ como razão das somas, os resíduos $u_c = y_c/\bar n - n_c \bar y/\bar n^2$, o erro $s = \sqrt{\sum u_c^2 / (C(C-1))}$ e o IC $\mathrm{logit}^{-1}(\mathrm{logit}(p) \pm t_{C-1} s / (p(1-p)))$, em percentual com 1 casa, como `ComputeImprovedClusterCI`.

#### Scenario: Quatro clusters de cinco crianças
- **WHEN** o sistema analisa estatura de 4 clusters com 5 registros de 96 meses cada, com 1, 2, 0 e 1 registros de z -2.5 e os demais com z 0
- **THEN** a prevalência < -2 é 20 e o IC de < -2 é `.interval(low: 4.7, high: 55.9)`

#### Scenario: Paridade com o pacote R survey
- **WHEN** o teste calcula os 200 desenhos de `ClusterCIGolden.generated.swift`, gerados com `survey::svyciprop(method = "logit")`
- **THEN** todos os limites diferem no máximo 0.1 do oráculo e pelo menos 198 desenhos têm os dois limites idênticos

### Requirement: Casos sem IC por cluster
O IC por cluster SHALL ser `.unavailable` quando o total for 0 ou $p \leq 0.00005$ ou $p \geq 0.99995$, e `.singleCluster` quando houver um único cluster (sem valor t para 0 graus de liberdade).

#### Scenario: Proporção nula
- **WHEN** o sistema analisa estatura dos 4 clusters de 5 registros, nenhum com z < -3
- **THEN** o IC de < -3 é `.unavailable`

#### Scenario: Um único cluster
- **WHEN** o sistema analisa estatura de 1 cluster com 5 registros de 96 meses, 2 com z -2.5 e 3 com z 0
- **THEN** a prevalência < -2 é 40 e o IC de < -2 é `.singleCluster`

### Requirement: Tabela t de Student
O sistema SHALL devolver o valor t bicaudal de 95% da tabela do original para 1 a 200 graus de liberdade, 1.96 acima de 200 e `nil` para 0 ou menos, como `GetTStudentValue`.

#### Scenario: Valores da tabela
- **WHEN** o sistema consulta t para 3 e para 200 graus de liberdade
- **THEN** os valores são 3.18244630528371 e 1.97189622363389

#### Scenario: Fora da tabela
- **WHEN** o sistema consulta t para 201 e para 0 graus de liberdade
- **THEN** os valores são 1.96 e `nil`

### Requirement: Clusters contados na correção
O número de clusters $C$ SHALL incluir todo cluster com ao menos um registro que chegue à checagem de edema e plausibilidade, mesmo que todos os seus registros sejam descartados; registro sem cluster SHALL ser ignorado na análise com correção.

#### Scenario: Cluster só com registro implausível
- **WHEN** o sistema analisa estatura dos 4 clusters de 5 registros mais um quinto cluster com 1 registro implausível
- **THEN** N = 20 e o IC de < -2 é `.interval(low: 6, high: 49.6)`

#### Scenario: Registro sem cluster na correção
- **WHEN** o sistema analisa estatura dos 4 clusters de 5 registros mais 1 registro sem cluster com z -2.5
- **THEN** N = 20 e o IC de < -2 é `.interval(low: 4.7, high: 55.9)`

### Requirement: Correção por cluster sem dados de cluster
Quando a análise com correção por cluster tiver N + N com edema maior que 0 e nenhum cluster registrado, o sistema SHALL lançar `AnalysisError.noClusterData`, como a `DataException` do original.

#### Scenario: Peso para idade de crianças sem cluster
- **WHEN** o sistema analisa com correção peso para idade de 2 registros de 110 e 112 meses sem cluster
- **THEN** a análise lança `AnalysisError.noClusterData`

#### Scenario: População vazia com correção
- **WHEN** o sistema analisa com correção estatura de uma lista vazia
- **THEN** a análise não lança erro, N = 0 e o IC de < -2 é `.unavailable`

### Requirement: Agrupamento por faixas etárias
Com as faixas de `AgeGroups.groups(fromBoundaries:)` sobre `SurveyOptions.ageGroupBoundaries`, o sistema SHALL colocar cada registro na maior faixa cujo limite inferior seja menor ou igual à idade em meses, descartar idade `nil` ou abaixo da primeira fronteira e, na análise de cada faixa, descartar idade cuja parte inteira passe da última fronteira, como `GetPrevalencesValuesByAgeGroups`.

#### Scenario: Faixas fixas de 61 a 228 meses
- **WHEN** o sistema agrupa IMC com `ageGroupBoundaries` [61, 120, 180, 228] registros de 61, 119.9, 120, 228.5, 229 e 60.9 meses, todos com z 0
- **THEN** são 3 resultados com N = 2, 1 e 1

#### Scenario: Idade desconhecida
- **WHEN** o sistema agrupa com as mesmas fronteiras 1 registro sem idade e com z 0
- **THEN** os 3 resultados têm N = 0

### Requirement: Filtro por sexo nas faixas
Quando um sexo for informado, o agrupamento por faixas SHALL considerar só os registros desse sexo; registro sem sexo SHALL entrar só na análise sem filtro de sexo.

#### Scenario: Três meninos e duas meninas
- **WHEN** o sistema agrupa IMC com `ageGroupBoundaries` [61, 228] 3 meninos, 2 meninas e 1 registro sem sexo, todos de 96 meses com z 0
- **THEN** N = 3 para meninos, N = 2 para meninas e N = 6 sem filtro

#### Scenario: Sexo sem registros
- **WHEN** o sistema agrupa só meninas numa lista com 2 meninos
- **THEN** o único resultado tem N = 0

### Requirement: População do total
O sistema SHALL formar a população dos totais com os registros de 61 a 228 meses inclusive (comparação decimal), do sexo pedido quando houver, e só com cluster quando pedido, como `GetFilteredRecords`.

#### Scenario: Bordas de idade do total
- **WHEN** o sistema filtra registros de 60.99, 61, 228, 228.01 meses e 1 sem idade
- **THEN** ficam só os registros de 61 e de 228 meses

#### Scenario: Só registros com cluster
- **WHEN** o sistema filtra com `onlyWithCluster` 2 registros de 96 meses, um com cluster 3 e outro sem cluster
- **THEN** fica só o registro do cluster 3

### Requirement: Análise por cluster
O sistema SHALL agrupar os registros com cluster e idade de 61 a 228 meses por número de cluster, em ordem crescente, e analisar cada grupo sem filtro de faixa etária e sem correção, como `GetPrevalencesValuesByCluster`.

#### Scenario: Clusters fora de ordem
- **WHEN** o sistema analisa IMC por cluster de registros de 96 meses nos clusters 7, 2, 7 e 5, com z 0
- **THEN** os resultados vêm nos clusters [2, 5, 7] com N = 1, 1 e 2

#### Scenario: Sem registros elegíveis
- **WHEN** o sistema analisa por cluster 1 registro do cluster 4 com 230 meses, 1 registro de 96 meses sem cluster e 1 registro do cluster 9 com 96 meses
- **THEN** o resultado tem só o cluster 9, com N = 1

### Requirement: Pré-filtro de medidas nas estimativas
No tipo de análise do banco global da OMS, o sistema SHALL descartar registros com peso informado fora de 0.9 a 275 kg ou medida informada fora de 38 a 230 cm antes de qualquer contagem; a análise padrão SHALL manter esses registros.

#### Scenario: Peso abaixo do mínimo
- **WHEN** o sistema analisa IMC de 2 registros de 96 meses, um com peso 0.5 kg e z -2.5 e outro com peso 25 kg e z 0
- **THEN** a análise do banco global tem N = 1 e prevalência < -2 igual a 0, e a análise padrão tem N = 2 e prevalência < -2 igual a 50

#### Scenario: Medida ausente não é filtrada
- **WHEN** o sistema analisa no tipo do banco global 1 registro de 96 meses sem peso, com altura 120 cm e z de estatura -2.5
- **THEN** a análise de estatura tem N = 1 e prevalência < -2 igual a 100

### Requirement: Exclusão pelos limites do inquérito
O sistema SHALL marcar como implausível, na entrada da análise, cada z que `SurveyPlausibility.isFlagged` (change `add-nutritional-survey`) marque com as `SurveyOptions` do inquérito, sem limites próprios, de modo que prevalências, média e DP reflitam limites de z personalizados.

#### Scenario: Limite de IMC do inquérito exclui registro
- **WHEN** o sistema analisa IMC de 2 meninos com idade informada de 96 meses, altura 130 cm e pesos 26.60 kg (z 0.00) e 33.25 kg (z 2.00), primeiro com `SurveyOptions.default` e depois com `referenceMaxZ` de IMC igual a 1.0
- **THEN** com as opções padrão N = 2 e a prevalência > +1 é 50, e com o limite 1.0 N = 1 e a prevalência > +1 é 0

#### Scenario: Limite dos padrões não afeta a referência
- **WHEN** o sistema analisa IMC dos mesmos 2 meninos com `standardsMaxZ` de IMC igual a 1.0 e os demais limites padrão
- **THEN** N = 2 e a prevalência > +1 é 50
