import AnthroFeatures
import SwiftUI

/// Estado do módulo guardado no `AppModel`: sobrevive ao fechamento da janela, então o inquérito em edição não se perde.
@MainActor
final class SurveySession {
    let module: SurveyModuleModel
    var isLoaded = false

    init(database: AnthroDatabase, tables: GrowthReferenceTables) {
        module = SurveyModuleModel(repository: SurveyRepository(database: database), engine: AnthroEngine(tables: tables))
    }
}

/// Módulo Inquérito nutricional: lista de inquéritos à esquerda e inquérito aberto à direita, como `NSMain`.
struct SurveyModuleHostView: View {
    let model: AppModel

    var body: some View {
        if let database = model.store.database, let tables = try? GrowthReferenceTables.bundled() {
            SurveyModuleView(session: session(database: database, tables: tables))
        } else {
            ContentUnavailableView(L10n.Calculator.tablesUnavailable, systemImage: "exclamationmark.triangle")
        }
    }

    private func session(database: AnthroDatabase, tables: GrowthReferenceTables) -> SurveySession {
        let session = model.moduleSessions[.nutritionalSurvey] as? SurveySession ?? SurveySession(database: database, tables: tables)
        model.moduleSessions[.nutritionalSurvey] = session
        model.unsavedChangesGuard = session.module
        return session
    }
}

struct SurveyModuleView: View {
    let session: SurveySession

    @State private var errorMessage: String?

    private var module: SurveyModuleModel { session.module }

    var body: some View {
        HSplitView {
            SurveyListView(module: module, onError: show)
                .frame(minWidth: 220, idealWidth: 260, maxWidth: 340, maxHeight: .infinity)
            Group {
                if let detail = module.openSurvey {
                    SurveyDetailPane(module: module, detail: detail, onError: show)
                        .id(ObjectIdentifier(detail))
                } else {
                    ContentUnavailableView(L10n.Survey.noSurveyOpen, systemImage: "chart.bar.doc.horizontal",
                                           description: Text(L10n.Survey.noSurveyOpenHint))
                }
            }
            .frame(minWidth: 560, maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .environment(\.locale, Locale(identifier: "pt_BR"))
        .task {
            guard !session.isLoaded else { return }
            session.isLoaded = true
            perform { try module.list.reload() }
        }
        .unsavedChangesDialog(pending: Binding(get: { module.pendingAction }, set: { _ in }),
                              title: L10n.Survey.unsavedTitle, message: L10n.Survey.unsavedMessage) { decision, _ in
            perform { try module.resolvePending(decision) }
        }
        .alert(L10n.IndividualAssessment.saveFailed,
               isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "")
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
        errorMessage = SurveyErrorText.message(for: error)
    }
}

/// Mensagem em pt-BR para os erros do módulo.
enum SurveyErrorText {
    static func message(for error: Error) -> String {
        switch error {
        case SurveyStoreError.nameRequired: L10n.Survey.nameRequired
        case is RecordValidationError: L10n.Survey.invalidFields
        case SurveyOptionsEditorError.tooFewAgeGroups: L10n.Survey.tooFewAgeGroups
        case SurveyOptionsEditorError.inconsistentAgeGroups: L10n.Survey.inconsistentAgeGroups
        case SurveyOptionsEditorError.invalidZBounds: L10n.Survey.invalidZBounds
        default: IAErrorText.message(for: error)
        }
    }
}

/// Título e mensagem do diálogo de pendências conforme o módulo que tem alterações.
@MainActor
enum UnsavedChangesText {
    static func title(for unsaved: UnsavedChangesGuard?) -> String {
        unsaved is SurveyModuleModel ? L10n.Survey.unsavedTitle : L10n.IndividualAssessment.unsavedTitle
    }

    static func message(for unsaved: UnsavedChangesGuard?) -> String {
        unsaved is SurveyModuleModel ? L10n.Survey.unsavedMessage : L10n.IndividualAssessment.unsavedMessage
    }
}
