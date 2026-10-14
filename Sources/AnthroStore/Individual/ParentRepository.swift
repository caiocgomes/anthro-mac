import Foundation

/// Mães e pais no banco (`Mothers` e `Fathers` do DAL original).
public final class ParentRepository {
    private let database: AnthroDatabase

    public init(database: AnthroDatabase) {
        self.database = database
    }

    @discardableResult public func save(_ parent: ParentRecord) throws -> ParentRecord { parent }
    public func parent(kind: ParentKind, id: Int64) throws -> ParentRecord? { nil }
    public func search(kind: ParentKind, text: String, limit: Int = 50) throws -> LookupSearchOutcome<ParentRecord> {
        .results([])
    }
}
