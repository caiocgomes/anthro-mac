import AnthroCore
import Foundation

/// Resultados calculados escritos na exportação com resultados (`WAZ`, `HAZ`, `BAZ`, `BMI`).
public struct ExchangeResults: Equatable, Sendable {
    public var weightForAgeZ: Decimal?
    public var lengthOrHeightForAgeZ: Decimal?
    public var bmiForAgeZ: Decimal?
    public var bmi: Decimal?

    public init(weightForAgeZ: Decimal?, lengthOrHeightForAgeZ: Decimal?, bmiForAgeZ: Decimal?, bmi: Decimal?) {
        self.weightForAgeZ = weightForAgeZ
        self.lengthOrHeightForAgeZ = lengthOrHeightForAgeZ
        self.bmiForAgeZ = bmiForAgeZ
        self.bmi = bmi
    }
}

/// Mãe ou pai na troca de dados (`Mother` e `Father` do XML do original).
public struct ExchangePerson: Equatable, Sendable {
    public var firstName: String?
    public var lastName: String?
    public var height: Decimal?
    public var weight: Decimal?
    public var dateOfBirth: Date?
    public var dateOfBirthIsApprox: Bool
    public var notes: String?

    public init(firstName: String? = nil, lastName: String? = nil, height: Decimal? = nil, weight: Decimal? = nil,
                dateOfBirth: Date? = nil, dateOfBirthIsApprox: Bool = false, notes: String? = nil) {
        self.firstName = firstName
        self.lastName = lastName
        self.height = height
        self.weight = weight
        self.dateOfBirth = dateOfBirth
        self.dateOfBirthIsApprox = dateOfBirthIsApprox
        self.notes = notes
    }
}

/// Endereço na troca de dados (`Address` do XML do original, sem os níveis SALB).
public struct ExchangeAddress: Equatable, Sendable {
    public var streetInfo: String?
    public var place: String?
    public var zip: String?
    public var district: String?
    public var province: String?
    public var state: String?
    public var country: String?
    public var phoneNumber: String?
    public var email: String?

    public init(streetInfo: String? = nil, place: String? = nil, zip: String? = nil, district: String? = nil,
                province: String? = nil, state: String? = nil, country: String? = nil, phoneNumber: String? = nil,
                email: String? = nil) {
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
}

/// Visita na troca de dados (`Visit` do XML do original).
public struct ExchangeVisit: Equatable, Sendable {
    public var date: Date
    public var weight: Decimal?
    public var height: Decimal?
    public var isRecumbent: Bool
    public var hasOedema: Bool
    public var notes: String?
    public var additionalData: AdditionalData?
    public var results: ExchangeResults?

    public init(date: Date, weight: Decimal? = nil, height: Decimal? = nil, isRecumbent: Bool = false,
                hasOedema: Bool = false, notes: String? = nil, additionalData: AdditionalData? = nil,
                results: ExchangeResults? = nil) {
        self.date = date
        self.weight = weight
        self.height = height
        self.isRecumbent = isRecumbent
        self.hasOedema = hasOedema
        self.notes = notes
        self.additionalData = additionalData
        self.results = results
    }
}

/// Criança na troca de dados (`Child` do XML do original), com pais, endereço e visitas (design D1).
public struct ExchangeChild: Equatable, Sendable {
    public var displayID: Int?
    public var firstName: String?
    public var lastName: String?
    public var dateOfBirth: Date
    public var dateOfBirthIsApprox: Bool
    public var sex: Sex
    public var notes: String?
    public var mother: ExchangePerson?
    public var father: ExchangePerson?
    public var address: ExchangeAddress?
    public var visits: [ExchangeVisit]

    public init(displayID: Int? = nil, firstName: String? = nil, lastName: String? = nil, dateOfBirth: Date,
                dateOfBirthIsApprox: Bool = false, sex: Sex, notes: String? = nil, mother: ExchangePerson? = nil,
                father: ExchangePerson? = nil, address: ExchangeAddress? = nil, visits: [ExchangeVisit] = []) {
        self.displayID = displayID
        self.firstName = firstName
        self.lastName = lastName
        self.dateOfBirth = dateOfBirth
        self.dateOfBirthIsApprox = dateOfBirthIsApprox
        self.sex = sex
        self.notes = notes
        self.mother = mother
        self.father = father
        self.address = address
        self.visits = visits
    }
}

/// `CreatedBy` escrito em toda exportação (design D9): o app é de usuário único.
public enum ExchangeDefaults {
    public static let createdBy: String = ""
}
