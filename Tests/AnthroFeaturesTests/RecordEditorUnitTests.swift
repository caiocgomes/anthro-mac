import AnthroFeatures
import Foundation
import Testing

/// Laço interno de `RecordEditorModel`: ida e volta de registro existente, avisos e habilitação da idade.
@MainActor
@Suite("RecordEditorModel: unidades")
struct RecordEditorUnitTests {
    let engine: AnthroEngine

    init() throws {
        engine = try AnthroEngine.shared()
    }

    private func editor(record: SurveyRecord? = nil, options: SurveyOptions = SurveyFixtures.literalOptions(),
                        existing: [SurveyRecord] = []) -> RecordEditorModel {
        RecordEditorModel(record: record, survey: Survey(name: "Escola A", options: options), existingRecords: existing,
                          engine: engine, today: day("2026-10-14"), randomDay: { $0.lowerBound })
    }

    @Test func untouchedExistingRecordComesBackUnchanged() throws {
        var record = SurveyFixtures.record(sex: .boy, visit: "2021-04-01", birth: "2016-03-15", approx: true,
                                           weight: "18.555", height: "110.25", cluster: 2, displayID: 9, household: 4,
                                           firstName: "Ana", oedema: nil, weightingFactor: "0.1234567890123456")
        record.id = 10
        record.team = 1
        record.lastName = "Silva"
        record.notes = "Nota"
        record.additionalDataXML = "<Data><Cat ID=\"Escola\" /></Data>"
        #expect(try editor(record: record).makeRecord() == record)
    }

    @Test func untouchedTypedAgeRecordComesBackUnchanged() throws {
        var record = SurveyFixtures.record(sex: .girl, months: "61.5", weight: "18", oedema: false)
        record.id = 3
        record.additionalDataXML = "<Data />"
        var options = SurveyFixtures.literalOptions()
        options.autoIDRecord = false
        options.autoIDHousehold = false
        let e = editor(record: record, options: options)
        #expect(e.dateOfBirthUnknown)
        #expect(try e.makeRecord() == record)
    }

    @Test func warningsCarryFieldLimits() {
        let e = editor()
        e.setText("abc", for: .lengthOrHeight)
        e.setText("300", for: .weight)
        e.setText("", for: .weightingFactor)
        e.setText("-1", for: .displayID)
        #expect(e.warnings[.lengthOrHeight] == "Valor inválido")
        #expect(e.warnings[.weight] == "Fora do intervalo: 0,90 a 275,00")
        #expect(e.warnings[.weightingFactor] == "Campo obrigatório")
        #expect(e.warnings[.displayID] == "Fora do intervalo: 0 a 2147483647")
        e.setText("-0,5", for: .weightingFactor)
        #expect(e.warnings[.weightingFactor] == "Valor mínimo: 0")
    }

    @Test func ageEntryIsDisabledAndClearedWithBothDates() {
        let e = editor()
        #expect(e.isAgeEntryEnabled)
        e.setText("30", for: .ageInMonths)
        e.setVisitDate(day("2021-04-01"))
        #expect(e.isAgeEntryEnabled == false)
        #expect(e.text(.ageInMonths) == "")
        e.dateOfBirthUnknown = true
        #expect(e.isAgeEntryEnabled)
    }

    @Test func uncheckingUnknownBirthClearsApproximateFlag() throws {
        let e = editor()
        e.setDateOfBirthIsApprox(true)
        e.dateOfBirthUnknown = true
        try #require(e.dateOfBirthIsApprox)
        e.dateOfBirthUnknown = false
        #expect(e.dateOfBirthIsApprox == false)
    }

    @Test func autoAssignmentFollowsOptionsAndExistingMaximum() throws {
        var options = SurveyFixtures.literalOptions()
        options.autoIDTeam = true
        let e = editor(options: options, existing: [SurveyFixtures.record(displayID: 4), SurveyFixtures.record(household: 9)])
        #expect(e.isAutoAssigned(.team))
        #expect(e.isAutoAssigned(.cluster) == false)
        let record = try e.makeRecord()
        #expect(record.team == 1)
        #expect(record.displayID == 5)
        #expect(record.household == 10)
        #expect(record.cluster == nil)
    }

    @Test func typedAgeOfElevenMonthsForcesStanding() {
        let e = editor()
        e.dateOfBirthUnknown = true
        e.setText("10", for: .ageInMonths)
        e.setMeasuredRecumbent(true)
        #expect(e.measuredRecumbent)
        e.setText("11", for: .ageInMonths)
        #expect(e.measuredRecumbent == false)
    }
}
