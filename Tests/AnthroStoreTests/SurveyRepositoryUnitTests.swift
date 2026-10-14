import AnthroCore
import AnthroStore
import Foundation
import Testing

/// Laço interno de `SurveyRepository`: mapeamento de colunas e caminhos de atualização.
@Suite("SurveyRepository: colunas e atualização")
struct SurveyRepositoryUnitTests {
    let db: AnthroDatabase
    let repository: SurveyRepository

    init() throws {
        db = try SurveyFixtures.makeDatabase()
        repository = SurveyRepository(database: db)
    }

    @Test func recordColumnsFollowStorageConventions() throws {
        var boy = SurveyRecord(sex: .boy, weightingFactor: d("2.50"))
        boy.visitDate = SurveyFixtures.date("2021-04-01")
        boy.ageInMonths = d("61.5")
        boy.hasOedema = false
        var girl = SurveyRecord(sex: .girl)
        girl.hasOedema = nil
        girl.measuredRecumbent = true
        _ = try repository.save(Survey(name: "Escola A"), records: [boy, girl])
        let rows = try db.query(
            "SELECT position, sex, has_oedema, weighting_factor, visit_date, age_months, measured_recumbent FROM records ORDER BY position")
        #expect(rows.map { $0["position"] } == [.integer(0), .integer(1)])
        #expect(rows.map { $0["sex"] } == [.integer(1), .integer(2)])
        #expect(rows.map { $0["has_oedema"] } == [.integer(0), .null])
        #expect(rows.map { $0["weighting_factor"] } == [.text("2.5"), .text("1")])
        #expect(rows.map { $0["visit_date"] } == [.text("2021-04-01"), .null])
        #expect(rows.map { $0["age_months"] } == [.text("61.5"), .null])
        #expect(rows.map { $0["measured_recumbent"] } == [.integer(0), .integer(1)])
    }

    @Test func surveyFieldsRoundTripIncludingOptionsXML() throws {
        var options = SurveyOptions.default
        options.autoIDCluster = true
        options.standardsMaxZ = [d("4.5"), 6, 5]
        let saved = try repository.save(
            Survey(name: "Escola A", notes: " Turma 1 ", additionalDataDefinitionXML: "<Data />", options: options),
            records: [])
        let id = try #require(saved.survey.id)
        let reread = try repository.survey(id: id)
        #expect(reread == Survey(id: id, name: "Escola A", notes: "Turma 1", additionalDataDefinitionXML: "<Data />",
                                 options: options))
        #expect(saved.survey == reread)
        #expect(try db.query("SELECT options FROM surveys").first?["options"] == .text(options.xml()))
    }

    @Test func savingAgainUpdatesKeptRecordsAndDeletesRemovedOnes() throws {
        var a = SurveyRecord(sex: .girl)
        a.firstName = "A"
        var b = SurveyRecord(sex: .girl)
        b.firstName = "B"
        let first = try repository.save(Survey(name: "Escola A"), records: [a, b])
        var survey = first.survey
        let surveyID = try #require(survey.id)
        try #require(first.records.count == 2)
        survey.name = "Escola A2"
        var keptB = first.records[1]
        keptB.weight = 20
        var c = SurveyRecord(sex: .boy)
        c.firstName = "C"
        let second = try repository.save(survey, records: [keptB, c])
        #expect(second.records.first?.id == keptB.id)
        let reread = try repository.records(surveyID: surveyID)
        #expect(reread.map(\.firstName) == ["B", "C"])
        #expect(reread.first?.weight == 20)
        #expect(try SurveyFixtures.count(db, "records") == 2)
        #expect(try repository.survey(id: surveyID).name == "Escola A2")
        #expect(try SurveyFixtures.count(db, "surveys") == 1)
    }

    @Test func missingSurveyThrowsNotFound() {
        #expect(throws: SurveyStoreError.notFound(42)) { try repository.survey(id: 42) }
    }

    @Test func archiveFlagMovesSurveysBetweenLists() throws {
        let a = try SurveyFixtures.insertSurvey(db, name: "Escola A")
        try SurveyFixtures.insertSurvey(db, name: "Escola B")
        try repository.setArchived([a], archived: true)
        #expect(try repository.list(archived: true).map(\.name) == ["Escola A"])
        #expect(try repository.list(archived: false).map(\.name) == ["Escola B"])
        #expect(try repository.list(archived: true).first?.isArchived == true)
    }
}
