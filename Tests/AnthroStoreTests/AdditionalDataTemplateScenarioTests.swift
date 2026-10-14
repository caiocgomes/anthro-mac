import AnthroCore
import AnthroStore
import Foundation
import Testing

/// Cenários do modelo de dados adicionais da avaliação individual no banco (change add-additional-data).
@Suite("additional-data: modelo da avaliação individual no banco")
struct AdditionalDataTemplateScenarioTests {
    // Scenario: Banco novo
    @Test func migrationFourSeedsIndividualTemplate() throws {
        let db = try AnthroDatabase.open(at: try temporaryDatabaseURL())
        defer { db.close() }
        #expect(try db.schemaVersion() >= 4)
        let template = try AdditionalDataTemplateRepository(database: db).individualAssessmentTemplate()
        #expect(template.sections.map(\.identifier) == ["Maturation", "Physical activity", "Food", "Health"])
    }

    // Scenario: Modelo editado persiste
    @Test func editedTemplateSurvivesReopen() throws {
        let url = try temporaryDatabaseURL()
        let db = try AnthroDatabase.open(at: url)
        let repository = AdditionalDataTemplateRepository(database: db)
        var template = try repository.individualAssessmentTemplate()
        template.sections.append(AdditionalDataSection(identifier: "Escola"))
        try repository.saveIndividualAssessmentTemplate(template)
        db.close()

        let reopened = try AnthroDatabase.open(at: url)
        defer { reopened.close() }
        let reread = try AdditionalDataTemplateRepository(database: reopened).individualAssessmentTemplate()
        #expect(reread.sections.count == 5)
        #expect(reread.sections.last?.identifier == "Escola")
    }
}
