import Foundation

/// Opções do inquérito (`SurveyOptions` do original, design D9).
public struct SurveyOptions: Sendable, Equatable {
    public var autoIDCluster: Bool
    public var autoIDTeam: Bool
    public var autoIDRecord: Bool
    public var autoIDHousehold: Bool
    public var ageGroupBoundaries: [Int]
    public var standardsMinZ: [Decimal]
    public var standardsMaxZ: [Decimal]
    public var referenceMinZ: [Decimal]
    public var referenceMaxZ: [Decimal]

    public static let `default` = SurveyOptions(
        autoIDCluster: false, autoIDTeam: false, autoIDRecord: false, autoIDHousehold: false, ageGroupBoundaries: [],
        standardsMinZ: [], standardsMaxZ: [], referenceMinZ: [], referenceMaxZ: []
    )
}

extension SurveyOptions {
    public init(xml: String) throws {
        self = .default
    }

    public func xml() -> String {
        ""
    }

    public func zBounds(_ indicator: Indicator, range: AgeRange) -> (min: Decimal, max: Decimal)? {
        nil
    }
}

public enum SurveyOptionsError: Error, Equatable {
    case invalidXML(String)
}
