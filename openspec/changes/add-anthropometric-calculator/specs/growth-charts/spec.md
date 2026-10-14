# Spec Delta

## ADDED Requirements

### Requirement: Curvas de desvio-padrão
No modo z-score, o gráfico SHALL exibir as séries -3, -2, mediana, +2 e +3 DP de `GrowthCurves` para peso e estatura para idade, e acrescentar -1 e +1 DP só para IMC para idade, com rótulos "-3 DP", "-2 DP", "-1 DP", "Mediana", "+1 DP", "+2 DP", "+3 DP", como `GraphDialog.DrawIndicatorGraph`.

#### Scenario: Peso para idade sem linhas de 1 DP
- **WHEN** o gráfico de peso para idade de uma menina é exibido no modo z-score
- **THEN** as séries são, em ordem, "-3 DP", "-2 DP", "Mediana", "+2 DP", "+3 DP", com estilos `.sd3`, `.sd2`, `.median`, `.sd2`, `.sd3`

#### Scenario: IMC para idade com linhas de 1 DP
- **WHEN** o gráfico de IMC para idade de um menino é exibido no modo z-score
- **THEN** há 7 séries, incluindo "-1 DP" e "+1 DP" com estilo `.sd1`

### Requirement: Curvas de percentis
No modo percentil, o gráfico SHALL exibir as séries dos percentis 3, 15, 50, 85 e 97 de `GrowthCurves` com rótulos "3º", "15º", "50º", "85º" e "97º" e estilos de cor do original: 3 e 97 como `.sd2`, 15 e 85 como `.sd1`, 50 como `.median`.

#### Scenario: Percentis de estatura para idade
- **WHEN** o gráfico de estatura para idade de um menino é exibido no modo percentil
- **THEN** as séries são, em ordem, "3º", "15º", "50º", "85º", "97º", com estilos `.sd2`, `.sd1`, `.median`, `.sd1`, `.sd2`

#### Scenario: Percentil 50 sobre a mediana
- **WHEN** o gráfico de IMC para idade de uma menina é exibido no modo percentil
- **THEN** cada valor da série "50º" é igual ao valor da mediana na mesma posição da série de DP

### Requirement: Costura entre padrões e referência
Cada série de curva SHALL ter x estritamente crescente: na costura dos cinco anos, os pontos da referência OMS 2007 com x menor ou igual ao último x dos padrões (o mês 60, depois de 1856 dias, ou 60,98 meses) SHALL ser omitidos do desenho, para que a linha não volte no eixo x. O `GraphDialog` original desenhava o mês 60 depois de 60,98 meses e formava um "Z" em todas as curvas; nenhum valor desenhado muda, só deixa de haver o retorno.

#### Scenario: Peso para idade sem retorno aos 60 meses
- **WHEN** o gráfico de peso para idade de uma menina é exibido no modo z-score
- **THEN** em toda série cada ponto tem x maior que o anterior, e o ponto seguinte a x = 1856 / 30.4375 tem x = 61

#### Scenario: Percentis de IMC sem retorno aos 60 meses
- **WHEN** o gráfico de IMC para idade de um menino é exibido no modo percentil
- **THEN** em toda série cada ponto tem x maior que o anterior

### Requirement: Marca de transição entre comprimento e estatura
Para estatura e IMC para idade, o gráfico SHALL exibir uma linha vertical em x = 24 meses com os rótulos "COMPRIMENTO" em x = 23.5 e "ESTATURA" em x = 24.5, na altura do primeiro valor da série mais baixa; peso para idade SHALL não ter essa marca.

#### Scenario: Marca no gráfico de IMC
- **WHEN** o gráfico de IMC para idade de um menino é exibido no modo z-score
- **THEN** `transitionMarker` tem x = 24 e y igual ao primeiro valor da série "-3 DP"

#### Scenario: Peso para idade sem marca
- **WHEN** o gráfico de peso para idade é exibido
- **THEN** `transitionMarker` é `nil`

### Requirement: Faixa dos eixos
O gráfico SHALL usar no eixo x de 0 até o último x das curvas mais 10 meses para peso e mais 20 para os demais; no eixo y, mínimo 0 (peso), 40 (estatura) ou 8 (IMC) e máximo igual ao maior valor da série mais alta, exceto IMC, fixo em 38, como `DrawIndicatorGraph`.

#### Scenario: Faixa de peso para idade
- **WHEN** o gráfico de peso para idade de uma menina é exibido no modo z-score
- **THEN** o domínio x é 0...130, o mínimo de y é 0 e o máximo de y é o maior valor da série "+3 DP"

#### Scenario: Faixa de IMC para idade
- **WHEN** o gráfico de IMC para idade é exibido no modo percentil
- **THEN** o domínio x é 0...248 e o domínio y é 8...38

### Requirement: Títulos do gráfico e dos eixos
O gráfico SHALL usar o título "Padrões de crescimento da OMS (nascimento a 60 meses), referência OMS 2007 (61 meses a 19 anos)", o eixo x "Idade (meses)" e o eixo y "Peso (kg)", "Comprimento/estatura (cm)" ou "Índice de massa corporal" conforme o indicador.

#### Scenario: Títulos de estatura para idade
- **WHEN** o gráfico de estatura para idade é exibido
- **THEN** o título do eixo x é "Idade (meses)" e o do eixo y é "Comprimento/estatura (cm)"

#### Scenario: Título do gráfico vazio
- **WHEN** não há ponto desenhável
- **THEN** o título é "(Sem dados)"

### Requirement: Valor plotado de cada medida
Cada resultado desenhado SHALL virar um ponto com x igual à idade em meses e y igual ao peso, à medida ajustada ou ao IMC exato da medida ajustada, conforme o indicador; resultado com z-score `nil` no indicador SHALL ser omitido, como `GraphDialog.DrawMeasures`.

#### Scenario: Ponto de IMC
- **WHEN** o gráfico de IMC recebe um resultado de 2192 dias com peso 20 e medida ajustada 110
- **THEN** há um ponto com x = 2192 / 30.4375 e y igual a 16.5289256198347 arredondado a 13 casas

#### Scenario: Resultado sem z omitido
- **WHEN** o gráfico de peso recebe um resultado com z de peso para idade `nil`
- **THEN** não há ponto desenhado e `isEmpty` é verdadeiro

### Requirement: Limite de idade dos pontos
O gráfico SHALL omitir e marcar como fora do intervalo o ponto com idade negativa, com parte inteira dos meses acima de 108 para peso para idade, ou acima de 228 para os demais, e SHALL acrescentar " (valor(es) fora do intervalo)" ao título do eixo x, mesmo com o z de peso definido até 121 meses.

#### Scenario: Peso aos 109 meses fora do gráfico
- **WHEN** o gráfico de peso para idade recebe dois resultados com z definido, de 3317 dias (108.98 meses) e 3318 dias (109.01 meses), no modo de vários pontos
- **THEN** só o de 3317 dias é desenhado, `hasOutOfRangePoints` é verdadeiro e o título do eixo x é "Idade (meses) (valor(es) fora do intervalo)"

#### Scenario: Só pontos fora do intervalo
- **WHEN** o gráfico de peso para idade recebe apenas um resultado de 3318 dias com z definido
- **THEN** `isEmpty` é verdadeiro e o título é "(Sem dados)"

### Requirement: Ponto atual e legenda
O ponto do índice atual SHALL ter linhas-guia com estilo `.current` e legenda "{idade}, z-score: {z}" ou "{idade}, Percentil: {p}", com z em 2 casas, percentil em 1 casa ou "N/D", e a idade de `GetLocalizedAgeFromMonths` incluída só quando a idade em dias for positiva; os demais pontos SHALL ter estilo `.other`.

#### Scenario: Legenda no modo z-score
- **WHEN** o resultado atual tem 2192 dias e z de peso para idade -2.35
- **THEN** a legenda é "Idade: 6a 0m (72m), z-score: -2,35"

#### Scenario: Legenda no modo percentil sem percentil
- **WHEN** o resultado atual tem 2192 dias, z de IMC 3.50 e percentil `nil`, no modo percentil
- **THEN** a legenda é "Idade: 6a 0m (72m), Percentil: N/D"

#### Scenario: Legenda sem idade no nascimento
- **WHEN** o resultado atual tem 0 dias e z de peso para idade 0.00
- **THEN** a legenda é "z-score: 0,00"

### Requirement: Um ponto ou vários pontos
O gráfico SHALL oferecer a escolha entre ponto único e vários pontos só quando houver mais de um resultado; no ponto único SHALL desenhar só o índice atual, e com vários pontos SHALL desenhar todos os desenháveis na ordem recebida, ligados por uma linha quando houver ao menos dois.

#### Scenario: Três visitas com vários pontos
- **WHEN** o gráfico recebe três resultados desenháveis, índice atual 1, e o modo de vários pontos é ligado
- **THEN** há 3 pontos na ordem recebida, `showsConnectingLine` é verdadeiro e só o ponto de índice 1 tem estilo `.current`

#### Scenario: Ponto único entre três visitas
- **WHEN** o gráfico recebe três resultados desenháveis, índice atual 2, no modo de ponto único
- **THEN** há 1 ponto, o do índice 2, e `showsConnectingLine` é falso

#### Scenario: Resultado único sem escolha
- **WHEN** o gráfico recebe um único resultado e tenta ligar o modo de vários pontos
- **THEN** `canShowMultiplePoints` é falso e `showMultiplePoints` permanece falso

### Requirement: Troca de indicador e de modo
Trocar o indicador ou o modo SHALL recalcular curvas, pontos e faixas e SHALL descartar o zoom, voltando à faixa completa, como `RefreshGraph`.

#### Scenario: De peso para IMC
- **WHEN** o gráfico de peso para idade no modo z-score passa para IMC para idade
- **THEN** há 7 séries e o domínio y visível é 8...38

#### Scenario: Troca de modo descarta o zoom
- **WHEN** o gráfico tem zoom em x 60...120 e o modo passa para percentil
- **THEN** o domínio visível é igual ao domínio completo do novo modo

### Requirement: Zoom por área, deslocamento e restauração
O gráfico SHALL ampliar para a área selecionada, ignorando seleção com largura ou altura zero; SHALL deslocar a faixa visível por um delta em x ou y; e SHALL restaurar a faixa completa, como as interações `RubberBandSelection`, `HorizontalDrag`, `VerticalDrag` e `OriginalDimensions` do NPlot.

#### Scenario: Zoom e restauração
- **WHEN** o gráfico recebe zoom para x 60...120 e y 10...30 e depois é restaurado
- **THEN** após o zoom os domínios visíveis são 60...120 e 10...30, e após a restauração são iguais aos completos

#### Scenario: Seleção degenerada ignorada
- **WHEN** o gráfico recebe zoom para x 60...60 e y 10...30
- **THEN** os domínios visíveis permanecem os anteriores

#### Scenario: Deslocamento horizontal
- **WHEN** o gráfico com domínio visível x 60...120 é deslocado em 12 meses
- **THEN** o domínio visível x é 72...132 e o domínio y não muda

### Requirement: Copiar imagem do gráfico
O gráfico SHALL copiar para a área de transferência a imagem renderizada em PNG, e SHALL devolver falha sem alterar a área de transferência quando não houver imagem.

#### Scenario: Cópia em PNG
- **WHEN** uma imagem de 400 por 300 pixels é copiada para uma área de transferência nomeada de teste
- **THEN** a área de transferência contém dados do tipo PNG que começam com os bytes 89 50 4E 47

#### Scenario: Cópia sem imagem
- **WHEN** a cópia recebe imagem `nil`
- **THEN** o retorno é falso e a contagem de alterações da área de transferência não muda

### Requirement: Exportar e imprimir o gráfico
O gráfico SHALL exportar a imagem como PNG ou PDF de uma página e criar a operação de impressão a partir desse PDF, com nome de arquivo sugerido "{indicador} - {modo} - {AAAA-MM-DD}" e barras trocadas por hífen.

#### Scenario: Exportações válidas
- **WHEN** uma imagem de 400 por 300 pixels é exportada
- **THEN** o PNG começa com os bytes 89 50 4E 47, o PDF começa com "%PDF" e tem 1 página, e a operação de impressão criada a partir do PDF não é `nil`

#### Scenario: Nome de arquivo sem barra
- **WHEN** o nome sugerido é pedido para estatura para idade, modo percentil, em 2026-10-14
- **THEN** o nome é "Comprimento-estatura para idade - Percentil - 2026-10-14"

#### Scenario: PDF inválido para impressão
- **WHEN** a operação de impressão recebe dados que não são PDF
- **THEN** o retorno é `nil`
