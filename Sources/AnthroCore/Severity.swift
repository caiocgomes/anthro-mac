import Foundation

public enum Severity: Sendable {
    case normal
    case moderate
    case high
    case extreme
    case undefined
}

/// Faixas de cor de `IndicatorDisplayPanel.SetZLabelColor`: verde, dourado, laranja-vermelho, preto.
public enum SeverityClassifier {
    public static func severity(_ z: Decimal?) -> Severity {
        guard let z else { return .undefined }
        let magnitude = abs(z)
        if magnitude < 1 { return .normal }
        if magnitude < 2 { return .moderate }
        if magnitude < 3 { return .high }
        return .extreme
    }
}
