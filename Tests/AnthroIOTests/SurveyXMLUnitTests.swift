import AnthroCore
import AnthroIO
import Foundation
import Testing

@Suite("survey-data-exchange: XML de inquéritos (unitários)")
struct SurveyXMLUnitTests {
    private typealias F = SurveyExchangeFixtures

    private func read(_ surveys: String) throws(ImportFailure) -> [ExchangeSurvey] {
        try SurveyXML.read(F.xml(surveys))
    }

    @Test func recordOutsideSurveyAndNestedSurveyAreInvalid() {
        expectInvalidStructure { () throws(ImportFailure) in _ = try read(F.recordXML()) }
        expectInvalidStructure { () throws(ImportFailure) in
            _ = try read("<Survey Name=\"a\">" + F.survey(records: []) + "</Survey>")
        }
    }

    @Test func unreadableAdditionalDataDefinitionOrValuesAreInvalid() {
        expectInvalidStructure { () throws(ImportFailure) in
            _ = try read("<Survey Name=\"a\" AdditionalDataDef=\"&lt;Data&gt;\" />")
        }
        expectInvalidStructure { () throws(ImportFailure) in
            _ = try read(F.survey(records: [F.recordXML(["AdditionalData": "&lt;Data&gt;"])]))
        }
    }

    @Test func absentOptionalsKeepDefaults() throws {
        let surveys = try read("<Survey Name=\"a\" />" + F.survey(records: [F.recordXML(["WeightingFactor": nil, "Notes": nil])]))
        #expect(surveys.first?.survey.options == .default)
        #expect(surveys.first?.records.isEmpty == true)
        #expect(surveys.last?.records.first?.weightingFactor == 1)
        #expect(surveys.last?.records.first?.notes == nil)
    }

    @Test func requiredRecordFieldsRejectTheFile() {
        for name in ["Sex", "DateOfBirthIsApprox", "IsRecumbent", "HasOedema"] {
            expectInvalidStructure { () throws(ImportFailure) in _ = try read(F.survey(records: [F.recordXML([name: nil])])) }
        }
        expectInvalidStructure { () throws(ImportFailure) in _ = try read(F.survey(records: [F.recordXML(["Weight": "0.5"])])) }
        expectInvalidStructure { () throws(ImportFailure) in _ = try read(F.survey(records: [F.recordXML(["DisplayID": "2147483648"])])) }
    }

    @Test func textsAreCutAtTheOriginalLimits() throws {
        let long = String(repeating: "a", count: 60)
        let surveys = try read(F.survey(name: long, records: [F.recordXML(["FirstName": long, "Notes": String(repeating: "n", count: 300)])]))
        #expect(surveys.first?.survey.name.count == 50)
        #expect(surveys.first?.records.first?.firstName?.count == 50)
        #expect(surveys.first?.records.first?.notes?.count == 250)
    }

    /// `HC` só vale quando aparece no primeiro registro do arquivo.
    @Test func whoAnthroFlagComesFromTheFirstRecordOfTheFile() throws {
        let surveys = try read(F.survey(records: [F.recordXML(["Age": "60"]), F.recordXML(["HC": "48", "Age": "60"])])
                               + F.survey(name: "b", records: [F.recordXML(["HC": "48", "Age": "60"])]))
        #expect(surveys.flatMap(\.records).map(\.ageInMonths) == [d("60"), d("60"), d("60")])
    }

    @Test func writerOmitsEmptyDefinitionAndWritesDefaultAdditionalData() throws {
        var record = F.record()
        record.additionalDataXML = nil
        let data = SurveyXML.data([ExchangeSurvey(survey: Survey(name: "a"), records: [record])], resultsEngine: nil)
        let text = String(decoding: data, as: UTF8.self)
        #expect(data.starts(with: [0xEF, 0xBB, 0xBF]))
        #expect(text.contains("\r\n"))
        #expect(!text.contains("AdditionalDataDef"))
        #expect(text.contains("AdditionalData=\"&lt;Data /&gt;\""))
        #expect(String(decoding: SurveyXML.data([], resultsEngine: nil), as: UTF8.self).hasSuffix("<Surveys />"))
    }

    @Test func controlCharactersInNotesDoNotBreakTheFile() throws {
        var record = F.record()
        record.notes = "a\u{0B}b\u{01}c"
        let reread = try SurveyXML.read(SurveyXML.data([ExchangeSurvey(survey: Survey(name: "a"), records: [record])], resultsEngine: nil))
        #expect(reread.first?.records.first?.notes == "a bc")
    }

    @Test func resultsUseTheSurveyEvaluation() throws {
        let engine = try AnthroEngine.shared()
        let record = F.record()
        let data = SurveyXML.data([ExchangeSurvey(survey: Survey(name: "a"), records: [record])], resultsEngine: engine)
        let doc = try XMLDocument(data: data)
        let bmi = try doc.nodes(forXPath: "//Record/@BMI").first?.stringValue
        #expect(bmi == SurveyRecordEvaluation.displayedBMI(record).map { "\($0)" })
        let waz = try doc.nodes(forXPath: "//Record/@WAZ").first?.stringValue
        #expect(waz == SurveyRecordEvaluation.result(record, engine: engine).score(.weightForAge).zScore.map { "\($0)" })
        #expect(waz?.isEmpty == false)
    }
}
