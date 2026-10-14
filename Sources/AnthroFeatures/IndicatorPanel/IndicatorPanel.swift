import AnthroCore
import Foundation

/// Painel de resultados compartilhado pela Calculadora, Avaliação individual e Inquérito.
public enum IndicatorPanel {
    public static func rows(for result: AnthropometricResult) -> [IndicatorPanelRow] {
        []
    }

    public static func percentileBarValue(percentile: Decimal?, zScore: Decimal?) -> Int {
        0
    }
}
