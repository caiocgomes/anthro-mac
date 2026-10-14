import AnthroCore
import AnthroStore
import Foundation
import Observation

/// Inquérito aberto em memória, gravado numa transação ao salvar (`NSMain` e `BaseDataList`, design D2): registros em
/// ordem de inclusão, lista visível filtrada e ordenada, e alterações pendentes até `save()`.
@MainActor
@Observable
public final class SurveyDetailModel {
    public var name: String {
        didSet { if name != oldValue { hasUnsavedChanges = true } }
    }
    public var notes: String {
        didSet { if notes != oldValue { hasUnsavedChanges = true } }
    }
    public private(set) var survey: Survey
    public private(set) var options: SurveyOptions
    public private(set) var allRecords: [SurveyRecord] = []
    public private(set) var visibleRows: [SurveyRecordRow] = []
    public private(set) var hasUnsavedChanges: Bool = false
    public private(set) var isFiltered: Bool = false
    public private(set) var sortColumn: SurveyTableColumn? = nil
    public private(set) var sortAscending: Bool = false
    public private(set) var selectedResult: AnthropometricResult? = nil
    /// Definição de dados adicionais em edição; a coluna `additional_data_def` só muda ao salvar.
    public private(set) var additionalDataDefinition = AdditionalData()
    private var definitionXML: String?
    private var additionalColumns: [AdditionalDataColumn] = []

    /// Registro com chave estável em memória (registros novos ainda não têm `id`).
    private struct Entry {
        let key: Int
        var row: SurveyRecordRow
    }

    @ObservationIgnored private var entries: [Entry] = []
    @ObservationIgnored private var visibleKeys: [Int] = []
    @ObservationIgnored private var selectedKey: Int?
    @ObservationIgnored private var nextKey = 0
    /// Editores abertos sobre registros existentes; o editor fica retido até `commit` para que a chave não se confunda.
    @ObservationIgnored private var editorKeys: [ObjectIdentifier: (editor: RecordEditorModel, key: Int)] = [:]

    @ObservationIgnored private let repository: SurveyRepository
    @ObservationIgnored private let engine: AnthroEngine
    @ObservationIgnored private let today: () -> Date

    public init(survey: Survey, records: [SurveyRecord], repository: SurveyRepository, engine: AnthroEngine,
                today: @escaping () -> Date) {
        self.survey = survey
        name = survey.name
        notes = survey.notes ?? ""
        options = survey.options
        self.repository = repository
        self.engine = engine
        self.today = today
        setDefinition(survey.additionalDataDefinitionXML)
        load(records)
    }

    /// As 19 colunas fixas e uma por variável da definição (`BindRecordsToGrid` com `GetDataStructure`).
    public var columns: [SurveyTableColumn] {
        SurveyColumn.allCases.map { .fixed($0) } + additionalColumns.map { .additional($0) }
    }

    /// `NSMain_LabelNbRecords` sobre os registros visíveis.
    public var recordCountLabel: String {
        "\(visibleRows.count) \(L10n.Survey.recordCountSuffix)"
    }

    // MARK: Seleção

    /// `dgvRecords_RowEnter`: o painel de resultados mostra o registro selecionado; `nil` limpa.
    public func select(visibleIndex: Int?) {
        selectedKey = visibleIndex.flatMap { visibleKeys.indices.contains($0) ? visibleKeys[$0] : nil }
        refreshSelection()
    }

    /// Faixa de cor do z do registro selecionado (`IndicatorDisplayPanel`).
    public func severity(_ indicator: Indicator) -> Severity {
        SeverityClassifier.severity(selectedResult?.score(indicator).zScore)
    }

    // MARK: Registros

    public func makeNewRecordEditor() -> RecordEditorModel {
        RecordEditorModel(record: nil, survey: currentSurvey, existingRecords: allRecords, engine: engine, today: today())
    }

    public func makeEditor(visibleIndex: Int) -> RecordEditorModel {
        let key = visibleKeys[visibleIndex]
        let editor = RecordEditorModel(record: entry(key)?.row.record, survey: currentSurvey, existingRecords: allRecords,
                                       engine: engine, today: today())
        editorKeys[ObjectIdentifier(editor)] = (editor, key)
        return editor
    }

    /// Inclui (no fim da ordem de inclusão e da lista visível, como `Records.Add`) ou atualiza o registro do editor.
    public func commit(_ editor: RecordEditorModel) throws {
        let record = try editor.makeRecord()
        let row = SurveyRecordRow(record: record, engine: engine, options: options)
        if let key = editorKeys.removeValue(forKey: ObjectIdentifier(editor))?.key,
           let index = entries.firstIndex(where: { $0.key == key }) {
            entries[index].row = row
        } else {
            let key = takeKey()
            entries.append(Entry(key: key, row: row))
            visibleKeys.append(key)
        }
        hasUnsavedChanges = true
        publish()
    }

    public func deleteRecords(visibleIndices: IndexSet) {
        let removed = Set(visibleIndices.compactMap { visibleKeys.indices.contains($0) ? visibleKeys[$0] : nil })
        guard !removed.isEmpty else { return }
        entries.removeAll { removed.contains($0.key) }
        visibleKeys.removeAll { removed.contains($0) }
        if let selectedKey, removed.contains(selectedKey) { self.selectedKey = nil }
        hasUnsavedChanges = true
        publish()
    }

    // MARK: Ordenação

    /// `dgvRecords_ColumnHeaderMouseClick`: coluna nova ordena crescente (estável); a mesma coluna inverte a lista.
    public func sort(by column: SurveyTableColumn) {
        if column == sortColumn {
            sortAscending.toggle()
            visibleKeys.reverse()
        } else {
            sortColumn = column
            sortAscending = true
            let keyed = visibleKeys.enumerated().map { offset, key in
                (offset: offset, key: key, value: SurveySortKey(entry(key)!.row, column))
            }
            visibleKeys = keyed.sorted { ($0.value, $0.offset) < ($1.value, $1.offset) }.map(\.key)
        }
        publish()
    }

    // MARK: Filtro

    /// `FilterRecords` sobre a lista visível: cada filtro estreita o que já está visível (`BaseDataList.FilterAt`).
    public func applyFilter(_ filter: SurveyFilter) {
        visibleKeys = visibleKeys.filter { key in
            SurveyFilterEvaluator.keeps(cellText: entry(key)!.row.text(filter.column), condition: filter.condition,
                                        value1: filter.value1, value2: filter.value2)
        }
        isFiltered = true
        if let selectedKey, !visibleKeys.contains(selectedKey) { self.selectedKey = nil }
        publish()
    }

    /// `tsbFilterBack_Click` com `UnfilterAll`: todos visíveis na ordem de inclusão, sem indicador de ordenação.
    public func clearFilter() {
        guard isFiltered else { return }
        visibleKeys = entries.map(\.key)
        isFiltered = false
        sortColumn = nil
        sortAscending = false
        publish()
    }

    // MARK: Cópia

    /// `tsbCopyToClipboard_Click`: títulos e linhas selecionadas na ordem da tabela, cada célula seguida de tabulação e
    /// cada linha terminada em CRLF.
    public func clipboardText(selectedVisibleIndices: IndexSet) -> String {
        let columns = columns
        var text = columns.map { $0.title + "\t" }.joined() + "\r\n"
        for index in selectedVisibleIndices where visibleRows.indices.contains(index) {
            let row = visibleRows[index]
            text += columns.map { row.text($0) + "\t" }.joined() + "\r\n"
        }
        return text
    }

    // MARK: Opções

    /// Editor sobre uma cópia das opções correntes: cancelar é simplesmente não aplicar.
    public func makeOptionsEditor() -> SurveyOptionsEditorModel {
        SurveyOptionsEditorModel(options: options)
    }

    /// Opções aplicadas marcam pendência e recalculam as flags de todas as linhas.
    public func applyOptions(_ editor: SurveyOptionsEditorModel) throws {
        options = try editor.apply()
        for index in entries.indices {
            entries[index].row = SurveyRecordRow(record: entries[index].row.record, engine: engine, options: options)
        }
        hasUnsavedChanges = true
        publish()
    }

    // MARK: Dados adicionais

    /// `tsbAddData_Click`: editor sobre uma cópia da definição; cancelar é não aplicar.
    public func makeAdditionalDataDefinitionEditor() -> AdditionalDataEditorModel {
        AdditionalDataEditorModel(definition: additionalDataDefinition)
    }

    /// Definição aplicada marca pendência e refaz as colunas (`SetModified` e `BindRecordsToGrid`); os registros
    /// existentes guardam os seus próprios dados (D6).
    public func applyAdditionalDataDefinition(_ editor: AdditionalDataEditorModel) throws {
        let applied = try editor.apply()
        setDefinition(AdditionalDataXML.encode(applied))
        if let sortColumn, !columns.contains(sortColumn) {
            self.sortColumn = nil
            sortAscending = false
        }
        hasUnsavedChanges = true
        publish()
    }

    // MARK: Salvar e descartar

    /// Grava inquérito e registros numa transação (`ApplyDataChanges`); a ordem de inclusão vira `position`.
    public func save() throws {
        let saved = try repository.save(currentSurvey, records: entries.map(\.row.record))
        survey = saved.survey
        setDefinition(saved.survey.additionalDataDefinitionXML)
        name = saved.survey.name
        notes = saved.survey.notes ?? ""
        for (index, record) in saved.records.enumerated() {
            entries[index].row = SurveyRecordRow(record: record, engine: engine, options: options)
        }
        hasUnsavedChanges = false
        publish()
    }

    /// `Survey.DiscardDataChanges`: relê o inquérito salvo; inquérito nunca salvo volta a vazio.
    public func discardChanges() throws {
        if let id = survey.id {
            survey = try repository.survey(id: id)
            load(try repository.records(surveyID: id))
        } else {
            load([])
        }
        name = survey.name
        notes = survey.notes ?? ""
        options = survey.options
        setDefinition(survey.additionalDataDefinitionXML)
        rebuildRows()
        hasUnsavedChanges = false
    }

    // MARK: Privado

    /// Inquérito com nome, notas e opções em edição.
    private var currentSurvey: Survey {
        var current = survey
        current.name = name
        current.notes = notes
        current.options = options
        current.additionalDataDefinitionXML = definitionXML
        return current
    }

    /// Guarda o texto da definição e as colunas derivadas; definição ilegível não gera colunas.
    private func setDefinition(_ xml: String?) {
        definitionXML = xml
        additionalDataDefinition = (try? AdditionalDataXML.decode(xml)) ?? AdditionalData()
        additionalColumns = AdditionalDataColumns.structure(of: additionalDataDefinition,
                                                            forbiddenKeys: SurveyColumn.allCases.map(\.title))
    }

    private func load(_ records: [SurveyRecord]) {
        entries = records.map { Entry(key: takeKey(), row: SurveyRecordRow(record: $0, engine: engine, options: options)) }
        visibleKeys = entries.map(\.key)
        editorKeys = [:]
        selectedKey = nil
        isFiltered = false
        sortColumn = nil
        sortAscending = false
        publish()
    }

    private func rebuildRows() {
        for index in entries.indices {
            entries[index].row = SurveyRecordRow(record: entries[index].row.record, engine: engine, options: options)
        }
        publish()
    }

    private func takeKey() -> Int {
        defer { nextKey += 1 }
        return nextKey
    }

    private func entry(_ key: Int) -> Entry? {
        entries.first { $0.key == key }
    }

    /// Atualiza as propriedades observadas a partir das entradas e da ordem visível.
    private func publish() {
        let rows = Dictionary(uniqueKeysWithValues: entries.map { ($0.key, $0.row) })
        allRecords = entries.map(\.row.record)
        visibleRows = visibleKeys.compactMap { rows[$0] }
        refreshSelection()
    }

    private func refreshSelection() {
        selectedResult = selectedKey.flatMap { key in entries.first { $0.key == key }?.row.result }
    }
}

/// Valor tipado de ordenação de uma célula (`Record.CompareTo` com `SortBy`): valores antes de ausentes (`CompareNull`),
/// mas z indefinido entra como o menor valor, porque o original guarda `decimal.MinValue` no campo.
private enum SurveySortKey: Comparable {
    case value(Decimal)
    case date(Date)
    case text(String)
    case missing

    /// Números, depois datas, depois textos, ausentes no fim; texto pela comparação localizada (`string.CompareTo`).
    static func < (lhs: SurveySortKey, rhs: SurveySortKey) -> Bool {
        switch (lhs, rhs) {
        case let (.value(a), .value(b)): a < b
        case let (.date(a), .date(b)): a < b
        case let (.text(a), .text(b)): a.localizedCompare(b) == .orderedAscending
        default: lhs.rank < rhs.rank
        }
    }

    static func == (lhs: SurveySortKey, rhs: SurveySortKey) -> Bool {
        switch (lhs, rhs) {
        case let (.value(a), .value(b)): a == b
        case let (.date(a), .date(b)): a == b
        case let (.text(a), .text(b)): a.localizedCompare(b) == .orderedSame
        case (.missing, .missing): true
        default: false
        }
    }

    private var rank: Int {
        switch self {
        case .value: 0
        case .date: 1
        case .text: 2
        case .missing: 3
        }
    }

    init(_ row: SurveyRecordRow, _ column: SurveyTableColumn) {
        let record = row.record
        func number(_ value: Int?) -> SurveySortKey { value.map { .value(Decimal($0)) } ?? .missing }
        func number(_ value: Decimal?) -> SurveySortKey { value.map { .value($0) } ?? .missing }
        func date(_ value: Date?) -> SurveySortKey { value.map { .value(Decimal($0.timeIntervalSinceReferenceDate)) } ?? .missing }
        func flag(_ value: Bool?) -> SurveySortKey { value.map { .value($0 ? 1 : 0) } ?? .missing }
        func z(_ indicator: Indicator) -> SurveySortKey { .value(row.result.score(indicator).zScore ?? -Decimal.greatestFiniteMagnitude) }
        switch column {
        case .fixed(let fixed):
            switch fixed {
            case .surveyDate: self = date(record.visitDate)
            case .cluster: self = number(record.cluster)
            case .team: self = number(record.team)
            case .displayID: self = number(record.displayID)
            case .household: self = number(record.household)
            case .sex: self = .value(Decimal(record.sex.rawValue))
            case .dateOfBirth: self = date(record.dateOfBirth)
            case .ageInDays, .ageInMonths: self = number(SurveyRecordEvaluation.ageInMonths(record))
            case .weight: self = number(record.weight)
            case .oedema: self = flag(record.hasOedema)
            case .recumbent: self = flag(record.measuredRecumbent)
            case .lengthOrHeight: self = number(record.lengthOrHeight)
            case .weightForAgeZ: self = z(.weightForAge)
            case .lengthOrHeightForAgeZ: self = z(.lengthOrHeightForAge)
            case .bmiForAgeZ: self = z(.bmiForAge)
            case .flag: self = .value(Decimal(Self.rank(row.flag)))
            case .weightingFactor: self = .value(record.weightingFactor)
            case .estimatedDateOfBirth: self = flag(record.dateOfBirthIsApprox)
            }
        case .additional(let column):
            switch row.additionalVariable(column)?.kind {
            case .text(let value?): self = .text(value)
            case .number(let value?, _, _): self = .value(value)
            case .date(let value?): self = .date(value)
            default: self = .missing
            }
        }
    }

    /// Ordem do enum `Flag` do original.
    private static func rank(_ flag: PlausibilityFlag) -> Int {
        switch flag {
        case .none: 0
        case .weightForAge: 1
        case .lengthOrHeightForAge: 2
        case .weightAndLengthOrHeightForAge: 3
        case .bmiForAge: 4
        }
    }
}
