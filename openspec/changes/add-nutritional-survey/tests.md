# Tests

## Test Strategy

- **Framework**: swift-testing (`import Testing`, `@Test`, `#expect`, `#require`), com `@MainActor` nos testes de view model.
- **Full-suite command**: `swift test`
- **Conventions**: um arquivo por área. Banco real em arquivo temporário (`AnthroDatabase.open(at: FileManager.default.temporaryDirectory.appending(path: UUID().uuidString + ".sqlite"))`), nunca mock do banco. Motor real (`AnthroEngine.shared()`, já entregue por `port-anthro-engine`). Datas criadas por um helper `day("2021-04-01")` ao meio-dia do calendário do usuário (`Calendar.current`), a normalização das changes 3 e 4 (D10 da add-individual-assessment), porque o banco grava o dia de calendário do usuário; meia-noite UTC cairia no dia anterior em São Paulo. A migração 3 entra no commit vermelho como dado de partida, como a migração 2 na change 4: os testes de repositório e de tela semeiam linhas por SQL direto, e com a migração vazia falhariam por erro lançado, não por asserção. O vermelho dos dois testes da migração é observado antes, contra a migração 3 registrada com SQL vazio, e registrado no ledger; depois o SQL é preenchido e o vermelho dos demais é observado. Dados de partida de inquéritos e registros entram por SQL direto (`SurveyFixtures.insertSurvey`, `insertRecord`), nunca pelo repositório em teste. Fixtures de registro em `Tests/AnthroFeaturesTests/Support/SurveyFixtures.swift` e `Tests/AnthroStoreTests/Support/SurveyFixtures.swift`. Asserções sobre opções padrão comparam com valores literais escritos no teste, nunca com `SurveyOptions.default`, para que o stub neutro não passe. Testes de cenário ficam em arquivos com sufixo `ScenarioTests.swift`; testes unitários do laço interno, em arquivos sem esse sufixo.
- **Mutation tool**: manual.

## Spec-to-Test Mapping

### Capability: survey-management

#### Scenario: Inquérito novo salvo com nome e notas vazias
- **Test name**: `newSurveyIsSavedWithTrimmedNameAndNilNotes`
- **Test file**: `Tests/AnthroStoreTests/SurveyRepositoryScenarioTests.swift`
- **Level**: integration
- **Breaks if**: `save` grava o nome sem `trimmingCharacters(in: .whitespaces)` ou grava notas "   " em vez de NULL.
- **Expected red**: expected 1 row in `surveys` with name "Escola A 2026", got 0 rows (stub não grava).

#### Scenario: Nome só com espaços
- **Test name**: `blankSurveyNameThrowsNameRequired`
- **Test file**: `Tests/AnthroStoreTests/SurveyRepositoryScenarioTests.swift`
- **Level**: integration
- **Breaks if**: a validação testa `name.isEmpty` antes de remover espaços.
- **Expected red**: expected error `SurveyStoreError.nameRequired`, got no error.

#### Scenario: Ordem da lista
- **Test name**: `activeSurveysAreOrderedByNameThenID`
- **Test file**: `Tests/AnthroStoreTests/SurveyRepositoryScenarioTests.swift`
- **Level**: integration
- **Breaks if**: a consulta de `list(archived:)` perde `ORDER BY name, id`.
- **Expected red**: expected ids [2, 3, 1], got [].

#### Scenario: Ações dependem da marcação
- **Test name**: `archiveAndDeleteDependOnCheckedSurveys`
- **Test file**: `Tests/AnthroFeaturesTests/SurveyModuleScenarioTests.swift`
- **Level**: acceptance
- **Breaks if**: `canArchive` ou `canDelete` ignoram `checkedIDs` (sempre verdadeiros ou sempre falsos).
- **Expected red**: expected `list.surveys.count == 2`, got 0 (o stub de `reload` não lê o banco).

#### Scenario: Arquivar e restaurar
- **Test name**: `archiveThenRestoreMovesSurveyBetweenLists`
- **Test file**: `Tests/AnthroFeaturesTests/SurveyModuleScenarioTests.swift`
- **Level**: acceptance
- **Breaks if**: `setArchived` grava sempre `is_archived = 1` ou `list(archived:)` ignora o parâmetro.
- **Expected red**: expected archive list to contain "Escola A", got [].

#### Scenario: Arquivar o inquérito aberto
- **Test name**: `archivingOpenSurveyClosesDetail`
- **Test file**: `Tests/AnthroFeaturesTests/SurveyModuleScenarioTests.swift`
- **Level**: acceptance
- **Breaks if**: `archiveChecked` não compara os ids arquivados com `openSurvey?.survey.id`.
- **Expected red**: o teste exige `openSurvey != nil` depois de `open(id:)`, antes de arquivar; contra o stub, expected non-nil openSurvey, got nil.

#### Scenario: Exclusão em cascata
- **Test name**: `deletingSurveyDeletesItsRecords`
- **Test file**: `Tests/AnthroStoreTests/SurveyRepositoryScenarioTests.swift`
- **Level**: integration
- **Breaks if**: a migração 3 perde `ON DELETE CASCADE` ou a abertura do banco perde `PRAGMA foreign_keys = ON`.
- **Expected red**: inquérito e 3 registros semeados por SQL; contra o stub de `delete`, expected 0 rows in `surveys`, got 1.

#### Scenario: Exclusão do inquérito aberto
- **Test name**: `deletingOpenSurveyClosesDetail`
- **Test file**: `Tests/AnthroFeaturesTests/SurveyModuleScenarioTests.swift`
- **Level**: acceptance
- **Breaks if**: `deleteChecked` não fecha o detalhe aberto.
- **Expected red**: o teste exige `openSurvey != nil` antes de excluir; contra o stub, expected non-nil openSurvey, got nil.

#### Scenario: Descartar alterações
- **Test name**: `discardRestoresSavedRecords`
- **Test file**: `Tests/AnthroFeaturesTests/SurveyDetailScenarioTests.swift`
- **Level**: acceptance
- **Breaks if**: `discardChanges` não relê `records(surveyID:)` ou não zera `hasUnsavedChanges`.
- **Expected red**: expected 2 records after discard, got 3.

#### Scenario: Falha no meio do salvamento
- **Test name**: `failedRecordInsertRollsBackSurveyInsert`
- **Test file**: `Tests/AnthroStoreTests/SurveyRepositoryScenarioTests.swift`
- **Level**: integration
- **Breaks if**: `save` grava o inquérito fora da transação que grava os registros.
- **Expected red**: expected error `StoreError.sqlite`, got no error.

#### Scenario: Salvar antes de abrir outro inquérito
- **Test name**: `saveDecisionPersistsThenOpensOtherSurvey`
- **Test file**: `Tests/AnthroFeaturesTests/SurveyModuleScenarioTests.swift`
- **Level**: acceptance
- **Breaks if**: `resolvePending(.save)` abre o inquérito pedido sem chamar `save()` do atual.
- **Expected red**: expected `open(id:)` to return `.needsDecision`, got `.done`.

#### Scenario: Cancelar a troca
- **Test name**: `cancelDecisionKeepsCurrentSurveyDirty`
- **Test file**: `Tests/AnthroFeaturesTests/SurveyModuleScenarioTests.swift`
- **Level**: acceptance
- **Breaks if**: `resolvePending(.cancel)` limpa `hasUnsavedChanges` ou troca o inquérito aberto.
- **Expected red**: expected open survey name "Escola A" with unsaved changes, got `openSurvey == nil`.

#### Scenario: Registro novo
- **Test name**: `newRecordEditorStartsWithOriginalDefaults`
- **Test file**: `Tests/AnthroFeaturesTests/RecordEditorScenarioTests.swift`
- **Level**: acceptance
- **Breaks if**: o fator de peso inicial é 0 ou o nascimento padrão não subtrai um ano de `today`.
- **Expected red**: expected weightingFactor 1 and dateOfBirth 2025-10-14, got 0 and 1970-01-01.

#### Scenario: Registro existente de menino
- **Test name**: `existingBoyRecordLoadsSexAndWeightingFactor`
- **Test file**: `Tests/AnthroFeaturesTests/RecordEditorScenarioTests.swift`
- **Level**: acceptance
- **Breaks if**: o editor ignora o registro recebido e usa os padrões de registro novo.
- **Expected red**: expected sex `.boy` and weightingFactor 0.5, got `.girl` and 0.

#### Scenario: Valores nos limites aceitos e truncados
- **Test name**: `boundaryInputsAreAcceptedAndTruncated`
- **Test file**: `Tests/AnthroFeaturesTests/RecordEditorScenarioTests.swift`
- **Level**: acceptance
- **Breaks if**: o editor avalia o peso com `places: 3`, ou usa intervalo aberto e rejeita 230 cm.
- **Expected red**: expected record weight 20.12, got nil (o stub de `makeRecord` devolve `SurveyRecord()`).

#### Scenario: Valores fora dos limites bloqueiam salvar
- **Test name**: `outOfRangeInputsWarnAndBlockSave`
- **Test file**: `Tests/AnthroFeaturesTests/RecordEditorScenarioTests.swift`
- **Level**: acceptance
- **Breaks if**: `canSave` considera só `.invalid`, ou o fator de peso é avaliado sem o mínimo 0.
- **Expected red**: expected weight outcome `.outOfRange(0.9...275)`, got `.empty` (stub de `outcome(_:)`).

#### Scenario: Texto inválido bloqueia e vazio é aceito
- **Test name**: `invalidTextBlocksSaveButEmptyIsAllowed`
- **Test file**: `Tests/AnthroFeaturesTests/RecordEditorScenarioTests.swift`
- **Level**: acceptance
- **Breaks if**: campo vazio é tratado como `.invalid` e também bloqueia salvar.
- **Expected red**: expected weight outcome `.invalid` for "abc", got `.empty`.

#### Scenario: Fator de peso vazio
- **Test name**: `emptyWeightingFactorIsRequired`
- **Test file**: `Tests/AnthroFeaturesTests/RecordEditorScenarioTests.swift`
- **Level**: acceptance
- **Breaks if**: o fator de peso vazio é aceito como os demais campos e gravado como 0 ou NULL.
- **Expected red**: expected `RecordValidationError` with `.required(.weightingFactor)`, got no error.

#### Scenario: Idade derivada das datas exibida
- **Test name**: `editorAgeTextUsesSharedAgeText`
- **Test file**: `Tests/AnthroFeaturesTests/RecordEditorScenarioTests.swift`
- **Level**: acceptance
- **Breaks if**: o texto usa meses arredondados (61) em vez da parte inteira (60).
- **Expected red**: expected `AgeText.localized(months: 60)`, got "".

#### Scenario: Idade desconhecida
- **Test name**: `editorAgeTextWithoutAgeIsNotAvailable`
- **Test file**: `Tests/AnthroFeaturesTests/RecordEditorScenarioTests.swift`
- **Level**: acceptance
- **Breaks if**: idade desconhecida chama `AgeText.localized(months: 0)` e mostra "Idade: 0m".
- **Expected red**: expected "Idade: N/D", got "".

#### Scenario: Nascimento desconhecido com idade digitada
- **Test name**: `unknownBirthUsesTypedMonthsForResult`
- **Test file**: `Tests/AnthroCoreTests/SurveyRecordEvaluationScenarioTests.swift`
- **Level**: acceptance
- **Breaks if**: `result` ignora `ageInMonths` e usa só as datas.
- **Expected red**: expected ageInDays 1872 and range `.reference`, got nil and `.unknown`.

#### Scenario: Duas datas presentes e idade digitada
- **Test name**: `typedAgeIsDiscardedWhenBothDatesExist`
- **Test file**: `Tests/AnthroFeaturesTests/RecordEditorScenarioTests.swift`
- **Level**: acceptance
- **Breaks if**: `makeRecord` mantém `ageInMonths` quando há nascimento e data da pesquisa.
- **Expected red**: expected ageInMonths nil and ageInDays 1843, got stub record with nil dates and ageInDays nil.

#### Scenario: Sorteio no limite superior
- **Test name**: `approximateBirthDrawsDayBelowLastDayOfMonth`
- **Test file**: `Tests/AnthroFeaturesTests/RecordEditorScenarioTests.swift`
- **Level**: acceptance
- **Breaks if**: o editor chama `ApproximateBirthDate.randomized` com `1..<(diasNoMês + 1)` ou sorteia por conta própria, permitindo 29 de fevereiro de 2016.
- **Expected red**: expected dateOfBirth 2016-02-28, got 2016-02-10 (stub não sorteia).

#### Scenario: Nascimento depois da data da pesquisa
- **Test name**: `birthAfterVisitIsClampedToVisitDate`
- **Test file**: `Tests/AnthroFeaturesTests/RecordEditorScenarioTests.swift`
- **Level**: acceptance
- **Breaks if**: `setDateOfBirth` não passa por `ApproximateBirthDate.adjusted` com a data da pesquisa.
- **Expected red**: expected dateOfBirth 2021-04-01, got 2021-05-10.

#### Scenario: Idade abaixo de 11 meses
- **Test name**: `measureChoiceEnabledBelowElevenMonths`
- **Test file**: `Tests/AnthroFeaturesTests/RecordEditorScenarioTests.swift`
- **Level**: acceptance
- **Breaks if**: o limite muda para `< 10` ou usa meses arredondados em vez da parte inteira.
- **Expected red**: expected `isMeasureChoiceEnabled == true`, got false.

#### Scenario: Idade de 11 meses
- **Test name**: `measureChoiceDisabledAndStandingFromElevenMonths`
- **Test file**: `Tests/AnthroFeaturesTests/RecordEditorScenarioTests.swift`
- **Level**: acceptance
- **Breaks if**: o limite é trocado para 61 meses, como diz a ajuda, ou o modo não é forçado para em pé.
- **Expected red**: o teste primeiro coloca 2020-11-30 e deitado e exige `measuredRecumbent == true`; contra o stub, expected true, got false.

#### Scenario: IMC com idade digitada
- **Test name**: `editorBMIUsesTypedMonthsAdjustment`
- **Test file**: `Tests/AnthroFeaturesTests/RecordEditorScenarioTests.swift`
- **Level**: acceptance
- **Breaks if**: `bmiText` não arredonda a 1 casa ou formata com ponto.
- **Expected red**: expected "16,5", got "".

#### Scenario: IMC com edema
- **Test name**: `editorBMIIsNotAvailableWithOedema`
- **Test file**: `Tests/AnthroFeaturesTests/RecordEditorScenarioTests.swift`
- **Level**: acceptance
- **Breaks if**: `bmiText` ignora `hasOedema`.
- **Expected red**: expected "N/D", got "".

#### Scenario: Próximo ID
- **Test name**: `autoRecordIDIsMaxPlusOne`
- **Test file**: `Tests/AnthroFeaturesTests/SurveyDetailScenarioTests.swift`
- **Level**: acceptance
- **Breaks if**: o cálculo usa `count + 1` em vez de `max + 1`.
- **Expected red**: expected displayID 8, got nil.

#### Scenario: Inquérito sem domicílios
- **Test name**: `autoHouseholdStartsAtOne`
- **Test file**: `Tests/AnthroFeaturesTests/SurveyDetailScenarioTests.swift`
- **Level**: acceptance
- **Breaks if**: o máximo inicial é 1 em vez de 0, produzindo 2.
- **Expected red**: expected household 1, got nil.

#### Scenario: Filtro ativo não reduz o próximo ID
- **Test name**: `autoIDConsidersFilteredRecords`
- **Test file**: `Tests/AnthroFeaturesTests/SurveyDetailScenarioTests.swift`
- **Level**: acceptance
- **Breaks if**: o máximo é calculado sobre `visibleRows` em vez de `allRecords`.
- **Expected red**: expected displayID 8, got nil.

#### Scenario: Atribuição de conglomerado desligada
- **Test name**: `clusterStaysNilWhenAutoIDOff`
- **Test file**: `Tests/AnthroFeaturesTests/SurveyDetailScenarioTests.swift`
- **Level**: acceptance
- **Breaks if**: a atribuição automática é aplicada a todos os campos sem consultar a opção.
- **Expected red**: expected 1 record with cluster nil, got 0 records (stub de `commit` não inclui).

#### Scenario: Valor digitado com atribuição ligada
- **Test name**: `typedIDWinsOverAutoID`
- **Test file**: `Tests/AnthroFeaturesTests/SurveyDetailScenarioTests.swift`
- **Level**: acceptance
- **Breaks if**: a atribuição sobrescreve valores não nulos.
- **Expected red**: expected displayID 2, got 0 records.

#### Scenario: Estatura na mediana pela idade em meses
- **Test name**: `heightAtMedianByTypedMonthsHasZeroZ`
- **Test file**: `Tests/AnthroCoreTests/SurveyRecordEvaluationScenarioTests.swift`
- **Level**: acceptance
- **Breaks if**: a idade digitada é convertida em dias e passada como `ageInDays`, perdendo a linha mensal exata.
- **Expected red**: expected height-for-age z 0.00, got nil.

#### Scenario: Registro sem idade
- **Test name**: `recordWithoutAgeHasUnknownRange`
- **Test file**: `Tests/AnthroCoreTests/SurveyRecordEvaluationScenarioTests.swift`
- **Level**: acceptance
- **Breaks if**: a ausência de data da pesquisa é preenchida com a data de hoje, ou o peso não é repassado ao motor sem idade.
- **Expected red**: expected result weight 18.00, got nil (o stub devolve o resultado do motor com todas as entradas nulas).

#### Scenario: Limite alterado nas opções
- **Test name**: `surveyMaxBoundChangesWeightFlag`
- **Test file**: `Tests/AnthroCoreTests/SurveyPlausibilityScenarioTests.swift`
- **Level**: acceptance
- **Breaks if**: `isFlagged` usa os limites fixos de `Plausibility` em vez de `options.zBounds`.
- **Expected red**: expected flagged true with max 3.5, got false.

#### Scenario: Faixa desconhecida
- **Test name**: `unknownRangeFlagsAllIndicators`
- **Test file**: `Tests/AnthroCoreTests/SurveyPlausibilityScenarioTests.swift`
- **Level**: acceptance
- **Breaks if**: o caso `default` do switch devolve falso.
- **Expected red**: expected `.weightAndLengthOrHeightForAge`, got `.none`.

#### Scenario: 109 meses sem peso
- **Test name**: `weightForAgeAbove108MonthsIsNeverFlagged`
- **Test file**: `Tests/AnthroCoreTests/SurveyPlausibilityScenarioTests.swift`
- **Level**: acceptance
- **Breaks if**: a constante 108 é removida ou trocada por 120.
- **Expected red**: expected BMI-for-age flagged true, got false (o stub de `isFlagged` devolve falso).

#### Scenario: 108 meses sem peso
- **Test name**: `weightForAgeAt108MonthsWithoutWeightIsFlagged`
- **Test file**: `Tests/AnthroCoreTests/SurveyPlausibilityScenarioTests.swift`
- **Level**: acceptance
- **Breaks if**: a comparação usa `>=` 108.
- **Expected red**: expected summary flag `.weightForAge`, got `.none`.

#### Scenario: Linha completa
- **Test name**: `fullRowRendersOriginalFormats`
- **Test file**: `Tests/AnthroFeaturesTests/SurveyTableScenarioTests.swift`
- **Level**: acceptance
- **Breaks if**: o nascimento aproximado não troca o dia por "XX" ou a idade em meses usa 1 casa.
- **Expected red**: expected cell texts ["01/04/2021", "XX/03/2016", "1843", "60,55", ...], got ten empty strings.

#### Scenario: Valores ausentes
- **Test name**: `missingValuesRenderAsEmptyText`
- **Test file**: `Tests/AnthroFeaturesTests/SurveyTableScenarioTests.swift`
- **Level**: acceptance
- **Breaks if**: valores ausentes são renderizados como "N/D" ou "0".
- **Expected red**: expected sex cell "Feminino", got "" (o stub de `text` devolve texto vazio).

#### Scenario: Idade digitada
- **Test name**: `typedAgeRendersDaysAndIsNotDerived`
- **Test file**: `Tests/AnthroFeaturesTests/SurveyTableScenarioTests.swift`
- **Level**: acceptance
- **Breaks if**: a coluna de dias usa `AgeMath.monthsToDays` (mesmo valor aqui) ou marca a célula como derivada.
- **Expected red**: expected "1872", got "" .

#### Scenario: Idade derivada das datas
- **Test name**: `computedAgeRendersAsDerived`
- **Test file**: `Tests/AnthroFeaturesTests/SurveyTableScenarioTests.swift`
- **Level**: acceptance
- **Breaks if**: `isDerived` devolve falso para idade calculada.
- **Expected red**: expected "1843" and isDerived true, got "" and false.

#### Scenario: z de estatura implausível
- **Test name**: `implausibleHeightZIsHighlightedWithFlagText`
- **Test file**: `Tests/AnthroFeaturesTests/SurveyTableScenarioTests.swift`
- **Level**: acceptance
- **Breaks if**: `isHighlighted` usa `SeverityClassifier` em vez da plausibilidade, ou a flag de estatura vira "P/I".
- **Expected red**: expected flag cell "E/I", got "".

#### Scenario: z ausente sem destaque visível
- **Test name**: `missingWeightZIsNotHighlightedButFlagged`
- **Test file**: `Tests/AnthroFeaturesTests/SurveyTableScenarioTests.swift`
- **Level**: acceptance
- **Breaks if**: o destaque é aplicado também quando o z é `nil`.
- **Expected red**: expected flag "P/I", got "".

#### Scenario: Três cliques no peso
- **Test name**: `threeClicksSortAscendingThenReverseTwice`
- **Test file**: `Tests/AnthroFeaturesTests/SurveyTableScenarioTests.swift`
- **Level**: acceptance
- **Breaks if**: o segundo clique reordena em decrescente com ausentes no fim em vez de inverter a lista.
- **Expected red**: expected weights [15, 20, nil], got [20, nil, 15] (stub não ordena).

#### Scenario: z indefinido ordenado primeiro
- **Test name**: `undefinedZSortsAsSmallest`
- **Test file**: `Tests/AnthroFeaturesTests/SurveyTableScenarioTests.swift`
- **Level**: acceptance
- **Breaks if**: o comparador de z trata `nil` como os demais opcionais, mandando para o fim.
- **Expected red**: expected z order [nil, -0.50, 1.00], got [1.00, nil, -0.50].

#### Scenario: Troca de coluna recomeça em ordem crescente
- **Test name**: `newSortColumnRestartsAscending`
- **Test file**: `Tests/AnthroFeaturesTests/SurveyTableScenarioTests.swift`
- **Level**: acceptance
- **Breaks if**: o estado de ordem não é reiniciado ao trocar de coluna, invertendo a lista.
- **Expected red**: expected sortColumn `.fixed(.lengthOrHeight)` ascending, got nil.

#### Scenario: Maior ou igual em peso
- **Test name**: `numericGreaterOrEqualFilterKeepsMatches`
- **Test file**: `Tests/AnthroFeaturesTests/SurveyFilterScenarioTests.swift`
- **Level**: acceptance
- **Breaks if**: a comparação numérica usa `>` em vez de `>=`, ou o texto "20,00" não é lido como número.
- **Expected red**: expected 2 visible rows and "2 registro(s)", got 3 and "".

#### Scenario: Intervalo numérico sem limite superior
- **Test name**: `numericRangeWithEmptyUpperExcludesNumbers`
- **Test file**: `Tests/AnthroFeaturesTests/SurveyFilterScenarioTests.swift`
- **Level**: acceptance
- **Breaks if**: o intervalo numérico trata limite vazio como aberto (diferente do original).
- **Expected red**: o teste exige 3 linhas visíveis antes do filtro; contra o stub, expected 3, got 0.

#### Scenario: Sexo sem diferenciar maiúsculas
- **Test name**: `textEqualityIsCaseInsensitiveAndTrimsValue`
- **Test file**: `Tests/AnthroFeaturesTests/SurveyFilterScenarioTests.swift`
- **Level**: acceptance
- **Breaks if**: o valor não é aparado ou a comparação diferencia maiúsculas.
- **Expected red**: expected 2 visible rows, got 3.

#### Scenario: Célula vazia igual a vazio
- **Test name**: `emptyCellEqualsEmptyValue`
- **Test file**: `Tests/AnthroFeaturesTests/SurveyFilterScenarioTests.swift`
- **Level**: acceptance
- **Breaks if**: célula numérica com valor vazio é comparada como número e mantida.
- **Expected red**: expected 1 visible row, got 3.

#### Scenario: Intervalo de datas com limite superior aberto
- **Test name**: `dateRangeWithOpenUpperBound`
- **Test file**: `Tests/AnthroFeaturesTests/SurveyFilterScenarioTests.swift`
- **Level**: acceptance
- **Breaks if**: o ramo de intervalo de datas exclui incondicionalmente, como na leitura errada do ILSpy.
- **Expected red**: expected only the 2021-01-01 row visible, got 3 rows.

#### Scenario: Comparação de data com valor inválido
- **Test name**: `dateComparisonWithInvalidValueHidesAll`
- **Test file**: `Tests/AnthroFeaturesTests/SurveyFilterScenarioTests.swift`
- **Level**: acceptance
- **Breaks if**: data inválida no valor mantém a célula em vez de excluí-la.
- **Expected red**: o teste exige 3 linhas visíveis antes do filtro; contra o stub, expected 3, got 0.

#### Scenario: Dois filtros e limpeza
- **Test name**: `iterativeFiltersNarrowAndClearRestores`
- **Test file**: `Tests/AnthroFeaturesTests/SurveyFilterScenarioTests.swift`
- **Level**: acceptance
- **Breaks if**: cada filtro parte de `allRecords` em vez de `visibleRows`, ou `clearFilter` não devolve os ocultos.
- **Expected red**: expected 1 visible row after second filter, got 3.

#### Scenario: Limpar sem filtro ativo
- **Test name**: `clearWithoutFilterIsNoOp`
- **Test file**: `Tests/AnthroFeaturesTests/SurveyFilterScenarioTests.swift`
- **Level**: acceptance
- **Breaks if**: `clearFilter` duplica registros ao reinserir uma lista de ocultos já incorporada.
- **Expected red**: expected 3 visible rows, got 0.

#### Scenario: Duas linhas selecionadas
- **Test name**: `clipboardHasHeaderAndSelectedRowsInTableOrder`
- **Test file**: `Tests/AnthroFeaturesTests/SurveyTableScenarioTests.swift`
- **Level**: acceptance
- **Breaks if**: as linhas terminam em "\n" em vez de "\t\r\n" ou saem na ordem inversa.
- **Expected red**: expected 3 lines, got "" (0 lines).

#### Scenario: Nenhuma linha selecionada
- **Test name**: `clipboardWithoutSelectionHasOnlyHeader`
- **Test file**: `Tests/AnthroFeaturesTests/SurveyTableScenarioTests.swift`
- **Level**: acceptance
- **Breaks if**: a linha de cabeçalho só é gerada quando há seleção.
- **Expected red**: expected header line with 19 titles, got "".

#### Scenario: Linha selecionada
- **Test name**: `selectingRowExposesResultAndSeverity`
- **Test file**: `Tests/AnthroFeaturesTests/SurveyTableScenarioTests.swift`
- **Level**: acceptance
- **Breaks if**: `select` guarda o índice mas não o resultado, ou `severity` usa o percentil.
- **Expected red**: expected severity `.high`, got `.undefined`.

#### Scenario: Seleção removida
- **Test name**: `deletingSelectedRowClearsResult`
- **Test file**: `Tests/AnthroFeaturesTests/SurveyTableScenarioTests.swift`
- **Level**: acceptance
- **Breaks if**: `deleteRecords` não limpa `selectedResult`.
- **Expected red**: o teste exige `selectedResult != nil` depois de selecionar; contra o stub, expected non-nil, got nil.

#### Scenario: Opções de um inquérito novo
- **Test name**: `newSurveyHasLiteralDefaultOptions`
- **Test file**: `Tests/AnthroCoreTests/SurveyOptionsScenarioTests.swift`
- **Level**: acceptance
- **Breaks if**: a lista padrão de fronteiras perde o 228 repetido ou o mínimo de IMC muda.
- **Expected red**: expected 22 boundaries and referenceMinZ[2] -5, got 0 boundaries.

#### Scenario: XML sem chaves
- **Test name**: `emptyOptionsXMLYieldsDefaults`
- **Test file**: `Tests/AnthroCoreTests/SurveyOptionsScenarioTests.swift`
- **Level**: acceptance
- **Breaks if**: chave ausente vira valor vazio em vez do padrão.
- **Expected red**: expected autoIDRecord true and 22 boundaries, got false and 0.

#### Scenario: Gravação das opções padrão
- **Test name**: `defaultOptionsSerializeToExactXML`
- **Test file**: `Tests/AnthroCoreTests/SurveyOptionsScenarioTests.swift`
- **Level**: acceptance
- **Breaks if**: booleanos saem como "true" minúsculo ou a ordem das chaves muda.
- **Expected red**: expected the exact `<Opt>...</Opt>` string, got "".

#### Scenario: XML malformado
- **Test name**: `malformedOptionsXMLThrows`
- **Test file**: `Tests/AnthroCoreTests/SurveyOptionsScenarioTests.swift`
- **Level**: acceptance
- **Breaks if**: o parser devolve padrões em vez de lançar diante de XML inválido.
- **Expected red**: expected `SurveyOptionsError.invalidXML`, got no error.

#### Scenario: Limite legado preservado sem conversão
- **Test name**: `legacyMinZBoundsKeepOriginalValues`
- **Test file**: `Tests/AnthroCoreTests/SurveyOptionsScenarioTests.swift`
- **Level**: acceptance
- **Breaks if**: a conversão do Anthro II é aplicada (descartar o primeiro elemento), dando -6 para peso.
- **Expected red**: expected standards min weight -5, got nil (stub de `zBounds` devolve nil).

#### Scenario: Chave legada e nova juntas
- **Test name**: `legacyAndNewKeyTogetherThrow`
- **Test file**: `Tests/AnthroCoreTests/SurveyOptionsScenarioTests.swift`
- **Level**: acceptance
- **Breaks if**: a segunda chave sobrescreve a primeira em silêncio.
- **Expected red**: expected `SurveyOptionsError.invalidXML`, got no error.

#### Scenario: Faixas padrão
- **Test name**: `defaultBoundariesYieldTwentyOneGroups`
- **Test file**: `Tests/AnthroCoreTests/SurveyOptionsScenarioTests.swift`
- **Level**: acceptance
- **Breaks if**: a última faixa usa $b_n - 1$ como as demais (228 a 227).
- **Expected red**: expected 21 groups, got 0.

#### Scenario: Fronteiras mínimas
- **Test name**: `threeBoundariesYieldTwoGroups`
- **Test file**: `Tests/AnthroCoreTests/SurveyOptionsScenarioTests.swift`
- **Level**: acceptance
- **Breaks if**: o laço gera uma faixa a menos com três fronteiras.
- **Expected red**: expected [(0, 60), (61, 228)], got [].

#### Scenario: Menos de duas faixas
- **Test name**: `applyingWithOneAgeGroupThrowsTooFew`
- **Test file**: `Tests/AnthroFeaturesTests/SurveyOptionsEditorScenarioTests.swift`
- **Level**: acceptance
- **Breaks if**: o mínimo exigido cai para 1 faixa.
- **Expected red**: expected `SurveyOptionsEditorError.tooFewAgeGroups`, got no error.

#### Scenario: Limites inferiores repetidos
- **Test name**: `repeatedLowerBoundsThrowInconsistent`
- **Test file**: `Tests/AnthroFeaturesTests/SurveyOptionsEditorScenarioTests.swift`
- **Level**: acceptance
- **Breaks if**: a validação aceita inferiores iguais (`>=` no lugar de `>`).
- **Expected red**: expected `SurveyOptionsEditorError.inconsistentAgeGroups`, got no error.

#### Scenario: Máximo abaixo do mínimo
- **Test name**: `maxBelowMinIsRaisedToMin`
- **Test file**: `Tests/AnthroFeaturesTests/SurveyOptionsEditorScenarioTests.swift`
- **Level**: acceptance
- **Breaks if**: `setZBound(text:)` grava o máximo sem comparar com o mínimo.
- **Expected red**: expected max -6, got 0.

#### Scenario: Mínimo acima do máximo e limite fora da faixa
- **Test name**: `minAboveMaxIsLoweredAndOutOfRangeBoundBlocksApply`
- **Test file**: `Tests/AnthroFeaturesTests/SurveyOptionsEditorScenarioTests.swift`
- **Level**: acceptance
- **Breaks if**: o máximo "120" é aceito, ou ajustado para 99 em vez de ficar com aviso e bloquear `apply()`.
- **Expected red**: expected min 5, got 0 (stub de `zBound`).

#### Scenario: Restaurar depois de alterar
- **Test name**: `resetRestoresLiteralDefaults`
- **Test file**: `Tests/AnthroFeaturesTests/SurveyOptionsEditorScenarioTests.swift`
- **Level**: acceptance
- **Breaks if**: `resetToDefaults` restaura só os limites de z (`ResetZBoundsToDefault`) e mantém a atribuição de equipe.
- **Expected red**: expected applied autoIDTeam false and 22 boundaries, got the stub's empty options.

#### Scenario: Restaurar sem alterações
- **Test name**: `resetOnDefaultsKeepsLiteralDefaults`
- **Test file**: `Tests/AnthroFeaturesTests/SurveyOptionsEditorScenarioTests.swift`
- **Level**: acceptance
- **Breaks if**: `resetToDefaults` zera as faixas etárias.
- **Expected red**: expected 22 boundaries, got 0.

#### Scenario: Aplicar recalcula flags
- **Test name**: `applyingOptionsRecomputesHighlights`
- **Test file**: `Tests/AnthroFeaturesTests/SurveyDetailScenarioTests.swift`
- **Level**: acceptance
- **Breaks if**: `applyOptions` troca as opções mas não reconstrói `visibleRows`.
- **Expected red**: expected weight-for-age z highlighted, got false.

#### Scenario: Cancelar descarta a atribuição automática
- **Test name**: `cancellingOptionsEditorKeepsSurveyOptions`
- **Test file**: `Tests/AnthroFeaturesTests/SurveyDetailScenarioTests.swift`
- **Level**: acceptance
- **Breaks if**: o editor de opções recebe as opções do inquérito por referência e as altera ao editar.
- **Expected red**: expected `options.autoIDRecord == true`, got false (o stub do detalhe guarda opções neutras).

#### Scenario: Ida e volta de um registro completo
- **Test name**: `recordRoundTripsWithoutLoss`
- **Test file**: `Tests/AnthroStoreTests/SurveyRepositoryScenarioTests.swift`
- **Level**: integration
- **Breaks if**: o fator de peso é gravado como REAL, perdendo dígitos, ou `has_oedema` NULL é lido como falso.
- **Expected red**: expected reloaded record equal to saved, got [] from `records(surveyID:)`.

#### Scenario: Ordem de inclusão
- **Test name**: `recordsKeepInsertionOrder`
- **Test file**: `Tests/AnthroFeaturesTests/SurveyDetailScenarioTests.swift`
- **Level**: acceptance
- **Breaks if**: a consulta ordena por `id` depois de reordenações, ou ignora `position`.
- **Expected red**: expected first names ["A", "B", "C"], got [].

#### Scenario: Definição copiada
- **Test name**: `newRecordCopiesSurveyAdditionalDataDefinition`
- **Test file**: `Tests/AnthroFeaturesTests/RecordEditorScenarioTests.swift`
- **Level**: acceptance
- **Breaks if**: o editor de registro novo inicia o XML como nil.
- **Expected red**: expected additionalDataXML `<Data><Cat ID="Escola" Descr="" /></Data>`, got nil.

#### Scenario: Inquérito sem definição
- **Test name**: `newRecordWithoutDefinitionGetsEmptyData`
- **Test file**: `Tests/AnthroFeaturesTests/RecordEditorScenarioTests.swift`
- **Level**: acceptance
- **Breaks if**: a ausência de definição propaga nil em vez de `<Data />`.
- **Expected red**: expected `<Data />`, got nil.

#### Scenario: Banco migrado
- **Test name**: `migrationThreeCreatesSurveyTables`
- **Test file**: `Tests/AnthroStoreTests/SurveyMigrationScenarioTests.swift`
- **Level**: integration
- **Breaks if**: `Migrations.survey` não é registrada em `Migrations.all`.
- **Expected red**: contra a migração 3 com SQL vazio, expected `sqlite_master` to contain `surveys` and `records`, got neither (ver Conventions).

#### Scenario: Sexo inválido
- **Test name**: `invalidSexIsRejectedByConstraint`
- **Test file**: `Tests/AnthroStoreTests/SurveyMigrationScenarioTests.swift`
- **Level**: integration
- **Breaks if**: a coluna `sex` perde o `CHECK (sex IN (1, 2))`.
- **Expected red**: o teste exige que a mensagem do `StoreError.sqlite` contenha "CHECK constraint failed"; contra a migração 3 com SQL vazio, got "no such table: surveys" (ver Conventions).

## Coverage Ledger

| Capability | Scenario | Test file | Test name | Breaks if | Red (SHA: failure) | Green (SHA) | State |
|------------|----------|-----------|-----------|-----------|--------------------|-------------|-------|
| survey-management | Inquérito novo salvo com nome e notas vazias | Tests/AnthroStoreTests/SurveyRepositoryScenarioTests.swift | newSurveyIsSavedWithTrimmedNameAndNilNotes | nome sem trim ou notas não nulas | 143cda8: SurveyRepositoryScenarioTests.swift:21: Expectation failed: (rows.count → 0) == 1 | e0d8e1f | green |
| survey-management | Nome só com espaços | Tests/AnthroStoreTests/SurveyRepositoryScenarioTests.swift | blankSurveyNameThrowsNameRequired | validação antes do trim | 143cda8: SurveyRepositoryScenarioTests.swift:28: Expectation failed: an error was expected but none was thrown and "(survey: AnthroCore.Survey(id: nil, name... | e0d8e1f | green |
| survey-management | Ordem da lista | Tests/AnthroStoreTests/SurveyRepositoryScenarioTests.swift | activeSurveysAreOrderedByNameThenID | perde ORDER BY name, id | 143cda8: SurveyRepositoryScenarioTests.swift:37: Expectation failed: try repository.list(archived: false).map(\.id) == [firstA, secondA, b] | e0d8e1f | green |
| survey-management | Ações dependem da marcação | Tests/AnthroFeaturesTests/SurveyModuleScenarioTests.swift | archiveAndDeleteDependOnCheckedSurveys | ações ignoram a marcação | 143cda8: SurveyModuleScenarioTests.swift:32: Expectation failed: (m.list.surveys.count → 0) == 2 | cc5b56b | green |
| survey-management | Arquivar e restaurar | Tests/AnthroFeaturesTests/SurveyModuleScenarioTests.swift | archiveThenRestoreMovesSurveyBetweenLists | is_archived fixo | 143cda8: SurveyModuleScenarioTests.swift:48: Expectation failed: (names(m) → []) == ["Escola B"] | cc5b56b | green |
| survey-management | Arquivar o inquérito aberto | Tests/AnthroFeaturesTests/SurveyModuleScenarioTests.swift | archivingOpenSurveyClosesDetail | detalhe não fecha | 143cda8: SurveyModuleScenarioTests.swift:65: Expectation failed: (m.openSurvey → nil) != nil | cc5b56b | green |
| survey-management | Exclusão em cascata | Tests/AnthroStoreTests/SurveyRepositoryScenarioTests.swift | deletingSurveyDeletesItsRecords | sem ON DELETE CASCADE | 143cda8: SurveyRepositoryScenarioTests.swift:48: Expectation failed: try SurveyFixtures.count(db, "surveys", where: "id = \(id)") == 0 | e0d8e1f | green |
| survey-management | Exclusão do inquérito aberto | Tests/AnthroFeaturesTests/SurveyModuleScenarioTests.swift | deletingOpenSurveyClosesDetail | detalhe não fecha | 143cda8: SurveyModuleScenarioTests.swift:76: Expectation failed: (m.openSurvey → nil) != nil | cc5b56b | green |
| survey-management | Descartar alterações | Tests/AnthroFeaturesTests/SurveyDetailScenarioTests.swift | discardRestoresSavedRecords | não relê do banco | 143cda8: SurveyDetailScenarioTests.swift:35: Expectation failed: (m.allRecords.count → 0) == 3 | 21ca427 | green |
| survey-management | Falha no meio do salvamento | Tests/AnthroStoreTests/SurveyRepositoryScenarioTests.swift | failedRecordInsertRollsBackSurveyInsert | inquérito fora da transação | 143cda8: SurveyRepositoryScenarioTests.swift:56: Expectation failed: an error was expected but none was thrown and "(survey: AnthroCore.Survey(id: nil, name... | e0d8e1f | green |
| survey-management | Salvar antes de abrir outro inquérito | Tests/AnthroFeaturesTests/SurveyModuleScenarioTests.swift | saveDecisionPersistsThenOpensOtherSurvey | abre sem salvar | 143cda8: SurveyModuleScenarioTests.swift:89: Expectation failed: (m → AnthroFeatures.SurveyModuleModel).openSurvey → nil → nil | cc5b56b | green |
| survey-management | Cancelar a troca | Tests/AnthroFeaturesTests/SurveyModuleScenarioTests.swift | cancelDecisionKeepsCurrentSurveyDirty | cancelar limpa pendência | 143cda8: SurveyModuleScenarioTests.swift:105: Expectation failed: (m → AnthroFeatures.SurveyModuleModel).openSurvey → nil → nil | cc5b56b | green |
| survey-management | Registro novo | Tests/AnthroFeaturesTests/RecordEditorScenarioTests.swift | newRecordEditorStartsWithOriginalDefaults | fator 0 ou nascimento sem menos um ano | 143cda8: RecordEditorScenarioTests.swift:27: Expectation failed: (e.text(.weightingFactor) → "") == "1" | aef8629 | green |
| survey-management | Registro existente de menino | Tests/AnthroFeaturesTests/RecordEditorScenarioTests.swift | existingBoyRecordLoadsSexAndWeightingFactor | ignora registro recebido | 143cda8: RecordEditorScenarioTests.swift:42: Expectation failed: (e.sex → .girl) == .boy | aef8629 | green |
| survey-management | Valores nos limites aceitos e truncados | Tests/AnthroFeaturesTests/RecordEditorScenarioTests.swift | boundaryInputsAreAcceptedAndTruncated | places 3 ou intervalo aberto | 143cda8: RecordEditorScenarioTests.swift:65: Expectation failed: (e → AnthroFeatures.RecordEditorModel).canSave → false | aef8629 | green |
| survey-management | Valores fora dos limites bloqueiam salvar | Tests/AnthroFeaturesTests/RecordEditorScenarioTests.swift | outOfRangeInputsWarnAndBlockSave | canSave ignora fora do intervalo | 143cda8: RecordEditorScenarioTests.swift:78: Expectation failed: (e.outcome(.weight) → .empty) == (.outOfRange(num("0.9")...275) → .outOfRange(ClosedRange(0... | aef8629 | green |
| survey-management | Texto inválido bloqueia e vazio é aceito | Tests/AnthroFeaturesTests/RecordEditorScenarioTests.swift | invalidTextBlocksSaveButEmptyIsAllowed | vazio bloqueia salvar | 143cda8: RecordEditorScenarioTests.swift:91: Expectation failed: (e.outcome(.weight) → .empty) == .invalid | aef8629 | green |
| survey-management | Fator de peso vazio | Tests/AnthroFeaturesTests/RecordEditorScenarioTests.swift | emptyWeightingFactorIsRequired | fator vazio aceito | 143cda8: RecordEditorScenarioTests.swift:105: Expectation failed: an error was expected but none was thrown and "SurveyRecord(id: nil, visitDate: nil, clust... | aef8629 | green |
| survey-management | Idade derivada das datas exibida | Tests/AnthroFeaturesTests/RecordEditorScenarioTests.swift | editorAgeTextUsesSharedAgeText | meses arredondados | 143cda8: RecordEditorScenarioTests.swift:116: Expectation failed: (e.ageText → "") == (AgeText.localized(months: 60) → "Idade: 5a 0m (60m)") | aef8629 | green |
| survey-management | Idade desconhecida | Tests/AnthroFeaturesTests/RecordEditorScenarioTests.swift | editorAgeTextWithoutAgeIsNotAvailable | mostra 0m | 143cda8: RecordEditorScenarioTests.swift:123: Expectation failed: (e.ageText → "") == "Idade: N/D" | aef8629 | green |
| survey-management | Nascimento desconhecido com idade digitada | Tests/AnthroCoreTests/SurveyRecordEvaluationScenarioTests.swift | unknownBirthUsesTypedMonthsForResult | ignora ageInMonths | 143cda8: SurveyRecordEvaluationScenarioTests.swift:20: Expectation failed: (result.ageInDays → nil) == 1872 | a1483d0 | green |
| survey-management | Duas datas presentes e idade digitada | Tests/AnthroFeaturesTests/RecordEditorScenarioTests.swift | typedAgeIsDiscardedWhenBothDatesExist | mantém idade digitada | 143cda8: RecordEditorScenarioTests.swift:134: Expectation failed: (record.dateOfBirth.map(ymd) → nil) == "2016-03-15" | aef8629 | green |
| survey-management | Sorteio no limite superior | Tests/AnthroFeaturesTests/RecordEditorScenarioTests.swift | approximateBirthDrawsDayBelowLastDayOfMonth | inclui o último dia | 143cda8: RecordEditorScenarioTests.swift:146: Expectation failed: (ymd(e.dateOfBirth) → "1969-12-31") == "2016-02-28" | aef8629 | green |
| survey-management | Nascimento depois da data da pesquisa | Tests/AnthroFeaturesTests/RecordEditorScenarioTests.swift | birthAfterVisitIsClampedToVisitDate | sem comparação com a visita | 143cda8: RecordEditorScenarioTests.swift:156: Expectation failed: (ymd(e.dateOfBirth) → "1969-12-31") == "2021-04-01" | aef8629 | green |
| survey-management | Idade abaixo de 11 meses | Tests/AnthroFeaturesTests/RecordEditorScenarioTests.swift | measureChoiceEnabledBelowElevenMonths | limite 10 ou meses arredondados | 143cda8: RecordEditorScenarioTests.swift:166: Expectation failed: (e → AnthroFeatures.RecordEditorModel).isMeasureChoiceEnabled → false | aef8629 | green |
| survey-management | Idade de 11 meses | Tests/AnthroFeaturesTests/RecordEditorScenarioTests.swift | measureChoiceDisabledAndStandingFromElevenMonths | limite 61 da ajuda | 143cda8: RecordEditorScenarioTests.swift:175: Expectation failed: (e → AnthroFeatures.RecordEditorModel).measuredRecumbent → false | aef8629 | green |
| survey-management | IMC com idade digitada | Tests/AnthroFeaturesTests/RecordEditorScenarioTests.swift | editorBMIUsesTypedMonthsAdjustment | sem arredondar ou com ponto | 143cda8: RecordEditorScenarioTests.swift:188: Expectation failed: (e.bmiText → "") == "16,5" | aef8629 | green |
| survey-management | IMC com edema | Tests/AnthroFeaturesTests/RecordEditorScenarioTests.swift | editorBMIIsNotAvailableWithOedema | ignora edema | 143cda8: RecordEditorScenarioTests.swift:199: Expectation failed: (e.bmiText → "") == "N/D" | aef8629 | green |
| survey-management | Próximo ID | Tests/AnthroFeaturesTests/SurveyDetailScenarioTests.swift | autoRecordIDIsMaxPlusOne | count + 1 | 143cda8: SurveyDetailScenarioTests.swift:65: Expectation failed: (m.allRecords.count → 0) == 3 | 21ca427 | green |
| survey-management | Inquérito sem domicílios | Tests/AnthroFeaturesTests/SurveyDetailScenarioTests.swift | autoHouseholdStartsAtOne | máximo inicial 1 | 143cda8: SurveyDetailScenarioTests.swift:73: Expectation failed: (m.allRecords.count → 0) == 3 | 21ca427 | green |
| survey-management | Filtro ativo não reduz o próximo ID | Tests/AnthroFeaturesTests/SurveyDetailScenarioTests.swift | autoIDConsidersFilteredRecords | máximo sobre visibleRows | 143cda8: SurveyDetailScenarioTests.swift:81: Expectation failed: (m.visibleRows.map(\.record.displayID) → []) == ([3] → [Optional(3)]) | 21ca427 | green |
| survey-management | Atribuição de conglomerado desligada | Tests/AnthroFeaturesTests/SurveyDetailScenarioTests.swift | clusterStaysNilWhenAutoIDOff | ignora a opção | 143cda8: SurveyDetailScenarioTests.swift:90: Expectation failed: (m.allRecords.count → 0) == 2 | 21ca427 | green |
| survey-management | Valor digitado com atribuição ligada | Tests/AnthroFeaturesTests/SurveyDetailScenarioTests.swift | typedIDWinsOverAutoID | sobrescreve valor digitado | 143cda8: SurveyDetailScenarioTests.swift:100: Expectation failed: (m.allRecords.count → 0) == 2 | 21ca427 | green |
| survey-management | Estatura na mediana pela idade em meses | Tests/AnthroCoreTests/SurveyRecordEvaluationScenarioTests.swift | heightAtMedianByTypedMonthsHasZeroZ | meses convertidos em dias | 143cda8: SurveyRecordEvaluationScenarioTests.swift:29: Expectation failed: (SurveyRecordEvaluation.result(record, engine: engine).lengthOrHeightForAge.zScor... | a1483d0 | green |
| survey-management | Registro sem idade | Tests/AnthroCoreTests/SurveyRecordEvaluationScenarioTests.swift | recordWithoutAgeHasUnknownRange | data de hoje como padrão | 143cda8: SurveyRecordEvaluationScenarioTests.swift:42: Expectation failed: (result.weight → nil) == (d("18.00") → 18) | a1483d0 | green |
| survey-management | Limite alterado nas opções | Tests/AnthroCoreTests/SurveyPlausibilityScenarioTests.swift | surveyMaxBoundChangesWeightFlag | limites fixos em vez das opções | 143cda8: SurveyPlausibilityScenarioTests.swift:27: Expectation failed: (flagged(.weightForAge, result, options) → false) == true | c571328 | green |
| survey-management | Faixa desconhecida | Tests/AnthroCoreTests/SurveyPlausibilityScenarioTests.swift | unknownRangeFlagsAllIndicators | default devolve falso | 143cda8: SurveyPlausibilityScenarioTests.swift:34: Expectation failed: (SurveyPlausibility.flag(result: result, options: literalSurveyOptions()) → .none) ==... | c571328 | green |
| survey-management | 109 meses sem peso | Tests/AnthroCoreTests/SurveyPlausibilityScenarioTests.swift | weightForAgeAbove108MonthsIsNeverFlagged | constante 108 removida | 143cda8: SurveyPlausibilityScenarioTests.swift:42: Expectation failed: (flagged(.bmiForAge, result) → false) == true | c571328 | green |
| survey-management | 108 meses sem peso | Tests/AnthroCoreTests/SurveyPlausibilityScenarioTests.swift | weightForAgeAt108MonthsWithoutWeightIsFlagged | >= 108 | 143cda8: SurveyPlausibilityScenarioTests.swift:48: Expectation failed: (flagged(.weightForAge, result) → false) == true | c571328 | green |
| survey-management | Linha completa | Tests/AnthroFeaturesTests/SurveyTableScenarioTests.swift | fullRowRendersOriginalFormats | dia aproximado sem XX | 143cda8: SurveyTableScenarioTests.swift:41: Expectation failed: (columns.map { cell(r, $0) } → ["", "", "", "", "", "", "", "", "", ""]) == ["01/04/2021", "... | 651a481 | green |
| survey-management | Valores ausentes | Tests/AnthroFeaturesTests/SurveyTableScenarioTests.swift | missingValuesRenderAsEmptyText | ausente vira N/D ou 0 | 143cda8: SurveyTableScenarioTests.swift:52: Expectation failed: (cell(r, .sex) → "") == "Feminino" | 651a481 | green |
| survey-management | Idade digitada | Tests/AnthroFeaturesTests/SurveyTableScenarioTests.swift | typedAgeRendersDaysAndIsNotDerived | marcada como derivada | 143cda8: SurveyTableScenarioTests.swift:58: Expectation failed: (cell(r, .ageInDays) → "") == "1872" | 651a481 | green |
| survey-management | Idade derivada das datas | Tests/AnthroFeaturesTests/SurveyTableScenarioTests.swift | computedAgeRendersAsDerived | isDerived falso | 143cda8: SurveyTableScenarioTests.swift:67: Expectation failed: (cell(r, .ageInDays) → "") == "1843" | 651a481 | green |
| survey-management | z de estatura implausível | Tests/AnthroFeaturesTests/SurveyTableScenarioTests.swift | implausibleHeightZIsHighlightedWithFlagText | destaque por gravidade | 143cda8: SurveyTableScenarioTests.swift:76: Expectation failed: (cell(r, .weightForAgeZ) → "") == "1,14" | 651a481 | green |
| survey-management | z ausente sem destaque visível | Tests/AnthroFeaturesTests/SurveyTableScenarioTests.swift | missingWeightZIsNotHighlightedButFlagged | destaca z nil | 143cda8: SurveyTableScenarioTests.swift:91: Expectation failed: (cell(r, .flag) → "") == "P/I" | 651a481 | green |
| survey-management | Três cliques no peso | Tests/AnthroFeaturesTests/SurveyTableScenarioTests.swift | threeClicksSortAscendingThenReverseTwice | reordena em vez de inverter | 143cda8: SurveyTableScenarioTests.swift:100: Expectation failed: (weights(m) → []) == ([15, 20, nil] → [Optional(15), Optional(20), nil]) | 21ca427 | green |
| survey-management | z indefinido ordenado primeiro | Tests/AnthroFeaturesTests/SurveyTableScenarioTests.swift | undefinedZSortsAsSmallest | z nil no fim | 143cda8: SurveyTableScenarioTests.swift:117: Expectation failed: (m.visibleRows.map(\.result.weightForAge.zScore) → []) == ([nil, num("-0.5"), 1] → [nil, Op... | 21ca427 | green |
| survey-management | Troca de coluna recomeça em ordem crescente | Tests/AnthroFeaturesTests/SurveyTableScenarioTests.swift | newSortColumnRestartsAscending | estado de ordem não reinicia | 143cda8: SurveyTableScenarioTests.swift:126: Expectation failed: (weights(m) → []) == ([25, 20, 15] → [Optional(25), Optional(20), Optional(15)]) | 21ca427 | green |
| survey-management | Maior ou igual em peso | Tests/AnthroFeaturesTests/SurveyFilterScenarioTests.swift | numericGreaterOrEqualFilterKeepsMatches | > no lugar de >= | 143cda8: SurveyFilterScenarioTests.swift:38: Expectation failed: (weights(m) → []) == ([20, 25] → [Optional(20), Optional(25)]) | 21ca427 | green |
| survey-management | Intervalo numérico sem limite superior | Tests/AnthroFeaturesTests/SurveyFilterScenarioTests.swift | numericRangeWithEmptyUpperExcludesNumbers | limite vazio aberto | 143cda8: SurveyFilterScenarioTests.swift:46: Expectation failed: (m.visibleRows.count → 0) == 3 | 21ca427 | green |
| survey-management | Sexo sem diferenciar maiúsculas | Tests/AnthroFeaturesTests/SurveyFilterScenarioTests.swift | textEqualityIsCaseInsensitiveAndTrimsValue | sem trim ou sensível a maiúsculas | 143cda8: SurveyFilterScenarioTests.swift:56: Expectation failed: (m.visibleRows.map(\.record.sex) → []) == ([.girl, .girl] → [AnthroCore.Sex.girl, AnthroCor... | 21ca427 | green |
| survey-management | Célula vazia igual a vazio | Tests/AnthroFeaturesTests/SurveyFilterScenarioTests.swift | emptyCellEqualsEmptyValue | número com valor vazio mantido | 143cda8: SurveyFilterScenarioTests.swift:63: Expectation failed: (m.visibleRows.map(\.record.cluster) → []) == [nil] | 21ca427 | green |
| survey-management | Intervalo de datas com limite superior aberto | Tests/AnthroFeaturesTests/SurveyFilterScenarioTests.swift | dateRangeWithOpenUpperBound | exclusão incondicional | 143cda8: SurveyFilterScenarioTests.swift:71: Expectation failed: (m.visibleRows.map { $0.record.visitDate.map(ymd) } → []) == (["2021-01-01"] → [Optional("2... | 21ca427 | green |
| survey-management | Comparação de data com valor inválido | Tests/AnthroFeaturesTests/SurveyFilterScenarioTests.swift | dateComparisonWithInvalidValueHidesAll | data inválida mantém célula | 143cda8: SurveyFilterScenarioTests.swift:78: Expectation failed: (m.visibleRows.count → 0) == 3 | 21ca427 | green |
| survey-management | Dois filtros e limpeza | Tests/AnthroFeaturesTests/SurveyFilterScenarioTests.swift | iterativeFiltersNarrowAndClearRestores | filtro parte de allRecords | 143cda8: SurveyFilterScenarioTests.swift:89: Expectation failed: (weights(m) → []) == ([22] → [Optional(22)]) | 21ca427 | green |
| survey-management | Limpar sem filtro ativo | Tests/AnthroFeaturesTests/SurveyFilterScenarioTests.swift | clearWithoutFilterIsNoOp | duplica registros | 143cda8: SurveyFilterScenarioTests.swift:101: Expectation failed: (weights(m) → []) == ([15, 20, 25] → [Optional(15), Optional(20), Optional(25)]) | 21ca427 | green |
| survey-management | Duas linhas selecionadas | Tests/AnthroFeaturesTests/SurveyTableScenarioTests.swift | clipboardHasHeaderAndSelectedRowsInTableOrder | fim de linha sem \t\r\n | 143cda8: SurveyTableScenarioTests.swift:140: Expectation failed: (text → "").hasSuffix("\t\r\n" → " | 21ca427 | green |
| survey-management | Nenhuma linha selecionada | Tests/AnthroFeaturesTests/SurveyTableScenarioTests.swift | clipboardWithoutSelectionHasOnlyHeader | cabeçalho só com seleção | 143cda8: SurveyTableScenarioTests.swift:153: Expectation failed: SurveyColumn.allCases.allSatisfy { !$0.title.isEmpty } | 21ca427 | green |
| survey-management | Linha selecionada | Tests/AnthroFeaturesTests/SurveyTableScenarioTests.swift | selectingRowExposesResultAndSeverity | gravidade pelo percentil | 143cda8: SurveyTableScenarioTests.swift:164: Expectation failed: (m → AnthroFeatures.SurveyDetailModel).selectedResult → nil → nil | 21ca427 | green |
| survey-management | Seleção removida | Tests/AnthroFeaturesTests/SurveyTableScenarioTests.swift | deletingSelectedRowClearsResult | resultado não é limpo | 143cda8: SurveyTableScenarioTests.swift:175: Expectation failed: (m.selectedResult → nil) != nil | 21ca427 | green |
| survey-management | Opções de um inquérito novo | Tests/AnthroCoreTests/SurveyOptionsScenarioTests.swift | newSurveyHasLiteralDefaultOptions | perde 228 repetido | 143cda8: SurveyOptionsScenarioTests.swift:11: Expectation failed: (options.ageGroupBoundaries.count → 0) == 22 | 19abf30 | green |
| survey-management | XML sem chaves | Tests/AnthroCoreTests/SurveyOptionsScenarioTests.swift | emptyOptionsXMLYieldsDefaults | ausente vira vazio | 143cda8: SurveyOptionsScenarioTests.swift:20: Expectation failed: (options.autoIDRecord → false) == true | 19abf30 | green |
| survey-management | Gravação das opções padrão | Tests/AnthroCoreTests/SurveyOptionsScenarioTests.swift | defaultOptionsSerializeToExactXML | true minúsculo ou ordem trocada | 143cda8: SurveyOptionsScenarioTests.swift:32: Expectation failed: (SurveyOptions.default.xml() → "") == (expected → "<Opt><O ID="AutoIDCluster">False</O><O ... | 19abf30 | green |
| survey-management | XML malformado | Tests/AnthroCoreTests/SurveyOptionsScenarioTests.swift | malformedOptionsXMLThrows | devolve padrões | 143cda8: SurveyOptionsScenarioTests.swift:37: Expectation failed: an error was expected but none was thrown and "SurveyOptions(autoIDCluster: false, autoIDT... | 19abf30 | green |
| survey-management | Limite legado preservado sem conversão | Tests/AnthroCoreTests/SurveyOptionsScenarioTests.swift | legacyMinZBoundsKeepOriginalValues | aplica a conversão | 143cda8: SurveyOptionsScenarioTests.swift:43: Expectation failed: (options → SurveyOptions(autoIDCluster: false, autoIDTeam: false, autoIDRecord: false, aut... | 19abf30 | green |
| survey-management | Chave legada e nova juntas | Tests/AnthroCoreTests/SurveyOptionsScenarioTests.swift | legacyAndNewKeyTogetherThrow | sobrescreve em silêncio | 143cda8: SurveyOptionsScenarioTests.swift:52: Expectation failed: an error was expected but none was thrown and "SurveyOptions(autoIDCluster: false, autoIDT... | 19abf30 | green |
| survey-management | Faixas padrão | Tests/AnthroCoreTests/SurveyOptionsScenarioTests.swift | defaultBoundariesYieldTwentyOneGroups | última faixa com b_n - 1 | 143cda8: SurveyOptionsScenarioTests.swift:60: Expectation failed: (groups.count → 0) == 21 | 207a451 | green |
| survey-management | Fronteiras mínimas | Tests/AnthroCoreTests/SurveyOptionsScenarioTests.swift | threeBoundariesYieldTwoGroups | faixa a menos | 143cda8: SurveyOptionsScenarioTests.swift:69: Expectation failed: (AgeGroups.groups(fromBoundaries: [0, 61, 228]) → []) == ([AgeGroup(lowerMonths: 0, upperM... | 207a451 | green |
| survey-management | Menos de duas faixas | Tests/AnthroFeaturesTests/SurveyOptionsEditorScenarioTests.swift | applyingWithOneAgeGroupThrowsTooFew | mínimo de 1 faixa | 143cda8: SurveyOptionsEditorScenarioTests.swift:24: Expectation failed: (e.ageGroups.count → 0) == 1 | ea88379 | green |
| survey-management | Limites inferiores repetidos | Tests/AnthroFeaturesTests/SurveyOptionsEditorScenarioTests.swift | repeatedLowerBoundsThrowInconsistent | aceita iguais | 143cda8: SurveyOptionsEditorScenarioTests.swift:34: Expectation failed: (e.lowerBounds → []) == [0, 12, 12] | ea88379 | green |
| survey-management | Máximo abaixo do mínimo | Tests/AnthroFeaturesTests/SurveyOptionsEditorScenarioTests.swift | maxBelowMinIsRaisedToMin | sem comparação | 143cda8: SurveyOptionsEditorScenarioTests.swift:42: Expectation failed: (e.zBound(.weightForAge, range: .standards, isMax: true) → 0) == -6 | ea88379 | green |
| survey-management | Mínimo acima do máximo e limite fora da faixa | Tests/AnthroFeaturesTests/SurveyOptionsEditorScenarioTests.swift | minAboveMaxIsLoweredAndOutOfRangeBoundBlocksApply | aceita ou ajusta 120 | 143cda8: SurveyOptionsEditorScenarioTests.swift:49: Expectation failed: (e.zBound(.bmiForAge, range: .reference, isMax: false) → 0) == 5 | ea88379 | green |
| survey-management | Restaurar depois de alterar | Tests/AnthroFeaturesTests/SurveyOptionsEditorScenarioTests.swift | resetRestoresLiteralDefaults | restaura só limites de z | 143cda8: SurveyOptionsEditorScenarioTests.swift:63: Expectation failed: (options.autoIDRecord → false) == true | ea88379 | green |
| survey-management | Restaurar sem alterações | Tests/AnthroFeaturesTests/SurveyOptionsEditorScenarioTests.swift | resetOnDefaultsKeepsLiteralDefaults | zera faixas | 143cda8: SurveyOptionsEditorScenarioTests.swift:70: Expectation failed: (options.autoIDRecord → false) == true | ea88379 | green |
| survey-management | Aplicar recalcula flags | Tests/AnthroFeaturesTests/SurveyDetailScenarioTests.swift | applyingOptionsRecomputesHighlights | linhas não reconstruídas | 143cda8: SurveyDetailScenarioTests.swift:109: Expectation failed: (m.visibleRows.first?.isHighlighted(.fixed(.weightForAgeZ)) → nil) == false | ea88379 | green |
| survey-management | Cancelar descarta a atribuição automática | Tests/AnthroFeaturesTests/SurveyDetailScenarioTests.swift | cancellingOptionsEditorKeepsSurveyOptions | edição por referência | 143cda8: SurveyDetailScenarioTests.swift:124: Expectation failed: (m.options.autoIDRecord → false) == true | 21ca427 | green |
| survey-management | Ida e volta de um registro completo | Tests/AnthroStoreTests/SurveyRepositoryScenarioTests.swift | recordRoundTripsWithoutLoss | fator como REAL ou edema NULL vira falso | 143cda8: SurveyRepositoryScenarioTests.swift:86: Expectation failed: (saved.survey → Survey(id: nil, name: "Escola A", notes: nil, additionalDataDefinitionX... | e0d8e1f | green |
| survey-management | Ordem de inclusão | Tests/AnthroFeaturesTests/SurveyDetailScenarioTests.swift | recordsKeepInsertionOrder | ignora position | 143cda8: SurveyDetailScenarioTests.swift:52: Expectation failed: (m.survey → Survey(id: nil, name: "Escola A", notes: nil, additionalDataDefinitionXML: nil,... | 21ca427 | green |
| survey-management | Definição copiada | Tests/AnthroFeaturesTests/RecordEditorScenarioTests.swift | newRecordCopiesSurveyAdditionalDataDefinition | XML inicial nil | 143cda8: RecordEditorScenarioTests.swift:49: Expectation failed: try editor(definition: definition).makeRecord().additionalDataXML == definition | aef8629 | green |
| survey-management | Inquérito sem definição | Tests/AnthroFeaturesTests/RecordEditorScenarioTests.swift | newRecordWithoutDefinitionGetsEmptyData | propaga nil | 143cda8: RecordEditorScenarioTests.swift:54: Expectation failed: try editor().makeRecord().additionalDataXML == "<Data />" | aef8629 | green |
| survey-management | Banco migrado | Tests/AnthroStoreTests/SurveyMigrationScenarioTests.swift | migrationThreeCreatesSurveyTables | migração não registrada | 143cda8: SurveyMigrationScenarioTests.swift:14: fase 1, migração 3 com SQL vazio: Expectation failed: (tables → [app_meta, mothers, ..., visits]).contains("... | 143cda8 (migração escrita no vermelho como dado de partida) | green |
| survey-management | Sexo inválido | Tests/AnthroStoreTests/SurveyMigrationScenarioTests.swift | invalidSexIsRejectedByConstraint | sem CHECK de sexo | 143cda8: SurveyMigrationScenarioTests.swift:33: fase 1, migração 3 com SQL vazio: Expectation failed: (message → "no such table: surveys").contains("CHECK c... | 143cda8 (migração escrita no vermelho como dado de partida) | green |

## Test Changes After Red

<!-- Append-only. Vazio no planejamento. -->
