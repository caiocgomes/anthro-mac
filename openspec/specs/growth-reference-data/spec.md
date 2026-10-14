# growth-reference-data Specification

## Purpose
Tabelas LMS públicas da OMS embutidas no app (Padrões de Crescimento 2006 por dia, de 0 a 1856 dias, e Referência 2007 por mês, de 60 a 229 meses), com validação de integridade na carga, interpolação de meses fracionados como no original e as séries das curvas de DP e de percentis usadas nos gráficos.

## Requirements

### Requirement: Tabelas de padrões 2006 por dia
O sistema SHALL embutir as tabelas LMS dos padrões de crescimento da OMS 2006 para peso, comprimento ou altura e IMC para idade, por sexo, com uma linha por dia de 0 a 1856 dias, e devolver L, M e S como `Decimal` idênticos aos valores das planilhas expandidas da OMS.

#### Scenario: Linha do dia 0 de peso para idade de meninos
- **WHEN** o sistema busca a linha de padrões de peso para idade, sexo masculino, idade 0 dias
- **THEN** o resultado é L = 0.3487, M = 3.3464, S = 0.14602

#### Scenario: Último dia dos padrões de IMC de meninas
- **WHEN** o sistema busca a linha de padrões de IMC para idade, sexo feminino, idade 1856 dias
- **THEN** o resultado é L = -0.5684, M = 15.2798, S = 0.09825

#### Scenario: Dia além do fim dos padrões
- **WHEN** o sistema busca a linha de padrões de peso para idade, sexo masculino, idade 1857 dias
- **THEN** o resultado é `nil`

### Requirement: Tabelas de referência 2007 por mês
O sistema SHALL embutir as tabelas LMS da referência OMS 2007 por sexo e mês inteiro: IMC e estatura para idade de 60 a 229 meses, peso para idade de 60 a 121 meses.

#### Scenario: Mês 61 de IMC para idade de meninos
- **WHEN** o sistema busca a linha de referência de IMC para idade, sexo masculino, 61 meses
- **THEN** o resultado é L = -0.7387, M = 15.2641, S = 0.08390

#### Scenario: Peso para idade além de 121 meses
- **WHEN** o sistema busca a linha de referência de peso para idade, sexo masculino, 122 meses
- **THEN** o resultado é `nil`

### Requirement: Interpolação de meses fracionados
Para idade em meses não inteira, o sistema SHALL interpolar L, M e S linearmente entre o mês inteiro inferior e o superior, como `AnthroReferenceData.GetInterpolatedValue`; se uma das duas linhas não existir, o resultado SHALL ser `nil`.

#### Scenario: IMC de meninos aos 61,5 meses
- **WHEN** o sistema busca a referência de IMC para idade, sexo masculino, 61.5 meses
- **THEN** o resultado é L = -0.7504, M = 15.26285, S = 0.08402

#### Scenario: Último intervalo válido de estatura
- **WHEN** o sistema busca a referência de estatura para idade, sexo feminino, 228.5 meses
- **THEN** o resultado é L = 1, M = 163.1548, S = 0.04009, igual à linha de 228 meses, porque a linha de 229 da OMS repete a de 228 para permitir a interpolação até o fim do mês 228

#### Scenario: Mês superior ausente
- **WHEN** o sistema busca a referência de IMC para idade, sexo masculino, 229.5 meses
- **THEN** o resultado é `nil`

#### Scenario: Mês inferior ausente
- **WHEN** o sistema busca a referência de IMC para idade, sexo masculino, 59.5 meses
- **THEN** o resultado é `nil`

### Requirement: Integridade do recurso de tabelas
Ao carregar o recurso embutido, o sistema SHALL verificar que cada tabela tem idades contíguas e completas no intervalo declarado, e SHALL falhar com erro tipado que nomeia indicador, sexo e idade da primeira lacuna.

#### Scenario: Recurso embutido completo
- **WHEN** o sistema carrega as tabelas embutidas
- **THEN** cada tabela de padrões tem 1857 linhas por sexo, IMC e estatura de referência têm 170 linhas por sexo, peso de referência tem 62 linhas por sexo

#### Scenario: Recurso com dia faltando
- **WHEN** o sistema carrega um CSV de padrões de peso para idade, sexo masculino, sem a linha do dia 100
- **THEN** o carregamento lança `ReferenceDataError.gap(indicator: .weightForAge, sex: .boy, age: 100)`

### Requirement: Séries de curvas por desvio-padrão
O sistema SHALL gerar, por indicador e sexo, as séries das linhas de -3 a +3 DP com $SD_k = M (1 + L S k)^{1/L}$, usando padrões a cada 4 dias (eixo x em meses = dias / 30.4375) seguidos da referência mensal até 120 meses para peso e 228 meses para estatura e IMC, como `GetIndicatorDataCurves`.

#### Scenario: Linha +2 DP no dia 0 de peso de meninos
- **WHEN** o sistema gera as curvas de DP de peso para idade de meninos
- **THEN** o primeiro ponto tem x = 0, mediana 3.3464 e +2 DP igual a 4.4194 quando arredondado a 4 casas

#### Scenario: Número de pontos e limite superior de peso
- **WHEN** o sistema gera as curvas de DP de peso para idade de meninas
- **THEN** a série tem 526 pontos (465 de padrões e 61 de referência) e o último x é 120

### Requirement: Séries de curvas por percentil
O sistema SHALL gerar as séries de percentis 3, 15, 50, 85 e 97 com $M (1 + L S k)^{1/L}$ para $k$ = -1.88, -1.036, 0, 1.036 e 1.88, com a mesma amostragem das curvas de DP.

#### Scenario: Percentil 50 igual à mediana
- **WHEN** o sistema gera as curvas de percentil de IMC para idade de meninos
- **THEN** em todos os pontos o valor do percentil 50 é igual a M da linha de origem

#### Scenario: Limite superior das curvas de IMC
- **WHEN** o sistema gera as curvas de percentil de IMC para idade de meninas
- **THEN** a série tem 634 pontos (465 de padrões e 169 de referência) e o último x é 228
