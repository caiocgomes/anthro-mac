# Spec Delta

## ADDED Requirements

### Requirement: Nova visita com valores iniciais
O sistema SHALL abrir uma nova visita com data de hoje, medida em pé, sem edema e sem peso, medida e notas, como o construtor `Visit(Child)`; se hoje for anterior ao nascimento, a data SHALL ser o nascimento.

#### Scenario: Valores iniciais de uma nova visita
- **WHEN** hoje é 2021-09-01 e a usuária cria uma nova visita para uma criança nascida em 2015-01-01
- **THEN** a data é 2021-09-01, `measuredRecumbent` e `hasOedema` são falsos e peso, medida e notas estão vazios

#### Scenario: Hoje anterior ao nascimento
- **WHEN** hoje é 2021-09-01 e a criança tem nascimento 2021-09-05
- **THEN** a data da nova visita é 2021-09-05

### Requirement: Data da visita
O sistema SHALL ajustar para o nascimento qualquer data de visita anterior a ele, como `IAVisitDialog.dtpDateOfVisit_ValueChanged`, e SHALL manter fixa a data de uma visita já existente.

#### Scenario: Data anterior ao nascimento
- **WHEN** a criança nasceu em 2015-01-01 e a usuária informa a data de visita 2014-12-31
- **THEN** a data da visita passa a ser 2015-01-01

#### Scenario: Data de visita existente
- **WHEN** a usuária abre a visita de 2021-09-01 e tenta mudar a data para 2021-09-02
- **THEN** `isDateEditable` é falso e a data continua 2021-09-01

### Requirement: Uma visita por data
O sistema SHALL recusar uma nova visita na mesma data de outra visita da criança, lançando `VisitValidationError.duplicateDate`, como `IAVisitDialog.SaveVisit`, e SHALL inserir as demais na posição da sua data.

#### Scenario: Data repetida
- **WHEN** a criança tem visita em 2021-09-01 e a usuária confirma uma nova visita em 2021-09-01
- **THEN** a confirmação lança `VisitValidationError.duplicateDate` e a criança continua com 1 visita

#### Scenario: Inserção na ordem das datas
- **WHEN** a criança tem visitas em 2021-01-10 e 2021-09-01 e a usuária confirma uma nova visita em 2021-05-05
- **THEN** as visitas da ficha ficam na ordem 2021-01-10, 2021-05-05, 2021-09-01

### Requirement: Entrada de peso e medida da visita
O sistema SHALL ler peso e medida com vírgula ou ponto decimal pelo `MeasurementInput.evaluate`, truncar a 2 casas, como `NumericUpDownX` com `SymetricCrop`, e SHALL deixar fora do cálculo (`nil`) o valor ilegível ou fora de `InputLimits` (0.9 a 275 kg, 38 a 230 cm, limites inclusivos), expondo um aviso no campo.

#### Scenario: Peso com três casas
- **WHEN** a usuária digita o peso "21,567"
- **THEN** o peso da visita é 21.56

#### Scenario: Limites inclusivos aceitos
- **WHEN** a usuária digita peso "275" e medida "38"
- **THEN** o peso é 275, a medida é 38 e os dois avisos são `nil`

#### Scenario: Fora do limite fica fora do cálculo
- **WHEN** a usuária digita peso "300" e medida "110"
- **THEN** o peso é `nil`, `weightOutcome` é `.outOfRange(0.9...275)`, `weightWarning` não é `nil` e o IMC exibido é "N/D"

### Requirement: Visita com medida inválida não é confirmada
O sistema SHALL impedir a confirmação de uma visita enquanto peso ou medida tiverem texto ilegível ou fora do intervalo, lançando `VisitValidationError.invalidMeasurement`; campo vazio SHALL ser permitido. É desvio deliberado do original, que gravaria `nil` em silêncio, para proteger o dado de pesquisa.

#### Scenario: Peso fora do limite bloqueia a visita
- **WHEN** a usuária digita peso "300" e medida "110" e confirma a visita
- **THEN** `canSave` é falso, a confirmação lança `VisitValidationError.invalidMeasurement` e a ficha continua sem a visita

#### Scenario: Medida ilegível bloqueia a visita
- **WHEN** a usuária digita peso "20" e medida "abc" e confirma a visita
- **THEN** `lengthOrHeightOutcome` é `.invalid`, `canSave` é falso e a confirmação lança `VisitValidationError.invalidMeasurement`

#### Scenario: Peso vazio é permitido
- **WHEN** a usuária deixa o peso vazio, digita medida "110" e confirma a visita de 2021-09-01
- **THEN** `canSave` é verdadeiro e a visita confirmada tem data 2021-09-01, peso `nil` e medida 110

### Requirement: Escolha entre deitado e em pé
O sistema SHALL habilitar a escolha entre medida deitada e em pé só quando a idade na data da visita for menor que 11 meses; a partir disso SHALL forçar em pé e desabilitar a escolha, como `IAVisitDialog`, divergindo da ajuda, que fala em 0 a 60 meses.

#### Scenario: Visita aos 10 meses
- **WHEN** a criança nasceu em 2020-01-01 e a visita é em 2020-11-01 (305 dias)
- **THEN** `isMeasureChoiceEnabled` é verdadeiro e a usuária pode marcar medida deitada

#### Scenario: Visita aos 11 meses com medida deitada marcada
- **WHEN** a usuária marcou medida deitada numa visita em 2020-11-01 e muda a data para 2020-12-01 (335 dias)
- **THEN** `isMeasureChoiceEnabled` é falso e `measuredRecumbent` passa a ser falso

### Requirement: IMC durante a edição da visita
O sistema SHALL exibir, durante a edição, o IMC arredondado a 1 casa calculado com a medida ajustada pela idade, quando houver peso e medida e não houver edema, e "N/D" nos demais casos, como `IAVisitDialog.ComputeBMI`.

#### Scenario: IMC exibido
- **WHEN** uma menina nascida em 2015-01-01 tem visita em 2021-09-01 com peso "21,60" e medida "118,92"
- **THEN** o IMC exibido é "15,3"

#### Scenario: IMC com edema
- **WHEN** a mesma visita tem edema marcado
- **THEN** o IMC exibido é "N/D"

### Requirement: Visitas pendentes até salvar a criança
Confirmar, editar ou excluir uma visita SHALL alterar só a ficha em memória; o banco SHALL mudar apenas quando a criança for salva, numa transação, e descartar a criança SHALL desfazer todas as mudanças de visitas, como a unidade de trabalho de `Child.ApplyDataChanges`. Notas SHALL ser gravadas sem espaços nas pontas, e vazias como `nil`.

#### Scenario: Visita confirmada e criança salva
- **WHEN** a usuária confirma uma nova visita com notas " retorno " e ainda não salvou a criança
- **THEN** a tabela `visits` tem 0 linhas; depois de salvar a criança, tem 1 linha com notas "retorno"

#### Scenario: Exclusão descartada
- **WHEN** a usuária exclui a visita de 2021-09-01 de uma criança salva e descarta as alterações
- **THEN** a visita de 2021-09-01 continua no banco e volta à lista da ficha

### Requirement: Exclusão de visitas
O sistema SHALL excluir da ficha as visitas selecionadas, uma ou várias, e SHALL desabilitar a exclusão, a edição e o gráfico quando nenhuma visita estiver selecionada, como `IAMain.RefreshUI`.

#### Scenario: Excluir duas de três visitas
- **WHEN** a criança tem 3 visitas, a usuária seleciona 2, exclui e salva a criança
- **THEN** a tabela `visits` fica com 1 linha para a criança

#### Scenario: Ações de visita dependem da seleção
- **WHEN** a ficha tem 2 visitas sem nenhuma selecionada, e depois a usuária seleciona uma delas
- **THEN** sem seleção `canDeleteVisit`, `canEditVisit` e `canShowVisitGraph` são falsos, e com uma visita selecionada os três são verdadeiros

### Requirement: Lista de visitas da criança
O sistema SHALL listar as visitas em ordem crescente de data com as colunas data (dd/MM/aaaa), peso com 2 casas, edema "Sim" ou "Não", deitado "Sim" ou "Não" e medida com 2 casas, deixando vazio o peso ou a medida ausentes, como `IAMain.dgvVisits_CellValueNeeded`.

#### Scenario: Linha de visita completa
- **WHEN** a visita de 2021-09-01 tem peso 21.6, medida 118.92, sem edema e em pé
- **THEN** a linha é "01/09/2021", "21,60", "Não", "Não", "118,92"

#### Scenario: Visita sem peso
- **WHEN** a visita de 2021-09-01 não tem peso
- **THEN** a coluna de peso da linha é a string vazia

### Requirement: Resultado da visita selecionada
O sistema SHALL calcular, para a visita selecionada, z-score, percentil e gravidade dos três indicadores com `AnthroEngine`, usando nascimento e sexo da ficha em edição; sem visita selecionada, SHALL não expor resultado.

#### Scenario: Menina de 80 meses na mediana
- **WHEN** uma menina nascida em 2015-01-01 tem visita em 2021-09-01 com 21.60 kg e 118.92 cm, sem edema
- **THEN** os z-scores de peso, estatura e IMC são 0.00, 0.00 e -0.04, os percentis são 50.0, 50.0 e 48.3 e as três gravidades são `.normal`

#### Scenario: Peso e IMC elevados
- **WHEN** a mesma visita tem 30.00 kg
- **THEN** o z-score de peso é 1.97 com gravidade `.moderate` e o z-score de IMC é 2.54 com gravidade `.high`

#### Scenario: Foco retirado da visita
- **WHEN** a ficha tem a visita de 2021-09-01 em foco e a usuária retira o foco
- **THEN** `selectedResult` deixa de ser `nil` com a visita em foco e passa a `nil` sem foco

### Requirement: Idade exibida na ficha
O sistema SHALL exibir a idade em meses inteiros na data da visita selecionada, ou de hoje sem seleção, no formato do original `Utils.GetLocalizedAgeFromMonths`: "Idade: Xa Ym (Zm)" a partir de 12 meses, "Idade: Zm" abaixo disso e "Idade: N/D" se o nascimento for posterior à data.

#### Scenario: Idade de 80 meses
- **WHEN** a criança nasceu em 2015-01-01 e a visita selecionada é de 2021-09-01
- **THEN** a idade exibida é "Idade: 6a 8m (80m)"

#### Scenario: Idade abaixo de um ano
- **WHEN** a criança nasceu em 2020-01-01 e a visita selecionada é de 2020-11-01
- **THEN** a idade exibida é "Idade: 10m"

### Requirement: Série de resultados para o gráfico
O sistema SHALL montar a entrada do gráfico de crescimento com os resultados de todas as visitas em ordem de data e o resultado da visita em foco na posição da sua data, inclusive se ela ainda não foi confirmada, indicando seu índice, como o construtor `GraphDialog(Child, Visit, Indicator)`.

#### Scenario: Visita existente em foco
- **WHEN** a criança tem visitas em 2021-01-10, 2021-05-05 e 2021-09-01 e o gráfico é aberto para a de 2021-05-05
- **THEN** a entrada tem 3 resultados em ordem de data e `currentIndex` igual a 1

#### Scenario: Nova visita ainda não confirmada
- **WHEN** a criança tem visitas em 2021-01-10 e 2021-09-01 e o gráfico é aberto do editor de uma nova visita em 2021-05-05
- **THEN** a entrada tem 3 resultados, `currentIndex` é 1 e a ficha continua com 2 visitas
