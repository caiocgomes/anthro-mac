import AnthroFeatures
import SwiftUI

/// Painel de resultados, como `IndicatorDisplayPanel`: z-score com a cor de `SetZLabelColor`, percentil e barra.
struct IndicatorPanelView: View {
    let rows: [IndicatorPanelRow]
    let onShowChart: (Indicator) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L10n.Calculator.results)
                .font(.title3.weight(.semibold))
            VStack(spacing: 0) {
                ForEach(Array(rows.enumerated()), id: \.element.indicator) { index, row in
                    if index > 0 { Divider() }
                    IndicatorRowView(row: row) { onShowChart(row.indicator) }
                }
            }
            .background(.background.secondary, in: RoundedRectangle(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(.separator))
            SeverityLegend()
        }
    }
}

private struct IndicatorRowView: View {
    let row: IndicatorPanelRow
    let onShowChart: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text(row.title).font(.headline)
                HStack(spacing: 18) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(L10n.Calculator.zScore).font(.caption).foregroundStyle(.secondary)
                        SeverityBadge(text: row.zScoreText, severity: row.severity)
                    }
                    VStack(alignment: .leading, spacing: 3) {
                        Text(L10n.Calculator.percentile).font(.caption).foregroundStyle(.secondary)
                        Text(row.percentileText).font(.body.monospacedDigit()).frame(minWidth: 48, alignment: .leading)
                    }
                    PercentileTrack(value: row.percentileBarValue)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 14)
                }
            }
            Button(action: onShowChart) {
                Image(systemName: "chart.xyaxis.line")
                    .font(.title3)
                    .frame(width: 34, height: 30)
            }
            .buttonStyle(.bordered)
            .help(L10n.Calculator.showChart)
            .accessibilityLabel("\(L10n.Calculator.showChart): \(row.title)")
        }
        .padding(14)
    }
}

/// Selo do z-score nas cores do original; `.extreme` com borda clara para o modo escuro (design D12).
struct SeverityBadge: View {
    let text: String
    let severity: Severity

    var body: some View {
        Text(text)
            .font(.body.monospacedDigit().weight(.semibold))
            .foregroundStyle(severity == .undefined ? Color.primary : .white)
            .padding(.horizontal, 10)
            .padding(.vertical, 3)
            .frame(minWidth: 64)
            .background(severity.badgeColor, in: RoundedRectangle(cornerRadius: 6))
            .overlay {
                if severity == .extreme {
                    RoundedRectangle(cornerRadius: 6).strokeBorder(Color.white.opacity(0.6))
                }
            }
    }
}

/// Barra de percentil somente leitura, como o `TrackBar` desabilitado do original, com marcas em 3, 15, 50, 85 e 97.
struct PercentileTrack: View {
    let value: Int

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            ZStack(alignment: .leading) {
                Capsule().fill(.quaternary).frame(height: 6)
                ForEach([3, 15, 50, 85, 97], id: \.self) { mark in
                    Rectangle()
                        .fill(.tertiary)
                        .frame(width: 1, height: 12)
                        .offset(x: width * CGFloat(mark) / 100)
                }
                Circle()
                    .fill(Color.accentColor)
                    .overlay(Circle().strokeBorder(.white, lineWidth: 2))
                    .frame(width: 14, height: 14)
                    .shadow(radius: 1)
                    .offset(x: width * CGFloat(min(max(value, 0), 100)) / 100 - 7)
            }
            .frame(height: 14)
        }
        .frame(height: 14)
        .accessibilityElement()
        .accessibilityLabel(L10n.Calculator.percentile)
        .accessibilityValue("\(value)")
    }
}

/// Faixas de cor do z-score: |z| < 1, < 2, < 3 e a partir de 3.
private struct SeverityLegend: View {
    var body: some View {
        HStack(spacing: 14) {
            item(.normal, "|z| < 1")
            item(.moderate, "1 a 2")
            item(.high, "2 a 3")
            item(.extreme, "≥ 3")
        }
        .font(.caption)
        .foregroundStyle(.secondary)
    }

    private func item(_ severity: Severity, _ text: String) -> some View {
        HStack(spacing: 5) {
            RoundedRectangle(cornerRadius: 3)
                .fill(severity.badgeColor)
                .overlay {
                    if severity == .extreme {
                        RoundedRectangle(cornerRadius: 3).strokeBorder(Color.white.opacity(0.6))
                    }
                }
                .frame(width: 14, height: 10)
            Text(text)
        }
    }
}

extension Severity {
    /// `Color.Green`, `Goldenrod`, `OrangeRed` e `Black` de `SetZLabelColor`.
    var badgeColor: Color {
        switch self {
        case .normal: Color(red: 0, green: 128 / 255, blue: 0)
        case .moderate: Color(red: 218 / 255, green: 165 / 255, blue: 32 / 255)
        case .high: Color(red: 1, green: 69 / 255, blue: 0)
        case .extreme: .black
        case .undefined: .clear
        }
    }
}
