import AnthroCore
import Foundation

/// Criança da Avaliação individual (`Child` do original).
public struct ChildRecord: Sendable, Equatable {
    public var id: Int64?
    public var displayID: Int?
    public var firstName: String?
    public var lastName: String?
    public var dateOfBirth: Date
    public var dateOfBirthIsApprox: Bool
    public var sex: Sex
    public var motherID: Int64?
    public var fatherID: Int64?
    public var addressID: Int64?
    public var notes: String?
    public var followUpDate: Date?
    public var followUpInterval: Int?
    public var followUpRefTo: String?
    public var isArchived: Bool

    public init(id: Int64? = nil, displayID: Int? = nil, firstName: String? = nil, lastName: String? = nil,
                dateOfBirth: Date, dateOfBirthIsApprox: Bool = false, sex: Sex, motherID: Int64? = nil,
                fatherID: Int64? = nil, addressID: Int64? = nil, notes: String? = nil, followUpDate: Date? = nil,
                followUpInterval: Int? = nil, followUpRefTo: String? = nil, isArchived: Bool = false) {
        self.id = id
        self.displayID = displayID
        self.firstName = firstName
        self.lastName = lastName
        self.dateOfBirth = dateOfBirth
        self.dateOfBirthIsApprox = dateOfBirthIsApprox
        self.sex = sex
        self.motherID = motherID
        self.fatherID = fatherID
        self.addressID = addressID
        self.notes = notes
        self.followUpDate = followUpDate
        self.followUpInterval = followUpInterval
        self.followUpRefTo = followUpRefTo
        self.isArchived = isArchived
    }

    /// `Child.DisplayName`: sobrenome, ", " se já houver texto, e nome.
    public var displayName: String {
        var text = lastName ?? ""
        if !text.isEmpty { text += ", " }
        return text + (firstName ?? "")
    }

    /// Linha da lista de `IAMain.LoadChildrenList`: `"{DisplayName} ({DisplayID})"`, com parênteses vazios sem ID.
    public var listTitle: String {
        "\(displayName) (\(displayID.map(String.init) ?? ""))"
    }
}
