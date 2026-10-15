import AnthroFeatures
import AppKit
import SwiftUI
import UniformTypeIdentifiers

/// Estado do módulo guardado no `AppModel`: sobrevive ao fechamento da janela, então a ficha em edição não se perde.
@MainActor
final class IndividualAssessmentSession {
    let database: AnthroDatabase
    let list: ChildListModel
    let detail: ChildDetailModel
    /// Modelo de dados adicionais; `nil` se não puder ser lido, e então o botão de gerenciar fica desabilitado.
    let additionalData: IndividualAdditionalDataModel?
    /// Importação, exportação e relatório (`tsbChildrenImport_Click`, `tsbChildrenExport_Click`, `GenerateChildReport`).
    let exchange: ChildExchangeModel
    var isLoaded = false

    init(database: AnthroDatabase, settings: AppSettings, tables: GrowthReferenceTables) {
        self.database = database
        list = ChildListModel(database: database, settings: settings)
        detail = ChildDetailModel(database: database, settings: settings, engine: AnthroEngine(tables: tables))
        additionalData = try? IndividualAdditionalDataModel(repository: AdditionalDataTemplateRepository(database: database))
        let repositories = RepositoryChildExchange(
            database: database, children: ChildRepository(database: database), visits: VisitRepository(database: database),
            parents: ParentRepository(database: database), addresses: AddressRepository(database: database),
            templates: AdditionalDataTemplateRepository(database: database), engine: AnthroEngine(tables: tables))
        exchange = ChildExchangeModel(source: repositories, sink: repositories)
    }
}

/// Módulo Avaliação individual: lista de crianças à esquerda e ficha à direita, como `IAMain`.
struct IndividualAssessmentHostView: View {
    let model: AppModel

    var body: some View {
        if let database = model.store.database, let tables = try? GrowthReferenceTables.bundled() {
            IndividualAssessmentView(app: model, session: session(database: database, tables: tables), tables: tables)
        } else {
            ContentUnavailableView(L10n.Calculator.tablesUnavailable, systemImage: "exclamationmark.triangle")
        }
    }

    private func session(database: AnthroDatabase, tables: GrowthReferenceTables) -> IndividualAssessmentSession {
        if let existing = model.moduleSessions[.individualAssessment] as? IndividualAssessmentSession {
            model.unsavedChangesGuard = existing.detail
            return existing
        }
        let created = IndividualAssessmentSession(database: database, settings: model.settings, tables: tables)
        model.moduleSessions[.individualAssessment] = created
        model.unsavedChangesGuard = created.detail
        return created
    }
}

/// Pedido que espera a decisão sobre alterações não salvas.
enum PendingNavigation: Equatable {
    case open(Int64)
    case new
    case archiveChecked
}

struct IndividualAssessmentView: View {
    let app: AppModel
    let session: IndividualAssessmentSession
    let tables: GrowthReferenceTables

    @State private var selectedChildID: Int64?
    @State private var pending: PendingNavigation?
    @State private var errorMessage: String?
    @State private var templateEditor: AdditionalDataEditorPresentation?
    @State private var showingExport = false
    @State private var exchangeAlert: ExchangeAlert?

    private var list: ChildListModel { session.list }
    private var detail: ChildDetailModel { session.detail }

    var body: some View {
        HSplitView {
            ChildListPane(list: list, selectedChildID: selectedChildID, onSelect: { request(.open($0)) },
                          onNew: { request(.new) }, onArchive: archiveChecked, onDelete: deleteChecked, onError: show)
                .frame(minWidth: 220, idealWidth: 270, maxWidth: 360, maxHeight: .infinity)
            ChildDetailPane(detail: detail, database: session.database, tables: tables, onSaved: childSaved,
                            onError: show)
                .frame(minWidth: 440, maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .environment(\.locale, Locale(identifier: "pt_BR"))
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                // `IAMain.miManageAddData_Click`: o modelo vale para as visitas criadas daqui em diante.
                Button {
                    if let model = session.additionalData {
                        templateEditor = AdditionalDataEditorPresentation(editor: model.makeEditor())
                    }
                } label: {
                    Label(L10n.AddData.manage, systemImage: "list.bullet.rectangle")
                }
                .help(L10n.AddData.manage)
                .disabled(session.additionalData == nil)
            }
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button(L10n.Exchange.importChildren) { importChildren() }
                    Button(L10n.Exchange.exportChildren) { startExport() }
                        .disabled(list.checkedIDs.isEmpty)
                    Button(L10n.Exchange.childReport) { writeReport() }
                        .disabled(detail.draft?.id == nil)
                } label: {
                    Label(L10n.Exchange.menu, systemImage: "square.and.arrow.up.on.square")
                }
                .help(L10n.Exchange.menu)
            }
        }
        .sheet(isPresented: $showingExport) {
            ChildExportSheet(model: session.exchange) { error in
                if let error { exchangeAlert = ExchangeAlert(title: L10n.Exchange.fileErrorTitle, message: "\(error.localizedDescription)") }
            }
            .editingSheet()
        }
        .alert(exchangeAlert?.title ?? "", isPresented: Binding(get: { exchangeAlert != nil }, set: { if !$0 { exchangeAlert = nil } }),
               presenting: exchangeAlert) { _ in
            Button("OK", role: .cancel) {}
        } message: { alert in
            Text(alert.message)
        }
        .sheet(item: $templateEditor) { presentation in
            AdditionalDataEditorSheet(editor: presentation.editor, title: L10n.AddData.templateTitle) {
                try session.additionalData?.commit($0)
            }
            .editingSheet()
        }
        .task {
            selectedChildID = detail.draft?.id
            guard !session.isLoaded else { return }
            session.isLoaded = true
            perform { try list.load(keeping: detail.linkedRecords) }
        }
        .unsavedChangesDialog(pending: $pending) { decision, target in
            perform {
                guard try detail.proceedAfterUnsavedChanges(decision) else { return }
                if decision == .save { try list.showActive() }
                try navigate(target)
            }
        }
        .alert(L10n.IndividualAssessment.saveFailed,
               isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "")
        }
    }

    /// `IAMain.AskForSave` antes de trocar de criança, criar outra ou arquivar a criança aberta.
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
        case .archiveChecked:
            let closesOpenChild = detail.draft?.id.map(list.checkedIDs.contains) ?? false
            try list.archiveChecked()
            if closesOpenChild { closeDetail() }
        }
    }

    /// `tsbChildrenArchive_Click`: pergunta antes se a criança aberta está entre as marcadas e tem pendências.
    private func archiveChecked() {
        let opensChecked = detail.draft?.id.map(list.checkedIDs.contains) ?? false
        if opensChecked {
            request(.archiveChecked)
        } else {
            perform { try navigate(.archiveChecked) }
        }
    }

    /// `tsbChildrenDelete_Click`: a criança aberta que for excluída fecha a ficha sem perguntar (será apagada).
    private func deleteChecked() {
        perform {
            let closesOpenChild = detail.draft?.id.map(list.checkedIDs.contains) ?? false
            if closesOpenChild { closeDetail() }
            try list.deleteChecked(keeping: detail.linkedRecords)
        }
    }

    private func closeDetail() {
        detail.close()
        selectedChildID = nil
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

    // MARK: Importação, exportação e relatório

    /// `tsbChildrenImport_Click`: só XML; o arquivo é lido inteiro antes de gravar e, aceito, a lista ativa é recarregada.
    private func importChildren() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.xml]
        panel.allowsMultipleSelection = false
        guard panel.runModal() == .OK, let url = panel.url else { return }
        switch session.exchange.importXML(from: url) {
        case .imported(let count):
            perform { try list.showActive() }
            exchangeAlert = ExchangeAlert(title: L10n.Exchange.importedTitle, message: "\(count) \(L10n.Exchange.importedSuffix)")
        case .failed(let message):
            exchangeAlert = ExchangeAlert(title: L10n.Exchange.importFailedTitle, message: message)
        }
    }

    /// As crianças marcadas, na ordem da lista.
    private func startExport() {
        session.exchange.selectedChildIDs = list.rows.map(\.id).filter(list.checkedIDs.contains)
        showingExport = true
    }

    /// `GenerateChildReport`: relatório da ficha gravada; com alterações pendentes, pede para salvar antes.
    private func writeReport() {
        guard let id = detail.draft?.id else { return }
        guard !detail.hasUnsavedChanges else {
            exchangeAlert = ExchangeAlert(title: L10n.Exchange.childReport, message: L10n.Exchange.reportNeedsSave)
            return
        }
        do {
            let panel = NSSavePanel()
            panel.nameFieldStringValue = try session.exchange.suggestedReportFileName(childID: id)
            panel.allowedContentTypes = [.plainText]
            guard panel.runModal() == .OK, let url = panel.url else { return }
            try session.exchange.writeReport(childID: id, to: url)
            NSWorkspace.shared.open(url)
        } catch {
            exchangeAlert = ExchangeAlert(title: L10n.Exchange.fileErrorTitle, message: "\(error.localizedDescription)")
        }
    }
}

/// Aviso de importação, exportação ou relatório.
struct ExchangeAlert: Identifiable {
    let id = UUID()
    let title: String
    let message: String
}

/// Mensagem em pt-BR para os erros de validação e de banco.
enum IAErrorText {
    static func message(for error: Error) -> String {
        switch error {
        case ChildValidationError.sexRequired: L10n.IndividualAssessment.sexRequired
        case VisitValidationError.duplicateDate: L10n.IndividualAssessment.duplicateDate
        case VisitValidationError.invalidMeasurement, ParentValidationError.invalidMeasurement:
            L10n.IndividualAssessment.invalidMeasurement
        case StoreError.recordNotFound: L10n.IndividualAssessment.recordGone
        default: AdditionalDataErrorText.knownMessage(for: error) ?? "\(L10n.IndividualAssessment.databaseError) \(error)"
        }
    }
}

extension View {
    /// Diálogo Salvar, Descartar ou Cancelar de `IAMain.AskForSave`; a ação recebe o pedido apresentado, então a ordem
    /// em que o SwiftUI limpa a binding não troca Salvar por Cancelar.
    func unsavedChangesDialog<Pending>(pending: Binding<Pending?>, title: String = L10n.IndividualAssessment.unsavedTitle,
                                       message: String = L10n.IndividualAssessment.unsavedMessage,
                                       onDecision: @escaping (UnsavedChangesDecision, Pending) -> Void) -> some View {
        alert(title,
              isPresented: Binding(get: { pending.wrappedValue != nil }, set: { if !$0 { pending.wrappedValue = nil } }),
              presenting: pending.wrappedValue) { value in
            Button(L10n.IndividualAssessment.save) { onDecision(.save, value) }
                .keyboardShortcut(.defaultAction)
            Button(L10n.IndividualAssessment.discard, role: .destructive) { onDecision(.discard, value) }
            Button(L10n.IndividualAssessment.cancel, role: .cancel) { onDecision(.cancel, value) }
        } message: { _ in
            Text(message)
        }
    }
}
