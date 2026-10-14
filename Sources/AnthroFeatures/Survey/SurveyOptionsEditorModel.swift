import AnthroCore
import Foundation
import Observation

public enum SurveyOptionsEditorError: Error, Equatable {
    case tooFewAgeGroups
    case inconsistentAgeGroups
    case invalidZBounds
}

/// Editor das opções do inquérito (`NSOptionsDialog`, design D10); só altera o inquérito em `apply()`.
@MainActor
@Observable
public final class SurveyOptionsEditorModel {
    public var autoIDCluster: Bool = false
    public var autoIDTeam: Bool = false
    public var autoIDRecord: Bool = false
    public var autoIDHousehold: Bool = false
    public private(set) var lowerBounds: [Int] = []
    public var lastUpperBound: Int = 0

    public init(options: SurveyOptions) {}

    public var ageGroups: [AgeGroup] { [] }

    public func setLowerBound(_ value: Int, at index: Int) {}

    public func addAgeGroup() {}

    public func removeAgeGroup(at index: Int) {}

    public func zBound(_ indicator: Indicator, range: AgeRange, isMax: Bool) -> Decimal { 0 }

    public func setZBound(text: String, indicator: Indicator, range: AgeRange, isMax: Bool) {}

    public func zBoundOutcome(_ indicator: Indicator, range: AgeRange, isMax: Bool) -> MeasurementInput.Outcome { .empty }

    public func resetToDefaults() {}

    public func apply() throws -> SurveyOptions { .default }
}
