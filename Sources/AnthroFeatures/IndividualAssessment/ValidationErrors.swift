public enum ChildValidationError: Error, Equatable {
    case sexRequired
}

public enum VisitValidationError: Error, Equatable {
    case duplicateDate
    case invalidMeasurement
}

public enum ParentValidationError: Error, Equatable {
    case invalidMeasurement
}
