import Foundation

/// Registro de uma criança no inquérito (`Record` do original).
public struct SurveyRecord: Sendable, Equatable, Identifiable {
    public var id: Int64?
    public var visitDate: Date?
    public var cluster: Int?
    public var team: Int?
    public var displayID: Int?
    public var household: Int?
    public var weightingFactor: Decimal
    public var firstName: String?
    public var lastName: String?
    public var dateOfBirth: Date?
    public var dateOfBirthIsApprox: Bool = false
    public var ageInMonths: Decimal?
    public var sex: Sex
    public var weight: Decimal?
    public var lengthOrHeight: Decimal?
    public var measuredRecumbent: Bool = false
    public var hasOedema: Bool?
    public var notes: String?
    public var additionalDataXML: String?

    public init(id: Int64? = nil, sex: Sex = .girl, weightingFactor: Decimal = 1) {
        self.id = id
        self.sex = sex
        self.weightingFactor = weightingFactor
    }

    /// `Record.DisplayName`: sobrenome, ", " se já houver texto, e nome.
    public var displayName: String {
        var text = lastName ?? ""
        if !text.isEmpty { text += ", " }
        return text + (firstName ?? "")
    }
}
