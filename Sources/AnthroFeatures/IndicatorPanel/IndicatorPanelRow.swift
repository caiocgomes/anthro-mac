import AnthroCore

/// Uma linha do painel de resultados (`IndicatorDisplayPanel`).
public struct IndicatorPanelRow: Sendable, Equatable {
    public let indicator: Indicator
    public let title: String
    public let zScoreText: String
    public let percentileText: String
    public let severity: Severity
    public let percentileBarValue: Int

    public init(indicator: Indicator, title: String, zScoreText: String, percentileText: String, severity: Severity, percentileBarValue: Int) {
        self.indicator = indicator
        self.title = title
        self.zScoreText = zScoreText
        self.percentileText = percentileText
        self.severity = severity
        self.percentileBarValue = percentileBarValue
    }
}
