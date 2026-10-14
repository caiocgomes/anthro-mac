# Tasks

## 0. Red gate

- [x] 0.1 Write every scenario test from tests.md and stubs with the exact signatures from Interface Under Test (neutral return values, no logic), incluindo o caso `.additional` em `SurveyTableColumn` e as propriedades `additionalData` em `RecordEditorModel` e `VisitEditorModel`
- [x] 0.2 Run the scenario tests; confirm each FAILS BY ASSERTION (not import, syntax or collection errors); record each failure excerpt in the ledger
- [x] 0.3 Commit tests and stubs only as `test(red): add-additional-data`; write the SHA in the ledger
- [x] 0.4 STOP: show the user the failing tests and wait for explicit approval before implementing (registrado sem parada: a parada vale só para as changes que fixam números clínicos, decisão do Caio de 14/10/2026)

## 1. Modelo e XML

- [x] 1.1 Implement `AdditionalData`, `AdditionalDataSection` e `AdditionalDataVariable` com buscas por identificador; verified when the unit tests de `section(_:)` e `variable(section:variable:)` pass
- [x] 1.2 Implement `AdditionalDataXML.encode` escrito à mão (ordem de atributos, `Txt` aberto e fechado, `Num`/`Date`/`Cat`/`Data` autofechados com espaço, escape, ponto decimal, data `dd-MM-yyyy HH:mm:ss`), unit tests first para escape de `&`, `<`, `>` e `"`; verified when [tests: templateRoundTripIsByteIdentical, emptyDataAndEmptySectionSerializeSelfClosing, numberUsesPointAndDateUsesOriginalFormat] pass
- [x] 1.3 Implement `AdditionalDataXML.decode` com `XMLParser` (atributos obrigatórios, valores inválidos como `nil`, elementos desconhecidos ignorados, vírgula ou ponto, `nil` e "" como vazio); verified when [tests: decodesOriginalIndividualTemplate, invalidValuesBecomeNilAndUnknownElementsAreSkipped, missingDescrAttributeThrows, nilOrEmptyXMLDecodesToEmptyData, decoderAcceptsCommaDecimals] pass with `swift test --filter AdditionalDataXMLScenarioTests`
- [x] 1.4 Implement `AdditionalDataTemplates.individualAssessmentDefaultXML` e `AdditionalDataColumns.structure`; verified when [tests: defaultTemplateAddsSevenColumns, duplicateAndForbiddenKeysGetNumericSuffix] pass
- [x] 1.5 Refactor `Sources/AnthroCore/AdditionalData/`; `swift test` stays green

## 2. Persistência do modelo da avaliação individual

- [x] 2.1 Implement `Migration004_additional_data.swift` com `INSERT OR IGNORE` do modelo padrão e registro em `Migrations.all`; verified when [tests: migrationFourCreatesTemplateTable, templateXMLIsNotNull] pass
- [x] 2.2 Implement `AdditionalDataTemplateRepository`; verified when [tests: migrationFourSeedsIndividualTemplate, editedTemplateSurvivesReopen] pass
- [x] 2.3 Refactor `AdditionalDataTemplateRepository`; `swift test` stays green

## 3. Editor de definição

- [x] 3.1 Implement `AdditionalDataEditorModel` (incluir seção e variável, seleção, `canAddVariable`, excluir), unit tests first para a seleção após exclusão; verified when [tests: addVariableFromSelectedVariableAppendsToItsSection, addVariableRequiresSelection, deletingSectionRemovesItsVariables] pass
- [x] 3.2 Implement `setIdentifier`, `setDescription`, `setKind`, `setMinimum`, `setMaximum` e as validações de `apply()`; verified when [tests: identifierIsTrimmedAndEmptyDescriptionIsNil, emptySectionIdentifierThrowsOnApply, duplicateVariableInSectionThrowsOnApply, sameVariableInDifferentSectionsIsAccepted, changingKindKeepsPositionAndIdentifier, textToNumberStartsWithoutLimits, minimumAboveMaximumIsClamped, maximumBelowMinimumIsClampedAndEmptyAllowed] pass with `swift test --filter AdditionalDataEditorScenarioTests`
- [x] 3.3 Refactor `AdditionalDataEditorModel`; `swift test` stays green

## 4. Formulário de valores e rótulos

- [x] 4.1 Implement `AdditionalDataLabels` com os 11 identificadores e a descrição do modelo padrão; verified when [tests: userIdentifierIsShownAsTypedAndKeptInXML] pass and unit tests for each of the 12 labels pass
- [x] 4.2 Implement `AdditionalDataValuesModel` (campos em ordem, texto aparado, número avaliado por `MeasurementInput.evaluate` com o intervalo da variável e 2 casas, `outcome`, `warnings`, `canSave`, data opcional, `AdditionalDataValueError`), sem parser próprio; verified when [tests: valuesFormStoresTrimmedTextAndDate, clearedTextBecomesNilAndOpenCloseElement, numberWithCommaIsParsedAndShownWithTwoDecimals, outOfRangeAndInvalidNumbersWarnAndBlockSave, defaultTemplateLabelsAreTranslated] pass
- [x] 4.3 Refactor `AdditionalDataValuesModel`; `swift test` stays green

## 5. Integração com a avaliação individual

- [x] 5.1 Implement `IndividualAdditionalDataModel` (`makeEditor`, `commit`, `dataForNewVisit`); verified when [tests: newVisitGetsCurrentTemplateCopy, cancellingEditorKeepsTemplate] pass
- [x] 5.2 Implement em `VisitEditorModel` (change 4) a propriedade `additionalData`, montada a partir do modelo para visita nova (lido do banco por `ChildDetailModel.makeVisitEditor`, D12) e do XML para visita existente, com `canSave` exigindo `additionalData.canSave` e gravando o XML pela regra de D11, unit tests first para XML `nil` e ilegível preservados; verified when [tests: savedVisitKeepsStructureAfterTemplateChange] pass and the change 4 suite stays green
- [x] 5.3 Refactor a integração; `swift test` stays green

## 6. Integração com o inquérito

- [x] 6.1 Implement em `RecordEditorModel` a propriedade `additionalData` (definição do inquérito para registro novo, XML do registro para existente), `canSave` exigindo `additionalData.canSave` e a gravação do XML em `makeRecord()` pela regra de D11, unit tests first para número carregado fora do limite que não bloqueia; verified when [tests: newRecordStoresValuesFromSurveyDefinition, existingRecordFormUsesRecordStructure, invalidAdditionalValueBlocksRecordSave] pass
- [x] 6.2 Implement em `SurveyDetailModel` `additionalDataDefinition`, `makeAdditionalDataDefinitionEditor` e `applyAdditionalDataDefinition` com marcação de pendência e reconstrução das colunas; verified when [tests: surveyDefinitionIsAppliedMarkedAndSaved, existingRecordKeepsOldVariableAfterDefinitionChange] pass
- [x] 6.3 Implement o caso `.additional` em `SurveyTableColumn`, `SurveyRecordRow.text` para colunas adicionais, ordenação tipada (data cronológica) e inclusão em `columns`, filtro e cópia; verified when [tests: additionalCellsRenderTextNumberAndDate, missingAdditionalVariableRendersEmpty, additionalDateColumnSortsChronologically, additionalColumnIsFilterableAndCopied] pass and the change 5 suite stays green
- [x] 6.4 Refactor a integração com o inquérito; `swift test` stays green

## 7. Interface SwiftUI

- [x] 7.1 Implement `AdditionalDataEditorSheet` (árvore com `OutlineGroup`, campos de identificador, descrição, tipo, mínimo e máximo), `AdditionalDataFormSection` reutilizada nas folhas de visita e de registro, item de menu "Gerenciar dados adicionais" na avaliação individual e botão "Dados adicionais" no inquérito aberto e colunas adicionais na tabela a partir do macOS 14.4 (D13), sem regra de negócio; verified when `scripts/build-app.sh` termina com código 0 e `swift test` continua verde
- [x] 7.2 Verificação manual registrada (N/A non-executable): editar o modelo, criar visita e registro com valores, conferir colunas na tabela do inquérito; critério mecânico: `codesign --verify build/AnthroPlus.app` termina com código 0
- [x] 7.3 Refactor das views; `swift test` stays green

## 8. Verification

- [x] 8.1 Mutation check for additional-data: trocar a ordem de atributos de `Num` para `ID`, `Descr`, `Min`, `Max` em `AdditionalDataXML.encode`, ver `templateRoundTripIsByteIdentical` falhar, reverter
- [x] 8.2 Mutation check for additional-data: fazer `AdditionalDataColumns.structure` começar o sufixo em 1, ver `duplicateAndForbiddenKeysGetNumericSuffix` falhar, reverter
- [x] 8.3 Run the full suite fresh (`swift test`); all green, output free of errors and warnings

## Workflow follow-up

- Produce evidence.md (`openspec instructions evidence --change add-additional-data`) and reach `DECISION: PASS`
- Archive the change
