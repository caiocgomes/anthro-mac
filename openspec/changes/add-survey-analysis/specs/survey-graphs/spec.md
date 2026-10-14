# Spec Delta

Nos cenários, "doze z de densidade" são os z -2, -1.5, -1, -0.5, 0, 0, 0.5, 1, 1.5, 2, -0.25 e 0.25.

## ADDED Requirements

### Requirement: Curva normal de referência
O sistema SHALL gerar a curva normal padrão com x de -5 em passos `Double` de 10/resolução enquanto x < 5, e y = $2.718281828^{-x^2/2} / \sqrt{2\pi}$, com a constante de Euler truncada do original, como `AnthroAnalysis.GetNormalCurvePoints`.

#### Scenario: Resolução 500
- **WHEN** o sistema gera a curva normal com resolução 500
- **THEN** a curva tem 501 pontos, o primeiro com x = -5 e y igual a 1.48671951787e-6 com erro absoluto menor que $10^{-15}$, e o maior y arredondado a 8 casas é 0.39894228

#### Scenario: Resolução pequena
- **WHEN** o sistema gera a curva normal com resolução 10
- **THEN** a curva tem 10 pontos e o último x é 4

### Requirement: Densidade de Epanechnikov
O sistema SHALL estimar a densidade dos z com núcleo de Epanechnikov, largura $h = 0.9\,s / n^{0.2}$ (média e $s$ sem ponderação), tamanho $W = \sum w'_i$ com $w'_i = w_i$ se $w_i > 0$ e 1 caso contrário, grade de -5 em passos de $10/\min(W, 50)$ enquanto x < 5 + passo, e $y(x) = \sum w'_i\, 0.75 (1 - 0.2 u_i^2)/\sqrt 5 / (W h)$ para $|u_i| < \sqrt 5$.

#### Scenario: Doze z com tamanho ponderado 50
- **WHEN** o sistema estima a densidade dos doze z de densidade com fatores 4 nos dez primeiros e 5 nos dois últimos
- **THEN** o tamanho é 50, a grade tem 51 pontos de -5 a 5, y em x = 0 arredondado a 6 casas é 0.301381 e y em x = -5 é 0

#### Scenario: Doze z com fator 1
- **WHEN** o sistema estima a densidade dos doze z de densidade com fator 1
- **THEN** o tamanho é 12, a grade tem 14 pontos, o último x arredondado a 4 casas é 5.8333 e y no ponto mais próximo de 0 arredondado a 6 casas é 0.292832

#### Scenario: Fatores zero contam como 1
- **WHEN** o sistema estima a densidade dos doze z de densidade com fator 0
- **THEN** o tamanho é 12 e a grade tem 14 pontos

### Requirement: Densidade sem curva
O sistema SHALL devolver uma curva vazia quando o tamanho ponderado for 0 ou 1, e SHALL lançar `DensityError.zeroBandwidth` quando todos os z forem iguais, caso em que o original lança divisão por zero.

#### Scenario: Um único z
- **WHEN** o sistema estima a densidade do z 0.3 com fator 1
- **THEN** a curva tem 0 pontos e tamanho 1

#### Scenario: Todos os z iguais
- **WHEN** o sistema estima a densidade de 12 z iguais a 0.5 com fator 1
- **THEN** a estimativa lança `DensityError.zeroBandwidth`

### Requirement: Seleção dos z para a densidade
A densidade de todas as crianças SHALL usar todos os registros do inquérito, e a densidade por sexo SHALL usar só os registros de 61 a 228 meses do sexo; em ambos, z implausíveis pelos limites padrão do AnthroCore SHALL ficar de fora, como `GetZScoresForIndicator`.

#### Scenario: Limite padrão de plausibilidade
- **WHEN** o sistema seleciona os z de IMC de registros de 96 meses com z 5.5 e 4.9
- **THEN** só o z 4.9 é selecionado

#### Scenario: Criança abaixo de 61 meses
- **WHEN** o sistema seleciona os z de IMC de uma menina de 50 meses com z 0.4
- **THEN** o z entra na seleção de todas as crianças e não entra na seleção de meninas

### Requirement: Séries do gráfico de densidade
O gráfico SHALL mostrar a curva normal em verde com o rótulo dos padrões da OMS e, por filtro, a densidade de todas as crianças em vermelho ("Todas as crianças (n=W)") ou as de meninas em violeta e meninos em azul ("Feminino (n=W)", "Masculino (n=W)"), com W arredondado; erro de largura zero em qualquer série SHALL esvaziar o gráfico.

#### Scenario: Rótulo de todas as crianças
- **WHEN** o gráfico de densidade de todas as crianças usa os doze z de densidade com tamanho ponderado 50
- **THEN** o gráfico tem 2 séries, a normal verde "Padrões de crescimento da OMS (nascimento a 60 meses), referência OMS 2007 (61 meses a 19 anos)" e a vermelha "Todas as crianças (n=50)"

#### Scenario: Meninos com z iguais
- **WHEN** o gráfico por sexo tem meninas com os doze z de densidade e 12 meninos com z 0.5
- **THEN** o gráfico fica vazio com o título "(Sem dados)"

### Requirement: Barras de média e DP por faixa etária
O sistema SHALL gerar uma barra por faixa de `AgeGroups.groups(fromBoundaries:)`, na posição 1 a k, de 0 até a média, com haste até $\mathrm{sinal}(m)(|m| + DP)$, rótulo "inferior-superior" da faixa, contagem "n=" com N arredondado, cor tomate para média positiva e preta para negativa, como `GetValuesForCandlePlotByAge`.

#### Scenario: Duas faixas com médias de sinais opostos
- **WHEN** o sistema gera as barras de IMC com `SurveyOptions.default` para registros de 96 meses com z -1 e -2 e registros de 108 meses com z 1 e 2
- **THEN** a barra "96-107" vai de -1.5 a 0, com haste até -2.2071 (4 casas), n = 2 e cor preta, e a barra "108-119" vai de 0 a 1.5, com haste até 2.2071 e cor tomate

#### Scenario: Faixa vazia e N fracionado
- **WHEN** o sistema gera as barras de IMC com `SurveyOptions.default` para 1 registro de 96 meses com z 1 e fator 1.5
- **THEN** a barra "96-107" tem contagem 2, a barra "228-228" não tem média nem haste e tem contagem 0

### Requirement: Barras de média e DP por cluster
O sistema SHALL gerar uma barra por cluster com registros de 61 a 228 meses, em ordem crescente do número do cluster, rotulada pelo número, com contagem igual à parte inteira de N, como `GetValuesForCandlePlotByCluster`; sem clusters o gráfico SHALL ficar vazio.

#### Scenario: Dois clusters
- **WHEN** o sistema gera as barras de IMC por cluster para 1 registro do cluster 5 com z 1 e fator 1.5 e 2 registros do cluster 2 com z -1 e 0
- **THEN** as barras são "2" e "5", nessa ordem, com contagens 2 e 1

#### Scenario: Nenhum cluster
- **WHEN** o sistema gera as barras por cluster para registros sem cluster
- **THEN** a lista de barras é vazia e o gráfico mostra "(Sem dados)"

### Requirement: Disponibilidade da aba de resultados
A aba de resultados SHALL exigir pelo menos 12 registros no inquérito, válidos ou não, e com menos SHALL mostrar "A análise requer que o inquérito contenha pelo menos 12 registros válidos." sem calcular gráfico, como `tabNutriSurvey_Selected`.

#### Scenario: Onze registros
- **WHEN** o usuário abre a aba de resultados de um inquérito com 11 registros
- **THEN** `canShowGraphs` é `false` e a mensagem exposta é "A análise requer que o inquérito contenha pelo menos 12 registros válidos."

#### Scenario: Doze registros sem z
- **WHEN** o usuário abre a aba de resultados de um inquérito com 12 registros, todos sem z
- **THEN** `canShowGraphs` é `true` e o gráfico de densidade fica vazio com o título "(Sem dados)"

### Requirement: Zoom do gráfico
O gráfico de densidade SHALL começar com x de -5 a 5 e y de 0 a 0.45, aceitar zoom para um retângulo com largura e altura positivas e restaurar a vista inicial com o comando de restaurar.

#### Scenario: Zoom e restauração
- **WHEN** o usuário aplica zoom para x de -2 a 2 e y de 0 a 0.2 e depois restaura
- **THEN** depois do zoom os domínios são -2...2 e 0...0.2, e depois de restaurar são -5...5 e 0...0.45

#### Scenario: Retângulo degenerado
- **WHEN** o usuário aplica zoom para x de 1 a 1 e y de 0 a 0.2
- **THEN** os domínios continuam -5...5 e 0...0.45

### Requirement: Copiar e imprimir o gráfico
A aba de resultados SHALL oferecer copiar o gráfico como imagem para a área de transferência e imprimir o gráfico, como `tsbCopyGraph` e `tsbPrintGraph`.

#### Scenario: Comandos presentes na interface
- **WHEN** o app é compilado com `scripts/build-app.sh`
- **THEN** o build termina com código 0 e o binário contém os rótulos "Copiar gráfico" e "Imprimir gráfico" (verificação mecânica: `grep -a -c` sobre o executável em `build/AnthroPlus.app/Contents/MacOS/` encontra as duas strings)

#### Scenario: Gráfico vazio não é copiado
- **WHEN** o gráfico de um inquérito de 12 registros sem z está vazio com o título "(Sem dados)" e depois o modelo recebe os doze z de densidade
- **THEN** `canCopyGraph` é `false` com o gráfico vazio e `true` com o gráfico de densidade
