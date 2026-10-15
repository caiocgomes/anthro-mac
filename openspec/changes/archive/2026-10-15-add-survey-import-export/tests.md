# Tests

## Test Strategy

- **Framework**: swift-testing (`import Testing`, `@Test`, `#expect`, `#expect(throws:)`).
- **Full-suite command**: `swift test`
- **Conventions**: leitores, montagem e escritores testados como funções puras em `Tests/AnthroIOTests/`; modelo e gravação em `Tests/AnthroFeaturesTests/SurveyExchange/` (a falha no meio da gravação usa um trigger SQLite criado pelo teste na tabela de inquéritos da migração 3), com `RepositorySurveyExchange` real sobre `AnthroDatabase` num diretório temporário com as migrações 1, 3 e 4, e um `SurveyDraftPresenter` de teste que guarda o rascunho recebido (porta de saída da tela, não a unidade sob teste). Fixtures em `Tests/AnthroIOTests/Fixtures/` (`survey.rec`, `ns-two-surveys.xml`); DBF gerado em memória por `Tests/AnthroIOTests/Support/DBFBuilder.swift`; tabelas e CSV pequenos montados no próprio teste. Nome do teste em lowerCamelCase, prefixado pelo cenário. Datas ao meio-dia do calendário do usuário (`Calendar.current`), pelo helper `day("2021-04-01")` de cada alvo de teste, a normalização das changes 4 a 7.
- **Stubs do red gate**: parsers devolvem `ImportedTable(columns: [], rows: [])` sem lançar; `SeparatorDetector.detect` devolve `Character("\u{0}")`; `SurveyFileKind.forFileExtension` devolve `.xml`; `TextDecoding.decode` devolve `""`; `ColumnAutoMapper.propose` devolve `[:]`; `ExternalSurveyBuilder.build` devolve `ExternalImportResult(draft: ExchangeSurvey(survey: Survey(), records: []), rowErrors: [], hadFieldWarnings: false)`; `SurveyXML.read` devolve `[]`; funções de `Data` devolvem `Data()`; métodos do modelo não mudam `phase` (fica `.idle`) e `export` devolve `nil`; mensagens devolvem `""` ou `nil`.
- **Mutation tool**: manual.

## Spec-to-Test Mapping

### Capability: survey-data-exchange

#### Scenario: Extensões conhecidas
- **Test name**: `extensoesConhecidasEscolhemOLeitor`
- **Test file**: `Tests/AnthroIOTests/SurveyFileKindTests.swift`
- **Level**: acceptance
- **Breaks if**: a comparação diferenciar maiúsculas ou `.csv` usar tabulação como padrão
- **Expected red**: `expected .delimited(fallbackSeparator: "\t") for "a.TXT", got .xml`

#### Scenario: Extensão desconhecida vira XML
- **Test name**: `extensaoDesconhecidaViraXmlEFalha`
- **Test file**: `Tests/AnthroIOTests/SurveyFileKindTests.swift`
- **Level**: acceptance
- **Breaks if**: extensão desconhecida for lida como texto delimitado
- **Expected red**: `expected throw ImportFailure.invalidStructure from SurveyXML.read, got none`

#### Scenario: Arquivo do Excel em Windows-1252
- **Test name**: `arquivoDoExcelEmWindows1252ViraJoao`
- **Test file**: `Tests/AnthroIOTests/TextDecodingTests.swift`
- **Level**: acceptance
- **Breaks if**: a segunda opção for ISO-8859-1 sem tratar 0x80 a 0x9F, ou não houver segunda opção
- **Expected red**: `expected "João", got ""`

#### Scenario: Arquivo UTF-8 com BOM
- **Test name**: `arquivoUtf8ComBomRemoveOBom`
- **Test file**: `Tests/AnthroIOTests/TextDecodingTests.swift`
- **Level**: acceptance
- **Breaks if**: o BOM ficar como U+FEFF no começo do texto
- **Expected red**: `expected "João", got ""`

#### Scenario: Arquivo UTF-16 LE com BOM
- **Test name**: `arquivoUtf16LeComBomEhDecodificado`
- **Test file**: `Tests/AnthroIOTests/TextDecodingTests.swift`
- **Level**: acceptance
- **Breaks if**: o BOM UTF-16 for ignorado e os bytes lidos como Windows-1252
- **Expected red**: `expected "Sex", got ""`

#### Scenario: CSV com vírgula
- **Test name**: `csvComVirgulaUsaVirgulaComoSeparador`
- **Test file**: `Tests/AnthroIOTests/SeparatorDetectorTests.swift`
- **Level**: acceptance
- **Breaks if**: a detecção não contar vírgulas
- **Expected red**: `expected ",", got "\u{0}"`

#### Scenario: CSV com ponto e vírgula e vírgula decimal
- **Test name**: `csvComPontoEVirgulaEVirgulaDecimalLePeso`
- **Test file**: `Tests/AnthroIOTests/ExternalTableReaderTests.swift`
- **Level**: acceptance
- **Breaks if**: a vírgula decimal desempatar a contagem a favor da vírgula, ou o peso não trocar vírgula por ponto
- **Expected red**: `expected 3 columns and weight 16.5, got 0 columns`

#### Scenario: Primeira linha sem separador
- **Test name**: `primeiraLinhaSemSeparadorUsaPadraoDaExtensao`
- **Test file**: `Tests/AnthroIOTests/SeparatorDetectorTests.swift`
- **Level**: acceptance
- **Breaks if**: o padrão do `.csv` for vírgula
- **Expected red**: `expected ";", got "\u{0}"`

#### Scenario: Separador entre aspas não conta
- **Test name**: `separadorEntreAspasNaoConta`
- **Test file**: `Tests/AnthroIOTests/SeparatorDetectorTests.swift`
- **Level**: acceptance
- **Breaks if**: a contagem incluir caracteres entre aspas
- **Expected red**: `expected ";", got "\u{0}"`

#### Scenario: Campo entre aspas com separador
- **Test name**: `campoEntreAspasComSeparadorFicaInteiro`
- **Test file**: `Tests/AnthroIOTests/DelimitedParserTests.swift`
- **Level**: acceptance
- **Breaks if**: o separador dentro de aspas encerrar o campo
- **Expected red**: `expected ["Silva; Ana", "2"], got no rows`

#### Scenario: Espaço inicial e aspas duplicadas
- **Test name**: `espacoInicialEAspasDuplicadasSaoTratados`
- **Test file**: `Tests/AnthroIOTests/DelimitedParserTests.swift`
- **Level**: acceptance
- **Breaks if**: o espaço inicial for mantido ou `""` não virar uma aspa
- **Expected red**: `expected ["15", "a\"b"], got no rows`

#### Scenario: Quebra de linha dentro de aspas
- **Test name**: `quebraDeLinhaDentroDeAspasMantemUmRegistro`
- **Test file**: `Tests/AnthroIOTests/DelimitedParserTests.swift`
- **Level**: acceptance
- **Breaks if**: o fim de linha encerrar o registro dentro de aspas
- **Expected red**: `expected 1 row with "Ana\nMaria", got 0 rows`

#### Scenario: Nomes vazios e repetidos
- **Test name**: `nomesVaziosERepetidosViramColumnN`
- **Test file**: `Tests/AnthroIOTests/DelimitedParserTests.swift`
- **Level**: acceptance
- **Breaks if**: o contador de `ColumnN` não procurar o menor N livre
- **Expected red**: `expected ["Sex", "Column1", "Column2"], got []`

#### Scenario: Registro mais longo que o cabeçalho
- **Test name**: `registroMaisLongoQueOCabecalhoCriaColuna`
- **Test file**: `Tests/AnthroIOTests/DelimitedParserTests.swift`
- **Level**: acceptance
- **Breaks if**: o campo excedente for descartado
- **Expected red**: `expected column "Column1" with "4", got []`

#### Scenario: Arquivo vazio
- **Test name**: `arquivoVazioFalhaComFormatoInvalido`
- **Test file**: `Tests/AnthroIOTests/DelimitedParserTests.swift`
- **Level**: acceptance
- **Breaks if**: arquivo vazio virar tabela vazia aceita
- **Expected red**: `expected throw ImportFailure.invalidStructure, got none`

#### Scenario: Linha vazia no meio do arquivo
- **Test name**: `linhaVaziaNoMeioDoArquivoEhIgnorada`
- **Test file**: `Tests/AnthroIOTests/DelimitedParserTests.swift`
- **Level**: acceptance
- **Breaks if**: a linha vazia virar registro, como no original
- **Expected red**: `expected 2 rows, got 0`

#### Scenario: Registro curto
- **Test name**: `registroCurtoCompletaComTextoVazio`
- **Test file**: `Tests/AnthroIOTests/DelimitedParserTests.swift`
- **Level**: acceptance
- **Breaks if**: o registro curto ficar com menos células que o cabeçalho
- **Expected red**: `expected row ["1", "16,5", ""], got no rows`

#### Scenario: REC com dois registros
- **Test name**: `recComDoisRegistrosLeLargurasFixas`
- **Test file**: `Tests/AnthroIOTests/RECParserTests.swift`
- **Level**: acceptance
- **Breaks if**: a largura vier do token errado do descritor ou os valores não forem aparados
- **Expected red**: `expected columns ["SEX", "WEIGHT", "HEIGHT"], got []`

#### Scenario: Registro em duas linhas físicas
- **Test name**: `registroRecEmDuasLinhasFisicasEhJuntado`
- **Test file**: `Tests/AnthroIOTests/RECParserTests.swift`
- **Level**: acceptance
- **Breaks if**: o marcador de continuação for mantido ou a linha de 79 caracteres não continuar
- **Expected red**: `expected NOTES with 78 "a" + "bb", got no rows`

#### Scenario: Descritor de campo incompleto
- **Test name**: `descritorRecIncompletoFalha`
- **Test file**: `Tests/AnthroIOTests/RECParserTests.swift`
- **Level**: acceptance
- **Breaks if**: o descritor curto for aceito
- **Expected red**: `expected throw ImportFailure.invalidStructure, got none`

#### Scenario: DBF com dois registros
- **Test name**: `dbfComDoisRegistrosLeCamposEValores`
- **Test file**: `Tests/AnthroIOTests/DBFParserTests.swift`
- **Level**: acceptance
- **Breaks if**: a largura vier de outro byte do descritor ou o NUL do nome for mantido
- **Expected red**: `expected columns ["SEX", "WEIGHT"], got []`

#### Scenario: Registro apagado
- **Test name**: `registroApagadoNoDbfEhIgnorado`
- **Test file**: `Tests/AnthroIOTests/DBFParserTests.swift`
- **Level**: acceptance
- **Breaks if**: o marcador `*` for ignorado, importando o registro apagado
- **Expected red**: `expected 1 row, got 0`

#### Scenario: DBF truncado
- **Test name**: `dbfTruncadoFalha`
- **Test file**: `Tests/AnthroIOTests/DBFParserTests.swift`
- **Level**: acceptance
- **Breaks if**: a leitura completar o registro faltante com vazios
- **Expected red**: `expected throw ImportFailure.invalidStructure, got none`

#### Scenario: Colunas usuais
- **Test name**: `colunasUsuaisSaoMapeadasAutomaticamente`
- **Test file**: `Tests/AnthroIOTests/ColumnAutoMapperTests.swift`
- **Level**: acceptance
- **Breaks if**: a comparação diferenciar maiúsculas ou `LENGTH` não mapear altura
- **Expected red**: `expected [.displayID: "ID", .sex: "Sex", .weight: "Weight_kg", .height: "Length", .hasOedema: "Oedema"], got [:]`

#### Scenario: Fator de ponderação sem espaço
- **Test name**: `fatorDePonderacaoSemEspacoViraPeso`
- **Test file**: `Tests/AnthroIOTests/ColumnAutoMapperTests.swift`
- **Level**: acceptance
- **Breaks if**: a ordem dos testes for mudada para checar `WEIGHT` só depois de nomes de fator
- **Expected red**: `expected .weight: "WEIGHTFACTOR", got [:]`

#### Scenario: Duas colunas para o mesmo campo
- **Test name**: `duasColunasParaOMesmoCampoUltimaVence`
- **Test file**: `Tests/AnthroIOTests/ColumnAutoMapperTests.swift`
- **Level**: acceptance
- **Breaks if**: a primeira coluna for mantida
- **Expected red**: `expected .weight: "weight2", got [:]`

#### Scenario: Sexo não mapeado
- **Test name**: `sexoNaoMapeadoFalhaComCampoAusente`
- **Test file**: `Tests/AnthroIOTests/ExternalSurveyBuilderTests.swift`
- **Level**: acceptance
- **Breaks if**: a lista de campos obrigatórios ficar vazia
- **Expected red**: `expected throw ImportFailure.missingField([line 0, "Sex"]), got none`

#### Scenario: Sexo mapeado
- **Test name**: `sexoMapeadoMontaTodosOsRegistros`
- **Test file**: `Tests/AnthroIOTests/ExternalSurveyBuilderTests.swift`
- **Level**: acceptance
- **Breaks if**: registros sem outros campos mapeados forem descartados
- **Expected red**: `expected 3 records, got 0`

#### Scenario: Doze registros com sexo inválido
- **Test name**: `dozeRegistrosComSexoInvalidoListamDez`
- **Test file**: `Tests/AnthroIOTests/ExternalSurveyBuilderTests.swift`
- **Level**: acceptance
- **Breaks if**: o limite de 10 erros sumir, ou a linha contar a partir de 0
- **Expected red**: `expected 8 records and 10 errors, got 0 records and 0 errors`

#### Scenario: Sexo com código 2
- **Test name**: `sexoComCodigoDoisEhMenina`
- **Test file**: `Tests/AnthroIOTests/ExternalSurveyBuilderTests.swift`
- **Level**: acceptance
- **Breaks if**: o código 2 for rejeitado
- **Expected red**: `expected 1 record with sex .girl, got 0 records`

#### Scenario: Data de visita inválida
- **Test name**: `dataDeVisitaInvalidaMantemRegistroComAviso`
- **Test file**: `Tests/AnthroIOTests/ExternalSurveyBuilderTests.swift`
- **Level**: acceptance
- **Breaks if**: data inválida descartar o registro, ou o parser de data for leniente e aceitar 31/02
- **Expected red**: `expected 1 record with visitDate nil and hadFieldWarnings true, got 0 records`

#### Scenario: Fator de ponderação vazio e sem mapeamento
- **Test name**: `fatorDePonderacaoVazioViraZeroESemMapeamentoUm`
- **Test file**: `Tests/AnthroIOTests/ExternalSurveyBuilderTests.swift`
- **Level**: acceptance
- **Breaks if**: o fator vazio virar 1 ou o padrão sem mapeamento virar 0
- **Expected red**: `expected weightingFactor 0 and 1, got no records`

#### Scenario: Edema não informado
- **Test name**: `edemaNaoInformadoViraFalso`
- **Test file**: `Tests/AnthroIOTests/ExternalSurveyBuilderTests.swift`
- **Level**: acceptance
- **Breaks if**: edema vazio virar verdadeiro ou descartar o registro
- **Expected red**: `expected 1 record with hasOedema false, got 0 records`

#### Scenario: Peso com três casas
- **Test name**: `pesoComTresCasasEhTruncado`
- **Test file**: `Tests/AnthroIOTests/ExternalSurveyBuilderTests.swift`
- **Level**: acceptance
- **Breaks if**: o peso for arredondado (16.79)
- **Expected red**: `expected weight 16.78, got no records`

#### Scenario: Peso abaixo do mínimo
- **Test name**: `pesoAbaixoDoMinimoFicaAusenteComAviso`
- **Test file**: `Tests/AnthroIOTests/ExternalSurveyBuilderTests.swift`
- **Level**: acceptance
- **Breaks if**: o limite de 0.9 kg não for aplicado
- **Expected red**: `expected 1 record with weight nil and hadFieldWarnings true, got 0 records`

#### Scenario: Idade abaixo de 731 dias
- **Test name**: `idadeAbaixoDe731DiasMarcaDeitado`
- **Test file**: `Tests/AnthroIOTests/ExternalSurveyBuilderTests.swift`
- **Level**: acceptance
- **Breaks if**: a idade em meses não for convertida por `AgeMath.monthsToDays`
- **Expected red**: `expected measuredRecumbent true, got no records`

#### Scenario: Sem idade e com altura de corte
- **Test name**: `semIdadeComAlturaDeCorteDecidePorOitentaESete`
- **Test file**: `Tests/AnthroIOTests/ExternalSurveyBuilderTests.swift`
- **Level**: acceptance
- **Breaks if**: o corte usar `<=` 87
- **Expected red**: `expected [true, false], got no records`

#### Scenario: Sem idade e sem altura
- **Test name**: `semIdadeESemAlturaMarcaEmPe`
- **Test file**: `Tests/AnthroIOTests/ExternalSurveyBuilderTests.swift`
- **Level**: acceptance
- **Breaks if**: o padrão sem informação for deitado
- **Expected red**: `expected measuredRecumbent false, got no records`

#### Scenario: Duas colunas extras
- **Test name**: `duasColunasExtrasViramVariaveisImportadas`
- **Test file**: `Tests/AnthroIOTests/ExternalSurveyBuilderTests.swift`
- **Level**: acceptance
- **Breaks if**: colunas não mapeadas forem descartadas, a ordem mudar ou o valor não for gravado no XML do registro
- **Expected red**: `expected decoded definition with section "Imported" and variables ["escola", "turma"], got additionalDataDefinitionXML nil`

#### Scenario: Todas as colunas mapeadas
- **Test name**: `todasAsColunasMapeadasNaoCriamVariaveis`
- **Test file**: `Tests/AnthroIOTests/ExternalSurveyBuilderTests.swift`
- **Level**: acceptance
- **Breaks if**: colunas mapeadas também virarem variáveis importadas, ou uma seção vazia for gravada
- **Expected red**: `expected 2 records, got 0` (a contagem de registros é checada antes de `additionalDataDefinitionXML`)

#### Scenario: Importar CSV até o rascunho
- **Test name**: `importarCsvAteORascunhoNaoGrava`
- **Test file**: `Tests/AnthroFeaturesTests/SurveyExchange/SurveyExchangeModelTests.swift`
- **Level**: integration
- **Breaks if**: a importação externa gravar o inquérito no banco, ou o nome manter a extensão
- **Expected red**: `expected presented draft "escola_a" with 5 records, got none`

#### Scenario: Cancelar o mapeamento
- **Test name**: `cancelarOMapeamentoVoltaAoInicioSemRascunho`
- **Test file**: `Tests/AnthroFeaturesTests/SurveyExchange/SurveyExchangeModelTests.swift`
- **Level**: acceptance
- **Breaks if**: cancelar entregar o rascunho ou deixar a fase em `.mapping`
- **Expected red**: `expected phase .mapping after beginImport, got .idle`

#### Scenario: Aviso de registros descartados
- **Test name**: `avisoDeRegistrosDescartadosListaLinhaECampo`
- **Test file**: `Tests/AnthroFeaturesTests/SurveyExchange/SurveyExchangeModelTests.swift`
- **Level**: acceptance
- **Breaks if**: o detalhe de linha e campo for omitido
- **Expected red**: `expected message starting "O arquivo 'escola_a.csv' foi importado, mas uma ou mais linhas foram ignoradas", got nil`

#### Scenario: Aviso só de campos inválidos
- **Test name**: `avisoSoDeCamposInvalidos`
- **Test file**: `Tests/AnthroFeaturesTests/SurveyExchange/SurveyExchangeModelTests.swift`
- **Level**: acceptance
- **Breaks if**: o aviso de campos for suprimido quando não há linhas descartadas
- **Expected red**: `expected "...ausentes ou continham valores inválidos.", got nil`

#### Scenario: Importação limpa
- **Test name**: `importacaoLimpaTerminaSemAviso`
- **Test file**: `Tests/AnthroFeaturesTests/SurveyExchange/SurveyExchangeModelTests.swift`
- **Level**: integration
- **Breaks if**: um aviso for emitido sempre
- **Expected red**: `expected phase .finished(warning: nil), got .idle`

#### Scenario: XML com dois inquéritos
- **Test name**: `xmlComDoisInqueritosELido`
- **Test file**: `Tests/AnthroIOTests/SurveyXMLTests.swift`
- **Level**: acceptance
- **Breaks if**: registros forem associados ao inquérito errado
- **Expected red**: `expected 2 surveys with 2 and 1 records, got []`

#### Scenario: Fator de ponderação sem truncamento
- **Test name**: `fatorDePonderacaoDoXmlNaoEhTruncado`
- **Test file**: `Tests/AnthroIOTests/SurveyXMLTests.swift`
- **Level**: acceptance
- **Breaks if**: o fator passar pelo truncamento de 2 casas (1.23)
- **Expected red**: `expected 1.2345, got no surveys`

#### Scenario: Registro sem CreatedBy
- **Test name**: `registroSemCreatedByRejeitaOArquivo`
- **Test file**: `Tests/AnthroIOTests/SurveyXMLTests.swift`
- **Level**: acceptance
- **Breaks if**: `CreatedBy` do registro for tratado como opcional
- **Expected red**: `expected throw ImportFailure.invalidStructure, got none`

#### Scenario: Opções malformadas
- **Test name**: `opcoesMalformadasRejeitamOArquivo`
- **Test file**: `Tests/AnthroIOTests/SurveyXMLTests.swift`
- **Level**: acceptance
- **Breaks if**: o atributo `Options` não passar por `SurveyOptions(xml:)` ou o erro dele for engolido
- **Expected red**: `expected throw ImportFailure.invalidStructure, got none`

#### Scenario: Arquivo do WHO Anthro
- **Test name**: `arquivoDoWhoAnthroConverteDiasEmMeses`
- **Test file**: `Tests/AnthroIOTests/SurveyXMLTests.swift`
- **Level**: acceptance
- **Breaks if**: a presença de `HC` for ignorada
- **Expected red**: `expected ageInMonths 1843 / 30.4375, got no surveys`

#### Scenario: Arquivo do AnthroPlus
- **Test name**: `arquivoDoAnthroPlusLeIdadeEmMeses`
- **Test file**: `Tests/AnthroIOTests/SurveyXMLTests.swift`
- **Level**: acceptance
- **Breaks if**: a idade sempre for convertida de dias
- **Expected red**: `expected ageInMonths 60.55, got no surveys`

#### Scenario: Dois inquéritos gravados
- **Test name**: `doisInqueritosGravadosNumaTransacao`
- **Test file**: `Tests/AnthroFeaturesTests/SurveyExchange/SurveyExchangeModelTests.swift`
- **Level**: integration
- **Breaks if**: os registros não forem gravados junto com os inquéritos
- **Expected red**: `expected 2 surveys and 3 records in database, got 0`

#### Scenario: Sexo inválido no XML
- **Test name**: `sexoInvalidoNoXmlNaoGravaNada`
- **Test file**: `Tests/AnthroFeaturesTests/SurveyExchange/SurveyExchangeModelTests.swift`
- **Level**: integration
- **Breaks if**: o primeiro inquérito válido for gravado antes da falha
- **Expected red**: `expected phase .failed(message:) with "formato do arquivo é inválido", got .idle`

#### Scenario: Falha na gravação do segundo inquérito
- **Test name**: `falhaNaGravacaoDoSegundoInqueritoDesfazTudo`
- **Test file**: `Tests/AnthroFeaturesTests/SurveyExchange/RepositorySurveyExchangeTests.swift`
- **Level**: integration
- **Breaks if**: `insertAll` gravar fora de `AnthroDatabase.transaction`
- **Expected red**: `expected insertAll to throw (trigger on second survey), got 0 without error`

#### Scenario: Cabeçalho do inquérito
- **Test name**: `cabecalhoDoInqueritoTem18ColunasNaOrdem`
- **Test file**: `Tests/AnthroIOTests/SurveyDelimitedExportTests.swift`
- **Level**: acceptance
- **Breaks if**: uma coluna fixa for omitida ou reordenada
- **Expected red**: `expected header "Date;Cluster;...;CreatedBy", got ""`

#### Scenario: Cabeçalho com resultados e dados adicionais
- **Test name**: `cabecalhoComResultadosEDadosAdicionaisTem23Campos`
- **Test file**: `Tests/AnthroIOTests/SurveyDelimitedExportTests.swift`
- **Level**: acceptance
- **Breaks if**: as colunas adicionais vierem antes dos resultados
- **Expected red**: `expected 23 header fields, got 0`

#### Scenario: Idade calculada pelas datas
- **Test name**: `idadeCalculadaPelasDatasComDezCasas`
- **Test file**: `Tests/AnthroIOTests/SurveyDelimitedExportTests.swift`
- **Level**: acceptance
- **Breaks if**: a idade calculada não for escrita quando a guardada falta, ou o número de casas mudar
- **Expected red**: `expected "60,5503080082", got ""`

#### Scenario: Idade desconhecida
- **Test name**: `idadeDesconhecidaSaiVazia`
- **Test file**: `Tests/AnthroIOTests/SurveyDelimitedExportTests.swift`
- **Level**: acceptance
- **Breaks if**: idade desconhecida for escrita como `0`
- **Expected red**: `expected column Age with "", got no header`

#### Scenario: Dois inquéritos em CSV
- **Test name**: `doisInqueritosEmCsvExportaSoOPrimeiro`
- **Test file**: `Tests/AnthroFeaturesTests/SurveyExchange/SurveyExchangeModelTests.swift`
- **Level**: integration
- **Breaks if**: os dois inquéritos forem concatenados no CSV ou o aviso não for devolvido
- **Expected red**: `expected warning .onlyFirstSurveyExported, got nil`

#### Scenario: Dois inquéritos em XML
- **Test name**: `doisInqueritosEmXmlExportaAmbos`
- **Test file**: `Tests/AnthroFeaturesTests/SurveyExchange/SurveyExchangeModelTests.swift`
- **Level**: integration
- **Breaks if**: o XML também for limitado ao primeiro inquérito
- **Expected red**: `expected 2 Survey elements, got parse failure on empty file`

#### Scenario: Inquérito com registros e resultados
- **Test name**: `inqueritoComRegistrosEResultadosTemTodosOsAtributos`
- **Test file**: `Tests/AnthroIOTests/SurveyXMLTests.swift`
- **Level**: acceptance
- **Breaks if**: `AdditionalData` só sair quando houver dados ou um atributo de resultado faltar
- **Expected red**: `expected XPath /Surveys/Survey/Records/Record with 23 attributes, got parse failure`

#### Scenario: Inquérito sem registros
- **Test name**: `inqueritoSemRegistrosNaoTemFilhos`
- **Test file**: `Tests/AnthroIOTests/SurveyXMLTests.swift`
- **Level**: acceptance
- **Breaks if**: um elemento `Records` vazio for escrito
- **Expected red**: `expected one Survey element with 0 children, got parse failure`

#### Scenario: CreatedBy na exportação de inquérito
- **Test name**: `createdByNaExportacaoDeInqueritoEhFixo`
- **Test file**: `Tests/AnthroIOTests/SurveyXMLTests.swift`
- **Level**: acceptance
- **Breaks if**: `CreatedBy` sair vazio no XML ou no CSV
- **Expected red**: `expected Survey and Record CreatedBy == "AnthroPlus", got parse failure on empty data`

#### Scenario: CreatedBy lido e descartado
- **Test name**: `createdByLidoNoXmlDeInqueritoEhDescartado`
- **Test file**: `Tests/AnthroIOTests/SurveyXMLTests.swift`
- **Level**: acceptance
- **Breaks if**: o `CreatedBy` lido reaparecer na exportação seguinte
- **Expected red**: `expected 1 survey read and CreatedBy="AnthroPlus" on re-export, got []`

#### Scenario: Exportar e reler inquérito
- **Test name**: `exportarERelerInqueritoPreservaCampos`
- **Test file**: `Tests/AnthroIOTests/SurveyXMLTests.swift`
- **Level**: acceptance
- **Breaks if**: um atributo escrito não for lido, ou a idade calculada não for escrita no XML
- **Expected red**: `expected 1 survey with 3 equal records, got []`

#### Scenario: Inquérito com dados adicionais na ida e volta
- **Test name**: `inqueritoComDadosAdicionaisNaIdaEVolta`
- **Test file**: `Tests/AnthroIOTests/SurveyXMLTests.swift`
- **Level**: acceptance
- **Breaks if**: o XML interno for reescapado ou alterado na escrita
- **Expected red**: `expected additionalDataDefinitionXML equal to input, got no surveys`

#### Scenario: Planilha com as duas datas e a idade
- **Test name**: `idadeComAsDuasDatasEhDescartadaNaPlanilha`
- **Test file**: `Tests/AnthroIOTests/ExternalSurveyBuilderTests.swift`
- **Level**: unit
- **Breaks if**: a idade mapeada for gravada mesmo com as duas datas, divergindo do setter de `Record.Age` e mudando os z na reedição.
- **Expected red**: expected 1 record with ageInMonths nil, got 0 records (stub de `build`).

#### Scenario: XML com as duas datas e a idade
- **Test name**: `idadeComAsDuasDatasEhDescartadaNoXml`
- **Test file**: `Tests/AnthroIOTests/SurveyXMLTests.swift`
- **Level**: unit
- **Breaks if**: a idade lida do XML for mantida mesmo com as duas datas.
- **Expected red**: expected 1 record with ageInMonths nil, got 0 surveys (stub de `read`).

## Coverage Ledger

| Capability | Scenario | Test file | Test name | Breaks if | Red (SHA: failure) | Green (SHA) | State |
|------------|----------|-----------|-----------|-----------|--------------------|-------------|-------|
| survey-data-exchange | Extensões conhecidas | Tests/AnthroIOTests/SurveyFileKindTests.swift | extensoesConhecidasEscolhemOLeitor | sensível a maiúsculas | e12fb0e: SurveyFileKindTests.swift:11:9: Expectation failed: (kinds -> [AnthroIO.SurveyFileKind.xml, AnthroIO.SurveyFileKind.xml, AnthroIO.SurveyFileKind.xml, AnthroIO.SurveyFileKind.xml, AnthroIO.SurveyFileK... | 4e646f5 | green |
| survey-data-exchange | Extensão desconhecida vira XML | Tests/AnthroIOTests/SurveyFileKindTests.swift | extensaoDesconhecidaViraXmlEFalha | lida como delimitado | e12fb0e: SurveyFileKindTests.swift:17:32: Issue recorded: expected ImportFailure.invalidStructure, got no error | 8642bc4 | green |
| survey-data-exchange | Arquivo do Excel em Windows-1252 | Tests/AnthroIOTests/TextDecodingTests.swift | arquivoDoExcelEmWindows1252ViraJoao | sem segunda codificação | e12fb0e: TextDecodingTests.swift:10:9: Expectation failed: (TextDecoding.decode(Data([0x4A, 0x6F, 0xE3, 0x6F])) -> "") == "João" | 4e646f5 | green |
| survey-data-exchange | Arquivo UTF-8 com BOM | Tests/AnthroIOTests/TextDecodingTests.swift | arquivoUtf8ComBomRemoveOBom | BOM mantido | e12fb0e: TextDecodingTests.swift:15:9: Expectation failed: (TextDecoding.decode(Data([0xEF, 0xBB, 0xBF]) + Data("João".utf8)) -> "") == "João" | 4e646f5 | green |
| survey-data-exchange | Arquivo UTF-16 LE com BOM | Tests/AnthroIOTests/TextDecodingTests.swift | arquivoUtf16LeComBomEhDecodificado | BOM UTF-16 ignorado | e12fb0e: TextDecodingTests.swift:20:9: Expectation failed: (TextDecoding.decode(Data([0xFF, 0xFE, 0x53, 0x00, 0x65, 0x00, 0x78, 0x00])) -> "") == "Sex" | 4e646f5 | green |
| survey-data-exchange | CSV com vírgula | Tests/AnthroIOTests/SeparatorDetectorTests.swift | csvComVirgulaUsaVirgulaComoSeparador | vírgula não contada | e12fb0e: SeparatorDetectorTests.swift:10:9: Expectation failed: (SeparatorDetector.detect(firstLine: "Sex,Weight,Height", fallback: ";") -> ✘ Test primeiraLinhaSemSeparadorUsaPadraoDaExtensao() recorded an issue... | 4e646f5 | green |
| survey-data-exchange | CSV com ponto e vírgula e vírgula decimal | Tests/AnthroIOTests/ExternalTableReaderTests.swift | csvComPontoEVirgulaEVirgulaDecimalLePeso | vírgula decimal desempata | e12fb0e: ExternalTableReaderTests.swift:13:9: Expectation failed: (table.columns -> []) == ["Sex", "Weight", "Height"] | c05affa | green |
| survey-data-exchange | Primeira linha sem separador | Tests/AnthroIOTests/SeparatorDetectorTests.swift | primeiraLinhaSemSeparadorUsaPadraoDaExtensao | padrão do csv vírgula | e12fb0e: SeparatorDetectorTests.swift:17:9: Expectation failed: (table.columns -> []) == ["Sex"] | 9f9b6b6 | green |
| survey-data-exchange | Separador entre aspas não conta | Tests/AnthroIOTests/SeparatorDetectorTests.swift | separadorEntreAspasNaoConta | conta dentro de aspas | e12fb0e: SeparatorDetectorTests.swift:22:9: Expectation failed: (SeparatorDetector.detect(firstLine: "\"Nome, completo\";Sex", fallback: ";") -> ✘ Test duasColunasExtrasViramVariaveisImportadas() recorded an iss... | 4e646f5 | green |
| survey-data-exchange | Campo entre aspas com separador | Tests/AnthroIOTests/DelimitedParserTests.swift | campoEntreAspasComSeparadorFicaInteiro | separador encerra aspas | e12fb0e: DelimitedParserTests.swift:14:9: Expectation failed: try parse("Nome;Sex\r\n\"Silva; Ana\";2\r\n").rows == [["Silva; Ana", "2"]] | 4e646f5 | green |
| survey-data-exchange | Espaço inicial e aspas duplicadas | Tests/AnthroIOTests/DelimitedParserTests.swift | espacoInicialEAspasDuplicadasSaoTratados | espaço inicial mantido | e12fb0e: DelimitedParserTests.swift:19:9: Expectation failed: try parse("A;B\r\n 15;\"a\"\"b\"\r\n").rows == [["15", "a\"b"]] | 4e646f5 | green |
| survey-data-exchange | Quebra de linha dentro de aspas | Tests/AnthroIOTests/DelimitedParserTests.swift | quebraDeLinhaDentroDeAspasMantemUmRegistro | fim de linha encerra aspas | e12fb0e: DelimitedParserTests.swift:24:9: Expectation failed: try parse("Nome;Sex\n\"Ana\nMaria\";2\n").rows == [["Ana\nMaria", "2"]] | 4e646f5 | green |
| survey-data-exchange | Nomes vazios e repetidos | Tests/AnthroIOTests/DelimitedParserTests.swift | nomesVaziosERepetidosViramColumnN | ColumnN sem menor N livre | e12fb0e: DelimitedParserTests.swift:29:9: Expectation failed: try parse("Sex;;Sex\r\n1;2;3\r\n").columns == ["Sex", "Column1", "Column2"] | 4e646f5 | green |
| survey-data-exchange | Registro mais longo que o cabeçalho | Tests/AnthroIOTests/DelimitedParserTests.swift | registroMaisLongoQueOCabecalhoCriaColuna | excedente descartado | e12fb0e: DelimitedParserTests.swift:35:9: Expectation failed: (table.columns -> []) == ["A", "B", "C", "Column1"] | 4e646f5 | green |
| survey-data-exchange | Arquivo vazio | Tests/AnthroIOTests/DelimitedParserTests.swift | arquivoVazioFalhaComFormatoInvalido | vazio aceito | e12fb0e: DelimitedParserTests.swift:41:32: Issue recorded: expected ImportFailure.invalidStructure, got no error | 4e646f5 | green |
| survey-data-exchange | Linha vazia no meio do arquivo | Tests/AnthroIOTests/DelimitedParserTests.swift | linhaVaziaNoMeioDoArquivoEhIgnorada | linha vazia vira registro | e12fb0e: DelimitedParserTests.swift:46:9: Expectation failed: try parse("Sex;Weight\r\n1;16\r\n\r\n2;17\r\n").rows == [["1", "16"], ["2", "17"]] | 4e646f5 | green |
| survey-data-exchange | Registro curto | Tests/AnthroIOTests/DelimitedParserTests.swift | registroCurtoCompletaComTextoVazio | células faltando | e12fb0e: DelimitedParserTests.swift:51:9: Expectation failed: try parse("Sex;Weight;Height\r\n1;16,5\r\n").rows == [["1", "16,5", ""]] | 4e646f5 | green |
| survey-data-exchange | REC com dois registros | Tests/AnthroIOTests/RECParserTests.swift | recComDoisRegistrosLeLargurasFixas | largura do token errado | e12fb0e: RECParserTests.swift:12:9: Expectation failed: (table.columns -> []) == ["SEX", "WEIGHT", "HEIGHT"] | 9f9b6b6 | green |
| survey-data-exchange | Registro em duas linhas físicas | Tests/AnthroIOTests/RECParserTests.swift | registroRecEmDuasLinhasFisicasEhJuntado | marcador mantido | e12fb0e: RECParserTests.swift:20:9: Expectation failed: (table.rows -> []) == ([[String(repeating: "a", count: 78) + "bb", "1"]] -> [["aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa... | 9f9b6b6 | green |
| survey-data-exchange | Descritor de campo incompleto | Tests/AnthroIOTests/RECParserTests.swift | descritorRecIncompletoFalha | descritor curto aceito | e12fb0e: RECParserTests.swift:25:32: Issue recorded: expected ImportFailure.invalidStructure, got no error | 9f9b6b6 | green |
| survey-data-exchange | DBF com dois registros | Tests/AnthroIOTests/DBFParserTests.swift | dbfComDoisRegistrosLeCamposEValores | largura de outro byte | e12fb0e: DBFParserTests.swift:14:9: Expectation failed: (table.columns -> []) == ["SEX", "WEIGHT"] | 9f9b6b6 | green |
| survey-data-exchange | Registro apagado | Tests/AnthroIOTests/DBFParserTests.swift | registroApagadoNoDbfEhIgnorado | marcador * ignorado | e12fb0e: DBFParserTests.swift:21:9: Expectation failed: try DBFParser.parse(data).rows == [["1", "16.50"]] | 9f9b6b6 | green |
| survey-data-exchange | DBF truncado | Tests/AnthroIOTests/DBFParserTests.swift | dbfTruncadoFalha | faltante completado | e12fb0e: DBFParserTests.swift:27:32: Issue recorded: expected ImportFailure.invalidStructure, got no error | 9f9b6b6 | green |
| survey-data-exchange | Colunas usuais | Tests/AnthroIOTests/ColumnAutoMapperTests.swift | colunasUsuaisSaoMapeadasAutomaticamente | LENGTH não mapeia altura | e12fb0e: ColumnAutoMapperTests.swift:9:9: Expectation failed: (ColumnAutoMapper.propose(columns: ["ID", "Sex", "Weight_kg", "Length", "Oedema", "escola"]) -> [:]) == ([.displayID: "ID", .sex: "Sex", .weight: "... | c05affa | green |
| survey-data-exchange | Fator de ponderação sem espaço | Tests/AnthroIOTests/ColumnAutoMapperTests.swift | fatorDePonderacaoSemEspacoViraPeso | ordem de testes mudada | e12fb0e: ColumnAutoMapperTests.swift:16:9: Expectation failed: (proposal[.weightingFactor] -> nil) == "WT FACTOR" | c05affa | green |
| survey-data-exchange | Duas colunas para o mesmo campo | Tests/AnthroIOTests/ColumnAutoMapperTests.swift | duasColunasParaOMesmoCampoUltimaVence | primeira mantida | e12fb0e: ColumnAutoMapperTests.swift:22:9: Expectation failed: (ColumnAutoMapper.propose(columns: ["weight1", "weight2"])[.weight] -> nil) == "weight2" | c05affa | green |
| survey-data-exchange | Sexo não mapeado | Tests/AnthroIOTests/ExternalSurveyBuilderTests.swift | sexoNaoMapeadoFalhaComCampoAusente | obrigatórios vazios | e12fb0e: ExternalSurveyBuilderTests.swift:18:9: Expectation failed: an error was expected but none was thrown and "ExternalImportResult(draft: AnthroIO.ExchangeSurvey(survey: AnthroCore.Survey(id: nil, name: "", not... | c05affa | green |
| survey-data-exchange | Sexo mapeado | Tests/AnthroIOTests/ExternalSurveyBuilderTests.swift | sexoMapeadoMontaTodosOsRegistros | registros descartados | e12fb0e: ExternalSurveyBuilderTests.swift:26:9: Expectation failed: (result.draft.records.count -> 0) == 3 | c05affa | green |
| survey-data-exchange | Doze registros com sexo inválido | Tests/AnthroIOTests/ExternalSurveyBuilderTests.swift | dozeRegistrosComSexoInvalidoListamDez | sem limite de 10 | e12fb0e: ExternalSurveyBuilderTests.swift:34:9: Expectation failed: (result.draft.records.count -> 0) == 8 | c05affa | green |
| survey-data-exchange | Sexo com código 2 | Tests/AnthroIOTests/ExternalSurveyBuilderTests.swift | sexoComCodigoDoisEhMenina | código 2 rejeitado | e12fb0e: ExternalSurveyBuilderTests.swift:42:9: Expectation failed: (result.draft.records.map(\.sex) -> []) == ([.girl] -> [AnthroCore.Sex.girl]) | c05affa | green |
| survey-data-exchange | Data de visita inválida | Tests/AnthroIOTests/ExternalSurveyBuilderTests.swift | dataDeVisitaInvalidaMantemRegistroComAviso | registro descartado | e12fb0e: ExternalSurveyBuilderTests.swift:48:9: Expectation failed: (result.draft.records.count -> 0) == 1 | c05affa | green |
| survey-data-exchange | Fator de ponderação vazio e sem mapeamento | Tests/AnthroIOTests/ExternalSurveyBuilderTests.swift | fatorDePonderacaoVazioViraZeroESemMapeamentoUm | vazio vira 1 | e12fb0e: ExternalSurveyBuilderTests.swift:57:9: Expectation failed: (mapped.draft.records.first?.weightingFactor -> nil) == 0 | c05affa | green |
| survey-data-exchange | Edema não informado | Tests/AnthroIOTests/ExternalSurveyBuilderTests.swift | edemaNaoInformadoViraFalso | vazio vira verdadeiro | e12fb0e: ExternalSurveyBuilderTests.swift:67:9: Expectation failed: (result.draft.records.first?.hasOedema -> nil) == false | c05affa | green |
| survey-data-exchange | Peso com três casas | Tests/AnthroIOTests/ExternalSurveyBuilderTests.swift | pesoComTresCasasEhTruncado | peso arredondado | e12fb0e: ExternalSurveyBuilderTests.swift:73:9: Expectation failed: (result.draft.records.first?.weight -> nil) == (d("16.78") -> 16.78) | c05affa | green |
| survey-data-exchange | Peso abaixo do mínimo | Tests/AnthroIOTests/ExternalSurveyBuilderTests.swift | pesoAbaixoDoMinimoFicaAusenteComAviso | limite 0.9 ausente | e12fb0e: ExternalSurveyBuilderTests.swift:79:9: Expectation failed: (result.draft.records.count -> 0) == 1 | c05affa | green |
| survey-data-exchange | Idade abaixo de 731 dias | Tests/AnthroIOTests/ExternalSurveyBuilderTests.swift | idadeAbaixoDe731DiasMarcaDeitado | meses não convertidos | e12fb0e: ExternalSurveyBuilderTests.swift:87:9: Expectation failed: (result.draft.records.first?.measuredRecumbent -> nil) == true | c05affa | green |
| survey-data-exchange | Sem idade e com altura de corte | Tests/AnthroIOTests/ExternalSurveyBuilderTests.swift | semIdadeComAlturaDeCorteDecidePorOitentaESete | corte com <= | e12fb0e: ExternalSurveyBuilderTests.swift:94:9: Expectation failed: (result.draft.records.map(\.measuredRecumbent) -> []) == [true, false] | c05affa | green |
| survey-data-exchange | Sem idade e sem altura | Tests/AnthroIOTests/ExternalSurveyBuilderTests.swift | semIdadeESemAlturaMarcaEmPe | padrão deitado | e12fb0e: ExternalSurveyBuilderTests.swift:100:9: Expectation failed: (result.draft.records.map(\.measuredRecumbent) -> []) == [false] | c05affa | green |
| survey-data-exchange | Duas colunas extras | Tests/AnthroIOTests/ExternalSurveyBuilderTests.swift | duasColunasExtrasViramVariaveisImportadas | extras descartadas ou sem valor | e12fb0e: ExternalSurveyBuilderTests.swift:108:9: Expectation failed: (definition.sections.map(\.identifier) -> []) == ["Imported"] | c05affa | green |
| survey-data-exchange | Todas as colunas mapeadas | Tests/AnthroIOTests/ExternalSurveyBuilderTests.swift | todasAsColunasMapeadasNaoCriamVariaveis | mapeadas viram variáveis | e12fb0e: ExternalSurveyBuilderTests.swift:119:9: Expectation failed: (result.draft.records.count -> 0) == 2 | c05affa | green |
| survey-data-exchange | Importar CSV até o rascunho | Tests/AnthroFeaturesTests/SurveyExchange/SurveyExchangeModelTests.swift | importarCsvAteORascunhoNaoGrava | rascunho gravado | e12fb0e: SurveyExchangeModelTests.swift:38:25: Issue recorded: expected the mapping phase, got idle | 205b269 | green |
| survey-data-exchange | Cancelar o mapeamento | Tests/AnthroFeaturesTests/SurveyExchange/SurveyExchangeModelTests.swift | cancelarOMapeamentoVoltaAoInicioSemRascunho | cancelar entrega rascunho | e12fb0e: SurveyExchangeModelTests.swift:54:25: Issue recorded: expected the mapping phase, got idle | 205b269 | green |
| survey-data-exchange | Aviso de registros descartados | Tests/AnthroFeaturesTests/SurveyExchange/SurveyExchangeModelTests.swift | avisoDeRegistrosDescartadosListaLinhaECampo | detalhe omitido | e12fb0e: SurveyExchangeModelTests.swift:67:25: Issue recorded: expected a finished phase with a warning, got idle | 205b269 | green |
| survey-data-exchange | Aviso só de campos inválidos | Tests/AnthroFeaturesTests/SurveyExchange/SurveyExchangeModelTests.swift | avisoSoDeCamposInvalidos | aviso suprimido | e12fb0e: SurveyExchangeModelTests.swift:78:9: Expectation failed: (model.phase -> .idle) == (.finished(warning: "O arquivo 'escola_a.csv' foi importado, mas um ou mais campos estavam ausentes ou continham valores ... | 205b269 | green |
| survey-data-exchange | Importação limpa | Tests/AnthroFeaturesTests/SurveyExchange/SurveyExchangeModelTests.swift | importacaoLimpaTerminaSemAviso | aviso sempre emitido | e12fb0e: SurveyExchangeModelTests.swift:85:9: Expectation failed: (model.phase -> .idle) == .finished(warning: nil) | 205b269 | green |
| survey-data-exchange | XML com dois inquéritos | Tests/AnthroIOTests/SurveyXMLTests.swift | xmlComDoisInqueritosELido | registro no inquérito errado | e12fb0e: SurveyXMLTests.swift:22:9: Expectation failed: (surveys.map(\.survey.name) -> []) == ["Escola A", "Escola B"] | 8642bc4 | green |
| survey-data-exchange | Fator de ponderação sem truncamento | Tests/AnthroIOTests/SurveyXMLTests.swift | fatorDePonderacaoDoXmlNaoEhTruncado | fator truncado | e12fb0e: SurveyXMLTests.swift:30:9: Expectation failed: try readOne(F.recordXML(["WeightingFactor": "1.2345"]))?.weightingFactor == d("1.2345") | 8642bc4 | green |
| survey-data-exchange | Registro sem CreatedBy | Tests/AnthroIOTests/SurveyXMLTests.swift | registroSemCreatedByRejeitaOArquivo | CreatedBy opcional | e12fb0e: SurveyXMLTests.swift:35:32: Issue recorded: expected ImportFailure.invalidStructure, got no error | 8642bc4 | green |
| survey-data-exchange | Opções malformadas | Tests/AnthroIOTests/SurveyXMLTests.swift | opcoesMalformadasRejeitamOArquivo | opções não verificadas | e12fb0e: SurveyXMLTests.swift:41:32: Issue recorded: expected ImportFailure.invalidStructure, got no error | 8642bc4 | green |
| survey-data-exchange | Arquivo do WHO Anthro | Tests/AnthroIOTests/SurveyXMLTests.swift | arquivoDoWhoAnthroConverteDiasEmMeses | HC ignorado | e12fb0e: SurveyXMLTests.swift:47:9: Expectation failed: (record?.ageInMonths -> nil) == (d("1843") / d("30.4375") -> 60.5503080082135523613963039014373716) | 8642bc4 | green |
| survey-data-exchange | Arquivo do AnthroPlus | Tests/AnthroIOTests/SurveyXMLTests.swift | arquivoDoAnthroPlusLeIdadeEmMeses | sempre converte dias | e12fb0e: SurveyXMLTests.swift:52:9: Expectation failed: try readOne(F.recordXML(["Age": "60.55"]))?.ageInMonths == d("60.55") | 8642bc4 | green |
| survey-data-exchange | Dois inquéritos gravados | Tests/AnthroFeaturesTests/SurveyExchange/SurveyExchangeModelTests.swift | doisInqueritosGravadosNumaTransacao | registros não gravados | e12fb0e: SurveyExchangeModelTests.swift:92:9: Expectation failed: (model.phase -> .idle) == .finished(warning: nil) | 205b269 | green |
| survey-data-exchange | Sexo inválido no XML | Tests/AnthroFeaturesTests/SurveyExchange/SurveyExchangeModelTests.swift | sexoInvalidoNoXmlNaoGravaNada | gravação parcial | e12fb0e: SurveyExchangeModelTests.swift:102:25: Issue recorded: expected the failed phase, got idle | 205b269 | green |
| survey-data-exchange | Falha na gravação do segundo inquérito | Tests/AnthroFeaturesTests/SurveyExchange/RepositorySurveyExchangeTests.swift | falhaNaGravacaoDoSegundoInqueritoDesfazTudo | gravação fora de transação | e12fb0e: RepositorySurveyExchangeTests.swift:23:9: Expectation failed: an error was expected but none was thrown and "0" was returned | 205b269 | green |
| survey-data-exchange | Cabeçalho do inquérito | Tests/AnthroIOTests/SurveyDelimitedExportTests.swift | cabecalhoDoInqueritoTem18ColunasNaOrdem | coluna omitida | e12fb0e: SurveyDelimitedExportTests.swift:21:9: Expectation failed: (lines.first -> nil) == "Date;Cluster;Team;DisplayID;Household;WeightingFactor;FirstName;LastName;DateOfBirth;DateOfBirthIsApprox;Age;Sex;Weight;He... | 8642bc4 | green |
| survey-data-exchange | Cabeçalho com resultados e dados adicionais | Tests/AnthroIOTests/SurveyDelimitedExportTests.swift | cabecalhoComResultadosEDadosAdicionaisTem23Campos | adicionais antes dos resultados | e12fb0e: SurveyDelimitedExportTests.swift:30:9: Expectation failed: (header.count -> 0) == 23 | 8642bc4 | green |
| survey-data-exchange | Idade calculada pelas datas | Tests/AnthroIOTests/SurveyDelimitedExportTests.swift | idadeCalculadaPelasDatasComDezCasas | idade calculada não escrita | e12fb0e: SurveyDelimitedExportTests.swift:38:9: Expectation failed: (cell(lines, "Age", separator: ";") -> nil) == "60,5503080082" | 8642bc4 | green |
| survey-data-exchange | Idade desconhecida | Tests/AnthroIOTests/SurveyDelimitedExportTests.swift | idadeDesconhecidaSaiVazia | escrita como 0 | e12fb0e: SurveyDelimitedExportTests.swift:46:9: Expectation failed: (lines.count -> 0) == 2 | 8642bc4 | green |
| survey-data-exchange | Dois inquéritos em CSV | Tests/AnthroFeaturesTests/SurveyExchange/SurveyExchangeModelTests.swift | doisInqueritosEmCsvExportaSoOPrimeiro | inquéritos concatenados | e12fb0e: SurveyExchangeModelTests.swift:118:9: Expectation failed: try model.export(format: .semicolonCSV, to: url) == .onlyFirstSurveyExported | 205b269 | green |
| survey-data-exchange | Dois inquéritos em XML | Tests/AnthroFeaturesTests/SurveyExchange/SurveyExchangeModelTests.swift | doisInqueritosEmXmlExportaAmbos | XML limitado ao primeiro | e12fb0e: SurveyExchangeModelTests.swift:133:9: Expectation failed: try doc?.nodes(forXPath: "/Surveys/Survey").count == 2 | 205b269 | green |
| survey-data-exchange | Inquérito com registros e resultados | Tests/AnthroIOTests/SurveyXMLTests.swift | inqueritoComRegistrosEResultadosTemTodosOsAtributos | AdditionalData condicional | e12fb0e: SurveyXMLTests.swift:12:13: Expectation failed: try? XMLDocument(data: data) -> nil | 8642bc4 | green |
| survey-data-exchange | Inquérito sem registros | Tests/AnthroIOTests/SurveyXMLTests.swift | inqueritoSemRegistrosNaoTemFilhos | Records vazio escrito | e12fb0e: SurveyXMLTests.swift:12:13: Expectation failed: try? XMLDocument(data: data) -> nil | 8642bc4 | green |
| survey-data-exchange | CreatedBy na exportação de inquérito | Tests/AnthroIOTests/SurveyXMLTests.swift | createdByNaExportacaoDeInqueritoEhFixo | CreatedBy vazio | e12fb0e: SurveyXMLTests.swift:12:13: Expectation failed: try? XMLDocument(data: data) -> nil | 8642bc4 | green |
| survey-data-exchange | CreatedBy lido e descartado | Tests/AnthroIOTests/SurveyXMLTests.swift | createdByLidoNoXmlDeInqueritoEhDescartado | CreatedBy lido reaparece | e12fb0e: SurveyXMLTests.swift:96:9: Expectation failed: (surveys.count -> 0) == 1 | 8642bc4 | green |
| survey-data-exchange | Exportar e reler inquérito | Tests/AnthroIOTests/SurveyXMLTests.swift | exportarERelerInqueritoPreservaCampos | atributo não lido | e12fb0e: SurveyXMLTests.swift:12:13: Expectation failed: try? XMLDocument(data: data) -> nil | 8642bc4 | green |
| survey-data-exchange | Inquérito com dados adicionais na ida e volta | Tests/AnthroIOTests/SurveyXMLTests.swift | inqueritoComDadosAdicionaisNaIdaEVolta | XML interno alterado | e12fb0e: SurveyXMLTests.swift:133:9: Expectation failed: (reread.first?.survey.additionalDataDefinitionXML -> nil) == (definition -> "<Data><Cat ID="Escola" Descr=""><Txt ID="Série" Descr=""></Txt></Cat><... | 8642bc4 | green |
| survey-data-exchange | Planilha com as duas datas e a idade | Tests/AnthroIOTests/ExternalSurveyBuilderTests.swift | idadeComAsDuasDatasEhDescartadaNaPlanilha | idade mantida com as duas datas | e12fb0e: ExternalSurveyBuilderTests.swift:128:26: Expectation failed: (result.draft.records -> []).first -> nil -> nil | c05affa | green |
| survey-data-exchange | XML com as duas datas e a idade | Tests/AnthroIOTests/SurveyXMLTests.swift | idadeComAsDuasDatasEhDescartadaNoXml | idade mantida com as duas datas | e12fb0e: SurveyXMLTests.swift:57:26: Expectation failed: try readOne(F.recordXML(["DateOfBirth": "15-03-2016 00:00:00", "Age": "70"])) -> nil | 8642bc4 | green |

## Test Changes After Red

<!-- Append-only. Vazio no planejamento. -->
