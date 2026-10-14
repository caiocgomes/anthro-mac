import Foundation

/// Visitas no banco (`Visits` do DAL original).
public final class VisitRepository {
    private let database: AnthroDatabase

    public init(database: AnthroDatabase) {
        self.database = database
    }

    public func visits(childID: Int64) throws -> [VisitRecord] { [] }
    public func replaceVisits(childID: Int64, with visits: [VisitRecord]) throws {}
}
