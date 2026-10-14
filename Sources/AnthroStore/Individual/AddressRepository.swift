import Foundation

/// Endereços no banco (`Addresses` do DAL original).
public final class AddressRepository {
    private let database: AnthroDatabase

    public init(database: AnthroDatabase) {
        self.database = database
    }

    @discardableResult public func save(_ address: AddressRecord) throws -> AddressRecord { address }
    public func address(id: Int64) throws -> AddressRecord? { nil }
    public func search(text: String, limit: Int = 50) throws -> LookupSearchOutcome<AddressRecord> { .results([]) }
}
