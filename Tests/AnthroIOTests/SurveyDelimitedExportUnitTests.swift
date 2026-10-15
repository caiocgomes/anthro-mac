import AnthroCore
import AnthroIO
import Foundation
import Testing

@Suite("survey-data-exchange: exportação delimitada do inquérito (unitários)")
struct SurveyDelimitedExportUnitTests {
    private typealias F = SurveyExchangeFixtures

    @Test func valuesUseCommaDecimalsAndTheAdditionalValueText() throws {
        let definition = #"<Data><Cat ID="S" Descr=""><Num ID="horas" Descr="" Min="" Max=""></Num><Txt ID="Weight" Descr=""></Txt></Cat></Data>"#
        var record = F.record(weightingFactor: "1.5")
        record.additionalDataXML = #"<Data><Cat ID="S" Descr=""><Num ID="horas" Descr="" Min="" Max="">2.50</Num><Txt ID="Weight" Descr="">x</Txt></Cat></Data>"#
        let survey = ExchangeSurvey(survey: Survey(name: "A", additionalDataDefinitionXML: definition), records: [record])
        let lines = F.lines(SurveyDelimitedExport.data(survey, resultsEngine: nil, format: .semicolonCSV))
        let header = lines[0].components(separatedBy: ";")
        let row = lines[1].components(separatedBy: ";")
        #expect(header.count == 20)
        #expect(header.last != "Weight")
        #expect(row[5] == "1,5")
        #expect(row[12] == "18,4")
        #expect(row[18] == "2,5")
        #expect(row[19] == "x")
    }

    @Test func resultsAreWrittenWithCommaInTabText() throws {
        let engine = try AnthroEngine.shared()
        let record = F.record()
        let lines = F.lines(SurveyDelimitedExport.data(ExchangeSurvey(survey: Survey(name: "A"), records: [record]),
                                                       resultsEngine: engine, format: .tabText))
        let row = lines[1].components(separatedBy: "\t")
        let bmi = try #require(SurveyRecordEvaluation.displayedBMI(record))
        #expect(row[21] == "\(bmi)".replacingOccurrences(of: ".", with: ","))
        #expect(row[18].contains(","))
    }

    @Test func surveyWithoutRecordsWritesOnlyTheHeader() {
        let lines = F.lines(SurveyDelimitedExport.data(ExchangeSurvey(survey: Survey(name: "A"), records: []), resultsEngine: nil,
                                                       format: .tabText))
        #expect(lines.count == 1)
    }
}
