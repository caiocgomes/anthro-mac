import AnthroStore
import Foundation

/// Banco temporário e dados de partida por SQL direto, sem passar pelos repositórios em teste.
enum IAFixtures {
    static func makeDatabase() throws -> AnthroDatabase {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("anthro-ia-tests", isDirectory: true)
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return try AnthroDatabase.open(at: directory.appendingPathComponent("anthroplus.sqlite"))
    }

    /// Meio-dia do dia de calendário do usuário, a normalização dos modelos (design D10).
    static func date(_ text: String) -> Date {
        let parts = text.split(separator: "-").map { Int($0)! }
        return Calendar.current.date(from: DateComponents(year: parts[0], month: parts[1], day: parts[2], hour: 12))!
    }

    @discardableResult
    static func insertChild(_ db: AnthroDatabase, displayID: Int? = nil, firstName: String? = nil, lastName: String? = nil,
                            dateOfBirth: String = "2015-01-01", isApprox: Bool = false, sex: Int = 2,
                            motherID: Int64? = nil, fatherID: Int64? = nil, addressID: Int64? = nil,
                            archived: Bool = false) throws -> Int64 {
        try db.execute(
            """
            INSERT INTO children(display_id, first_name, last_name, date_of_birth, date_of_birth_is_approx, sex,
                                 mother_id, father_id, address_id, is_archived)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """,
            [displayID.map { .integer(Int64($0)) } ?? .null, text(firstName), text(lastName), .text(dateOfBirth),
             .integer(isApprox ? 1 : 0), .integer(Int64(sex)), id(motherID), id(fatherID), id(addressID),
             .integer(archived ? 1 : 0)])
        return db.lastInsertRowID()
    }

    static func insertVisit(_ db: AnthroDatabase, childID: Int64, date: String, weight: String? = nil,
                            height: String? = nil, recumbent: Bool = false, oedema: Bool = false,
                            notes: String? = nil) throws {
        try db.execute(
            "INSERT INTO visits(child_id, date, weight, height, is_recumbent, has_oedema, notes) VALUES (?, ?, ?, ?, ?, ?, ?)",
            [.integer(childID), .text(date), text(weight), text(height), .integer(recumbent ? 1 : 0),
             .integer(oedema ? 1 : 0), text(notes)])
    }

    @discardableResult
    static func insertMother(_ db: AnthroDatabase, firstName: String? = nil, lastName: String? = nil,
                             notes: String? = nil) throws -> Int64 {
        try db.execute("INSERT INTO mothers(first_name, last_name, notes) VALUES (?, ?, ?)",
                       [text(firstName), text(lastName), text(notes)])
        return db.lastInsertRowID()
    }

    @discardableResult
    static func insertFather(_ db: AnthroDatabase, firstName: String? = nil, lastName: String? = nil) throws -> Int64 {
        try db.execute("INSERT INTO fathers(first_name, last_name) VALUES (?, ?)", [text(firstName), text(lastName)])
        return db.lastInsertRowID()
    }

    @discardableResult
    static func insertAddress(_ db: AnthroDatabase, streetInfo: String? = nil, place: String? = nil,
                              country: String? = nil) throws -> Int64 {
        try db.execute("INSERT INTO addresses(street_info, place, country) VALUES (?, ?, ?)",
                       [text(streetInfo), text(place), text(country)])
        return db.lastInsertRowID()
    }

    static func count(_ db: AnthroDatabase, _ table: String, where condition: String = "1 = 1") throws -> Int {
        guard case .integer(let value) = try db.query("SELECT COUNT(*) AS n FROM \(table) WHERE \(condition)").first?["n"]
        else { return -1 }
        return Int(value)
    }

    private static func text(_ value: String?) -> SQLValue {
        value.map { .text($0) } ?? .null
    }

    private static func id(_ value: Int64?) -> SQLValue {
        value.map { .integer($0) } ?? .null
    }
}
