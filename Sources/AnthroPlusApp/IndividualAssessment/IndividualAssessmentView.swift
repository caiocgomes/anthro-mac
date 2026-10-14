import AnthroFeatures
import SwiftUI

/// Módulo Avaliação individual: lista de crianças à esquerda e ficha à direita, como `IAMain`.
struct IndividualAssessmentHostView: View {
    let model: AppModel

    var body: some View {
        if let database = model.store.database, let tables = try? GrowthReferenceTables.bundled() {
            IndividualAssessmentView(app: model, database: database, tables: tables)
        } else {
            ContentUnavailableView(L10n.Calculator.tablesUnavailable, systemImage: "exclamationmark.triangle")
        }
    }
}

/// Pedido que espera a decisão sobre alterações não salvas.
enum PendingNavigation: Equatable {
    case open(Int64)
    case new
}

struct IndividualAssessmentView: View {
    let app: AppModel
    let database: AnthroDatabase
    let tables: GrowthReferenceTables

    @State private var list: ChildListModel
    @State private var detail: ChildDetailModel
    @State private var selectedChildID: Int64?
    @State private var pending: PendingNavigation?
    @State private var errorMessage: String?

    init(app: AppModel, database: AnthroDatabase, tables: GrowthReferenceTables) {
        self.app = app
        self.database = database
        self.tables = tables
        _list = State(initialValue: ChildListModel(database: database, settings: app.settings))
        _detail = State(initialValue: ChildDetailModel(database: database, settings: app.settings,
                                                       engine: AnthroEngine(tables: tables)))
    }

    var body: some View {
        HSplitView {
            ChildListPane(list: list, selectedChildID: selectedChildID, onSelect: { request(.open($0)) },
                          onNew: { request(.new) }, onError: show)
                .frame(minWidth: 220, idealWidth: 270, maxWidth: 360, maxHeight: .infinity)
            ChildDetailPane(detail: detail, database: database, tables: tables, onSaved: childSaved, onError: show)
                .frame(minWidth: 440, maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .environment(\.locale, Locale(identifier: "pt_BR"))
        .task {
            app.unsavedChangesGuard = detail
            perform { try list.load() }
        }
        .onDisappear {
            if app.unsavedChangesGuard === detail { app.unsavedChangesGuard = nil }
        }
        .unsavedChangesDialog(isPresented: Binding(get: { pending != nil }, set: { if !$0 { pending = nil } })) { decision in
            guard let target = pending else { return }
            pending = nil
            perform {
                if try detail.proceedAfterUnsavedChanges(decision) { try navigate(target) }
            }
        }
        .alert(L10n.IndividualAssessment.saveFailed,
               isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "")
        }
    }

    /// `IAMain.AskForSave` antes de trocar de criança ou criar outra.
    private func request(_ target: PendingNavigation) {
        if detail.hasUnsavedChanges {
            pending = target
        } else {
            perform { try navigate(target) }
        }
    }

    private func navigate(_ target: PendingNavigation) throws {
        switch target {
        case .open(let id):
            try detail.open(childID: id)
            selectedChildID = id
        case .new:
            detail.startNew()
            selectedChildID = nil
        }
    }

    private func childSaved(_ id: Int64) {
        perform {
            try list.showActive()
            selectedChildID = id
        }
    }

    private func perform(_ action: () throws -> Void) {
        do {
            try action()
        } catch {
            show(error)
        }
    }

    private func show(_ error: Error) {
        errorMessage = IAErrorText.message(for: error)
    }
}

/// Mensagem em pt-BR para os erros de validação; os demais mostram a descrição técnica.
enum IAErrorText {
    static func message(for error: Error) -> String {
        switch error {
        case ChildValidationError.sexRequired: L10n.IndividualAssessment.sexRequired
        case VisitValidationError.duplicateDate: L10n.IndividualAssessment.duplicateDate
        case VisitValidationError.invalidMeasurement, ParentValidationError.invalidMeasurement:
            L10n.IndividualAssessment.invalidMeasurement
        default: String(describing: error)
        }
    }
}

extension View {
    /// Diálogo Salvar, Descartar ou Cancelar de `IAMain.AskForSave`.
    func unsavedChangesDialog(isPresented: Binding<Bool>, onDecision: @escaping (UnsavedChangesDecision) -> Void) -> some View {
        alert(L10n.IndividualAssessment.unsavedTitle, isPresented: isPresented) {
            Button(L10n.IndividualAssessment.save) { onDecision(.save) }
                .keyboardShortcut(.defaultAction)
            Button(L10n.IndividualAssessment.discard, role: .destructive) { onDecision(.discard) }
            Button(L10n.IndividualAssessment.cancel, role: .cancel) { onDecision(.cancel) }
        } message: {
            Text(L10n.IndividualAssessment.unsavedMessage)
        }
    }
}
