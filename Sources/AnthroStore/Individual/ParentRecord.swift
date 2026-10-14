import Foundation

public enum ParentKind: Sendable, Equatable {
    case mother
    case father
}

/// Mãe ou pai (`Mother` e `Father` do original).
public struct ParentRecord: Sendable, Equatable {
    public var id: Int64?
    public var kind: ParentKind
    public var firstName: String?
    public var lastName: String?
    public var height: Decimal?
    public var weight: Decimal?
    public var dateOfBirth: Date?
    public var dateOfBirthIsApprox: Bool
    public var notes: String?

    public init(id: Int64? = nil, kind: ParentKind, firstName: String? = nil, lastName: String? = nil,
                height: Decimal? = nil, weight: Decimal? = nil, dateOfBirth: Date? = nil,
                dateOfBirthIsApprox: Bool = false, notes: String? = nil) {
        self.id = id
        self.kind = kind
        self.firstName = firstName
        self.lastName = lastName
        self.height = height
        self.weight = weight
        self.dateOfBirth = dateOfBirth
        self.dateOfBirthIsApprox = dateOfBirthIsApprox
        self.notes = notes
    }

    public var displayName: String { "" }
}
