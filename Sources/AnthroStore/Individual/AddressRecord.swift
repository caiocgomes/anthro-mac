import Foundation

/// Endereço (`Address` do original, sem as listas SALB).
public struct AddressRecord: Sendable, Equatable {
    public var id: Int64?
    public var streetInfo: String?
    public var place: String?
    public var zip: String?
    public var district: String?
    public var province: String?
    public var state: String?
    public var country: String?
    public var phoneNumber: String?
    public var email: String?

    public init(id: Int64? = nil, streetInfo: String? = nil, place: String? = nil, zip: String? = nil,
                district: String? = nil, province: String? = nil, state: String? = nil, country: String? = nil,
                phoneNumber: String? = nil, email: String? = nil) {
        self.id = id
        self.streetInfo = streetInfo
        self.place = place
        self.zip = zip
        self.district = district
        self.province = province
        self.state = state
        self.country = country
        self.phoneNumber = phoneNumber
        self.email = email
    }

    /// `Address.DisplayName`: campos preenchidos separados por ", ", " - " antes do país, ou "(Sem dados)", e o ID.
    public var displayName: String {
        var text = ""
        for value in [streetInfo, place, zip, district, province, state] {
            appendIfNotNull(&text, value, separator: ", ")
        }
        appendIfNotNull(&text, country, separator: " - ")
        return (text.isEmpty ? noDataLabel : text) + idSuffix(id)
    }
}
