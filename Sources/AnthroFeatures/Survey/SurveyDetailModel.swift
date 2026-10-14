import AnthroCore
import AnthroStore
import Foundation
import Observation

/// Inquérito aberto em memória, gravado numa transação ao salvar (`NSMain` e `BaseDataList`, design D2).
@MainActor
@Observable
public final class SurveyDetailModel {
    public var name: String = ""
    public var notes: String = ""
    public private(set) var survey: Survey
    public private(set) var options: SurveyOptions
    public private(set) var allRecords: [SurveyRecord] = []
    public private(set) var visibleRows: [SurveyRecordRow] = []
    public private(set) var hasUnsavedChanges: Bool = false
    public private(set) var isFiltered: Bool = false
    public private(set) var sortColumn: SurveyTableColumn? = nil
    public private(set) var sortAscending: Bool = false
    public private(set) var selectedResult: AnthropometricResult? = nil

    @ObservationIgnored private let repository: SurveyRepository
    @ObservationIgnored private let engine: AnthroEngine
    @ObservationIgnored private let today: () -> Date

    public init(survey: Survey, records: [SurveyRecord], repository: SurveyRepository, engine: AnthroEngine,
                today: @escaping () -> Date) {
        self.survey = survey
        options = .default
        self.repository = repository
        self.engine = engine
        self.today = today
    }

    public var columns: [SurveyTableColumn] { [] }

    public var recordCountLabel: String { "" }

    public func select(visibleIndex: Int?) {}

    public func severity(_ indicator: Indicator) -> Severity { .undefined }

    public func makeNewRecordEditor() -> RecordEditorModel {
        RecordEditorModel(record: nil, survey: survey, existingRecords: [], engine: engine, today: today())
    }

    public func makeEditor(visibleIndex: Int) -> RecordEditorModel {
        RecordEditorModel(record: nil, survey: survey, existingRecords: [], engine: engine, today: today())
    }

    public func commit(_ editor: RecordEditorModel) throws {}

    public func deleteRecords(visibleIndices: IndexSet) {}

    public func sort(by column: SurveyTableColumn) {}

    public func applyFilter(_ filter: SurveyFilter) {}

    public func clearFilter() {}

    public func clipboardText(selectedVisibleIndices: IndexSet) -> String { "" }

    public func makeOptionsEditor() -> SurveyOptionsEditorModel {
        SurveyOptionsEditorModel(options: options)
    }

    public func applyOptions(_ editor: SurveyOptionsEditorModel) throws {}

    public func save() throws {}

    public func discardChanges() throws {}
}
