import AnthroCore
import Foundation

/// Critérios de `IASearchDialog`.
public struct ChildSearchCriteria: Sendable, Equatable {
    public var firstName: String?
    public var lastName: String?
    public var sex: Sex?
    public var displayIDFrom: Int?
    public var displayIDTo: Int?
    public var dateOfBirthFrom: Date?
    public var dateOfBirthTo: Date?

    public init(firstName: String? = nil, lastName: String? = nil, sex: Sex? = nil, displayIDFrom: Int? = nil,
                displayIDTo: Int? = nil, dateOfBirthFrom: Date? = nil, dateOfBirthTo: Date? = nil) {
        self.firstName = firstName
        self.lastName = lastName
        self.sex = sex
        self.displayIDFrom = displayIDFrom
        self.displayIDTo = displayIDTo
        self.dateOfBirthFrom = dateOfBirthFrom
        self.dateOfBirthTo = dateOfBirthTo
    }

    public var isEmpty: Bool { false }
}
