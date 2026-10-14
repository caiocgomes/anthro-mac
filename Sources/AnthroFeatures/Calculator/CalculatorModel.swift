import AnthroCore
import Foundation
import Observation

/// Calculadora antropométrica, port de `ACMain` (design D1 a D5).
@MainActor
@Observable
public final class CalculatorModel {
    public private(set) var dateOfBirth: Date = Date(timeIntervalSince1970: 0)
    public private(set) var dateOfVisit: Date = Date(timeIntervalSince1970: 0)
    public private(set) var isApproximateBirthDate: Bool = false
    public private(set) var sex: Sex = .girl
    public private(set) var weight: Decimal? = nil
    public private(set) var lengthOrHeight: Decimal? = nil
    public private(set) var measuredRecumbent: Bool = false
    public private(set) var hasOedema: Bool = false
    public private(set) var result: AnthropometricResult
    public private(set) var weightIssue: MeasurementInput.Outcome? = nil
    public private(set) var lengthOrHeightIssue: MeasurementInput.Outcome? = nil

    @ObservationIgnored private let tables: GrowthReferenceTables

    public init(engine: AnthroEngine, tables: GrowthReferenceTables, settings: AppSettings, today: Date,
                randomDay: @escaping (Range<Int>) -> Int = { Int.random(in: $0) }) {
        self.tables = tables
        result = engine.result(ageInDays: nil, ageInMonths: nil, sex: nil, weight: nil, lengthOrHeight: nil,
                               measuredRecumbent: false, hasOedema: false)
    }

    public var ageText: String { "" }
    public var isMeasurementChoiceEnabled: Bool { false }
    public var bmiText: String { "" }
    public var rows: [IndicatorPanelRow] { [] }

    public func setDateOfBirth(_ date: Date) {}
    public func setDateOfVisit(_ date: Date) {}
    public func setApproximateBirthDate(_ isOn: Bool) {}
    public func setSex(_ sex: Sex) {}
    public func setWeightText(_ text: String) {}
    public func setLengthOrHeightText(_ text: String) {}
    public func setMeasuredRecumbent(_ isOn: Bool) {}
    public func setHasOedema(_ isOn: Bool) {}

    public func nextFocus(after field: CalculatorField) -> CalculatorField? {
        nil
    }

    public func makeChart(for indicator: Indicator) -> GrowthChartModel {
        GrowthChartModel(results: [result], currentIndex: 0, indicator: .weightForAge, tables: tables)
    }
}
