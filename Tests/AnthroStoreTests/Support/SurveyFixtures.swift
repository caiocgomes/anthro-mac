import AnthroStore
import Foundation

/// Decimal a partir de texto com ponto, sem passar por Double.
func d(_ text: String) -> Decimal {
    Decimal(string: text, locale: Locale(identifier: "en_US_POSIX"))!
}

/// Banco temporário e dados de partida do inquérito por SQL direto, sem passar pelo repositório em teste.
enum SurveyFixtures {
    static func makeDatabase() throws -> AnthroDatabase {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("anthro-survey-tests", isDirectory: true)
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return try AnthroDatabase.open(at: directory.appendingPathComponent("anthroplus.sqlite"))
    }

    /// Meio-dia do dia de calendário do usuário, a normalização dos modelos.
    static func date(_ text: String) -> Date {
        let parts = text.split(separator: "-").map { Int($0)! }
        return Calendar.current.date(from: DateComponents(year: parts[0], month: parts[1], day: parts[2], hour: 12))!
    }

    @discardableResult
    static func insertSurvey(_ db: AnthroDatabase, name: String, archived: Bool = false) throws -> Int64 {
        try db.execute("INSERT INTO surveys(name, options, is_archived) VALUES (?, '<Opt />', ?)",
                       [.text(name), .integer(archived ? 1 : 0)])
        return db.lastInsertRowID()
    }

    @discardableResult
    static func insertRecord(_ db: AnthroDatabase, surveyID: Int64, position: Int, sex: Int = 2,
                             firstName: String? = nil) throws -> Int64 {
        try db.execute(
            """
            INSERT INTO records(survey_id, position, weighting_factor, dob_is_approx, sex, measured_recumbent, first_name)
            VALUES (?, ?, '1', 0, ?, 0, ?)
            """,
            [.integer(surveyID), .integer(Int64(position)), .integer(Int64(sex)), firstName.map { .text($0) } ?? .null])
        return db.lastInsertRowID()
    }

    static func count(_ db: AnthroDatabase, _ table: String, where condition: String = "1 = 1") throws -> Int {
        guard case .integer(let value) = try db.query("SELECT COUNT(*) AS n FROM \(table) WHERE \(condition)").first?["n"]
        else { return -1 }
        return Int(value)
    }
}
