import Foundation

/// Crianças no banco (`Children` do DAL original).
public final class ChildRepository {
    private let database: AnthroDatabase

    public init(database: AnthroDatabase) {
        self.database = database
    }

    public func list(archived: Bool) throws -> [ChildRecord] { [] }
    public func child(id: Int64) throws -> ChildRecord? { nil }
    public func search(_ criteria: ChildSearchCriteria) throws -> [ChildRecord] { [] }
    public func maxDisplayID() throws -> Int? { nil }
    @discardableResult public func save(_ child: ChildRecord, visits: [VisitRecord]) throws -> ChildRecord { child }
    public func setArchived(_ ids: [Int64], archived: Bool) throws {}
    public func delete(_ ids: [Int64]) throws {}
}
