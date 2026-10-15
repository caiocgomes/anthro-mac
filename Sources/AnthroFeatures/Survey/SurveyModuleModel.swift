import AnthroCore
import AnthroIO
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
    case openDraft(ExchangeSurvey)
}

/// Módulo Inquérito nutricional: lista, inquérito aberto e pergunta de alterações pendentes antes de abrir outro,
/// criar, fechar ou arquivar (`NSMain.AskForSave`).
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

    /// `tsbSurveyNew_Click`: inquérito vazio com as opções padrão.
    public func createSurvey() -> SurveyOpenOutcome {
        guard !needsDecision(.create) else { return .needsDecision }
        openNew()
        return .done
    }

    /// `tsbSurveyOpen_Click`.
    public func open(id: Int64) throws -> SurveyOpenOutcome {
        guard !needsDecision(.open(id)) else { return .needsDecision }
        try load(id)
        return .done
    }

    /// Rascunho da importação externa (design D12 e D18): abre como inquérito novo com alterações não salvas, depois da
    /// pergunta de salvar se o aberto tiver pendências.
    public func openDraft(_ draft: ExchangeSurvey) -> SurveyOpenOutcome {
        guard !needsDecision(.openDraft(draft)) else { return .needsDecision }
        openImported(draft)
        return .done
    }

    public func requestClose() -> SurveyOpenOutcome {
        guard !needsDecision(.close) else { return .needsDecision }
        openSurvey = nil
        return .done
    }

    /// Salvar grava e segue; descartar abandona as edições e segue; cancelar só esquece o pedido. Falha ao salvar
    /// interrompe a ação, como `AskForSave` devolvendo Cancelar.
    public func resolvePending(_ decision: UnsavedChangesDecision) throws {
        guard let action = pendingAction else { return }
        pendingAction = nil
        guard try settle(decision) else { return }
        switch action {
        case .open(let id): try load(id)
        case .create: openNew()
        case .close: openSurvey = nil
        case .archive: try archive()
        case .openDraft(let draft): openImported(draft)
        }
    }

    /// `tsbSurveyArchive_Click`: pergunta antes se o inquérito aberto tem pendências (D13); o aberto, se arquivado, fecha.
    @discardableResult public func archiveChecked() throws -> SurveyOpenOutcome {
        guard list.canArchive else { return .done }
        guard !needsDecision(.archive) else { return .needsDecision }
        try archive()
        return .done
    }

    /// `tsbSurveyDelete_Click`: exclui os marcados com os seus registros; o aberto, se excluído, fecha.
    public func deleteChecked() throws {
        guard list.canDelete else { return }
        let ids = list.checkedIDs
        try repository.delete(Array(ids))
        if let id = openSurvey?.survey.id, ids.contains(id) { openSurvey = nil }
        list.checkedIDs = []
        try list.reload()
    }

    // MARK: Privado

    private func needsDecision(_ action: PendingSurveyAction) -> Bool {
        guard openSurvey?.hasUnsavedChanges == true else { return false }
        pendingAction = action
        return true
    }

    /// Aplica a decisão ao inquérito aberto; `false` para cancelar.
    private func settle(_ decision: UnsavedChangesDecision) throws -> Bool {
        switch decision {
        case .cancel:
            return false
        case .save:
            try openSurvey?.save()
            try list.reload()
        case .discard:
            if openSurvey?.survey.id == nil {
                openSurvey = nil
            } else {
                try openSurvey?.discardChanges()
            }
        }
        return true
    }

    private func openNew() {
        openSurvey = SurveyDetailModel(survey: Survey(options: .default), records: [], repository: repository,
                                       engine: engine, today: today)
    }

    private func openImported(_ draft: ExchangeSurvey) {
        var survey = draft.survey
        survey.id = nil
        let detail = SurveyDetailModel(survey: survey, records: draft.records.map { record -> SurveyRecord in
            var copy = record
            copy.id = nil
            return copy
        }, repository: repository, engine: engine, today: today)
        detail.markUnsaved()
        openSurvey = detail
    }

    private func load(_ id: Int64) throws {
        openSurvey = SurveyDetailModel(survey: try repository.survey(id: id), records: try repository.records(surveyID: id),
                                       repository: repository, engine: engine, today: today)
    }

    private func archive() throws {
        let ids = list.checkedIDs
        try repository.setArchived(Array(ids), archived: true)
        if let id = openSurvey?.survey.id, ids.contains(id) { openSurvey = nil }
        list.checkedIDs = []
        try list.reload()
    }
}

extension SurveyModuleModel: UnsavedChangesGuard {
    public var hasUnsavedChanges: Bool {
        openSurvey?.hasUnsavedChanges ?? false
    }

    /// Troca de módulo ou encerramento do app com pendências (`NSMain_FormClosing`).
    public func proceedAfterUnsavedChanges(_ decision: UnsavedChangesDecision) throws -> Bool {
        guard hasUnsavedChanges else { return true }
        return try settle(decision)
    }
}

/// O editor da change 5 recebe o rascunho da importação externa (design D12 e D18); com pendências, a pergunta de
/// salvar fica em `pendingAction`.
extension SurveyModuleModel: SurveyDraftPresenter {
    public func presentDraft(_ draft: ExchangeSurvey) {
        _ = openDraft(draft)
    }
}
