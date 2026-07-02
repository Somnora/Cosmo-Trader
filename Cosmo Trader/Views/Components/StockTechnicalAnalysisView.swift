import SwiftUI

struct StockTechnicalAnalysisView: View {
    let summary: StockTechnicalSummary
    let isLoading: Bool
    let refreshAction: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header

            if isLoading {
                loadingState
            } else if let metrics = summary.metrics {
                metricContent(metrics)
            } else {
                unavailableContent
            }

            Text("Historical technical context only. Not financial advice.")
                .font(TerminalFont.data(8))
                .foregroundColor(CosmicTheme.textMuted)
        }
        .accessibilityIdentifier("stock.technicalAnalysis")
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(CosmicTheme.gold)

            VStack(alignment: .leading, spacing: 3) {
                Text("TECHNICAL LENS")
                    .font(TerminalFont.data(12, weight: .semibold))
                    .foregroundColor(CosmicTheme.textPrimary)

                Text("\(summary.candleCount) provider-shaped candles checked")
                    .font(TerminalFont.data(9))
                    .foregroundColor(CosmicTheme.textMuted)
            }

            Spacer(minLength: 8)

            DataSourceIndicator(provenance: summary.provenance, size: .compact)
                .fixedSize()
        }
    }

    private var loadingState: some View {
        HStack(spacing: 10) {
            ProgressView()
                .scaleEffect(0.7)
                .tint(CosmicTheme.gold)

            Text("Loading provider-backed technical context...")
                .font(TerminalFont.data(11))
                .foregroundColor(CosmicTheme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(CosmicTheme.secondaryBackground.opacity(0.7))
    }

    private func metricContent(_ metrics: StockTechnicalMetrics) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(summary.headline)
                .font(TerminalFont.data(12, weight: .semibold))
                .foregroundColor(CosmicTheme.textPrimary)
                .lineSpacing(3)

            Text(summary.explanation)
                .font(TerminalFont.data(10))
                .foregroundColor(CosmicTheme.textSecondary)
                .lineSpacing(3)

            VStack(spacing: 8) {
                technicalRow(
                    title: "Trend context",
                    value: movingAverageText(metrics)
                )

                technicalRow(
                    title: "Momentum context",
                    value: rsiText(metrics.rsi14)
                )

                technicalRow(
                    title: "Volume context",
                    value: volumeText(metrics.volumeTrend)
                )

                technicalRow(
                    title: "Volatility context",
                    value: volatilityText(metrics.volatility)
                )

                technicalRow(
                    title: "Recent range",
                    value: rangeText(metrics.recentRange)
                )

                technicalRow(
                    title: "Support/resistance",
                    value: supportResistanceText(metrics.supportResistance)
                )
            }
        }
    }

    private var unavailableContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(summary.headline)
                .font(TerminalFont.data(12, weight: .semibold))
                .foregroundColor(CosmicTheme.textPrimary)

            Text(summary.explanation)
                .font(TerminalFont.data(10))
                .foregroundColor(CosmicTheme.textSecondary)
                .lineSpacing(3)

            VStack(spacing: 8) {
                technicalRow(title: "Trend context", value: "Waiting for complete provider history")
                technicalRow(title: "Momentum context", value: "Metrics hidden until candles pass gates")
                technicalRow(title: "Volume context", value: "Provider volume required")
                technicalRow(title: "Data quality", value: "\(summary.provenance.shortLabel) | \(summary.completeness.label)")
            }

            if let refreshAction {
                Button(action: refreshAction) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 11, weight: .bold))

                        Text("REFRESH HISTORY")
                            .font(TerminalFont.data(10, weight: .bold))
                            .tracking(1)
                    }
                    .foregroundColor(CosmicTheme.terminalBlack)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(CosmicTheme.gold)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("stock.technicalAnalysis.refreshHistory")
            }
        }
    }

    private func technicalRow(title: String, value: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(title.uppercased())
                .font(TerminalFont.data(8, weight: .bold))
                .foregroundColor(CosmicTheme.textMuted)
                .tracking(0.8)
                .frame(width: 112, alignment: .leading)

            Text(value)
                .font(TerminalFont.data(10))
                .foregroundColor(CosmicTheme.textSecondary)
                .lineSpacing(2)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(10)
        .background(CosmicTheme.secondaryBackground.opacity(0.65))
        .overlay(
            RoundedRectangle(cornerRadius: 5)
                .stroke(CosmicTheme.borderDim, lineWidth: 0.5)
        )
    }

    private func movingAverageText(_ metrics: StockTechnicalMetrics) -> String {
        var values: [String] = []

        if let average20 = metrics.movingAverage20 {
            values.append("20D \(formatPrice(average20))")
        }
        if let average50 = metrics.movingAverage50 {
            values.append("50D \(formatPrice(average50))")
        }
        if let average200 = metrics.movingAverage200 {
            values.append("200D \(formatPrice(average200))")
        } else {
            values.append("200D needs 200 candles")
        }

        return values.joined(separator: " | ")
    }

    private func rsiText(_ rsi: Double?) -> String {
        guard let rsi else { return "Needs enough provider candles" }

        let context: String
        switch rsi {
        case 70...:
            context = "elevated"
        case ..<30:
            context = "low"
        default:
            context = "balanced"
        }

        return "RSI 14D \(String(format: "%.1f", rsi)) | \(context) context"
    }

    private func volumeText(_ trend: StockVolumeTrend?) -> String {
        guard let trend else { return "Provider volume unavailable" }
        return "\(trend.label) | \(formatPercent(trend.percentDifference)) vs prior 10 candles"
    }

    private func volatilityText(_ volatility: StockVolatilityContext?) -> String {
        guard let volatility else { return "Needs at least 20 return observations" }
        return "\(volatility.label) | \(String(format: "%.1f%%", volatility.annualizedPercent)) annualized from \(volatility.sampleDays) observations"
    }

    private func rangeText(_ range: StockRecentRange?) -> String {
        guard let range else { return "Needs 20 provider candles" }
        return "\(range.sampleDays)D \(formatPrice(range.low)) to \(formatPrice(range.high))"
    }

    private func supportResistanceText(_ levels: StockSupportResistance?) -> String {
        guard let levels else { return "Needs 60 provider candles" }
        return "Support candidate \(formatPrice(levels.supportCandidate)) | resistance candidate \(formatPrice(levels.resistanceCandidate))"
    }

    private func formatPrice(_ value: Double) -> String {
        "$\(String(format: "%.2f", value))"
    }

    private func formatPercent(_ value: Double) -> String {
        let prefix = value > 0 ? "+" : ""
        return "\(prefix)\(String(format: "%.1f%%", value))"
    }
}
