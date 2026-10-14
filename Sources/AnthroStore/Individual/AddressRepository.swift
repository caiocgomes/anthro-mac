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

    /// `Addresses._SEARCH`: texto contido em qualquer campo; ordem por país, estado, província, distrito, CEP, local,
    /// logradouro e ID.
    public func search(text: String, limit: Int = 50) throws -> LookupSearchOutcome<AddressRecord> {
        let all = try database.query(
            """
            SELECT * FROM addresses ORDER BY country COLLATE NOCASE, state COLLATE NOCASE, province COLLATE NOCASE,
                district COLLATE NOCASE, zip COLLATE NOCASE, place COLLATE NOCASE, street_info COLLATE NOCASE, address_id
            """
        ).map(Self.address)
        return lookupSearch(all, text: text, limit: limit) {
            [$0.streetInfo, $0.place, $0.zip, $0.district, $0.province, $0.state, $0.country, $0.phoneNumber, $0.email]
        }
    }

    static func address(_ row: Row) -> AddressRecord {
        AddressRecord(id: row.int64("address_id"), streetInfo: row.string("street_info"), place: row.string("place"),
                      zip: row.string("zip"), district: row.string("district"), province: row.string("province"),
                      state: row.string("state"), country: row.string("country"),
                      phoneNumber: row.string("phone_number"), email: row.string("email"))
    }
}
