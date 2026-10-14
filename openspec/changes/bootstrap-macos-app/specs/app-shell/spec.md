# Spec Delta

## ADDED Requirements

### Requirement: Pacote compilável sem Xcode
O repositório SHALL conter um `Package.swift` com os targets `AnthroCore`, `AnthroStore`, `AnthroIO`, `AnthroAnalysis`, `AnthroFeatures` e o executável `AnthroPlusApp`, que compilam e testam só com as Command Line Tools.

#### Scenario: Build e testes num clone limpo
- **WHEN** `swift build` e `swift test` são executados num clone limpo com Swift 6.1 e sem Xcode
- **THEN** os dois comandos terminam com código 0

#### Scenario: Produto inexistente
- **WHEN** `swift build --product AnthroPlusMac` é executado
- **THEN** o comando termina com código diferente de 0, porque o único executável se chama `AnthroPlusApp`

### Requirement: Bundle de aplicativo instalável
`scripts/build-app.sh` SHALL gerar `build/AnthroPlus.app` com `Info.plist` (`CFBundleIdentifier` `local.suzan.anthroplus`, `LSMinimumSystemVersion` 14.0, versão lida de `VERSION`), ícone `AppIcon.icns`, recursos do SwiftPM copiados e assinatura ad-hoc válida.

#### Scenario: Bundle gerado e assinado
- **WHEN** `scripts/build-app.sh` é executado com sucesso
- **THEN** `build/AnthroPlus.app/Contents/Info.plist` tem `CFBundleIdentifier` igual a `local.suzan.anthroplus`, `codesign --verify build/AnthroPlus.app` termina com código 0 e `build/AnthroPlus.app/Contents/MacOS/AnthroPlusApp --self-test` termina com código 0

#### Scenario: Arquivo de versão ausente
- **WHEN** `scripts/build-app.sh` é executado sem o arquivo `VERSION` na raiz
- **THEN** o script termina com código 2 e escreve em stderr uma mensagem que contém `VERSION`

### Requirement: Três módulos na sidebar
A janela principal SHALL listar, nesta ordem, Calculadora antropométrica, Avaliação individual e Inquérito nutricional, cada um com título em pt-BR e ícone SF Symbol, e SHALL abrir na seção salva em `AppSettings.lastSection` (padrão: Calculadora).

#### Scenario: Primeira abertura
- **WHEN** o `AppModel` é criado com configurações vazias
- **THEN** `selectedSection` é `.calculator` e `AppSection.allCases.map(\.title)` é `["Calculadora antropométrica", "Avaliação individual", "Inquérito nutricional"]`

#### Scenario: Reabertura lembra a seção
- **WHEN** o usuário seleciona `.nutritionalSurvey` e um novo `AppModel` é criado com o mesmo `UserDefaults`
- **THEN** `selectedSection` do novo modelo é `.nutritionalSurvey`

### Requirement: Atalhos de módulo
O sistema SHALL selecionar o módulo de número 1, 2 ou 3 com ⌘1, ⌘2 ou ⌘3, e SHALL ignorar outros números sem mudar a seleção.

#### Scenario: Atalho válido
- **WHEN** `handleShortcut(number: 2)` é chamado com a Calculadora selecionada
- **THEN** a função devolve `true` e `selectedSection` é `.individualAssessment`

#### Scenario: Atalho fora do intervalo
- **WHEN** `handleShortcut(number: 4)` é chamado com a Avaliação individual selecionada
- **THEN** a função devolve `false` e `selectedSection` continua `.individualAssessment`

### Requirement: Configurações persistidas
`AppSettings` SHALL persistir em `UserDefaults` as opções do original usadas pelo app (`useEnterForNextControl` padrão `true`, `autoAssignChildID` padrão `true`) e a seção ativa.

#### Scenario: Valores padrão
- **WHEN** `AppSettings` é criado com um `UserDefaults` vazio
- **THEN** `useEnterForNextControl` é `true`, `autoAssignChildID` é `true` e `lastSection` é `.calculator`

#### Scenario: Valor alterado sobrevive a nova instância
- **WHEN** `autoAssignChildID` é definido como `false`, `lastSection` como `.individualAssessment`, e outro `AppSettings` é criado com o mesmo `UserDefaults`
- **THEN** a nova instância tem `autoAssignChildID` igual a `false` e `lastSection` igual a `.individualAssessment`

### Requirement: Textos da interface em pt-BR
Toda string visível SHALL vir de `L10n`, em pt-BR, sem entradas vazias; o valor indefinido SHALL ser exibido como `N/D`.

#### Scenario: Catálogo sem buracos
- **WHEN** o teste percorre `L10n.allStrings`, que lista todas as strings do catálogo
- **THEN** a lista tem mais de 20 entradas, nenhuma é vazia e `L10n.notAvailable` é `"N/D"`

#### Scenario: Nome do app
- **WHEN** o teste lê `L10n.appName`
- **THEN** o valor é `"AnthroPlus"`

### Requirement: Números no padrão brasileiro
`ClinicalFormat` SHALL exibir valores com o número fixo de casas pedido e vírgula decimal, `N/D` para `nil`, e SHALL ler texto com vírgula ou ponto decimal, rejeitando texto com mais de um separador ou não numérico.

#### Scenario: Formatação com vírgula
- **WHEN** `ClinicalFormat.string` recebe 16.5 com 1 casa, -2.35 com 2 casas e 0 com 2 casas
- **THEN** os textos são `"16,5"`, `"-2,35"` e `"0,00"`

#### Scenario: Valor indefinido
- **WHEN** `ClinicalFormat.string` recebe `nil` com 2 casas
- **THEN** o texto é `"N/D"`

#### Scenario: Leitura de vírgula e ponto
- **WHEN** `ClinicalFormat.parseDecimal` recebe `"16,5"`, `"16.5"` e `" 20 "`
- **THEN** os valores são 16.5, 16.5 e 20

#### Scenario: Texto inválido
- **WHEN** `ClinicalFormat.parseDecimal` recebe `"1,2,3"`, `"abc"` e `""`
- **THEN** os três resultados são `nil`

### Requirement: Painel Sobre com atribuição
O painel Sobre SHALL mostrar a versão do app, a frase de atribuição ao WHO AnthroPlus 1.0.4 da OMS e as referências usadas (Padrões de Crescimento Infantil da OMS 2006 e Referência OMS 2007 para 5 a 19 anos).

#### Scenario: Conteúdo do Sobre
- **WHEN** o teste lê `L10n.About.attribution` e `L10n.About.references`
- **THEN** a atribuição contém `"WHO AnthroPlus 1.0.4"` e as referências contêm `"2006"` e `"2007"`

#### Scenario: Versão ausente no bundle
- **WHEN** `AboutInfo.version(bundle:)` recebe um bundle sem `CFBundleShortVersionString`
- **THEN** o resultado é `"desenvolvimento"`
