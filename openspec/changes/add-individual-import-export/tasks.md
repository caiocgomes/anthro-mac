# Tasks

## 0. Red gate

- [x] 0.1 Write every scenario test from tests.md and stubs with the exact signatures from Interface Under Test (neutral return values, no logic), including the fixture `Tests/AnthroIOTests/Fixtures/ia-original-ptbr.xml` and the builders in `Tests/AnthroIOTests/Support/ExchangeFixtures.swift`
- [x] 0.2 Run the scenario tests; confirm each FAILS BY ASSERTION (not import, syntax or collection errors); record each failure excerpt in the ledger
- [x] 0.3 Commit tests and stubs only as `test(red): add-individual-import-export`; write the SHA in the ledger
- [x] 0.4 STOP: show the user the failing tests and wait for explicit approval before implementing (registrado sem parada: a parada vale só para as changes que fixam números clínicos, decisão do Caio de 14/10/2026)

## 1. Campos e escritor delimitado

- [x] 1.1 Implement `FieldWriter` (datas, booleanos, sexo, medida, decimais com estilo, inteiros, texto) portando `ImportExport.WriteField`, unit tests first (inner loop); verified when [tests: dataSexoEMedidaUsamCodigosDoOriginal, decimalEmCsvUsaVirgulaEEmXmlUsaPonto] pass
- [x] 1.2 Implement `FieldParser` portando `ImportExport.ParseField` (nulos, truncamento `SymetricCrop`, limites, sexo, medida, booleanos, lista fixa de formatos de data não leniente), unit tests first; verified when [tests: variacoesDeSexoAceitasNaImportacao, decimalComVirgulaEhLidoComoPonto, formatosDeDataAceitosDescartamHora] pass
- [x] 1.3 Implement `ImportFailure`, `ImportFieldError`, `ImportFailureDetail`, `DelimitedFormat` e `DelimitedWriter` (aspas mínimas, CRLF, BOM) portando `Delimited.WriteToStream` e `WriteItem`; verified when [tests: valorComAspasEDuplicadoEPontoEVirgulaNoTxtSemAspas] pass
- [x] 1.4 Refactor `Sources/AnthroIO/Exchange/` (campos e delimitado); `swift test` stays green

## 2. Exportação delimitada de crianças

- [x] 2.1 Implement `ExchangeResultsCalculator` sobre `AnthroEngine` e `Anthropometry` (z como `Visit.AnthroResult`, IMC como `GetBMI`), unit tests first; verified when [tests: imcExportadoUsaAMedidaAjustadaEmQualquerIdade, resultadosComEdemaMantemSoEstatura] pass
- [x] 2.2 Implement `AdditionalValueText` (texto, número com estilo decimal, data `dd-MM-yyyy HH:mm:ss`), unit tests first; verified when its unit tests pass
- [x] 2.3 Implement `ChildDelimitedExport` (43 colunas, resultados, colunas de `AdditionalDataColumns.structure` com as colunas fixas como chaves proibidas, `CreatedBy` fixo, SALB vazio, uma linha por visita, criança sem visita) portando `Child.ExportChildrenToDelimitedFile`; verified when [tests: cabecalhoSemResultadosTem43ColunasNaOrdemOriginal, cabecalhoComResultadosAcrescentaWazHazBazBmi, criancaComTresVisitasGeraTresLinhasRepetindoDados, criancaSemVisitasGeraUmaLinhaComVisitaVazia, valorComOSeparadorNoCsvVaiEntreAspasComBom, alturaDaMaeAusenteSaiVazia, colisoesDeNomeComColunasFixasRecebemSufixo, visitaSemDadosAdicionaisDeixaColunasVazias, createdByESalbNaExportacaoSaoFixos] pass
- [x] 2.4 Refactor `ChildDelimitedExport`; `swift test` stays green

## 3. XML de crianças

- [x] 3.1 Implement `ChildXML.data` portando `Child.ExportChildrenToXML` (elementos condicionais, `AdditionalData` sempre presente por `AdditionalDataXML.encode`, `CreatedBy` fixo, SALB vazio, resultados opcionais); verified when [tests: criancaCompletaComUmaVisitaTemElementosEAtributos, criancaSemVisitasNoXmlNaoTemFilhos, visitaSemDadosAdicionaisNoXmlTemAtributoVazio] pass
- [x] 3.2 Implement `ChildXML.read` com `XMLParser` portando `Child.ImportChildrenFromXML` (obrigatórios, opcionais ausentes, limites de `InputLimits`, truncamentos, `CreatedBy` e SALB lidos e descartados, detalhe de linha, elemento e atributo), unit tests first; verified when [tests: createdByESalbLidosSaoDescartados, sexoNaoReconhecidoRejeitaOArquivo, dataIlegivelRejeitaOArquivo, nomeLongoEPesoComTresCasasSaoTruncados, truncamentoLevaOPesoAbaixoDoMinimoERejeita, visitaAntesDoNascimentoRejeita, visitaNaDataDoNascimentoEhAceita, atributoOpcionalAusenteEhAceitoComoNil, arquivoNoLayoutDoOriginalComVirgulaDecimalEhLido] pass
- [x] 3.3 Implement a checagem de datas crescentes portando `Child.CheckImportedVisitDates`; verified when [tests: duasVisitasNaMesmaDataRejeitaComValorInvalido, visitasForaDeOrdemRejeitaComValorInvalido, visitasEmOrdemCrescenteSaoAceitas] pass
- [x] 3.4 Implement a leitura de `AdditionalData` com `AdditionalDataXML.decode` da change 6 (erro rejeita o arquivo); verified when [tests: dadosAdicionaisValidosSaoGuardados, dadosAdicionaisMalformadosRejeitam, exportarEReimportarPreservaTodosOsCampos] pass
- [x] 3.5 Refactor `ChildXML`; `swift test` stays green

## 4. Relatório da criança

- [x] 4.1 Implement `L10n.Exchange` com os rótulos do relatório e as mensagens de importação em pt-BR; verified when `swift build` termina com código 0 e o teste de `L10n` da change 1 (nenhuma string vazia) passa
- [x] 4.2 Implement `ChildReport` portando `IAMain.GenerateChildReport` (cabeçalho, linhas de visita, idade `Xa Ym`, meses truncados, UTF-16 LE com BOM, nome sugerido), unit tests first; verified when [tests: relatorioComDuasVisitasNumeraLinhasEFormataCampos, idadeFormatadaEmAnosEMesesTruncaMeses, zScoreIndefinidoNoRelatorioDeixaCampoVazio, bytesIniciaisEQuebrasDeLinhaDoRelatorioSaoUtf16BomECrlf, nomeSugeridoSemSobrenomeOmiteVirgula] pass
- [x] 4.3 Refactor `ChildReport`; `swift test` stays green

## 5. Adaptador de repositório e modelo da tela

- [x] 5.1 Implement `ChildExchangeMapping` e `RepositoryChildExchange` sobre `ChildRepository`, `VisitRepository`, `ParentRepository`, `AddressRepository` e `AdditionalDataTemplateRepository`, com `insertAll` dentro de um único `AnthroDatabase.transaction`, unit tests first (conversões ida e volta entre `ExchangeChild` e os registros da change 4); verified when [tests: duasCriancasImportadasPreservamDisplayID, falhaNoMeioDaGravacaoDesfazTudo] pass
- [x] 5.2 Implement `ChildExchangeModel` (seleção, `includeResults`, exportação nos três formatos, importação com tradução de falha, relatório) e `ChildExchangeModel.message`; verified when [tests: exportacaoSoComCriancaMarcadaEResultadosDesligados, duasCriancasMarcadasEmCsvGeramTresLinhas, pesoAcimaDoLimiteRejeitaSemGravar, mensagemDeFormatoInvalidoTrazDetalhe, mensagemDeValorInvalidoEmPtBr] pass
- [ ] 5.3 Ligar a toolbar e o menu da Avaliação individual (Importar, Exportar com escolha de formato e pergunta sobre resultados, Relatório da criança) ao `ChildExchangeModel` com `NSOpenPanel` e `NSSavePanel`; verified when `scripts/build-app.sh` termina com código 0 (verificação visual manual registrada como N/A non-executable)
- [ ] 5.4 Refactor `Sources/AnthroFeatures/IndividualExchange/`; `swift test` stays green

## 6. Verification

- [ ] 6.1 Mutation check for individual-data-exchange (formato): trocar o separador do CSV para `,` em `DelimitedFormat.semicolonCSV`, see `cabecalhoSemResultadosTem43ColunasNaOrdemOriginal` fail, revert
- [ ] 6.2 Mutation check for individual-data-exchange (importação): trocar `<=` por `<` na checagem de datas de visita, see `duasVisitasNaMesmaDataRejeitaComValorInvalido` fail, revert
- [ ] 6.3 Mutation check for individual-data-exchange (gravação): remover o `transaction` de `RepositoryChildExchange.insertAll`, see `falhaNoMeioDaGravacaoDesfazTudo` fail, revert
- [ ] 6.4 Run the full suite fresh (`swift test`); all green, output free of errors and warnings

## Workflow follow-up

- Produce evidence.md (`openspec instructions evidence --change add-individual-import-export`) and reach `DECISION: PASS`
- Archive the change
- Commits de autoria do usuário, sem linha Co-Authored-By
