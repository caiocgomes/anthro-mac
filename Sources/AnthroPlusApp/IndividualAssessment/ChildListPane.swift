import AnthroFeatures
import SwiftUI

/// Lista de crianças com caixas de marcação e barra de ações (`IAMain.clbChildren` e a sua barra).
struct ChildListPane: View {
    let list: ChildListModel
    let selectedChildID: Int64?
    let onSelect: (Int64) -> Void
    let onNew: () -> Void
    let onError: (Error) -> Void

    @State private var showingSearch = false
    @State private var confirmingDelete = false

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            if list.rows.isEmpty {
                ContentUnavailableView(L10n.IndividualAssessment.emptyList, systemImage: "person.2")
                    .frame(maxHeight: .infinity)
            } else {
                List(selection: Binding(get: { selectedChildID }, set: { if let id = $0 { onSelect(id) } })) {
                    ForEach(list.rows) { row in
                        ChildListRowView(row: row, isChecked: Binding(
                            get: { list.checkedIDs.contains(row.id) },
                            set: { checked in
                                if checked { list.checkedIDs.insert(row.id) } else { list.checkedIDs.remove(row.id) }
                            }))
                        .tag(row.id)
                    }
                }
                .listStyle(.inset)
            }
            Divider()
            actions
        }
        .sheet(isPresented: $showingSearch) {
            ChildSearchSheet { criteria in
                perform { try list.search(criteria) }
            }
        }
        .confirmationDialog(L10n.IndividualAssessment.deleteChildrenTitle, isPresented: $confirmingDelete) {
            Button(L10n.IndividualAssessment.delete, role: .destructive) { perform { try list.deleteChecked() } }
            Button(L10n.IndividualAssessment.cancel, role: .cancel) {}
        } message: {
            Text(L10n.IndividualAssessment.deleteChildrenMessage)
        }
    }

    private var title: String {
        switch list.mode {
        case .active: L10n.IndividualAssessment.children
        case .archive: L10n.IndividualAssessment.archive
        case .searchResults: L10n.IndividualAssessment.searchResults
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.headline)
                Text("\(list.rows.count) · \(list.checkedIDs.count) \(L10n.IndividualAssessment.checkedCount)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if list.canCreate {
                Button(action: onNew) {
                    Label(L10n.IndividualAssessment.newChild, systemImage: "plus")
                }
                .labelStyle(.iconOnly)
                .help(L10n.IndividualAssessment.newChild)
            }
            if list.canSearch {
                Button { showingSearch = true } label: {
                    Label(L10n.IndividualAssessment.search, systemImage: "magnifyingglass")
                }
                .labelStyle(.iconOnly)
                .help(L10n.IndividualAssessment.search)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }

    @ViewBuilder
    private var actions: some View {
        HStack(spacing: 8) {
            switch list.mode {
            case .archive:
                Button(L10n.IndividualAssessment.restore) { perform { try list.restoreChecked() } }
                    .disabled(!list.canRestore)
                Spacer()
                Button(L10n.IndividualAssessment.backToList) { perform { try list.showActive() } }
            case .active, .searchResults:
                Button(L10n.IndividualAssessment.archiveAction) { perform { try list.archiveChecked() } }
                    .disabled(!list.canArchive)
                Button(L10n.IndividualAssessment.delete, role: .destructive) { confirmingDelete = true }
                    .disabled(!list.canDelete)
                Spacer()
                if list.mode == .searchResults {
                    Button(L10n.IndividualAssessment.clearSearch) { perform { try list.showActive() } }
                } else {
                    Button { perform { try list.showArchive() } } label: {
                        Label(L10n.IndividualAssessment.archive, systemImage: "archivebox")
                    }
                }
            }
        }
        .controlSize(.small)
        .padding(10)
    }

    private func perform(_ action: () throws -> Void) {
        do { try action() } catch { onError(error) }
    }
}

private struct ChildListRowView: View {
    let row: ChildListRow
    @Binding var isChecked: Bool

    var body: some View {
        HStack(spacing: 8) {
            Toggle("", isOn: $isChecked)
                .toggleStyle(.checkbox)
                .labelsHidden()
            Text(row.title)
                .lineLimit(1)
        }
    }
}

/// `IASearchDialog`: nome e sobrenome com curingas, sexo, faixa de ID e faixa de nascimento.
struct ChildSearchSheet: View {
    let onSearch: (ChildSearchCriteria) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var sex: Sex?
    @State private var idFrom = ""
    @State private var idTo = ""
    @State private var useBirthRange = false
    @State private var birthFrom = Date()
    @State private var birthTo = Date()

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Form {
                Section {
                    TextField(L10n.IndividualAssessment.firstName, text: $firstName)
                    TextField(L10n.IndividualAssessment.lastName, text: $lastName)
                } footer: {
                    Text(L10n.IndividualAssessment.wildcardHint).font(.caption).foregroundStyle(.secondary)
                }
                Picker(L10n.IndividualAssessment.sex, selection: $sex) {
                    Text(L10n.IndividualAssessment.any).tag(Sex?.none)
                    Text(L10n.Calculator.male).tag(Sex?.some(.boy))
                    Text(L10n.Calculator.female).tag(Sex?.some(.girl))
                }
                .pickerStyle(.segmented)
                HStack {
                    TextField(L10n.IndividualAssessment.idFrom, text: $idFrom)
                    TextField(L10n.IndividualAssessment.idTo, text: $idTo)
                }
                Toggle(L10n.IndividualAssessment.birthFrom, isOn: $useBirthRange)
                if useBirthRange {
                    DatePicker(L10n.IndividualAssessment.birthFrom, selection: $birthFrom, displayedComponents: .date)
                    DatePicker(L10n.IndividualAssessment.birthTo, selection: $birthTo, displayedComponents: .date)
                }
            }
            .formStyle(.grouped)
            .datePickerStyle(.stepperField)
            HStack {
                Button(L10n.IndividualAssessment.clearSearch) {
                    onSearch(ChildSearchCriteria())
                    dismiss()
                }
                Spacer()
                Button(L10n.IndividualAssessment.cancel, role: .cancel) { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Button(L10n.IndividualAssessment.search) {
                    onSearch(criteria)
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
            .padding(16)
        }
        .frame(width: 460)
        .navigationTitle(L10n.IndividualAssessment.searchTitle)
    }

    private var criteria: ChildSearchCriteria {
        ChildSearchCriteria(firstName: firstName, lastName: lastName, sex: sex, displayIDFrom: Int(idFrom),
                            displayIDTo: Int(idTo), dateOfBirthFrom: useBirthRange ? birthFrom : nil,
                            dateOfBirthTo: useBirthRange ? birthTo : nil)
    }
}
