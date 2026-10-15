# anthropometric-computation Specification

## Purpose
Cálculo de um atendimento exatamente como o WHO AnthroPlus 1.0.4: idade e faixa etária, ajuste entre comprimento e altura, IMC, z-scores de peso, estatura e IMC para idade (com o ajuste além de 3 DP para peso e IMC), percentis, arredondamento, flags de plausibilidade e classes de gravidade, com paridade comprovada contra os pacotes R da OMS.

## Requirements

### Requirement: Idade em dias e em meses
O sistema SHALL calcular a idade em dias como a diferença entre as datas de calendário da visita e do nascimento, e a idade em meses como dias / 30.4375 em `Decimal`. Data de nascimento posterior à visita SHALL lançar erro.

#### Scenario: Idade de uma criança de cinco anos
- **WHEN** a data de nascimento é 2016-03-15 e a data da visita é 2021-04-01
- **THEN** a idade é 1843 dias e a idade em meses é igual a 1843 / 30.4375

#### Scenario: Nascimento depois da visita
- **WHEN** a data de nascimento é 2021-04-02 e a data da visita é 2021-04-01
- **THEN** o cálculo lança `AnthroError.birthAfterVisit`

### Requirement: Conversão de meses para dias
Quando só a idade em meses for informada, o sistema SHALL obter a idade em dias como `Round(meses * 30.4375, 0)` com arredondamento meio para longe de zero, e 24 meses SHALL resultar em 731 dias, como `MonthsToDays`.

#### Scenario: Meses fracionados
- **WHEN** a idade informada é 61.5 meses
- **THEN** a idade em dias é 1872

#### Scenario: Dois anos exatos
- **WHEN** a idade informada é 24 meses
- **THEN** a idade em dias é 731

### Requirement: Faixa etária do cálculo
O sistema SHALL classificar a idade em padrões (até 1856 dias), referência (acima de 1856 dias) ou fora dos limites (dias negativos ou parte inteira dos meses acima de 228); fora dos limites, todos os z-scores e percentis SHALL ser `nil`.

#### Scenario: Último dia dos padrões e primeiro da referência
- **WHEN** o sistema calcula para 1856 dias e para 1857 dias
- **THEN** a faixa é `.standards` para 1856 e `.reference` para 1857

#### Scenario: Última idade válida e primeira fora dos limites
- **WHEN** o sistema calcula para 6970 dias e para 6971 dias, sexo masculino, peso 60 kg e altura 170 cm
- **THEN** a faixa é `.reference` para 6970 e `.offLimits` para 6971, com os três z-scores e percentis `nil` em 6971

### Requirement: Sexo ou idade desconhecidos
Sem sexo informado, o sistema SHALL devolver todos os z-scores e percentis `nil`; sem idade em dias nem em meses, SHALL devolver faixa `.unknown` e todos os resultados `nil`.

#### Scenario: Sexo ausente
- **WHEN** o sistema calcula para 2000 dias, peso 18 kg, altura 110 cm, sem sexo
- **THEN** os três z-scores e os três percentis são `nil`

#### Scenario: Idade ausente
- **WHEN** o sistema calcula sem idade em dias e sem idade em meses, sexo feminino, peso 18 kg
- **THEN** a faixa é `.unknown` e os três z-scores são `nil`

### Requirement: Ajuste entre comprimento e altura
Na faixa de padrões, o sistema SHALL tratar a medida como comprimento abaixo de 731 dias (somando 0,7 cm se medida em pé) e como altura a partir de 731 dias (subtraindo 0,7 cm se medida deitada). Na faixa de referência a medida SHALL ficar inalterada.

#### Scenario: Comprimento medido em pé
- **WHEN** a idade é 730 dias, a medida é 80.00 cm e a criança foi medida em pé
- **THEN** a medida ajustada é 80.70 e o resultado indica comprimento

#### Scenario: Altura medida deitada
- **WHEN** a idade é 731 dias, a medida é 90.00 cm e a criança foi medida deitada
- **THEN** a medida ajustada é 89.30 e o resultado indica altura

#### Scenario: Referência ignora o modo de medida
- **WHEN** a idade é 2000 dias, a medida é 110.00 cm e a criança foi medida deitada
- **THEN** a medida ajustada é 110.00

### Requirement: Arredondamento das entradas
O sistema SHALL arredondar peso e medida para 2 casas, meio para longe de zero, antes de qualquer cálculo, como `GetAnthroResult`.

#### Scenario: Peso com três casas
- **WHEN** o peso informado é 20.005 kg
- **THEN** o peso usado e exposto no resultado é 20.01

#### Scenario: Peso ausente
- **WHEN** o peso não é informado
- **THEN** o peso do resultado é `nil` e os z-scores de peso e IMC para idade são `nil`

### Requirement: IMC exato
O sistema SHALL calcular o IMC como peso / (medida ajustada / 100)$^2$, e SHALL devolver `nil` quando peso ou medida não forem positivos ou quando o IMC for maior ou igual a 1000.

#### Scenario: IMC de 20 kg e 110 cm
- **WHEN** o peso é 20 kg e a medida ajustada é 110 cm
- **THEN** o IMC exato arredondado a 13 casas é 16.5289256198347 e o IMC exibido com 1 casa é 16.5

#### Scenario: IMC absurdo
- **WHEN** o peso é 275 kg e a medida é 1 cm
- **THEN** o IMC é `nil`

### Requirement: Z-score de estatura para idade
O sistema SHALL calcular o z-score de estatura por $((Y/M)^L - 1) / (L S)$ sem ajuste além de $\pm 3$ DP, e SHALL devolver `nil` para medida menor que 1.

#### Scenario: Estatura em +2 DP
- **WHEN** um menino tem 61 meses de referência (L = 1, M = 110.2647, S = 0.04164) e a medida é 119.447544216 cm
- **THEN** o z-score de estatura é 2.00

#### Scenario: Estatura além de +3 DP não é ajustada
- **WHEN** a mesma linha recebe a medida 128.630388432 cm
- **THEN** o z-score de estatura é 4.00

#### Scenario: Medida inválida
- **WHEN** a medida é 0.5 cm
- **THEN** o z-score e o percentil de estatura são `nil`

### Requirement: Z-score ajustado de peso e IMC
Para peso e IMC para idade, o sistema SHALL substituir o z LMS abaixo de -3 por $-3 - (SD3neg - Y)/(SD2neg - SD3neg)$ e acima de +3 por $3 + (Y - SD3)/(SD3 - SD2)$, como `CalculateZandP` com `computeFinalZScore`.

#### Scenario: Peso acima de +3 DP
- **WHEN** um menino de 0 dias (L = 0.3487, M = 3.3464, S = 0.14602) pesa 5.641924702067 kg, isto é $SD3 + (SD3 - SD2)$
- **THEN** o z-score de peso é 4.00, e não 3.92 do LMS sem ajuste

#### Scenario: Peso abaixo de -3 DP
- **WHEN** a mesma linha recebe o peso 1.701303187307 kg, isto é $SD3neg - (SD2neg - SD3neg)$
- **THEN** o z-score de peso é -4.00, e não -4.13 do LMS sem ajuste

#### Scenario: Peso dentro de 3 DP
- **WHEN** a mesma linha recebe o peso 3.3464 kg
- **THEN** o z-score de peso é 0.00 e o percentil é 50.0

### Requirement: Edema e peso mínimo
Com edema, o sistema SHALL devolver `nil` para peso e IMC para idade, mantendo estatura para idade; peso abaixo de 0.9 kg SHALL tornar peso para idade `nil`.

#### Scenario: Criança com edema
- **WHEN** o sistema calcula com edema para 2000 dias, sexo feminino, peso 18 kg e altura 110 cm
- **THEN** os z-scores de peso e IMC são `nil` e o z-score de estatura não é `nil`

#### Scenario: Peso abaixo do mínimo
- **WHEN** o peso é 0.85 kg aos 0 dias, sexo masculino
- **THEN** o z-score de peso para idade é `nil`

### Requirement: Peso para idade só até 121 meses
Na referência, o sistema SHALL devolver peso para idade `nil` quando a idade em meses exigir uma linha acima de 121 meses, mantendo estatura e IMC para idade.

#### Scenario: Última idade com peso para idade
- **WHEN** o sistema calcula para 3682 dias (120.97 meses, entre as linhas 120 e 121, L = -0.6764, M = 31.1586, S = 0.16305), sexo masculino, peso 32 kg e altura 138 cm
- **THEN** o z-score de peso para idade é 0.16 e o percentil é 56.4

#### Scenario: Primeira idade sem peso para idade
- **WHEN** o sistema calcula para 3683 dias com as mesmas medidas
- **THEN** o z-score de peso para idade é `nil` e os de estatura e IMC não são `nil`

### Requirement: Percentil a partir do z-score
O sistema SHALL calcular o percentil sobre o z não arredondado pela aproximação de Abramowitz e Stegun com os coeficientes truncados do original (0.31938, 0.356563782, 1.781477937, 1.82125, 1.330274429), arredondar a 1 casa e devolver `nil` quando $|z| > 3$.

#### Scenario: Percentis de z conhecidos
- **WHEN** o z não arredondado é 1, -2 e 3
- **THEN** os percentis são 84.1, 2.3 e 99.9

#### Scenario: Percentil além de 3 DP
- **WHEN** o z não arredondado é 3.0001 ou -3.01
- **THEN** o percentil é `nil`

### Requirement: Arredondamento clínico
O sistema SHALL arredondar valores exibidos como `AnthroComputation.Round` do original, $\mathrm{sign}(x) \cdot |\lfloor x \cdot 10^p + 0.5 \rfloor| / 10^p$: o piso age sobre o valor com sinal, então o empate positivo vai para longe de zero e o negativo vai para zero; `nil` SHALL permanecer `nil`.

#### Scenario: Empates longe de zero
- **WHEN** o sistema arredonda 2.345 e 0.125 a 2 casas
- **THEN** os resultados são 2.35 e 0.13

#### Scenario: Empate negativo vai para zero
- **WHEN** o sistema arredonda -2.345 a 2 casas e -1.235 a 2 casas
- **THEN** os resultados são -2.34 e -1.23

#### Scenario: Valor indefinido
- **WHEN** o sistema arredonda `nil`
- **THEN** o resultado é `nil`

### Requirement: Conversão de Double para Decimal
Toda conversão de `Double` para `Decimal` no cálculo SHALL arredondar para 15 dígitos significativos, como o cast explícito do .NET Framework, e valor não finito SHALL tornar o indicador inteiro `nil`.

#### Scenario: Soma binária imprecisa
- **WHEN** o sistema converte o Double resultante de 0.1 + 0.2
- **THEN** o Decimal é exatamente 0.3

#### Scenario: Valor não finito
- **WHEN** a conversão recebe `Double.infinity`
- **THEN** a conversão devolve `nil`

### Requirement: Flags de plausibilidade
O sistema SHALL marcar um z-score como implausível quando for `nil` ou estiver fora de [-6, 5] para peso, [-6, 6] para estatura e [-5, 5] para IMC, e SHALL resumir o atendimento na ordem de `GetFlagUsingDefault`: peso e estatura, peso, estatura, IMC, nenhum.

#### Scenario: Limites dos intervalos
- **WHEN** o sistema avalia peso 5.00 e 5.01, estatura 6.00 e 6.01, IMC -5.00 e -5.01
- **THEN** só 5.01 de peso, 6.01 de estatura e -5.01 de IMC são implausíveis

#### Scenario: Peso e estatura implausíveis ao mesmo tempo
- **WHEN** o atendimento tem z de peso -6.5, z de estatura 6.5 e z de IMC 7.0
- **THEN** a flag resumida é `.weightAndLengthOrHeightForAge`

### Requirement: Classificação de gravidade
O sistema SHALL classificar cada z-score como `.normal` para $|z| < 1$, `.moderate` para $|z| < 2$, `.high` para $|z| < 3$, `.extreme` nos demais casos e `.undefined` para `nil`, como `SetZLabelColor`.

#### Scenario: Fronteiras das faixas
- **WHEN** o sistema classifica 0.99, 1.00, 2.00 e 3.00
- **THEN** as classes são `.normal`, `.moderate`, `.high` e `.extreme`

#### Scenario: Negativo extremo e indefinido
- **WHEN** o sistema classifica -3.50 e `nil`
- **THEN** as classes são `.extreme` e `.undefined`

### Requirement: Paridade com os pacotes R da OMS
O sistema SHALL reproduzir os z-scores das fixtures douradas geradas com `anthro` (0 a 1826 dias) e `anthroplus` (61 a 228 meses) com diferença absoluta de no máximo 0.01 em todos os casos e igualdade exata em pelo menos 99% deles.

#### Scenario: Fixture de padrões
- **WHEN** o teste calcula os 600 casos de `golden-standards.csv`, que não contêm medida em pé abaixo de 9 meses (o pacote `anthro` atual descarta o tipo de medida nessa idade e não soma 0,7 cm, enquanto o original soma)
- **THEN** todas as diferenças de z são no máximo 0.01 e pelo menos 594 casos são idênticos

#### Scenario: Fixture de referência
- **WHEN** o teste calcula os 600 casos de `golden-reference.csv`
- **THEN** todas as diferenças de z são no máximo 0.01 e pelo menos 594 casos são idênticos

#### Scenario: Peso para idade aos 121 meses informados
- **WHEN** a idade é informada como 121 meses (sem dias), sexo masculino (linha L = -0.6764, M = 31.1586, S = 0.16305), peso 45.04 kg, onde o pacote R devolve NA por usar limite exclusivo
- **THEN** o z-score de peso para idade é 2.00 e o percentil é 97.7, como no original, que aceita o mês 121
