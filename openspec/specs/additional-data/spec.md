# additional-data Specification

## Purpose
Dados adicionais, portados de `AdditionalData`, `Section`, `Text`, `Num` e `Date`, de `AdditionalDataDialog` e de `Utils.CreateAddDataControls`: estrutura de seções e variáveis de texto, número e data, XML compatível com o original, modelo padrão da avaliação individual guardado no banco e copiado para cada visita nova, definição por inquérito copiada para cada registro novo, editor de definição, entrada de valores com validação e colunas na tabela do inquérito com formato, ordenação, filtro e cópia.

## Requirements

### Requirement: Leitura do XML de dados adicionais
O sistema SHALL ler o XML do original em seções `Cat` com variáveis `Txt`, `Num` e `Date`, cada uma com atributos `ID` e `Descr`, e `Num` com `Min` e `Max`; texto vazio, número ou data inválidos SHALL virar `nil` e elementos desconhecidos SHALL ser ignorados, como o construtor `AdditionalData(string xml)`.

#### Scenario: Modelo padrão do original
- **WHEN** o sistema lê o XML do modelo padrão de `IAAdditionalDataTemplate`
- **THEN** há 4 seções, a segunda é "Physical activity" com descrição "hours per week" e 2 variáveis numéricas de mínimo 0 e máximo 140, e "Fruit&veg portions / day" tem máximo 10

#### Scenario: Valores inválidos e elemento desconhecido
- **WHEN** o sistema lê `<Data><Cat ID="A" Descr=""><Num Min="" Max="" ID="n" Descr="">abc</Num><Date ID="d" Descr="">31/02/2020</Date><Bool ID="b" Descr="" /></Cat></Data>`
- **THEN** a seção "A" tem 2 variáveis, o número e a data têm valor `nil` e mínimo e máximo do número são `nil`

### Requirement: XML inválido de dados adicionais
O sistema SHALL lançar erro tipado para XML malformado ou com atributo obrigatório ausente (`ID` ou `Descr` em seção e variável, `Min` ou `Max` em número), e SHALL tratar texto `nil` ou vazio como dados sem seções.

#### Scenario: Atributo obrigatório ausente
- **WHEN** o sistema lê `<Data><Cat ID="A"><Txt ID="t" Descr=""></Txt></Cat></Data>`
- **THEN** a leitura lança `AdditionalDataXMLError.invalid`

#### Scenario: Texto ausente
- **WHEN** o sistema lê `nil` e depois ""
- **THEN** os dois resultados são dados sem seções, que gravados de novo dão `<Data />`

### Requirement: Escrita do XML compatível com o original
O sistema SHALL gravar o XML exatamente como `AdditionalData.GetXML`: sem declaração nem espaços, `Num` com atributos na ordem `Min`, `Max`, `ID`, `Descr`, texto e variável sem valor como elemento aberto e fechado para `Txt` e vazio autofechado para `Num` e `Date`, descrição `nil` como "". Caracteres fora da produção `Char` do XML 1.0, que tornariam o texto ilegível também para o original, SHALL ser omitidos, com U+000B e U+000C gravados como espaço.

#### Scenario: Ida e volta do modelo padrão
- **WHEN** o sistema lê e grava de novo o XML do modelo padrão
- **THEN** o texto gravado é idêntico ao valor de `IAAdditionalDataTemplate` do `.exe.config` original

#### Scenario: Dados sem seções e seção sem variáveis
- **WHEN** o sistema grava dados sem seções e dados com uma seção "A" sem variáveis
- **THEN** os textos são `<Data />` e `<Data><Cat ID="A" Descr="" /></Data>`

### Requirement: Valores numéricos e datas no XML
O sistema SHALL gravar números com ponto decimal e datas no formato `dd-MM-yyyy HH:mm:ss` com hora 00:00:00, e SHALL ler números com vírgula ou ponto.

#### Scenario: Número e data gravados
- **WHEN** uma variável numérica tem valor 1.5 e uma de data tem 2016-03-15
- **THEN** o XML contém `ID="n" Descr="">1.5</Num>` e `<Date ID="d" Descr="">15-03-2016 00:00:00</Date>`

#### Scenario: Número com vírgula na leitura
- **WHEN** o sistema lê `<Num Min="0,5" Max="" ID="n" Descr="">2,25</Num>` dentro de uma seção
- **THEN** o valor é 2.25 e o mínimo é 0.5

### Requirement: Modelo padrão da avaliação individual no banco
A migração 4 SHALL criar o armazenamento do modelo de dados adicionais da avaliação individual já preenchido com o XML de `IAAdditionalDataTemplate`, e o modelo editado SHALL persistir entre aberturas do app.

#### Scenario: Banco novo
- **WHEN** o banco é aberto pela primeira vez com `Migrations.all`
- **THEN** `schemaVersion()` é pelo menos 4 e o modelo da avaliação individual tem as seções Maturation, Physical activity, Food e Health

#### Scenario: Modelo editado persiste
- **WHEN** a usuária acrescenta a seção "Escola" ao modelo, o banco é fechado e reaberto
- **THEN** o modelo relido tem 5 seções e a última é "Escola"

### Requirement: Visita nova recebe cópia do modelo atual
Uma visita nova SHALL receber uma cópia do modelo da avaliação individual vigente no momento da criação, como `IAVisitDialog`; visitas já gravadas SHALL manter sua própria estrutura quando o modelo mudar.

#### Scenario: Visita nova depois de editar o modelo
- **WHEN** a usuária acrescenta a seção "Escola" ao modelo e cria uma visita
- **THEN** os dados adicionais da visita nova têm 5 seções, a última "Escola"

#### Scenario: Visita antiga não muda com o modelo
- **WHEN** uma visita foi gravada com o modelo padrão e depois a usuária remove a seção Health do modelo
- **THEN** a visita relida pelo `VisitRepository` ainda tem a seção Health

### Requirement: Definição de dados adicionais do inquérito
Cada inquérito SHALL ter sua própria definição, vazia ao ser criado, editável no inquérito aberto; aplicar a definição SHALL marcar o inquérito com alterações pendentes, e registros já existentes SHALL manter seus próprios dados.

#### Scenario: Definição aplicada e salva
- **WHEN** a usuária abre a definição de um inquérito novo, acrescenta a seção "Escola" com a variável de texto "Série", aplica e salva
- **THEN** o inquérito relido tem definição com a seção "Escola" e `hasUnsavedChanges` ficou verdadeiro entre aplicar e salvar

#### Scenario: Registro antigo mantém seus dados
- **WHEN** um registro tem o valor "3º ano" em "Escola/Série" e a usuária troca a variável "Série" por "Turma" na definição
- **THEN** o XML do registro continua com "Série" igual a "3º ano"

### Requirement: Incluir seções e variáveis no editor
O editor SHALL incluir seção com identificador vazio ao fim da lista e selecioná-la; incluir variável SHALL criar texto vazio ao fim da seção selecionada ou da seção da variável selecionada, e SHALL ficar indisponível sem seleção.

#### Scenario: Variável incluída a partir de variável selecionada
- **WHEN** a seção "A" tem a variável "x" selecionada e a usuária inclui uma variável
- **THEN** a seção "A" tem 2 variáveis, a nova é de texto com identificador vazio e está selecionada

#### Scenario: Incluir variável sem seleção
- **WHEN** o editor tem a seção "A", nada está selecionado e depois a seção "A" é selecionada
- **THEN** sem seleção `canAddVariable` é falso e `addVariable()` não altera a definição, e com a seção selecionada `canAddVariable` é verdadeiro

### Requirement: Identificador obrigatório
O editor SHALL remover espaços das pontas do identificador e SHALL lançar erro ao aplicar se alguma seção ou variável tiver identificador vazio, como `AdditionalDataDialog_MsgInvalidID`; descrição vazia SHALL virar `nil`.

#### Scenario: Identificador aparado
- **WHEN** a usuária digita "  Escola  " como identificador de uma seção e "  " como descrição e aplica
- **THEN** a definição aplicada tem a seção "Escola" com descrição `nil`

#### Scenario: Seção sem identificador
- **WHEN** a usuária inclui uma seção e aplica sem preencher o identificador
- **THEN** a aplicação lança `AdditionalDataEditorError.emptyIdentifier`

### Requirement: Identificadores repetidos rejeitados
O editor SHALL rejeitar ao aplicar duas seções com o mesmo identificador ou duas variáveis com o mesmo identificador na mesma seção, porque a busca do original devolve só a primeira; identificadores iguais em seções diferentes SHALL ser aceitos.

#### Scenario: Variáveis repetidas na mesma seção
- **WHEN** a seção "A" tem duas variáveis "x" e a usuária aplica
- **THEN** a aplicação lança `AdditionalDataEditorError.duplicateIdentifier(section: "A", variable: "x")`

#### Scenario: Mesmo identificador em seções diferentes
- **WHEN** as seções "A" e "B" têm cada uma a variável "x" e a usuária aplica
- **THEN** a definição é aplicada com as duas variáveis

### Requirement: Trocar o tipo da variável
Trocar o tipo SHALL substituir a variável na mesma posição, mantendo identificador e descrição e descartando valor, mínimo e máximo, como `rbType_CheckedChanged`.

#### Scenario: Número vira data
- **WHEN** a variável "n" é a segunda da seção, numérica com mínimo 0 e máximo 10, e a usuária troca para data
- **THEN** a segunda variável da seção é de data, com identificador "n" e valor `nil`

#### Scenario: Texto vira número sem limites
- **WHEN** a usuária troca uma variável de texto para número
- **THEN** a variável é numérica com mínimo e máximo `nil`

### Requirement: Mínimo e máximo coerentes
Ao editar o mínimo acima do máximo, o editor SHALL igualá-lo ao máximo; ao editar o máximo abaixo do mínimo, SHALL igualá-lo ao mínimo; limites vazios SHALL ser aceitos, como `nudMinValue_ValueChanged`.

#### Scenario: Mínimo acima do máximo
- **WHEN** a variável numérica tem máximo 10 e a usuária define o mínimo como 12
- **THEN** o mínimo passa a 10

#### Scenario: Máximo abaixo do mínimo e limite vazio
- **WHEN** a variável tem mínimo 5, a usuária define o máximo como 2 e depois apaga o mínimo
- **THEN** o máximo passa a 5 e o mínimo fica `nil`

### Requirement: Excluir e cancelar no editor
Excluir SHALL remover a seção selecionada com suas variáveis ou a variável selecionada; cancelar SHALL descartar todas as alterações, porque o editor trabalha sobre uma cópia, como o construtor de `AdditionalDataDialog`.

#### Scenario: Excluir seção
- **WHEN** a seção "Food" está selecionada no modelo padrão e a usuária exclui
- **THEN** a definição do editor tem 3 seções e nenhuma se chama "Food"

#### Scenario: Cancelar a edição
- **WHEN** a usuária exclui a seção "Food" no editor do modelo e cancela
- **THEN** o modelo da avaliação individual continua com 4 seções

### Requirement: Entrada de valores de texto e data
O formulário de valores SHALL listar as variáveis por seção na ordem da definição; texto SHALL ser guardado sem espaços nas pontas e vazio como `nil`, como `Utils.SaveAddDataFromControls`; data SHALL aceitar `nil`.

#### Scenario: Texto e data preenchidos
- **WHEN** a usuária digita " 3º ano " em "Série" e escolhe 2021-04-01 numa variável de data
- **THEN** os dados resultantes têm "3º ano" e 2021-04-01

#### Scenario: Texto apagado
- **WHEN** a usuária apaga o texto da variável "t", que tinha "abc"
- **THEN** o valor da variável "t" é `nil` e o XML tem `<Txt ID="t" Descr=""></Txt>`

### Requirement: Entrada de valores numéricos
O formulário SHALL avaliar cada número com `MeasurementInput.evaluate`, usando o mínimo e o máximo da variável (limite ausente como `decimal.MinValue` ou `decimal.MaxValue`, como `CreateAddDataControls`) e 2 casas; texto inválido ou fora do intervalo SHALL virar `nil`, com aviso no campo, e bloquear salvar; vazio SHALL ser aceito como `nil`.

#### Scenario: Número dentro dos limites
- **WHEN** a usuária digita "7,5" em "Sport" (mínimo 0, máximo 140)
- **THEN** o valor é 7.5, o texto exibido é "7,50" e `canSave` é verdadeiro

#### Scenario: Número fora dos limites e texto inválido
- **WHEN** a usuária digita "141" em "Sport" e "dez" em "TV/computer"
- **THEN** a avaliação de "Sport" é `.outOfRange(0...140)`, a de "TV/computer" é `.invalid`, os dois valores são `nil`, `canSave` é falso e `result()` lança `AdditionalDataValueError` com `.outOfRange(section: "Physical activity", variable: "Sport")` e `.invalid(section: "Physical activity", variable: "TV/computer")`

#### Scenario: Registro bloqueado por dado adicional inválido
- **WHEN** o inquérito usa o modelo padrão como definição e, no editor de um registro novo sem outros erros, a usuária digita "141" em "Sport"
- **THEN** `RecordEditorModel.canSave` é falso, e depois de apagar o texto de "Sport" volta a ser verdadeiro

### Requirement: Rótulos em pt-BR do modelo padrão
A interface SHALL exibir em pt-BR os identificadores e a descrição do modelo padrão (ex.: "Maturation" como "Maturação", "hours per week" como "horas por semana"), e o XML SHALL manter os identificadores originais; identificadores criados pela usuária SHALL aparecer como digitados.

#### Scenario: Rótulos traduzidos
- **WHEN** o formulário de valores é montado a partir do modelo padrão
- **THEN** os títulos das seções são "Maturação", "Atividade física", "Alimentação" e "Saúde", e a variável "Fruit&veg portions / day" aparece como "Porções de frutas e hortaliças por dia"

#### Scenario: Identificador da usuária
- **WHEN** a usuária cria a seção "Escola"
- **THEN** o título exibido é "Escola" e o XML gravado contém `ID="Escola"`

### Requirement: Registro novo usa a definição do inquérito
O formulário de um registro novo SHALL ser montado a partir da definição do inquérito, e o de um registro existente, a partir dos dados do próprio registro; salvar o registro SHALL gravar o XML dos valores.

#### Scenario: Registro novo com definição
- **WHEN** o inquérito tem a seção "Escola" com a variável de texto "Série" e a usuária cria um registro digitando "3º ano"
- **THEN** o XML do registro gravado é `<Data><Cat ID="Escola" Descr=""><Txt ID="Série" Descr="">3º ano</Txt></Cat></Data>`

#### Scenario: Registro existente com estrutura antiga
- **WHEN** um registro tem a variável "Série" e a definição atual só tem "Turma"
- **THEN** o formulário do registro mostra "Série", não "Turma"

### Requirement: Colunas de dados adicionais na tabela do inquérito
A tabela SHALL acrescentar, após as 19 colunas fixas, uma coluna por variável da definição na ordem das seções, com chave igual ao identificador; chave repetida ou igual a um título fixo SHALL receber o sufixo " 2", " 3" e assim por diante, como `GetDataStructure`.

#### Scenario: Colunas do modelo padrão
- **WHEN** a definição do inquérito é o modelo padrão
- **THEN** a tabela tem 26 colunas e as chaves acrescentadas são, em ordem, Menarche/spermarche, Self-reported, Sport, TV/computer, Fruit&veg portions / day, Blood pressure, Blood lipids

#### Scenario: Chaves repetidas
- **WHEN** a definição tem a variável "x" nas seções "A" e "B" e uma variável "Sexo" na seção "C"
- **THEN** as chaves são "x", "x 2" e "Sexo 2"

### Requirement: Células de dados adicionais
A célula SHALL mostrar o valor da variável do registro com a mesma seção e identificador: texto como está, data dd/MM/aaaa e número com vírgula sem casas fixas; variável ausente no registro ou sem valor SHALL ficar vazia.

#### Scenario: Valores formatados
- **WHEN** um registro tem "Série" igual a "3º ano", "Peso ao nascer" igual a 3.25 e "Data da escola" igual a 2021-02-01
- **THEN** as células são "3º ano", "3,25" e "01/02/2021"

#### Scenario: Variável ausente no registro
- **WHEN** a definição tem "Série" e "Turma" na seção "Escola" e o registro só tem "Série" igual a "3º ano"
- **THEN** a célula de "Turma" é texto vazio e a de "Série" é "3º ano"

### Requirement: Ordenação, filtro e cópia com colunas adicionais
As colunas adicionais SHALL ser ordenáveis (número pelo valor, texto pela comparação de texto, data em ordem cronológica, ausentes no fim), filtráveis pelas mesmas regras das colunas fixas e incluídas na cópia para a área de transferência.

#### Scenario: Ordenação de data em ordem cronológica
- **WHEN** as datas visíveis numa coluna adicional são 01/02/2021, 15/01/2021 e ausente, e a usuária clica no cabeçalho
- **THEN** a ordem é 15/01/2021, 01/02/2021 e ausente, e não a ordem do texto

#### Scenario: Filtro e cópia com coluna adicional
- **WHEN** a definição tem só a variável numérica "Recreio", com valores 2, 7 e 10 nos registros, e a usuária filtra "Recreio" maior ou igual a "7" e copia as linhas visíveis
- **THEN** ficam visíveis 2 registros e a linha de cabeçalhos copiada termina em "Recreio\t\r\n"

### Requirement: Migração 4 do banco
A migração 4 SHALL criar a tabela `additional_data_templates`, com escopo como chave e XML obrigatório, e SHALL gravar nela o modelo padrão da avaliação individual.

#### Scenario: Tabela criada e preenchida
- **WHEN** o banco migra da versão 3 para a 4
- **THEN** existe uma linha com escopo "individualAssessment" cujo XML é o de `IAAdditionalDataTemplate`

#### Scenario: XML obrigatório
- **WHEN** um INSERT direto grava um escopo com XML NULL
- **THEN** o banco lança `StoreError.sqlite` de restrição NOT NULL
