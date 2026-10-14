import AnthroCore
import Foundation
import Testing

/// Laço interno de `SurveyOptions`: leitura das chaves do XML.
@Suite("SurveyOptions: leitura do XML")
struct SurveyOptionsUnitTests {
    @Test func booleansAreReadIgnoringCase() throws {
        let options = try SurveyOptions(xml: "<Opt><O ID=\"AutoIDCluster\">true</O><O ID=\"AutoIDRecord\">False</O></Opt>")
        #expect(options.autoIDCluster == true)
        #expect(options.autoIDRecord == false)
    }

    @Test func decimalListsAcceptCommaOrDot() throws {
        let options = try SurveyOptions(xml: "<Opt><O ID=\"StdMaxZBounds\">4,5|6|5</O><O ID=\"RefMaxZBounds\">4.5|6|5</O></Opt>")
        #expect(options.standardsMaxZ == [d("4.5"), 6, 5])
        #expect(options.referenceMaxZ == [d("4.5"), 6, 5])
    }

    @Test func missingKeyKeepsDefaultWhileOthersAreRead() throws {
        let options = try SurveyOptions(xml: "<Opt><O ID=\"AgeGroups\">0|61|228</O></Opt>")
        #expect(options.ageGroupBoundaries == [0, 61, 228])
        #expect(options.autoIDHousehold == true)
        #expect(options.standardsMinZ == [-6, -6, -5])
    }

    @Test func unreadableValueMakesXMLInvalid() {
        #expect(throws: SurveyOptionsError.self) { try SurveyOptions(xml: "<Opt><O ID=\"AutoIDTeam\">talvez</O></Opt>") }
        #expect(throws: SurveyOptionsError.self) { try SurveyOptions(xml: "<Opt><O ID=\"AgeGroups\">0|seis</O></Opt>") }
    }

    @Test func optionWithoutIDMakesXMLInvalid() {
        #expect(throws: SurveyOptionsError.self) { try SurveyOptions(xml: "<Opt><O>True</O></Opt>") }
    }

    @Test func zBoundsAreNilForShortListOrUnknownRange() {
        var options = literalSurveyOptions()
        options.referenceMaxZ = [5]
        #expect(options.zBounds(.lengthOrHeightForAge, range: .reference) == nil)
        #expect(options.zBounds(.weightForAge, range: .unknown) == nil)
        #expect(options.zBounds(.bmiForAge, range: .standards)?.max == 5)
    }
}
