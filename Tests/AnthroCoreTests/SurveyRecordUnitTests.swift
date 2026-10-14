import AnthroCore
import Foundation
import Testing

/// Laço interno de `SurveyRecord` e `SurveyRecordEvaluation`.
@Suite("SurveyRecord: nome exibido, idade e IMC")
struct SurveyRecordUnitTests {
    let engine: AnthroEngine

    init() throws {
        engine = try AnthroEngine.shared()
    }

    private func record(first: String? = nil, last: String? = nil) -> SurveyRecord {
        var record = SurveyRecord()
        record.firstName = first
        record.lastName = last
        return record
    }

    @Test func displayNameJoinsLastAndFirstLikeTheOriginal() {
        #expect(record(first: "Ana", last: "Silva").displayName == "Silva, Ana")
        #expect(record(first: "Ana").displayName == "Ana")
        #expect(record(last: "Silva").displayName == "Silva, ")
        #expect(record().displayName == "")
    }

    @Test func birthAfterVisitBecomesUnknownAge() {
        var r = SurveyRecord(sex: .girl)
        r.dateOfBirth = localDate(2021, 5, 10)
        r.visitDate = localDate(2021, 4, 1)
        r.lengthOrHeight = 110
        #expect(SurveyRecordEvaluation.ageInDays(r) == nil)
        #expect(SurveyRecordEvaluation.ageInMonths(r) == nil)
        let result = SurveyRecordEvaluation.result(r, engine: engine)
        #expect(result.ageRange == .unknown)
        #expect(result.sex == .girl)
        #expect(result.lengthOrHeight == 110)
    }

    @Test func agesComeFromDatesWhenNotTyped() {
        var r = SurveyRecord(sex: .girl)
        r.dateOfBirth = localDate(2016, 3, 15)
        r.visitDate = localDate(2021, 4, 1)
        #expect(SurveyRecordEvaluation.ageInDays(r) == 1843)
        #expect(SurveyRecordEvaluation.ageInMonths(r) == Decimal(1843) / d("30.4375"))
    }

    @Test func typedMonthsWinAndConvertToDays() {
        var r = SurveyRecord(sex: .girl)
        r.dateOfBirth = localDate(2016, 3, 15)
        r.ageInMonths = d("61.5")
        #expect(SurveyRecordEvaluation.ageInMonths(r) == d("61.5"))
        #expect(SurveyRecordEvaluation.ageInDays(r) == 1872)
    }

    @Test func nilOedemaCountsAsNoOedema() {
        var r = SurveyRecord(sex: .boy)
        r.ageInMonths = 72
        r.weight = 20
        r.hasOedema = nil
        #expect(SurveyRecordEvaluation.result(r, engine: engine).weightForAge.zScore != nil)
    }

    @Test func displayedBMIUsesAdjustedMeasureOrRawWithoutAge() {
        var r = SurveyRecord(sex: .boy)
        r.weight = 10
        r.lengthOrHeight = 80
        r.measuredRecumbent = false
        #expect(SurveyRecordEvaluation.displayedBMI(r) == d("15.6"))  // 10 / 0,8^2 = 15,625, sem idade
        r.ageInMonths = 12  // 365 dias: em pé soma 0,7 cm, 10 / 0,807^2 = 15,35
        #expect(SurveyRecordEvaluation.displayedBMI(r) == d("15.4"))
        r.hasOedema = true
        #expect(SurveyRecordEvaluation.displayedBMI(r) == nil)
    }
}
