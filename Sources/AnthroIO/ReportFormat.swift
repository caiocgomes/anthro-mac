import AnthroAnalysis
import Foundation

/// Números e IC no formato do Windows em pt-BR (`decimal.ToString()` e `CIToString`, design D9).
public enum ReportFormat {
    /// Vírgula decimal, sem zeros à direita; `nil` (o `decimal.MinValue` do original) vira um espaço.
    public static func number(_ value: Decimal?) -> String {
        guard let value else { return " " }
        return "\(value)".replacingOccurrences(of: ".", with: ",")
    }

    /// `CIToString`: cluster único "(., .)"; indisponível ou não calculado "(-, -)"; senão "(baixo%, alto%)".
    public static func interval(_ ci: ConfidenceInterval) -> String {
        switch ci {
        case .interval(let low, let high): "(\(number(low))%, \(number(high))%)"
        case .singleCluster: "(., .)"
        case .unavailable, .notComputed: "(-, -)"
        }
    }
}
