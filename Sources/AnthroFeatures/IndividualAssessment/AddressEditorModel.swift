import AnthroStore
import Foundation
import Observation

/// Editor de endereço (`IAAddressDialog`, sem as listas SALB): gravado na hora (D3), textos sem espaços nas pontas e
/// vazio como `nil`.
@MainActor
@Observable
public final class AddressEditorModel {
    public var streetInfo: String
    public var place: String
    public var zip: String
    public var district: String
    public var province: String
    public var state: String
    public var country: String
    public var phoneNumber: String
    public var email: String

    @ObservationIgnored private let database: AnthroDatabase
    @ObservationIgnored private let editing: AddressRecord?

    public init(database: AnthroDatabase, editing: AddressRecord?) {
        self.database = database
        self.editing = editing
        streetInfo = editing?.streetInfo ?? ""
        place = editing?.place ?? ""
        zip = editing?.zip ?? ""
        district = editing?.district ?? ""
        province = editing?.province ?? ""
        state = editing?.state ?? ""
        country = editing?.country ?? ""
        phoneNumber = editing?.phoneNumber ?? ""
        email = editing?.email ?? ""
    }

    @discardableResult public func save() throws -> AddressRecord {
        let n = IndividualAssessment.nullable
        return try AddressRepository(database: database).save(
            AddressRecord(id: editing?.id, streetInfo: n(streetInfo), place: n(place), zip: n(zip), district: n(district),
                          province: n(province), state: n(state), country: n(country), phoneNumber: n(phoneNumber),
                          email: n(email)))
    }
}
