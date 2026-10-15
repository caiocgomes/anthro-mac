# Spec Delta

## ADDED Requirements

### Requirement: Escolha do leitor pela extensão
O sistema SHALL escolher o leitor pela extensão do arquivo, sem diferenciar maiúsculas, como `NSMain.importFromFileToolStripMenuItem_Click`: `.txt` e `.csv` como texto delimitado, `.rec` como Epi Info, `.dbf` como XBase e qualquer outra extensão como XML do Anthro/AnthroPlus.

#### Scenario: Extensões conhecidas
- **WHEN** o sistema classifica `a.TXT`, `b.csv`, `c.Rec`, `d.dbf` e `e.xml`
- **THEN** os leitores são texto delimitado com tabulação, texto delimitado com ponto e vírgula, REC, DBF e XML

#### Scenario: Extensão desconhecida vira XML
- **WHEN** o arquivo `medidas.dat` com conteúdo `Sex;Weight` é importado
- **THEN** o sistema o lê como XML e a importação falha com `ImportFailure.invalidStructure`

### Requirement: Decodificação de texto importado
O sistema SHALL decodificar TXT, CSV e REC respeitando BOM de UTF-8, UTF-16 LE e UTF-16 BE; sem BOM, SHALL usar UTF-8 se os bytes forem UTF-8 válido e Windows-1252 caso contrário, removendo o BOM do texto.

#### Scenario: Arquivo do Excel em Windows-1252
- **WHEN** o arquivo contém os bytes `4A 6F E3 6F` sem BOM
- **THEN** o texto decodificado é `João`

#### Scenario: Arquivo UTF-8 com BOM
- **WHEN** o arquivo contém `EF BB BF` seguido de `Jo\u{E3}o` em UTF-8
- **THEN** o texto decodificado é `João`, sem o caractere do BOM

#### Scenario: Arquivo UTF-16 LE com BOM
- **WHEN** o arquivo começa com `FF FE` e contém `Sex` em UTF-16 LE
- **THEN** o texto decodificado é `Sex`

### Requirement: Separador do texto delimitado
O sistema SHALL usar o padrão de `NSMain` (tabulação para `.txt`, ponto e vírgula para `.csv`) quando ele aparecer fora de aspas na primeira linha não vazia; sem ele, SHALL contar tabulações, pontos e vírgulas e vírgulas fora de aspas nessa linha e usar o mais frequente como separador, e em empate ou sem nenhum, o padrão.

#### Scenario: CSV com vírgula
- **WHEN** a primeira linha de um `.csv` é `Sex,Weight,Height`
- **THEN** o separador é vírgula

#### Scenario: CSV com ponto e vírgula e vírgula decimal
- **WHEN** a primeira linha de um `.csv` é `Sex;Weight;Height` e as seguintes trazem `1;16,5;110`
- **THEN** o separador é ponto e vírgula e o peso lido é 16.5

#### Scenario: Primeira linha sem separador
- **WHEN** a primeira linha de um `.csv` é `Sex`
- **THEN** o separador é ponto e vírgula e a tabela tem uma coluna

#### Scenario: Separador entre aspas não conta
- **WHEN** a primeira linha de um `.csv` é `"Nome, completo";Sex`
- **THEN** o separador é ponto e vírgula

### Requirement: Leitura de campos delimitados
O sistema SHALL ler cada campo como `DelimitedTextStream.GetNextItem`: ignorar espaços antes do campo, tratar aspas iniciais como delimitador com `""` valendo uma aspa, aceitar separador e quebra de linha dentro de aspas e reconhecer CRLF, LF e CR como fim de linha; aspas abertas até o fim do texto SHALL tornar o formato inválido, porque engoliriam os registros seguintes.

#### Scenario: Campo entre aspas com separador
- **WHEN** a linha é `"Silva; Ana";2` com separador ponto e vírgula
- **THEN** os campos são `Silva; Ana` e `2`

#### Scenario: Espaço inicial e aspas duplicadas
- **WHEN** a linha é ` 15;"a""b"` com separador ponto e vírgula
- **THEN** os campos são `15` e `a"b`

#### Scenario: Quebra de linha dentro de aspas
- **WHEN** o arquivo tem cabeçalho `Nome;Sex` e o registro `"Ana` / `Maria";2` em duas linhas físicas
- **THEN** a tabela tem um registro, com nome `Ana\nMaria` e sexo `2`

### Requirement: Cabeçalho e nomes de coluna
A primeira linha SHALL ser o cabeçalho, como em `Delimited.ParseStream` com `includeHeader: true`; nome vazio ou repetido SHALL virar `ColumnN` com o menor N livre, e registro com mais campos que o cabeçalho SHALL criar novas colunas `ColumnN`.

#### Scenario: Nomes vazios e repetidos
- **WHEN** o cabeçalho é `Sex;;Sex`
- **THEN** as colunas são `Sex`, `Column1` e `Column2`

#### Scenario: Registro mais longo que o cabeçalho
- **WHEN** o cabeçalho é `A;B;C` e um registro é `1;2;3;4`
- **THEN** a tabela ganha a coluna `Column1` e o registro tem `4` nela

#### Scenario: Arquivo vazio
- **WHEN** o arquivo `.csv` não tem nenhum caractere
- **THEN** a leitura falha com `ImportFailure.invalidStructure`

### Requirement: Linhas vazias e registros curtos
O sistema SHALL ignorar linhas vazias ou só de campos vazios e SHALL completar com texto vazio os campos que faltarem num registro mais curto que o cabeçalho, em vez de falhar o arquivo inteiro como o original.

#### Scenario: Linha vazia no meio do arquivo
- **WHEN** um `.csv` tem cabeçalho, um registro, uma linha vazia e outro registro
- **THEN** a tabela tem dois registros

#### Scenario: Registro curto
- **WHEN** o cabeçalho é `Sex;Weight;Height` e um registro é `1;16,5`
- **THEN** o registro tem `Height` igual a texto vazio e a importação continua

### Requirement: Leitura de arquivo REC do Epi Info
O sistema SHALL ler REC como `External.ParseRECFile`: número de campos no primeiro token da primeira linha, um descritor por campo com nome no token 1 e largura no token 8, campos de largura 0 ignorados, registros de largura fixa com linhas de 79 caracteres continuando no seguinte, valores sem espaços e NUL nas pontas; largura negativa ou absurda, nome de campo idêntico a outro (como `Columns.Add`) e arquivo sem nenhum campo SHALL tornar o formato inválido.

#### Scenario: REC com dois registros
- **WHEN** a fixture `survey.rec` declara `SEX` (1), `WEIGHT` (5) e `HEIGHT` (5) e traz as linhas `116.50110.0` e `012.30 95.4`
- **THEN** a tabela tem colunas `SEX`, `WEIGHT`, `HEIGHT` e registros `[1, 16.50, 110.0]` e `[0, 12.30, 95.4]`

#### Scenario: Registro em duas linhas físicas
- **WHEN** o REC declara `NOTES` (80) e `SEX` (1), e o registro ocupa uma linha de 79 caracteres (78 letras `a` e o marcador final) e a linha `bb1`
- **THEN** o registro tem `NOTES` com 78 `a` seguidos de `bb` e `SEX` igual a `1`

#### Scenario: Descritor de campo incompleto
- **WHEN** um descritor de campo tem menos de 8 tokens
- **THEN** a leitura falha com `ImportFailure.invalidStructure`

### Requirement: Leitura de arquivo DBF
O sistema SHALL ler DBF como `External.ParseDBFFile`: número de registros no inteiro de 32 bits em 4, tamanho do cabeçalho no de 16 bits em 8, um descritor de 32 bytes por campo com nome nos 11 primeiros bytes sem NUL e largura no byte 16, descritores até o terminador `0x0D`, valores sem espaços nas pontas, e SHALL ignorar registros marcados como apagados (`*`); cabeçalho menor que 33 bytes, nome de campo idêntico a outro e arquivo sem nenhum campo SHALL tornar o formato inválido, nomes SHALL ser decodificados como os valores e nome vazio SHALL virar `ColumnN`.

#### Scenario: DBF com dois registros
- **WHEN** a fixture gerada `survey.dbf` tem campos `SEX` (1) e `WEIGHT` (6) e registros `1`/`16.50` e `2`/`12.30`
- **THEN** a tabela tem colunas `SEX` e `WEIGHT` e os dois registros com esses valores

#### Scenario: Registro apagado
- **WHEN** o segundo registro do DBF tem o marcador `*`
- **THEN** a tabela tem um registro

#### Scenario: DBF truncado
- **WHEN** o cabeçalho declara 2 registros e o arquivo só tem bytes para 1
- **THEN** a leitura falha com `ImportFailure.invalidStructure`

### Requirement: Proposta automática de mapeamento
O sistema SHALL propor o mapeamento de `NSImportDialog` pelo nome em maiúsculas: `SURVDATE`/`SURVEYDATE`, `CLUSTER`, `TEAM`, `ID`, `HH`/`HOUSEHOLD`, `WT FACTOR`, `DOB`/`BIRTHDAT`/`BIRTHDATE`, `AGE`/`MONTHS`, `SEX` exatos; contendo `WEIGHT`, peso; contendo `HEIGHT` ou `LENGTH`, altura; `MEASURE`, `EDEMA`/`OEDEMA` exatos; a última coluna vence.

#### Scenario: Colunas usuais
- **WHEN** as colunas são `ID`, `Sex`, `Weight_kg`, `Length`, `Oedema` e `escola`
- **THEN** a proposta é `displayID` para `ID`, `sex` para `Sex`, `weight` para `Weight_kg`, `height` para `Length`, `hasOedema` para `Oedema`, e `escola` fica sem campo

#### Scenario: Fator de ponderação sem espaço
- **WHEN** as colunas são `WT FACTOR` e `WEIGHTFACTOR`
- **THEN** `weightingFactor` aponta para `WT FACTOR` e `weight` aponta para `WEIGHTFACTOR`

#### Scenario: Duas colunas para o mesmo campo
- **WHEN** as colunas são `weight1` e `weight2`
- **THEN** `weight` aponta para `weight2`

### Requirement: Sexo obrigatório no mapeamento
A montagem do inquérito SHALL falhar com campo obrigatório ausente, linha 0 e campo `Sex`, quando o sexo não estiver mapeado, como `_IMPORT_MANDATORYFIELDS` de `Survey`.

#### Scenario: Sexo não mapeado
- **WHEN** o mapeamento tem peso e altura mas não sexo
- **THEN** a montagem falha com `ImportFailure.missingField([ImportFieldError(line: 0, field: "Sex")])`

#### Scenario: Sexo mapeado
- **WHEN** o mapeamento tem só sexo e a tabela tem 3 registros válidos
- **THEN** o inquérito montado tem 3 registros

### Requirement: Registros com sexo inválido
O sistema SHALL descartar todo registro cujo sexo não seja reconhecido e SHALL listar no máximo os 10 primeiros, cada um com o número do registro contado a partir de 1 e o nome da coluna de sexo.

#### Scenario: Doze registros com sexo inválido
- **WHEN** uma tabela de 20 registros tem sexo `x` nos registros 3 a 14 e a coluna de sexo se chama `sexo`
- **THEN** o inquérito tem 8 registros e a lista de erros tem 10 entradas, a primeira `ImportFieldError(line: 3, field: "sexo")`

#### Scenario: Sexo com código 2
- **WHEN** um registro tem sexo `2`
- **THEN** o registro é mantido como menina

### Requirement: Campos opcionais inválidos e fator de ponderação
Campo opcional inválido SHALL ficar ausente e marcar aviso, mantendo o registro; o fator de ponderação SHALL valer 1 sem mapeamento e 0 com aviso se mapeado e vazio ou inválido; edema ausente SHALL valer não, como `CreateSurveyFromExternalData`.

#### Scenario: Data de visita inválida
- **WHEN** o campo mapeado como data da visita vale `31/02/2021`
- **THEN** o registro é mantido com data `nil` e `hadFieldWarnings` é verdadeiro

#### Scenario: Fator de ponderação vazio e sem mapeamento
- **WHEN** um inquérito é montado com o fator mapeado e vazio, e outro sem mapear o fator
- **THEN** os registros do primeiro têm fator 0 com aviso e os do segundo têm fator 1 sem aviso

#### Scenario: Edema não informado
- **WHEN** o edema está mapeado e vazio
- **THEN** o registro tem edema falso

### Requirement: Peso e altura importados
Peso e altura SHALL ser truncados para 2 casas em direção a zero e validados em [0.9, 275] kg e [38, 230] cm; fora dos limites, o valor SHALL ficar ausente com aviso, mantendo o registro.

#### Scenario: Peso com três casas
- **WHEN** o peso é `16.789`
- **THEN** o peso do registro é 16.78

#### Scenario: Peso abaixo do mínimo
- **WHEN** o peso é `0.89`
- **THEN** o peso do registro é `nil` e `hadFieldWarnings` é verdadeiro

### Requirement: Medida deitada derivada
Sem medida mapeada ou com valor inválido, o sistema SHALL definir deitado quando a idade em dias (pela idade em meses ou pelas datas) for menor que 731 e, sem idade, quando a altura for menor que 87 cm; nos demais casos, em pé.

#### Scenario: Idade abaixo de 731 dias
- **WHEN** a idade em meses é 23.9 e a medida não está mapeada
- **THEN** o registro é marcado como medido deitado

#### Scenario: Sem idade e com altura de corte
- **WHEN** não há idade nem datas e as alturas são 86.9 e 87.0 cm em dois registros
- **THEN** o primeiro é deitado e o segundo em pé

#### Scenario: Sem idade e sem altura
- **WHEN** não há idade, datas nem altura
- **THEN** o registro é marcado como medido em pé

### Requirement: Colunas não mapeadas como dados adicionais
As colunas não mapeadas SHALL virar variáveis de texto de uma seção `Imported` na definição de dados adicionais do inquérito, uma por coluna e na ordem da tabela, e cada registro SHALL guardar seus valores nessa seção, ambos codificados com `AdditionalDataXML.encode` (change `add-additional-data`); sem colunas não mapeadas, a definição SHALL ficar ausente.

#### Scenario: Duas colunas extras
- **WHEN** a tabela tem `Sex`, `escola` e `turma` e só `Sex` está mapeado
- **THEN** a definição decodificada tem a seção `Imported` com as variáveis de texto `escola` e `turma`, e o XML de cada registro decodificado traz nelas os textos da linha

#### Scenario: Todas as colunas mapeadas
- **WHEN** a tabela tem só `Sex` e `Weight`, ambas mapeadas, e dois registros
- **THEN** o inquérito tem dois registros, `additionalDataDefinitionXML` é `nil` e nenhum registro tem `additionalDataXML`

### Requirement: Rascunho do inquérito importado
A importação de TXT, CSV, REC ou DBF SHALL passar pela etapa de mapeamento com a proposta automática e, ao confirmar, SHALL entregar ao editor de inquérito um rascunho não salvo com o nome do arquivo sem extensão, sem gravar nada.

#### Scenario: Importar CSV até o rascunho
- **WHEN** a usuária importa `escola_a.csv` com 5 registros válidos e confirma o mapeamento proposto
- **THEN** o editor recebe um rascunho de nome `escola_a` com 5 registros e o número de inquéritos no banco não muda

#### Scenario: Cancelar o mapeamento
- **WHEN** a usuária abre `escola_a.csv` e cancela na etapa de mapeamento
- **THEN** a fase volta a `.idle` e o editor não recebe rascunho

### Requirement: Mensagens da importação externa
O modelo SHALL avisar, com as mensagens pt-BR equivalentes a `Utils.DisplayImportWarningRows` e `DisplayImportWarningFields`, quando registros forem descartados (com linha e campo de cada erro) ou quando houver campos inválidos.

#### Scenario: Aviso de registros descartados
- **WHEN** a importação de `escola_a.csv` descarta o registro 3 por sexo inválido na coluna `Sex`
- **THEN** o aviso começa com `O arquivo 'escola_a.csv' foi importado, mas uma ou mais linhas foram ignoradas por campos obrigatórios ausentes ou inválidos.` e contém `linha 3, campo 'Sex'.`

#### Scenario: Aviso só de campos inválidos
- **WHEN** a importação de `escola_a.csv` não descarta registros mas tem um peso fora do limite
- **THEN** o aviso é `O arquivo 'escola_a.csv' foi importado, mas um ou mais campos estavam ausentes ou continham valores inválidos.`

#### Scenario: Importação limpa
- **WHEN** a importação não descarta registros nem tem campos inválidos
- **THEN** não há aviso

### Requirement: Importação de XML de inquéritos
O sistema SHALL ler XML como `Survey.ImportSurveysFromXML`: nome, sexo, `DateOfBirthIsApprox`, `IsRecumbent`, `HasOedema` e `CreatedBy` do registro obrigatórios, peso e altura truncados e limitados, fator de ponderação sem truncamento, opções por `SurveyOptions(xml:)` e dados adicionais por `AdditionalDataXML.decode`; qualquer valor inválido, inclusive nome de inquérito em branco, SHALL rejeitar o arquivo inteiro, e textos cortados nos limites do original SHALL ser avisados.

#### Scenario: XML com dois inquéritos
- **WHEN** a fixture `ns-two-surveys.xml` tem dois inquéritos com 2 e 1 registros
- **THEN** a leitura devolve dois inquéritos com 2 e 1 registros, nomes e fatores de ponderação iguais aos do arquivo

#### Scenario: Fator de ponderação sem truncamento
- **WHEN** um registro tem `WeightingFactor="1.2345"`
- **THEN** o fator lido é 1.2345

#### Scenario: Registro sem CreatedBy
- **WHEN** um registro não tem o atributo `CreatedBy`
- **THEN** a leitura falha com `ImportFailure.invalidStructure`

#### Scenario: Opções malformadas
- **WHEN** o atributo `Options` do inquérito vale `<Opt><O ID="x">`
- **THEN** a leitura falha com `ImportFailure.invalidStructure`

### Requirement: XML do WHO Anthro com idade em dias
Quando o primeiro registro do arquivo tiver o atributo `HC`, o sistema SHALL ler `Age` de todos os registros como dias e convertê-la para meses dividindo por 30.4375; sem `HC`, `Age` SHALL ser lida como meses.

#### Scenario: Arquivo do WHO Anthro
- **WHEN** o primeiro registro tem `HC="48.5"` e `Age="1843"`
- **THEN** a idade em meses do registro é 1843 / 30.4375

#### Scenario: Arquivo do AnthroPlus
- **WHEN** nenhum registro tem `HC` e um registro tem `Age="60.55"`
- **THEN** a idade em meses do registro é 60.55

### Requirement: Gravação da importação XML
A importação XML aceita SHALL gravar todos os inquéritos e registros numa única transação e listá-los em seguida; falha de leitura ou de gravação SHALL deixar o banco sem nenhum inquérito novo, e arquivo sem nenhum `Survey` SHALL ser informado como falha.

#### Scenario: Dois inquéritos gravados
- **WHEN** `ns-two-surveys.xml` é importado pelo modelo
- **THEN** o banco ganha 2 inquéritos e 3 registros

#### Scenario: Sexo inválido no XML
- **WHEN** um registro do segundo inquérito tem `Sex="x"`
- **THEN** o modelo termina em falha com a mensagem de formato inválido e o banco não ganha inquéritos

#### Scenario: Falha na gravação do segundo inquérito
- **WHEN** `ns-two-surveys.xml` é lido sem erro mas a gravação do segundo inquérito falha
- **THEN** `insertAll` lança erro e o banco não ganha inquéritos nem registros

### Requirement: Colunas da exportação delimitada de inquérito
A exportação TXT e CSV SHALL ter os 18 nomes de coluna de `Survey.ExportSurveyToDelimitedFile` (Date a CreatedBy), mais WAZ, HAZ, BAZ e BMI com resultados e as colunas de `AdditionalDataColumns.structure` do inquérito; `Age` SHALL trazer a idade de `SurveyRecordEvaluation.ageInMonths` com 10 casas.

#### Scenario: Cabeçalho do inquérito
- **WHEN** um inquérito é exportado em CSV sem resultados e sem dados adicionais
- **THEN** a primeira linha é `Date;Cluster;Team;DisplayID;Household;WeightingFactor;FirstName;LastName;DateOfBirth;DateOfBirthIsApprox;Age;Sex;Weight;Height;IsRecumbent;HasOedema;Notes;CreatedBy`

#### Scenario: Cabeçalho com resultados e dados adicionais
- **WHEN** um inquérito com a variável adicional `escola` é exportado em TXT com resultados
- **THEN** a primeira linha tem 23 campos e os campos 19 a 23 são `WAZ`, `HAZ`, `BAZ`, `BMI` e `escola`

#### Scenario: Idade calculada pelas datas
- **WHEN** o registro não tem idade guardada, nasceu em 2016-03-15 e foi medido em 2021-04-01
- **THEN** o campo `Age` é `60,5503080082`

#### Scenario: Idade desconhecida
- **WHEN** o registro não tem idade nem data de nascimento
- **THEN** o campo `Age` é vazio

### Requirement: Exportação delimitada de um só inquérito
Com mais de um inquérito marcado e formato TXT ou CSV, o sistema SHALL exportar só o primeiro marcado e SHALL devolver o aviso de que os demais não foram exportados, como `NSMain_ExportFlatMultipleWarning`; o XML SHALL incluir todos os marcados.

#### Scenario: Dois inquéritos em CSV
- **WHEN** dois inquéritos estão marcados e a exportação é CSV
- **THEN** o arquivo só tem os registros do primeiro e a exportação devolve `.onlyFirstSurveyExported`

#### Scenario: Dois inquéritos em XML
- **WHEN** dois inquéritos estão marcados e a exportação é XML
- **THEN** o arquivo tem dois elementos `Survey` e a exportação não devolve aviso

### Requirement: Esquema XML de exportação de inquéritos
O XML SHALL ter raiz `Surveys`, um `Survey` com `Name`, `Notes`, `AdditionalDataDef` (se houver), `Options` (de `SurveyOptions.xml()`) e `CreatedBy`, e `Records` com um `Record` por registro só quando houver registros; `Record` SHALL sempre trazer `AdditionalData`, com `<Data />` quando não houver dados, e `CreatedBy`.

#### Scenario: Inquérito com registros e resultados
- **WHEN** um inquérito com um registro é exportado com resultados
- **THEN** o documento tem `/Surveys/Survey/Records/Record` com os atributos `Date`, `Cluster`, `Team`, `DisplayID`, `Household`, `WeightingFactor`, `FirstName`, `LastName`, `DateOfBirth`, `DateOfBirthIsApprox`, `Age`, `Sex`, `Weight`, `Height`, `IsRecumbent`, `HasOedema`, `Notes`, `AdditionalData`, `CreatedBy`, `WAZ`, `HAZ`, `BAZ` e `BMI`

#### Scenario: Inquérito sem registros
- **WHEN** um inquérito sem registros é exportado em XML
- **THEN** o elemento `Survey` não tem filhos

### Requirement: CreatedBy fixo na exportação e descartado na importação
A exportação SHALL escrever `ExchangeDefaults.createdBy` em todo `CreatedBy` de inquérito e de registro, no XML e na coluna `CreatedBy`; a importação XML SHALL ler o atributo, com a obrigatoriedade do original no registro, e descartá-lo, porque o app não tem multiusuário.

#### Scenario: CreatedBy na exportação de inquérito
- **WHEN** um inquérito com um registro é exportado em XML e em CSV
- **THEN** `Survey` e `Record` trazem `CreatedBy="AnthroPlus"` e o campo `CreatedBy` do CSV é `AnthroPlus`

#### Scenario: CreatedBy lido e descartado
- **WHEN** um XML com `CreatedBy="obs1"` no inquérito e nos registros é lido e exportado de novo
- **THEN** a leitura é aceita e o novo XML traz `CreatedBy="AnthroPlus"` no inquérito e nos registros

### Requirement: Idade lida com as duas datas
Na importação externa e na XML, o sistema SHALL descartar a idade em meses lida quando o registro tiver data da pesquisa e data de nascimento, como o setter de `Record.Age` do original, que zera a idade sempre que as duas datas existem; o editor de registro da change `add-nutritional-survey` só aceita idade digitada sem as duas datas.

#### Scenario: Planilha com as duas datas e a idade
- **WHEN** a tabela mapeia data da pesquisa, nascimento e idade, e um registro traz `01/04/2021`, `15/03/2016` e `70`
- **THEN** o registro montado tem as duas datas e idade em meses `nil`

#### Scenario: XML com as duas datas e a idade
- **WHEN** um registro do XML tem `Date`, `DateOfBirth` e `Age="70"`
- **THEN** o registro lido tem as duas datas e idade em meses `nil`

### Requirement: Ida e volta de inquérito pelo XML
Um inquérito exportado em XML e lido de volta SHALL ter os mesmos valores de campo em cada registro, com textos dentro dos limites do original e registro sem dados adicionais voltando com `<Data />`; o campo `Age` do arquivo traz a idade calculada quando o registro não tem idade guardada, e essa idade é descartada na leitura quando o registro tem as duas datas.

#### Scenario: Exportar e reler inquérito
- **WHEN** um inquérito com três registros, um deles sem idade guardada e com as duas datas, é exportado e lido por `SurveyXML.read`
- **THEN** o arquivo traz `Age` com a idade calculada com 10 casas para esse registro, e os registros lidos são iguais aos exportados, inclusive esse registro sem idade guardada

#### Scenario: Inquérito com dados adicionais na ida e volta
- **WHEN** o inquérito tem `AdditionalDataDef` e registros com `AdditionalData`
- **THEN** os XML lidos são iguais, como texto, aos exportados
