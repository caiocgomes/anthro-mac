import AnthroCore
import Foundation

/// Painel de resultados compartilhado pela Calculadora, Avaliação individual e Inquérito, como
/// `IndicatorDisplayPanel.DisplayResult` e `SetZLabelColor` (design D3).
public enum IndicatorPanel {
    public static func rows(for result: AnthropometricResult) -> [IndicatorPanelRow] {
        Indicator.allCases.map { indicator in
            let score = result.score(indicator)
            return IndicatorPanelRow(
                indicator: indicator,
                title: L10n.Indicators.title(indicator, isLength: result.isLength),
                zScoreText: ClinicalFormat.string(score.zScore, places: 2),
                percentileText: ClinicalFormat.string(score.percentile, places: 1),
                severity: SeverityClassifier.severity(score.zScore),
                percentileBarValue: percentileBarValue(percentile: score.percentile, zScore: score.zScore)
            )
        }
    }

    /// Percentil positivo arredondado ao inteiro par mais próximo (`Convert.ToInt32`); sem percentil,
    /// 100 para z acima de 3, 50 para z indefinido e 0 nos demais casos.
    public static func percentileBarValue(percentile: Decimal?, zScore: Decimal?) -> Int {
        if let percentile, percentile > 0 {
            var input = percentile
            var rounded = Decimal()
            NSDecimalRound(&rounded, &input, 0, .bankers)
            return NSDecimalNumber(decimal: rounded).intValue
        }
        guard let zScore else { return 50 }
        return zScore > 3 ? 100 : 0
    }
}
