import AnthroFeatures
import AppKit
import SwiftUI
import UniformTypeIdentifiers

/// Estado do módulo guardado no `AppModel`: sobrevive ao fechamento da janela, então o inquérito em edição não se perde.
@MainActor
final class SurveySession {
    let module: SurveyModuleModel
    /// Importação e exportação (`importFromFileToolStripMenuItem_Click`, `tsbSurveyExport_Click`); o rascunho da
    /// importação externa vai para o módulo, que pergunta antes se o inquérito aberto tem alterações.
    let exchange: SurveyExchangeModel
    var isLoaded = false

    init(database: AnthroDatabase, tables: GrowthReferenceTables) {
        let repository = SurveyRepository(database: database)
        let engine = AnthroEngine(tables: tables)
        module = SurveyModuleModel(repository: repository, engine: engine)
        let adapter = RepositorySurveyExchange(database: database, surveys: repository)
        exchange = SurveyExchangeModel(source: adapter, sink: adapter, presenter: module, engine: engine)
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
    @State private var showingMapping = false
    @State private var mappingConfirmed = false
    /// Resultado da exportação, avisado depois que a folha fecha.
    @State private var exportResult: Result<SurveyExportWarning?, Error>?
    @State private var showingExport = false
    @State private var exchangeAlert: ExchangeAlert?
    /// Aviso da importação externa, mostrado depois da pergunta sobre o inquérito aberto, se houver.
    @State private var importWarning: String?

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
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button(L10n.SurveyExchange.importSurvey) { importSurveys() }
                    Button(L10n.SurveyExchange.exportSurveys) { startExport() }
                        .disabled(module.list.checkedIDs.isEmpty)
                } label: {
                    Label(L10n.Exchange.menu, systemImage: "square.and.arrow.up.on.square")
                }
                .help(L10n.Exchange.menu)
            }
        }
        .sheet(isPresented: $showingMapping, onDismiss: mappingClosed) {
            SurveyImportMappingSheet(model: session.exchange) { mappingConfirmed = true }
                .editingSheet()
        }
        .sheet(isPresented: $showingExport, onDismiss: exportClosed) {
            SurveyExportSheet(model: session.exchange) { exportResult = $0 }
                .editingSheet()
        }
        .alert(exchangeAlert?.title ?? "", isPresented: Binding(get: { exchangeAlert != nil }, set: { if !$0 { exchangeAlert = nil } }),
               presenting: exchangeAlert) { _ in
            Button("OK", role: .cancel) {}
        } message: { alert in
            Text(alert.message)
        }
        .alert(L10n.SurveyExchange.importedTitle,
               isPresented: Binding(get: { importWarning != nil && module.pendingAction == nil && !showingMapping },
                                    set: { if !$0 { importWarning = nil } })) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(importWarning ?? "")
        }
        .task {
            guard !session.isLoaded else { return }
            session.isLoaded = true
            perform { try module.list.reload() }
        }
        .unsavedChangesDialog(pending: Binding(get: { module.pendingAction }, set: { _ in }),
                              title: L10n.Survey.unsavedTitle, message: L10n.Survey.unsavedMessage) { decision, action in
            // Cancelar a pergunta sobre o inquérito aberto, ou falhar ao salvá-lo, descarta o rascunho importado, e com
            // ele o aviso da importação.
            if decision == .cancel, case .openDraft = action { importWarning = nil }
            do {
                try module.resolvePending(decision)
            } catch {
                importWarning = nil
                show(error)
            }
        }
        .alert(L10n.IndividualAssessment.saveFailed,
               isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "")
        }
    }

    // MARK: Importação e exportação

    /// `importFromFileToolStripMenuItem_Click`: XML grava direto e recarrega a lista; TXT, CSV, REC e DBF abrem a
    /// associação de colunas e terminam num rascunho não salvo no editor.
    private func importSurveys() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = ["xml", "txt", "csv", "rec", "dbf"].compactMap { UTType(filenameExtension: $0) }
        panel.allowsMultipleSelection = false
        guard panel.runModal() == .OK, let url = panel.url else { return }
        session.exchange.beginImport(from: url)
        switch session.exchange.phase {
        case .mapping:
            mappingConfirmed = false
            showingMapping = true
        case .finished(let warning):
            perform { try module.list.showArchive(false) }
            exchangeAlert = ExchangeAlert(title: L10n.SurveyExchange.importedTitle,
                                          message: L10n.SurveyExchange.importedXML + (warning.map { "\n\n\($0)" } ?? ""))
        case .failed(let message):
            exchangeAlert = ExchangeAlert(title: L10n.Exchange.importFailedTitle, message: message)
        case .idle:
            break
        }
    }

    /// Depois da folha: confirmada, monta o rascunho e o entrega ao módulo (que pergunta antes, se o inquérito aberto
    /// tiver alterações); fechada de outro jeito, cancela. Resta o aviso ou a falha da montagem.
    private func mappingClosed() {
        if mappingConfirmed {
            mappingConfirmed = false
            session.exchange.confirmMapping()
        } else {
            session.exchange.cancelImport()
        }
        switch session.exchange.phase {
        case .mapping:
            session.exchange.cancelImport()
        case .finished(let warning):
            importWarning = warning
        case .failed(let message):
            exchangeAlert = ExchangeAlert(title: L10n.Exchange.importFailedTitle, message: message)
        case .idle:
            break
        }
    }

    /// Depois da folha de exportação: o aviso de inquérito único ou a falha ao gravar.
    private func exportClosed() {
        defer { exportResult = nil }
        switch exportResult {
        case .success(.onlyFirstSurveyExported):
            exchangeAlert = ExchangeAlert(title: L10n.SurveyExchange.exportDone, message: L10n.SurveyExchange.onlyFirstExported)
        case .failure(let error):
            exchangeAlert = ExchangeAlert(title: L10n.Exchange.fileErrorTitle, message: "\(error.localizedDescription)")
        case .success(nil), nil:
            break
        }
    }

    /// Os inquéritos marcados, na ordem da lista. A exportação lê o banco: o inquérito aberto com alterações pendentes
    /// sairia sem elas, então pede para salvar antes.
    private func startExport() {
        let selected = module.list.surveys.compactMap(\.id).filter(module.list.checkedIDs.contains)
        if module.openSurvey?.hasUnsavedChanges == true, let openID = module.openSurvey?.survey.id, selected.contains(openID) {
            exchangeAlert = ExchangeAlert(title: L10n.SurveyExchange.exportTitle, message: L10n.SurveyExchange.exportNeedsSave)
            return
        }
        session.exchange.selectedSurveyIDs = selected
        showingExport = true
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
