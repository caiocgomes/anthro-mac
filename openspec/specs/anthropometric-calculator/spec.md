# anthropometric-calculator Specification

## Purpose
Calculadora antropométrica portada de `ACMain` do WHO AnthroPlus: entradas de datas, sexo, peso, medida, modo de medida e edema, com as regras de datas e de data aproximada, os limites e o truncamento dos campos, o recálculo a cada alteração, o painel de resultados com gravidade e barra de percentil, e a navegação por Enter.

## Requirements

### Requirement: Estado inicial da Calculadora
Ao abrir, a Calculadora SHALL iniciar com nascimento seis anos antes de hoje, visita hoje, sexo feminino, peso 20.00 kg, medida 115.00 cm, sem edema, data exata e medida em pé, como `ACMain` e `ACMain_Load`. Nenhum valor SHALL ser persistido entre aberturas.

#### Scenario: Abertura com valores padrão
- **WHEN** a Calculadora é criada com hoje igual a 2026-10-14
- **THEN** o nascimento é 2020-10-14, a visita é 2026-10-14, o sexo é `.girl`, o peso é 20.00, a medida é 115.00, `hasOedema` é falso, `isApproximateBirthDate` é falso e `measuredRecumbent` é falso

#### Scenario: Nova calculadora não herda valores
- **WHEN** uma Calculadora recebe peso 30 e, em seguida, uma segunda Calculadora é criada
- **THEN** o peso da segunda Calculadora é 20.00

### Requirement: Idade exibida
A Calculadora SHALL exibir a idade a partir da parte inteira dos meses, como `Utils.GetLocalizedAgeFromMonths`: com 12 meses ou mais, "Idade: Aa Mm (Tm)"; abaixo de 12 meses, "Idade: Mm".

#### Scenario: Seis anos de calendário mostram 71 meses
- **WHEN** o nascimento é 2020-10-14 e a visita é 2026-10-14 (2191 dias, 71.98 meses)
- **THEN** o texto da idade é "Idade: 5a 11m (71m)"

#### Scenario: Idade abaixo de um ano
- **WHEN** o nascimento é 2026-05-14 e a visita é 2026-10-14
- **THEN** o texto da idade é "Idade: 5m"

### Requirement: Nascimento limitado pela visita
Sempre que a data de nascimento ficar posterior à data da visita, por alteração de qualquer uma das duas, a Calculadora SHALL igualar o nascimento à visita, como `dtpDateOfVisit_ValueChanged` e `dtpDateOfBirth_ValueChanged`.

#### Scenario: Visita movida para antes do nascimento
- **WHEN** o nascimento é 2020-10-14 e a visita passa para 2019-01-01
- **THEN** o nascimento passa a ser 2019-01-01

#### Scenario: Nascimento informado depois da visita
- **WHEN** a visita é 2026-10-14 e o nascimento passa para 2027-01-01
- **THEN** o nascimento passa a ser 2026-10-14

### Requirement: Data de nascimento aproximada
Ao marcar a data como aproximada, a Calculadora SHALL sortear o dia com `ApproximateBirthDate.randomized`, no intervalo semiaberto de 1 até o número de dias do mês, sem incluir o último dia, como `Random.Next(1, DaysInMonth)` de `ACMain`, e depois aplicar o limite da visita.

#### Scenario: Sorteio em fevereiro de 2021
- **WHEN** o nascimento é 2021-02-10, a visita é 2026-10-14 e a data é marcada como aproximada com um sorteador que devolve o limite inferior
- **THEN** o sorteador recebe o intervalo 1..<28 e o nascimento passa a ser 2021-02-01

#### Scenario: Sorteio que ultrapassa a visita
- **WHEN** a visita é 2026-10-14, o nascimento é 2026-10-05 e a data é marcada como aproximada com um sorteador que devolve 20
- **THEN** o nascimento passa a ser 2026-10-14

### Requirement: Sorteio do dia aproximado
O helper compartilhado `ApproximateBirthDate.randomized` SHALL manter ano e mês da data e trocar o dia pelo valor do sorteador, chamado com o intervalo semiaberto de 1 até o número de dias do mês, como `Random.Next(1, DaysInMonth)`; o último dia do mês SHALL nunca ser sorteado.

#### Scenario: Helper nunca sorteia o último dia
- **WHEN** `randomized` recebe 2021-02-10 e um sorteador que devolve o maior valor do intervalo recebido
- **THEN** o sorteador recebe 1..<28 e o resultado é 2021-02-27

#### Scenario: Helper em fevereiro bissexto
- **WHEN** `randomized` recebe 2024-02-10 e um sorteador que devolve o menor valor do intervalo recebido
- **THEN** o sorteador recebe 1..<29 e o resultado é 2024-02-01

### Requirement: Ajuste da data aproximada
O helper compartilhado `ApproximateBirthDate.adjusted` SHALL, com data aproximada, devolver a data anterior quando a proposta mudar o dia e sortear novo dia quando só mês ou ano mudarem; sem data aproximada SHALL devolver a proposta; em todos os casos SHALL limitar o resultado ao limite superior (visita).

#### Scenario: Helper desfaz troca de dia
- **WHEN** `adjusted` recebe anterior 2021-02-01, proposta 2021-02-15, data aproximada e limite 2026-10-14
- **THEN** o resultado é 2021-02-01 e o sorteador não é chamado

#### Scenario: Helper aceita troca de mês e sorteia de novo
- **WHEN** `adjusted` recebe anterior 2021-02-01, proposta 2021-03-01, data aproximada, limite 2026-10-14 e um sorteador que devolve 9
- **THEN** o sorteador recebe 1..<31 e o resultado é 2021-03-09

#### Scenario: Helper sem data aproximada só limita pela visita
- **WHEN** `adjusted` recebe anterior 2020-10-14, sem data aproximada e limite 2026-10-14, com as propostas 2020-01-01 e 2027-01-01
- **THEN** os resultados são 2020-01-01 e 2026-10-14

### Requirement: Dia bloqueado na data aproximada
Com a data aproximada marcada, a Calculadora SHALL aplicar `ApproximateBirthDate.adjusted` a cada alteração do nascimento: desfazer a que mude o dia e aceitar a de mês ou ano que preserve o dia, sorteando novo dia no mês resultante, como `dtpDateOfBirth_ValueChanged`.

#### Scenario: Troca de mês aceita com novo sorteio
- **WHEN** a data aproximada está marcada, o nascimento é 2021-02-01 e passa para 2021-03-01 com um sorteador que devolve 9
- **THEN** o sorteador recebe o intervalo 1..<31 e o nascimento passa a ser 2021-03-09

#### Scenario: Troca de dia desfeita
- **WHEN** a data aproximada está marcada, o nascimento é 2021-02-01 e passa para 2021-02-15
- **THEN** o nascimento permanece 2021-02-01

### Requirement: Modo de medida só abaixo de 11 meses
A Calculadora SHALL habilitar a escolha entre deitado e em pé somente quando a idade em meses for menor que 11, e SHALL forçar "em pé" nas demais idades, como `ACMain.RefreshAge`, mesmo onde a ajuda (`AC.htm`) promete a escolha de 0 a 60 meses.

#### Scenario: Escolha habilitada com 334 dias
- **WHEN** o nascimento é 2025-11-14, a visita é 2026-10-14 e a medida passa para deitado
- **THEN** `isMeasurementChoiceEnabled` é verdadeiro e `measuredRecumbent` é verdadeiro

#### Scenario: Escolha desabilitada com 335 dias
- **WHEN** `measuredRecumbent` é verdadeiro e o nascimento passa para 2025-11-13, com visita 2026-10-14
- **THEN** `isMeasurementChoiceEnabled` é falso e `measuredRecumbent` é falso

#### Scenario: Criança de 30 meses sem escolha, contra a ajuda
- **WHEN** o nascimento é 2024-04-14 e a visita é 2026-10-14
- **THEN** `isMeasurementChoiceEnabled` é falso e `measuredRecumbent` é falso

### Requirement: Campos de peso e medida
A Calculadora SHALL ler peso e medida aceitando vírgula ou ponto, SHALL esvaziar o campo (`nil`) quando o texto for vazio, inválido ou fora de `InputLimits`, e SHALL truncar valores válidos a 2 casas, como `NumericUpDownX.CheckValidValue` com `AnthroComputation.SymetricCrop`.

#### Scenario: Peso truncado, não arredondado
- **WHEN** o texto do peso é "20,129"
- **THEN** o peso é 20.12

#### Scenario: Valores fora dos limites
- **WHEN** o texto do peso é "300", ou o texto da medida é "37,99", ou o texto do peso é vazio
- **THEN** o campo correspondente fica `nil`

### Requirement: Avaliação do texto de medida
O helper compartilhado `MeasurementInput.evaluate` SHALL classificar o texto como `.empty` (vazio ou só espaços), `.invalid` (não numérico, aceitando vírgula ou ponto como separador), `.outOfRange` (fora do intervalo recebido) ou `.value` (dentro do intervalo, truncado às casas pedidas, como `SymetricCrop`); `parse` SHALL devolver o valor só no caso `.value`.

#### Scenario: Helper trunca texto válido
- **WHEN** `evaluate` recebe "20,129" e "20.5" com intervalo 0.9...275
- **THEN** os resultados são `.value(20.12)` e `.value(20.5)`

#### Scenario: Helper aponta valor fora do intervalo
- **WHEN** `evaluate` recebe "300" e "0,5" com intervalo 0.9...275
- **THEN** ambos os resultados são `.outOfRange(0.9...275)` e `parse` devolve `nil` para os dois

#### Scenario: Helper aponta texto inválido e vazio
- **WHEN** `evaluate` recebe "12,3,4", "abc" e "  " com intervalo 38...230
- **THEN** os resultados são `.invalid`, `.invalid` e `.empty`

### Requirement: Aviso inline de campo com problema
Quando o texto de peso ou de medida for inválido ou estiver fora do intervalo, a Calculadora SHALL calcular com o campo `nil`, como `NumericUpDownX.SetToNull`, e SHALL expor o problema do campo com a mensagem do aviso inline; texto válido ou vazio SHALL limpar o aviso.

#### Scenario: Aviso de peso fora do intervalo
- **WHEN** o texto do peso é "300"
- **THEN** o peso é `nil`, `weightIssue` é `.outOfRange(0.9...275)` e a mensagem do aviso é "Fora do intervalo: 0,90 a 275,00"

#### Scenario: Aviso some com valor válido
- **WHEN** o texto do peso passa de "300" para "25"
- **THEN** o peso é 25 e `weightIssue` é `nil`

#### Scenario: Aviso de medida inválida
- **WHEN** o texto da medida é "abc"
- **THEN** a medida é `nil`, `lengthOrHeightIssue` é `.invalid` e a mensagem do aviso é "Valor inválido"

### Requirement: IMC exibido
Sem edema e com peso e medida presentes, a Calculadora SHALL exibir o IMC exato calculado com a medida ajustada, arredondado a 1 casa no formato pt-BR; nos demais casos SHALL exibir "N/D", como `ACMain.UpdateIndicators`.

#### Scenario: IMC de 20 kg e 110 cm aos seis anos
- **WHEN** o nascimento é 2020-10-14, a visita é 2026-10-14, o peso é 20 e a medida é 110
- **THEN** o texto do IMC é "16,5"

#### Scenario: IMC indisponível
- **WHEN** a criança tem edema, ou o peso está vazio
- **THEN** o texto do IMC é "N/D"

### Requirement: Recálculo a cada alteração
A cada alteração de entrada, a Calculadora SHALL recalcular o resultado com `AnthroEngine.result(dateOfBirth:dateOfVisit:sex:weight:lengthOrHeight:measuredRecumbent:hasOedema:)` usando os valores atuais, sem botão de calcular.

#### Scenario: Troca de sexo
- **WHEN** o sexo passa de feminino para masculino
- **THEN** o resultado da Calculadora é igual ao do motor para as entradas atuais e `result.sex` é `.boy`

#### Scenario: Peso apagado
- **WHEN** o texto do peso fica vazio
- **THEN** os z-scores de peso e IMC para idade do resultado são `nil` e o de estatura para idade não é `nil`

### Requirement: Valores do painel de resultados
Para cada indicador, o painel SHALL exibir o z-score com 2 casas e o percentil com 1 casa no formato pt-BR, e "N/D" quando o valor for `nil`, como `IndicatorDisplayPanel.DisplayResult`.

#### Scenario: Z e percentil formatados
- **WHEN** o resultado de peso para idade tem z -2.35 e percentil 0.9
- **THEN** a linha de peso mostra "-2,35" e "0,9"

#### Scenario: Percentil além de 3 DP
- **WHEN** o resultado de IMC para idade tem z 3.50 e percentil `nil`
- **THEN** a linha de IMC mostra "3,50" e "N/D"

### Requirement: Gravidade no painel
O painel SHALL atribuir a cada indicador a gravidade de `SeverityClassifier.severity` aplicada ao z-score arredondado do resultado, como `IndicatorDisplayPanel.SetZLabelColor`.

#### Scenario: Gravidade alta
- **WHEN** o z de peso para idade do resultado é -2.35
- **THEN** a gravidade da linha de peso é `.high`

#### Scenario: Gravidade indefinida
- **WHEN** o z de estatura para idade do resultado é `nil`
- **THEN** a gravidade da linha de estatura é `.undefined`

### Requirement: Barra de percentil
O painel SHALL posicionar a barra de 0 a 100 no percentil arredondado ao inteiro par mais próximo quando o percentil for positivo; sem percentil, SHALL usar 100 para z maior que 3, 50 para z indefinido e 0 nos demais casos, como `IndicatorDisplayPanel.DisplayResult`.

#### Scenario: Empate arredondado para par
- **WHEN** os percentis são 84.5 e 85.5
- **THEN** as barras ficam em 84 e 86

#### Scenario: Barra sem percentil
- **WHEN** o z é 3.50, -3.50 ou `nil`, com percentil `nil`
- **THEN** as barras ficam em 100, 0 e 50

### Requirement: Rótulo de comprimento ou estatura
O painel SHALL rotular o indicador de medida como "Comprimento para idade" quando `result.isLength` for verdadeiro e "Estatura para idade" caso contrário, como `IndicatorDisplayPanel.DisplayResult`.

#### Scenario: Seis anos mostra estatura
- **WHEN** o nascimento é 2020-10-14 e a visita é 2026-10-14
- **THEN** o rótulo é "Estatura para idade"

#### Scenario: Quinze meses medido em pé mostra comprimento
- **WHEN** o nascimento é 2025-07-14, a visita é 2026-10-14 e a medida é 80.00
- **THEN** o rótulo é "Comprimento para idade" e a medida ajustada do resultado é 80.70

### Requirement: Abrir o gráfico a partir do painel
O botão de gráfico de cada indicador SHALL abrir o gráfico de crescimento com o resultado atual como único ponto, índice atual 0 e o indicador do botão, como `ACMain.indicatorDisplayPanel_GraphButtonClicked*`.

#### Scenario: Gráfico de IMC
- **WHEN** o usuário aciona o gráfico de IMC para idade
- **THEN** o modelo de gráfico tem indicador `.bmiForAge`, 1 resultado, índice atual 0 e `canShowMultiplePoints` falso

#### Scenario: Gráfico sem medida calculável
- **WHEN** o nascimento é 2000-01-01, a visita é 2026-10-14 e o usuário aciona o gráfico de peso para idade
- **THEN** o modelo de gráfico tem `isEmpty` verdadeiro

### Requirement: Enter avança para o próximo campo
Com `AppSettings.useEnterForNextControl` ligado, Enter SHALL levar ao próximo campo habilitado na ordem nascimento, data aproximada, visita, sexo, peso, medida, modo de medida, edema, voltando ao primeiro depois do último, como `FormX.PreFilterMessage`; desligado, Enter SHALL manter o foco.

#### Scenario: Do peso para a medida
- **WHEN** a configuração está ligada e o foco está no peso
- **THEN** `nextFocus(after: .weight)` é `.lengthOrHeight`

#### Scenario: Modo de medida desabilitado é pulado
- **WHEN** a configuração está ligada, a idade é de seis anos e o foco está na medida
- **THEN** `nextFocus(after: .lengthOrHeight)` é `.oedema`

#### Scenario: Volta ao início e configuração desligada
- **WHEN** a configuração está ligada e o foco está no edema, e depois a configuração é desligada
- **THEN** `nextFocus(after: .oedema)` é `.dateOfBirth` com a configuração ligada e `nil` com ela desligada
