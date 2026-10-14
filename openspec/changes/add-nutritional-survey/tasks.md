# Tasks

## 0. Red gate

- [x] 0.1 Write every scenario test from tests.md and stubs with the exact signatures from Interface Under Test (neutral return values, no logic)
- [x] 0.2 Run the scenario tests; confirm each FAILS BY ASSERTION (not import, syntax or collection errors); record each failure excerpt in the ledger
- [x] 0.3 Commit tests and stubs only as `test(red): add-nutritional-survey`; write the SHA in the ledger
- [x] 0.4 STOP: show the user the failing tests and wait for explicit approval before implementing
  - Portão registrado sem parada: esta change não fixa números clínicos; por decisão do Caio (14/10/2026), a parada no vermelho vale só para `port-anthro-engine` e `add-survey-analysis`.

## 1. Domínio do inquérito em AnthroCore

- [ ] 1.1 Implement `SurveyOptions` (padrões, `xml()`, `init(xml:)` com chaves legadas e chave repetida, `zBounds`), unit tests first (inner loop) para leitura de booleanos, listas com vírgula ou ponto e chave ausente; verified when [tests: newSurveyHasLiteralDefaultOptions, emptyOptionsXMLYieldsDefaults, defaultOptionsSerializeToExactXML, malformedOptionsXMLThrows, legacyMinZBoundsKeepOriginalValues, legacyAndNewKeyTogetherThrow] pass with `swift test --filter SurveyOptionsScenarioTests`
- [ ] 1.2 Implement `AgeGroups.groups(fromBoundaries:)`; verified when [tests: defaultBoundariesYieldTwentyOneGroups, threeBoundariesYieldTwoGroups] pass
- [ ] 1.3 Implement `Survey`, `SurveyRecord` (inclui `displayName` de `Record.DisplayName`) e `SurveyRecordEvaluation` (idade por meses ou datas, `displayedBMI`), unit tests first para `displayName` e para nascimento posterior à pesquisa; verified when [tests: unknownBirthUsesTypedMonthsForResult, heightAtMedianByTypedMonthsHasZeroZ, recordWithoutAgeHasUnknownRange] pass
- [ ] 1.4 Implement `SurveyPlausibility` com limites das opções, regra dos 108 meses e faixa desconhecida; verified when [tests: surveyMaxBoundChangesWeightFlag, unknownRangeFlagsAllIndicators, weightForAgeAbove108MonthsIsNeverFlagged, weightForAgeAt108MonthsWithoutWeightIsFlagged] pass
- [ ] 1.5 Refactor `Sources/AnthroCore/Survey/`; `swift test` stays green

## 2. Persistência do inquérito

- [ ] 2.1 Implement `Migration003_survey.swift` (tabelas, cascata, CHECK de sexo, índice) e registrá-la em `Migrations.all` (escrita no vermelho como dado de partida, ver Conventions de tests.md; aqui se confirma o verde e a detecção por mutação do CHECK); verified when [tests: migrationThreeCreatesSurveyTables, invalidSexIsRejectedByConstraint] pass
- [ ] 2.2 Implement `SurveyRepository` (`list`, `survey`, `records`, `save` transacional com `position`, `setArchived`, `delete`), unit tests first para o mapeamento de `SQLValue` de cada coluna; verified when [tests: newSurveyIsSavedWithTrimmedNameAndNilNotes, blankSurveyNameThrowsNameRequired, activeSurveysAreOrderedByNameThenID, deletingSurveyDeletesItsRecords, failedRecordInsertRollsBackSurveyInsert, recordRoundTripsWithoutLoss] pass with `swift test --filter SurveyRepositoryScenarioTests`
- [ ] 2.3 Refactor `Sources/AnthroStore/SurveyRepository.swift`; `swift test` stays green

## 3. Editor de registro

- [ ] 3.1 Implement valores padrão, carga de registro existente e cópia da definição de dados adicionais em `RecordEditorModel`; verified when [tests: newRecordEditorStartsWithOriginalDefaults, existingBoyRecordLoadsSexAndWeightingFactor, newRecordCopiesSurveyAdditionalDataDefinition, newRecordWithoutDefinitionGetsEmptyData] pass
- [ ] 3.2 Implement os campos numéricos como texto avaliado por `MeasurementInput.evaluate` (`RecordNumericField.range` e `places`), `outcome`, `value`, `warnings`, `canSave` e `RecordValidationError` em `makeRecord()`, sem helper próprio de parse; verified when [tests: boundaryInputsAreAcceptedAndTruncated, outOfRangeInputsWarnAndBlockSave, invalidTextBlocksSaveButEmptyIsAllowed, emptyWeightingFactorIsRequired] pass
- [ ] 3.3 Implement regras de datas (idade digitada descartada, nascimento aproximado por `ApproximateBirthDate.randomized` com o `randomDay` injetado, nascimento limitado à data da pesquisa por `ApproximateBirthDate.adjusted`) e `ageText` por `AgeText.localized(months:)`; verified when [tests: typedAgeIsDiscardedWhenBothDatesExist, approximateBirthDrawsDayBelowLastDayOfMonth, birthAfterVisitIsClampedToVisitDate, editorAgeTextUsesSharedAgeText, editorAgeTextWithoutAgeIsNotAvailable] pass
- [ ] 3.4 Implement `isMeasureChoiceEnabled`, forçar em pé e `bmiText`; verified when [tests: measureChoiceEnabledBelowElevenMonths, measureChoiceDisabledAndStandingFromElevenMonths, editorBMIUsesTypedMonthsAdjustment, editorBMIIsNotAvailableWithOedema] pass
- [ ] 3.5 Refactor `RecordEditorModel`; `swift test` stays green

## 4. Tabela de registros

- [ ] 4.1 Implement `SurveyColumn.title` (pt-BR em `L10n`), `SurveyRecordRow.text`, `isDerived`, `isHighlighted` e `flag`, unit tests first para a máscara `XX` do nascimento aproximado e para o fator de peso com casas variáveis; verified when [tests: fullRowRendersOriginalFormats, missingValuesRenderAsEmptyText, typedAgeRendersDaysAndIsNotDerived, computedAgeRendersAsDerived, implausibleHeightZIsHighlightedWithFlagText, missingWeightZIsNotHighlightedButFlagged] pass with `swift test --filter SurveyTableScenarioTests`
- [ ] 4.2 Implement ordenação em `SurveyDetailModel.sort(by:)` com comparadores tipados e inversão, unit tests first para o comparador de z indefinido e de sexo; verified when [tests: threeClicksSortAscendingThenReverseTwice, undefinedZSortsAsSmallest, newSortColumnRestartsAscending] pass
- [ ] 4.3 Implement `SurveyFilterEvaluator.keeps`, unit tests first para cada condição e cada ramo (número, texto, data), seguindo o IL de `FilterRecords` (D7); verified when its unit tests pass
- [ ] 4.4 Implement `applyFilter`, `clearFilter`, `isFiltered` e `recordCountLabel`; verified when [tests: numericGreaterOrEqualFilterKeepsMatches, numericRangeWithEmptyUpperExcludesNumbers, textEqualityIsCaseInsensitiveAndTrimsValue, emptyCellEqualsEmptyValue, dateRangeWithOpenUpperBound, dateComparisonWithInvalidValueHidesAll, iterativeFiltersNarrowAndClearRestores, clearWithoutFilterIsNoOp] pass with `swift test --filter SurveyFilterScenarioTests`
- [ ] 4.5 Implement `clipboardText`, `select(visibleIndex:)` e `severity`; verified when [tests: clipboardHasHeaderAndSelectedRowsInTableOrder, clipboardWithoutSelectionHasOnlyHeader, selectingRowExposesResultAndSeverity, deletingSelectedRowClearsResult] pass
- [ ] 4.6 Refactor `SurveyRecordRow`, filtro e ordenação; `swift test` stays green

## 5. Ciclo do inquérito

- [ ] 5.1 Implement em `SurveyDetailModel` inclusão e edição por `commit(_:)` com atribuição automática de IDs sobre `allRecords`; verified when [tests: autoRecordIDIsMaxPlusOne, autoHouseholdStartsAtOne, autoIDConsidersFilteredRecords, clusterStaysNilWhenAutoIDOff, typedIDWinsOverAutoID] pass
- [ ] 5.2 Implement `save()`, `discardChanges()`, `hasUnsavedChanges` e ordem de inclusão; verified when [tests: discardRestoresSavedRecords, recordsKeepInsertionOrder] pass
- [ ] 5.3 Implement `makeOptionsEditor()` e `applyOptions(_:)` com reconstrução das linhas; verified when [tests: applyingOptionsRecomputesHighlights, cancellingOptionsEditorKeepsSurveyOptions] pass
- [ ] 5.4 Implement `SurveyListModel` e `SurveyModuleModel` (abrir, criar, fechar, decisão pendente com o `UnsavedChangesDecision` da change 4, arquivar, restaurar, excluir); verified when [tests: archiveAndDeleteDependOnCheckedSurveys, archiveThenRestoreMovesSurveyBetweenLists, archivingOpenSurveyClosesDetail, deletingOpenSurveyClosesDetail, saveDecisionPersistsThenOpensOtherSurvey, cancelDecisionKeepsCurrentSurveyDirty] pass with `swift test --filter SurveyModuleScenarioTests`
- [ ] 5.5 Refactor `SurveyDetailModel` e `SurveyModuleModel`; `swift test` stays green

## 6. Editor de opções

- [ ] 6.1 Implement `SurveyOptionsEditorModel` (faixas, limites de z como texto avaliado por `MeasurementInput.evaluate` entre -99 e 99 com 1 casa, coerência mínimo e máximo, `invalidZBounds`, restaurar, `apply()`), unit tests first para `addAgeGroup` no limite de 21 faixas; verified when [tests: applyingWithOneAgeGroupThrowsTooFew, repeatedLowerBoundsThrowInconsistent, maxBelowMinIsRaisedToMin, minAboveMaxIsLoweredAndOutOfRangeBoundBlocksApply, resetRestoresLiteralDefaults, resetOnDefaultsKeepsLiteralDefaults] pass
- [ ] 6.2 Refactor `SurveyOptionsEditorModel`; `swift test` stays green

## 7. Interface SwiftUI

- [ ] 7.1 Implement `SurveyModuleView`, `SurveyListView`, `SurveyTableView` (`Table` com multisseleção, ordenação pelo cabeçalho, ⌘C, células derivadas em `.secondary`, destaque de z implausível), `RecordEditorSheet`, `SurveyOptionsSheet` e `SurveyFilterSheet`, sem regra de negócio; verified when `scripts/build-app.sh` termina com código 0 e `swift test` continua verde
- [ ] 7.2 Verificação manual registrada (N/A non-executable): criar inquérito, incluir 3 registros, ordenar, filtrar, copiar para o Numbers, salvar, reabrir o app e conferir os dados; critério mecânico: `codesign --verify build/AnthroPlus.app` termina com código 0
- [ ] 7.3 Refactor das views; `swift test` stays green

## 8. Verification

- [ ] 8.1 Mutation check for survey-management: trocar a constante 108 por 120 em `SurveyPlausibility.isFlagged`, ver `weightForAgeAbove108MonthsIsNeverFlagged` falhar, reverter
- [ ] 8.2 Mutation check for survey-management: fazer o ramo de intervalo de datas de `SurveyFilterEvaluator` excluir incondicionalmente, ver `dateRangeWithOpenUpperBound` falhar, reverter
- [ ] 8.3 Mutation check for survey-management: gravar booleanos como "true" em `SurveyOptions.xml()`, ver `defaultOptionsSerializeToExactXML` falhar, reverter
- [ ] 8.4 Run the full suite fresh (`swift test`); all green, output free of errors and warnings

## Workflow follow-up

- Produce evidence.md (`openspec instructions evidence --change add-nutritional-survey`) and reach `DECISION: PASS`
- Archive the change
