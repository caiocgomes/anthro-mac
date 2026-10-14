# Spec Delta

## ADDED Requirements

### Requirement: Persistência dos dados da criança
O sistema SHALL gravar e reler, sem perda, ID de exibição, nome, sobrenome, data de nascimento, marca de data aproximada, sexo, notas, data, intervalo e destino do acompanhamento e os vínculos com mãe, pai e endereço. Textos SHALL ser gravados sem espaços nas pontas, e texto vazio SHALL ser gravado como `nil`, como `Utils.TextToNullableString`.

#### Scenario: Criança salva e reaberta
- **WHEN** a usuária salva uma menina com ID 7, nome "Ana", sobrenome "Silva", nascimento 2015-01-01 aproximado, notas "Ambulatório", acompanhamento em 2021-10-01 a cada 30 dias com destino "Nutrição", mãe, pai e endereço vinculados, e reabre a ficha
- **THEN** todos os campos relidos são iguais aos salvos, com sexo `.girl` e `dateOfBirthIsApprox` verdadeiro

#### Scenario: Textos em branco viram nulos
- **WHEN** a usuária salva uma criança com nome "  Ana  ", sobrenome "   " e notas vazias
- **THEN** o nome relido é "Ana" e o sobrenome e as notas relidos são `nil`

### Requirement: Sexo obrigatório para salvar
O sistema SHALL recusar salvar uma criança sem sexo informado, lançando `ChildValidationError.sexRequired` e sem gravar nada no banco, como `IAMain.SaveCurrentChild`.

#### Scenario: Criança com sexo informado
- **WHEN** a usuária salva uma nova criança com sexo masculino
- **THEN** a tabela `children` passa a ter 1 linha com `sex` igual a 1

#### Scenario: Criança sem sexo
- **WHEN** a usuária salva uma nova criança sem escolher o sexo
- **THEN** o salvamento lança `ChildValidationError.sexRequired` e a tabela `children` continua com 0 linhas

### Requirement: ID de exibição automático
Com `AppSettings.autoAssignChildID` ligado, o sistema SHALL atribuir a uma criança salva sem ID o maior ID de exibição entre todas as crianças do banco, ativas e arquivadas, mais 1, ou 1 se não houver nenhuma, e SHALL impedir a edição manual do ID; desligado, o ID SHALL ser editável e opcional.

#### Scenario: Próximo ID considera o arquivo
- **WHEN** o banco tem crianças ativas com ID 3 e 7 e uma arquivada com ID 12, o ID automático está ligado e a usuária salva uma nova criança
- **THEN** a nova criança recebe o ID 13

#### Scenario: Primeira criança do banco
- **WHEN** o banco não tem crianças, o ID automático está ligado e a usuária salva uma nova criança
- **THEN** a nova criança recebe o ID 1

#### Scenario: ID manual com automático desligado
- **WHEN** o ID automático está desligado e a usuária salva uma nova criança sem ID
- **THEN** `isDisplayIDEditable` é verdadeiro e a criança é gravada com ID `nil`

### Requirement: Lista de crianças ativas
O sistema SHALL listar só as crianças não arquivadas, em ordem crescente de ID de exibição com ID `nil` primeiro, e SHALL rotular cada linha como o original: sobrenome, a vírgula e espaço só se houver sobrenome, o nome, e o ID entre parênteses.

#### Scenario: Ordem e rótulo das linhas
- **WHEN** o banco tem "Silva, Ana" com ID 2, "Souza, Bia" com ID 1 e "Lima, Caio" sem ID, todos ativos
- **THEN** os rótulos, em ordem, são "Lima, Caio ()", "Souza, Bia (1)" e "Silva, Ana (2)"

#### Scenario: Rótulo sem sobrenome
- **WHEN** uma criança ativa tem nome "Dora", sobrenome `nil` e ID 5
- **THEN** o rótulo é "Dora (5)"

### Requirement: Arquivamento e restauração
O sistema SHALL mover as crianças marcadas para o arquivo e de volta à lista ativa, preservando visitas. Na visão do arquivo SHALL ficar disponível só restaurar e voltar, e restaurar SHALL exigir ao menos uma criança marcada.

#### Scenario: Arquivar duas de três crianças
- **WHEN** a lista ativa tem 3 crianças, a usuária marca 2 e arquiva
- **THEN** a lista ativa mostra 1 criança, a visão do arquivo mostra 2 e as visitas das arquivadas continuam no banco

#### Scenario: Restaurar sem marcação
- **WHEN** a usuária está na visão do arquivo sem nenhuma criança marcada
- **THEN** `canRestore` é falso, e `canCreate`, `canDelete`, `canSearch` e `canArchive` são falsos

### Requirement: Exclusão de crianças
O sistema SHALL excluir as crianças marcadas e todas as suas visitas numa única transação, como `Children.Delete`, e em seguida SHALL remover mães, pais e endereços que não estejam vinculados a nenhuma criança, exceto os ligados à ficha aberta e ainda não salva, que SHALL ser preservados.

#### Scenario: Excluir criança com visitas
- **WHEN** a usuária exclui uma criança que tem 2 visitas
- **THEN** a criança e as 2 visitas deixam de existir no banco

#### Scenario: Mãe compartilhada por irmãos
- **WHEN** duas crianças compartilham a mesma mãe e a usuária exclui só uma delas
- **THEN** a mãe continua no banco; e quando a segunda também é excluída, a mãe deixa de existir

### Requirement: Limpeza de órfãos ao abrir o módulo
Ao carregar o módulo de Avaliação individual, o sistema SHALL remover mães, pais e endereços sem nenhuma criança vinculada, como `Global.Init` chama `CleanupOrphans`.

#### Scenario: Mãe sem filhos é removida
- **WHEN** o banco tem uma mãe sem criança vinculada e uma mãe vinculada a uma criança, e o módulo é carregado
- **THEN** só a mãe vinculada continua no banco

#### Scenario: Limpeza repetida preserva vinculados
- **WHEN** a limpeza roda duas vezes seguidas sobre um banco com uma mãe sem criança e uma mãe vinculada a uma criança
- **THEN** a primeira execução devolve 1 mãe removida, a segunda devolve 0 mães, 0 pais e 0 endereços removidos, e a mãe vinculada continua no banco

### Requirement: Busca de crianças por nome
O sistema SHALL buscar entre as crianças ativas por nome e sobrenome com `*` valendo qualquer sequência e `?` um único caractere, como `DBHelper.ReplaceWildcards`; sem curinga a comparação SHALL ser exata. A comparação SHALL ignorar maiúsculas, inclusive em letras acentuadas, e SHALL diferenciar acentos.

#### Scenario: Prefixo com curinga
- **WHEN** as crianças ativas têm sobrenomes "Lopez", "lima" e "Silva" e a busca é sobrenome "L*"
- **THEN** o resultado tem "Lopez" e "lima" e não tem "Silva"

#### Scenario: Sem curinga é igualdade
- **WHEN** a busca é sobrenome "lopez" e depois sobrenome "Lop"
- **THEN** a primeira encontra "Lopez" e a segunda não encontra nenhuma criança

#### Scenario: Curinga de um caractere
- **WHEN** as crianças ativas têm nomes "Ana" e "Anna" e a busca é nome "?na"
- **THEN** o resultado tem só "Ana"

#### Scenario: Maiúsculas e acentos
- **WHEN** uma criança ativa tem nome "Érica" e as buscas são nome "érica" e nome "erica"
- **THEN** a busca "érica" encontra a criança e a busca "erica" não encontra

### Requirement: Busca de crianças por sexo, ID e nascimento
O sistema SHALL filtrar as crianças ativas por sexo, por ID de exibição entre limites inclusivos e por nascimento entre datas inclusivas, combinando os critérios informados com E e ordenando por ID. Critérios todos vazios SHALL encerrar a busca e voltar à lista ativa.

#### Scenario: Faixas de ID e de nascimento
- **WHEN** as crianças ativas são meninas com ID 1, 2, 4 e 5 nascidas em 2015-01-01, 2015-06-01, 2016-01-01 e 2017-01-01, e a busca é sexo feminino, ID de 2 a 4, nascimento de 2015-06-01 a 2016-01-01
- **THEN** o resultado tem as crianças de ID 2 e 4, nessa ordem, e o modo da lista é `.searchResults`

#### Scenario: Criança arquivada fica fora da busca
- **WHEN** uma criança arquivada tem sobrenome "Lopez", uma ativa tem sobrenome "Lopes" e a busca é sobrenome "Lop*"
- **THEN** o resultado tem só a criança "Lopes"

#### Scenario: Critérios vazios
- **WHEN** a lista está em `.searchResults` e a usuária busca com todos os critérios vazios
- **THEN** o modo da lista volta a `.active` com todas as crianças ativas

### Requirement: Cadastro de mãe e pai
O sistema SHALL gravar mãe ou pai na hora em que a usuária salva o cadastro, independente de salvar a criança. Altura fora de 50 a 300 cm ou peso fora de 10 a 1000 kg SHALL ficar `nil` no cálculo; o IMC exibido SHALL ser truncado a 1 casa, como `IAParentDialog.RefreshBMI`; nascimento SHALL ser opcional e não posterior a hoje.

#### Scenario: IMC truncado da mãe
- **WHEN** a usuária informa para a mãe peso "59" e altura "165"
- **THEN** o IMC exibido é "21,6", e não "21,7" do arredondamento

#### Scenario: Altura fora do intervalo bloqueia o cadastro
- **WHEN** a usuária informa para o pai peso "80" e altura "40" e tenta salvar
- **THEN** `heightOutcome` é `.outOfRange(50...300)`, `heightWarning` não é `nil`, o IMC exibido é "N/D", `canSave` é falso, `save()` lança `ParentValidationError.invalidMeasurement` e a tabela `fathers` continua com 0 linhas

#### Scenario: Altura vazia é permitida
- **WHEN** a usuária informa para o pai peso "80", deixa a altura vazia e salva
- **THEN** `canSave` é verdadeiro e a tabela `fathers` passa a ter 1 linha com peso 80 e altura `nil`

#### Scenario: Nascimento desconhecido e futuro
- **WHEN** a usuária marca nascimento desconhecido e salva, e em outro cadastro informa nascimento amanhã
- **THEN** o primeiro é gravado com nascimento `nil` e o segundo com nascimento igual a hoje

### Requirement: Cadastro de endereço
O sistema SHALL gravar endereço com logradouro, local, CEP, distrito, província, estado, país, telefone e e-mail, sem espaços nas pontas e com vazio como `nil`, e SHALL rotulá-lo juntando os campos preenchidos com ", ", usando " - " antes do país e o ID entre parênteses, ou "(Sem dados)" sem campos.

#### Scenario: Rótulo de endereço
- **WHEN** a usuária salva logradouro "Rua A, 10", local "São Paulo", país "Brasil" e o endereço recebe o ID 3
- **THEN** o rótulo é "Rua A, 10, São Paulo - Brasil (3)"

#### Scenario: Endereço vazio
- **WHEN** a usuária salva um endereço sem nenhum campo e ele recebe o ID 4
- **THEN** o rótulo é "(Sem dados) (4)"

### Requirement: Busca de mãe, pai e endereço existentes
O sistema SHALL buscar mães e pais pelo texto contido no nome, sobrenome ou notas, e endereços pelo texto contido em qualquer campo, sem diferenciar maiúsculas. Texto vazio SHALL listar todos; mais de 50 resultados SHALL dar `.tooManyResults` e nenhum SHALL dar `.noResults`, como `ComboSearch.DoSearch`.

#### Scenario: Mãe encontrada por trecho do sobrenome
- **WHEN** o banco tem a mãe "Maria Silva" e a busca de mães é "sil"
- **THEN** o resultado é `.results` contendo "Maria Silva"

#### Scenario: Resultados demais
- **WHEN** o banco tem 51 mães e a busca de mães é vazia
- **THEN** o resultado é `.tooManyResults`

#### Scenario: Nenhum resultado
- **WHEN** a busca de endereços é "xyz" e nenhum campo de endereço contém esse texto
- **THEN** o resultado é `.noResults`

### Requirement: Data de nascimento da criança
O sistema SHALL limitar o nascimento da criança à data da primeira visita, se houver visitas, ou a hoje. Com data aproximada, o dia SHALL ser sorteado entre 1 e o penúltimo dia do mês, como `Random.Next(1, DiasNoMês)`, e mudar só o dia SHALL ser ignorado.

#### Scenario: Nascimento depois da primeira visita
- **WHEN** a criança tem a primeira visita em 2021-09-01 e a usuária muda o nascimento para 2021-10-01
- **THEN** o nascimento passa a ser 2021-09-01

#### Scenario: Nascimento futuro sem visitas
- **WHEN** a criança não tem visitas, hoje é 2026-10-14 e a usuária informa nascimento 2026-10-20
- **THEN** o nascimento passa a ser 2026-10-14

#### Scenario: Dia sorteado em fevereiro bissexto
- **WHEN** a usuária marca data aproximada com nascimento em fevereiro de 2016
- **THEN** o sorteio recebe o intervalo de 1 a 28 e o nascimento fica em fevereiro de 2016 com o dia sorteado

#### Scenario: Dia alterado com data aproximada
- **WHEN** a data aproximada está marcada com nascimento 2016-02-10 e a usuária muda só o dia para 2016-02-11
- **THEN** o nascimento continua 2016-02-10

### Requirement: Alterações não salvas
O sistema SHALL detectar alterações pendentes na criança ou nas suas visitas e, ao trocar de criança, criar outra ou sair do módulo, SHALL aplicar a decisão da usuária: salvar e seguir, descartar e seguir, ou cancelar e permanecer, como `IAMain.AskForSave`.

#### Scenario: Descartar e seguir
- **WHEN** a usuária mudou o nome da criança aberta de "Ana" para "Bia" sem salvar e escolhe descartar ao abrir outra criança
- **THEN** a troca acontece e o nome gravado continua "Ana"

#### Scenario: Cancelar a troca
- **WHEN** há alterações pendentes e a usuária escolhe cancelar ao abrir outra criança
- **THEN** a troca não acontece, a criança aberta continua a mesma e `hasUnsavedChanges` continua verdadeiro

#### Scenario: Salvar falha por falta de sexo
- **WHEN** a nova criança não tem sexo, há alterações pendentes e a usuária escolhe salvar ao abrir outra criança
- **THEN** a troca não acontece e o erro `ChildValidationError.sexRequired` é exposto ao chamador
