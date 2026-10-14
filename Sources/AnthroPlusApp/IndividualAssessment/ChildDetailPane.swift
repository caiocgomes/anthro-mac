import AnthroFeatures
import SwiftUI

/// Folhas abertas pela ficha.
enum DetailSheet: Identifiable {
    case visit(VisitEditorModel)
    case parent(ParentKind, ParentEditorModel)
    case address(AddressEditorModel)
    case lookupParent(ParentKind)
    case lookupAddress

    var id: String {
        switch self {
        case .visit: "visit"
        case .parent(let kind, _): "parent-\(kind)"
        case .address: "address"
        case .lookupParent(let kind): "lookup-\(kind)"
        case .lookupAddress: "lookup-address"
        }
    }
}

/// Ficha da criança (`IAMain`, painel da direita): formulário, visitas, resultado da visita e Salvar ou Cancelar.
struct ChildDetailPane: View {
    let detail: ChildDetailModel
    let database: AnthroDatabase
    let tables: GrowthReferenceTables
    let onSaved: (Int64) -> Void
    let onError: (Error) -> Void

    @State private var sheet: DetailSheet?
    @State private var chart: ChartPresentation?
    @State private var confirmingVisitDelete = false
    @State private var confirmingCancel = false

    var body: some View {
        if let draft = detail.draft {
            VStack(spacing: 0) {
                Form {
                    ChildSection(detail: detail, draft: draft)
                    linkedSection(L10n.IndividualAssessment.mother, systemImage: "figure.dress.line.vertical.figure",
                                  title: parentTitle(.mother, draft.motherID), id: draft.motherID,
                                  choose: { sheet = .lookupParent(.mother) },
                                  create: { openParentEditor(.mother, editing: nil) },
                                  edit: { openParentEditor(.mother, editing: draft.motherID) },
                                  clear: { detail.update { $0.motherID = nil } })
                    linkedSection(L10n.IndividualAssessment.father, systemImage: "figure.stand",
                                  title: parentTitle(.father, draft.fatherID), id: draft.fatherID,
                                  choose: { sheet = .lookupParent(.father) },
                                  create: { openParentEditor(.father, editing: nil) },
                                  edit: { openParentEditor(.father, editing: draft.fatherID) },
                                  clear: { detail.update { $0.fatherID = nil } })
                    linkedSection(L10n.IndividualAssessment.address, systemImage: "house",
                                  title: addressTitle(draft.addressID), id: draft.addressID,
                                  choose: { sheet = .lookupAddress },
                                  create: { sheet = .address(AddressEditorModel(database: database, editing: nil)) },
                                  edit: { openAddressEditor(draft.addressID) },
                                  clear: { detail.update { $0.addressID = nil } })
                    FollowUpSection(detail: detail, draft: draft)
                    visitsSection
                    resultSection
                }
                .formStyle(.grouped)
                .datePickerStyle(.stepperField)
                Divider()
                saveBar
            }
            .sheet(item: $sheet) { sheet in sheetContent(sheet).editingSheet() }
            .sheet(item: $chart) { presentation in GrowthChartSheet(model: presentation.model) }
            .confirmationDialog(L10n.IndividualAssessment.cancelChangesTitle, isPresented: $confirmingCancel) {
                Button(L10n.IndividualAssessment.discard, role: .destructive) {
                    do { try detail.discardChanges() } catch { onError(error) }
                }
                Button(L10n.IndividualAssessment.cancel, role: .cancel) {}
            } message: {
                Text(L10n.IndividualAssessment.cancelChangesMessage)
            }
            .confirmationDialog(L10n.IndividualAssessment.deleteVisitsTitle, isPresented: $confirmingVisitDelete) {
                Button(L10n.IndividualAssessment.delete, role: .destructive) { detail.deleteSelectedVisits() }
                Button(L10n.IndividualAssessment.cancel, role: .cancel) {}
            } message: {
                Text(L10n.IndividualAssessment.deleteVisitsMessage)
            }
        } else {
            ContentUnavailableView(L10n.IndividualAssessment.child, systemImage: "person.text.rectangle",
                                   description: Text(L10n.IndividualAssessment.noChildOpen))
        }
    }

    // MARK: Mãe, pai e endereço

    private func linkedSection(_ header: String, systemImage: String, title: String, id: Int64?,
                               choose: @escaping () -> Void, create: @escaping () -> Void, edit: @escaping () -> Void,
                               clear: @escaping () -> Void) -> some View {
        Section {
            HStack {
                Label(title, systemImage: systemImage)
                    .foregroundStyle(id == nil ? .secondary : .primary)
                    .lineLimit(1)
                Spacer()
                Button(L10n.IndividualAssessment.select, action: choose)
                Button(L10n.IndividualAssessment.new, action: create)
                Button(L10n.IndividualAssessment.edit, action: edit).disabled(id == nil)
                Button(action: clear) { Image(systemName: "xmark.circle") }
                    .buttonStyle(.borderless)
                    .help(L10n.IndividualAssessment.none)
                    .disabled(id == nil)
            }
            .controlSize(.small)
        } header: {
            Text(header)
        }
    }

    private func parentTitle(_ kind: ParentKind, _ id: Int64?) -> String {
        guard let id, let parent = try? ParentRepository(database: database).parent(kind: kind, id: id) else {
            return L10n.IndividualAssessment.none
        }
        return parent.displayName
    }

    private func addressTitle(_ id: Int64?) -> String {
        guard let id, let address = try? AddressRepository(database: database).address(id: id) else {
            return L10n.IndividualAssessment.none
        }
        return address.displayName
    }

    private func openParentEditor(_ kind: ParentKind, editing id: Int64?) {
        let record = id.flatMap { try? ParentRepository(database: database).parent(kind: kind, id: $0) }
        sheet = .parent(kind, ParentEditorModel(kind: kind, database: database, editing: record))
    }

    private func openAddressEditor(_ id: Int64?) {
        let record = id.flatMap { try? AddressRepository(database: database).address(id: $0) }
        sheet = .address(AddressEditorModel(database: database, editing: record))
    }

    @ViewBuilder
    private func sheetContent(_ sheet: DetailSheet) -> some View {
        switch sheet {
        case .visit(let editor):
            VisitEditorSheet(editor: editor, tables: tables, onCommit: { try detail.commitVisit(from: $0) },
                             chartInput: { detail.chartInput(indicator: $1, focusing: $0) })
        case .parent(let kind, let editor):
            ParentEditorSheet(kind: kind, editor: editor) { saved in
                detail.update { draft in
                    if kind == .mother { draft.motherID = saved.id } else { draft.fatherID = saved.id }
                }
            }
        case .address(let editor):
            AddressEditorSheet(editor: editor) { saved in detail.update { $0.addressID = saved.id } }
        case .lookupParent(let kind):
            LookupSheet(title: kind == .mother ? L10n.IndividualAssessment.mother : L10n.IndividualAssessment.father,
                        search: { text in LookupItems(try detail.searchParents(kind: kind, text: text)) { ($0.id, $0.displayName) } },
                        onPick: { id in
                            detail.update { draft in
                                if kind == .mother { draft.motherID = id } else { draft.fatherID = id }
                            }
                        })
        case .lookupAddress:
            LookupSheet(title: L10n.IndividualAssessment.address,
                        search: { text in LookupItems(try detail.searchAddresses(text: text)) { ($0.id, $0.displayName) } },
                        onPick: { id in detail.update { $0.addressID = id } })
        }
    }

    // MARK: Visitas e resultado

    private var visitsSection: some View {
        Section {
            VisitsTable(detail: detail, onEdit: editSelectedVisit)
                .frame(minHeight: 150, idealHeight: 190)
        } header: {
            HStack {
                Text(L10n.IndividualAssessment.visits)
                Text("(\(detail.visits.count))").foregroundStyle(.secondary)
                Spacer()
                Button { sheet = .visit(detail.makeVisitEditor(editing: nil)) } label: {
                    Label(L10n.IndividualAssessment.newVisit, systemImage: "plus")
                }
                Button(action: editSelectedVisit) { Label(L10n.IndividualAssessment.editVisit, systemImage: "pencil") }
                    .disabled(!detail.canEditVisit)
                Button { confirmingVisitDelete = true } label: {
                    Label(L10n.IndividualAssessment.deleteVisits, systemImage: "trash")
                }
                .disabled(!detail.canDeleteVisit)
                Button { showChart(.weightForAge) } label: {
                    Label(L10n.IndividualAssessment.showChart, systemImage: "chart.xyaxis.line")
                }
                .disabled(!detail.canShowVisitGraph)
            }
            .labelStyle(.iconOnly)
            .buttonStyle(.borderless)
        }
    }

    private var resultSection: some View {
        Section {
            if let result = detail.selectedResult {
                IndicatorPanelView(rows: IndicatorPanel.rows(for: result)) { indicator in showChart(indicator) }
            } else {
                Text(L10n.IndividualAssessment.noVisitSelected).foregroundStyle(.secondary)
            }
        } header: {
            Text(L10n.IndividualAssessment.result)
        }
    }

    private func editSelectedVisit() {
        guard detail.canEditVisit, let date = detail.focusedVisitDate ?? detail.selectedVisitDates.sorted().first else { return }
        sheet = .visit(detail.makeVisitEditor(editing: date))
    }

    private func showChart(_ indicator: Indicator) {
        let date = detail.focusedVisitDate ?? detail.selectedVisitDates.sorted().last
        guard let date, let visit = detail.visits.first(where: { Calendar.current.isDate($0.date, inSameDayAs: date) })
        else { return }
        let input = detail.chartInput(indicator: indicator, focusing: visit)
        chart = ChartPresentation(model: GrowthChartModel(results: input.results, currentIndex: input.currentIndex,
                                                          indicator: input.indicator, tables: tables))
    }

    private var saveBar: some View {
        HStack {
            if detail.hasUnsavedChanges {
                Label(L10n.IndividualAssessment.unsavedMessage, systemImage: "pencil.circle")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
            Spacer()
            Button(L10n.IndividualAssessment.cancel) { confirmingCancel = true }
                .disabled(!detail.hasUnsavedChanges)
            Button(L10n.IndividualAssessment.save) {
                do { onSaved(try detail.save()) } catch { onError(error) }
            }
            .keyboardShortcut("s", modifiers: .command)
            .buttonStyle(.borderedProminent)
        }
        .padding(12)
    }
}

/// Seção Criança: ID, nome, sobrenome, nascimento com data aproximada, idade, sexo e notas.
private struct ChildSection: View {
    let detail: ChildDetailModel
    let draft: ChildDraft

    var body: some View {
        Section {
            if detail.isDisplayIDEditable {
                // Campo numérico: texto que não é inteiro volta ao último valor válido, sem virar `nil` em silêncio.
                TextField(L10n.IndividualAssessment.displayID,
                          value: Binding(get: { draft.displayID }, set: { id in detail.update { $0.displayID = id } }),
                          format: .number.grouping(.never))
            } else {
                LabeledContent(L10n.IndividualAssessment.displayID) {
                    Text(draft.displayID.map(String.init) ?? L10n.IndividualAssessment.automaticID)
                        .foregroundStyle(draft.displayID == nil ? .secondary : .primary)
                }
            }
            TextField(L10n.IndividualAssessment.firstName, text: text(\.firstName))
            TextField(L10n.IndividualAssessment.lastName, text: text(\.lastName))
            DatePicker(L10n.IndividualAssessment.dateOfBirth,
                       selection: Binding(get: { draft.dateOfBirth }, set: { detail.setDateOfBirth($0) }),
                       displayedComponents: .date)
            Toggle(L10n.IndividualAssessment.approximateDate,
                   isOn: Binding(get: { draft.dateOfBirthIsApprox }, set: { detail.setDateOfBirthIsApprox($0) }))
            LabeledContent(L10n.Age.label) {
                Text(ageValue).monospacedDigit().fontWeight(.medium)
            }
            Picker(L10n.IndividualAssessment.sex, selection: Binding(get: { draft.sex }, set: { sex in detail.update { $0.sex = sex } })) {
                Text(L10n.Calculator.male).tag(Sex?.some(.boy))
                Text(L10n.Calculator.female).tag(Sex?.some(.girl))
            }
            .pickerStyle(.segmented)
            TextField(L10n.IndividualAssessment.notes, text: text(\.notes), axis: .vertical)
                .lineLimit(2...4)
        } header: {
            Text(draft.id == nil ? L10n.IndividualAssessment.newChild : L10n.IndividualAssessment.child)
        }
    }

    private var ageValue: String {
        let prefix = "\(L10n.Age.label): "
        return detail.ageLabel.hasPrefix(prefix) ? String(detail.ageLabel.dropFirst(prefix.count)) : detail.ageLabel
    }

    private func text(_ keyPath: WritableKeyPath<ChildDraft, String>) -> Binding<String> {
        Binding(get: { draft[keyPath: keyPath] }, set: { value in detail.update { $0[keyPath: keyPath] = value } })
    }
}

/// Seção Acompanhamento (D16): data do retorno, intervalo em dias e destino.
private struct FollowUpSection: View {
    let detail: ChildDetailModel
    let draft: ChildDraft

    var body: some View {
        Section {
            Toggle(L10n.IndividualAssessment.followUpDate, isOn: Binding(
                get: { draft.followUpDate != nil },
                set: { on in detail.update { $0.followUpDate = on ? ($0.followUpDate ?? Date()) : nil } }))
            if let date = draft.followUpDate {
                DatePicker(L10n.IndividualAssessment.followUpDate,
                           selection: Binding(get: { date }, set: { value in detail.update { $0.followUpDate = value } }),
                           displayedComponents: .date)
            }
            TextField(L10n.IndividualAssessment.followUpInterval,
                      value: Binding(get: { draft.followUpInterval },
                                     set: { days in detail.update { $0.followUpInterval = days } }),
                      format: .number.grouping(.never))
            TextField(L10n.IndividualAssessment.followUpRefTo, text: Binding(
                get: { draft.followUpRefTo }, set: { value in detail.update { $0.followUpRefTo = value } }))
        } header: {
            Text(L10n.IndividualAssessment.followUp)
        }
    }
}

/// Tabela de visitas com seleção múltipla; a visita em foco é a última selecionada (`dgvVisits_RowEnter`).
private struct VisitsTable: View {
    let detail: ChildDetailModel
    let onEdit: () -> Void

    private struct Item: Identifiable {
        let id: Date
        let row: VisitRow
    }

    var body: some View {
        let items = zip(detail.visits, detail.visitRows).map { Item(id: $0.date, row: $1) }
        Table(items, selection: Binding(
            get: { detail.selectedVisitDates },
            set: { selection in
                detail.selectedVisitDates = selection
                detail.focusedVisitDate = selection.sorted().last
            })) {
            TableColumn(L10n.IndividualAssessment.visitDate) { Text($0.row.date).monospacedDigit() }
            TableColumn(L10n.IndividualAssessment.weight) { Text($0.row.weight).monospacedDigit() }
            TableColumn(L10n.IndividualAssessment.oedema) { Text($0.row.oedema) }
            TableColumn(L10n.IndividualAssessment.recumbent) { Text($0.row.recumbent) }
            TableColumn(L10n.IndividualAssessment.lengthOrHeight) { Text($0.row.lengthOrHeight).monospacedDigit() }
        }
        .contextMenu(forSelectionType: Date.self) { _ in
            Button(L10n.IndividualAssessment.editVisit, action: onEdit)
        } primaryAction: { _ in
            onEdit()
        }
    }
}
