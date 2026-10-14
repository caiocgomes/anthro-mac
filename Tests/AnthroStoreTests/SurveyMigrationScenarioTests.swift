import AnthroStore
import Foundation
import Testing

/// Cenários da migração 3 (change add-nutritional-survey).
@Suite("survey-management: migração 3")
struct SurveyMigrationScenarioTests {
    // Scenario: Banco migrado
    @Test func migrationThreeCreatesSurveyTables() throws {
        let db = try SurveyFixtures.makeDatabase()
        #expect(try db.schemaVersion() >= 3)
        let tables = try db.query("SELECT name FROM sqlite_master WHERE type = 'table'")
            .compactMap { row -> String? in if case .text(let name) = row["name"] { name } else { nil } }
        #expect(tables.contains("surveys"))
        #expect(tables.contains("records"))
    }

    // Scenario: Sexo inválido
    @Test func invalidSexIsRejectedByConstraint() throws {
        let db = try SurveyFixtures.makeDatabase()
        var message = "no error"
        do {
            try db.execute("INSERT INTO surveys(name, options) VALUES ('Escola A', '<Opt />')")
            let surveyID = db.lastInsertRowID()
            try db.execute(
                """
                INSERT INTO records(survey_id, position, weighting_factor, dob_is_approx, sex, measured_recumbent)
                VALUES (?, 0, '1', 0, 3, 0)
                """, [.integer(surveyID)])
        } catch StoreError.sqlite(_, let text) {
            message = text
        }
        #expect(message.contains("CHECK constraint failed"))
    }
}
