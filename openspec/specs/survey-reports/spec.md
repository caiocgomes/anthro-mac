# survey-reports Specification

## Purpose
Relatórios do Inquérito nutricional, portados de `NSMain.CreateExcelReport`, `GetReportForIndicator` e `GetWHOReport`: relatório padrão com IC 95% (com ou sem correção por cluster) e relatório de estimativas sem IC no formato do banco global da OMS, em texto tabulado UTF-16 com rótulos em pt-BR, gravado em arquivo, aberto no Excel ou no Numbers e mostrado numa tabela no app.

Nos cenários, "inquérito de dez crianças" é um inquérito com `SurveyOptions.default` (fronteiras 0, 6, 12, 24, 36, 48, 61, 72, 84, 96, 108, 120, 132, 144, 156, 168, 180, 192, 204, 216, 228, 228), 10 registros de 96 meses (5 meninos e 5 meninas), fator 1, sem edema, sem cluster e com os mesmos z nos três indicadores: -3.5, -2.5, -2.1, -1.0, 0.0, 0.5, 1.2, 2.2, 3.1 e 0.0. "Inquérito de quatro clusters" tem 20 registros de 96 meses, 5 por cluster (clusters 1 a 4), com 1, 2, 0 e 1 registros de z -2.5 e os demais com z 0 nos três indicadores. Nas strings, `\t` é tabulação.

## Requirements

### Requirement: Estrutura do relatório padrão
O relatório padrão SHALL conter, nesta ordem, o título, a linha de tabelas com IC, o Conjunto 1 (sexos combinados), o Conjunto 2 (masculino), o Conjunto 3 (feminino), o Conjunto 4 (por cluster) só quando não houver correção por cluster, e as notas; cada conjunto traz peso, estatura e IMC para idade, como `NSMain.CreateExcelReport`.

#### Scenario: Abertura e conjuntos do relatório sem correção
- **WHEN** o sistema gera o relatório padrão sem correção do inquérito de dez crianças
- **THEN** as linhas 1 a 4 são "Análise padrão do inquérito nutricional", "Tabelas detalhadas com intervalos de confiança de 95%*", "" e "Conjunto 1: Sexos combinados", e as linhas "Conjunto 2: Masculino", "Conjunto 3: Feminino" e "Conjunto 4: Geral, sexos combinados por cluster" aparecem uma vez cada, nessa ordem

#### Scenario: Relatório com correção por cluster
- **WHEN** o sistema gera o relatório padrão com correção do inquérito de quatro clusters
- **THEN** nenhuma linha é "Conjunto 4: Geral, sexos combinados por cluster" e as duas últimas linhas começam com "-) " e ".) "

### Requirement: Cabeçalhos das tabelas do relatório padrão
Cada tabela SHALL abrir com a linha de faixas e indicador e a linha de colunas; peso e estatura para idade têm só as colunas abaixo da mediana, IMC para idade tem as cinco; no Conjunto 4 a primeira coluna se chama "Cluster" e as colunas de anos e meses ficam vazias.

#### Scenario: Cabeçalho de IMC para idade
- **WHEN** o sistema gera o relatório padrão sem correção do inquérito de dez crianças
- **THEN** a tabela de IMC do Conjunto 1 abre com "Faixas etárias\t\tN\tIMC para idade (%)" seguida de "Anos\tMeses\t\t% < -3DP\t(IC 95%)\t% < -2DP\t(IC 95%)\t% > +1DP\t(IC 95%)\t% > +2DP\t(IC 95%)\t% > +3DP\t(IC 95%)\tMédia\tDP"

#### Scenario: Cabeçalho de estatura no conjunto por cluster
- **WHEN** o sistema gera o relatório padrão sem correção do inquérito de quatro clusters
- **THEN** a tabela de estatura do Conjunto 4 abre com "Cluster\t\tN\tComprimento/estatura para idade (%)" seguida de "\t\t\t% < -3DP\t(IC 95%)\t% < -2DP\t(IC 95%)\tMédia\tDP"

### Requirement: Linha de total do relatório padrão
A linha de total SHALL usar a população de 61 a 228 meses, o rótulo "Total (a-b)" com os anos do limite igual a 61 e do último limite das faixas do inquérito, o intervalo em meses na segunda coluna, e deixar vazias as colunas de peso para idade; com N igual a 0 a linha SHALL ser "Total\t\t0".

#### Scenario: Total de IMC das dez crianças
- **WHEN** o sistema gera o relatório padrão sem correção do inquérito de dez crianças
- **THEN** a linha de total de IMC do Conjunto 1 é "Total (5-19)\t(61-228)\t10\t10\t(0%, 33,6%)\t30\t(0%, 63,4%)\t30\t(0%, 63,4%)\t20\t(0%, 49,8%)\t10\t(0%, 33,6%)\t-0,21\t2,1" e a de peso é "Total (5-19)\t(61-228)\t\t\t\t\t\t\t"

#### Scenario: Total sem crianças de 61 a 228 meses
- **WHEN** o sistema gera o relatório padrão de um inquérito com 3 registros de 40 meses
- **THEN** a linha de total de estatura do Conjunto 1 é "Total\t\t0"

### Requirement: Linhas das faixas fixas de idade
Depois do total, o relatório SHALL trazer as faixas fixas 61-119, 120-179 e 180-228 meses, rotuladas "Total (5-9)", "Total (10-14)" e "Total (15-19)"; faixa com N igual a 0, ou faixa de peso para idade com início abaixo de 11 ou acima de 108 meses, SHALL trazer só rótulo e intervalo.

#### Scenario: Faixas fixas de estatura
- **WHEN** o sistema gera o relatório padrão sem correção do inquérito de dez crianças
- **THEN** as linhas de estatura seguintes ao total são "Total (5-9)\t(61-119)\t10\t10\t(0%, 33,6%)\t30\t(0%, 63,4%)\t-0,21\t2,1", "Total (10-14)\t(120-179)\t" e "Total (15-19)\t(180-228)\t"

#### Scenario: Peso para idade em faixa acima de 108 meses
- **WHEN** o sistema gera o relatório padrão de um inquérito com 4 registros de 130 meses e z de peso -2.5
- **THEN** a linha de peso da faixa fixa 120-179 é "Total (10-14)\t(120-179)\t"

### Requirement: Linhas das faixas do inquérito
O relatório SHALL trazer uma linha por faixa de `AgeGroups.groups(fromBoundaries:)`, com os anos inteiros do limite inferior, o intervalo "(inferior-superior)" da faixa e as mesmas regras de linha vazia das faixas fixas.

#### Scenario: Faixa de 96 meses e primeira e última faixas
- **WHEN** o sistema gera o relatório padrão sem correção do inquérito de dez crianças
- **THEN** a tabela de IMC do Conjunto 1 contém "8\t(96-107)\t10\t10\t(0%, 33,6%)\t30\t(0%, 63,4%)\t30\t(0%, 63,4%)\t20\t(0%, 49,8%)\t10\t(0%, 33,6%)\t-0,21\t2,1", "0\t(0-5)\t" e "19\t(228-228)\t"

#### Scenario: Peso para idade na faixa de 120 meses
- **WHEN** o sistema gera o relatório padrão de um inquérito com 4 registros de 125 meses e z de peso -2.5
- **THEN** a tabela de peso do Conjunto 1 contém "10\t(120-131)\t"

### Requirement: Formatação dos valores do relatório
O relatório SHALL escrever números com vírgula decimal, sem zeros à direita e sem sinal em zero; IC como "(baixo%, alto%)", IC indisponível como "(-, -)", IC de cluster único como "(., .)" e valor `nil` como um espaço, como `CIToString` e a substituição de `decimal.MinValue`.

#### Scenario: Intervalos calculados
- **WHEN** o sistema formata `.interval(low: 4.7, high: 55.9)` e `.interval(low: 0, high: 100)`
- **THEN** os textos são "(4,7%, 55,9%)" e "(0%, 100%)"

#### Scenario: Valores especiais
- **WHEN** o sistema formata `.unavailable`, `.singleCluster`, uma média `nil` e o valor -0.00
- **THEN** os textos são "(-, -)", "(., .)", " " e "0"

### Requirement: Conjunto por cluster do relatório padrão
O Conjunto 4 SHALL trazer, por indicador, a linha "Total\t\t..." dos registros com cluster de 61 a 228 meses e uma linha por cluster em ordem crescente, rotulada pelo número do cluster; linhas com N igual a 0 SHALL ser omitidas.

#### Scenario: Estatura nos quatro clusters
- **WHEN** o sistema gera o relatório padrão sem correção do inquérito de quatro clusters
- **THEN** a tabela de estatura do Conjunto 4 tem as linhas "Total\t\t20\t0\t(0%, 2,5%)\t20\t(0%, 40%)\t-0,5\t1,03", "1\t\t5\t0\t(0%, 10%)\t20\t(0%, 65,1%)\t-0,5\t1,12", "2\t\t5\t0\t(0%, 10%)\t40\t(0%, 92,9%)\t-1\t1,37", "3\t\t5\t0\t(0%, 10%)\t0\t(0%, 10%)\t0\t0" e "4\t\t5\t0\t(0%, 10%)\t20\t(0%, 65,1%)\t-0,5\t1,12"

#### Scenario: Inquérito sem cluster
- **WHEN** o sistema gera o relatório padrão sem correção do inquérito de dez crianças
- **THEN** a tabela de estatura do Conjunto 4 tem só as duas linhas de cabeçalho seguidas de uma linha vazia

### Requirement: Notas do relatório padrão
O relatório SHALL terminar com as notas de valores baseados nos padrões, de z plausível, de edema, de inclusão dos limiares e do número de crianças com edema (contando todos os registros do inquérito com edema), seguidas da nota de peso para idade; com correção por cluster SHALL acrescentar as notas de prevalências extremas e de cluster único.

#### Scenario: Contagem de crianças com edema
- **WHEN** o sistema gera o relatório padrão de um inquérito com 2 registros com edema entre 12 registros
- **THEN** uma linha é "Número de crianças com edema: 2 (este número pode ser usado para calcular a prevalência de desnutrição edematosa na amostra)" e a última linha começa com "**) "

#### Scenario: Notas da correção por cluster
- **WHEN** o sistema gera o relatório padrão com correção do inquérito de quatro clusters
- **THEN** a penúltima linha começa com "-) Não há IC 95% para prevalências (p)" e a última é ".) Nº de clusters = 1; o IC não pode ser calculado."

### Requirement: Estrutura do relatório de estimativas
O relatório de estimativas SHALL abrir com o título seguido de asterisco, uma linha vazia, as linhas "País:", "Referência:", "Nível administrativo:" e "Mês e ano do inquérito:", uma linha vazia e os conjuntos 1 a 4 separados por linha vazia, terminando com as notas sem as de correção por cluster, como `CreateExcelReport` com `WHOGlobalDatabase`.

#### Scenario: Abertura do relatório de estimativas
- **WHEN** o sistema gera o relatório de estimativas do inquérito de dez crianças
- **THEN** as linhas 1 a 8 são "Relatório de crescimento e estado nutricional de crianças e adolescentes*", "", "País:", "Referência:", "Nível administrativo:", "Mês e ano do inquérito:", "" e "Conjunto 1: Sexos combinados"

#### Scenario: Estimativas sem notas de cluster
- **WHEN** o sistema gera o relatório de estimativas do inquérito de quatro clusters
- **THEN** nenhuma linha começa com "-) " e a última linha começa com "**) "

### Requirement: Tabela do relatório de estimativas
Cada conjunto SHALL ter duas linhas de cabeçalho e linhas com 18 colunas mais tabulação final: rótulos, N de estatura para idade, peso (< -3, < -2, média, DP), estatura (idem) e IMC (cinco limiares, média, DP); peso fica vazio no total sem cluster e quando seus quatro valores forem 0, e N igual a 0 SHALL deixar todas as colunas vazias, como `GetWHOReport`.

#### Scenario: Total e faixa de 5 a 9 anos
- **WHEN** o sistema gera o relatório de estimativas do inquérito de dez crianças
- **THEN** o Conjunto 1 contém "Total (5-19)\t(61-228)\t10\t\t\t\t\t10\t30\t-0,21\t2,1\t10\t30\t30\t20\t10\t-0,21\t2,1\t" e "Total (5-9)\t(61-119)\t10\t10\t30\t-0,21\t2,1\t10\t30\t-0,21\t2,1\t10\t30\t30\t20\t10\t-0,21\t2,1\t"

#### Scenario: Faixa sem crianças
- **WHEN** o sistema gera o relatório de estimativas do inquérito de dez crianças
- **THEN** o Conjunto 1 contém "Total (10-14)\t(120-179)\t0" seguido de 16 tabulações

#### Scenario: Peso para idade sem dados acima de 108 meses
- **WHEN** o sistema gera o relatório de estimativas de um inquérito com 4 registros de 130 meses, z -2.5 nos três indicadores
- **THEN** a linha "10\t(120-131)" tem N = 4, as quatro colunas de peso vazias e prevalência < -2 de estatura igual a 100

### Requirement: Conjunto por cluster do relatório de estimativas
O Conjunto 4 das estimativas SHALL trazer a linha "Total" com peso, estatura e IMC dos registros com cluster e uma linha por cluster; sem nenhum cluster o conjunto SHALL ter só as duas linhas de cabeçalho.

#### Scenario: Total dos quatro clusters
- **WHEN** o sistema gera o relatório de estimativas do inquérito de quatro clusters
- **THEN** o Conjunto 4 contém uma linha que começa com "Total\t\t20\t0\t20\t" e as linhas que começam com "1\t\t5\t", "2\t\t5\t", "3\t\t5\t" e "4\t\t5\t"

#### Scenario: Estimativas sem clusters
- **WHEN** o sistema gera o relatório de estimativas do inquérito de dez crianças
- **THEN** o Conjunto 4 tem só as duas linhas de cabeçalho

### Requirement: Arquivo do relatório
O sistema SHALL gravar o relatório em UTF-16 little-endian com BOM e quebras de linha CRLF, com nome padrão "<nome do inquérito>_standard.txt", "<nome>_standard_cluster.txt" ou "<nome>_estimates.txt", usando "Relatório" quando o nome do inquérito estiver em branco.

#### Scenario: Bytes e nomes do arquivo
- **WHEN** o sistema grava o relatório padrão do inquérito "Escola A" e pede os nomes padrão dos três tipos
- **THEN** o arquivo começa com os bytes FF FE, toda quebra de linha é CR LF, e os nomes são "Escola A_standard.txt", "Escola A_standard_cluster.txt" e "Escola A_estimates.txt"

#### Scenario: Nome em branco e destino sem permissão
- **WHEN** o nome do inquérito é "  " e o destino escolhido é um diretório sem permissão de escrita
- **THEN** o nome padrão do relatório de estimativas é "Relatório_estimates.txt" e a gravação lança erro que o modelo mostra como "Não foi possível salvar no arquivo indicado. Verifique se o arquivo existente não está em uso."

### Requirement: Abertura do relatório gravado
Depois de gravar, o sistema SHALL abrir o arquivo no Microsoft Excel se instalado, senão no Numbers se instalado, senão no aplicativo padrão para o arquivo, equivalente a `Utils.OpenExcel`.

#### Scenario: Excel instalado
- **WHEN** o Excel e o Numbers estão instalados e o relatório é gravado
- **THEN** o arquivo é aberto com o bundle `com.microsoft.Excel`

#### Scenario: Nenhuma planilha instalada
- **WHEN** nem Excel nem Numbers estão instalados
- **THEN** o arquivo é aberto pelo aplicativo padrão do sistema

### Requirement: Visualização do relatório no app
O sistema SHALL mostrar o relatório gerado numa tabela dentro do app, com uma linha por linha do texto e uma célula por campo separado por tabulação, sem alterar o conteúdo gravado.

#### Scenario: Linhas e células da tabela
- **WHEN** o sistema gera o relatório padrão sem correção do inquérito de dez crianças e monta a tabela
- **THEN** a tabela tem o mesmo número de linhas do texto e a linha de total de IMC tem 15 células, a primeira "Total (5-19)" e a última "2,1"

#### Scenario: Linha vazia na tabela
- **WHEN** a tabela é montada a partir da linha 3 do relatório, que é vazia
- **THEN** a linha da tabela tem exatamente 1 célula vazia

### Requirement: Erro de cluster ausente no relatório
Ao pedir o relatório padrão com correção por cluster de um inquérito cuja análise lance `AnalysisError.noClusterData`, o sistema SHALL mostrar "Erro: a variável cluster está vazia." e SHALL não gravar arquivo.

#### Scenario: Correção pedida sem clusters
- **WHEN** o usuário pede o relatório padrão com correção de um inquérito com 2 registros de 110 meses sem cluster
- **THEN** o modelo expõe a mensagem "Erro: a variável cluster está vazia." e o arquivo de destino não existe

#### Scenario: Correção pedida com clusters
- **WHEN** o usuário pede o relatório padrão com correção do inquérito de quatro clusters
- **THEN** nenhuma mensagem de erro é exposta e o arquivo de destino existe
