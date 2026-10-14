import AnthroCore
import AnthroStore
import Foundation
import Testing

/// Cenários de persistência do inquérito sobre `SurveyRepository` (change add-nutritional-survey).
@Suite("survey-management: SurveyRepository")
struct SurveyRepositoryScenarioTests {
    let db: AnthroDatabase
    let repository: SurveyRepository

    init() throws {
        db = try SurveyFixtures.makeDatabase()
        repository = SurveyRepository(database: db)
    }

    // Scenario: Inquérito novo salvo com nome e notas vazias
    @Test func newSurveyIsSavedWithTrimmedNameAndNilNotes() throws {
        _ = try repository.save(Survey(name: " Escola A 2026 ", notes: "   "), records: [])
        let rows = try db.query("SELECT name, notes FROM surveys")
        #expect(rows.count == 1)
        #expect(rows.first?["name"] == .text("Escola A 2026"))
        #expect(rows.first?["notes"] == .null)
    }

    // Scenario: Nome só com espaços
    @Test func blankSurveyNameThrowsNameRequired() throws {
        #expect(throws: SurveyStoreError.nameRequired) { try repository.save(Survey(name: "   "), records: []) }
        #expect(try SurveyFixtures.count(db, "surveys") == 0)
    }

    // Scenario: Ordem da lista
    @Test func activeSurveysAreOrderedByNameThenID() throws {
        let b = try SurveyFixtures.insertSurvey(db, name: "Escola B")
        let firstA = try SurveyFixtures.insertSurvey(db, name: "Escola A")
        let secondA = try SurveyFixtures.insertSurvey(db, name: "Escola A")
        #expect(try repository.list(archived: false).map(\.id) == [firstA, secondA, b])
    }

    // Scenario: Exclusão em cascata
    @Test func deletingSurveyDeletesItsRecords() throws {
        let id = try SurveyFixtures.insertSurvey(db, name: "Escola A")
        for position in 0..<3 {
            try SurveyFixtures.insertRecord(db, surveyID: id, position: position)
        }
        try #require(try SurveyFixtures.count(db, "records", where: "survey_id = \(id)") == 3)
        try repository.delete([id])
        #expect(try SurveyFixtures.count(db, "surveys", where: "id = \(id)") == 0)
        #expect(try SurveyFixtures.count(db, "records", where: "survey_id = \(id)") == 0)
    }

    // Scenario: Falha no meio do salvamento
    @Test func failedRecordInsertRollsBackSurveyInsert() throws {
        try db.execute("DROP TABLE records")
        let records = [SurveyRecord(sex: .girl), SurveyRecord(sex: .boy)]
        let error = #expect(throws: StoreError.self) { try repository.save(Survey(name: "Escola A"), records: records) }
        if let error, case .sqlite = error {} else if let error {
            Issue.record("expected StoreError.sqlite, got \(error)")
        }
        #expect(try SurveyFixtures.count(db, "surveys") == 0)
    }

    // Scenario: Ida e volta de um registro completo
    @Test func recordRoundTripsWithoutLoss() throws {
        var complete = SurveyRecord(sex: .boy, weightingFactor: d("0.1234567890123456"))
        complete.visitDate = SurveyFixtures.date("2021-04-01")
        complete.cluster = 3
        complete.team = 2
        complete.displayID = 7
        complete.household = 5
        complete.firstName = "Ana"
        complete.lastName = "Silva"
        complete.dateOfBirth = SurveyFixtures.date("2016-03-15")
        complete.dateOfBirthIsApprox = true
        complete.weight = d("18.5")
        complete.lengthOrHeight = d("110.25")
        complete.measuredRecumbent = true
        complete.hasOedema = nil
        complete.notes = "Nota"
        complete.additionalDataXML = "<Data />"
        var typedAge = SurveyRecord(sex: .girl)
        typedAge.ageInMonths = d("61.5")
        typedAge.hasOedema = false

        let saved = try repository.save(Survey(name: "Escola A"), records: [complete, typedAge])
        let surveyID = try #require(saved.survey.id)
        let reloaded = try repository.records(surveyID: surveyID)
        #expect(reloaded.count == 2)
        #expect(reloaded.allSatisfy { $0.id != nil })
        #expect(reloaded.map { record -> SurveyRecord in
            var copy = record
            copy.id = nil
            return copy
        } == [complete, typedAge])
    }
}
