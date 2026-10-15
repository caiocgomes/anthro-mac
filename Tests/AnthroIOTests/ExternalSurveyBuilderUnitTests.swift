import AnthroCore
import AnthroIO
import Foundation
import Testing

@Suite("survey-data-exchange: montagem do inquérito importado (unitários)")
struct ExternalSurveyBuilderUnitTests {
    private typealias F = SurveyExchangeFixtures

    @Test func measureMappedButInvalidWarnsAndIsDerived() throws {
        let result = try ExternalSurveyBuilder.build(table: F.table(["Sex", "Measure", "Age"], [["1", "x", "12"], ["1", "L", "60"]]),
                                                     mapping: [.sex: "Sex", .isRecumbent: "Measure", .ageInMonths: "Age"], name: "a")
        #expect(result.draft.records.map(\.measuredRecumbent) == [true, true])
        #expect(result.hadFieldWarnings)
    }

    @Test func identifiersOedemaAndInvalidIntegersFollowTheOriginal() throws {
        let result = try ExternalSurveyBuilder.build(
            table: F.table(["Sex", "ID", "HH", "Cluster", "Edema"], [["F", "12", "3", "x", "1"]]),
            mapping: [.sex: "Sex", .displayID: "ID", .household: "HH", .cluster: "Cluster", .hasOedema: "Edema"], name: "a")
        let record = try #require(result.draft.records.first)
        #expect(record.displayID == 12)
        #expect(record.household == 3)
        #expect(record.cluster == nil)
        #expect(record.hasOedema == true)
        #expect(record.weightingFactor == 1)
        #expect(result.hadFieldWarnings)
        #expect(result.draft.survey.options == .default)
        #expect(result.draft.survey.id == nil)
    }

    @Test func emptyExtraValuesAreNilAndSectionHasTheTranslatedDescription() throws {
        let result = try ExternalSurveyBuilder.build(table: F.table(["Sex", "obs"], [["1", ""]]), mapping: [.sex: "Sex"], name: "a")
        let definition = try AdditionalDataXML.decode(result.draft.survey.additionalDataDefinitionXML)
        #expect(definition.sections.first?.description == "Dados importados de arquivo externo.")
        #expect(ExternalSurveyBuilder.importedSectionID == "Imported")
        let values = try AdditionalDataXML.decode(result.draft.records.first?.additionalDataXML)
        #expect(values.variable(section: "Imported", variable: "obs")?.kind == .text(nil))
    }

    @Test func weightingFactorIsNotTruncatedAndAgeKeepsAllPlaces() throws {
        let result = try ExternalSurveyBuilder.build(table: F.table(["Sex", "W", "Age"], [["1", "1.23456", "30.123456"]]),
                                                     mapping: [.sex: "Sex", .weightingFactor: "W", .ageInMonths: "Age"], name: "a")
        #expect(result.draft.records.first?.weightingFactor == d("1.23456"))
        #expect(result.draft.records.first?.ageInMonths == d("30.123456"))
    }

    /// `int.Parse` do original estoura acima de 2147483647: o valor fica ausente com aviso, como na change 7.
    @Test func integersAboveInt32BecomeAbsentWithWarning() throws {
        let result = try ExternalSurveyBuilder.build(table: F.table(["Sex", "ID", "Team"], [["1", "2147483648", "2147483647"]]),
                                                     mapping: [.sex: "Sex", .displayID: "ID", .team: "Team"], name: "a")
        #expect(result.draft.records.first?.displayID == nil)
        #expect(result.draft.records.first?.team == 2147483647)
        #expect(result.hadFieldWarnings)
    }
}
