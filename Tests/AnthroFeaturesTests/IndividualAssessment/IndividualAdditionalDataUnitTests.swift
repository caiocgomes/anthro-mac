import AnthroCore
import AnthroFeatures
import AnthroStore
import Foundation
import Testing

@MainActor
@Suite("additional-data: modelo da avaliação individual (unitários)")
struct IndividualAdditionalDataUnitTests {
    @Test func committedTemplateInMemoryMatchesWhatWasStored() throws {
        let db = try IAFixtures.makeDatabase()
        let repository = AdditionalDataTemplateRepository(database: db)
        let model = try IndividualAdditionalDataModel(repository: repository)
        let editor = model.makeEditor()
        editor.addSection()
        editor.setIdentifier("Escola\u{0B}A")
        try model.commit(editor)
        #expect(model.template == (try repository.individualAssessmentTemplate()))
        #expect(model.dataForNewVisit().sections.last?.identifier == "Escola A")
    }
}
