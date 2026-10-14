import AnthroFeatures
import Foundation
import Testing

/// Dia de calendário do usuário ao meio-dia, a partir de "AAAA-MM-DD" (a normalização dos modelos).
func day(_ text: String) -> Date {
    let parts = text.split(separator: "-").map { Int($0)! }
    return day(parts[0], parts[1], parts[2])
}

/// Banco temporário, opções literais e registros do inquérito; dados de partida no banco por SQL direto.
enum SurveyFixtures {
    static let literalAgeBoundaries = [0, 6, 12, 24, 36, 48, 61, 72, 84, 96, 108, 120, 132, 144, 156, 168, 180, 192, 204,
                                       216, 228, 228]

    static func makeDatabase() throws -> AnthroDatabase {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("anthro-survey-tests", isDirectory: true)
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return try AnthroDatabase.open(at: directory.appendingPathComponent("anthroplus.sqlite"))
    }

    /// Opções padrão montadas campo a campo com literais, sem depender de `SurveyOptions.default`.
    static func literalOptions() -> SurveyOptions {
        var options = SurveyOptions.default
        options.autoIDCluster = false
        options.autoIDTeam = false
        options.autoIDRecord = true
        options.autoIDHousehold = true
        options.ageGroupBoundaries = literalAgeBoundaries
        options.standardsMinZ = [-6, -6, -5]
        options.standardsMaxZ = [5, 6, 5]
        options.referenceMinZ = [-6, -6, -5]
        options.referenceMaxZ = [5, 6, 5]
        return options
    }

    static func expectLiteralDefaults(_ options: SurveyOptions, sourceLocation: SourceLocation = #_sourceLocation) {
        #expect(options.autoIDCluster == false, sourceLocation: sourceLocation)
        #expect(options.autoIDTeam == false, sourceLocation: sourceLocation)
        #expect(options.autoIDRecord == true, sourceLocation: sourceLocation)
        #expect(options.autoIDHousehold == true, sourceLocation: sourceLocation)
        #expect(options.ageGroupBoundaries == literalAgeBoundaries, sourceLocation: sourceLocation)
        #expect(options.standardsMinZ == [-6, -6, -5], sourceLocation: sourceLocation)
        #expect(options.standardsMaxZ == [5, 6, 5], sourceLocation: sourceLocation)
        #expect(options.referenceMinZ == [-6, -6, -5], sourceLocation: sourceLocation)
        #expect(options.referenceMaxZ == [5, 6, 5], sourceLocation: sourceLocation)
    }

    static func record(sex: Sex = .girl, visit: String? = nil, birth: String? = nil, approx: Bool = false,
                       months: String? = nil, weight: String? = nil, height: String? = nil, cluster: Int? = nil,
                       displayID: Int? = nil, household: Int? = nil, firstName: String? = nil, oedema: Bool? = nil,
                       weightingFactor: String = "1") -> SurveyRecord {
        var record = SurveyRecord(sex: sex, weightingFactor: num(weightingFactor))
        record.visitDate = visit.map(day)
        record.dateOfBirth = birth.map(day)
        record.dateOfBirthIsApprox = approx
        record.ageInMonths = months.map(num)
        record.weight = weight.map(num)
        record.lengthOrHeight = height.map(num)
        record.cluster = cluster
        record.displayID = displayID
        record.household = household
        record.firstName = firstName
        record.hasOedema = oedema
        return record
    }

    @discardableResult
    static func insertSurvey(_ db: AnthroDatabase, name: String, archived: Bool = false) throws -> Int64 {
        try db.execute("INSERT INTO surveys(name, options, is_archived) VALUES (?, '<Opt />', ?)",
                       [.text(name), .integer(archived ? 1 : 0)])
        return db.lastInsertRowID()
    }

    @discardableResult
    static func insertRecord(_ db: AnthroDatabase, surveyID: Int64, position: Int, firstName: String? = nil) throws -> Int64 {
        try db.execute(
            """
            INSERT INTO records(survey_id, position, weighting_factor, dob_is_approx, sex, measured_recumbent, first_name)
            VALUES (?, ?, '1', 0, 2, 0, ?)
            """,
            [.integer(surveyID), .integer(Int64(position)), firstName.map { .text($0) } ?? .null])
        return db.lastInsertRowID()
    }

    static func row(_ db: AnthroDatabase, _ table: String, where condition: String) throws -> Row? {
        try db.query("SELECT * FROM \(table) WHERE \(condition)").first
    }

    static func count(_ db: AnthroDatabase, _ table: String, where condition: String = "1 = 1") throws -> Int {
        guard case .integer(let value) = try db.query("SELECT COUNT(*) AS n FROM \(table) WHERE \(condition)").first?["n"]
        else { return -1 }
        return Int(value)
    }

    @MainActor
    static func detail(_ records: [SurveyRecord], db: AnthroDatabase, engine: AnthroEngine,
                       survey: Survey = Survey(name: "Escola A", options: literalOptions())) -> SurveyDetailModel {
        SurveyDetailModel(survey: survey, records: records, repository: SurveyRepository(database: db), engine: engine,
                          today: { day("2026-10-14") })
    }
}
