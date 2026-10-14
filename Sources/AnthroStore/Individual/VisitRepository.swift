import Foundation

/// Visitas no banco (`Visits` do DAL original), identificadas por criança e data (design D2).
public final class VisitRepository {
    private let database: AnthroDatabase

    public init(database: AnthroDatabase) {
        self.database = database
    }

    /// `Visits._GETLIST`: em ordem crescente de data.
    public func visits(childID: Int64) throws -> [VisitRecord] {
        try database.query(
            """
            SELECT child_id, date, weight, height, is_recumbent, has_oedema, notes, additional_data
            FROM visits WHERE child_id = ? ORDER BY date ASC
            """, [.integer(childID)]
        ).compactMap(Self.visit)
    }

    /// Substitui o conjunto de visitas da criança, numa transação (unidade de trabalho, design D3).
    public func replaceVisits(childID: Int64, with visits: [VisitRecord]) throws {
        try database.transaction {
            try database.execute("DELETE FROM visits WHERE child_id = ?", [.integer(childID)])
            for visit in visits {
                try database.execute(
                    """
                    INSERT INTO visits(child_id, date, weight, height, is_recumbent, has_oedema, notes, additional_data)
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?)
                    """,
                    [.integer(childID), SQLValue(visit.date), SQLValue(visit.weight), SQLValue(visit.lengthOrHeight),
                     .flag(visit.measuredRecumbent), .flag(visit.hasOedema), .text(visit.notes),
                     .text(visit.additionalDataXML)])
            }
        }
    }

    static func visit(_ row: Row) -> VisitRecord? {
        guard let date = row.date("date") else { return nil }
        return VisitRecord(childID: row.int64("child_id"), date: date, weight: row.decimal("weight"),
                           lengthOrHeight: row.decimal("height"), measuredRecumbent: row.flag("is_recumbent"),
                           hasOedema: row.flag("has_oedema"), notes: row.string("notes"),
                           additionalDataXML: row.string("additional_data"))
    }
}
