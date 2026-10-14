import AnthroCore
import AnthroStore
import Observation

/// Lista de inquéritos ativos ou arquivados com marcação (`NSMain.LoadSurveyList` e `RefreshUI`).
@MainActor
@Observable
public final class SurveyListModel {
    public private(set) var surveys: [Survey] = []
    public private(set) var showsArchive: Bool = false
    public var checkedIDs: Set<Int64> = []

    @ObservationIgnored private let repository: SurveyRepository

    public init(repository: SurveyRepository) {
        self.repository = repository
    }

    public var canArchive: Bool { false }
    public var canDelete: Bool { false }
    public var canRestore: Bool { false }

    public func reload() throws {}

    public func showArchive(_ archived: Bool) throws {}

    public func restoreChecked() throws {}
}
