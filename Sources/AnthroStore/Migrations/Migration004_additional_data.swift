import AnthroCore

extension Migrations {
    /// Versão 4: modelo de dados adicionais da avaliação individual (design D5 da add-additional-data). O original o
    /// guarda nas configurações do usuário; no banco ele entra nos backups automáticos.
    public static let additionalData = Migration(
        version: 4,
        name: "additional_data",
        sql: """
        CREATE TABLE additional_data_templates(
            scope TEXT PRIMARY KEY,
            xml TEXT NOT NULL
        );
        INSERT OR IGNORE INTO additional_data_templates(scope, xml)
        VALUES ('individualAssessment', '\(AdditionalDataTemplates.individualAssessmentDefaultXML
            .replacingOccurrences(of: "'", with: "''"))');
        """
    )
}
