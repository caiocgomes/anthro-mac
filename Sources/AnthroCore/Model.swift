import Foundation

/// Sexo da criança. Os valores seguem `Gender` do original (Girl = 0, Boy = 1).
public enum Sex: Int, Sendable, Codable, CaseIterable {
    case girl = 0
    case boy = 1
}

/// Indicadores do WHO AnthroPlus (`Indicator` do original).
public enum Indicator: Int, Sendable, CaseIterable {
    case weightForAge = 0
    case lengthOrHeightForAge = 1
    case bmiForAge = 2
}

/// Faixa etária do cálculo (`AgeRange` do original).
public enum AgeRange: Sendable {
    case unknown
    case standards
    case reference
    case offLimits
}

/// Linha LMS de uma tabela da OMS.
public struct LMS: Sendable, Equatable {
    public let l: Decimal
    public let m: Decimal
    public let s: Decimal

    public init(l: Decimal, m: Decimal, s: Decimal) {
        self.l = l
        self.m = m
        self.s = s
    }
}

/// z-score e percentil de um indicador; `nil` é o indefinido do original (`decimal.MinValue`).
public struct IndicatorScore: Sendable, Equatable {
    public let zScore: Decimal?
    public let percentile: Decimal?

    public init(zScore: Decimal?, percentile: Decimal?) {
        self.zScore = zScore
        self.percentile = percentile
    }
}

/// Resultado de um atendimento (`AnthropometricResult` do original).
public struct AnthropometricResult: Sendable, Equatable {
    public let sex: Sex?
    public let ageInDays: Int?
    public let ageInMonths: Decimal?
    public let ageRange: AgeRange
    public let weight: Decimal?
    public let lengthOrHeight: Decimal?
    public let adjustedLengthOrHeight: Decimal?
    public let isLength: Bool
    public let weightForAge: IndicatorScore
    public let lengthOrHeightForAge: IndicatorScore
    public let bmiForAge: IndicatorScore

    public init(
        sex: Sex?, ageInDays: Int?, ageInMonths: Decimal?, ageRange: AgeRange,
        weight: Decimal?, lengthOrHeight: Decimal?, adjustedLengthOrHeight: Decimal?, isLength: Bool,
        weightForAge: IndicatorScore, lengthOrHeightForAge: IndicatorScore, bmiForAge: IndicatorScore
    ) {
        self.sex = sex
        self.ageInDays = ageInDays
        self.ageInMonths = ageInMonths
        self.ageRange = ageRange
        self.weight = weight
        self.lengthOrHeight = lengthOrHeight
        self.adjustedLengthOrHeight = adjustedLengthOrHeight
        self.isLength = isLength
        self.weightForAge = weightForAge
        self.lengthOrHeightForAge = lengthOrHeightForAge
        self.bmiForAge = bmiForAge
    }

    public func score(_ indicator: Indicator) -> IndicatorScore {
        switch indicator {
        case .weightForAge: weightForAge
        case .lengthOrHeightForAge: lengthOrHeightForAge
        case .bmiForAge: bmiForAge
        }
    }
}
