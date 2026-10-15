# Tasks

## 0. Red gate

- [x] 0.1 Write every scenario test from tests.md and stubs with the exact signatures from Interface Under Test (neutral return values, no logic), including the fixtures `Tests/AnthroIOTests/Fixtures/survey.rec` and `ns-two-surveys.xml` and the byte builder `Tests/AnthroIOTests/Support/DBFBuilder.swift`
- [x] 0.2 Run the scenario tests; confirm each FAILS BY ASSERTION (not import, syntax or collection errors); record each failure excerpt in the ledger
- [x] 0.3 Commit tests and stubs only as `test(red): add-survey-import-export`; write the SHA in the ledger
- [x] 0.4 STOP: show the user the failing tests, confirm the open question on deleted DBF records, and wait for explicit approval before implementing (registrado sem parada, por decisão do Caio de 14/10/2026 e pela meta de 15/10/2026; pergunta do DBF decidida antes do vermelho: registros apagados continuam ignorados, ver Open Questions do design)

## 1. Leitura de texto delimitado

- [x] 1.1 Implement `SurveyFileKind.forFileExtension` portando a escolha por extensão de `NSMain.importFromFileToolStripMenuItem_Click`; verified when [tests: extensoesConhecidasEscolhemOLeitor] pass
- [x] 1.2 Implement `TextDecoding` (BOM UTF-8, UTF-16 LE e BE, UTF-8 estrito, Windows-1252), unit tests first (inner loop); verified when [tests: arquivoDoExcelEmWindows1252ViraJoao, arquivoUtf8ComBomRemoveOBom, arquivoUtf16LeComBomEhDecodificado] pass
- [x] 1.3 Implement `SeparatorDetector` (contagem fora de aspas, padrão por extensão); verified when [tests: csvComVirgulaUsaVirgulaComoSeparador, primeiraLinhaSemSeparadorUsaPadraoDaExtensao, separadorEntreAspasNaoConta] pass
- [x] 1.4 Implement `DelimitedParser` portando `DelimitedTextStream.GetNextItem` e `Delimited.ParseStream` (aspas, espaço inicial, CRLF/LF/CR, `ColumnN`, linhas vazias ignoradas, registros curtos completados), unit tests first; verified when [tests: campoEntreAspasComSeparadorFicaInteiro, espacoInicialEAspasDuplicadasSaoTratados, quebraDeLinhaDentroDeAspasMantemUmRegistro, nomesVaziosERepetidosViramColumnN, registroMaisLongoQueOCabecalhoCriaColuna, arquivoVazioFalhaComFormatoInvalido, linhaVaziaNoMeioDoArquivoEhIgnorada, registroCurtoCompletaComTextoVazio] pass
- [x] 1.5 Refactor `Sources/AnthroIO/SurveyExchange/` (leitura de texto); `swift test` stays green

## 2. REC, DBF e leitura externa

- [x] 2.1 Implement `RECParser` portando `External.ParseRECFile` (descritores, largura no token 8, linhas de 79 caracteres, aparo de espaço e NUL), unit tests first; verified when [tests: recComDoisRegistrosLeLargurasFixas, registroRecEmDuasLinhasFisicasEhJuntado, descritorRecIncompletoFalha] pass
- [x] 2.2 Implement `DBFParser` lendo por bytes a partir do tamanho do cabeçalho, com decodificação de `TextDecoding` por valor, unit tests first; verified when [tests: dbfComDoisRegistrosLeCamposEValores, dbfTruncadoFalha] pass
- [x] 2.3 Implement o descarte de registros DBF marcados com `*` (decisão D8, sujeita ao OK da usuária no red gate); verified when [tests: registroApagadoNoDbfEhIgnorado] pass
- [x] 2.4 Implement `ExternalTableReader` (decodificação, detecção de separador, despacho por tipo); verified when [tests: csvComPontoEVirgulaEVirgulaDecimalLePeso, extensaoDesconhecidaViraXmlEFalha] pass
- [x] 2.5 Refactor leitores externos; `swift test` stays green

## 3. Mapeamento e montagem do inquérito importado

- [x] 3.1 Implement `SurveyImportField` e `ColumnAutoMapper` portando a ordem de testes de `NSImportDialog`; verified when [tests: colunasUsuaisSaoMapeadasAutomaticamente, fatorDePonderacaoSemEspacoViraPeso, duasColunasParaOMesmoCampoUltimaVence] pass
- [x] 3.2 Implement `ExternalSurveyBuilder` portando `Survey.CreateSurveyFromExternalData` sobre `Survey` e `SurveyRecord` da change 5 (sexo obrigatório, descarte com até 10 erros, avisos, fator de ponderação, truncamento e limites de `InputLimits` para peso e altura, edema), unit tests first; verified when [tests: sexoNaoMapeadoFalhaComCampoAusente, sexoMapeadoMontaTodosOsRegistros, dozeRegistrosComSexoInvalidoListamDez, sexoComCodigoDoisEhMenina, dataDeVisitaInvalidaMantemRegistroComAviso, fatorDePonderacaoVazioViraZeroESemMapeamentoUm, edemaNaoInformadoViraFalso, pesoComTresCasasEhTruncado, pesoAbaixoDoMinimoFicaAusenteComAviso, idadeComAsDuasDatasEhDescartadaNaPlanilha] pass
- [x] 3.3 Implement a derivação da medida deitada por `SurveyRecordEvaluation.ageInDays` e a seção `Imported` com `AdditionalDataXML.encode` da change 6; verified when [tests: idadeAbaixoDe731DiasMarcaDeitado, semIdadeComAlturaDeCorteDecidePorOitentaESete, semIdadeESemAlturaMarcaEmPe, duasColunasExtrasViramVariaveisImportadas, todasAsColunasMapeadasNaoCriamVariaveis] pass
- [x] 3.4 Refactor `ExternalSurveyBuilder`; `swift test` stays green

## 4. XML e exportação delimitada de inquéritos

- [x] 4.1 Implement `SurveyXML.data` portando `Survey.ExportSurveysToXML` (`Options` por `SurveyOptions.xml()`, `AdditionalData` sempre presente com `<Data />` padrão, `CreatedBy` fixo, idade de `SurveyRecordEvaluation.ageInMonths` com 10 casas, resultados de `SurveyRecordEvaluation` com `resultsEngine`); verified when [tests: inqueritoComRegistrosEResultadosTemTodosOsAtributos, inqueritoSemRegistrosNaoTemFilhos, createdByNaExportacaoDeInqueritoEhFixo] pass
- [x] 4.2 Implement `SurveyXML.read` portando `Survey.ImportSurveysFromXML` (obrigatórios, opcionais ausentes, `HC`, truncamentos, `SurveyOptions(xml:)`, `AdditionalDataXML.decode`, `CreatedBy` lido e descartado), unit tests first; verified when [tests: createdByLidoNoXmlDeInqueritoEhDescartado, xmlComDoisInqueritosELido, fatorDePonderacaoDoXmlNaoEhTruncado, registroSemCreatedByRejeitaOArquivo, opcoesMalformadasRejeitamOArquivo, arquivoDoWhoAnthroConverteDiasEmMeses, arquivoDoAnthroPlusLeIdadeEmMeses, exportarERelerInqueritoPreservaCampos, inqueritoComDadosAdicionaisNaIdaEVolta, idadeComAsDuasDatasEhDescartadaNoXml] pass
- [x] 4.3 Implement `SurveyDelimitedExport` portando `Survey.ExportSurveyToDelimitedFile` (18 colunas, resultados por `SurveyRecordEvaluation`, colunas de `AdditionalDataColumns.structure` com as colunas fixas como chaves proibidas, valores por `AdditionalValueText`, idade com 10 casas); verified when [tests: cabecalhoDoInqueritoTem18ColunasNaOrdem, cabecalhoComResultadosEDadosAdicionaisTem23Campos, idadeCalculadaPelasDatasComDezCasas, idadeDesconhecidaSaiVazia] pass
- [x] 4.4 Refactor `SurveyXML` e `SurveyDelimitedExport`; `swift test` stays green

## 5. Adaptador de repositório e modelo da tela

- [x] 5.1 Implement `RepositorySurveyExchange` sobre `SurveyRepository` da change 5 (leitura por `survey(id:)` e `records(surveyID:)`, gravação por `save(_:records:)` com `id` zerado), com `insertAll` dentro de um único `AnthroDatabase.transaction`, unit tests first; verified when [tests: doisInqueritosGravadosNumaTransacao, sexoInvalidoNoXmlNaoGravaNada, falhaNaGravacaoDoSegundoInqueritoDesfazTudo] pass
- [x] 5.2 Implement `SurveyExchangeModel` (fases, proposta de mapeamento, rascunho por `SurveyDraftPresenter`, mensagens pt-BR, exportação com aviso de inquérito único); verified when [tests: importarCsvAteORascunhoNaoGrava, cancelarOMapeamentoVoltaAoInicioSemRascunho, avisoDeRegistrosDescartadosListaLinhaECampo, avisoSoDeCamposInvalidos, importacaoLimpaTerminaSemAviso, doisInqueritosEmCsvExportaSoOPrimeiro, doisInqueritosEmXmlExportaAmbos] pass
- [x] 5.3 Ligar a toolbar e o menu do Inquérito nutricional (Importar, folha de mapeamento com um seletor por campo, Exportar com escolha de formato e pergunta sobre resultados) ao `SurveyExchangeModel`, e o editor da change 5 como `SurveyDraftPresenter` (por `SurveyModuleModel.openDraft`, D18); verified when `scripts/build-app.sh` termina com código 0 (verificação visual manual registrada como N/A non-executable)
- [x] 5.4 Refactor `Sources/AnthroFeatures/SurveyExchange/`; `swift test` stays green

## 6. Verification

- [x] 6.1 Mutation check for survey-data-exchange (leitura): remover o salto de espaços iniciais em `DelimitedParser`, see `espacoInicialEAspasDuplicadasSaoTratados` fail, revert
- [x] 6.2 Mutation check for survey-data-exchange (montagem): trocar o limite de erros listados de 10 para 20, see `dozeRegistrosComSexoInvalidoListamDez` fail, revert
- [x] 6.3 Mutation check for survey-data-exchange (XML): ignorar o atributo `HC`, see `arquivoDoWhoAnthroConverteDiasEmMeses` fail, revert
- [x] 6.4 Mutation check for survey-data-exchange (gravação): remover o `transaction` de `RepositorySurveyExchange.insertAll`, see `falhaNaGravacaoDoSegundoInqueritoDesfazTudo` fail, revert
- [x] 6.5 Run the full suite fresh (`swift test`); all green, output free of errors and warnings

## Workflow follow-up

- Produce evidence.md (`openspec instructions evidence --change add-survey-import-export`) and reach `DECISION: PASS`
- Archive the change
- Commits de autoria do usuário, sem linha Co-Authored-By
