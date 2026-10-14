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

    /// Arquivar e excluir só na lista ativa e com algum inquérito marcado; restaurar só no arquivo.
    public var canArchive: Bool { !showsArchive && !checkedIDs.isEmpty }
    public var canDelete: Bool { !showsArchive && !checkedIDs.isEmpty }
    public var canRestore: Bool { showsArchive && !checkedIDs.isEmpty }

    /// Relê a lista corrente; marcações de inquéritos que saíram da lista são descartadas.
    public func reload() throws {
        surveys = try repository.list(archived: showsArchive)
        checkedIDs.formIntersection(surveys.compactMap(\.id))
    }

    /// Alterna entre a lista ativa e o arquivo, sem marcações.
    public func showArchive(_ archived: Bool) throws {
        showsArchive = archived
        checkedIDs = []
        try reload()
    }

    /// `tsbSurveyRestore_Click`: os marcados voltam à lista ativa.
    public func restoreChecked() throws {
        guard canRestore else { return }
        try repository.setArchived(Array(checkedIDs), archived: false)
        checkedIDs = []
        try reload()
    }
}
