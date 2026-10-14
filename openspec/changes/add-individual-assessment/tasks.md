# Tasks

## 0. Red gate

- [ ] 0.1 Write every scenario test from tests.md (67 testes em `Tests/AnthroStoreTests/IndividualAssessment/` e `Tests/AnthroFeaturesTests/IndividualAssessment/`, mais `Support.swift` com `IAFixtures`) and stubs with the exact signatures from Interface Under Test (neutral return values, no logic; `LookupSearchOutcome` stub devolve `.results([])`; a migração 2 já cria as tabelas, porque é dado de partida e não lógica)
- [ ] 0.2 Run the scenario tests (`swift test --filter IndividualAssessment`); confirm each FAILS BY ASSERTION (not import, syntax or collection errors); record each failure excerpt in the ledger
- [ ] 0.3 Commit tests and stubs only as `test(red): add-individual-assessment`; write the SHA in the ledger
- [ ] 0.4 STOP: show the user the failing tests and wait for explicit approval before implementing; nesta parada, confirmar também a decisão D4 do design (ID automático sobre o banco inteiro) (aprovação prévia do usuário em 14/10/2026: changes sem números clínicos seguem do vermelho ao verde sem parada; D4 confirmada no mesmo dia; portão registrado no ledger)

## 1. Persistência de crianças, visitas, pais e endereços

- [ ] 1.1 Implement `Migration002_individual` (tabelas, chaves, `CHECK` de sexo, `ON DELETE CASCADE`, índice) registrada em `Migrations.all`, com teste unitário de que `schemaVersion()` vira 2 e de que a migração roda sobre um banco na versão 1; verified when the unit tests pass
- [ ] 1.2 Implement mapeamento de `ChildRecord`, `VisitRecord`, `ParentRecord` e `AddressRecord` para linhas (`SQLValue` de `Decimal`, datas e sexo), com `SQLValue` de data no calendário do usuário (D10: grava o dia local, relê ao meio-dia local; o unit test `dataViraTextoDeCalendarioEmUTC` da change 1 é trocado por um no calendário do usuário), unit tests first (inner loop); verified when [tests: childSavedAndReopenedKeepsAllFields] and its unit tests pass
- [ ] 1.3 Implement `ChildRepository.list(archived:)`, `child(id:)`, `save(_:visits:)` e `VisitRepository` (`visits(childID:)`, `replaceVisits`), com `displayName` e `listTitle`; verified when [tests: childSavedAndReopenedKeepsAllFields, activeListOrdersByDisplayIDWithNilFirst, listTitleWithoutLastName] pass
- [ ] 1.4 Implement `ParentRepository` e `AddressRepository` (`save`, leitura, `displayName`); verified when [tests: addressDisplayNameJoinsFilledFields, emptyAddressShowsNoDataLabel] pass
- [ ] 1.5 Refactor `Sources/AnthroStore/Individual/`; full suite stays green (`swift test`)

## 2. Busca, arquivo, exclusão e órfãos

- [ ] 2.1 Implement `NameMatcher`, unit tests first (inner loop: escape de metacaracteres de regex, `*`, `?`, ancoragem, Unicode); verified when [tests: searchByLastNamePrefixWildcard, searchWithoutWildcardIsExactMatch, questionMarkMatchesExactlyOneCharacter, searchIgnoresCaseButNotAccents] and its unit tests pass
- [ ] 2.2 Implement `ChildRepository.search` (critérios SQL de sexo, ID e nascimento, só ativas, filtro de nomes em Swift, ordem por ID); verified when [tests: searchExcludesArchivedChildren] pass
- [ ] 2.3 Implement `OrphanCleanup.run` com contagem por `changes()`, `ChildRepository.delete` (visitas, crianças e órfãos numa transação), `setArchived` e `maxDisplayID`; verified when [tests: deletingChildRemovesItsVisits, sharedMotherSurvivesUntilLastChildIsDeleted, orphanCleanupIsIdempotentAndKeepsLinkedRecords] pass
- [ ] 2.4 Implement `ParentRepository.search` e `AddressRepository.search` (contagem antes da busca, limite 50, ordenações de `Mothers._SEARCH` e `Addresses._SEARCH`, texto literal, sem diferenciar maiúsculas); verified when [tests: motherSearchMatchesSubstringIgnoringCase, lookupSearchReportsTooManyResults, lookupSearchReportsNoResults] pass
- [ ] 2.5 Refactor busca e exclusão; full suite stays green (`swift test`)

## 3. Lista de crianças

- [ ] 3.1 Implement `ChildListModel` (`load` com limpeza de órfãos, `showActive`, `showArchive`, `search`, `archiveChecked`, `restoreChecked`, `deleteChecked` e as flags `can*` por modo e marcação); verified when [tests: archivingMovesCheckedChildrenToArchive, archiveModeExposesOnlyRestoreAndBack, moduleLoadRemovesOrphanParentsAndAddresses, searchCombinesSexIDRangeAndBirthRange, emptyCriteriaClearsSearch] pass
- [ ] 3.2 Refactor `ChildListModel`; full suite stays green (`swift test`)

## 4. Ficha da criança e unidade de trabalho

- [ ] 4.1 Confirm que os helpers `ApproximateBirthDate`, `AgeText` e `MeasurementInput` da change 3 estão em `Sources/AnthroFeatures/Common/` com as assinaturas do design (sem reimplementá-los aqui) e declare `IndividualAssessment.parentHeightRange` e `parentWeightRange`; verified when `swift build` passes
- [ ] 4.2 Implement `ChildDetailModel` com `startNew`, `open`, `update`, `save` (validação de sexo, trim de textos, ID automático), `discardChanges` e `hasUnsavedChanges`; verified when [tests: blankTextsAreStoredAsNil, childWithSexIsSaved, childWithoutSexIsRejected, autoDisplayIDIncludesArchivedChildren, firstChildGetsDisplayIDOne, manualDisplayIDWhenAutoAssignIsOff] pass
- [ ] 4.3 Implement `setDateOfBirth` e `setDateOfBirthIsApprox` com os limites de D10, delegando o sorteio a `ApproximateBirthDate` (D9); verified when [tests: birthDateClampedToFirstVisit, birthDateClampedToToday, approximateBirthDayDrawsBeforeLastDay, dayOnlyChangeIgnoredWhenApproximate] pass
- [ ] 4.4 Implement `proceedAfterUnsavedChanges` (salvar, descartar, cancelar); verified when [tests: discardDecisionProceedsWithoutSaving, cancelDecisionKeepsChildOpen, saveDecisionWithoutSexBlocksNavigation] pass
- [ ] 4.5 Implement visitas na ficha: `commitVisit` ordenado por data, `deleteSelectedVisits`, flags de visita, `visitRows`, `selectedResult`, `ageLabel` e `chartInput`; verified when [tests: committedVisitsStayInDateOrder, committedVisitPersistsOnlyWithChildSave, discardRestoresDeletedVisit, deletingSelectedVisitsPersistsOnSave, visitActionsFollowSelection, visitRowFormatsColumns, visitRowLeavesMissingWeightEmpty, selectedVisitResultAtMedianForGirlAt80Months, selectedVisitResultSeverities, selectedResultFollowsVisitFocus, ageLabelForEightyMonths, ageLabelUnderOneYear, chartInputForExistingVisit, chartInputInsertsUncommittedVisit] pass
- [ ] 4.6 Refactor `ChildDetailModel`; full suite stays green (`swift test`)

## 5. Editor de visita

- [ ] 5.1 Implement `VisitEditorModel` (valores iniciais, limites de data, data fixa ao editar, regra de 11 meses, IMC, `makeVisit` com data repetida e trim de notas, preservação de `additionalDataXML` ao editar); verified when [tests: newVisitStartsTodayStandingWithoutOedema, newVisitDateNeverBeforeBirth, visitDateClampedToBirth, existingVisitDateIsFrozen, duplicateVisitDateIsRejected, measureChoiceEnabledUnderElevenMonths, measureChoiceForcedStandingFromElevenMonths, visitBMIShownWithOneDecimal, visitBMIHiddenWithOedema] pass
- [ ] 5.2 Implement a entrada de peso e medida do `VisitEditorModel` com `MeasurementInput.evaluate` (`weightOutcome`, `lengthOrHeightOutcome`, avisos com o intervalo aceito, `canSave` e `VisitValidationError.invalidMeasurement` em `makeVisit`, D7), unit tests first (inner loop: texto do aviso para `.invalid` e `.outOfRange`); verified when [tests: visitWeightIsTruncatedToTwoPlaces, visitMeasuresAcceptInclusiveLimits, visitMeasureOutOfRangeIsExcludedFromCalculation, visitWithOutOfRangeWeightCannotBeSaved, visitWithInvalidLengthCannotBeSaved, visitWithEmptyWeightCanBeSaved] and its unit tests pass
- [ ] 5.3 Refactor `VisitEditorModel`; full suite stays green (`swift test`)

## 6. Editores de mãe, pai e endereço

- [ ] 6.1 Implement `ParentEditorModel` (intervalos 50 a 300 cm e 10 a 1000 kg por `MeasurementInput.evaluate`, avisos, `canSave` e `ParentValidationError.invalidMeasurement`, IMC truncado, nascimento desconhecido, limite a hoje, data aproximada por `ApproximateBirthDate`) e `AddressEditorModel` (trim, vazio como `nil`, gravação imediata); verified when [tests: parentBMIIsTruncatedNotRounded, parentHeightOutsideRangeBlocksSave, parentWithEmptyHeightIsSaved, parentBirthDateUnknownOrFuture] pass
- [ ] 6.2 Refactor editores; full suite stays green (`swift test`)

## 7. Telas SwiftUI

- [ ] 7.1 Implement as views de `Sources/AnthroPlusApp/IndividualAssessment/` (lista com marcação e barra de ações, ficha com seções Criança, Mãe, Pai, Endereço e Acompanhamento, avisos inline nos campos numéricos e botão Salvar desabilitado por `canSave`, tabela de visitas, painel de resultado com cores de `SeverityClassifier`, folhas de visita, busca, mãe, pai e endereço, diálogo de alterações não salvas) e ligue o módulo à seção `.individualAssessment` de `AppModel`; verified when `scripts/build-app.sh` termina com código 0 e `codesign --verify build/AnthroPlus.app` passa (N/A non-executable para o visual)
- [ ] 7.2 Refactor das views para não conter regra de negócio (toda regra nos modelos de `AnthroFeatures`); full suite stays green (`swift test`)

## 8. Verification

- [ ] 8.1 Mutation check for child-registry: trocar em `ChildRepository.maxDisplayID()` a consulta para `WHERE is_archived = 0`, ver `autoDisplayIDIncludesArchivedChildren` falhar, reverter
- [ ] 8.2 Mutation check for child-registry: remover a ancoragem `^...$` em `NameMatcher`, ver `searchWithoutWildcardIsExactMatch` falhar, reverter
- [ ] 8.3 Mutation check for visit-tracking: trocar `< 11` por `< 61` na regra de medida do `VisitEditorModel`, ver `measureChoiceForcedStandingFromElevenMonths` falhar, reverter
- [ ] 8.4 Mutation check for visit-tracking: fazer `commitVisit` gravar direto com `VisitRepository.replaceVisits`, ver `committedVisitPersistsOnlyWithChildSave` falhar, reverter
- [ ] 8.5 Mutation check for visit-tracking: fazer `canSave` ignorar `.outOfRange` e `makeVisit()` gravar `nil`, ver `visitWithOutOfRangeWeightCannotBeSaved` falhar, reverter
- [ ] 8.6 Run the full suite fresh (`swift test`); all green, output free of errors and warnings

## Workflow follow-up

- Produce evidence.md (`openspec instructions evidence --change add-individual-assessment`) and reach `DECISION: PASS`
- Archive the change
