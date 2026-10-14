/// Condições do `NSFilterDialog`.
public enum FilterCondition: Int, CaseIterable, Sendable {
    case equal, notEqual, greaterOrEqual, lessOrEqual, range

    public var symbol: String {
        ""
    }
}

public struct SurveyFilter: Sendable, Equatable {
    public var column: SurveyTableColumn
    public var condition: FilterCondition
    public var value1: String
    public var value2: String

    public init(column: SurveyTableColumn, condition: FilterCondition, value1: String, value2: String = "") {
        self.column = column
        self.condition = condition
        self.value1 = value1
        self.value2 = value2
    }
}

/// Decisão de manter uma célula, como `NSMain.FilterRecords` (design D7).
public enum SurveyFilterEvaluator {
    public static func keeps(cellText: String, condition: FilterCondition, value1: String, value2: String) -> Bool {
        true
    }
}
