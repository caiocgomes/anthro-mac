import AnthroCore
import AnthroStore
import Foundation
import Observation

/// Decisão do diálogo de alterações não salvas (`IAMain.AskForSave`); consumida pela change add-nutritional-survey.
public enum UnsavedChangesDecision: Sendable {
    case save
    case discard
    case cancel
}

/// Ficha da criança em edição com as suas visitas (`IAMain`, design D3): nada vai ao banco até salvar a criança;
/// mãe, pai e endereço são gravados na hora pelos seus editores.
@MainActor
@Observable
public final class ChildDetailModel {
    public private(set) var draft: ChildDraft? = nil
    public private(set) var visits: [VisitRecord] = []
    public private(set) var hasUnsavedChanges: Bool = false
    public var selectedVisitDates: Set<Date> = []
    public var focusedVisitDate: Date? = nil

    @ObservationIgnored private let database: AnthroDatabase
    @ObservationIgnored private let settings: AppSettings
    @ObservationIgnored private let engine: AnthroEngine
    @ObservationIgnored private let today: () -> Date
    @ObservationIgnored private let randomDay: (Range<Int>) -> Int
    @ObservationIgnored private let children: ChildRepository
    @ObservationIgnored private var savedDraft: ChildDraft? = nil
    @ObservationIgnored private var savedVisits: [VisitRecord] = []

    public init(database: AnthroDatabase, settings: AppSettings, engine: AnthroEngine, today: @escaping () -> Date = { Date() },
                randomDay: @escaping (Range<Int>) -> Int = { Int.random(in: $0) }) {
        self.database = database
        self.settings = settings
        self.engine = engine
        self.today = today
        self.randomDay = randomDay
        children = ChildRepository(database: database)
    }

    /// Com o ID automático ligado, o ID não é editado à mão.
    public var isDisplayIDEditable: Bool { !settings.autoAssignChildID }

    /// `IAMain.RefreshUI`: excluir, editar e gráfico dependem de visita selecionada.
    public var canDeleteVisit: Bool { !selectedVisits.isEmpty }
    public var canEditVisit: Bool { !selectedVisits.isEmpty }
    public var canShowVisitGraph: Bool { !selectedVisits.isEmpty }

    // MARK: Criança

    /// `Child()`: nascimento um ano antes de hoje, sexo indefinido, sem visitas.
    public func startNew() {
        let birth = Calendar.current.date(byAdding: .year, value: -1, to: today()) ?? today()
        let new = ChildDraft(id: nil, displayID: nil, firstName: "", lastName: "", sex: nil,
                             dateOfBirth: IndividualAssessment.normalized(birth), dateOfBirthIsApprox: false, notes: "",
                             followUpDate: nil, followUpInterval: nil, followUpRefTo: "", motherID: nil, fatherID: nil,
                             addressID: nil)
        load(new, visits: [])
    }

    public func open(childID: Int64) throws {
        guard let child = try children.child(id: childID) else { return }
        load(Self.draft(from: child), visits: try VisitRepository(database: database).visits(childID: childID))
    }

    public func update(_ edit: (inout ChildDraft) -> Void) {
        guard var current = draft else { return }
        edit(&current)
        draft = current
        refreshUnsavedChanges()
    }

    /// `dtpDateOfBirth_ValueChanged`: com data aproximada, desfaz troca de dia e sorteia na troca de mês; limite na
    /// primeira visita, se houver, senão em hoje (D9, D10).
    public func setDateOfBirth(_ date: Date) {
        guard let current = draft else { return }
        let adjusted = ApproximateBirthDate.adjusted(previous: current.dateOfBirth, proposed: IndividualAssessment.normalized(date),
                                                     isApprox: current.dateOfBirthIsApprox, upperBound: birthUpperBound,
                                                     randomDay: randomDay)
        update { $0.dateOfBirth = IndividualAssessment.normalized(adjusted) }
    }

    /// `cbDateIsApprox_CheckedChanged`: marcar sorteia o dia do mês e aplica o limite.
    public func setDateOfBirthIsApprox(_ isApprox: Bool) {
        guard let current = draft else { return }
        let birth = isApprox
            ? IndividualAssessment.approximated(current.dateOfBirth, upperBound: birthUpperBound, randomDay: randomDay)
            : current.dateOfBirth
        update {
            $0.dateOfBirthIsApprox = isApprox
            $0.dateOfBirth = birth
        }
    }

    /// `IAMain.SaveCurrentChild`: sexo obrigatório, textos sem espaços nas pontas, ID automático sobre o banco
    /// inteiro (D4); grava a criança e o conjunto de visitas numa transação (D3).
    @discardableResult public func save() throws -> Int64 {
        guard var current = draft else { return 0 }
        guard let sex = current.sex else { throw ChildValidationError.sexRequired }
        if current.displayID == nil, settings.autoAssignChildID {
            current.displayID = (try children.maxDisplayID() ?? 0) + 1
        }
        let record = ChildRecord(
            id: current.id, displayID: current.displayID, firstName: IndividualAssessment.nullable(current.firstName),
            lastName: IndividualAssessment.nullable(current.lastName), dateOfBirth: current.dateOfBirth,
            dateOfBirthIsApprox: current.dateOfBirthIsApprox, sex: sex, motherID: current.motherID,
            fatherID: current.fatherID, addressID: current.addressID, notes: IndividualAssessment.nullable(current.notes),
            followUpDate: current.followUpDate, followUpInterval: current.followUpInterval,
            followUpRefTo: IndividualAssessment.nullable(current.followUpRefTo))
        let saved = try children.save(record, visits: visits)
        let id = saved.id ?? 0
        load(Self.draft(from: saved), visits: try VisitRepository(database: database).visits(childID: id),
             keepSelection: true)
        return id
    }

    /// `Child.DiscardDataChanges`: volta ao que está no banco, ou à criança nova sem edições.
    public func discardChanges() throws {
        if let id = savedDraft?.id {
            try open(childID: id)
        } else if let initial = savedDraft {
            load(initial, visits: [])
        }
    }

    /// `IAMain.AskForSave`: sem alterações segue; salvar segue se gravar (o erro chega ao chamador); descartar
    /// segue; cancelar fica.
    public func proceedAfterUnsavedChanges(_ decision: UnsavedChangesDecision) throws -> Bool {
        guard hasUnsavedChanges else { return true }
        switch decision {
        case .save:
            try save()
            return true
        case .discard:
            try discardChanges()
            return true
        case .cancel:
            return false
        }
    }

    // MARK: Visitas

    public func makeVisitEditor(editing date: Date?) -> VisitEditorModel {
        let existing = date.flatMap { day in visits.first { IndividualAssessment.sameDay($0.date, day) } }
        return VisitEditorModel(dateOfBirth: draft?.dateOfBirth ?? today(), sex: draft?.sex,
                                existingDates: Set(visits.map(\.date)), editing: existing, engine: engine, today: today())
    }

    /// `tsbVisitNew_Click` e `tsbVisitOpen_Click`: a visita entra na ficha na posição da sua data, sem ir ao banco.
    public func commitVisit(from editor: VisitEditorModel) throws {
        var visit = try editor.makeVisit()
        visit.childID = draft?.id
        visits.removeAll { IndividualAssessment.sameDay($0.date, visit.date) }
        let index = visits.firstIndex { $0.date > visit.date } ?? visits.endIndex
        visits.insert(visit, at: index)
        refreshUnsavedChanges()
    }

    /// `tsbVisitDelete_Click`: remove da ficha as visitas selecionadas; o banco muda ao salvar a criança.
    public func deleteSelectedVisits() {
        let doomed = selectedVisits
        visits.removeAll { visit in doomed.contains { IndividualAssessment.sameDay($0.date, visit.date) } }
        selectedVisitDates = []
        if let focused = focusedVisitDate, !visits.contains(where: { IndividualAssessment.sameDay($0.date, focused) }) {
            focusedVisitDate = nil
        }
        refreshUnsavedChanges()
    }

    /// `IAMain.dgvVisits_CellValueNeeded`: data, peso, edema, deitado e medida.
    public var visitRows: [VisitRow] {
        let yes = L10n.IndividualAssessment.yes, no = L10n.IndividualAssessment.no
        return visits.map { visit in
            VisitRow(date: Self.shortDate(visit.date),
                     weight: visit.weight.map { ClinicalFormat.string($0, places: 2) } ?? "",
                     oedema: visit.hasOedema ? yes : no,
                     recumbent: visit.measuredRecumbent ? yes : no,
                     lengthOrHeight: visit.lengthOrHeight.map { ClinicalFormat.string($0, places: 2) } ?? "")
        }
    }

    /// Resultado da visita em foco com nascimento e sexo do rascunho (`Visit.AnthroResult`, D14).
    public var selectedResult: AnthropometricResult? {
        guard let focused = focusedVisit else { return nil }
        return result(for: focused)
    }

    /// `IAMain.RefreshAge`: meses inteiros na data da visita em foco, ou de hoje; "Idade: N/D" se o nascimento for
    /// posterior (D14).
    public var ageLabel: String {
        guard let birth = draft?.dateOfBirth else { return "" }
        let reference = focusedVisit?.date ?? today()
        guard let days = try? AgeMath.ageInDays(birth: birth, visit: reference) else {
            return "\(L10n.Age.label): \(L10n.notAvailable)"
        }
        return AgeText.localized(months: AgeText.wholeMonths(AgeMath.daysToMonths(days)))
    }

    /// `GraphDialog(Child, Visit, Indicator)`: resultados em ordem de data com a visita em foco na posição da sua data,
    /// mesmo se ainda não confirmada (D15).
    public func chartInput(indicator: Indicator, focusing visit: VisitRecord) -> GrowthChartInput {
        var series = visits.filter { !IndividualAssessment.sameDay($0.date, visit.date) }
        let index = series.firstIndex { $0.date > visit.date } ?? series.endIndex
        series.insert(visit, at: index)
        let results = series.map { result(for: $0) ?? emptyResult }
        return GrowthChartInput(results: results, currentIndex: index, indicator: indicator)
    }

    public func searchParents(kind: ParentKind, text: String) throws -> LookupSearchOutcome<ParentRecord> {
        try ParentRepository(database: database).search(kind: kind, text: text)
    }

    public func searchAddresses(text: String) throws -> LookupSearchOutcome<AddressRecord> {
        try AddressRepository(database: database).search(text: text)
    }

    // MARK: Apoio

    private var selectedVisits: [VisitRecord] {
        visits.filter { visit in selectedVisitDates.contains { IndividualAssessment.sameDay($0, visit.date) } }
    }

    private var focusedVisit: VisitRecord? {
        guard let focused = focusedVisitDate else { return nil }
        return visits.first { IndividualAssessment.sameDay($0.date, focused) }
    }

    private var birthUpperBound: Date {
        visits.first?.date ?? IndividualAssessment.normalized(today())
    }

    private var emptyResult: AnthropometricResult {
        engine.result(ageInDays: nil, ageInMonths: nil, sex: nil, weight: nil, lengthOrHeight: nil,
                      measuredRecumbent: false, hasOedema: false)
    }

    private func result(for visit: VisitRecord) -> AnthropometricResult? {
        guard let draft else { return nil }
        return try? engine.result(dateOfBirth: draft.dateOfBirth, dateOfVisit: visit.date, sex: draft.sex,
                                  weight: visit.weight, lengthOrHeight: visit.lengthOrHeight,
                                  measuredRecumbent: visit.measuredRecumbent, hasOedema: visit.hasOedema)
    }

    private func load(_ draft: ChildDraft, visits: [VisitRecord], keepSelection: Bool = false) {
        self.draft = draft
        self.visits = visits
        savedDraft = draft
        savedVisits = visits
        if !keepSelection {
            selectedVisitDates = []
            focusedVisitDate = nil
        }
        hasUnsavedChanges = false
    }

    private func refreshUnsavedChanges() {
        hasUnsavedChanges = draft != savedDraft || visits != savedVisits
    }

    private static func draft(from child: ChildRecord) -> ChildDraft {
        ChildDraft(id: child.id, displayID: child.displayID, firstName: child.firstName ?? "",
                   lastName: child.lastName ?? "", sex: child.sex, dateOfBirth: child.dateOfBirth,
                   dateOfBirthIsApprox: child.dateOfBirthIsApprox, notes: child.notes ?? "",
                   followUpDate: child.followUpDate, followUpInterval: child.followUpInterval,
                   followUpRefTo: child.followUpRefTo ?? "", motherID: child.motherID, fatherID: child.fatherID,
                   addressID: child.addressID)
    }

    /// `DateTime.ToShortDateString()` em pt-BR: dd/MM/aaaa.
    private static func shortDate(_ date: Date) -> String {
        let parts = Calendar.current.dateComponents([.year, .month, .day], from: date)
        return String(format: "%02d/%02d/%04d", parts.day!, parts.month!, parts.year!)
    }
}
