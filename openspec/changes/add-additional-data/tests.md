# Tests

## Test Strategy

- **Framework**: swift-testing (`import Testing`, `@Test`, `#expect`, `#require`), com `@MainActor` nos testes de view model.
- **Full-suite command**: `swift test`
- **Conventions**: testes de cenário em arquivos `*ScenarioTests.swift`; unitários do laço interno em arquivos sem o sufixo. O XML do modelo padrão é comparado com o valor literal de `reference/original-help/WHO AnthroPlus.exe.config`, desescapado uma vez (o arquivo de configuração guarda `&amp;amp;`, e o XML real tem `Fruit&amp;veg`), nunca com `AdditionalDataTemplates.individualAssessmentDefaultXML`, para que um stub neutro não passe: em `Tests/AnthroCoreTests/Fixtures/ia-additional-data-template.xml` para o alvo que já tem recursos, e como constante literal `iaTemplateXML` em `Support/AdditionalDataFixtures.swift` de `AnthroStoreTests` e `AnthroFeaturesTests`, que não têm recursos no `Package.swift`. Banco real em arquivo temporário; `VisitRepository` e `ChildDetailModel` reais da change 4; `SurveyDetailModel` e `RecordEditorModel` reais da change 5. Datas ao meio-dia do calendário do usuário (`Calendar.current`), pelos helpers `day("2021-04-01")` de `AnthroFeaturesTests` e `localDate` de `AnthroCoreTests`, a normalização das changes 4 e 5. A migração 4 entra no commit vermelho registrada em `Migrations.all` com SQL vazio (nenhum outro teste semeia a tabela por SQL), e os dois testes da migração consultam `sqlite_master` e a mensagem do erro, para falhar por asserção contra ela; o SQL é preenchido no verde.
- **Mutation tool**: manual.

## Spec-to-Test Mapping

### Capability: additional-data

#### Scenario: Modelo padrão do original
- **Test name**: `decodesOriginalIndividualTemplate`
- **Test file**: `Tests/AnthroCoreTests/AdditionalDataXMLScenarioTests.swift`
- **Level**: acceptance
- **Breaks if**: o decodificador lê só o primeiro `Cat` ou ignora o atributo `Max` de `Num`.
- **Expected red**: expected 4 sections, got 0.

#### Scenario: Valores inválidos e elemento desconhecido
- **Test name**: `invalidValuesBecomeNilAndUnknownElementsAreSkipped`
- **Test file**: `Tests/AnthroCoreTests/AdditionalDataXMLScenarioTests.swift`
- **Level**: acceptance
- **Breaks if**: o decodificador lança erro diante de número inválido, ou cria variável para `<Bool>`.
- **Expected red**: expected section "A" with 2 variables, got no sections.

#### Scenario: Atributo obrigatório ausente
- **Test name**: `missingDescrAttributeThrows`
- **Test file**: `Tests/AnthroCoreTests/AdditionalDataXMLScenarioTests.swift`
- **Level**: acceptance
- **Breaks if**: atributo ausente é tratado como "".
- **Expected red**: expected `AdditionalDataXMLError.invalid`, got no error.

#### Scenario: Texto ausente
- **Test name**: `nilOrEmptyXMLDecodesToEmptyData`
- **Test file**: `Tests/AnthroCoreTests/AdditionalDataXMLScenarioTests.swift`
- **Level**: acceptance
- **Breaks if**: `decode(nil)` lança erro, como `new AdditionalData(null)` no original.
- **Expected red**: expected re-encoded text `<Data />`, got "".

#### Scenario: Ida e volta do modelo padrão
- **Test name**: `templateRoundTripIsByteIdentical`
- **Test file**: `Tests/AnthroCoreTests/AdditionalDataXMLScenarioTests.swift`
- **Level**: acceptance
- **Breaks if**: `Num` grava `ID` antes de `Min`, ou `Txt` vazio sai autofechado.
- **Expected red**: expected the literal template string, got "".

#### Scenario: Dados sem seções e seção sem variáveis
- **Test name**: `emptyDataAndEmptySectionSerializeSelfClosing`
- **Test file**: `Tests/AnthroCoreTests/AdditionalDataXMLScenarioTests.swift`
- **Level**: acceptance
- **Breaks if**: o escritor gera `<Data></Data>` ou omite o espaço antes de `/>`.
- **Expected red**: expected `<Data />`, got "".

#### Scenario: Número e data gravados
- **Test name**: `numberUsesPointAndDateUsesOriginalFormat`
- **Test file**: `Tests/AnthroCoreTests/AdditionalDataXMLScenarioTests.swift`
- **Level**: acceptance
- **Breaks if**: o número é formatado com `Locale(pt_BR)` ou a data perde a parte ` 00:00:00`.
- **Expected red**: expected XML containing `>1.5</Num>`, got "".

#### Scenario: Número com vírgula na leitura
- **Test name**: `decoderAcceptsCommaDecimals`
- **Test file**: `Tests/AnthroCoreTests/AdditionalDataXMLScenarioTests.swift`
- **Level**: acceptance
- **Breaks if**: o decodificador usa `Decimal(string:)` só com ponto.
- **Expected red**: expected value 2.25, got no variable.

#### Scenario: Banco novo
- **Test name**: `migrationFourSeedsIndividualTemplate`
- **Test file**: `Tests/AnthroStoreTests/AdditionalDataTemplateScenarioTests.swift`
- **Level**: integration
- **Breaks if**: a migração cria a tabela sem inserir o modelo padrão.
- **Expected red**: expected template with 4 sections, got 0.

#### Scenario: Modelo editado persiste
- **Test name**: `editedTemplateSurvivesReopen`
- **Test file**: `Tests/AnthroStoreTests/AdditionalDataTemplateScenarioTests.swift`
- **Level**: integration
- **Breaks if**: `saveIndividualAssessmentTemplate` grava fora da tabela ou o leitor devolve sempre o padrão embutido.
- **Expected red**: expected 5 sections after reopen, got 0.

#### Scenario: Visita nova depois de editar o modelo
- **Test name**: `newVisitGetsCurrentTemplateCopy`
- **Test file**: `Tests/AnthroFeaturesTests/IndividualAdditionalDataScenarioTests.swift`
- **Level**: acceptance
- **Breaks if**: `dataForNewVisit` devolve o padrão embutido em vez do modelo atual, ou `ChildDetailModel.makeVisitEditor` monta a visita nova sem ler o modelo gravado.
- **Expected red**: expected 5 sections, last "Escola", got 0 sections (o teste confere `dataForNewVisit()` e o formulário do editor criado pela ficha).

#### Scenario: Visita antiga não muda com o modelo
- **Test name**: `savedVisitKeepsStructureAfterTemplateChange`
- **Test file**: `Tests/AnthroFeaturesTests/IndividualAdditionalDataScenarioTests.swift`
- **Level**: integration
- **Breaks if**: a carga da visita monta o formulário a partir do modelo atual em vez do XML da visita.
- **Expected red**: expected reloaded visit to contain section "Health", got no sections.

#### Scenario: Definição aplicada e salva
- **Test name**: `surveyDefinitionIsAppliedMarkedAndSaved`
- **Test file**: `Tests/AnthroFeaturesTests/SurveyAdditionalDataScenarioTests.swift`
- **Level**: acceptance
- **Breaks if**: `applyAdditionalDataDefinition` troca a definição sem marcar `hasUnsavedChanges`.
- **Expected red**: expected reloaded definition with section "Escola", got none.

#### Scenario: Registro antigo mantém seus dados
- **Test name**: `existingRecordKeepsOldVariableAfterDefinitionChange`
- **Test file**: `Tests/AnthroFeaturesTests/SurveyAdditionalDataScenarioTests.swift`
- **Level**: acceptance
- **Breaks if**: aplicar a definição reescreve o XML dos registros existentes.
- **Expected red**: o teste exige que a definição aplicada contenha "Turma" antes de checar o registro; contra o stub, expected variable "Turma", got none.

#### Scenario: Variável incluída a partir de variável selecionada
- **Test name**: `addVariableFromSelectedVariableAppendsToItsSection`
- **Test file**: `Tests/AnthroFeaturesTests/AdditionalDataEditorScenarioTests.swift`
- **Level**: acceptance
- **Breaks if**: a variável nova é anexada como filha da variável (estrutura inválida) ou numa seção nova.
- **Expected red**: expected section "A" with 2 variables, got 0 sections.

#### Scenario: Incluir variável sem seleção
- **Test name**: `addVariableRequiresSelection`
- **Test file**: `Tests/AnthroFeaturesTests/AdditionalDataEditorScenarioTests.swift`
- **Level**: acceptance
- **Breaks if**: `canAddVariable` ignora a seleção.
- **Expected red**: expected `canAddVariable == true` with section selected, got false.

#### Scenario: Identificador aparado
- **Test name**: `identifierIsTrimmedAndEmptyDescriptionIsNil`
- **Test file**: `Tests/AnthroFeaturesTests/AdditionalDataEditorScenarioTests.swift`
- **Level**: acceptance
- **Breaks if**: `setIdentifier` grava o texto sem aparar.
- **Expected red**: expected section "Escola", got no sections.

#### Scenario: Seção sem identificador
- **Test name**: `emptySectionIdentifierThrowsOnApply`
- **Test file**: `Tests/AnthroFeaturesTests/AdditionalDataEditorScenarioTests.swift`
- **Level**: acceptance
- **Breaks if**: `apply` valida só variáveis.
- **Expected red**: expected `AdditionalDataEditorError.emptyIdentifier`, got no error.

#### Scenario: Variáveis repetidas na mesma seção
- **Test name**: `duplicateVariableInSectionThrowsOnApply`
- **Test file**: `Tests/AnthroFeaturesTests/AdditionalDataEditorScenarioTests.swift`
- **Level**: acceptance
- **Breaks if**: a checagem de repetição é removida (fidelidade cega ao original).
- **Expected red**: expected `.duplicateIdentifier(section: "A", variable: "x")`, got no error.

#### Scenario: Mesmo identificador em seções diferentes
- **Test name**: `sameVariableInDifferentSectionsIsAccepted`
- **Test file**: `Tests/AnthroFeaturesTests/AdditionalDataEditorScenarioTests.swift`
- **Level**: acceptance
- **Breaks if**: a checagem de repetição compara variáveis de todas as seções juntas.
- **Expected red**: expected applied definition with 2 sections, got 0.

#### Scenario: Número vira data
- **Test name**: `changingKindKeepsPositionAndIdentifier`
- **Test file**: `Tests/AnthroFeaturesTests/AdditionalDataEditorScenarioTests.swift`
- **Level**: acceptance
- **Breaks if**: a variável substituída é movida para o fim da seção.
- **Expected red**: expected second variable of kind date with identifier "n", got no variables.

#### Scenario: Texto vira número sem limites
- **Test name**: `textToNumberStartsWithoutLimits`
- **Test file**: `Tests/AnthroFeaturesTests/AdditionalDataEditorScenarioTests.swift`
- **Level**: acceptance
- **Breaks if**: a troca reaproveita limites de uma variável numérica anterior.
- **Expected red**: expected number kind with nil limits, got no variable.

#### Scenario: Mínimo acima do máximo
- **Test name**: `minimumAboveMaximumIsClamped`
- **Test file**: `Tests/AnthroFeaturesTests/AdditionalDataEditorScenarioTests.swift`
- **Level**: acceptance
- **Breaks if**: `setMinimum` grava sem comparar com o máximo.
- **Expected red**: expected minimum 10, got no variable.

#### Scenario: Máximo abaixo do mínimo e limite vazio
- **Test name**: `maximumBelowMinimumIsClampedAndEmptyAllowed`
- **Test file**: `Tests/AnthroFeaturesTests/AdditionalDataEditorScenarioTests.swift`
- **Level**: acceptance
- **Breaks if**: `setMinimum(nil)` é rejeitado ou mantém o valor anterior.
- **Expected red**: expected maximum 5 and minimum nil, got no variable.

#### Scenario: Excluir seção
- **Test name**: `deletingSectionRemovesItsVariables`
- **Test file**: `Tests/AnthroFeaturesTests/AdditionalDataEditorScenarioTests.swift`
- **Level**: acceptance
- **Breaks if**: excluir seção remove só a primeira variável dela.
- **Expected red**: expected 3 sections, got 0.

#### Scenario: Cancelar a edição
- **Test name**: `cancellingEditorKeepsTemplate`
- **Test file**: `Tests/AnthroFeaturesTests/IndividualAdditionalDataScenarioTests.swift`
- **Level**: acceptance
- **Breaks if**: o editor recebe o modelo por referência compartilhada e as exclusões vazam.
- **Expected red**: expected template with 4 sections, got 0.

#### Scenario: Texto e data preenchidos
- **Test name**: `valuesFormStoresTrimmedTextAndDate`
- **Test file**: `Tests/AnthroFeaturesTests/AdditionalDataValuesScenarioTests.swift`
- **Level**: acceptance
- **Breaks if**: `setText` não apara o texto.
- **Expected red**: expected "3º ano", got no variable.

#### Scenario: Texto apagado
- **Test name**: `clearedTextBecomesNilAndOpenCloseElement`
- **Test file**: `Tests/AnthroFeaturesTests/AdditionalDataValuesScenarioTests.swift`
- **Level**: acceptance
- **Breaks if**: texto vazio é guardado como "" e o escritor gera `<Txt ... />`.
- **Expected red**: expected XML containing `<Txt ID="t" Descr=""></Txt>`, got "".

#### Scenario: Número dentro dos limites
- **Test name**: `numberWithCommaIsParsedAndShownWithTwoDecimals`
- **Test file**: `Tests/AnthroFeaturesTests/AdditionalDataValuesScenarioTests.swift`
- **Level**: acceptance
- **Breaks if**: `displayText` usa as casas do valor em vez de 2 fixas, ou o formulário avalia com `places: 0`.
- **Expected red**: expected display "7,50", got "".

#### Scenario: Número fora dos limites e texto inválido
- **Test name**: `outOfRangeAndInvalidNumbersWarnAndBlockSave`
- **Test file**: `Tests/AnthroFeaturesTests/AdditionalDataValuesScenarioTests.swift`
- **Level**: acceptance
- **Breaks if**: o intervalo passado a `MeasurementInput.evaluate` ignora o máximo da variável, ou `canSave` considera só `.invalid`.
- **Expected red**: expected outcome `.outOfRange(0...140)` for "Sport", got `.empty` (stub de `outcome`).

#### Scenario: Registro bloqueado por dado adicional inválido
- **Test name**: `invalidAdditionalValueBlocksRecordSave`
- **Test file**: `Tests/AnthroFeaturesTests/SurveyAdditionalDataScenarioTests.swift`
- **Level**: acceptance
- **Breaks if**: `RecordEditorModel.canSave` não consulta `additionalData.canSave`.
- **Expected red**: o teste exige que o formulário do registro tenha o campo "Sport" antes de digitar; contra o stub, expected field "Sport", got no fields.

#### Scenario: Rótulos traduzidos
- **Test name**: `defaultTemplateLabelsAreTranslated`
- **Test file**: `Tests/AnthroFeaturesTests/AdditionalDataValuesScenarioTests.swift`
- **Level**: acceptance
- **Breaks if**: a tabela de rótulos perde uma entrada ou o formulário usa o identificador cru.
- **Expected red**: expected section titles ["Maturação", "Atividade física", "Alimentação", "Saúde"], got [].

#### Scenario: Identificador da usuária
- **Test name**: `userIdentifierIsShownAsTypedAndKeptInXML`
- **Test file**: `Tests/AnthroFeaturesTests/AdditionalDataValuesScenarioTests.swift`
- **Level**: acceptance
- **Breaks if**: `display` devolve "" ou traduz identificadores desconhecidos.
- **Expected red**: expected "Escola", got "".

#### Scenario: Registro novo com definição
- **Test name**: `newRecordStoresValuesFromSurveyDefinition`
- **Test file**: `Tests/AnthroFeaturesTests/SurveyAdditionalDataScenarioTests.swift`
- **Level**: acceptance
- **Breaks if**: `makeRecord` mantém o XML da definição sem os valores digitados.
- **Expected red**: expected the exact `<Data><Cat ID="Escola" ...>3º ano</Txt></Cat></Data>` string, got "".

#### Scenario: Registro existente com estrutura antiga
- **Test name**: `existingRecordFormUsesRecordStructure`
- **Test file**: `Tests/AnthroFeaturesTests/SurveyAdditionalDataScenarioTests.swift`
- **Level**: acceptance
- **Breaks if**: o editor de registro existente monta o formulário pela definição atual.
- **Expected red**: expected field labels ["Série"], got [].

#### Scenario: Colunas do modelo padrão
- **Test name**: `defaultTemplateAddsSevenColumns`
- **Test file**: `Tests/AnthroCoreTests/AdditionalDataColumnsScenarioTests.swift`
- **Level**: acceptance
- **Breaks if**: as colunas pulam a primeira seção ou seguem ordem alfabética.
- **Expected red**: expected 7 keys starting with "Menarche/spermarche", got [].

#### Scenario: Chaves repetidas
- **Test name**: `duplicateAndForbiddenKeysGetNumericSuffix`
- **Test file**: `Tests/AnthroCoreTests/AdditionalDataColumnsScenarioTests.swift`
- **Level**: acceptance
- **Breaks if**: o sufixo começa em 1 ou as chaves proibidas são ignoradas.
- **Expected red**: expected ["x", "x 2", "Sexo 2"], got [].

#### Scenario: Valores formatados
- **Test name**: `additionalCellsRenderTextNumberAndDate`
- **Test file**: `Tests/AnthroFeaturesTests/SurveyAdditionalDataScenarioTests.swift`
- **Level**: acceptance
- **Breaks if**: o número sai com ponto ou com 2 casas fixas, ou a data sai no formato do XML.
- **Expected red**: expected ["3º ano", "3,25", "01/02/2021"], got ["", "", ""].

#### Scenario: Variável ausente no registro
- **Test name**: `missingAdditionalVariableRendersEmpty`
- **Test file**: `Tests/AnthroFeaturesTests/SurveyAdditionalDataScenarioTests.swift`
- **Level**: acceptance
- **Breaks if**: a busca usa só o identificador da variável e acha "Série" para a coluna "Turma".
- **Expected red**: expected "Série" cell "3º ano", got "".

#### Scenario: Ordenação de data em ordem cronológica
- **Test name**: `additionalDateColumnSortsChronologically`
- **Test file**: `Tests/AnthroFeaturesTests/SurveyAdditionalDataScenarioTests.swift`
- **Level**: acceptance
- **Breaks if**: a coluna de data adicional é ordenada pelo texto exibido, como no original.
- **Expected red**: expected [15/01/2021, 01/02/2021, nil], got [01/02/2021, 15/01/2021, nil].

#### Scenario: Filtro e cópia com coluna adicional
- **Test name**: `additionalColumnIsFilterableAndCopied`
- **Test file**: `Tests/AnthroFeaturesTests/SurveyAdditionalDataScenarioTests.swift`
- **Level**: acceptance
- **Breaks if**: `columns` não inclui as colunas adicionais e o cabeçalho copiado para na coluna 19.
- **Expected red**: expected 2 visible rows, got 0.

#### Scenario: Tabela criada e preenchida
- **Test name**: `migrationFourCreatesTemplateTable`
- **Test file**: `Tests/AnthroStoreTests/AdditionalDataMigrationScenarioTests.swift`
- **Level**: integration
- **Breaks if**: `Migrations.additionalData` não é registrada em `Migrations.all` ou usa escopo com outro nome.
- **Expected red**: expected table `additional_data_templates` in `sqlite_master`, got none (migração 4 registrada com SQL vazio).

#### Scenario: XML obrigatório
- **Test name**: `templateXMLIsNotNull`
- **Test file**: `Tests/AnthroStoreTests/AdditionalDataMigrationScenarioTests.swift`
- **Level**: integration
- **Breaks if**: a coluna `xml` perde `NOT NULL`.
- **Expected red**: o teste exige que a mensagem do `StoreError.sqlite` contenha "NOT NULL constraint failed"; contra o stub, got "no such table: additional_data_templates".

## Coverage Ledger

| Capability | Scenario | Test file | Test name | Breaks if | Red (SHA: failure) | Green (SHA) | State |
|------------|----------|-----------|-----------|-----------|--------------------|-------------|-------|
| additional-data | Modelo padrão do original | Tests/AnthroCoreTests/AdditionalDataXMLScenarioTests.swift | decodesOriginalIndividualTemplate | lê só o primeiro Cat | d584f0f: AdditionalDataXMLScenarioTests.swift:18:9: Expectation failed: (data.sections.count → 0) == 4 | c68c579 | green |
| additional-data | Valores inválidos e elemento desconhecido | Tests/AnthroCoreTests/AdditionalDataXMLScenarioTests.swift | invalidValuesBecomeNilAndUnknownElementsAreSkipped | lança em número inválido | d584f0f: AdditionalDataXMLScenarioTests.swift:31:27: Expectation failed: try AdditionalDataXML.decode(xml).section("A") → nil | c68c579 | green |
| additional-data | Atributo obrigatório ausente | Tests/AnthroCoreTests/AdditionalDataXMLScenarioTests.swift | missingDescrAttributeThrows | ausente vira "" | d584f0f: AdditionalDataXMLScenarioTests.swift:38:9: Expectation failed: an error was expected but none was thrown and "AdditionalData(sections: [])" was returned | c68c579 | green |
| additional-data | Texto ausente | Tests/AnthroCoreTests/AdditionalDataXMLScenarioTests.swift | nilOrEmptyXMLDecodesToEmptyData | decode(nil) lança | d584f0f: AdditionalDataXMLScenarioTests.swift:49:9: Expectation failed: (AdditionalDataXML.encode(fromNil) → "") == "<Data />" | c68c579 | green |
| additional-data | Ida e volta do modelo padrão | Tests/AnthroCoreTests/AdditionalDataXMLScenarioTests.swift | templateRoundTripIsByteIdentical | ordem de atributos de Num | d584f0f: AdditionalDataXMLScenarioTests.swift:57:9: Expectation failed: AdditionalDataXML.encode(try AdditionalDataXML.decode(xml)) == xml | c68c579 | green |
| additional-data | Dados sem seções e seção sem variáveis | Tests/AnthroCoreTests/AdditionalDataXMLScenarioTests.swift | emptyDataAndEmptySectionSerializeSelfClosing | sem espaço antes de /> | d584f0f: AdditionalDataXMLScenarioTests.swift:62:9: Expectation failed: (AdditionalDataXML.encode(AdditionalData()) → "") == "<Data />" | c68c579 | green |
| additional-data | Número e data gravados | Tests/AnthroCoreTests/AdditionalDataXMLScenarioTests.swift | numberUsesPointAndDateUsesOriginalFormat | número com vírgula | d584f0f: AdditionalDataXMLScenarioTests.swift:74:9: Expectation failed: (xml → "").contains(#"ID="n" Descr="">1.5</Num>"# → "ID="n" Descr="">1.5</Num>") | c68c579 | green |
| additional-data | Número com vírgula na leitura | Tests/AnthroCoreTests/AdditionalDataXMLScenarioTests.swift | decoderAcceptsCommaDecimals | só ponto | d584f0f: AdditionalDataXMLScenarioTests.swift:82:28: Expectation failed: try AdditionalDataXML.decode(xml).variable(section: "A", variable: "n") → nil | c68c579 | green |
| additional-data | Banco novo | Tests/AnthroStoreTests/AdditionalDataTemplateScenarioTests.swift | migrationFourSeedsIndividualTemplate | sem seed do modelo | d584f0f: AdditionalDataTemplateScenarioTests.swift:15:9: Expectation failed: (template.sections.map(\.identifier) → []) == ["Maturation", "Physical activity", "Food", "Health"] | 4a52377 | green |
| additional-data | Modelo editado persiste | Tests/AnthroStoreTests/AdditionalDataTemplateScenarioTests.swift | editedTemplateSurvivesReopen | leitor devolve o embutido | d584f0f: AdditionalDataTemplateScenarioTests.swift:31:9: Expectation failed: (reread.sections.count → 0) == 5 | 4a52377 | green |
| additional-data | Visita nova depois de editar o modelo | Tests/AnthroFeaturesTests/IndividualAdditionalDataScenarioTests.swift | newVisitGetsCurrentTemplateCopy | usa o padrão embutido | d584f0f: IndividualAdditionalDataScenarioTests.swift:35:9: Expectation failed: (templates.dataForNewVisit().sections.count → 0) == 5 | 80c6326 | green |
| additional-data | Visita antiga não muda com o modelo | Tests/AnthroFeaturesTests/IndividualAdditionalDataScenarioTests.swift | savedVisitKeepsStructureAfterTemplateChange | monta pela estrutura atual | d584f0f: IndividualAdditionalDataScenarioTests.swift:64:9: Expectation failed: (stored.sections.map(\.identifier) → []).contains("Health") | 80c6326 | green |
| additional-data | Definição aplicada e salva | Tests/AnthroFeaturesTests/SurveyAdditionalDataScenarioTests.swift | surveyDefinitionIsAppliedMarkedAndSaved | não marca pendência | d584f0f: SurveyAdditionalDataScenarioTests.swift:43:9: Expectation failed: (m → AnthroFeatures.SurveyDetailModel).hasUnsavedChanges → false | 4c08c16 | green |
| additional-data | Registro antigo mantém seus dados | Tests/AnthroFeaturesTests/SurveyAdditionalDataScenarioTests.swift | existingRecordKeepsOldVariableAfterDefinitionChange | reescreve registros | d584f0f: SurveyAdditionalDataScenarioTests.swift:60:9: Expectation failed: (m.additionalDataDefinition.variable(section: "Escola", variable: "Turma") → nil) != nil | 4c08c16 | green |
| additional-data | Variável incluída a partir de variável selecionada | Tests/AnthroFeaturesTests/AdditionalDataEditorScenarioTests.swift | addVariableFromSelectedVariableAppendsToItsSection | anexa como filha da variável | d584f0f: AdditionalDataEditorScenarioTests.swift:19:27: Expectation failed: (e.definition → AdditionalData(sections: [])).section("A") → nil | 1223e5d | green |
| additional-data | Incluir variável sem seleção | Tests/AnthroFeaturesTests/AdditionalDataEditorScenarioTests.swift | addVariableRequiresSelection | ignora a seleção | d584f0f: AdditionalDataEditorScenarioTests.swift:33:9: Expectation failed: (e.definition → AdditionalData(sections: [])) == (original → AdditionalData(sections: [AnthroCore.AdditionalDataSection(identifier: "A", ... | 1223e5d | green |
| additional-data | Identificador aparado | Tests/AnthroFeaturesTests/AdditionalDataEditorScenarioTests.swift | identifierIsTrimmedAndEmptyDescriptionIsNil | sem aparar | d584f0f: AdditionalDataEditorScenarioTests.swift:45:9: Expectation failed: (applied.sections → []) == ([AdditionalDataSection(identifier: "Escola", description: nil)] → [AnthroCore.AdditionalDataSection(identifie... | 1223e5d | green |
| additional-data | Seção sem identificador | Tests/AnthroFeaturesTests/AdditionalDataEditorScenarioTests.swift | emptySectionIdentifierThrowsOnApply | valida só variáveis | d584f0f: AdditionalDataEditorScenarioTests.swift:52:9: Expectation failed: an error was expected but none was thrown and "AdditionalData(sections: [])" was returned | 1223e5d | green |
| additional-data | Variáveis repetidas na mesma seção | Tests/AnthroFeaturesTests/AdditionalDataEditorScenarioTests.swift | duplicateVariableInSectionThrowsOnApply | sem checagem de repetição | d584f0f: AdditionalDataEditorScenarioTests.swift:58:9: Expectation failed: an error was expected but none was thrown and "AdditionalData(sections: [])" was returned | 1223e5d | green |
| additional-data | Mesmo identificador em seções diferentes | Tests/AnthroFeaturesTests/AdditionalDataEditorScenarioTests.swift | sameVariableInDifferentSectionsIsAccepted | checagem global | d584f0f: AdditionalDataEditorScenarioTests.swift:66:9: Expectation failed: (applied.sections.count → 0) == 2 | 1223e5d | green |
| additional-data | Número vira data | Tests/AnthroFeaturesTests/AdditionalDataEditorScenarioTests.swift | changingKindKeepsPositionAndIdentifier | move para o fim | d584f0f: AdditionalDataEditorScenarioTests.swift:78:29: Expectation failed: (e.definition → AdditionalData(sections: [])).section("A") → nil | 1223e5d | green |
| additional-data | Texto vira número sem limites | Tests/AnthroFeaturesTests/AdditionalDataEditorScenarioTests.swift | textToNumberStartsWithoutLimits | reaproveita limites | d584f0f: AdditionalDataEditorScenarioTests.swift:90:28: Expectation failed: (e.definition.section("A")?.variables → nil).last → nil → nil | 1223e5d | green |
| additional-data | Mínimo acima do máximo | Tests/AnthroFeaturesTests/AdditionalDataEditorScenarioTests.swift | minimumAboveMaximumIsClamped | sem comparação | d584f0f: AdditionalDataEditorScenarioTests.swift:99:28: Expectation failed: (e.definition.section("A")?.variables → nil).first → nil → nil | 1223e5d | green |
| additional-data | Máximo abaixo do mínimo e limite vazio | Tests/AnthroFeaturesTests/AdditionalDataEditorScenarioTests.swift | maximumBelowMinimumIsClampedAndEmptyAllowed | rejeita nil | d584f0f: AdditionalDataEditorScenarioTests.swift:109:28: Expectation failed: (e.definition.section("A")?.variables → nil).first → nil → nil | 1223e5d | green |
| additional-data | Excluir seção | Tests/AnthroFeaturesTests/AdditionalDataEditorScenarioTests.swift | deletingSectionRemovesItsVariables | remove só uma variável | d584f0f: AdditionalDataEditorScenarioTests.swift:116:24: Expectation failed: e.definition.sections.firstIndex { $0.identifier == "Food" } → nil | 1223e5d | green |
| additional-data | Cancelar a edição | Tests/AnthroFeaturesTests/IndividualAdditionalDataScenarioTests.swift | cancellingEditorKeepsTemplate | referência compartilhada | d584f0f: IndividualAdditionalDataScenarioTests.swift:70:9: Expectation failed: (templates.template.sections.count → 0) == 4 | 80c6326 | green |
| additional-data | Texto e data preenchidos | Tests/AnthroFeaturesTests/AdditionalDataValuesScenarioTests.swift | valuesFormStoresTrimmedTextAndDate | sem aparar | d584f0f: AdditionalDataValuesScenarioTests.swift:19:9: Expectation failed: (result.variable(section: "Escola", variable: "Série")?.kind → nil) == (.text("3º ano") → .text(Optional("3º ano"))) | 57e5a1d | green |
| additional-data | Texto apagado | Tests/AnthroFeaturesTests/AdditionalDataValuesScenarioTests.swift | clearedTextBecomesNilAndOpenCloseElement | "" em vez de nil | d584f0f: AdditionalDataValuesScenarioTests.swift:30:9: Expectation failed: (result.variable(section: "S", variable: "t")?.kind → nil) == .text(nil) | 57e5a1d | green |
| additional-data | Número dentro dos limites | Tests/AnthroFeaturesTests/AdditionalDataValuesScenarioTests.swift | numberWithCommaIsParsedAndShownWithTwoDecimals | casas do valor ou places 0 | d584f0f: AdditionalDataValuesScenarioTests.swift:38:9: Expectation failed: (m.outcome(section: 1, variable: 0) → .empty) == (.value(num("7.5")) → .value(7.5)) | 57e5a1d | green |
| additional-data | Número fora dos limites e texto inválido | Tests/AnthroFeaturesTests/AdditionalDataValuesScenarioTests.swift | outOfRangeAndInvalidNumbersWarnAndBlockSave | ignora o máximo ou canSave só com invalid | d584f0f: AdditionalDataValuesScenarioTests.swift:50:9: Expectation failed: (m.outcome(section: 1, variable: 0) → .empty) == (.outOfRange(0...140) → .outOfRange(ClosedRange(0...140))) | 57e5a1d | green |
| additional-data | Registro bloqueado por dado adicional inválido | Tests/AnthroFeaturesTests/SurveyAdditionalDataScenarioTests.swift | invalidAdditionalValueBlocksRecordSave | canSave do registro ignora dados adicionais | d584f0f: SurveyAdditionalDataScenarioTests.swift:69:25: Expectation failed: editor.additionalData.fields.first { $0.sectionIndex == 1 && $0.variableIndex == 0 } → nil | ac37b38 | green |
| additional-data | Rótulos traduzidos | Tests/AnthroFeaturesTests/AdditionalDataValuesScenarioTests.swift | defaultTemplateLabelsAreTranslated | rótulo faltando | d584f0f: AdditionalDataValuesScenarioTests.swift:65:9: Expectation failed: (titles → []) == ["Maturação", "Atividade física", "Alimentação", "Saúde"] | 57e5a1d | green |
| additional-data | Identificador da usuária | Tests/AnthroFeaturesTests/AdditionalDataValuesScenarioTests.swift | userIdentifierIsShownAsTypedAndKeptInXML | traduz desconhecido | d584f0f: AdditionalDataValuesScenarioTests.swift:78:9: Expectation failed: (AdditionalDataLabels.display("Escola") → "") == "Escola" | 57e5a1d | green |
| additional-data | Registro novo com definição | Tests/AnthroFeaturesTests/SurveyAdditionalDataScenarioTests.swift | newRecordStoresValuesFromSurveyDefinition | XML sem valores | d584f0f: SurveyAdditionalDataScenarioTests.swift:85:9: Expectation failed: (stored.map(\.additionalDataXML) → [Optional("<Data><Cat ID=\"Escola\" Descr=\"\"><Txt ID=\"Série\" Descr=\"\"></Txt></Cat></Data>")]) ==... | ac37b38 | green |
| additional-data | Registro existente com estrutura antiga | Tests/AnthroFeaturesTests/SurveyAdditionalDataScenarioTests.swift | existingRecordFormUsesRecordStructure | monta pela definição | d584f0f: SurveyAdditionalDataScenarioTests.swift:93:9: Expectation failed: (editor.additionalData.fields.map(\.label) → []) == ["Série"] | ac37b38 | green |
| additional-data | Colunas do modelo padrão | Tests/AnthroCoreTests/AdditionalDataColumnsScenarioTests.swift | defaultTemplateAddsSevenColumns | ordem alfabética | d584f0f: AdditionalDataColumnsScenarioTests.swift:17:9: Expectation failed: (columns.map(\.key) → []) == (["Menarche/spermarche", "Self-reported", "Sport", "TV/computer", | 8f26ae8 | green |
| additional-data | Chaves repetidas | Tests/AnthroCoreTests/AdditionalDataColumnsScenarioTests.swift | duplicateAndForbiddenKeysGetNumericSuffix | sufixo começa em 1 | d584f0f: AdditionalDataColumnsScenarioTests.swift:32:9: Expectation failed: (columns.map(\.key) → []) == ["x", "x 2", "Sexo 2"] | 8f26ae8 | green |
| additional-data | Valores formatados | Tests/AnthroFeaturesTests/SurveyAdditionalDataScenarioTests.swift | additionalCellsRenderTextNumberAndDate | número com ponto | d584f0f: SurveyAdditionalDataScenarioTests.swift:103:9: Expectation failed: (additional.map { row.text($0) } → []) == ["3º ano", "3,25", "01/02/2021"] | 4c08c16 | green |
| additional-data | Variável ausente no registro | Tests/AnthroFeaturesTests/SurveyAdditionalDataScenarioTests.swift | missingAdditionalVariableRendersEmpty | busca sem seção | d584f0f: SurveyAdditionalDataScenarioTests.swift:112:9: Expectation failed: (additional.map(\.title) → []) == ["Série", "Turma"] | 4c08c16 | green |
| additional-data | Ordenação de data em ordem cronológica | Tests/AnthroFeaturesTests/SurveyAdditionalDataScenarioTests.swift | additionalDateColumnSortsChronologically | ordena pelo texto | d584f0f: SurveyAdditionalDataScenarioTests.swift:124:26: Expectation failed: m.columns.first { $0.isAdditional } → nil | 4c08c16 | green |
| additional-data | Filtro e cópia com coluna adicional | Tests/AnthroFeaturesTests/SurveyAdditionalDataScenarioTests.swift | additionalColumnIsFilterableAndCopied | colunas adicionais ausentes | d584f0f: SurveyAdditionalDataScenarioTests.swift:136:26: Expectation failed: m.columns.first { $0.isAdditional } → nil | 4c08c16 | green |
| additional-data | Tabela criada e preenchida | Tests/AnthroStoreTests/AdditionalDataMigrationScenarioTests.swift | migrationFourCreatesTemplateTable | migração não registrada | d584f0f: AdditionalDataMigrationScenarioTests.swift:20:9: Expectation failed: (tables.count → 0) == 1 | 4a52377 | green |
| additional-data | XML obrigatório | Tests/AnthroStoreTests/AdditionalDataMigrationScenarioTests.swift | templateXMLIsNotNull | sem NOT NULL | d584f0f: AdditionalDataMigrationScenarioTests.swift:37:9: Expectation failed: (message → "no such table: additional_data_templates").contains("NOT NULL constraint failed") | 4a52377 | green |

## Test Changes After Red

<!-- Append-only. Vazio no planejamento. -->
