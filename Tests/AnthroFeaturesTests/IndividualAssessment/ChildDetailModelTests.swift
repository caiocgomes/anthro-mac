import AnthroFeatures
import Foundation
import Testing

/// Cenários de child-registry e visit-tracking exercidos sobre `ChildDetailModel` (change add-individual-assessment).
@MainActor
@Suite("child-registry e visit-tracking: ChildDetailModel")
struct ChildDetailModelTests {
    let db: AnthroDatabase
    let engine: AnthroEngine

    init() throws {
        db = try IAFixtures.makeDatabase()
        engine = try AnthroEngine.shared()
    }

    private func model(autoAssign: Bool = true, today: String = "2026-10-14",
                       picker: IADayPicker = IADayPicker()) -> ChildDetailModel {
        ChildDetailModel(database: db, settings: IAFixtures.settings(autoAssignChildID: autoAssign), engine: engine,
                         today: { IAFixtures.date(today) }, randomDay: { picker($0) })
    }

    private func savedDisplayID(_ id: Int64) throws -> SQLValue {
        try #require(try IAFixtures.row(db, "children", where: "child_id = \(id)"))["display_id"]
    }

    private func visitDates(_ model: ChildDetailModel) -> [String?] {
        model.visits.map { IAFixtures.ymd($0.date) }
    }

    /// Menina nascida em 2015-01-01 com uma visita em 2021-09-01, aberta na ficha e com a visita em foco.
    private func girlWithVisit(weight: String) throws -> ChildDetailModel {
        let child = try IAFixtures.insertChild(db, firstName: "Ana", dateOfBirth: "2015-01-01", sex: 2)
        try IAFixtures.insertVisit(db, childID: child, date: "2021-09-01", weight: weight, height: "118.92")
        let m = model()
        try m.open(childID: child)
        m.focusedVisitDate = IAFixtures.date("2021-09-01")
        return m
    }

    // MARK: Persistência, sexo e ID

    // Scenario: Textos em branco viram nulos
    @Test func blankTextsAreStoredAsNil() throws {
        let m = model()
        m.startNew()
        m.update { draft in
            draft.firstName = "  Ana  "
            draft.lastName = "   "
            draft.notes = ""
            draft.sex = .girl
        }
        let id = try m.save()
        let row = try #require(try IAFixtures.row(db, "children", where: "child_id = \(id)"))
        #expect(row["first_name"] == .text("Ana"))
        #expect(row["last_name"] == .null)
        #expect(row["notes"] == .null)
    }

    // Scenario: Criança com sexo informado
    @Test func childWithSexIsSaved() throws {
        let m = model()
        m.startNew()
        m.update { $0.sex = .boy }
        try m.save()
        #expect(try IAFixtures.count(db, "children") == 1)
        #expect(try IAFixtures.count(db, "children", where: "sex = 1") == 1)
    }

    // Scenario: Criança sem sexo
    @Test func childWithoutSexIsRejected() throws {
        let m = model()
        m.startNew()
        #expect(throws: ChildValidationError.sexRequired) { try m.save() }
        #expect(try IAFixtures.count(db, "children") == 0)
    }

    // Scenario: Próximo ID considera o arquivo
    @Test func autoDisplayIDIncludesArchivedChildren() throws {
        try IAFixtures.insertChild(db, displayID: 3, firstName: "Ana")
        try IAFixtures.insertChild(db, displayID: 7, firstName: "Bia")
        try IAFixtures.insertChild(db, displayID: 12, firstName: "Caio", sex: 1, archived: true)
        let m = model(autoAssign: true)
        m.startNew()
        m.update { $0.sex = .girl }
        let id = try m.save()
        #expect(try savedDisplayID(id) == .integer(13))
    }

    // Scenario: Primeira criança do banco
    @Test func firstChildGetsDisplayIDOne() throws {
        let m = model(autoAssign: true)
        m.startNew()
        m.update { $0.sex = .boy }
        let id = try m.save()
        #expect(try savedDisplayID(id) == .integer(1))
    }

    // Scenario: ID manual com automático desligado
    @Test func manualDisplayIDWhenAutoAssignIsOff() throws {
        let m = model(autoAssign: false)
        m.startNew()
        #expect(m.isDisplayIDEditable == true)
        m.update { $0.sex = .boy }
        let id = try m.save()
        #expect(try savedDisplayID(id) == .null)
    }

    // MARK: Data de nascimento

    // Scenario: Nascimento depois da primeira visita
    @Test func birthDateClampedToFirstVisit() throws {
        let child = try IAFixtures.insertChild(db, firstName: "Ana", dateOfBirth: "2021-01-01")
        try IAFixtures.insertVisit(db, childID: child, date: "2021-09-01", weight: "10")
        try IAFixtures.insertVisit(db, childID: child, date: "2021-12-01", weight: "11")
        let m = model()
        try m.open(childID: child)
        m.setDateOfBirth(IAFixtures.date("2021-10-01"))
        #expect(IAFixtures.ymd(m.draft?.dateOfBirth) == "2021-09-01")
    }

    // Scenario: Nascimento futuro sem visitas
    @Test func birthDateClampedToToday() {
        let m = model(today: "2026-10-14")
        m.startNew()
        m.setDateOfBirth(IAFixtures.date("2026-10-20"))
        #expect(IAFixtures.ymd(m.draft?.dateOfBirth) == "2026-10-14")
    }

    // Scenario: Dia sorteado em fevereiro bissexto
    @Test func approximateBirthDayDrawsBeforeLastDay() {
        let picker = IADayPicker()
        picker.pick = { _ in 7 }
        let m = model(picker: picker)
        m.startNew()
        m.setDateOfBirth(IAFixtures.date("2016-02-10"))
        m.setDateOfBirthIsApprox(true)
        #expect(picker.ranges.last == 1..<29)
        #expect(IAFixtures.ymd(m.draft?.dateOfBirth) == "2016-02-07")
        #expect(m.draft?.dateOfBirthIsApprox == true)
    }

    // Scenario: Dia alterado com data aproximada
    @Test func dayOnlyChangeIgnoredWhenApproximate() throws {
        let child = try IAFixtures.insertChild(db, firstName: "Ana", dateOfBirth: "2016-02-10", isApprox: true)
        let m = model()
        try m.open(childID: child)
        m.setDateOfBirth(IAFixtures.date("2016-02-11"))
        #expect(IAFixtures.ymd(m.draft?.dateOfBirth) == "2016-02-10")
    }

    // MARK: Alterações não salvas

    // Scenario: Descartar e seguir
    @Test func discardDecisionProceedsWithoutSaving() throws {
        let child = try IAFixtures.insertChild(db, firstName: "Ana")
        let m = model()
        try m.open(childID: child)
        m.update { $0.firstName = "Bia" }
        #expect(try m.proceedAfterUnsavedChanges(.discard) == true)
        #expect(try IAFixtures.row(db, "children", where: "child_id = \(child)")?["first_name"] == .text("Ana"))
    }

    // Scenario: Cancelar a troca
    @Test func cancelDecisionKeepsChildOpen() throws {
        let child = try IAFixtures.insertChild(db, firstName: "Ana")
        let m = model()
        try m.open(childID: child)
        m.update { $0.firstName = "Bia" }
        #expect(m.hasUnsavedChanges == true)
        #expect(try m.proceedAfterUnsavedChanges(.cancel) == false)
        #expect(m.hasUnsavedChanges == true)
        #expect(m.draft?.id == child)
        #expect(m.draft?.firstName == "Bia")
    }

    // Scenario: Salvar falha por falta de sexo
    @Test func saveDecisionWithoutSexBlocksNavigation() throws {
        let m = model()
        m.startNew()
        m.update { $0.firstName = "Ana" }
        #expect(throws: ChildValidationError.sexRequired) { try m.proceedAfterUnsavedChanges(.save) }
        #expect(try IAFixtures.count(db, "children") == 0)
    }

    // MARK: Visitas na ficha

    // Scenario: Inserção na ordem das datas
    @Test func committedVisitsStayInDateOrder() throws {
        let child = try IAFixtures.insertChild(db, firstName: "Ana")
        try IAFixtures.insertVisit(db, childID: child, date: "2021-01-10", weight: "18")
        try IAFixtures.insertVisit(db, childID: child, date: "2021-09-01", weight: "21")
        let m = model(today: "2021-09-01")
        try m.open(childID: child)
        let editor = m.makeVisitEditor(editing: nil)
        editor.date = IAFixtures.date("2021-05-05")
        editor.weightText = "20"
        try m.commitVisit(from: editor)
        #expect(visitDates(m) == ["2021-01-10", "2021-05-05", "2021-09-01"])
    }

    // Scenario: Visita confirmada e criança salva
    @Test func committedVisitPersistsOnlyWithChildSave() throws {
        let child = try IAFixtures.insertChild(db, firstName: "Ana")
        let m = model(today: "2021-09-01")
        try m.open(childID: child)
        let editor = m.makeVisitEditor(editing: nil)
        editor.weightText = "21"
        editor.notes = " retorno "
        try m.commitVisit(from: editor)
        #expect(try IAFixtures.count(db, "visits") == 0)
        try m.save()
        #expect(try IAFixtures.count(db, "visits") == 1)
        #expect(try IAFixtures.row(db, "visits", where: "child_id = \(child)")?["notes"] == .text("retorno"))
    }

    // Scenario: Exclusão descartada
    @Test func discardRestoresDeletedVisit() throws {
        let child = try IAFixtures.insertChild(db, firstName: "Ana")
        try IAFixtures.insertVisit(db, childID: child, date: "2021-09-01", weight: "21")
        let m = model()
        try m.open(childID: child)
        m.selectedVisitDates = [IAFixtures.date("2021-09-01")]
        m.deleteSelectedVisits()
        try m.discardChanges()
        #expect(visitDates(m) == ["2021-09-01"])
        #expect(try IAFixtures.count(db, "visits") == 1)
    }

    // Scenario: Excluir duas de três visitas
    @Test func deletingSelectedVisitsPersistsOnSave() throws {
        let child = try IAFixtures.insertChild(db, firstName: "Ana")
        for date in ["2021-01-10", "2021-05-05", "2021-09-01"] {
            try IAFixtures.insertVisit(db, childID: child, date: date, weight: "20")
        }
        let m = model()
        try m.open(childID: child)
        m.selectedVisitDates = [IAFixtures.date("2021-01-10"), IAFixtures.date("2021-09-01")]
        m.deleteSelectedVisits()
        try m.save()
        #expect(try IAFixtures.count(db, "visits", where: "child_id = \(child)") == 1)
    }

    // Scenario: Ações de visita dependem da seleção
    @Test func visitActionsFollowSelection() throws {
        let child = try IAFixtures.insertChild(db, firstName: "Ana")
        try IAFixtures.insertVisit(db, childID: child, date: "2021-01-10", weight: "18")
        try IAFixtures.insertVisit(db, childID: child, date: "2021-09-01", weight: "21")
        let m = model()
        try m.open(childID: child)
        m.selectedVisitDates = []
        #expect(m.canDeleteVisit == false)
        #expect(m.canEditVisit == false)
        #expect(m.canShowVisitGraph == false)
        m.selectedVisitDates = [IAFixtures.date("2021-09-01")]
        #expect(m.canEditVisit == true)
        #expect(m.canDeleteVisit == true)
        #expect(m.canShowVisitGraph == true)
    }

    // Scenario: Linha de visita completa
    @Test func visitRowFormatsColumns() throws {
        let child = try IAFixtures.insertChild(db, firstName: "Ana")
        try IAFixtures.insertVisit(db, childID: child, date: "2021-09-01", weight: "21.6", height: "118.92")
        let m = model()
        try m.open(childID: child)
        let row = try #require(m.visitRows.first)
        #expect([row.date, row.weight, row.oedema, row.recumbent, row.lengthOrHeight]
                == ["01/09/2021", "21,60", "Não", "Não", "118,92"])
    }

    // Scenario: Visita sem peso
    @Test func visitRowLeavesMissingWeightEmpty() throws {
        let child = try IAFixtures.insertChild(db, firstName: "Ana")
        try IAFixtures.insertVisit(db, childID: child, date: "2021-09-01", height: "118.92")
        let m = model()
        try m.open(childID: child)
        #expect(m.visitRows.count == 1)
        #expect(m.visitRows.first?.weight == "")
    }

    // MARK: Resultado e idade

    // Scenario: Menina de 80 meses na mediana
    @Test func selectedVisitResultAtMedianForGirlAt80Months() throws {
        let m = try girlWithVisit(weight: "21.60")
        let result = try #require(m.selectedResult)
        #expect(result.weightForAge.zScore == Decimal(string: "0.00"))
        #expect(result.lengthOrHeightForAge.zScore == Decimal(string: "0.00"))
        #expect(result.bmiForAge.zScore == Decimal(string: "-0.04"))
        #expect(result.weightForAge.percentile == Decimal(string: "50.0"))
        #expect(result.lengthOrHeightForAge.percentile == Decimal(string: "50.0"))
        #expect(result.bmiForAge.percentile == Decimal(string: "48.3"))
        #expect(Indicator.allCases.map { SeverityClassifier.severity(result.score($0).zScore) } == [.normal, .normal, .normal])
    }

    // Scenario: Peso e IMC elevados
    @Test func selectedVisitResultSeverities() throws {
        let m = try girlWithVisit(weight: "30.00")
        let result = try #require(m.selectedResult)
        #expect(result.weightForAge.zScore == Decimal(string: "1.97"))
        #expect(SeverityClassifier.severity(result.weightForAge.zScore) == .moderate)
        #expect(result.bmiForAge.zScore == Decimal(string: "2.54"))
        #expect(SeverityClassifier.severity(result.bmiForAge.zScore) == .high)
    }

    // Scenario: Foco retirado da visita
    @Test func selectedResultFollowsVisitFocus() throws {
        let m = try girlWithVisit(weight: "21.60")
        #expect(m.selectedResult != nil)
        m.focusedVisitDate = nil
        #expect(m.selectedResult == nil)
    }

    // Scenario: Idade de 80 meses
    @Test func ageLabelForEightyMonths() throws {
        let m = try girlWithVisit(weight: "21.60")
        #expect(m.ageLabel == "Idade: 6a 8m (80m)")
    }

    // Scenario: Idade abaixo de um ano
    @Test func ageLabelUnderOneYear() throws {
        let child = try IAFixtures.insertChild(db, firstName: "Bia", dateOfBirth: "2020-01-01")
        try IAFixtures.insertVisit(db, childID: child, date: "2020-11-01", weight: "8")
        let m = model()
        try m.open(childID: child)
        m.focusedVisitDate = IAFixtures.date("2020-11-01")
        #expect(m.ageLabel == "Idade: 10m")
    }

    // MARK: Entrada do gráfico

    // Scenario: Visita existente em foco
    @Test func chartInputForExistingVisit() throws {
        let child = try IAFixtures.insertChild(db, firstName: "Ana")
        for date in ["2021-01-10", "2021-05-05", "2021-09-01"] {
            try IAFixtures.insertVisit(db, childID: child, date: date, weight: "20", height: "115")
        }
        let m = model()
        try m.open(childID: child)
        let focused = VisitRecord(childID: child, date: IAFixtures.date("2021-05-05"), weight: 20, lengthOrHeight: 115)
        let input = m.chartInput(indicator: .weightForAge, focusing: focused)
        #expect(input.results.count == 3)
        #expect(input.currentIndex == 1)
        #expect(input.indicator == .weightForAge)
    }

    // Scenario: Nova visita ainda não confirmada
    @Test func chartInputInsertsUncommittedVisit() throws {
        let child = try IAFixtures.insertChild(db, firstName: "Ana")
        try IAFixtures.insertVisit(db, childID: child, date: "2021-01-10", weight: "19", height: "114")
        try IAFixtures.insertVisit(db, childID: child, date: "2021-09-01", weight: "21", height: "118")
        let m = model()
        try m.open(childID: child)
        let uncommitted = VisitRecord(date: IAFixtures.date("2021-05-05"), weight: 20, lengthOrHeight: 116)
        let input = m.chartInput(indicator: .bmiForAge, focusing: uncommitted)
        #expect(input.results.count == 3)
        #expect(input.currentIndex == 1)
        #expect(m.visits.count == 2)
    }
}
