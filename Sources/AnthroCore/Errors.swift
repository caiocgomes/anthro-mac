public enum AnthroError: Error, Equatable {
    case birthAfterVisit
}

public enum ReferenceDataError: Error, Equatable {
    case missingResource(String)
    case malformedRow(file: String, line: Int)
    case gap(indicator: Indicator, sex: Sex, age: Int)
}
