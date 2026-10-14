import AnthroFeatures
import SwiftUI

/// Lista de inquéritos com caixas de marcação e barra de ações (`NSMain.clbSurveys` e a sua barra).
struct SurveyListView: View {
    let module: SurveyModuleModel
    let onError: (Error) -> Void

    @State private var confirmingDelete = false

    private var list: SurveyListModel { module.list }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            if list.surveys.isEmpty {
                ContentUnavailableView(L10n.Survey.emptyList, systemImage: "chart.bar.doc.horizontal")
                    .frame(maxHeight: .infinity)
            } else {
                List(selection: Binding(get: { list.showsArchive ? nil : module.openSurvey?.survey.id },
                                        set: { id in if let id, !list.showsArchive { perform { _ = try module.open(id: id) } } })) {
                    ForEach(list.surveys) { survey in
                        if let id = survey.id {
                            // Caixa sem rótulo e nome à parte, como a lista de crianças: clicar no nome abre o
                            // inquérito; só a caixa marca.
                            HStack(spacing: 8) {
                                Toggle("", isOn: Binding(get: { list.checkedIDs.contains(id) },
                                                         set: { checked in
                                                             if checked { list.checkedIDs.insert(id) } else { list.checkedIDs.remove(id) }
                                                         }))
                                    .toggleStyle(.checkbox)
                                    .labelsHidden()
                                Text(survey.name).lineLimit(1)
                            }
                            .tag(id)
                        }
                    }
                }
                .listStyle(.inset)
            }
            Divider()
            actions
        }
        .confirmationDialog(L10n.Survey.deleteSurveysTitle, isPresented: $confirmingDelete) {
            Button(L10n.Survey.delete, role: .destructive) { perform { try module.deleteChecked() } }
            Button(L10n.Survey.cancel, role: .cancel) {}
        } message: {
            Text(L10n.Survey.deleteSurveysMessage)
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(list.showsArchive ? L10n.Survey.archive : L10n.Survey.surveys).font(.headline)
                Text("\(list.surveys.count) · \(list.checkedIDs.count) \(L10n.Survey.checkedCount)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if !list.showsArchive {
                Button { _ = module.createSurvey() } label: {
                    Label(L10n.Survey.newSurvey, systemImage: "plus")
                }
                .labelStyle(.iconOnly)
                .help(L10n.Survey.newSurvey)
            }
        }
        .padding(12)
    }

    private var actions: some View {
        HStack {
            if list.showsArchive {
                Button(L10n.Survey.restore) { perform { try list.restoreChecked() } }
                    .disabled(!list.canRestore)
                Spacer()
                Button(L10n.Survey.backToActive) { perform { try list.showArchive(false) } }
            } else {
                Button(L10n.Survey.archiveAction) { perform { _ = try module.archiveChecked() } }
                    .disabled(!list.canArchive)
                Button(L10n.Survey.delete) { confirmingDelete = true }
                    .disabled(!list.canDelete)
                Spacer()
                Button(L10n.Survey.viewArchive) { perform { try list.showArchive(true) } }
            }
        }
        .controlSize(.small)
        .padding(10)
    }

    private func perform(_ action: () throws -> Void) {
        do {
            try action()
        } catch {
            onError(error)
        }
    }
}
