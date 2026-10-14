import AnthroCore

/// Modelo de dados adicionais da avaliação individual gravado no banco (design D5).
public struct AdditionalDataTemplateRepository: Sendable {
    static let individualAssessmentScope = "individualAssessment"

    private let database: AnthroDatabase

    public init(database: AnthroDatabase) {
        self.database = database
    }

    /// O modelo gravado; sem linha (banco que perdeu a semente), o padrão do original.
    public func individualAssessmentTemplate() throws -> AdditionalData {
        let rows = try database.query("SELECT xml FROM additional_data_templates WHERE scope = ?",
                                      [.text(Self.individualAssessmentScope)])
        guard let row = rows.first, case .text(let xml) = row["xml"] else {
            return try AdditionalDataXML.decode(AdditionalDataTemplates.individualAssessmentDefaultXML)
        }
        return try AdditionalDataXML.decode(xml)
    }

    /// Grava na hora, como `Settings.Save()` em `miManageAddData_Click`.
    public func saveIndividualAssessmentTemplate(_ template: AdditionalData) throws {
        try database.execute(
            "INSERT INTO additional_data_templates(scope, xml) VALUES (?, ?) ON CONFLICT(scope) DO UPDATE SET xml = excluded.xml",
            [.text(Self.individualAssessmentScope), .text(AdditionalDataXML.encode(template))])
    }
}
