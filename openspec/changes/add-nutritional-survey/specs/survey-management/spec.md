# Spec Delta

## ADDED Requirements

### Requirement: Nome obrigatório do inquérito
O sistema SHALL exigir nome não vazio, após remover espaços das pontas, para salvar um inquérito, como `NSMain.SaveCurrentSurvey`, e SHALL guardar notas vazias como `nil`.

#### Scenario: Inquérito novo salvo com nome e notas vazias
- **WHEN** a usuária cria um inquérito com nome " Escola A 2026 " e notas "   " e salva
- **THEN** o banco tem um inquérito com nome "Escola A 2026" e notas `nil`

#### Scenario: Nome só com espaços
- **WHEN** a usuária tenta salvar um inquérito com nome "   "
- **THEN** o salvamento lança `SurveyStoreError.nameRequired` e a tabela `surveys` continua sem linhas

### Requirement: Lista de inquéritos ativos
O sistema SHALL listar os inquéritos não arquivados em ordem de nome e, no empate, de identificador, como `Surveys.GetList`.

#### Scenario: Ordem da lista
- **WHEN** existem os inquéritos ativos "Escola B" (id 1), "Escola A" (id 2) e "Escola A" (id 3)
- **THEN** a lista ativa é, nesta ordem, id 2, id 3, id 1

#### Scenario: Ações dependem da marcação
- **WHEN** há 2 inquéritos ativos, a usuária marca um e depois o desmarca
- **THEN** com a marcação arquivar e excluir ficam disponíveis, e sem marcação ficam indisponíveis

### Requirement: Arquivar e restaurar inquéritos
O sistema SHALL mover os inquéritos marcados para o arquivo e de volta, alternando entre a lista ativa e a do arquivo; arquivar o inquérito aberto SHALL fechá-lo, como `tsbSurveyArchive_Click`.

#### Scenario: Arquivar e restaurar
- **WHEN** a usuária marca "Escola A" na lista ativa, arquiva, abre o arquivo, marca "Escola A" e restaura
- **THEN** depois de arquivar "Escola A" só aparece no arquivo, e depois de restaurar volta à lista ativa com `isArchived` falso no banco

#### Scenario: Arquivar o inquérito aberto
- **WHEN** "Escola A" está aberto e a usuária o marca e arquiva
- **THEN** nenhum inquérito fica aberto no detalhe

### Requirement: Excluir inquéritos com seus registros
O sistema SHALL excluir os inquéritos marcados junto com todos os seus registros, e excluir o inquérito aberto SHALL fechá-lo, como `Surveys.Delete`.

#### Scenario: Exclusão em cascata
- **WHEN** a usuária exclui "Escola A", que tem 3 registros salvos
- **THEN** o banco não tem "Escola A" e a tabela `records` não tem linhas com o identificador dele

#### Scenario: Exclusão do inquérito aberto
- **WHEN** "Escola A" está aberto e é excluído
- **THEN** nenhum inquérito fica aberto no detalhe

### Requirement: Edição transacional do inquérito aberto
Inclusões, edições e exclusões de registros, nome, notas e opções SHALL ficar pendentes até Salvar, que grava tudo numa única transação; Descartar SHALL restaurar o estado salvo.

#### Scenario: Descartar alterações
- **WHEN** um inquérito salvo com 2 registros recebe um terceiro registro e a usuária descarta
- **THEN** o inquérito volta a ter 2 registros e `hasUnsavedChanges` é falso

#### Scenario: Falha no meio do salvamento
- **WHEN** um inquérito novo com 2 registros é salvo e a tabela `records` foi removida do banco antes
- **THEN** o salvamento lança `StoreError.sqlite` e a tabela `surveys` continua sem linhas

### Requirement: Aviso de alterações não salvas
Ao abrir outro inquérito, criar um novo ou fechar o módulo com alterações pendentes, o sistema SHALL pedir uma decisão entre salvar, descartar e cancelar, como `NSMain.AskForSave`.

#### Scenario: Salvar antes de abrir outro inquérito
- **WHEN** "Escola A" tem alterações pendentes, a usuária pede para abrir "Escola B" e escolhe salvar
- **THEN** as alterações de "Escola A" estão no banco e "Escola B" fica aberto

#### Scenario: Cancelar a troca
- **WHEN** "Escola A" tem alterações pendentes, a usuária pede para abrir "Escola B" e escolhe cancelar
- **THEN** "Escola A" continua aberto com `hasUnsavedChanges` verdadeiro

### Requirement: Valores padrão de um registro novo
O editor de um registro novo SHALL começar com fator de peso 1, sexo feminino, data de nascimento um ano antes de hoje, medida em pé, sem edema e sem data da pesquisa, como o construtor de `NSRecordDialog`.

#### Scenario: Registro novo
- **WHEN** a usuária abre o editor de registro novo com hoje igual a 2026-10-14
- **THEN** o fator de peso é 1, o sexo é `.girl`, o nascimento é 2025-10-14, a medida é em pé, o edema é falso e a data da pesquisa é `nil`

#### Scenario: Registro existente de menino
- **WHEN** a usuária abre o editor de um registro salvo de menino
- **THEN** o sexo do editor é `.boy` e o fator de peso é o gravado

### Requirement: Campos numéricos do registro
O editor SHALL avaliar cada campo numérico com `MeasurementInput.evaluate`: peso 0.9 a 275, medida 38 a 230 e idade 0 a 2400 com 2 casas; IDs, conglomerado, equipe e domicílio 0 a 2147483647 sem casas; fator de peso a partir de 0 com 16 casas. Texto inválido ou fora do intervalo SHALL virar `nil` para o cálculo, com aviso no campo, e bloquear salvar; vazio SHALL ser aceito, exceto no fator de peso.

#### Scenario: Valores nos limites aceitos e truncados
- **WHEN** o editor recebe peso "20,129", medida "230" e idade "2400"
- **THEN** `canSave` é verdadeiro e `makeRecord()` devolve peso 20.12, medida 230 e idade 2400

#### Scenario: Valores fora dos limites bloqueiam salvar
- **WHEN** o editor recebe peso "300", medida "37,99" e fator de peso "-0,1"
- **THEN** o resultado da avaliação do peso é `.outOfRange(0.9...275)`, o peso para cálculo é `nil`, os três campos têm aviso, `canSave` é falso e `makeRecord()` lança `RecordValidationError` com `.outOfRange(.weight)`, `.outOfRange(.lengthOrHeight)` e `.outOfRange(.weightingFactor)`

#### Scenario: Texto inválido bloqueia e vazio é aceito
- **WHEN** o editor recebe peso "abc" e medida vazia, e depois o peso é apagado
- **THEN** com "abc" a avaliação do peso é `.invalid` e `canSave` é falso; depois de apagado, `canSave` é verdadeiro e o registro tem peso e medida `nil`

#### Scenario: Fator de peso vazio
- **WHEN** o editor recebe fator de peso vazio
- **THEN** `canSave` é falso e `makeRecord()` lança `RecordValidationError` com `.required(.weightingFactor)`

### Requirement: Idade exibida no editor de registro
O editor SHALL exibir a idade com `AgeText.localized(months:)` sobre a parte inteira dos meses, calculada das datas ou digitada, e "Idade: N/D" quando a idade for desconhecida, como `NSRecordDialog.RefreshAge`.

#### Scenario: Idade derivada das datas exibida
- **WHEN** o editor tem nascimento 2016-03-15 e data da pesquisa 2021-04-01
- **THEN** o texto de idade é igual a `AgeText.localized(months: 60)`

#### Scenario: Idade desconhecida
- **WHEN** o editor tem nascimento desconhecido e nenhuma idade digitada
- **THEN** o texto de idade é "Idade: N/D"

### Requirement: Idade em meses quando o nascimento é desconhecido
Com nascimento marcado como desconhecido ou sem data da pesquisa, o editor SHALL aceitar a idade em meses e o cálculo SHALL usá-la; com as duas datas presentes, a idade digitada SHALL ser descartada, como o setter de `Record.Age`.

#### Scenario: Nascimento desconhecido com idade digitada
- **WHEN** um registro tem nascimento desconhecido, idade 61.5 meses, sexo masculino e medida 110 cm
- **THEN** o resultado tem idade em dias 1872 e faixa `.reference`

#### Scenario: Duas datas presentes e idade digitada
- **WHEN** o editor tem nascimento 2016-03-15, data da pesquisa 2021-04-01 e idade digitada 30
- **THEN** o registro gerado tem idade em meses `nil` e o cálculo usa 1843 dias

### Requirement: Data de nascimento aproximada
Marcar a data de nascimento como aproximada SHALL sortear o dia entre 1 e o penúltimo dia do mês com `ApproximateBirthDate.randomized`, como `Random.Next(1, DaysInMonth)`; nascimento posterior à data da pesquisa SHALL ser trocado pela data da pesquisa com `ApproximateBirthDate.adjusted`.

#### Scenario: Sorteio no limite superior
- **WHEN** o nascimento é 2016-02-10, a data é marcada como aproximada e o sorteio devolve o maior valor permitido
- **THEN** o nascimento passa a 2016-02-28

#### Scenario: Nascimento depois da data da pesquisa
- **WHEN** a data da pesquisa é 2021-04-01 e a usuária informa nascimento 2021-05-10
- **THEN** o nascimento do editor passa a 2021-04-01

### Requirement: Escolha entre deitado e em pé
O editor SHALL habilitar a escolha entre deitado e em pé só quando a idade é desconhecida ou sua parte inteira em meses é menor que 11; nos demais casos SHALL forçar em pé, como `NSRecordDialog.RefreshAge`, mesmo que a ajuda cite 0 a 60 meses.

#### Scenario: Idade abaixo de 11 meses
- **WHEN** o nascimento é 2020-01-01 e a data da pesquisa é 2020-11-30
- **THEN** a escolha entre deitado e em pé está habilitada

#### Scenario: Idade de 11 meses
- **WHEN** o nascimento é 2020-01-01, a data da pesquisa é 2020-12-01 e o editor estava em deitado
- **THEN** a escolha está desabilitada e a medida passa a em pé

### Requirement: IMC exibido no editor de registro
O editor SHALL exibir o IMC arredondado a 1 casa quando houver peso, medida e ausência de edema, ajustando a medida pela idade em dias (das datas ou de meses convertidos) e usando a medida bruta sem idade; nos demais casos SHALL exibir "N/D".

#### Scenario: IMC com idade digitada
- **WHEN** o editor tem peso 20 kg, medida 110 cm, em pé, nascimento desconhecido e idade 72 meses
- **THEN** o IMC exibido é "16,5"

#### Scenario: IMC com edema
- **WHEN** o mesmo editor marca edema
- **THEN** o IMC exibido é "N/D"

### Requirement: Atribuição automática de IDs
Ao salvar um registro com o campo vazio e a atribuição automática ligada nas opções, o sistema SHALL usar o maior valor existente no inquérito mais 1, separadamente para conglomerado, equipe, ID e domicílio, considerando todos os registros, inclusive os ocultos por filtro.

#### Scenario: Próximo ID
- **WHEN** o inquérito tem registros com ID 3 e 7, a atribuição de ID está ligada e um registro novo é salvo sem ID
- **THEN** o registro novo recebe ID 8

#### Scenario: Inquérito sem domicílios
- **WHEN** a atribuição de domicílio está ligada, nenhum registro tem domicílio e um registro novo é salvo sem domicílio
- **THEN** o registro novo recebe domicílio 1

#### Scenario: Filtro ativo não reduz o próximo ID
- **WHEN** o inquérito tem registros com ID 3 e 7, o de ID 7 está oculto por filtro e um registro novo é salvo sem ID
- **THEN** o registro novo recebe ID 8

### Requirement: Campos sem atribuição automática
Com a atribuição automática desligada, o campo vazio SHALL continuar `nil`, e um valor digitado SHALL prevalecer mesmo com a atribuição ligada.

#### Scenario: Atribuição de conglomerado desligada
- **WHEN** a atribuição de conglomerado está desligada (padrão) e o registro é salvo sem conglomerado
- **THEN** o conglomerado do registro é `nil`

#### Scenario: Valor digitado com atribuição ligada
- **WHEN** a atribuição de ID está ligada, o maior ID é 7 e a usuária digita ID 2
- **THEN** o registro é salvo com ID 2

### Requirement: Resultado antropométrico do registro
O sistema SHALL calcular o resultado de cada registro com o `AnthroEngine`: pela idade em meses quando ela existir, senão pelas datas de nascimento e da pesquisa; edema `nil` SHALL contar como sem edema, como `Record.AnthroResult`.

#### Scenario: Estatura na mediana pela idade em meses
- **WHEN** um registro de menino tem idade 61 meses, sem datas, e medida 110.26 cm
- **THEN** o z-score de estatura para idade é 0.00

#### Scenario: Registro sem idade
- **WHEN** um registro de menina com peso 18 kg não tem idade em meses nem data da pesquisa
- **THEN** a faixa do resultado é `.unknown`, os três z-scores são `nil` e o peso do resultado é 18.00

### Requirement: Plausibilidade com os limites do inquérito
O sistema SHALL marcar o z de um registro como implausível quando for `nil` ou estiver fora dos limites mínimo e máximo das opções do inquérito para a faixa (padrões ou referência), e SHALL marcar todos os indicadores com faixa desconhecida ou fora dos limites, como `Record.IsFlagged`.

#### Scenario: Limite alterado nas opções
- **WHEN** um menino com nascimento igual à data da pesquisa pesa 5.64 kg (z de peso 4.00) e o limite máximo de peso dos padrões é 5 e depois 3.5
- **THEN** o z de peso não é implausível com 5 e é implausível com 3.5

#### Scenario: Faixa desconhecida
- **WHEN** um registro não tem idade
- **THEN** a flag resumida do registro é `.weightAndLengthOrHeightForAge`

### Requirement: Peso para idade acima de 108 meses nunca é implausível
Na faixa de referência, o sistema SHALL considerar plausível o peso para idade quando a parte inteira da idade em meses for maior que 108, mesmo com z `nil`, como `Record.IsFlagged`.

#### Scenario: 109 meses sem peso
- **WHEN** um registro de menino tem idade 109 meses, medida 130 cm e nenhum peso
- **THEN** o peso para idade não é implausível e o IMC para idade é implausível

#### Scenario: 108 meses sem peso
- **WHEN** um registro de menino tem idade 108 meses, medida 130 cm e nenhum peso
- **THEN** o peso para idade é implausível e a flag resumida é `.weightForAge`

### Requirement: Colunas da tabela de registros
A tabela SHALL mostrar, nesta ordem, data da pesquisa, conglomerado, equipe, ID, domicílio, sexo, nascimento, idade em dias, idade em meses, peso, edema, deitado, medida, z de peso, z de estatura, z de IMC, flag, fator de peso e nascimento estimado, como `dgvRecords_CellValueNeeded`.

#### Scenario: Linha completa
- **WHEN** um registro de menina tem data da pesquisa 2021-04-01, nascimento aproximado 2016-03-15, peso 18.5, medida 110, sem edema gravado e fator de peso 1
- **THEN** as células de data, nascimento, idade em dias, idade em meses, peso, edema, deitado, medida, fator e nascimento estimado são "01/04/2021", "XX/03/2016", "1843", "60,55", "18,50", "Não", "Não", "110,00", "1" e "Sim"

#### Scenario: Valores ausentes
- **WHEN** um registro de menina não tem data da pesquisa, conglomerado nem peso
- **THEN** as células de data, conglomerado, peso e z de peso são texto vazio e a de sexo é "Feminino"

### Requirement: Idade digitada versus idade calculada na tabela
Quando a idade em meses foi digitada, a coluna de dias SHALL mostrar `Round(meses * 30.4375, 0)` e as duas colunas de idade SHALL ser marcadas como digitadas; idade calculada das datas SHALL ser marcada como derivada.

#### Scenario: Idade digitada
- **WHEN** um registro tem idade digitada 61.5 meses
- **THEN** a idade em dias é "1872", a idade em meses é "61,50" e as duas células não são derivadas

#### Scenario: Idade derivada das datas
- **WHEN** um registro tem nascimento 2016-03-15 e data da pesquisa 2021-04-01
- **THEN** as células de idade são "1843" e "60,55" e ambas são derivadas

### Requirement: Destaque de z implausível e flag na tabela
Células de z implausível pelos limites do inquérito SHALL ser destacadas; a coluna de flag SHALL mostrar "P/I", "E/I", "E/I, P/I", "IMC/I" ou vazio, como `Utils.GetLocalizedFlagName`.

#### Scenario: z de estatura implausível
- **WHEN** um registro tem z de estatura 6.5 e z de peso 1.0 com limites padrão
- **THEN** só a célula de z de estatura está destacada e a flag é "E/I"

#### Scenario: z ausente sem destaque visível
- **WHEN** um registro de menina com nascimento 2016-01-01, data da pesquisa 2021-06-23 (2000 dias) e medida 110 cm não tem peso
- **THEN** a célula de z de peso é texto vazio, sem destaque, e a flag é "P/I"

### Requirement: Ordenação por coluna
Clicar no cabeçalho SHALL ordenar a lista visível em ordem crescente pelo valor tipado da coluna, com valores ausentes no fim, exceto nas colunas de z, em que z indefinido conta como o menor valor (o `decimal.MinValue` do original); clicar de novo na mesma coluna SHALL inverter a lista, e cada novo clique SHALL inverter outra vez.

#### Scenario: Três cliques no peso
- **WHEN** os pesos visíveis são 20, ausente e 15, e a usuária clica três vezes no cabeçalho de peso
- **THEN** a ordem após cada clique é (15, 20, ausente), (ausente, 20, 15) e (15, 20, ausente)

#### Scenario: z indefinido ordenado primeiro
- **WHEN** os z de peso visíveis são 1.00, indefinido e -0.50, e a usuária clica uma vez no cabeçalho de z de peso
- **THEN** a ordem é (indefinido, -0.50, 1.00)

#### Scenario: Troca de coluna recomeça em ordem crescente
- **WHEN** a lista está em ordem decrescente de peso e a usuária clica no cabeçalho de medida
- **THEN** a lista fica em ordem crescente de medida e o indicador de ordem do peso é removido

### Requirement: Filtro numérico
O filtro SHALL comparar numericamente quando o texto da célula e o valor informado forem números (vírgula ou ponto), com as condições igual, diferente, maior ou igual, menor ou igual e intervalo fechado.

#### Scenario: Maior ou igual em peso
- **WHEN** os pesos visíveis são 15, 20 e 25 e a usuária filtra peso maior ou igual a "20"
- **THEN** ficam visíveis os registros de 20 e 25 e o rótulo de contagem é "2 registro(s)"

#### Scenario: Intervalo numérico sem limite superior
- **WHEN** a usuária filtra peso no intervalo de "15" a vazio
- **THEN** nenhum registro com peso fica visível, porque o limite vazio leva à comparação por data, que falha

### Requirement: Filtro por texto
Quando a célula ou o valor não for número, igual e diferente SHALL comparar o texto da célula com o valor sem espaços nas pontas, sem diferenciar maiúsculas de minúsculas.

#### Scenario: Sexo sem diferenciar maiúsculas
- **WHEN** há duas meninas e um menino e a usuária filtra sexo igual a " feminino "
- **THEN** ficam visíveis as duas meninas

#### Scenario: Célula vazia igual a vazio
- **WHEN** a usuária filtra conglomerado igual a "" e só um registro não tem conglomerado
- **THEN** fica visível só o registro sem conglomerado

### Requirement: Filtro por data
Quando célula ou valor não for número, maior ou igual, menor ou igual e intervalo SHALL comparar datas dd/MM/aaaa; no intervalo, limite vazio SHALL ficar aberto; célula que não é data SHALL ser ocultada.

#### Scenario: Intervalo de datas com limite superior aberto
- **WHEN** as datas da pesquisa são 2020-12-31, 2021-01-01 e vazia, e a usuária filtra o intervalo de "01/01/2021" a ""
- **THEN** fica visível só o registro de 2021-01-01

#### Scenario: Comparação de data com valor inválido
- **WHEN** a usuária filtra data da pesquisa maior ou igual a "ontem"
- **THEN** nenhum registro fica visível

### Requirement: Filtro iterativo e limpeza
Cada filtro SHALL atuar sobre os registros já visíveis; limpar o filtro SHALL tornar todos visíveis de novo e remover os indicadores de ordenação, como `BaseDataList.FilterAt` e `UnfilterAll`.

#### Scenario: Dois filtros e limpeza
- **WHEN** há 2 meninas (pesos 15 e 22) e 1 menino (peso 25), a usuária filtra sexo igual a "feminino", depois peso maior ou igual a "20", e depois limpa
- **THEN** após o segundo filtro só a menina de 22 está visível, e após limpar os 3 registros estão visíveis com "3 registro(s)"

#### Scenario: Limpar sem filtro ativo
- **WHEN** não há filtro ativo e a usuária limpa o filtro
- **THEN** a lista visível não muda e `isFiltered` é falso

### Requirement: Cópia dos registros selecionados
A cópia SHALL gerar texto com a linha de cabeçalhos e as linhas selecionadas na ordem da tabela, cada célula seguida de tabulação e cada linha terminada em CRLF, como `tsbCopyToClipboard_Click`, e SHALL ser acionada por ⌘C.

#### Scenario: Duas linhas selecionadas
- **WHEN** a tabela tem 3 registros e a usuária seleciona as linhas 0 e 2 e copia
- **THEN** o texto tem 3 linhas terminadas em "\t\r\n", a primeira é a junção dos 19 títulos e a segunda começa pela data da pesquisa do registro 0

#### Scenario: Nenhuma linha selecionada
- **WHEN** a usuária copia sem seleção
- **THEN** o texto é só a linha de cabeçalhos terminada em "\t\r\n"

### Requirement: Seleção mostra o resultado do registro
Selecionar uma linha SHALL expor o resultado antropométrico do registro e a gravidade de cada z para o painel de resultados; sem seleção, o painel SHALL ficar vazio.

#### Scenario: Linha selecionada
- **WHEN** a usuária seleciona o registro com z de estatura 2.50
- **THEN** `selectedResult` é o resultado desse registro e a gravidade de estatura é `.high`

#### Scenario: Seleção removida
- **WHEN** o registro selecionado é excluído
- **THEN** `selectedResult` é `nil`

### Requirement: Opções padrão do inquérito
Um inquérito novo SHALL ter atribuição automática desligada para conglomerado e equipe e ligada para ID e domicílio, fronteiras etárias 0, 6, 12, 24, 36, 48, 61, 72, 84, ..., 216, 228, 228 e limites de z de padrões e referência de -6/5 (peso), -6/6 (estatura) e -5/5 (IMC).

#### Scenario: Opções de um inquérito novo
- **WHEN** a usuária cria um inquérito
- **THEN** as opções são iguais a `SurveyOptions.default`, com 22 fronteiras etárias e mínimo de IMC na referência -5

#### Scenario: XML sem chaves
- **WHEN** o sistema lê as opções do XML "<Opt />"
- **THEN** o resultado é igual a `SurveyOptions.default`

### Requirement: XML das opções compatível com o original
O sistema SHALL ler e gravar as opções no formato `<Opt><O ID="...">valor</O></Opt>` de `SurveyOptions.GetXML`, com booleanos True/False e listas separadas por "|", aceitando vírgula ou ponto decimal na leitura e gravando ponto.

#### Scenario: Gravação das opções padrão
- **WHEN** o sistema grava `SurveyOptions.default`
- **THEN** o XML é exatamente `<Opt><O ID="AutoIDCluster">False</O><O ID="AutoIDTeam">False</O><O ID="AutoIDRecord">True</O><O ID="AutoIDHousehold">True</O><O ID="AgeGroups">0|6|12|24|36|48|61|72|84|96|108|120|132|144|156|168|180|192|204|216|228|228</O><O ID="StdMinZBounds">-6|-6|-5</O><O ID="StdMaxZBounds">5|6|5</O><O ID="RefMinZBounds">-6|-6|-5</O><O ID="RefMaxZBounds">5|6|5</O></Opt>`

#### Scenario: XML malformado
- **WHEN** o sistema lê as opções do texto "<Opt><O>"
- **THEN** a leitura lança `SurveyOptionsError.invalidXML`

### Requirement: Chaves legadas do Anthro II nas opções
Na leitura, as chaves `MinZBounds` e `MaxZBounds` SHALL ser renomeadas para `StdMinZBounds` e `StdMaxZBounds` com o valor preservado sem conversão, como `SurveyOptions(string xml)`, e chave repetida após a renomeação SHALL tornar o XML inválido.

#### Scenario: Limite legado preservado sem conversão
- **WHEN** o sistema lê `<Opt><O ID="MinZBounds">-5|-6|-6|-5</O></Opt>`
- **THEN** o mínimo de peso para idade nos padrões é -5 e o de estatura é -6

#### Scenario: Chave legada e nova juntas
- **WHEN** o XML tem `MinZBounds` e `StdMinZBounds`
- **THEN** a leitura lança `SurveyOptionsError.invalidXML`

### Requirement: Faixas etárias a partir das fronteiras
O sistema SHALL derivar as faixas etárias das fronteiras $b_0, ..., b_n$: faixa $k$ de $b_k$ a $b_{k+1} - 1$ para $k < n - 1$ e a última de $b_{n-1}$ a $b_n$, como `NSOptionsDialog.Init`.

#### Scenario: Faixas padrão
- **WHEN** o sistema deriva as faixas de `SurveyOptions.default`
- **THEN** há 21 faixas, a primeira é 0 a 5, a sexta é 48 a 60, a sétima é 61 a 71 e a última é 228 a 228

#### Scenario: Fronteiras mínimas
- **WHEN** as fronteiras são 0, 61, 228
- **THEN** há 2 faixas, 0 a 60 e 61 a 228

### Requirement: Edição das faixas etárias
O editor de opções SHALL aceitar de 2 a 21 faixas com limites inferiores estritamente crescentes entre 0 e 228 e limite superior final maior ou igual ao último inferior; fora disso, aplicar SHALL lançar erro, como as mensagens de `NSOptionsDialog`.

#### Scenario: Menos de duas faixas
- **WHEN** a usuária remove faixas até sobrar uma e aplica
- **THEN** a aplicação lança `SurveyOptionsEditorError.tooFewAgeGroups`

#### Scenario: Limites inferiores repetidos
- **WHEN** os limites inferiores são 0, 12 e 12 e a usuária aplica
- **THEN** a aplicação lança `SurveyOptionsEditorError.inconsistentAgeGroups`

### Requirement: Edição dos limites de z
O editor SHALL avaliar cada limite com `MeasurementInput.evaluate` entre -99 e 99 com 1 casa, bloqueando aplicar com texto vazio, inválido ou fora do intervalo; ao editar um máximo abaixo do mínimo SHALL igualá-lo ao mínimo, e um mínimo acima do máximo, ao máximo, como `NSOptionsDialog.CheckZRanges`.

#### Scenario: Máximo abaixo do mínimo
- **WHEN** o mínimo de peso dos padrões é -6 e a usuária digita "-7" no máximo
- **THEN** o máximo passa a -6

#### Scenario: Mínimo acima do máximo e limite fora da faixa
- **WHEN** o máximo de IMC da referência é 5 e a usuária digita "6" no mínimo e depois "120" no máximo
- **THEN** o mínimo passa a 5, a avaliação do máximo é `.outOfRange(-99...99)`, o máximo vigente continua 5 e `apply()` lança `SurveyOptionsEditorError.invalidZBounds`

### Requirement: Restaurar opções padrão
O botão de restaurar SHALL repor no editor todas as opções padrão: atribuição automática, faixas etárias e limites de z, como `SurveyOptions.ResetToDefault`.

#### Scenario: Restaurar depois de alterar
- **WHEN** a usuária liga a atribuição de equipe, muda o máximo de estatura para 4 e restaura
- **THEN** o editor aplica opções iguais a `SurveyOptions.default`

#### Scenario: Restaurar sem alterações
- **WHEN** a usuária restaura num inquérito que já tem as opções padrão
- **THEN** as opções aplicadas continuam iguais a `SurveyOptions.default`

### Requirement: Opções aplicadas só ao confirmar
As alterações do editor de opções SHALL valer só quando a usuária aplicar; aplicar SHALL marcar o inquérito com alterações pendentes e recalcular as flags, e cancelar SHALL descartar tudo, inclusive a atribuição automática e a restauração.

#### Scenario: Aplicar recalcula flags
- **WHEN** um registro tem z de peso 4.00 nos padrões e a usuária aplica máximo de peso 3.5
- **THEN** a célula de z de peso fica destacada e `hasUnsavedChanges` é verdadeiro

#### Scenario: Cancelar descarta a atribuição automática
- **WHEN** a usuária liga a atribuição de conglomerado no editor e cancela
- **THEN** as opções do inquérito continuam com a atribuição de conglomerado desligada e a de ID ligada, e `hasUnsavedChanges` continua falso

### Requirement: Persistência dos registros
O sistema SHALL gravar e reler cada registro com todos os campos sem perda: decimais como texto exato, datas sem hora, edema distinguindo `nil` de falso, e XML de dados adicionais copiado sem interpretação; a ordem de inclusão SHALL ser preservada.

#### Scenario: Ida e volta de um registro completo
- **WHEN** o sistema salva e relê um registro com fator de peso 0.1234567890123456, edema `nil` e dados adicionais `<Data />`
- **THEN** o registro relido é igual ao salvo

#### Scenario: Ordem de inclusão
- **WHEN** a usuária inclui os registros A, B e C, salva e reabre o inquérito
- **THEN** a tabela mostra A, B e C nesta ordem

### Requirement: Registro novo copia a definição de dados adicionais
Um registro novo SHALL receber uma cópia do XML de definição de dados adicionais do inquérito, como o construtor de `Record`, e inquérito sem definição SHALL usar `<Data />`.

#### Scenario: Definição copiada
- **WHEN** o inquérito tem definição `<Data><Cat ID="Escola" Descr="" /></Data>` e a usuária cria um registro
- **THEN** o XML de dados adicionais do registro é `<Data><Cat ID="Escola" Descr="" /></Data>`

#### Scenario: Inquérito sem definição
- **WHEN** o inquérito novo não tem definição de dados adicionais
- **THEN** o registro criado tem XML `<Data />`

### Requirement: Migração 3 do banco
A migração 3 SHALL criar as tabelas `surveys` e `records`, com exclusão em cascata dos registros e sexo restrito a 1 (menino) ou 2 (menina).

#### Scenario: Banco migrado
- **WHEN** o banco é aberto com `Migrations.all`
- **THEN** `schemaVersion()` é pelo menos 3 e as tabelas `surveys` e `records` existem

#### Scenario: Sexo inválido
- **WHEN** um INSERT direto grava um registro com sexo 3
- **THEN** o banco lança `StoreError.sqlite` de restrição
