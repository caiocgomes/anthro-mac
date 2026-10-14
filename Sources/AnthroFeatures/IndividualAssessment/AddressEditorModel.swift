import AnthroStore
import Foundation
import Observation

/// Editor de endereço (`IAAddressDialog`, sem as listas SALB).
@MainActor
@Observable
public final class AddressEditorModel {
    public var streetInfo: String = ""
    public var place: String = ""
    public var zip: String = ""
    public var district: String = ""
    public var province: String = ""
    public var state: String = ""
    public var country: String = ""
    public var phoneNumber: String = ""
    public var email: String = ""

    public init(database: AnthroDatabase, editing: AddressRecord?) {}

    @discardableResult public func save() throws -> AddressRecord {
        AddressRecord()
    }
}
