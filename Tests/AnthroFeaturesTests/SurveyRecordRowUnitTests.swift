import AnthroFeatures
import Foundation
import Testing

/// Laço interno de `SurveyRecordRow`: formatos de célula.
@Suite("SurveyRecordRow: formatos")
struct SurveyRecordRowUnitTests {
    let engine: AnthroEngine

    init() throws {
        engine = try AnthroEngine.shared()
    }

    private func cell(_ record: SurveyRecord, _ column: SurveyColumn) -> String {
        SurveyRecordRow(record: record, engine: engine, options: SurveyFixtures.literalOptions()).text(.fixed(column))
    }

    @Test func birthDateKeepsDayOrMasksItWhenApproximate() {
        #expect(cell(SurveyFixtures.record(birth: "2016-03-05"), .dateOfBirth) == "05/03/2016")
        #expect(cell(SurveyFixtures.record(birth: "2016-03-05", approx: true), .dateOfBirth) == "XX/03/2016")
        #expect(cell(SurveyFixtures.record(birth: "2016-03-05", approx: true), .estimatedDateOfBirth) == "Sim")
        #expect(cell(SurveyFixtures.record(birth: "2016-03-05"), .estimatedDateOfBirth) == "Não")
    }

    @Test func weightingFactorShowsItsOwnDecimalPlacesWithComma() {
        #expect(cell(SurveyFixtures.record(weightingFactor: "0.125"), .weightingFactor) == "0,125")
        #expect(cell(SurveyFixtures.record(weightingFactor: "2"), .weightingFactor) == "2")
        #expect(cell(SurveyFixtures.record(weightingFactor: "0.1234567890123456"), .weightingFactor) == "0,1234567890123456")
    }

    @Test func sexIDsAndBooleansUseOriginalTexts() {
        var record = SurveyFixtures.record(sex: .boy, cluster: 3, displayID: 12, household: 0, oedema: true)
        record.team = 7
        record.measuredRecumbent = true
        #expect(cell(record, .sex) == "Masculino")
        #expect([SurveyColumn.cluster, .team, .displayID, .household].map { cell(record, $0) } == ["3", "7", "12", "0"])
        #expect(cell(record, .oedema) == "Sim")
        #expect(cell(record, .recumbent) == "Sim")
    }

    @Test func bothWeightAndHeightFlagsShowHeightFirst() {
        // Sem peso e com estatura 200 cm aos 72 meses: P/I indefinido e E/I acima de 6.
        let record = SurveyFixtures.record(sex: .boy, months: "72", height: "200")
        #expect(cell(record, .flag) == "E/I, P/I")
        #expect(cell(SurveyFixtures.record(sex: .boy, months: "72", weight: "20", height: "115"), .flag) == "")
    }

    @Test func typedAgeOf24MonthsShowsRoundedDays() {
        #expect(cell(SurveyFixtures.record(months: "24"), .ageInDays) == "731")
        #expect(cell(SurveyFixtures.record(months: "0.5"), .ageInDays) == "15")
    }
}
