import AnthroFeatures
import Foundation
import Testing

/// Cenários do editor de registro do inquérito (change add-nutritional-survey).
@MainActor
@Suite("survey-management: editor de registro")
struct RecordEditorScenarioTests {
    let engine: AnthroEngine

    init() throws {
        engine = try AnthroEngine.shared()
    }

    private func editor(record: SurveyRecord? = nil, definition: String? = nil,
                        picker: DayPicker = DayPicker()) -> RecordEditorModel {
        let survey = Survey(name: "Escola A", additionalDataDefinitionXML: definition, options: SurveyFixtures.literalOptions())
        return RecordEditorModel(record: record, survey: survey, existingRecords: [], engine: engine,
                                 today: day("2026-10-14"), randomDay: { picker($0) })
    }

    // MARK: Valores iniciais

    // Scenario: Registro novo
    @Test func newRecordEditorStartsWithOriginalDefaults() {
        let e = editor()
        #expect(e.text(.weightingFactor) == "1")
        #expect(e.value(.weightingFactor) == 1)
        #expect(e.sex == .girl)
        #expect(ymd(e.dateOfBirth) == "2025-10-14")
        #expect(e.dateOfBirthUnknown == false)
        #expect(e.measuredRecumbent == false)
        #expect(e.hasOedema == false)
        #expect(e.visitDate == nil)
    }

    // Scenario: Registro existente de menino
    @Test func existingBoyRecordLoadsSexAndWeightingFactor() {
        var record = SurveyFixtures.record(sex: .boy, visit: "2021-04-01", birth: "2016-03-15", weightingFactor: "0.5")
        record.id = 10
        let e = editor(record: record)
        #expect(e.sex == .boy)
        #expect(e.value(.weightingFactor) == num("0.5"))
    }

    // Scenario: Definição copiada
    @Test func newRecordCopiesSurveyAdditionalDataDefinition() throws {
        let definition = "<Data><Cat ID=\"Escola\" Descr=\"\" /></Data>"
        #expect(try editor(definition: definition).makeRecord().additionalDataXML == definition)
    }

    // Scenario: Inquérito sem definição
    @Test func newRecordWithoutDefinitionGetsEmptyData() throws {
        #expect(try editor().makeRecord().additionalDataXML == "<Data />")
    }

    // MARK: Campos numéricos

    // Scenario: Valores nos limites aceitos e truncados
    @Test func boundaryInputsAreAcceptedAndTruncated() throws {
        let e = editor()
        e.setText("20,129", for: .weight)
        e.setText("230", for: .lengthOrHeight)
        e.setText("2400", for: .ageInMonths)
        #expect(e.canSave)
        let record = try e.makeRecord()
        #expect(record.weight == num("20.12"))
        #expect(record.lengthOrHeight == 230)
        #expect(record.ageInMonths == 2400)
    }

    // Scenario: Valores fora dos limites bloqueiam salvar
    @Test func outOfRangeInputsWarnAndBlockSave() {
        let e = editor()
        e.setText("300", for: .weight)
        e.setText("37,99", for: .lengthOrHeight)
        e.setText("-0,1", for: .weightingFactor)
        #expect(e.outcome(.weight) == .outOfRange(num("0.9")...275))
        #expect(e.value(.weight) == nil)
        #expect(Set(e.warnings.keys) == [.weight, .lengthOrHeight, .weightingFactor])
        #expect(e.canSave == false)
        let error = #expect(throws: RecordValidationError.self) { try e.makeRecord() }
        #expect(error?.issues == [.outOfRange(.weight), .outOfRange(.lengthOrHeight), .outOfRange(.weightingFactor)])
    }

    // Scenario: Texto inválido bloqueia e vazio é aceito
    @Test func invalidTextBlocksSaveButEmptyIsAllowed() throws {
        let e = editor()
        e.setText("abc", for: .weight)
        e.setText("", for: .lengthOrHeight)
        #expect(e.outcome(.weight) == .invalid)
        #expect(e.canSave == false)
        e.setText("", for: .weight)
        #expect(e.canSave)
        let record = try e.makeRecord()
        #expect(record.weight == nil)
        #expect(record.lengthOrHeight == nil)
    }

    // Scenario: Fator de peso vazio
    @Test func emptyWeightingFactorIsRequired() {
        let e = editor()
        e.setText("", for: .weightingFactor)
        #expect(e.canSave == false)
        let error = #expect(throws: RecordValidationError.self) { try e.makeRecord() }
        #expect(error?.issues == [.required(.weightingFactor)])
    }

    // MARK: Idade e datas

    // Scenario: Idade derivada das datas exibida
    @Test func editorAgeTextUsesSharedAgeText() {
        let e = editor()
        e.setDateOfBirth(day("2016-03-15"))
        e.setVisitDate(day("2021-04-01"))
        #expect(e.ageText == AgeText.localized(months: 60))
    }

    // Scenario: Idade desconhecida
    @Test func editorAgeTextWithoutAgeIsNotAvailable() {
        let e = editor()
        e.dateOfBirthUnknown = true
        #expect(e.ageText == "Idade: N/D")
    }

    // Scenario: Duas datas presentes e idade digitada
    @Test func typedAgeIsDiscardedWhenBothDatesExist() throws {
        let e = editor()
        e.setText("30", for: .ageInMonths)
        e.setDateOfBirth(day("2016-03-15"))
        e.setVisitDate(day("2021-04-01"))
        let record = try e.makeRecord()
        #expect(record.ageInMonths == nil)
        #expect(record.dateOfBirth.map(ymd) == "2016-03-15")
        #expect(record.visitDate.map(ymd) == "2021-04-01")
        #expect(SurveyRecordEvaluation.ageInDays(record) == 1843)
    }

    // Scenario: Sorteio no limite superior
    @Test func approximateBirthDrawsDayBelowLastDayOfMonth() {
        let picker = DayPicker()
        picker.pick = { $0.upperBound - 1 }
        let e = editor(picker: picker)
        e.setDateOfBirth(day("2016-02-10"))
        e.setDateOfBirthIsApprox(true)
        #expect(ymd(e.dateOfBirth) == "2016-02-28")
        #expect(picker.ranges.last == 1..<29)
        #expect(e.dateOfBirthIsApprox)
    }

    // Scenario: Nascimento depois da data da pesquisa
    @Test func birthAfterVisitIsClampedToVisitDate() {
        let e = editor()
        e.setVisitDate(day("2021-04-01"))
        e.setDateOfBirth(day("2021-05-10"))
        #expect(ymd(e.dateOfBirth) == "2021-04-01")
    }

    // MARK: Medida e IMC

    // Scenario: Idade abaixo de 11 meses
    @Test func measureChoiceEnabledBelowElevenMonths() {
        let e = editor()
        e.setDateOfBirth(day("2020-01-01"))
        e.setVisitDate(day("2020-11-30"))
        #expect(e.isMeasureChoiceEnabled)
    }

    // Scenario: Idade de 11 meses
    @Test func measureChoiceDisabledAndStandingFromElevenMonths() throws {
        let e = editor()
        e.setDateOfBirth(day("2020-01-01"))
        e.setVisitDate(day("2020-11-30"))
        e.setMeasuredRecumbent(true)
        try #require(e.measuredRecumbent)
        e.setVisitDate(day("2020-12-01"))
        #expect(e.isMeasureChoiceEnabled == false)
        #expect(e.measuredRecumbent == false)
    }

    // Scenario: IMC com idade digitada
    @Test func editorBMIUsesTypedMonthsAdjustment() {
        let e = editor()
        e.dateOfBirthUnknown = true
        e.setText("72", for: .ageInMonths)
        e.setText("20", for: .weight)
        e.setText("110", for: .lengthOrHeight)
        #expect(e.bmiText == "16,5")
    }

    // Scenario: IMC com edema
    @Test func editorBMIIsNotAvailableWithOedema() {
        let e = editor()
        e.dateOfBirthUnknown = true
        e.setText("72", for: .ageInMonths)
        e.setText("20", for: .weight)
        e.setText("110", for: .lengthOrHeight)
        e.hasOedema = true
        #expect(e.bmiText == "N/D")
    }
}
