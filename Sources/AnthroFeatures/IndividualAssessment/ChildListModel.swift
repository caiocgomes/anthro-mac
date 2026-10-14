import AnthroStore
import Foundation
import Observation

public enum ChildListMode: Sendable, Equatable {
    case active
    case archive
    case searchResults
}

public struct ChildListRow: Identifiable, Sendable, Equatable {
    public let id: Int64
    public let title: String
}

/// Lista de crianças de `IAMain` (ativas, arquivo e resultados de busca).
@MainActor
@Observable
public final class ChildListModel {
    public private(set) var mode: ChildListMode = .active
    public private(set) var rows: [ChildListRow] = []
    public var checkedIDs: Set<Int64> = []

    @ObservationIgnored private let database: AnthroDatabase
    @ObservationIgnored private let settings: AppSettings

    public init(database: AnthroDatabase, settings: AppSettings) {
        self.database = database
        self.settings = settings
    }

    public var canCreate: Bool { false }
    public var canDelete: Bool { false }
    public var canArchive: Bool { false }
    public var canRestore: Bool { false }
    public var canSearch: Bool { false }

    public func load() throws {}
    public func showActive() throws {}
    public func showArchive() throws {}
    public func search(_ criteria: ChildSearchCriteria) throws {}
    public func archiveChecked() throws {}
    public func restoreChecked() throws {}
    public func deleteChecked() throws {}
}
