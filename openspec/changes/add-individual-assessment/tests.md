# Tests

## Test Strategy

- **Framework**: swift-testing (`import Testing`, `@Test`, `#expect`, `#require`), com `@MainActor` nos testes de view model.
- **Full-suite command**: `swift test`
- **Conventions**: testes de cenário em `Tests/AnthroStoreTests/IndividualAssessment/` (repositórios, contra `AnthroDatabase` real) e `Tests/AnthroFeaturesTests/IndividualAssessment/` (view models). Cada teste abre um banco novo num diretório temporário com `AnthroDatabase.open(at:)` e `Migrations.all`, por um helper `IAFixtures.makeDatabase()` em `Support.swift` de cada pasta, e usa `AnthroEngine.shared()`. `today` e `randomDay` são sempre injetados; datas criadas por `IAFixtures.date("2021-09-01")` ao meio-dia do calendário do usuário (`Calendar.current`), a mesma normalização dos modelos, porque o motor conta o dia de calendário que a tela mostra (D10); meia-noite UTC cairia no dia anterior em São Paulo. Datas de partida inseridas por SQL vão como TEXT `yyyy-MM-dd`. `AppSettings` usa `UserDefaults(suiteName:)` exclusivo por teste. Os dados de partida (crianças, visitas, mães, pais, endereços) são inseridos com SQL direto por `IAFixtures.insertChild`, `insertVisit`, `insertMother`, `insertFather` e `insertAddress`, nunca pelos repositórios em teste, para que o vermelho venha da asserção sobre a unidade exercitada. Nenhum mock de banco nem de motor.
- **Stubs do portão vermelho**: valores neutros do tipo (`nil`, `[]`, `""`, `false`, `0`); `LookupSearchOutcome` devolve `.results([])`; propriedades armazenadas dos view models existem sem lógica nos setters; datas iniciais dos editores são `Date(timeIntervalSince1970: 0)`; `weightOutcome`, `lengthOrHeightOutcome` e `heightOutcome` devolvem `.empty`, avisos devolvem `nil`, `canSave` devolve `false` e `makeVisit()` devolve `VisitRecord(date: Date(timeIntervalSince1970: 0))` sem lançar. Os helpers `MeasurementInput`, `ApproximateBirthDate` e `AgeText` são os reais da change 3, não stubs.
- **Mutation tool**: manual.

## Spec-to-Test Mapping

### Capability: child-registry

#### Scenario: Criança salva e reaberta
- **Test name**: `childSavedAndReopenedKeepsAllFields`
- **Test file**: `Tests/AnthroStoreTests/IndividualAssessment/ChildRepositoryTests.swift`
- **Level**: integration
- **Breaks if**: `ChildRepository.save` deixa de gravar `follow_up_ref_to` ou `date_of_birth_is_approx`, ou a leitura troca o código de sexo 2 por `.boy`.
- **Expected red**: `#require(try repository.child(id:))` falha: expected ChildRecord, got nil.

#### Scenario: Textos em branco viram nulos
- **Test name**: `blankTextsAreStoredAsNil`
- **Test file**: `Tests/AnthroFeaturesTests/IndividualAssessment/ChildDetailModelTests.swift`
- **Level**: acceptance
- **Breaks if**: `ChildDetailModel.save` grava o texto sem `trimmingCharacters` ou grava "" em vez de `nil`.
- **Expected red**: expected firstName "Ana", got no row for the returned id 0.

#### Scenario: Criança com sexo informado
- **Test name**: `childWithSexIsSaved`
- **Test file**: `Tests/AnthroFeaturesTests/IndividualAssessment/ChildDetailModelTests.swift`
- **Level**: acceptance
- **Breaks if**: o mapeamento de `.boy` para a coluna `sex` grava 0 ou 2.
- **Expected red**: expected 1 row in children, got 0.

#### Scenario: Criança sem sexo
- **Test name**: `childWithoutSexIsRejected`
- **Test file**: `Tests/AnthroFeaturesTests/IndividualAssessment/ChildDetailModelTests.swift`
- **Level**: acceptance
- **Breaks if**: a guarda `draft.sex == nil` em `save()` é removida e o `CHECK (sex IN (1, 2))` some da migração.
- **Expected red**: expected error ChildValidationError.sexRequired, got no error (stub de `save` devolve 0 sem lançar).

#### Scenario: Próximo ID considera o arquivo
- **Test name**: `autoDisplayIDIncludesArchivedChildren`
- **Test file**: `Tests/AnthroFeaturesTests/IndividualAssessment/ChildDetailModelTests.swift`
- **Level**: acceptance
- **Breaks if**: `maxDisplayID()` filtra `is_archived = 0`.
- **Expected red**: expected displayID 13, got nil.

#### Scenario: Primeira criança do banco
- **Test name**: `firstChildGetsDisplayIDOne`
- **Test file**: `Tests/AnthroFeaturesTests/IndividualAssessment/ChildDetailModelTests.swift`
- **Level**: acceptance
- **Breaks if**: o cálculo usa `(maxDisplayID() ?? 1) + 1` ou começa de 0.
- **Expected red**: expected displayID 1, got nil.

#### Scenario: ID manual com automático desligado
- **Test name**: `manualDisplayIDWhenAutoAssignIsOff`
- **Test file**: `Tests/AnthroFeaturesTests/IndividualAssessment/ChildDetailModelTests.swift`
- **Level**: acceptance
- **Breaks if**: `isDisplayIDEditable` ignora `settings.autoAssignChildID` ou o save atribui ID mesmo desligado.
- **Expected red**: expected isDisplayIDEditable true, got false.

#### Scenario: Ordem e rótulo das linhas
- **Test name**: `activeListOrdersByDisplayIDWithNilFirst`
- **Test file**: `Tests/AnthroStoreTests/IndividualAssessment/ChildRepositoryTests.swift`
- **Level**: integration
- **Breaks if**: `list(archived:)` perde o `ORDER BY display_id ASC` ou `listTitle` omite os parênteses vazios.
- **Expected red**: expected ["Lima, Caio ()", "Souza, Bia (1)", "Silva, Ana (2)"], got [].

#### Scenario: Rótulo sem sobrenome
- **Test name**: `listTitleWithoutLastName`
- **Test file**: `Tests/AnthroStoreTests/IndividualAssessment/ChildRepositoryTests.swift`
- **Level**: acceptance
- **Breaks if**: `displayName` sempre insere ", " entre sobrenome e nome.
- **Expected red**: expected "Dora (5)", got "" (stub de `listTitle`).

#### Scenario: Arquivar duas de três crianças
- **Test name**: `archivingMovesCheckedChildrenToArchive`
- **Test file**: `Tests/AnthroFeaturesTests/IndividualAssessment/ChildListModelTests.swift`
- **Level**: acceptance
- **Breaks if**: `setArchived` grava `is_archived = 0` ou apaga visitas.
- **Expected red**: expected 1 active row, got 0.

#### Scenario: Restaurar sem marcação
- **Test name**: `archiveModeExposesOnlyRestoreAndBack`
- **Test file**: `Tests/AnthroFeaturesTests/IndividualAssessment/ChildListModelTests.swift`
- **Level**: acceptance
- **Breaks if**: `canCreate` ou `canSearch` não consultam `mode == .archive`, ou `canRestore` ignora `checkedIDs`.
- **Expected red**: expected mode .archive, got .active (stub de `showArchive` não muda o modo).

#### Scenario: Excluir criança com visitas
- **Test name**: `deletingChildRemovesItsVisits`
- **Test file**: `Tests/AnthroStoreTests/IndividualAssessment/ChildRepositoryTests.swift`
- **Level**: integration
- **Breaks if**: `delete` apaga só a linha de `children` e o `ON DELETE CASCADE` some da migração.
- **Expected red**: expected 0 visits, got 2 (stub de `delete` não apaga).

#### Scenario: Mãe compartilhada por irmãos
- **Test name**: `sharedMotherSurvivesUntilLastChildIsDeleted`
- **Test file**: `Tests/AnthroStoreTests/IndividualAssessment/ChildRepositoryTests.swift`
- **Level**: integration
- **Breaks if**: `delete` remove a mãe da criança excluída sem verificar outros filhos, ou não roda `OrphanCleanup`.
- **Expected red**: expected 1 child after the first delete, got 2 (stub de `delete` não apaga).

#### Scenario: Mãe sem filhos é removida
- **Test name**: `moduleLoadRemovesOrphanParentsAndAddresses`
- **Test file**: `Tests/AnthroFeaturesTests/IndividualAssessment/ChildListModelTests.swift`
- **Level**: acceptance
- **Breaks if**: `ChildListModel.load()` deixa de chamar `OrphanCleanup.run`.
- **Expected red**: expected 1 mother, got 2.

#### Scenario: Limpeza repetida preserva vinculados
- **Test name**: `orphanCleanupIsIdempotentAndKeepsLinkedRecords`
- **Test file**: `Tests/AnthroStoreTests/IndividualAssessment/ChildRepositoryTests.swift`
- **Level**: integration
- **Breaks if**: o SQL de limpeza apaga sem `NOT EXISTS` sobre `children`, ou a contagem devolvida não usa `changes()` do SQLite.
- **Expected red**: expected first run mothers 1, got 0 (stub devolve `OrphanCleanupResult(0, 0, 0)`).

#### Scenario: Prefixo com curinga
- **Test name**: `searchByLastNamePrefixWildcard`
- **Test file**: `Tests/AnthroStoreTests/IndividualAssessment/ChildRepositoryTests.swift`
- **Level**: integration
- **Breaks if**: `NameMatcher` traduz `*` para `.` ou omite `.caseInsensitive`.
- **Expected red**: expected ["Lopez", "lima"], got [].

#### Scenario: Sem curinga é igualdade
- **Test name**: `searchWithoutWildcardIsExactMatch`
- **Test file**: `Tests/AnthroStoreTests/IndividualAssessment/ChildRepositoryTests.swift`
- **Level**: integration
- **Breaks if**: `NameMatcher` não ancora o padrão (`^...$`) e passa a buscar substring.
- **Expected red**: expected 1 result for "lopez", got 0.

#### Scenario: Curinga de um caractere
- **Test name**: `questionMarkMatchesExactlyOneCharacter`
- **Test file**: `Tests/AnthroStoreTests/IndividualAssessment/ChildRepositoryTests.swift`
- **Level**: integration
- **Breaks if**: `?` vira `.*` ou é escapado como literal.
- **Expected red**: expected ["Ana"], got [].

#### Scenario: Maiúsculas e acentos
- **Test name**: `searchIgnoresCaseButNotAccents`
- **Test file**: `Tests/AnthroStoreTests/IndividualAssessment/ChildRepositoryTests.swift`
- **Level**: integration
- **Breaks if**: `NameMatcher` usa `.diacriticInsensitive`, ou a busca vai para `LIKE` do SQLite (que não dobra "É").
- **Expected red**: expected 1 result for "érica", got 0.

#### Scenario: Faixas de ID e de nascimento
- **Test name**: `searchCombinesSexIDRangeAndBirthRange`
- **Test file**: `Tests/AnthroFeaturesTests/IndividualAssessment/ChildListModelTests.swift`
- **Level**: acceptance
- **Breaks if**: a faixa de ID usa `<` em vez de `<=` ou a ordenação por ID some.
- **Expected red**: expected titles of IDs [2, 4], got [].

#### Scenario: Criança arquivada fica fora da busca
- **Test name**: `searchExcludesArchivedChildren`
- **Test file**: `Tests/AnthroStoreTests/IndividualAssessment/ChildRepositoryTests.swift`
- **Level**: integration
- **Breaks if**: `search` perde a condição `is_archived = 0`.
- **Expected red**: expected ["Lopes"], got [].

#### Scenario: Critérios vazios
- **Test name**: `emptyCriteriaClearsSearch`
- **Test file**: `Tests/AnthroFeaturesTests/IndividualAssessment/ChildListModelTests.swift`
- **Level**: acceptance
- **Breaks if**: `search` com `criteria.isEmpty` mantém `.searchResults`.
- **Expected red**: expected mode .active with 3 rows, got .active with 0 rows.

#### Scenario: IMC truncado da mãe
- **Test name**: `parentBMIIsTruncatedNotRounded`
- **Test file**: `Tests/AnthroFeaturesTests/IndividualAssessment/ParentAddressEditorTests.swift`
- **Level**: acceptance
- **Breaks if**: `bmiText` usa `ClinicalRounding.round` em vez de truncar.
- **Expected red**: expected "21,6", got "" (stub de `bmiText`).

#### Scenario: Altura fora do intervalo bloqueia o cadastro
- **Test name**: `parentHeightOutsideRangeBlocksSave`
- **Test file**: `Tests/AnthroFeaturesTests/IndividualAssessment/ParentAddressEditorTests.swift`
- **Level**: acceptance
- **Breaks if**: `parentHeightRange` vira `38...230`, ou `save()` grava com `heightOutcome` em `.outOfRange` em vez de lançar.
- **Expected red**: expected heightOutcome .outOfRange(50...300), got .empty.

#### Scenario: Altura vazia é permitida
- **Test name**: `parentWithEmptyHeightIsSaved`
- **Test file**: `Tests/AnthroFeaturesTests/IndividualAssessment/ParentAddressEditorTests.swift`
- **Level**: acceptance
- **Breaks if**: `canSave` trata `.empty` como inválido.
- **Expected red**: expected canSave true, got false.

#### Scenario: Nascimento desconhecido e futuro
- **Test name**: `parentBirthDateUnknownOrFuture`
- **Test file**: `Tests/AnthroFeaturesTests/IndividualAssessment/ParentAddressEditorTests.swift`
- **Level**: acceptance
- **Breaks if**: `save` grava a data do seletor mesmo com `dateOfBirthUnknown`, ou o setter não limita a `today()`.
- **Expected red**: expected dateOfBirth 2026-10-14, got 2026-10-20 (o stub guarda a data sem limitar).

#### Scenario: Rótulo de endereço
- **Test name**: `addressDisplayNameJoinsFilledFields`
- **Test file**: `Tests/AnthroStoreTests/IndividualAssessment/ParentAddressRepositoryTests.swift`
- **Level**: integration
- **Breaks if**: o separador antes do país vira ", " ou o ID sai do rótulo.
- **Expected red**: expected "Rua A, 10, São Paulo - Brasil (3)", got "".

#### Scenario: Endereço vazio
- **Test name**: `emptyAddressShowsNoDataLabel`
- **Test file**: `Tests/AnthroStoreTests/IndividualAssessment/ParentAddressRepositoryTests.swift`
- **Level**: integration
- **Breaks if**: o rótulo vazio deixa de usar "(Sem dados)".
- **Expected red**: expected "(Sem dados) (4)", got "".

#### Scenario: Mãe encontrada por trecho do sobrenome
- **Test name**: `motherSearchMatchesSubstringIgnoringCase`
- **Test file**: `Tests/AnthroStoreTests/IndividualAssessment/ParentAddressRepositoryTests.swift`
- **Level**: integration
- **Breaks if**: a busca compara o início do texto ou diferencia maiúsculas.
- **Expected red**: expected .results containing "Silva, Maria (1)", got .results([]).

#### Scenario: Resultados demais
- **Test name**: `lookupSearchReportsTooManyResults`
- **Test file**: `Tests/AnthroStoreTests/IndividualAssessment/ParentAddressRepositoryTests.swift`
- **Level**: integration
- **Breaks if**: a comparação com o limite usa `>=` ou o limite padrão deixa de ser 50.
- **Expected red**: expected .tooManyResults, got .results([]).

#### Scenario: Nenhum resultado
- **Test name**: `lookupSearchReportsNoResults`
- **Test file**: `Tests/AnthroStoreTests/IndividualAssessment/ParentAddressRepositoryTests.swift`
- **Level**: integration
- **Breaks if**: a busca vazia de resultados devolve `.results([])` em vez de `.noResults`.
- **Expected red**: expected .noResults, got .results([]).

#### Scenario: Nascimento depois da primeira visita
- **Test name**: `birthDateClampedToFirstVisit`
- **Test file**: `Tests/AnthroFeaturesTests/IndividualAssessment/ChildDetailModelTests.swift`
- **Level**: acceptance
- **Breaks if**: `setDateOfBirth` limita só a `today()` e ignora a primeira visita.
- **Expected red**: expected dateOfBirth 2021-09-01, got draft nil (stub de `open` não carrega a ficha).

#### Scenario: Nascimento futuro sem visitas
- **Test name**: `birthDateClampedToToday`
- **Test file**: `Tests/AnthroFeaturesTests/IndividualAssessment/ChildDetailModelTests.swift`
- **Level**: acceptance
- **Breaks if**: o limite superior usa `today() + 1 dia` ou não existe.
- **Expected red**: expected 2026-10-14, got draft nil (stub de `startNew` não cria rascunho).

#### Scenario: Dia sorteado em fevereiro bissexto
- **Test name**: `approximateBirthDayDrawsBeforeLastDay`
- **Test file**: `Tests/AnthroFeaturesTests/IndividualAssessment/ChildDetailModelTests.swift`
- **Level**: acceptance
- **Breaks if**: o modelo passa a `ApproximateBirthDate` um `randomDay` que sorteia em `1..<30` (inclui o último dia) ou não repassa o `randomDay` injetado.
- **Expected red**: expected randomDay called with 1..<29, got no call.

#### Scenario: Dia alterado com data aproximada
- **Test name**: `dayOnlyChangeIgnoredWhenApproximate`
- **Test file**: `Tests/AnthroFeaturesTests/IndividualAssessment/ChildDetailModelTests.swift`
- **Level**: acceptance
- **Breaks if**: `setDateOfBirth` chama `ApproximateBirthDate.adjusted` com `isApprox` falso ou grava a data proposta sem passar pelo helper.
- **Expected red**: expected 2016-02-10, got draft nil.

#### Scenario: Descartar e seguir
- **Test name**: `discardDecisionProceedsWithoutSaving`
- **Test file**: `Tests/AnthroFeaturesTests/IndividualAssessment/ChildDetailModelTests.swift`
- **Level**: acceptance
- **Breaks if**: `.discard` salva o rascunho ou devolve falso.
- **Expected red**: expected proceed true, got false.

#### Scenario: Cancelar a troca
- **Test name**: `cancelDecisionKeepsChildOpen`
- **Test file**: `Tests/AnthroFeaturesTests/IndividualAssessment/ChildDetailModelTests.swift`
- **Level**: acceptance
- **Breaks if**: `.cancel` devolve verdadeiro ou zera `hasUnsavedChanges`.
- **Expected red**: expected hasUnsavedChanges true, got false.

#### Scenario: Salvar falha por falta de sexo
- **Test name**: `saveDecisionWithoutSexBlocksNavigation`
- **Test file**: `Tests/AnthroFeaturesTests/IndividualAssessment/ChildDetailModelTests.swift`
- **Level**: acceptance
- **Breaks if**: `proceedAfterUnsavedChanges(.save)` engole o erro e devolve verdadeiro.
- **Expected red**: expected error ChildValidationError.sexRequired, got false without error.

### Capability: visit-tracking

#### Scenario: Valores iniciais de uma nova visita
- **Test name**: `newVisitStartsTodayStandingWithoutOedema`
- **Test file**: `Tests/AnthroFeaturesTests/IndividualAssessment/VisitEditorModelTests.swift`
- **Level**: acceptance
- **Breaks if**: o editor inicia `measuredRecumbent` verdadeiro ou usa outra data que não `today`.
- **Expected red**: expected date 2021-09-01, got 1970-01-01 (stub inicializa com `Date(timeIntervalSince1970: 0)`).

#### Scenario: Hoje anterior ao nascimento
- **Test name**: `newVisitDateNeverBeforeBirth`
- **Test file**: `Tests/AnthroFeaturesTests/IndividualAssessment/VisitEditorModelTests.swift`
- **Level**: acceptance
- **Breaks if**: o init não aplica o limite inferior do nascimento.
- **Expected red**: expected 2021-09-05, got 1970-01-01.

#### Scenario: Data anterior ao nascimento
- **Test name**: `visitDateClampedToBirth`
- **Test file**: `Tests/AnthroFeaturesTests/IndividualAssessment/VisitEditorModelTests.swift`
- **Level**: acceptance
- **Breaks if**: o setter de `date` aceita datas anteriores ao nascimento.
- **Expected red**: expected 2015-01-01, got 1970-01-01.

#### Scenario: Data de visita existente
- **Test name**: `existingVisitDateIsFrozen`
- **Test file**: `Tests/AnthroFeaturesTests/IndividualAssessment/VisitEditorModelTests.swift`
- **Level**: acceptance
- **Breaks if**: `isDateEditable` devolve verdadeiro para `editing != nil` ou o setter grava mesmo assim.
- **Expected red**: expected date 2021-09-01, got 1970-01-01.

#### Scenario: Data repetida
- **Test name**: `duplicateVisitDateIsRejected`
- **Test file**: `Tests/AnthroFeaturesTests/IndividualAssessment/VisitEditorModelTests.swift`
- **Level**: acceptance
- **Breaks if**: `makeVisit` não consulta `existingDates` para visitas novas.
- **Expected red**: expected error VisitValidationError.duplicateDate, got no error.

#### Scenario: Inserção na ordem das datas
- **Test name**: `committedVisitsStayInDateOrder`
- **Test file**: `Tests/AnthroFeaturesTests/IndividualAssessment/ChildDetailModelTests.swift`
- **Level**: acceptance
- **Breaks if**: `commitVisit` faz `append` sem ordenar.
- **Expected red**: expected dates [2021-01-10, 2021-05-05, 2021-09-01], got [].

#### Scenario: Peso com três casas
- **Test name**: `visitWeightIsTruncatedToTwoPlaces`
- **Test file**: `Tests/AnthroFeaturesTests/IndividualAssessment/VisitEditorModelTests.swift`
- **Level**: acceptance
- **Breaks if**: o editor chama `MeasurementInput.evaluate` com `places: 1` ou arredonda o valor (21.57) em vez de usar o truncamento do helper.
- **Expected red**: expected 21.56, got nil.

#### Scenario: Limites inclusivos aceitos
- **Test name**: `visitMeasuresAcceptInclusiveLimits`
- **Test file**: `Tests/AnthroFeaturesTests/IndividualAssessment/VisitEditorModelTests.swift`
- **Level**: acceptance
- **Breaks if**: o editor passa ao helper um intervalo aberto (`InputLimits.minLengthOrHeight` exclusivo) ou outro intervalo que não `InputLimits`.
- **Expected red**: expected weight 275, got nil.

#### Scenario: Fora do limite fica fora do cálculo
- **Test name**: `visitMeasureOutOfRangeIsExcludedFromCalculation`
- **Test file**: `Tests/AnthroFeaturesTests/IndividualAssessment/VisitEditorModelTests.swift`
- **Level**: acceptance
- **Breaks if**: o editor limita o valor ao máximo (275) em vez de anular, ou deixa de expor `weightWarning`.
- **Expected red**: expected weightOutcome .outOfRange(0.9...275), got .empty.

#### Scenario: Peso fora do limite bloqueia a visita
- **Test name**: `visitWithOutOfRangeWeightCannotBeSaved`
- **Test file**: `Tests/AnthroFeaturesTests/IndividualAssessment/VisitEditorModelTests.swift`
- **Level**: acceptance
- **Breaks if**: `makeVisit()` devolve a visita com peso `nil` em vez de lançar `.invalidMeasurement`, como o original.
- **Expected red**: expected error VisitValidationError.invalidMeasurement, got no error.

#### Scenario: Medida ilegível bloqueia a visita
- **Test name**: `visitWithInvalidLengthCannotBeSaved`
- **Test file**: `Tests/AnthroFeaturesTests/IndividualAssessment/VisitEditorModelTests.swift`
- **Level**: acceptance
- **Breaks if**: `canSave` só confere `.outOfRange` e ignora `.invalid`.
- **Expected red**: expected lengthOrHeightOutcome .invalid, got .empty.

#### Scenario: Peso vazio é permitido
- **Test name**: `visitWithEmptyWeightCanBeSaved`
- **Test file**: `Tests/AnthroFeaturesTests/IndividualAssessment/VisitEditorModelTests.swift`
- **Level**: acceptance
- **Breaks if**: `canSave` exige peso preenchido.
- **Expected red**: expected canSave true, got false.

#### Scenario: Visita aos 10 meses
- **Test name**: `measureChoiceEnabledUnderElevenMonths`
- **Test file**: `Tests/AnthroFeaturesTests/IndividualAssessment/VisitEditorModelTests.swift`
- **Level**: acceptance
- **Breaks if**: o limite vira `<= 10` meses inteiros com outra base de cálculo ou `< 61`.
- **Expected red**: expected isMeasureChoiceEnabled true, got false.

#### Scenario: Visita aos 11 meses com medida deitada marcada
- **Test name**: `measureChoiceForcedStandingFromElevenMonths`
- **Test file**: `Tests/AnthroFeaturesTests/IndividualAssessment/VisitEditorModelTests.swift`
- **Level**: acceptance
- **Breaks if**: mudar a data não reavalia a regra ou o limite segue a ajuda (60 meses).
- **Expected red**: expected measuredRecumbent false after moving to 335 days, got true (o stub guarda o valor sem forçar em pé).

#### Scenario: IMC exibido
- **Test name**: `visitBMIShownWithOneDecimal`
- **Test file**: `Tests/AnthroFeaturesTests/IndividualAssessment/VisitEditorModelTests.swift`
- **Level**: acceptance
- **Breaks if**: `bmiText` usa a medida sem ajuste ou trunca em vez de arredondar.
- **Expected red**: expected "15,3", got "".

#### Scenario: IMC com edema
- **Test name**: `visitBMIHiddenWithOedema`
- **Test file**: `Tests/AnthroFeaturesTests/IndividualAssessment/VisitEditorModelTests.swift`
- **Level**: acceptance
- **Breaks if**: `bmiText` ignora `hasOedema`.
- **Expected red**: expected "N/D", got "".

#### Scenario: Visita confirmada e criança salva
- **Test name**: `committedVisitPersistsOnlyWithChildSave`
- **Test file**: `Tests/AnthroFeaturesTests/IndividualAssessment/ChildDetailModelTests.swift`
- **Level**: acceptance
- **Breaks if**: `commitVisit` grava direto no banco ou `save` não chama `replaceVisits`.
- **Expected red**: expected 1 visit row with notes "retorno" after save, got 0.

#### Scenario: Exclusão descartada
- **Test name**: `discardRestoresDeletedVisit`
- **Test file**: `Tests/AnthroFeaturesTests/IndividualAssessment/ChildDetailModelTests.swift`
- **Level**: acceptance
- **Breaks if**: `deleteSelectedVisits` apaga do banco na hora ou `discardChanges` não recarrega as visitas.
- **Expected red**: expected visits [2021-09-01] after discard, got [].

#### Scenario: Excluir duas de três visitas
- **Test name**: `deletingSelectedVisitsPersistsOnSave`
- **Test file**: `Tests/AnthroFeaturesTests/IndividualAssessment/ChildDetailModelTests.swift`
- **Level**: acceptance
- **Breaks if**: `deleteSelectedVisits` remove só a primeira selecionada.
- **Expected red**: expected 1 visit row after save, got 3 (as 3 visitas de partida, inseridas por SQL, continuam porque o stub de `save` não grava nada).

#### Scenario: Ações de visita dependem da seleção
- **Test name**: `visitActionsFollowSelection`
- **Test file**: `Tests/AnthroFeaturesTests/IndividualAssessment/ChildDetailModelTests.swift`
- **Level**: acceptance
- **Breaks if**: `canDeleteVisit` olha `visits.isEmpty` em vez de `selectedVisitDates`.
- **Expected red**: expected canEditVisit true with one selected visit, got false.

#### Scenario: Linha de visita completa
- **Test name**: `visitRowFormatsColumns`
- **Test file**: `Tests/AnthroFeaturesTests/IndividualAssessment/ChildDetailModelTests.swift`
- **Level**: acceptance
- **Breaks if**: o peso sai com 1 casa ("21,6") ou edema e deitado ficam trocados.
- **Expected red**: expected VisitRow("01/09/2021", "21,60", "Não", "Não", "118,92"), got [] rows.

#### Scenario: Visita sem peso
- **Test name**: `visitRowLeavesMissingWeightEmpty`
- **Test file**: `Tests/AnthroFeaturesTests/IndividualAssessment/ChildDetailModelTests.swift`
- **Level**: acceptance
- **Breaks if**: o peso ausente sai como "N/D" ou "0,00".
- **Expected red**: expected 1 row with weight "", got [] rows.

#### Scenario: Menina de 80 meses na mediana
- **Test name**: `selectedVisitResultAtMedianForGirlAt80Months`
- **Test file**: `Tests/AnthroFeaturesTests/IndividualAssessment/ChildDetailModelTests.swift`
- **Level**: acceptance
- **Breaks if**: `selectedResult` usa a data de hoje em vez da data da visita, ou o sexo do registro salvo em vez do rascunho.
- **Expected red**: expected weightForAge.zScore 0.00, got selectedResult nil.

#### Scenario: Peso e IMC elevados
- **Test name**: `selectedVisitResultSeverities`
- **Test file**: `Tests/AnthroFeaturesTests/IndividualAssessment/ChildDetailModelTests.swift`
- **Level**: acceptance
- **Breaks if**: a gravidade é calculada sobre o percentil ou sobre z arredondado de outro indicador.
- **Expected red**: expected weightForAge.zScore 1.97, got selectedResult nil.

#### Scenario: Foco retirado da visita
- **Test name**: `selectedResultFollowsVisitFocus`
- **Test file**: `Tests/AnthroFeaturesTests/IndividualAssessment/ChildDetailModelTests.swift`
- **Level**: acceptance
- **Breaks if**: `selectedResult` cai para a última visita quando `focusedVisitDate` é nil.
- **Expected red**: expected non-nil selectedResult with focused visit, got nil.

#### Scenario: Idade de 80 meses
- **Test name**: `ageLabelForEightyMonths`
- **Test file**: `Tests/AnthroFeaturesTests/IndividualAssessment/ChildDetailModelTests.swift`
- **Level**: acceptance
- **Breaks if**: `ageLabel` arredonda os meses (81) ou omite o total entre parênteses.
- **Expected red**: expected "Idade: 6a 8m (80m)", got "".

#### Scenario: Idade abaixo de um ano
- **Test name**: `ageLabelUnderOneYear`
- **Test file**: `Tests/AnthroFeaturesTests/IndividualAssessment/ChildDetailModelTests.swift`
- **Level**: acceptance
- **Breaks if**: abaixo de 12 meses o rótulo inclui "0a".
- **Expected red**: expected "Idade: 10m", got "".

#### Scenario: Visita existente em foco
- **Test name**: `chartInputForExistingVisit`
- **Test file**: `Tests/AnthroFeaturesTests/IndividualAssessment/ChildDetailModelTests.swift`
- **Level**: acceptance
- **Breaks if**: `chartInput` duplica a visita em foco ou usa índice da lista não ordenada.
- **Expected red**: expected 3 results and currentIndex 1, got 0 results and currentIndex 0.

#### Scenario: Nova visita ainda não confirmada
- **Test name**: `chartInputInsertsUncommittedVisit`
- **Test file**: `Tests/AnthroFeaturesTests/IndividualAssessment/ChildDetailModelTests.swift`
- **Level**: acceptance
- **Breaks if**: `chartInput` só usa visitas da ficha ou altera `visits` ao inserir a nova.
- **Expected red**: expected 3 results and currentIndex 1, got 0 results and currentIndex 0.

## Coverage Ledger

| Capability | Scenario | Test file | Test name | Breaks if | Red (SHA: failure) | Green (SHA) | State |
|------------|----------|-----------|-----------|-----------|--------------------|-------------|-------|
| child-registry | Criança salva e reaberta | Tests/AnthroStoreTests/IndividualAssessment/ChildRepositoryTests.swift | childSavedAndReopenedKeepsAllFields | save deixa de gravar follow_up_ref_to | | | planned |
| child-registry | Textos em branco viram nulos | Tests/AnthroFeaturesTests/IndividualAssessment/ChildDetailModelTests.swift | blankTextsAreStoredAsNil | texto gravado sem trim | | | planned |
| child-registry | Criança com sexo informado | Tests/AnthroFeaturesTests/IndividualAssessment/ChildDetailModelTests.swift | childWithSexIsSaved | sexo .boy gravado como 0 ou 2 | | | planned |
| child-registry | Criança sem sexo | Tests/AnthroFeaturesTests/IndividualAssessment/ChildDetailModelTests.swift | childWithoutSexIsRejected | guarda de sexo removida | | | planned |
| child-registry | Próximo ID considera o arquivo | Tests/AnthroFeaturesTests/IndividualAssessment/ChildDetailModelTests.swift | autoDisplayIDIncludesArchivedChildren | maxDisplayID filtra arquivadas | | | planned |
| child-registry | Primeira criança do banco | Tests/AnthroFeaturesTests/IndividualAssessment/ChildDetailModelTests.swift | firstChildGetsDisplayIDOne | ID inicial diferente de 1 | | | planned |
| child-registry | ID manual com automático desligado | Tests/AnthroFeaturesTests/IndividualAssessment/ChildDetailModelTests.swift | manualDisplayIDWhenAutoAssignIsOff | isDisplayIDEditable ignora a configuração | | | planned |
| child-registry | Ordem e rótulo das linhas | Tests/AnthroStoreTests/IndividualAssessment/ChildRepositoryTests.swift | activeListOrdersByDisplayIDWithNilFirst | ORDER BY display_id removido | | | planned |
| child-registry | Rótulo sem sobrenome | Tests/AnthroStoreTests/IndividualAssessment/ChildRepositoryTests.swift | listTitleWithoutLastName | displayName insere vírgula sempre | | | planned |
| child-registry | Arquivar duas de três crianças | Tests/AnthroFeaturesTests/IndividualAssessment/ChildListModelTests.swift | archivingMovesCheckedChildrenToArchive | setArchived grava 0 | | | planned |
| child-registry | Restaurar sem marcação | Tests/AnthroFeaturesTests/IndividualAssessment/ChildListModelTests.swift | archiveModeExposesOnlyRestoreAndBack | flags ignoram o modo arquivo | | | planned |
| child-registry | Excluir criança com visitas | Tests/AnthroStoreTests/IndividualAssessment/ChildRepositoryTests.swift | deletingChildRemovesItsVisits | delete não apaga visitas | | | planned |
| child-registry | Mãe compartilhada por irmãos | Tests/AnthroStoreTests/IndividualAssessment/ChildRepositoryTests.swift | sharedMotherSurvivesUntilLastChildIsDeleted | delete não roda limpeza de órfãos | | | planned |
| child-registry | Mãe sem filhos é removida | Tests/AnthroFeaturesTests/IndividualAssessment/ChildListModelTests.swift | moduleLoadRemovesOrphanParentsAndAddresses | load não chama OrphanCleanup | | | planned |
| child-registry | Limpeza repetida preserva vinculados | Tests/AnthroStoreTests/IndividualAssessment/ChildRepositoryTests.swift | orphanCleanupIsIdempotentAndKeepsLinkedRecords | limpeza sem NOT EXISTS | | | planned |
| child-registry | Prefixo com curinga | Tests/AnthroStoreTests/IndividualAssessment/ChildRepositoryTests.swift | searchByLastNamePrefixWildcard | * traduzido para . | | | planned |
| child-registry | Sem curinga é igualdade | Tests/AnthroStoreTests/IndividualAssessment/ChildRepositoryTests.swift | searchWithoutWildcardIsExactMatch | padrão não ancorado | | | planned |
| child-registry | Curinga de um caractere | Tests/AnthroStoreTests/IndividualAssessment/ChildRepositoryTests.swift | questionMarkMatchesExactlyOneCharacter | ? vira .* | | | planned |
| child-registry | Maiúsculas e acentos | Tests/AnthroStoreTests/IndividualAssessment/ChildRepositoryTests.swift | searchIgnoresCaseButNotAccents | busca insensível a acentos | | | planned |
| child-registry | Faixas de ID e de nascimento | Tests/AnthroFeaturesTests/IndividualAssessment/ChildListModelTests.swift | searchCombinesSexIDRangeAndBirthRange | faixa de ID exclusiva | | | planned |
| child-registry | Criança arquivada fica fora da busca | Tests/AnthroStoreTests/IndividualAssessment/ChildRepositoryTests.swift | searchExcludesArchivedChildren | search sem is_archived = 0 | | | planned |
| child-registry | Critérios vazios | Tests/AnthroFeaturesTests/IndividualAssessment/ChildListModelTests.swift | emptyCriteriaClearsSearch | critério vazio mantém busca | | | planned |
| child-registry | IMC truncado da mãe | Tests/AnthroFeaturesTests/IndividualAssessment/ParentAddressEditorTests.swift | parentBMIIsTruncatedNotRounded | IMC arredondado | | | planned |
| child-registry | Altura fora do intervalo bloqueia o cadastro | Tests/AnthroFeaturesTests/IndividualAssessment/ParentAddressEditorTests.swift | parentHeightOutsideRangeBlocksSave | save grava altura fora do intervalo | | | planned |
| child-registry | Altura vazia é permitida | Tests/AnthroFeaturesTests/IndividualAssessment/ParentAddressEditorTests.swift | parentWithEmptyHeightIsSaved | .empty tratado como inválido | | | planned |
| child-registry | Nascimento desconhecido e futuro | Tests/AnthroFeaturesTests/IndividualAssessment/ParentAddressEditorTests.swift | parentBirthDateUnknownOrFuture | data futura aceita | | | planned |
| child-registry | Rótulo de endereço | Tests/AnthroStoreTests/IndividualAssessment/ParentAddressRepositoryTests.swift | addressDisplayNameJoinsFilledFields | separador do país trocado | | | planned |
| child-registry | Endereço vazio | Tests/AnthroStoreTests/IndividualAssessment/ParentAddressRepositoryTests.swift | emptyAddressShowsNoDataLabel | rótulo vazio sem (Sem dados) | | | planned |
| child-registry | Mãe encontrada por trecho do sobrenome | Tests/AnthroStoreTests/IndividualAssessment/ParentAddressRepositoryTests.swift | motherSearchMatchesSubstringIgnoringCase | busca por prefixo | | | planned |
| child-registry | Resultados demais | Tests/AnthroStoreTests/IndividualAssessment/ParentAddressRepositoryTests.swift | lookupSearchReportsTooManyResults | limite comparado com >= | | | planned |
| child-registry | Nenhum resultado | Tests/AnthroStoreTests/IndividualAssessment/ParentAddressRepositoryTests.swift | lookupSearchReportsNoResults | vazio vira .results([]) | | | planned |
| child-registry | Nascimento depois da primeira visita | Tests/AnthroFeaturesTests/IndividualAssessment/ChildDetailModelTests.swift | birthDateClampedToFirstVisit | limite ignora primeira visita | | | planned |
| child-registry | Nascimento futuro sem visitas | Tests/AnthroFeaturesTests/IndividualAssessment/ChildDetailModelTests.swift | birthDateClampedToToday | sem limite superior | | | planned |
| child-registry | Dia sorteado em fevereiro bissexto | Tests/AnthroFeaturesTests/IndividualAssessment/ChildDetailModelTests.swift | approximateBirthDayDrawsBeforeLastDay | sorteio inclui o último dia | | | planned |
| child-registry | Dia alterado com data aproximada | Tests/AnthroFeaturesTests/IndividualAssessment/ChildDetailModelTests.swift | dayOnlyChangeIgnoredWhenApproximate | troca só do dia aceita | | | planned |
| child-registry | Descartar e seguir | Tests/AnthroFeaturesTests/IndividualAssessment/ChildDetailModelTests.swift | discardDecisionProceedsWithoutSaving | .discard salva | | | planned |
| child-registry | Cancelar a troca | Tests/AnthroFeaturesTests/IndividualAssessment/ChildDetailModelTests.swift | cancelDecisionKeepsChildOpen | .cancel prossegue | | | planned |
| child-registry | Salvar falha por falta de sexo | Tests/AnthroFeaturesTests/IndividualAssessment/ChildDetailModelTests.swift | saveDecisionWithoutSexBlocksNavigation | erro de sexo engolido | | | planned |
| visit-tracking | Valores iniciais de uma nova visita | Tests/AnthroFeaturesTests/IndividualAssessment/VisitEditorModelTests.swift | newVisitStartsTodayStandingWithoutOedema | nova visita deitada | | | planned |
| visit-tracking | Hoje anterior ao nascimento | Tests/AnthroFeaturesTests/IndividualAssessment/VisitEditorModelTests.swift | newVisitDateNeverBeforeBirth | init sem limite inferior | | | planned |
| visit-tracking | Data anterior ao nascimento | Tests/AnthroFeaturesTests/IndividualAssessment/VisitEditorModelTests.swift | visitDateClampedToBirth | setter aceita data anterior | | | planned |
| visit-tracking | Data de visita existente | Tests/AnthroFeaturesTests/IndividualAssessment/VisitEditorModelTests.swift | existingVisitDateIsFrozen | data editável ao editar | | | planned |
| visit-tracking | Data repetida | Tests/AnthroFeaturesTests/IndividualAssessment/VisitEditorModelTests.swift | duplicateVisitDateIsRejected | makeVisit ignora existingDates | | | planned |
| visit-tracking | Inserção na ordem das datas | Tests/AnthroFeaturesTests/IndividualAssessment/ChildDetailModelTests.swift | committedVisitsStayInDateOrder | append sem ordenar | | | planned |
| visit-tracking | Peso com três casas | Tests/AnthroFeaturesTests/IndividualAssessment/VisitEditorModelTests.swift | visitWeightIsTruncatedToTwoPlaces | peso arredondado | | | planned |
| visit-tracking | Limites inclusivos aceitos | Tests/AnthroFeaturesTests/IndividualAssessment/VisitEditorModelTests.swift | visitMeasuresAcceptInclusiveLimits | intervalo exclusivo | | | planned |
| visit-tracking | Fora do limite fica fora do cálculo | Tests/AnthroFeaturesTests/IndividualAssessment/VisitEditorModelTests.swift | visitMeasureOutOfRangeIsExcludedFromCalculation | valor limitado ao máximo | | | planned |
| visit-tracking | Peso fora do limite bloqueia a visita | Tests/AnthroFeaturesTests/IndividualAssessment/VisitEditorModelTests.swift | visitWithOutOfRangeWeightCannotBeSaved | grava peso nil em silêncio | | | planned |
| visit-tracking | Medida ilegível bloqueia a visita | Tests/AnthroFeaturesTests/IndividualAssessment/VisitEditorModelTests.swift | visitWithInvalidLengthCannotBeSaved | canSave ignora .invalid | | | planned |
| visit-tracking | Peso vazio é permitido | Tests/AnthroFeaturesTests/IndividualAssessment/VisitEditorModelTests.swift | visitWithEmptyWeightCanBeSaved | canSave exige peso | | | planned |
| visit-tracking | Visita aos 10 meses | Tests/AnthroFeaturesTests/IndividualAssessment/VisitEditorModelTests.swift | measureChoiceEnabledUnderElevenMonths | limite de idade errado | | | planned |
| visit-tracking | Visita aos 11 meses com medida deitada marcada | Tests/AnthroFeaturesTests/IndividualAssessment/VisitEditorModelTests.swift | measureChoiceForcedStandingFromElevenMonths | regra não reavaliada ao mudar data | | | planned |
| visit-tracking | IMC exibido | Tests/AnthroFeaturesTests/IndividualAssessment/VisitEditorModelTests.swift | visitBMIShownWithOneDecimal | medida sem ajuste | | | planned |
| visit-tracking | IMC com edema | Tests/AnthroFeaturesTests/IndividualAssessment/VisitEditorModelTests.swift | visitBMIHiddenWithOedema | edema ignorado | | | planned |
| visit-tracking | Visita confirmada e criança salva | Tests/AnthroFeaturesTests/IndividualAssessment/ChildDetailModelTests.swift | committedVisitPersistsOnlyWithChildSave | commit grava direto | | | planned |
| visit-tracking | Exclusão descartada | Tests/AnthroFeaturesTests/IndividualAssessment/ChildDetailModelTests.swift | discardRestoresDeletedVisit | exclusão imediata no banco | | | planned |
| visit-tracking | Excluir duas de três visitas | Tests/AnthroFeaturesTests/IndividualAssessment/ChildDetailModelTests.swift | deletingSelectedVisitsPersistsOnSave | exclui só a primeira | | | planned |
| visit-tracking | Ações de visita dependem da seleção | Tests/AnthroFeaturesTests/IndividualAssessment/ChildDetailModelTests.swift | visitActionsFollowSelection | flags olham visits.isEmpty | | | planned |
| visit-tracking | Linha de visita completa | Tests/AnthroFeaturesTests/IndividualAssessment/ChildDetailModelTests.swift | visitRowFormatsColumns | peso com 1 casa | | | planned |
| visit-tracking | Visita sem peso | Tests/AnthroFeaturesTests/IndividualAssessment/ChildDetailModelTests.swift | visitRowLeavesMissingWeightEmpty | peso ausente como N/D | | | planned |
| visit-tracking | Menina de 80 meses na mediana | Tests/AnthroFeaturesTests/IndividualAssessment/ChildDetailModelTests.swift | selectedVisitResultAtMedianForGirlAt80Months | resultado com data de hoje | | | planned |
| visit-tracking | Peso e IMC elevados | Tests/AnthroFeaturesTests/IndividualAssessment/ChildDetailModelTests.swift | selectedVisitResultSeverities | gravidade sobre percentil | | | planned |
| visit-tracking | Foco retirado da visita | Tests/AnthroFeaturesTests/IndividualAssessment/ChildDetailModelTests.swift | selectedResultFollowsVisitFocus | cai para a última visita | | | planned |
| visit-tracking | Idade de 80 meses | Tests/AnthroFeaturesTests/IndividualAssessment/ChildDetailModelTests.swift | ageLabelForEightyMonths | meses arredondados | | | planned |
| visit-tracking | Idade abaixo de um ano | Tests/AnthroFeaturesTests/IndividualAssessment/ChildDetailModelTests.swift | ageLabelUnderOneYear | rótulo com 0a | | | planned |
| visit-tracking | Visita existente em foco | Tests/AnthroFeaturesTests/IndividualAssessment/ChildDetailModelTests.swift | chartInputForExistingVisit | visita em foco duplicada | | | planned |
| visit-tracking | Nova visita ainda não confirmada | Tests/AnthroFeaturesTests/IndividualAssessment/ChildDetailModelTests.swift | chartInputInsertsUncommittedVisit | nova visita ignorada | | | planned |

## Test Changes After Red
