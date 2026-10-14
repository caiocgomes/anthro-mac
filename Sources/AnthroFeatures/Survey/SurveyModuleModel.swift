import AnthroCore
import AnthroStore
import Foundation
import Observation

public enum SurveyOpenOutcome: Equatable, Sendable {
    case done
    case needsDecision
}

/// Ação que espera a decisão de `NSMain.AskForSave` (design D2 e D13).
public enum PendingSurveyAction: Equatable, Sendable {
    case open(Int64)
    case create
    case close
    case archive
}

/// Módulo Inquérito nutricional: lista, inquérito aberto e pergunta de alterações pendentes.
@MainActor
@Observable
public final class SurveyModuleModel {
    public let list: SurveyListModel
    public private(set) var openSurvey: SurveyDetailModel?
    public private(set) var pendingAction: PendingSurveyAction?

    @ObservationIgnored private let repository: SurveyRepository
    @ObservationIgnored private let engine: AnthroEngine
    @ObservationIgnored private let today: () -> Date

    public init(repository: SurveyRepository, engine: AnthroEngine, today: @escaping () -> Date = Date.init) {
        self.repository = repository
        self.engine = engine
        self.today = today
        list = SurveyListModel(repository: repository)
    }

    public func createSurvey() -> SurveyOpenOutcome { .done }

    public func open(id: Int64) throws -> SurveyOpenOutcome { .done }

    public func requestClose() -> SurveyOpenOutcome { .done }

    public func resolvePending(_ decision: UnsavedChangesDecision) throws {}

    @discardableResult public func archiveChecked() throws -> SurveyOpenOutcome { .done }

    public func deleteChecked() throws {}
}

extension SurveyModuleModel: UnsavedChangesGuard {
    public var hasUnsavedChanges: Bool { false }

    public func proceedAfterUnsavedChanges(_ decision: UnsavedChangesDecision) throws -> Bool { true }
}
