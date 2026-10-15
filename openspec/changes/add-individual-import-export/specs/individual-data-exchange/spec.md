# Spec Delta

## ADDED Requirements

### Requirement: Conteúdo do relatório da criança
O sistema SHALL gerar o relatório TXT da criança aberta no layout de `IAMain.GenerateChildReport`: título, nome, sobrenome, data de nascimento, sexo, rótulo de resultados, cabeçalho de 12 colunas separadas por tabulação, uma linha por visita na ordem cronológica e a nota sobre padrões e referência da OMS.

#### Scenario: Relatório com duas visitas
- **WHEN** o relatório é gerado para Ana Silva, nascida em 2016-03-15, menina, com visitas em 2021-04-01 (18.4 kg, 110 cm) e 2021-10-01
- **THEN** o texto tem uma linha de cabeçalho de visitas com 12 campos e duas linhas de visita cujo primeiro campo é `1` e `2`, e a primeira linha de visita tem `01/04/2021` no segundo campo, `AnthroPlus` no terceiro (ID do observador) e `18,4` no quarto

#### Scenario: Idade formatada em anos e meses
- **WHEN** a visita ocorre 1843 dias após o nascimento
- **THEN** o campo de idade é `5a 0m` e o campo de idade em meses é `60,5` (truncado a 1 casa)

#### Scenario: Z-score indefinido no relatório
- **WHEN** uma visita tem edema
- **THEN** os campos de z-score de peso para idade e de IMC para idade dessa linha são vazios, o campo de edema é `s` e a linha mantém 12 campos

### Requirement: Arquivo do relatório da criança
O sistema SHALL gravar o relatório em UTF-16 little-endian com BOM e quebras de linha CRLF, como o `StreamWriter` com `Encoding.Unicode` do original, e SHALL sugerir o nome de arquivo `<sobrenome>, <nome>.txt`, omitindo a vírgula quando faltar um dos dois.

#### Scenario: Bytes iniciais e quebras de linha
- **WHEN** o relatório de qualquer criança é gravado
- **THEN** os dois primeiros bytes do arquivo são `FF FE` e todas as quebras de linha decodificadas são `\r\n`

#### Scenario: Nome sugerido sem sobrenome
- **WHEN** a criança tem nome `Ana` e sobrenome vazio
- **THEN** o nome de arquivo sugerido é `Ana.txt`

### Requirement: Colunas da exportação delimitada de crianças
A exportação TXT e CSV de crianças SHALL ter cabeçalho com os 43 nomes de coluna de `Child.ExportChildrenToDelimitedFile` na ordem original (DisplayID a CreatedBy), seguidos de WAZ, HAZ, BAZ e BMI quando os resultados forem incluídos, e depois das colunas de dados adicionais.

#### Scenario: Cabeçalho sem resultados
- **WHEN** duas crianças são exportadas em CSV sem resultados e sem dados adicionais
- **THEN** a primeira linha tem 43 campos, começa com `DisplayID;FirstName;LastName;DateOfBirth;DateOfBirthIsApprox;Sex;ChildNotes;ChildCreatedBy;MotherFirstName` e termina com `Date;Weight;Height;IsRecumbent;HasOedema;Notes;CreatedBy`

#### Scenario: Cabeçalho com resultados
- **WHEN** a mesma exportação inclui resultados
- **THEN** a primeira linha tem 47 campos e os campos 44 a 47 são `WAZ`, `HAZ`, `BAZ` e `BMI`

### Requirement: Uma linha por visita na exportação delimitada
A exportação delimitada SHALL escrever uma linha por visita, repetindo os campos da criança, da mãe, do pai e do endereço, e SHALL escrever uma única linha com as colunas de visita vazias para criança sem visitas.

#### Scenario: Criança com três visitas
- **WHEN** uma criança com três visitas é exportada em TXT
- **THEN** o arquivo tem quatro linhas (cabeçalho e três visitas) e o campo `FirstName` é igual nas três linhas de dados

#### Scenario: Criança sem visitas
- **WHEN** uma criança sem visitas é exportada em TXT
- **THEN** o arquivo tem duas linhas e os campos `Date`, `Weight` e `Height` da linha de dados são vazios

### Requirement: Formato dos arquivos TXT e CSV
O TXT SHALL usar tabulação e o CSV ponto e vírgula como separador, ambos em UTF-8 com BOM e linhas terminadas em CRLF; um valor SHALL ir entre aspas, com aspas internas duplicadas, só quando contiver aspas, CR, LF ou o próprio separador, como `Delimited.WriteItem`.

#### Scenario: Valor com o separador no CSV
- **WHEN** a observação da criança é `pesada; sem sapatos` e a exportação é CSV
- **THEN** o campo é escrito como `"pesada; sem sapatos"` e o arquivo começa com os bytes `EF BB BF`

#### Scenario: Valor com aspas e separador ausente
- **WHEN** a observação é `disse "não"` e a exportação é TXT
- **THEN** o campo é escrito como `"disse ""não"""`, e a observação `pesada; sem sapatos` no TXT é escrita sem aspas

### Requirement: Codificação de valores exportados
O sistema SHALL escrever datas como `dd-MM-yyyy HH:mm:ss` com hora `00:00:00`, booleanos como `1`/`0`, sexo como `1` para menino e `0` para menina, medida deitada como `1` e em pé como `0`, valor ausente como vazio e decimais sem zeros à direita, com vírgula nos arquivos delimitados e ponto no XML.

#### Scenario: Data, sexo e medida
- **WHEN** uma menina nascida em 2016-03-15 tem visita medida em pé sem edema
- **THEN** `DateOfBirth` é `15-03-2016 00:00:00`, `Sex` é `0`, `IsRecumbent` é `0` e `HasOedema` é `0`

#### Scenario: Decimal em CSV e em XML
- **WHEN** o peso da visita é 16.50 kg
- **THEN** o CSV traz `16,5` e o XML traz `Weight="16.5"`

#### Scenario: Altura da mãe ausente
- **WHEN** a mãe existe mas não tem altura registrada
- **THEN** o campo `MotherHeight` é vazio

### Requirement: Resultados incluídos na exportação
Com resultados incluídos, o sistema SHALL escrever WAZ, HAZ e BAZ calculados por `AnthroEngine` com 2 casas e BMI como em `Visit.GetBMI`: com peso, medida e sem edema, IMC da medida ajustada por `Anthropometry.adjustedLengthOrHeight` em qualquer idade, arredondado a 1 casa; z indefinido SHALL ficar vazio.

#### Scenario: IMC exportado usa a medida ajustada
- **WHEN** uma visita aos 2000 dias registra 20 kg e 110 cm medidos deitado
- **THEN** a coluna `BMI` traz `16,7` (110 - 0.7 cm), e não `16,5`

#### Scenario: Resultados com edema
- **WHEN** a visita tem edema
- **THEN** as colunas `WAZ`, `BAZ` e `BMI` são vazias e `HAZ` não é vazia

### Requirement: Colunas de dados adicionais na exportação
O sistema SHALL acrescentar as colunas de `AdditionalDataColumns.structure` (change `add-additional-data`) sobre o modelo de dados adicionais da Avaliação individual, passando como chaves proibidas os nomes das colunas fixas e de resultado escritos no arquivo, como `Child.ExportChildrenToDelimitedFile` faz com `GetDataStructure`.

#### Scenario: Colisões de nome com colunas fixas
- **WHEN** o modelo de dados adicionais tem a variável `Sport` em duas seções e uma variável `Weight`, e a exportação TXT inclui resultados
- **THEN** os três últimos campos do cabeçalho são `Sport`, `Sport 2` e `Weight 2`, nessa ordem

#### Scenario: Visita sem dados adicionais
- **WHEN** uma visita não tem valores de dados adicionais
- **THEN** as colunas de dados adicionais dessa linha são vazias

### Requirement: Esquema XML de exportação de crianças
O XML SHALL ter raiz `Children` e um elemento `Child` por criança com os atributos de `Child.ExportChildrenToXML`, elementos `Mother`, `Father` e `Address` só quando existirem e `Visits` com um `Visit` por visita só quando houver visitas; `Visit` SHALL sempre trazer o atributo `AdditionalData`, com `<Data />` quando não houver dados.

#### Scenario: Criança completa com uma visita
- **WHEN** uma criança com mãe, endereço e uma visita é exportada em XML com resultados
- **THEN** o documento tem `/Children/Child/Mother`, `/Children/Child/Address`, `/Children/Child/Visits/Visit` com os atributos `Date`, `Weight`, `Height`, `IsRecumbent`, `HasOedema`, `Notes`, `AdditionalData`, `CreatedBy`, `WAZ`, `HAZ`, `BAZ` e `BMI`, e não tem `Father`

#### Scenario: Criança sem visitas no XML
- **WHEN** uma criança sem visitas e sem pais é exportada em XML
- **THEN** o elemento `Child` não tem filhos

#### Scenario: Visita sem dados adicionais no XML
- **WHEN** a visita exportada não tem dados adicionais
- **THEN** o atributo `AdditionalData` existe com o valor `<Data />`

### Requirement: Leitura de valores na importação
O sistema SHALL ler booleanos (`1`, `y`, `true`, `yes` / `0`, `n`, `false`, `no`), sexo (`1`, `m`, `male`, `true` menino / `0`, `2`, `f`, `female`, `false` menina) e medida (`1`, `l`, `true` deitado / `0`, `h`, `false` em pé) sem diferenciar maiúsculas, e decimais com vírgula ou ponto, como `ImportExport.ParseField`.

#### Scenario: Variações de sexo aceitas
- **WHEN** o atributo `Sex` vale `F`, `2` e `Male` em três crianças
- **THEN** as crianças importadas são menina, menina e menino

#### Scenario: Sexo não reconhecido
- **WHEN** o atributo `Sex` vale `x`
- **THEN** a importação falha com `ImportFailure.invalidStructure` e nenhuma criança é gravada

#### Scenario: Decimal com vírgula
- **WHEN** o atributo `Weight` da visita vale `16,5`
- **THEN** o peso importado é 16.5

### Requirement: Leitura de datas na importação
O sistema SHALL ler datas no formato `dd-MM-yyyy HH:mm:ss` e, se falhar, em `dd/MM/yyyy`, `dd/MM/yyyy HH:mm:ss`, `yyyy-MM-dd`, `yyyy-MM-ddTHH:mm:ss`, `dd-MM-yyyy` e nos 8 primeiros caracteres como `yyyyMMdd`, descartando a hora.

#### Scenario: Formatos de data aceitos
- **WHEN** as datas de nascimento são `15-03-2016 10:20:00`, `15/03/2016` e `20160315`
- **THEN** as três crianças têm data de nascimento 2016-03-15

#### Scenario: Data ilegível
- **WHEN** a data de nascimento é `março de 2016`
- **THEN** a importação falha com `ImportFailure.invalidStructure`

### Requirement: Truncamento de textos e medidas importados
O sistema SHALL cortar textos no limite de `Child.ImportChildrenFromXML` (nomes 50, observações 250, CEP 15, telefone 20, demais campos de endereço 50) e truncar decimais para 2 casas em direção a zero, como `AnthroComputation.SymetricCrop`, antes de validar limites.

#### Scenario: Nome longo e peso com três casas
- **WHEN** o nome tem 60 caracteres e o peso da visita é `16.789`
- **THEN** o nome importado tem os 50 primeiros caracteres e o peso importado é 16.78

#### Scenario: Truncamento leva o peso abaixo do mínimo
- **WHEN** o peso da visita é `0.899`
- **THEN** a importação falha com `ImportFailure.invalidStructure`, porque 0.89 é menor que 0.9

### Requirement: Validação de campos obrigatórios e limites
A importação SHALL rejeitar o arquivo inteiro, sem gravar nada, quando faltar ou for inválido um atributo obrigatório (`DateOfBirth`, `DateOfBirthIsApprox` e `Sex` da criança; `Date`, `IsRecumbent`, `HasOedema` e `CreatedBy` da visita), quando o peso sair de [0.9, 275], a medida de [38, 230] ou a visita for anterior ao nascimento.

#### Scenario: Peso acima do limite
- **WHEN** um arquivo com duas crianças tem uma visita com `Weight="300"`
- **THEN** a importação falha com `ImportFailure.invalidStructure` e o número de crianças no banco não muda

#### Scenario: Visita antes do nascimento
- **WHEN** a visita tem data 2016-03-14 e a criança nasceu em 2016-03-15
- **THEN** a importação falha com `ImportFailure.invalidStructure`

#### Scenario: Visita na data do nascimento
- **WHEN** a visita tem data 2016-03-15 e a criança nasceu em 2016-03-15
- **THEN** a importação é aceita

#### Scenario: Atributo opcional ausente
- **WHEN** o elemento `Child` não tem os atributos `Notes` e `DisplayID`
- **THEN** a importação é aceita, com observação e ID `nil`

### Requirement: Datas de visita estritamente crescentes
A importação SHALL rejeitar o arquivo inteiro com falha de valor inválido quando, para alguma criança, as visitas na ordem do documento não tiverem datas estritamente crescentes, como `Child.CheckImportedVisitDates`.

#### Scenario: Duas visitas na mesma data
- **WHEN** uma criança tem visitas em 2021-04-01 e 2021-04-01
- **THEN** a importação falha com `ImportFailure.invalidFieldValue([])` e nada é gravado

#### Scenario: Visitas fora de ordem
- **WHEN** uma criança tem visitas em 2021-10-01 e depois 2021-04-01 no documento
- **THEN** a importação falha com `ImportFailure.invalidFieldValue([])`

#### Scenario: Visitas em ordem crescente
- **WHEN** uma criança tem visitas em 2021-04-01 e 2021-10-01
- **THEN** a importação é aceita com duas visitas

### Requirement: Dados adicionais na importação
O sistema SHALL decodificar o atributo `AdditionalData` da visita com `AdditionalDataXML.decode` (change `add-additional-data`) e SHALL rejeitar o arquivo inteiro quando a decodificação lançar erro, como o `new AdditionalData(xml)` dentro do `try` de `ImportChildrenFromXML`.

#### Scenario: Dados adicionais válidos
- **WHEN** a visita traz `AdditionalData` com `<Data><Cat ID="Food" Descr="" /></Data>`
- **THEN** a visita importada tem dados adicionais com uma seção de identificador `Food`

#### Scenario: Dados adicionais malformados
- **WHEN** a visita traz `AdditionalData` com `<Data><Cat>`
- **THEN** a importação falha com `ImportFailure.invalidStructure`

### Requirement: Gravação da importação
A importação aceita SHALL gravar mães, pais, endereços, crianças e visitas numa única transação, preservando o `DisplayID` lido do arquivo; falha de gravação SHALL desfazer tudo.

#### Scenario: Duas crianças importadas
- **WHEN** um arquivo válido com duas crianças de `DisplayID` 7 e 9, uma visita cada, é importado
- **THEN** o banco ganha duas crianças e duas visitas, e as crianças têm `displayID` 7 e 9

#### Scenario: Falha no meio da gravação
- **WHEN** a gravação da segunda criança falha
- **THEN** o banco não ganha nenhuma criança, nenhuma visita, nenhuma mãe e nenhum endereço

### Requirement: Campos do original sem destino no app
Na exportação, todo `CreatedBy` (criança, mãe, pai, endereço e visita) SHALL ser `ExchangeDefaults.createdBy` e os níveis SALB SHALL ser vazios; na importação, esses atributos SHALL ser lidos, com a obrigatoriedade do original para `CreatedBy` da visita, e descartados, porque o app não tem multiusuário nem listas SALB.

#### Scenario: CreatedBy e SALB na exportação
- **WHEN** uma criança com mãe, endereço e uma visita é exportada em CSV
- **THEN** os campos `ChildCreatedBy`, `MotherCreatedBy`, `AddressCreatedBy` e `CreatedBy` são `AnthroPlus` e `AddressSALBLevel1` e `AddressSALBLevel2` são vazios

#### Scenario: CreatedBy e SALB lidos e descartados
- **WHEN** um arquivo com `CreatedBy="obs1"` em todos os elementos e `SALBLevel1="123"` no endereço é lido e exportado de novo em XML
- **THEN** a leitura é aceita e o novo XML traz `CreatedBy="AnthroPlus"` em todos os elementos e `SALBLevel1=""`

### Requirement: Ida e volta pelo XML
Um conjunto de crianças exportado em XML e importado de volta SHALL produzir crianças, pais, endereços e visitas com os mesmos valores de campo; a visita sem dados adicionais volta com dados adicionais vazios, porque o atributo `AdditionalData` é sempre escrito.

#### Scenario: Exportar e reimportar
- **WHEN** três crianças com visitas, mãe, pai e endereço são exportadas em XML e o arquivo é lido por `ChildXML.read`
- **THEN** a lista lida é igual à lista exportada, campo a campo, ignorando os resultados calculados

#### Scenario: Arquivo no layout do original com vírgula decimal
- **WHEN** a fixture `ia-original-ptbr.xml`, montada no layout de `ExportChildrenToXML` com `Weight="16,5"`, é lida
- **THEN** a leitura é aceita e o peso da visita é 16.5

### Requirement: Exportação a partir da seleção
O modelo da tela SHALL habilitar a exportação só com ao menos uma criança marcada, SHALL exportar as crianças marcadas na ordem da lista e SHALL incluir resultados só quando `includeResults` for verdadeiro, que começa falso.

#### Scenario: Exportação só com criança marcada
- **WHEN** nenhuma criança está marcada e, em seguida, uma criança é marcada
- **THEN** `canExport` é falso no primeiro momento, verdadeiro no segundo, e `includeResults` começa falso

#### Scenario: Duas crianças marcadas em CSV
- **WHEN** duas crianças sem visitas estão marcadas e a exportação CSV é gravada
- **THEN** o arquivo tem três linhas e o cabeçalho tem os 43 campos fixos seguidos das 7 colunas do modelo padrão de dados adicionais

### Requirement: Mensagens de falha de importação
O modelo SHALL traduzir cada falha para a mensagem pt-BR equivalente a `Utils.DisplayImportError`, com o nome do arquivo, e SHALL acrescentar o detalhe de linha, elemento e atributo quando a leitura o informar.

#### Scenario: Mensagem de formato inválido
- **WHEN** a importação de `criancas.xml` falha por peso acima do limite na linha 7
- **THEN** a mensagem começa com `Não foi possível importar o arquivo 'criancas.xml': o formato do arquivo é inválido.` e contém `linha 7`, `Visit` e `Weight`

#### Scenario: Mensagem de valor inválido
- **WHEN** a importação de `criancas.xml` falha por datas de visita fora de ordem
- **THEN** a mensagem é `Não foi possível importar o arquivo 'criancas.xml': um ou mais campos obrigatórios contêm valores inválidos.`
