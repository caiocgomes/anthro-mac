import AnthroCore
import Foundation
import Testing

/// Cenários de opções do inquérito e faixas etárias (change add-nutritional-survey).
@Suite("survey-management: opções do inquérito e faixas etárias")
struct SurveyOptionsScenarioTests {
    // Scenario: Opções de um inquérito novo
    @Test func newSurveyHasLiteralDefaultOptions() {
        let options = Survey(name: "Escola A").options
        #expect(options.ageGroupBoundaries.count == 22)
        #expect(options.referenceMinZ.dropFirst(2).first == -5)
        expectLiteralDefaultOptions(options)
        #expect(options == SurveyOptions.default)
    }

    // Scenario: XML sem chaves
    @Test func emptyOptionsXMLYieldsDefaults() throws {
        let options = try SurveyOptions(xml: "<Opt />")
        #expect(options.autoIDRecord == true)
        #expect(options.ageGroupBoundaries.count == 22)
        expectLiteralDefaultOptions(options)
    }

    // Scenario: Gravação das opções padrão
    @Test func defaultOptionsSerializeToExactXML() {
        let expected = "<Opt><O ID=\"AutoIDCluster\">False</O><O ID=\"AutoIDTeam\">False</O>"
            + "<O ID=\"AutoIDRecord\">True</O><O ID=\"AutoIDHousehold\">True</O>"
            + "<O ID=\"AgeGroups\">0|6|12|24|36|48|61|72|84|96|108|120|132|144|156|168|180|192|204|216|228|228</O>"
            + "<O ID=\"StdMinZBounds\">-6|-6|-5</O><O ID=\"StdMaxZBounds\">5|6|5</O>"
            + "<O ID=\"RefMinZBounds\">-6|-6|-5</O><O ID=\"RefMaxZBounds\">5|6|5</O></Opt>"
        #expect(SurveyOptions.default.xml() == expected)
    }

    // Scenario: XML malformado
    @Test func malformedOptionsXMLThrows() {
        #expect(throws: SurveyOptionsError.self) { try SurveyOptions(xml: "<Opt><O>") }
    }

    // Scenario: Limite legado preservado sem conversão
    @Test func legacyMinZBoundsKeepOriginalValues() throws {
        let options = try SurveyOptions(xml: "<Opt><O ID=\"MinZBounds\">-5|-6|-6|-5</O></Opt>")
        let weight = try #require(options.zBounds(.weightForAge, range: .standards))
        let height = try #require(options.zBounds(.lengthOrHeightForAge, range: .standards))
        #expect(weight.min == -5)
        #expect(height.min == -6)
        #expect(options.standardsMinZ == [-5, -6, -6, -5])
    }

    // Scenario: Chave legada e nova juntas
    @Test func legacyAndNewKeyTogetherThrow() {
        #expect(throws: SurveyOptionsError.self) {
            try SurveyOptions(xml: "<Opt><O ID=\"MinZBounds\">-5|-6|-6|-5</O><O ID=\"StdMinZBounds\">-6|-6|-5</O></Opt>")
        }
    }

    // Scenario: Faixas padrão
    @Test func defaultBoundariesYieldTwentyOneGroups() {
        let groups = AgeGroups.groups(fromBoundaries: literalAgeBoundaries)
        #expect(groups.count == 21)
        #expect(groups.first == AgeGroup(lowerMonths: 0, upperMonths: 5))
        #expect(groups.dropFirst(5).first == AgeGroup(lowerMonths: 48, upperMonths: 60))
        #expect(groups.dropFirst(6).first == AgeGroup(lowerMonths: 61, upperMonths: 71))
        #expect(groups.last == AgeGroup(lowerMonths: 228, upperMonths: 228))
    }

    // Scenario: Fronteiras mínimas
    @Test func threeBoundariesYieldTwoGroups() {
        #expect(AgeGroups.groups(fromBoundaries: [0, 61, 228])
            == [AgeGroup(lowerMonths: 0, upperMonths: 60), AgeGroup(lowerMonths: 61, upperMonths: 228)])
    }
}
