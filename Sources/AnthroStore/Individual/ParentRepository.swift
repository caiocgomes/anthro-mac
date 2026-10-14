import Foundation

/// Mães e pais no banco (`Mothers` e `Fathers` do DAL original), gravados na hora pelo editor (design D3).
public final class ParentRepository {
    private let database: AnthroDatabase

    public init(database: AnthroDatabase) {
        self.database = database
    }

    @discardableResult public func save(_ parent: ParentRecord) throws -> ParentRecord {
        let table = Self.table(parent.kind)
        var saved = parent
        let values: [SQLValue] = [
            .text(parent.firstName), .text(parent.lastName), SQLValue(parent.height), SQLValue(parent.weight),
            SQLValue(parent.dateOfBirth), .flag(parent.dateOfBirthIsApprox), .text(parent.notes),
        ]
        if let id = parent.id {
            try database.execute(
                """
                UPDATE \(table.name) SET first_name = ?, last_name = ?, height = ?, weight = ?, date_of_birth = ?,
                    date_of_birth_is_approx = ?, notes = ?, updated_at = strftime('%Y-%m-%dT%H:%M:%SZ', 'now')
                WHERE \(table.key) = ?
                """, values + [.integer(id)])
        } else {
            try database.execute(
                """
                INSERT INTO \(table.name)(first_name, last_name, height, weight, date_of_birth, date_of_birth_is_approx, notes)
                VALUES (?, ?, ?, ?, ?, ?, ?)
                """, values)
            saved.id = database.lastInsertRowID()
        }
        return saved
    }

    public func parent(kind: ParentKind, id: Int64) throws -> ParentRecord? {
        let table = Self.table(kind)
        return try database.query("SELECT * FROM \(table.name) WHERE \(table.key) = ?", [.integer(id)])
            .first.map { Self.parent($0, kind: kind) }
    }

    /// `Mothers._SEARCH`: texto contido no nome, sobrenome ou notas; ordem por sobrenome, nome e ID.
    public func search(kind: ParentKind, text: String, limit: Int = 50) throws -> LookupSearchOutcome<ParentRecord> {
        let table = Self.table(kind)
        let all = try database.query(
            "SELECT * FROM \(table.name) ORDER BY last_name COLLATE NOCASE, first_name COLLATE NOCASE, \(table.key)"
        ).map { Self.parent($0, kind: kind) }
        return lookupSearch(all, text: text, limit: limit) { [$0.firstName, $0.lastName, $0.notes] }
    }

    static func table(_ kind: ParentKind) -> (name: String, key: String) {
        kind == .mother ? ("mothers", "mother_id") : ("fathers", "father_id")
    }

    static func parent(_ row: Row, kind: ParentKind) -> ParentRecord {
        ParentRecord(id: row.int64(table(kind).key), kind: kind, firstName: row.string("first_name"),
                     lastName: row.string("last_name"), height: row.decimal("height"), weight: row.decimal("weight"),
                     dateOfBirth: row.date("date_of_birth"), dateOfBirthIsApprox: row.flag("date_of_birth_is_approx"),
                     notes: row.string("notes"))
    }
}
