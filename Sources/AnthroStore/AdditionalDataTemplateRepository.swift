import AnthroCore

/// Modelo de dados adicionais da avaliação individual gravado no banco (design D5).
public struct AdditionalDataTemplateRepository: Sendable {
    private let database: AnthroDatabase

    public init(database: AnthroDatabase) {
        self.database = database
    }

    public func individualAssessmentTemplate() throws -> AdditionalData {
        AdditionalData()
    }

    public func saveIndividualAssessmentTemplate(_ template: AdditionalData) throws {}
}
