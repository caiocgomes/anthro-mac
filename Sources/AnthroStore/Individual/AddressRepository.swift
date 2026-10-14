import Foundation

/// Endereços no banco (`Addresses` do DAL original), gravados na hora pelo editor (design D3).
public final class AddressRepository {
    private let database: AnthroDatabase

    public init(database: AnthroDatabase) {
        self.database = database
    }

    @discardableResult public func save(_ address: AddressRecord) throws -> AddressRecord {
        var saved = address
        let values: [SQLValue] = [address.streetInfo, address.place, address.zip, address.district, address.province,
                                  address.state, address.country, address.phoneNumber, address.email].map { .text($0) }
        if let id = address.id {
            try database.execute(
                """
                UPDATE addresses SET street_info = ?, place = ?, zip = ?, district = ?, province = ?, state = ?,
                    country = ?, phone_number = ?, email = ?, updated_at = strftime('%Y-%m-%dT%H:%M:%SZ', 'now')
                WHERE address_id = ?
                """, values + [.integer(id)])
        } else {
            try database.execute(
                """
                INSERT INTO addresses(street_info, place, zip, district, province, state, country, phone_number, email)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
                """, values)
            saved.id = database.lastInsertRowID()
        }
        return saved
    }

    public func address(id: Int64) throws -> AddressRecord? {
        try database.query("SELECT * FROM addresses WHERE address_id = ?", [.integer(id)]).first.map(Self.address)
    }

    public func search(text: String, limit: Int = 50) throws -> LookupSearchOutcome<AddressRecord> { .results([]) }

    static func address(_ row: Row) -> AddressRecord {
        AddressRecord(id: row.int64("address_id"), streetInfo: row.string("street_info"), place: row.string("place"),
                      zip: row.string("zip"), district: row.string("district"), province: row.string("province"),
                      state: row.string("state"), country: row.string("country"),
                      phoneNumber: row.string("phone_number"), email: row.string("email"))
    }
}
