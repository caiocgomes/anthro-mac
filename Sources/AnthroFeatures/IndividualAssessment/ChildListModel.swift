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

/// Lista de crianças de `IAMain` (ativas, arquivo e resultados de busca) com as regras de `RefreshUI`.
@MainActor
@Observable
public final class ChildListModel {
    public private(set) var mode: ChildListMode = .active
    public private(set) var rows: [ChildListRow] = []
    public var checkedIDs: Set<Int64> = []

    @ObservationIgnored private let database: AnthroDatabase
    @ObservationIgnored private let settings: AppSettings
    @ObservationIgnored private let repository: ChildRepository
    @ObservationIgnored private var lastCriteria = ChildSearchCriteria()

    public init(database: AnthroDatabase, settings: AppSettings) {
        self.database = database
        self.settings = settings
        repository = ChildRepository(database: database)
    }

    /// No arquivo só há restaurar e voltar.
    public var canCreate: Bool { mode != .archive }
    public var canSearch: Bool { mode != .archive }
    public var canDelete: Bool { mode != .archive && !checkedIDs.isEmpty }
    public var canArchive: Bool { mode != .archive && !checkedIDs.isEmpty }
    public var canRestore: Bool { mode == .archive && !checkedIDs.isEmpty }

    /// Abertura do módulo: limpeza de órfãos (`Global.Init` chama `CleanupOrphans`, design D6) e lista ativa.
    public func load() throws {
        try OrphanCleanup.run(in: database)
        try showActive()
    }

    public func showActive() throws {
        show(.active, try repository.list(archived: false))
    }

    public func showArchive() throws {
        show(.archive, try repository.list(archived: true))
    }

    /// Critérios todos vazios encerram a busca e voltam à lista ativa (`OnSearchCleared`).
    public func search(_ criteria: ChildSearchCriteria) throws {
        guard !criteria.isEmpty else {
            try showActive()
            return
        }
        lastCriteria = criteria
        show(.searchResults, try repository.search(criteria))
    }

    public func archiveChecked() throws {
        try repository.setArchived(Array(checkedIDs), archived: true)
        try reload()
    }

    public func restoreChecked() throws {
        try repository.setArchived(Array(checkedIDs), archived: false)
        try reload()
    }

    public func deleteChecked() throws {
        try repository.delete(Array(checkedIDs))
        try reload()
    }

    private func reload() throws {
        switch mode {
        case .active: try showActive()
        case .archive: try showArchive()
        case .searchResults: show(.searchResults, try repository.search(lastCriteria))
        }
    }

    private func show(_ mode: ChildListMode, _ children: [ChildRecord]) {
        self.mode = mode
        rows = children.compactMap { child in child.id.map { ChildListRow(id: $0, title: child.listTitle) } }
        checkedIDs = []
    }
}
