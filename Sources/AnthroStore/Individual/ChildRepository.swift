import Foundation

/// Crianças no banco (`Children` do DAL original).
public final class ChildRepository {
    private let database: AnthroDatabase

    private static let columns = """
        child_id, display_id, first_name, last_name, date_of_birth, date_of_birth_is_approx, sex, mother_id, father_id,
        address_id, notes, follow_up_date, follow_up_interval, follow_up_ref_to, is_archived
        """

    public init(database: AnthroDatabase) {
        self.database = database
    }

    /// `Children._GETLIST`: ativas ou arquivadas, em ordem crescente de ID de exibição (`NULL` primeiro).
    public func list(archived: Bool) throws -> [ChildRecord] {
        try database.query("SELECT \(Self.columns) FROM children WHERE is_archived = ? ORDER BY display_id ASC, child_id ASC",
                           [.flag(archived)]).compactMap(Self.child)
    }

    public func child(id: Int64) throws -> ChildRecord? {
        try database.query("SELECT \(Self.columns) FROM children WHERE child_id = ?", [.integer(id)]).compactMap(Self.child).first
    }

    /// `Children.Search`: só ativas, sexo, faixas de ID e de nascimento no SQL, ordem por ID; nomes filtrados em Swift
    /// por `NameMatcher` (design D5).
    public func search(_ criteria: ChildSearchCriteria) throws -> [ChildRecord] {
        var conditions = ["is_archived = 0"]
        var params: [SQLValue] = []
        if let sex = criteria.sex {
            conditions.append("sex = ?")
            params.append(.sex(sex))
        }
        if let from = criteria.displayIDFrom {
            conditions.append("display_id >= ?")
            params.append(.integer(Int64(from)))
        }
        if let to = criteria.displayIDTo {
            conditions.append("display_id <= ?")
            params.append(.integer(Int64(to)))
        }
        if let from = criteria.dateOfBirthFrom {
            conditions.append("date_of_birth >= ?")
            params.append(SQLValue(from))
        }
        if let to = criteria.dateOfBirthTo {
            conditions.append("date_of_birth <= ?")
            params.append(SQLValue(to))
        }
        let sql = "SELECT \(Self.columns) FROM children WHERE \(conditions.joined(separator: " AND ")) ORDER BY display_id ASC, child_id ASC"
        let firstName = ChildSearchCriteria.nameCriterion(criteria.firstName)
        let lastName = ChildSearchCriteria.nameCriterion(criteria.lastName)
        return try database.query(sql, params).compactMap(Self.child).filter { child in
            (firstName.map { NameMatcher.matches(pattern: $0, value: child.firstName) } ?? true)
                && (lastName.map { NameMatcher.matches(pattern: $0, value: child.lastName) } ?? true)
        }
    }
    public func maxDisplayID() throws -> Int? { nil }

    /// Grava a criança (inclui ou atualiza) e substitui as suas visitas numa só transação (design D3).
    @discardableResult public func save(_ child: ChildRecord, visits: [VisitRecord]) throws -> ChildRecord {
        try database.transaction {
            var saved = child
            let values: [SQLValue] = [
                .integer(child.displayID), .text(child.firstName), .text(child.lastName), SQLValue(child.dateOfBirth),
                .flag(child.dateOfBirthIsApprox), .sex(child.sex), .integer(child.motherID), .integer(child.fatherID),
                .integer(child.addressID), .text(child.notes), SQLValue(child.followUpDate),
                .integer(child.followUpInterval), .text(child.followUpRefTo), .flag(child.isArchived),
            ]
            if let id = child.id {
                try database.execute(
                    """
                    UPDATE children SET display_id = ?, first_name = ?, last_name = ?, date_of_birth = ?,
                        date_of_birth_is_approx = ?, sex = ?, mother_id = ?, father_id = ?, address_id = ?, notes = ?,
                        follow_up_date = ?, follow_up_interval = ?, follow_up_ref_to = ?, is_archived = ?,
                        updated_at = strftime('%Y-%m-%dT%H:%M:%SZ', 'now')
                    WHERE child_id = ?
                    """, values + [.integer(id)])
            } else {
                try database.execute(
                    """
                    INSERT INTO children(display_id, first_name, last_name, date_of_birth, date_of_birth_is_approx, sex,
                        mother_id, father_id, address_id, notes, follow_up_date, follow_up_interval, follow_up_ref_to,
                        is_archived)
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                    """, values)
                saved.id = database.lastInsertRowID()
            }
            try VisitRepository(database: database).replaceVisits(childID: saved.id!, with: visits)
            return saved
        }
    }

    public func setArchived(_ ids: [Int64], archived: Bool) throws {}
    public func delete(_ ids: [Int64]) throws {}

    static func child(_ row: Row) -> ChildRecord? {
        guard let dateOfBirth = row.date("date_of_birth") else { return nil }
        return ChildRecord(
            id: row.int64("child_id"), displayID: row.int("display_id"), firstName: row.string("first_name"),
            lastName: row.string("last_name"), dateOfBirth: dateOfBirth,
            dateOfBirthIsApprox: row.flag("date_of_birth_is_approx"), sex: row.sex("sex"),
            motherID: row.int64("mother_id"), fatherID: row.int64("father_id"), addressID: row.int64("address_id"),
            notes: row.string("notes"), followUpDate: row.date("follow_up_date"),
            followUpInterval: row.int("follow_up_interval"), followUpRefTo: row.string("follow_up_ref_to"),
            isArchived: row.flag("is_archived"))
    }
}
