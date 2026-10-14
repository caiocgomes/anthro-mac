import Foundation

public enum Severity: Sendable {
    case normal
    case moderate
    case high
    case extreme
    case undefined
}

public enum SeverityClassifier {
    public static func severity(_ z: Decimal?) -> Severity {
        .undefined
    }
}
