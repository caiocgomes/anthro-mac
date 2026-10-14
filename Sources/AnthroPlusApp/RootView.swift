import AnthroFeatures
import SwiftUI

/// Escolhe entre a janela principal e as telas de problema do banco.
struct RootView: View {
    let model: AppModel

    var body: some View {
        Group {
            switch model.store.state {
            case .closed, .ready:
                MainSplitView(model: model)
            case .corrupted(let details):
                CorruptedDatabaseView(store: model.store, details: details)
            case .failed(let message):
                ContentUnavailableView(
                    L10n.Store.failedTitle,
                    systemImage: "exclamationmark.triangle",
                    description: Text(message)
                )
            }
        }
        .task {
            if model.store.state == .closed {
                model.store.openOnLaunch()
            }
        }
    }
}

/// Sidebar com os três módulos e o módulo selecionado à direita.
struct MainSplitView: View {
    let model: AppModel

    private var selection: Binding<AppSection?> {
        Binding(
            get: { model.selectedSection },
            set: { if let section = $0 { model.requestSection(section) } }
        )
    }

    /// O pedido pendente só é limpo pela decisão (`resolvePendingSection`), nunca pelo fechamento do alerta.
    private var pendingSection: Binding<AppSection?> {
        Binding(get: { model.pendingSection }, set: { _ in })
    }

    @State private var errorMessage: String?

    private func resolve(_ decision: UnsavedChangesDecision) {
        do {
            try model.resolvePendingSection(decision)
        } catch {
            errorMessage = IAErrorText.message(for: error)
        }
    }

    var body: some View {
        NavigationSplitView {
            List(selection: selection) {
                Section(L10n.Menu.modules) {
                    ForEach(AppSection.allCases, id: \.self) { section in
                        Label(section.title, systemImage: section.systemImage)
                            .tag(section)
                    }
                }
            }
            .navigationSplitViewColumnWidth(min: 280, ideal: 300, max: 380)
        } detail: {
            ModuleView(model: model)
                .navigationTitle(model.selectedSection.title)
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            DatabaseExporter.run(store: model.store)
                        } label: {
                            Label(L10n.Menu.exportDatabase, systemImage: "externaldrive.badge.checkmark")
                        }
                        .help(L10n.Menu.exportDatabase)
                        .disabled(model.store.state != .ready)
                    }
                }
        }
        .unsavedChangesDialog(pending: pendingSection) { decision, _ in resolve(decision) }
        .alert(L10n.IndividualAssessment.saveFailed,
               isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "")
        }
    }
}

/// Módulo selecionado; Avaliação individual e Inquérito chegam nas changes seguintes.
struct ModuleView: View {
    let model: AppModel

    var body: some View {
        switch model.selectedSection {
        case .calculator:
            CalculatorHostView(settings: model.settings)
        case .individualAssessment:
            IndividualAssessmentHostView(model: model)
        case .nutritionalSurvey:
            ModulePlaceholderView(section: model.selectedSection)
        }
    }
}

/// Estado vazio de cada módulo enquanto as changes seguintes não chegam.
struct ModulePlaceholderView: View {
    let section: AppSection

    var body: some View {
        ContentUnavailableView(
            section.title,
            systemImage: section.systemImage,
            description: Text(L10n.Section.emptyStateMessage)
        )
    }
}
