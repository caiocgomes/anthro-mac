import AnthroFeatures
import AppKit
import SwiftUI
import UniformTypeIdentifiers

/// Editor aberto numa folha; o invólucro dá identidade a cada abertura.
struct RecordEditorPresentation: Identifiable {
    let id = UUID()
    let editor: RecordEditorModel
    let isNew: Bool
}

struct OptionsEditorPresentation: Identifiable {
    let id = UUID()
    let editor: SurveyOptionsEditorModel
}

/// Relatório gravado, mostrado no app.
struct ReportPresentation: Identifiable {
    let id = UUID()
    let title: String
    let table: [[String]]
}

/// Abas do inquérito aberto (`tabNutriSurvey`).
enum SurveyTab: Hashable {
    case records, results
}

/// Inquérito aberto: nome e notas, ações de gravação, barra de registros, tabela e painel de resultados (`NSMain`).
struct SurveyDetailPane: View {
    let module: SurveyModuleModel
    @Bindable var detail: SurveyDetailModel
    let onError: (Error) -> Void

    @State private var selection: Set<Int> = []
    @State private var recordEditor: RecordEditorPresentation?
    @State private var optionsEditor: OptionsEditorPresentation?
    @State private var definitionEditor: AdditionalDataEditorPresentation?
    @State private var showingFilter = false
    @State private var confirmingDiscard = false
    @State private var confirmingDelete = false
    @State private var tab: SurveyTab = .records
    /// Modelo da aba de resultados, refeito com os registros atuais ao abrir a aba e quando eles mudam.
    @State private var analysis: SurveyAnalysisModel?
    @State private var askingClusterAnalysis = false
    @State private var report: ReportPresentation?
    @State private var reportError: String?

    var body: some View {
        VStack(spacing: 0) {
            header
            Picker("", selection: $tab) {
                Text(L10n.SurveyAnalysis.tabRecords).tag(SurveyTab.records)
                Text(L10n.SurveyAnalysis.tabResults).tag(SurveyTab.results)
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .frame(maxWidth: 320)
            .padding(.bottom, 8)
            Divider()
            switch tab {
            case .records:
                recordBar
                Divider()
                VSplitView {
                    SurveyTableView(detail: detail, selection: $selection, onEdit: edit)
                        .frame(minHeight: 220, maxHeight: .infinity)
                    results
                        .frame(minHeight: 150, idealHeight: 220)
                }
            case .results:
                if let analysis {
                    SurveyResultsView(model: analysis)
                } else {
                    ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
        .onChange(of: tab) { _, newValue in
            if newValue == .results { analysis = detail.makeAnalysisModel() }
        }
        .onChange(of: detail.allRecords) { _, _ in
            if tab == .results { analysis = detail.makeAnalysisModel() }
        }
        .onChange(of: detail.options) { _, _ in
            if tab == .results { analysis = detail.makeAnalysisModel() }
        }
        .confirmationDialog(L10n.SurveyAnalysis.clusterQuestion, isPresented: $askingClusterAnalysis) {
            Button(L10n.SurveyAnalysis.yes) { exportReport(estimates: false, improved: true) }
            Button(L10n.SurveyAnalysis.no) { exportReport(estimates: false, improved: false) }
            Button(L10n.SurveyAnalysis.cancel, role: .cancel) {}
        }
        .alert(L10n.SurveyAnalysis.reportFailedTitle,
               isPresented: Binding(get: { reportError != nil }, set: { if !$0 { reportError = nil } })) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(reportError ?? "")
        }
        .sheet(item: $report) { presentation in
            SurveyReportTableView(title: presentation.title, table: presentation.table)
        }
        .onChange(of: selection) { _, newValue in
            detail.select(visibleIndex: newValue.count == 1 ? newValue.first : nil)
        }
        .onChange(of: detail.visibleRows) { _, _ in selection = [] }
        .sheet(item: $recordEditor) { presentation in
            RecordEditorSheet(editor: presentation.editor, isNew: presentation.isNew, surveyName: detail.name) {
                try detail.commit($0)
            }
            .editingSheet()
        }
        .sheet(item: $optionsEditor) { presentation in
            SurveyOptionsSheet(editor: presentation.editor) { try detail.applyOptions($0) }
                .editingSheet()
        }
        .sheet(item: $definitionEditor) { presentation in
            AdditionalDataEditorSheet(editor: presentation.editor, title: L10n.AddData.definitionTitle) {
                try detail.applyAdditionalDataDefinition($0)
            }
            .editingSheet()
        }
        .sheet(isPresented: $showingFilter) {
            SurveyFilterSheet(columns: detail.columns) { detail.applyFilter($0) }
                .editingSheet()
        }
        .confirmationDialog(L10n.Survey.discardTitle, isPresented: $confirmingDiscard) {
            Button(L10n.Survey.discard, role: .destructive) { discard() }
            Button(L10n.Survey.cancel, role: .cancel) {}
        } message: {
            Text(L10n.Survey.discardMessage)
        }
        .confirmationDialog(L10n.Survey.deleteRecordsTitle, isPresented: $confirmingDelete) {
            Button(L10n.Survey.delete, role: .destructive) { detail.deleteRecords(visibleIndices: IndexSet(selection)) }
            Button(L10n.Survey.cancel, role: .cancel) {}
        } message: {
            Text(L10n.Survey.deleteRecordsMessage)
        }
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                TextField(L10n.Survey.name, text: $detail.name)
                    .textFieldStyle(.roundedBorder)
                    .font(.title3.weight(.semibold))
                TextField(L10n.Survey.notes, text: $detail.notes, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(1...3)
            }
            VStack(alignment: .trailing, spacing: 8) {
                HStack {
                    Menu {
                        Button(L10n.SurveyAnalysis.standardReport) { askingClusterAnalysis = true }
                        Button(L10n.SurveyAnalysis.estimatesReport) { exportReport(estimates: true, improved: false) }
                    } label: {
                        Label(L10n.SurveyAnalysis.reports, systemImage: "tablecells")
                    }
                    .fixedSize()
                    .disabled(detail.allRecords.isEmpty)
                    Button {
                        definitionEditor = AdditionalDataEditorPresentation(editor: detail.makeAdditionalDataDefinitionEditor())
                    } label: {
                        Label(L10n.AddData.surveyButton, systemImage: "list.bullet.rectangle")
                    }
                    Button { optionsEditor = OptionsEditorPresentation(editor: detail.makeOptionsEditor()) } label: {
                        Label(L10n.Survey.options, systemImage: "slider.horizontal.3")
                    }
                    Button(L10n.Survey.discard) { confirmingDiscard = true }
                        .disabled(!detail.hasUnsavedChanges)
                    Button(L10n.Survey.save) { save() }
                        .keyboardShortcut("s", modifiers: .command)
                        .disabled(!detail.hasUnsavedChanges)
                        .buttonStyle(.borderedProminent)
                }
                if detail.hasUnsavedChanges {
                    Text(L10n.Survey.unsavedMessage).font(.caption).foregroundStyle(.orange)
                }
            }
        }
        .padding(12)
    }

    private var recordBar: some View {
        HStack(spacing: 8) {
            Button { recordEditor = RecordEditorPresentation(editor: detail.makeNewRecordEditor(), isNew: true) } label: {
                Label(L10n.Survey.newRecord, systemImage: "plus")
            }
            .keyboardShortcut("n", modifiers: .command)
            Button { if let index = selection.first { edit(index) } } label: {
                Label(L10n.Survey.editRecord, systemImage: "pencil")
            }
            .disabled(selection.count != 1)
            Button { confirmingDelete = true } label: {
                Label(L10n.Survey.deleteRecords, systemImage: "trash")
            }
            .disabled(selection.isEmpty)
            Divider().frame(height: 18)
            Button { showingFilter = true } label: {
                Label(L10n.Survey.filter, systemImage: "line.3.horizontal.decrease.circle")
            }
            .disabled(detail.visibleRows.isEmpty)
            if detail.isFiltered {
                Button { detail.clearFilter() } label: {
                    Label(L10n.Survey.clearFilter, systemImage: "xmark.circle")
                }
            }
            Button { copySelection() } label: {
                Label(L10n.Survey.copy, systemImage: "doc.on.doc")
            }
            .disabled(selection.isEmpty)
            Spacer()
            Text(detail.recordCountLabel).font(.callout).foregroundStyle(.secondary).monospacedDigit()
        }
        .labelStyle(.titleAndIcon)
        .controlSize(.small)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    @ViewBuilder private var results: some View {
        if let result = detail.selectedResult {
            ScrollView {
                IndicatorPanelView(rows: IndicatorPanel.rows(for: result), onShowChart: nil)
                    .padding(12)
            }
        } else {
            ContentUnavailableView(L10n.Survey.noRecordSelected, systemImage: "hand.point.up.left")
        }
    }

    /// `tsbExportExcel_Click` e `tsbReportExcelGlobal_Click`: local do arquivo, gravação, abertura na planilha e a tabela
    /// no app; a análise usa os registros atuais do inquérito aberto, como o original.
    private func exportReport(estimates: Bool, improved: Bool) {
        let model = detail.makeAnalysisModel()
        let panel = NSSavePanel()
        panel.nameFieldStringValue = estimates ? model.defaultFileName(.estimates)
            : model.defaultFileName(.standard(improvedClusterAnalysis: improved))
        panel.allowedContentTypes = [.plainText]
        guard panel.runModal() == .OK, let url = panel.url else { return }
        if estimates {
            model.exportReport(.estimates, to: url, opener: WorkspaceReportOpener())
        } else {
            model.exportReport(.standard(improvedClusterAnalysis: improved), to: url, opener: WorkspaceReportOpener())
        }
        if let message = model.errorMessage {
            reportError = message
        } else if let table = model.lastReport?.table {
            report = ReportPresentation(title: url.lastPathComponent, table: table)
        }
    }

    private func edit(_ visibleIndex: Int) {
        guard detail.visibleRows.indices.contains(visibleIndex) else { return }
        recordEditor = RecordEditorPresentation(editor: detail.makeEditor(visibleIndex: visibleIndex), isNew: false)
    }

    /// ⌘C e o botão Copiar gravam o texto de `clipboardText` como string (design D8).
    private func copySelection() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(detail.clipboardText(selectedVisibleIndices: IndexSet(selection)), forType: .string)
    }

    private func save() {
        do {
            try detail.save()
            try module.list.reload()
        } catch {
            onError(error)
        }
    }

    /// Inquérito nunca salvo, descartado, fecha (`tsbSurveyCancel_Click`).
    private func discard() {
        do {
            try detail.discardChanges()
            if detail.survey.id == nil { _ = module.requestClose() }
        } catch {
            onError(error)
        }
    }
}

/// Ordenação pelo cabeçalho: o comparador só carrega a coluna clicada; quem ordena é `SurveyDetailModel.sort(by:)`,
/// que inverte a lista a cada novo clique na mesma coluna, como o original.
struct SurveyColumnSort: SortComparator, Hashable {
    let column: SurveyTableColumn
    var order: SortOrder = .forward

    func compare(_ lhs: SurveyTableView.Item, _ rhs: SurveyTableView.Item) -> ComparisonResult {
        .orderedSame
    }
}

/// Tabela de registros (`dgvRecords`): células derivadas em cinza e z implausível destacado (`SetCellBackColor`).
struct SurveyTableView: View {
    let detail: SurveyDetailModel
    @Binding var selection: Set<Int>
    let onEdit: (Int) -> Void

    struct Item: Identifiable {
        let id: Int
        let row: SurveyRecordRow
    }

    private var items: [Item] {
        detail.visibleRows.enumerated().map { Item(id: $0.offset, row: $0.element) }
    }

    private var sortOrder: Binding<[SurveyColumnSort]> {
        Binding(
            get: {
                detail.sortColumn.map { [SurveyColumnSort(column: $0, order: detail.sortAscending ? .forward : .reverse)] } ?? []
            },
            set: { newValue in
                if let clicked = newValue.first { detail.sort(by: clicked.column) }
            })
    }

    var body: some View {
        // `TableColumnForEach` e `if` no construtor de colunas exigem macOS 14.4 (design D13 da add-additional-data);
        // antes disso a tabela mostra só as colunas fixas, e filtro e cópia continuam incluindo as adicionais.
        if #available(macOS 14.4, *) {
            decorated(Table(items, selection: $selection, sortOrder: sortOrder) {
                fixedColumns
                TableColumnForEach(additionalColumns, id: \.self) { column in
                    TableColumn(SurveyTableColumn.additional(column).title,
                                sortUsing: SurveyColumnSort(column: .additional(column))) { item in
                        SurveyCell(row: item.row, column: .additional(column), numeric: isNumeric(column))
                    }
                }
            })
        } else {
            decorated(Table(items, selection: $selection, sortOrder: sortOrder) { fixedColumns })
        }
    }

    @TableColumnBuilder<Item, SurveyColumnSort>
    private var fixedColumns: some TableColumnContent<Item, SurveyColumnSort> {
        Group {
            column(.surveyDate)
            column(.cluster)
            column(.team)
            column(.displayID)
            column(.household)
            column(.sex)
            column(.dateOfBirth)
            column(.ageInDays)
            column(.ageInMonths)
            column(.weight)
        }
        Group {
            column(.oedema)
            column(.recumbent)
            column(.lengthOrHeight)
            column(.weightForAgeZ)
            column(.lengthOrHeightForAgeZ)
            column(.bmiForAgeZ)
            column(.flag)
            column(.weightingFactor)
            column(.estimatedDateOfBirth)
        }
    }

    private func decorated(_ table: some View) -> some View {
        table
            .contextMenu(forSelectionType: Int.self) { _ in
            } primaryAction: { indices in
                if indices.count == 1, let index = indices.first { onEdit(index) }
            }
            .onCopyCommand {
                [NSItemProvider(object: detail.clipboardText(selectedVisibleIndices: IndexSet(selection)) as NSString)]
            }
    }

    private var additionalColumns: [AdditionalDataColumn] {
        detail.columns.compactMap { if case .additional(let column) = $0 { column } else { nil } }
    }

    /// Número alinhado à direita, pelo tipo da variável na definição do inquérito.
    private func isNumeric(_ column: AdditionalDataColumn) -> Bool {
        if case .number = detail.additionalDataDefinition.variable(section: column.sectionID, variable: column.variableID)?.kind {
            return true
        }
        return false
    }

    private func column(_ fixed: SurveyColumn) -> TableColumn<Item, SurveyColumnSort, SurveyCell, Text> {
        let column = SurveyTableColumn.fixed(fixed)
        return TableColumn(column.title, sortUsing: SurveyColumnSort(column: column)) { item in
            SurveyCell(row: item.row, column: column, numeric: Self.isNumeric(fixed))
        }
    }

    private static func isNumeric(_ column: SurveyColumn) -> Bool {
        switch column {
        case .cluster, .team, .displayID, .household, .ageInDays, .ageInMonths, .weight, .lengthOrHeight, .weightForAgeZ,
             .lengthOrHeightForAgeZ, .bmiForAgeZ, .weightingFactor:
            true
        case .surveyDate, .sex, .dateOfBirth, .oedema, .recumbent, .flag, .estimatedDateOfBirth:
            false
        }
    }
}

struct SurveyCell: View {
    let row: SurveyRecordRow
    let column: SurveyTableColumn
    let numeric: Bool

    var body: some View {
        Text(row.text(column))
            .monospacedDigit()
            .foregroundStyle(row.isDerived(column) ? .secondary : .primary)
            .frame(maxWidth: .infinity, alignment: numeric ? .trailing : .leading)
            .padding(.horizontal, 2)
            .background(row.isHighlighted(column) ? Color.purple.opacity(0.35) : .clear,
                        in: RoundedRectangle(cornerRadius: 3))
    }
}
