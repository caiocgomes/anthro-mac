import AnthroCore
import AnthroStore
import Observation

/// Modelo de dados adicionais da avaliação individual (`IAMain.miManageAddData_Click`, design D5 e D6).
@MainActor
@Observable
public final class IndividualAdditionalDataModel {
    public private(set) var template: AdditionalData

    public init(repository: AdditionalDataTemplateRepository) throws {
        template = AdditionalData()
    }

    public func makeEditor() -> AdditionalDataEditorModel {
        AdditionalDataEditorModel(definition: template)
    }

    public func commit(_ editor: AdditionalDataEditorModel) throws {}

    public func dataForNewVisit() -> AdditionalData {
        AdditionalData()
    }
}
