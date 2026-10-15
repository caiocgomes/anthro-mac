import AnthroAnalysis
import Foundation

/// Números e IC no formato do Windows em pt-BR (`decimal.ToString()` e `CIToString`, design D9).
public enum ReportFormat {
    public static func number(_ value: Decimal?) -> String { "" }

    public static func interval(_ ci: ConfidenceInterval) -> String { "" }
}
