import AnthroCore
import AnthroStore
import Foundation
import Testing

@Suite("additional-data: repositório do modelo (unitários)")
struct AdditionalDataTemplateUnitTests {
    @Test func missingRowFallsBackToOriginalDefault() throws {
        let db = try AnthroDatabase.open(at: try temporaryDatabaseURL())
        defer { db.close() }
        try db.execute("DELETE FROM additional_data_templates")
        let template = try AdditionalDataTemplateRepository(database: db).individualAssessmentTemplate()
        #expect(AdditionalDataXML.encode(template) == iaTemplateXML)
    }

    @Test func savingTwiceKeepsOneRowWithTheLastTemplate() throws {
        let db = try AnthroDatabase.open(at: try temporaryDatabaseURL())
        defer { db.close() }
        let repository = AdditionalDataTemplateRepository(database: db)
        try repository.saveIndividualAssessmentTemplate(AdditionalData(sections: [AdditionalDataSection(identifier: "A")]))
        try repository.saveIndividualAssessmentTemplate(AdditionalData(sections: [AdditionalDataSection(identifier: "B")]))
        let rows = try db.query("SELECT scope, xml FROM additional_data_templates")
        #expect(rows.count == 1)
        #expect(rows.first?["xml"] == .text(#"<Data><Cat ID="B" Descr="" /></Data>"#))
    }
}
