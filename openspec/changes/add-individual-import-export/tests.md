# Tests

## Test Strategy

- **Framework**: swift-testing (`import Testing`, `@Test`, `#expect`, `#expect(throws:)`).
- **Full-suite command**: `swift test`
- **Conventions**: testes de formato puros em `Tests/AnthroIOTests/` (sem banco, sem arquivo em disco além das fixtures); testes de gravação e de modelo em `Tests/AnthroFeaturesTests/IndividualExchange/`, com `RepositoryChildExchange` real sobre `AnthroDatabase` num diretório temporário com as migrações 1, 2 e 4. Fixtures em `Tests/AnthroIOTests/Fixtures/` (`resources: [.copy("Fixtures")]`). Construtores de dados de teste em `Tests/AnthroIOTests/Support/ExchangeFixtures.swift` (criança Ana Silva, nascida em 2016-03-15, menina). Datas ao meio-dia do calendário do usuário (`Calendar.current`), pelo helper `day("2016-03-15")`, a normalização das changes 4 a 6: o app guarda o dia de calendário do usuário, e meia-noite UTC cairia no dia anterior em São Paulo. A falha no meio da gravação é provocada por um gatilho SQLite criado pelo próprio teste (`RAISE(ABORT)` ao inserir a segunda criança), sem tocar no código de produção. Nome do teste em lowerCamelCase, prefixado pelo cenário.
- **Stubs do red gate**: funções que devolvem `String` devolvem `""`, `Data` devolvem `Data()`, listas devolvem `[]`, opcionais devolvem `nil`, `Sex` devolve `.girl`, `Bool` devolve `false`, `ExchangeResults` devolve todos os campos `nil`, `ChildImportOutcome` devolve `.imported(count: 0)`; nenhuma função lança erro.
- **Mutation tool**: manual.

## Spec-to-Test Mapping

### Capability: individual-data-exchange

#### Scenario: Relatório com duas visitas
- **Test name**: `relatorioComDuasVisitasNumeraLinhasEFormataCampos`
- **Test file**: `Tests/AnthroIOTests/ChildReportTests.swift`
- **Level**: acceptance
- **Breaks if**: o índice da visita começar em 0, o separador não for tabulação, o peso usar ponto decimal ou o ID do observador não for `AnthroPlus`
- **Expected red**: `expected 2 visit lines with 12 fields, got 0` (stub devolve texto vazio)

#### Scenario: Idade formatada em anos e meses
- **Test name**: `idadeFormatadaEmAnosEMesesTruncaMeses`
- **Test file**: `Tests/AnthroIOTests/ChildReportTests.swift`
- **Level**: acceptance
- **Breaks if**: a idade em meses for arredondada (60,6) em vez de truncada, ou o rótulo usar `yr`/`mo`
- **Expected red**: `expected field "5a 0m", got nil`

#### Scenario: Z-score indefinido no relatório
- **Test name**: `zScoreIndefinidoNoRelatorioDeixaCampoVazio`
- **Test file**: `Tests/AnthroIOTests/ChildReportTests.swift`
- **Level**: acceptance
- **Breaks if**: z indefinido for escrito como `N/D`, `0` ou o sentinela, ou a linha perder campos
- **Expected red**: `expected 12 fields with WAZ empty and oedema "s", got 0 lines`

#### Scenario: Bytes iniciais e quebras de linha
- **Test name**: `bytesIniciaisEQuebrasDeLinhaDoRelatorioSaoUtf16BomECrlf`
- **Test file**: `Tests/AnthroIOTests/ChildReportTests.swift`
- **Level**: acceptance
- **Breaks if**: o relatório for gravado em UTF-8 ou com `\n` sozinho
- **Expected red**: `expected prefix [0xFF, 0xFE], got []`

#### Scenario: Nome sugerido sem sobrenome
- **Test name**: `nomeSugeridoSemSobrenomeOmiteVirgula`
- **Test file**: `Tests/AnthroIOTests/ChildReportTests.swift`
- **Level**: acceptance
- **Breaks if**: a vírgula for escrita sempre (`, Ana.txt`) ou a extensão faltar
- **Expected red**: `expected "Ana.txt", got ""`

#### Scenario: Cabeçalho sem resultados
- **Test name**: `cabecalhoSemResultadosTem43ColunasNaOrdemOriginal`
- **Test file**: `Tests/AnthroIOTests/ChildDelimitedExportTests.swift`
- **Level**: acceptance
- **Breaks if**: uma coluna fixa for omitida, reordenada, traduzida, ou o CSV usar vírgula como separador
- **Expected red**: `expected 43 header fields starting with "DisplayID", got 0`

#### Scenario: Cabeçalho com resultados
- **Test name**: `cabecalhoComResultadosAcrescentaWazHazBazBmi`
- **Test file**: `Tests/AnthroIOTests/ChildDelimitedExportTests.swift`
- **Level**: acceptance
- **Breaks if**: as colunas de resultado vierem antes das fixas ou faltar `BMI`
- **Expected red**: `expected 47 header fields, got 0`

#### Scenario: Criança com três visitas
- **Test name**: `criancaComTresVisitasGeraTresLinhasRepetindoDados`
- **Test file**: `Tests/AnthroIOTests/ChildDelimitedExportTests.swift`
- **Level**: acceptance
- **Breaks if**: só a primeira visita for escrita ou os dados da criança só aparecerem na primeira linha
- **Expected red**: `expected 4 lines, got 0`

#### Scenario: Criança sem visitas
- **Test name**: `criancaSemVisitasGeraUmaLinhaComVisitaVazia`
- **Test file**: `Tests/AnthroIOTests/ChildDelimitedExportTests.swift`
- **Level**: acceptance
- **Breaks if**: a criança sem visitas for omitida do arquivo
- **Expected red**: `expected 2 lines, got 0`

#### Scenario: Valor com o separador no CSV
- **Test name**: `valorComOSeparadorNoCsvVaiEntreAspasComBom`
- **Test file**: `Tests/AnthroIOTests/ChildDelimitedExportTests.swift`
- **Level**: acceptance
- **Breaks if**: a checagem de aspas ignorar o separador, ou o BOM UTF-8 não for escrito
- **Expected red**: `expected field "\"pesada; sem sapatos\"" and prefix EF BB BF, got empty data`

#### Scenario: Valor com aspas e separador ausente
- **Test name**: `valorComAspasEDuplicadoEPontoEVirgulaNoTxtSemAspas`
- **Test file**: `Tests/AnthroIOTests/DelimitedWriterTests.swift`
- **Level**: acceptance
- **Breaks if**: aspas internas não forem duplicadas, ou todo valor for posto entre aspas
- **Expected red**: `expected "\"disse \"\"não\"\"\"", got ""`

#### Scenario: Data, sexo e medida
- **Test name**: `dataSexoEMedidaUsamCodigosDoOriginal`
- **Test file**: `Tests/AnthroIOTests/FieldWriterTests.swift`
- **Level**: acceptance
- **Breaks if**: a data sair em ISO, o sexo de menina sair `2`, ou a medida em pé sair `1`
- **Expected red**: `expected "15-03-2016 00:00:00", got ""`

#### Scenario: Decimal em CSV e em XML
- **Test name**: `decimalEmCsvUsaVirgulaEEmXmlUsaPonto`
- **Test file**: `Tests/AnthroIOTests/FieldWriterTests.swift`
- **Level**: acceptance
- **Breaks if**: o estilo de decimal for ignorado ou zeros à direita forem mantidos (`16,50`)
- **Expected red**: `expected "16,5", got ""`

#### Scenario: Altura da mãe ausente
- **Test name**: `alturaDaMaeAusenteSaiVazia`
- **Test file**: `Tests/AnthroIOTests/ChildDelimitedExportTests.swift`
- **Level**: acceptance
- **Breaks if**: valor ausente for escrito como `0` ou `nil`
- **Expected red**: `expected column MotherHeight with "", got no header`

#### Scenario: IMC exportado usa a medida ajustada
- **Test name**: `imcExportadoUsaAMedidaAjustadaEmQualquerIdade`
- **Test file**: `Tests/AnthroIOTests/ExchangeResultsCalculatorTests.swift`
- **Level**: acceptance
- **Breaks if**: o IMC usar a medida sem ajuste fora da faixa de padrões (16.5)
- **Expected red**: `expected bmi 16.7, got nil`

#### Scenario: Resultados com edema
- **Test name**: `resultadosComEdemaMantemSoEstatura`
- **Test file**: `Tests/AnthroIOTests/ExchangeResultsCalculatorTests.swift`
- **Level**: acceptance
- **Breaks if**: o edema não for repassado ao motor ou o IMC for calculado com edema
- **Expected red**: `expected lengthOrHeightForAgeZ != nil, got nil`

#### Scenario: Colisões de nome com colunas fixas
- **Test name**: `colisoesDeNomeComColunasFixasRecebemSufixo`
- **Test file**: `Tests/AnthroIOTests/ChildDelimitedExportTests.swift`
- **Level**: acceptance
- **Breaks if**: as colunas fixas e de resultado não forem passadas como `forbiddenKeys` a `AdditionalDataColumns.structure`, deixando `Weight` duplicada
- **Expected red**: `expected last header fields ["Sport", "Sport 2", "Weight 2"], got no header`

#### Scenario: Visita sem dados adicionais
- **Test name**: `visitaSemDadosAdicionaisDeixaColunasVazias`
- **Test file**: `Tests/AnthroIOTests/ChildDelimitedExportTests.swift`
- **Level**: acceptance
- **Breaks if**: as colunas adicionais forem omitidas na linha, deslocando campos
- **Expected red**: `expected header with "Sport" and empty cell, got no header`

#### Scenario: Criança completa com uma visita
- **Test name**: `criancaCompletaComUmaVisitaTemElementosEAtributos`
- **Test file**: `Tests/AnthroIOTests/ChildXMLTests.swift`
- **Level**: acceptance
- **Breaks if**: `Father` vazio for escrito, `Visits` faltar ou um atributo de resultado for omitido
- **Expected red**: `expected XPath /Children/Child/Visits/Visit count 1, got parse failure on empty data`

#### Scenario: Criança sem visitas no XML
- **Test name**: `criancaSemVisitasNoXmlNaoTemFilhos`
- **Test file**: `Tests/AnthroIOTests/ChildXMLTests.swift`
- **Level**: acceptance
- **Breaks if**: um elemento `Visits` vazio for escrito
- **Expected red**: `expected one Child element with 0 children, got parse failure`

#### Scenario: Visita sem dados adicionais no XML
- **Test name**: `visitaSemDadosAdicionaisNoXmlTemAtributoVazio`
- **Test file**: `Tests/AnthroIOTests/ChildXMLTests.swift`
- **Level**: acceptance
- **Breaks if**: o atributo `AdditionalData` só for escrito quando houver dados, ou sair vazio em vez de `<Data />`
- **Expected red**: `expected attribute AdditionalData == "<Data />", got parse failure`

#### Scenario: Variações de sexo aceitas
- **Test name**: `variacoesDeSexoAceitasNaImportacao`
- **Test file**: `Tests/AnthroIOTests/FieldParserTests.swift`
- **Level**: acceptance
- **Breaks if**: a comparação diferenciar maiúsculas ou `2` não for aceito como menina
- **Expected red**: `expected .boy for "Male", got .girl`

#### Scenario: Sexo não reconhecido
- **Test name**: `sexoNaoReconhecidoRejeitaOArquivo`
- **Test file**: `Tests/AnthroIOTests/ChildXMLTests.swift`
- **Level**: acceptance
- **Breaks if**: sexo inválido virar menina por padrão
- **Expected red**: `expected throw ImportFailure.invalidStructure, got none`

#### Scenario: Decimal com vírgula
- **Test name**: `decimalComVirgulaEhLidoComoPonto`
- **Test file**: `Tests/AnthroIOTests/FieldParserTests.swift`
- **Level**: acceptance
- **Breaks if**: a vírgula não for trocada por ponto antes da conversão
- **Expected red**: `expected 16.5, got nil`

#### Scenario: Formatos de data aceitos
- **Test name**: `formatosDeDataAceitosDescartamHora`
- **Test file**: `Tests/AnthroIOTests/FieldParserTests.swift`
- **Level**: acceptance
- **Breaks if**: o fallback `yyyyMMdd` ou `dd/MM/yyyy` faltar, ou a hora for mantida
- **Expected red**: `expected 2016-03-15, got nil`

#### Scenario: Data ilegível
- **Test name**: `dataIlegivelRejeitaOArquivo`
- **Test file**: `Tests/AnthroIOTests/ChildXMLTests.swift`
- **Level**: acceptance
- **Breaks if**: data ilegível virar `nil` numa data obrigatória
- **Expected red**: `expected throw ImportFailure.invalidStructure, got none`

#### Scenario: Nome longo e peso com três casas
- **Test name**: `nomeLongoEPesoComTresCasasSaoTruncados`
- **Test file**: `Tests/AnthroIOTests/ChildXMLTests.swift`
- **Level**: acceptance
- **Breaks if**: o peso for arredondado (16.79) ou o nome for rejeitado em vez de cortado
- **Expected red**: `expected 1 child with weight 16.78, got 0 children`

#### Scenario: Truncamento leva o peso abaixo do mínimo
- **Test name**: `truncamentoLevaOPesoAbaixoDoMinimoERejeita`
- **Test file**: `Tests/AnthroIOTests/ChildXMLTests.swift`
- **Level**: acceptance
- **Breaks if**: o limite for checado antes do truncamento
- **Expected red**: `expected throw ImportFailure.invalidStructure, got none`

#### Scenario: Peso acima do limite
- **Test name**: `pesoAcimaDoLimiteRejeitaSemGravar`
- **Test file**: `Tests/AnthroFeaturesTests/IndividualExchange/ChildExchangeModelTests.swift`
- **Level**: integration
- **Breaks if**: o limite superior de 275 kg não for aplicado, ou a criança válida do mesmo arquivo for gravada
- **Expected red**: `expected outcome .failed, got .imported(count: 0)`

#### Scenario: Visita antes do nascimento
- **Test name**: `visitaAntesDoNascimentoRejeita`
- **Test file**: `Tests/AnthroIOTests/ChildXMLTests.swift`
- **Level**: acceptance
- **Breaks if**: o limite inferior da data da visita não for passado a `FieldParser.date`
- **Expected red**: `expected throw ImportFailure.invalidStructure, got none`

#### Scenario: Visita na data do nascimento
- **Test name**: `visitaNaDataDoNascimentoEhAceita`
- **Test file**: `Tests/AnthroIOTests/ChildXMLTests.swift`
- **Level**: acceptance
- **Breaks if**: a comparação usar `<=` em vez de `<` para rejeitar
- **Expected red**: `expected 1 child with 1 visit, got 0 children`

#### Scenario: Atributo opcional ausente
- **Test name**: `atributoOpcionalAusenteEhAceitoComoNil`
- **Test file**: `Tests/AnthroIOTests/ChildXMLTests.swift`
- **Level**: acceptance
- **Breaks if**: atributo ausente for tratado como obrigatório (comportamento acidental do original)
- **Expected red**: `expected 1 child with notes nil, got 0 children`

#### Scenario: Duas visitas na mesma data
- **Test name**: `duasVisitasNaMesmaDataRejeitaComValorInvalido`
- **Test file**: `Tests/AnthroIOTests/ChildXMLTests.swift`
- **Level**: acceptance
- **Breaks if**: a checagem usar `<` em vez de `<=`, aceitando datas iguais
- **Expected red**: `expected throw ImportFailure.invalidFieldValue([]), got none`

#### Scenario: Visitas fora de ordem
- **Test name**: `visitasForaDeOrdemRejeitaComValorInvalido`
- **Test file**: `Tests/AnthroIOTests/ChildXMLTests.swift`
- **Level**: acceptance
- **Breaks if**: as visitas forem ordenadas antes da checagem
- **Expected red**: `expected throw ImportFailure.invalidFieldValue([]), got none`

#### Scenario: Visitas em ordem crescente
- **Test name**: `visitasEmOrdemCrescenteSaoAceitas`
- **Test file**: `Tests/AnthroIOTests/ChildXMLTests.swift`
- **Level**: acceptance
- **Breaks if**: a checagem rejeitar qualquer criança com mais de uma visita
- **Expected red**: `expected 2 visits, got 0 children`

#### Scenario: Dados adicionais válidos
- **Test name**: `dadosAdicionaisValidosSaoGuardados`
- **Test file**: `Tests/AnthroIOTests/ChildXMLTests.swift`
- **Level**: acceptance
- **Breaks if**: o atributo `AdditionalData` for ignorado na leitura ou não passar por `AdditionalDataXML.decode`
- **Expected red**: `expected visit additionalData with section "Food", got 0 children`

#### Scenario: Dados adicionais malformados
- **Test name**: `dadosAdicionaisMalformadosRejeitam`
- **Test file**: `Tests/AnthroIOTests/ChildXMLTests.swift`
- **Level**: acceptance
- **Breaks if**: o erro de `AdditionalDataXML.decode` for engolido e a visita ficar sem dados adicionais
- **Expected red**: `expected throw ImportFailure.invalidStructure, got none`

#### Scenario: Duas crianças importadas
- **Test name**: `duasCriancasImportadasPreservamDisplayID`
- **Test file**: `Tests/AnthroFeaturesTests/IndividualExchange/RepositoryChildExchangeTests.swift`
- **Level**: integration
- **Breaks if**: o `displayID` do arquivo for renumerado, ou as visitas não forem gravadas
- **Expected red**: `expected insertAll == 2 and children with displayID [7, 9] in database, got 0`

#### Scenario: Falha no meio da gravação
- **Test name**: `falhaNoMeioDaGravacaoDesfazTudo`
- **Test file**: `Tests/AnthroFeaturesTests/IndividualExchange/RepositoryChildExchangeTests.swift`
- **Level**: integration
- **Breaks if**: a gravação não estiver dentro de `AnthroDatabase.transaction`
- **Expected red**: `expected insertAll to throw (trigger on second child), got 0 without error`

#### Scenario: CreatedBy e SALB na exportação
- **Test name**: `createdByESalbNaExportacaoSaoFixos`
- **Test file**: `Tests/AnthroIOTests/ChildDelimitedExportTests.swift`
- **Level**: acceptance
- **Breaks if**: algum `CreatedBy` sair vazio ou SALB sair preenchido
- **Expected red**: `expected ChildCreatedBy == "AnthroPlus", got no header`

#### Scenario: CreatedBy e SALB lidos e descartados
- **Test name**: `createdByESalbLidosSaoDescartados`
- **Test file**: `Tests/AnthroIOTests/ChildXMLTests.swift`
- **Level**: acceptance
- **Breaks if**: o `CreatedBy` lido reaparecer na exportação, ou `SALBLevel1` do arquivo for reescrito
- **Expected red**: `expected 1 child read and CreatedBy="AnthroPlus" on re-export, got 0 children`

#### Scenario: Exportar e reimportar
- **Test name**: `exportarEReimportarPreservaTodosOsCampos`
- **Test file**: `Tests/AnthroIOTests/ChildXMLTests.swift`
- **Level**: acceptance
- **Breaks if**: um atributo escrito não for lido, ou o separador decimal do XML for vírgula
- **Expected red**: `expected 3 children equal to input, got []`

#### Scenario: Arquivo no layout do original com vírgula decimal
- **Test name**: `arquivoNoLayoutDoOriginalComVirgulaDecimalEhLido`
- **Test file**: `Tests/AnthroIOTests/ChildXMLTests.swift`
- **Level**: acceptance
- **Breaks if**: a leitura de decimal exigir ponto
- **Expected red**: `expected weight 16.5 from ia-original-ptbr.xml, got 0 children`

#### Scenario: Exportação só com criança marcada
- **Test name**: `exportacaoSoComCriancaMarcadaEResultadosDesligados`
- **Test file**: `Tests/AnthroFeaturesTests/IndividualExchange/ChildExchangeModelTests.swift`
- **Level**: acceptance
- **Breaks if**: `canExport` ignorar a seleção
- **Expected red**: `expected canExport == true after selecting one child, got false`

#### Scenario: Duas crianças marcadas em CSV
- **Test name**: `duasCriancasMarcadasEmCsvGeramTresLinhas`
- **Test file**: `Tests/AnthroFeaturesTests/IndividualExchange/ChildExchangeModelTests.swift`
- **Level**: integration
- **Breaks if**: a exportação usar todas as crianças em vez das marcadas, ou o formato errado
- **Expected red**: `expected file with 3 lines, got empty file`

#### Scenario: Mensagem de formato inválido
- **Test name**: `mensagemDeFormatoInvalidoTrazDetalhe`
- **Test file**: `Tests/AnthroFeaturesTests/IndividualExchange/ChildExchangeModelTests.swift`
- **Level**: acceptance
- **Breaks if**: o detalhe de linha, elemento e atributo não for acrescentado
- **Expected red**: `expected prefix "Não foi possível importar o arquivo 'criancas.xml': o formato do arquivo é inválido.", got ""`

#### Scenario: Mensagem de valor inválido
- **Test name**: `mensagemDeValorInvalidoEmPtBr`
- **Test file**: `Tests/AnthroFeaturesTests/IndividualExchange/ChildExchangeModelTests.swift`
- **Level**: acceptance
- **Breaks if**: a falha de valor inválido usar o texto de formato inválido
- **Expected red**: `expected "...contêm valores inválidos.", got ""`

## Coverage Ledger

| Capability | Scenario | Test file | Test name | Breaks if | Red (SHA: failure) | Green (SHA) | State |
|------------|----------|-----------|-----------|-----------|--------------------|-------------|-------|
| individual-data-exchange | Relatório com duas visitas | Tests/AnthroIOTests/ChildReportTests.swift | relatorioComDuasVisitasNumeraLinhasEFormataCampos | índice começa em 0 | 9d785b8: ChildReportTests.swift:19:9: Expectation failed: (table.count -> 0) == 3 |  | red |
| individual-data-exchange | Idade formatada em anos e meses | Tests/AnthroIOTests/ChildReportTests.swift | idadeFormatadaEmAnosEMesesTruncaMeses | meses arredondados | 9d785b8: ChildReportTests.swift:32:9: Expectation failed: (line?[7] -> nil) == "5a 0m" |  | red |
| individual-data-exchange | Z-score indefinido no relatório | Tests/AnthroIOTests/ChildReportTests.swift | zScoreIndefinidoNoRelatorioDeixaCampoVazio | z indefinido escrito como texto | 9d785b8: ChildReportTests.swift:42:9: Expectation failed: (line?.count -> nil) == 12 |  | red |
| individual-data-exchange | Bytes iniciais e quebras de linha | Tests/AnthroIOTests/ChildReportTests.swift | bytesIniciaisEQuebrasDeLinhaDoRelatorioSaoUtf16BomECrlf | gravação em UTF-8 | 9d785b8: ChildReportTests.swift:52:9: Expectation failed: (Array(data.prefix(2)) -> []) == ([0xFF, 0xFE] -> [255, 254]) |  | red |
| individual-data-exchange | Nome sugerido sem sobrenome | Tests/AnthroIOTests/ChildReportTests.swift | nomeSugeridoSemSobrenomeOmiteVirgula | vírgula sempre escrita | 9d785b8: ChildReportTests.swift:61:9: Expectation failed: (ChildReport.suggestedFileName(for: ExchangeFixtures.ana(lastName: "")) -> "") == "Ana.txt" |  | red |
| individual-data-exchange | Cabeçalho sem resultados | Tests/AnthroIOTests/ChildDelimitedExportTests.swift | cabecalhoSemResultadosTem43ColunasNaOrdemOriginal | coluna omitida ou reordenada | 9d785b8: ChildDelimitedExportTests.swift:20:9: Expectation failed: (header.count -> 0) == 43 |  | red |
| individual-data-exchange | Cabeçalho com resultados | Tests/AnthroIOTests/ChildDelimitedExportTests.swift | cabecalhoComResultadosAcrescentaWazHazBazBmi | coluna BMI ausente | 9d785b8: ChildDelimitedExportTests.swift:31:9: Expectation failed: (header.count -> 0) == 47 |  | red |
| individual-data-exchange | Criança com três visitas | Tests/AnthroIOTests/ChildDelimitedExportTests.swift | criancaComTresVisitasGeraTresLinhasRepetindoDados | só a primeira visita escrita | 9d785b8: ChildDelimitedExportTests.swift:42:9: Expectation failed: (table.count -> 0) == 4 |  | red |
| individual-data-exchange | Criança sem visitas | Tests/AnthroIOTests/ChildDelimitedExportTests.swift | criancaSemVisitasGeraUmaLinhaComVisitaVazia | criança sem visitas omitida | 9d785b8: ChildDelimitedExportTests.swift:50:9: Expectation failed: (table.count -> 0) == 2 |  | red |
| individual-data-exchange | Valor com o separador no CSV | Tests/AnthroIOTests/ChildDelimitedExportTests.swift | valorComOSeparadorNoCsvVaiEntreAspasComBom | separador não aciona aspas | 9d785b8: ChildDelimitedExportTests.swift:58:9: Expectation failed: (Array(data.prefix(3)) -> []) == ([0xEF, 0xBB, 0xBF] -> [239, 187, 191]) |  | red |
| individual-data-exchange | Valor com aspas e separador ausente | Tests/AnthroIOTests/DelimitedWriterTests.swift | valorComAspasEDuplicadoEPontoEVirgulaNoTxtSemAspas | aspas não duplicadas | 9d785b8: DelimitedWriterTests.swift:12:9: Expectation failed: (text -> "") == ("Notes\tPlace\r\n\"disse \"\"não\"\"\"\tpesada; sem sapatos\r\n" -> "Notes	Place |  | red |
| individual-data-exchange | Data, sexo e medida | Tests/AnthroIOTests/FieldWriterTests.swift | dataSexoEMedidaUsamCodigosDoOriginal | menina escrita como 2 | 9d785b8: FieldWriterTests.swift:11:9: Expectation failed: (FieldWriter.date(day("2016-03-15")) -> "") == "15-03-2016 00:00:00" |  | red |
| individual-data-exchange | Decimal em CSV e em XML | Tests/AnthroIOTests/FieldWriterTests.swift | decimalEmCsvUsaVirgulaEEmXmlUsaPonto | estilo decimal ignorado | 9d785b8: FieldWriterTests.swift:23:9: Expectation failed: (FieldWriter.decimal(d("16.50"), style: .comma) -> "") == "16,5" |  | red |
| individual-data-exchange | Altura da mãe ausente | Tests/AnthroIOTests/ChildDelimitedExportTests.swift | alturaDaMaeAusenteSaiVazia | ausente escrito como 0 | 9d785b8: ChildDelimitedExportTests.swift:66:9: Expectation failed: (ExchangeFixtures.cell(table, "MotherFirstName") -> nil) == "Maria" |  | red |
| individual-data-exchange | IMC exportado usa a medida ajustada | Tests/AnthroIOTests/ExchangeResultsCalculatorTests.swift | imcExportadoUsaAMedidaAjustadaEmQualquerIdade | IMC sem ajuste na referência | 9d785b8: ExchangeResultsCalculatorTests.swift:19:9: Expectation failed: (results.bmi -> nil) == (d("16.7") -> 16.7) |  | red |
| individual-data-exchange | Resultados com edema | Tests/AnthroIOTests/ExchangeResultsCalculatorTests.swift | resultadosComEdemaMantemSoEstatura | edema não repassado | 9d785b8: ExchangeResultsCalculatorTests.swift:26:9: Expectation failed: (results.lengthOrHeightForAgeZ -> nil) != nil |  | red |
| individual-data-exchange | Colisões de nome com colunas fixas | Tests/AnthroIOTests/ChildDelimitedExportTests.swift | colisoesDeNomeComColunasFixasRecebemSufixo | forbiddenKeys sem colunas fixas | 9d785b8: ChildDelimitedExportTests.swift:82:9: Expectation failed: (Array((table.first ?? []).suffix(3)) -> []) == ["Sport", "Sport 2", "Weight 2"] |  | red |
| individual-data-exchange | Visita sem dados adicionais | Tests/AnthroIOTests/ChildDelimitedExportTests.swift | visitaSemDadosAdicionaisDeixaColunasVazias | colunas omitidas na linha | 9d785b8: ChildDelimitedExportTests.swift:94:9: Expectation failed: (table.first?.count -> nil) == 45 |  | red |
| individual-data-exchange | Criança completa com uma visita | Tests/AnthroIOTests/ChildXMLTests.swift | criancaCompletaComUmaVisitaTemElementosEAtributos | Father vazio escrito | 9d785b8: ChildXMLTests.swift:12:13: Expectation failed: try? XMLDocument(data: data) -> nil |  | red |
| individual-data-exchange | Criança sem visitas no XML | Tests/AnthroIOTests/ChildXMLTests.swift | criancaSemVisitasNoXmlNaoTemFilhos | Visits vazio escrito | 9d785b8: ChildXMLTests.swift:12:13: Expectation failed: try? XMLDocument(data: data) -> nil |  | red |
| individual-data-exchange | Visita sem dados adicionais no XML | Tests/AnthroIOTests/ChildXMLTests.swift | visitaSemDadosAdicionaisNoXmlTemAtributoVazio | atributo só com dados ou vazio | 9d785b8: ChildXMLTests.swift:12:13: Expectation failed: try? XMLDocument(data: data) -> nil |  | red |
| individual-data-exchange | Variações de sexo aceitas | Tests/AnthroIOTests/FieldParserTests.swift | variacoesDeSexoAceitasNaImportacao | comparação sensível a maiúsculas | 9d785b8: FieldParserTests.swift:13:9: Expectation failed: try FieldParser.sex("Male") == .boy |  | red |
| individual-data-exchange | Sexo não reconhecido | Tests/AnthroIOTests/ChildXMLTests.swift | sexoNaoReconhecidoRejeitaOArquivo | sexo inválido vira menina | 9d785b8: ChildXMLTests.swift:55:31: Issue recorded: expected ImportFailure.invalidStructure, got 0 children |  | red |
| individual-data-exchange | Decimal com vírgula | Tests/AnthroIOTests/FieldParserTests.swift | decimalComVirgulaEhLidoComoPonto | vírgula não trocada | 9d785b8: FieldParserTests.swift:21:9: Expectation failed: try FieldParser.decimal("16,5", nullable: false, unsigned: true) == d("16.5") |  | red |
| individual-data-exchange | Formatos de data aceitos | Tests/AnthroIOTests/FieldParserTests.swift | formatosDeDataAceitosDescartamHora | fallback yyyyMMdd ausente | 9d785b8: FieldParserTests.swift:28:13: Expectation failed: (date -> nil) == (day("2016-03-15") -> 2016-03-15 15:00:00 +0000) |  | red |
| individual-data-exchange | Data ilegível | Tests/AnthroIOTests/ChildXMLTests.swift | dataIlegivelRejeitaOArquivo | data ilegível vira nil | 9d785b8: ChildXMLTests.swift:60:31: Issue recorded: expected ImportFailure.invalidStructure, got 0 children |  | red |
| individual-data-exchange | Nome longo e peso com três casas | Tests/AnthroIOTests/ChildXMLTests.swift | nomeLongoEPesoComTresCasasSaoTruncados | peso arredondado | 9d785b8: ChildXMLTests.swift:70:25: Expectation failed: (children -> []).first -> nil -> nil |  | red |
| individual-data-exchange | Truncamento leva o peso abaixo do mínimo | Tests/AnthroIOTests/ChildXMLTests.swift | truncamentoLevaOPesoAbaixoDoMinimoERejeita | limite antes do truncamento | 9d785b8: ChildXMLTests.swift:77:31: Issue recorded: expected ImportFailure.invalidStructure, got 0 children |  | red |
| individual-data-exchange | Peso acima do limite | Tests/AnthroFeaturesTests/IndividualExchange/ChildExchangeModelTests.swift | pesoAcimaDoLimiteRejeitaSemGravar | limite de 275 kg ausente | 9d785b8: ChildExchangeModelTests.swift:83:25: Issue recorded: expected .failed, got imported(count: 0) |  | red |
| individual-data-exchange | Visita antes do nascimento | Tests/AnthroIOTests/ChildXMLTests.swift | visitaAntesDoNascimentoRejeita | limite inferior não passado | 9d785b8: ChildXMLTests.swift:84:31: Issue recorded: expected ImportFailure.invalidStructure, got 0 children |  | red |
| individual-data-exchange | Visita na data do nascimento | Tests/AnthroIOTests/ChildXMLTests.swift | visitaNaDataDoNascimentoEhAceita | rejeição com <= | 9d785b8: ChildXMLTests.swift:90:9: Expectation failed: (children.count -> 0) == 1 |  | red |
| individual-data-exchange | Atributo opcional ausente | Tests/AnthroIOTests/ChildXMLTests.swift | atributoOpcionalAusenteEhAceitoComoNil | ausente tratado como obrigatório | 9d785b8: ChildXMLTests.swift:98:9: Expectation failed: (children.count -> 0) == 1 |  | red |
| individual-data-exchange | Duas visitas na mesma data | Tests/AnthroIOTests/ChildXMLTests.swift | duasVisitasNaMesmaDataRejeitaComValorInvalido | aceita datas iguais | 9d785b8: ChildXMLTests.swift:109:9: Expectation failed: an error was expected but none was thrown and "[]" was returned |  | red |
| individual-data-exchange | Visitas fora de ordem | Tests/AnthroIOTests/ChildXMLTests.swift | visitasForaDeOrdemRejeitaComValorInvalido | visitas ordenadas antes | 9d785b8: ChildXMLTests.swift:115:9: Expectation failed: an error was expected but none was thrown and "[]" was returned |  | red |
| individual-data-exchange | Visitas em ordem crescente | Tests/AnthroIOTests/ChildXMLTests.swift | visitasEmOrdemCrescenteSaoAceitas | rejeita mais de uma visita | 9d785b8: ChildXMLTests.swift:122:9: Expectation failed: (children.first?.visits.map { ymd($0.date) } -> nil) == (["2021-04-01", "2021-10-01"] -> [Optional("2021-04-01"), Optional("2021-10-01")]) |  | red |
| individual-data-exchange | Dados adicionais válidos | Tests/AnthroIOTests/ChildXMLTests.swift | dadosAdicionaisValidosSaoGuardados | atributo ignorado na leitura | 9d785b8: ChildXMLTests.swift:131:25: Expectation failed: (children.first?.visits -> nil).first -> nil -> nil |  | red |
| individual-data-exchange | Dados adicionais malformados | Tests/AnthroIOTests/ChildXMLTests.swift | dadosAdicionaisMalformadosRejeitam | erro do decode engolido | 9d785b8: ChildXMLTests.swift:137:31: Issue recorded: expected ImportFailure.invalidStructure, got 0 children |  | red |
| individual-data-exchange | Duas crianças importadas | Tests/AnthroFeaturesTests/IndividualExchange/RepositoryChildExchangeTests.swift | duasCriancasImportadasPreservamDisplayID | displayID renumerado | 9d785b8: RepositoryChildExchangeTests.swift:39:9: Expectation failed: try exchange.insertAll(twoChildren) == 2 |  | red |
| individual-data-exchange | Falha no meio da gravação | Tests/AnthroFeaturesTests/IndividualExchange/RepositoryChildExchangeTests.swift | falhaNoMeioDaGravacaoDesfazTudo | gravação fora de transação | 9d785b8: RepositoryChildExchangeTests.swift:56:9: Expectation failed: an error was expected but none was thrown and "0" was returned |  | red |
| individual-data-exchange | CreatedBy e SALB na exportação | Tests/AnthroIOTests/ChildDelimitedExportTests.swift | createdByESalbNaExportacaoSaoFixos | CreatedBy vazio ou SALB preenchido | 9d785b8: ChildDelimitedExportTests.swift:105:9: Expectation failed: (["ChildCreatedBy", "MotherCreatedBy", "AddressCreatedBy", "CreatedBy"].map { ExchangeFixtures.cell(table, $0) } -> [nil, nil, nil, nil]) == (["Ant... |  | red |
| individual-data-exchange | CreatedBy e SALB lidos e descartados | Tests/AnthroIOTests/ChildXMLTests.swift | createdByESalbLidosSaoDescartados | CreatedBy lido reaparece | 9d785b8: ChildXMLTests.swift:147:9: Expectation failed: (children.count -> 0) == 1 |  | red |
| individual-data-exchange | Exportar e reimportar | Tests/AnthroIOTests/ChildXMLTests.swift | exportarEReimportarPreservaTodosOsCampos | atributo escrito e não lido | 9d785b8: ChildXMLTests.swift:178:9: Expectation failed: (reread -> []) == (children -> [AnthroIO.ExchangeChild(displayID: Optional(12), firstName: Optional("Ana"), lastName: Optional("Silva"), dateOfBirt... |  | red |
| individual-data-exchange | Arquivo no layout do original com vírgula decimal | Tests/AnthroIOTests/ChildXMLTests.swift | arquivoNoLayoutDoOriginalComVirgulaDecimalEhLido | leitura exige ponto | 9d785b8: ChildXMLTests.swift:184:25: Expectation failed: (children -> []).first -> nil -> nil |  | red |
| individual-data-exchange | Exportação só com criança marcada | Tests/AnthroFeaturesTests/IndividualExchange/ChildExchangeModelTests.swift | exportacaoSoComCriancaMarcadaEResultadosDesligados | canExport ignora seleção | 9d785b8: ChildExchangeModelTests.swift:57:9: Expectation failed: (model -> AnthroFeatures.ChildExchangeModel).canExport -> false |  | red |
| individual-data-exchange | Duas crianças marcadas em CSV | Tests/AnthroFeaturesTests/IndividualExchange/ChildExchangeModelTests.swift | duasCriancasMarcadasEmCsvGeramTresLinhas | exporta todas as crianças | 9d785b8: ChildExchangeModelTests.swift:70:9: Expectation failed: (lines.count -> 0) == 3 |  | red |
| individual-data-exchange | Mensagem de formato inválido | Tests/AnthroFeaturesTests/IndividualExchange/ChildExchangeModelTests.swift | mensagemDeFormatoInvalidoTrazDetalhe | detalhe não acrescentado | 9d785b8: ChildExchangeModelTests.swift:96:25: Issue recorded: expected .failed |  | red |
| individual-data-exchange | Mensagem de valor inválido | Tests/AnthroFeaturesTests/IndividualExchange/ChildExchangeModelTests.swift | mensagemDeValorInvalidoEmPtBr | texto de formato inválido usado | 9d785b8: ChildExchangeModelTests.swift:110:9: Expectation failed: (model.importXML(from: url) -> .imported(count: 0)) == (.failed(message: "Não foi possível importar o arquivo 'criancas.xml': um ou mais campos obr... |  | red |

## Test Changes After Red

<!-- Append-only. Vazio no planejamento. -->
