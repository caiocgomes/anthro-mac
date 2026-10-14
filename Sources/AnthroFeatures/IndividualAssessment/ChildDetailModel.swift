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

/// Ficha da criança em edição com as suas visitas (`IAMain`, design D3).
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

    public init(database: AnthroDatabase, settings: AppSettings, engine: AnthroEngine, today: @escaping () -> Date = { Date() },
                randomDay: @escaping (Range<Int>) -> Int = { Int.random(in: $0) }) {
        self.database = database
        self.settings = settings
        self.engine = engine
        self.today = today
        self.randomDay = randomDay
    }

    public var isDisplayIDEditable: Bool { false }
    public var canDeleteVisit: Bool { false }
    public var canEditVisit: Bool { false }
    public var canShowVisitGraph: Bool { false }

    public func startNew() {}
    public func open(childID: Int64) throws {}
    public func update(_ edit: (inout ChildDraft) -> Void) {}
    public func setDateOfBirth(_ date: Date) {}
    public func setDateOfBirthIsApprox(_ isApprox: Bool) {}
    @discardableResult public func save() throws -> Int64 { 0 }
    public func discardChanges() throws {}
    public func proceedAfterUnsavedChanges(_ decision: UnsavedChangesDecision) throws -> Bool { false }

    public func makeVisitEditor(editing date: Date?) -> VisitEditorModel {
        VisitEditorModel(dateOfBirth: Date(timeIntervalSince1970: 0), sex: nil, existingDates: [], editing: nil,
                         engine: engine, today: Date(timeIntervalSince1970: 0))
    }

    public func commitVisit(from editor: VisitEditorModel) throws {}
    public func deleteSelectedVisits() {}

    public var visitRows: [VisitRow] { [] }
    public var selectedResult: AnthropometricResult? { nil }
    public var ageLabel: String { "" }

    public func chartInput(indicator: Indicator, focusing visit: VisitRecord) -> GrowthChartInput {
        GrowthChartInput(results: [], currentIndex: 0, indicator: indicator)
    }

    public func searchParents(kind: ParentKind, text: String) throws -> LookupSearchOutcome<ParentRecord> { .results([]) }
    public func searchAddresses(text: String) throws -> LookupSearchOutcome<AddressRecord> { .results([]) }
}
