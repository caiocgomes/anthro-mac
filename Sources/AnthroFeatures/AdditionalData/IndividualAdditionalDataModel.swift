import AnthroCore
import AnthroStore
import Observation

/// Modelo de dados adicionais da avaliação individual (`IAMain.miManageAddData_Click`, design D5 e D6): editado sobre
/// uma cópia e gravado na hora ao confirmar.
@MainActor
@Observable
public final class IndividualAdditionalDataModel {
    public private(set) var template: AdditionalData

    @ObservationIgnored private let repository: AdditionalDataTemplateRepository

    public init(repository: AdditionalDataTemplateRepository) throws {
        self.repository = repository
        template = try repository.individualAssessmentTemplate()
    }

    public func makeEditor() -> AdditionalDataEditorModel {
        AdditionalDataEditorModel(definition: template)
    }

    /// Aplica o editor e grava como `Settings.Save()`; com erro, o modelo não muda.
    public func commit(_ editor: AdditionalDataEditorModel) throws {
        let applied = try editor.apply()
        try repository.saveIndividualAssessmentTemplate(applied)
        template = applied
    }

    /// `IAVisitDialog`: visita nova recebe uma cópia do modelo vigente.
    public func dataForNewVisit() -> AdditionalData {
        template
    }
}
