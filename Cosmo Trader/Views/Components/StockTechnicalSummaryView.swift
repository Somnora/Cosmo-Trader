import SwiftUI

struct StockTechnicalSummaryView: View {
    let summary: StockTechnicalSummary?
    let isLoading: Bool
    let refreshAction: () async -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header

            if isLoading && summary == nil {
                loadingState
            } else if let summary, summary.canShowNumericMetrics {
                metricContent(summary)
            } else {
                unavailableState(summary)
            }
        }
        .accessibilityIdentifier("stockDetail.technicalSummary")
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 10) {
            Image(systemName: "waveform.path.ecg")
                .foregroundColor(CosmicTheme.nebulaBlue)

            VStack(alignment: .leading, spacing: 2) {
                Text("TECHNICAL CONTEXT")
                    .font(TerminalFont.data(12, weight: .semibold))
                    .foregroundColor(CosmicTheme.textPrimary)

                Text("Provider-backed technical lens")
                    .font(TerminalFont.data(10))
                    .foregroundColor(CosmicTheme.textMuted)
            }

            Spacer()

            if let summary {
                DataSourceIndicator(provenance: summary.provenance, size: .compact)
            }
        }
    }

    private var loadingState: some View {
        HStack(spacing: 10) {
            ProgressView()
                .scaleEffect(0.75)
                .tint(CosmicTheme.gold)

            Text("Loading provider-backed candles...")
                .font(TerminalFont.data(11))
                .foregroundColor(CosmicTheme.textSecondary)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(CosmicTheme.cardBackground.opacity(0.65))
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(CosmicTheme.borderDim, lineWidth: 0.75)
        )
    }

    private func metricContent(_ summary: StockTechnicalSummary) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                metadataChip(summary.freshnessLabel)
                metadataChip("Completeness: \(summary.completeness.label)")
            }

            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 10),
                    GridItem(.flexible(), spacing: 10)
                ],
                spacing: 10
            ) {
                metricCard(
                    title: "TREND",
                    value: movingAverageText(summary),
                    detail: summary.trendContext
                )
                metricCard(
                    title: "MOMENTUM",
                    value: summary.rsi14.map { String(format: "RSI %.0f", $0) } ?? "Needs 15 candles",
                    detail: summary.momentumContext
                )
                metricCard(
                    title: "VOLUME",
                    value: summary.volumeRatio20.map { String(format: "%.2fx 20D", $0) } ?? "Needs volume",
                    detail: summary.volumeContext
                )
                metricCard(
                    title: "VOLATILITY",
                    value: summary.averageAbsoluteMove20.map { String(format: "%.2f%% avg", $0) } ?? "Needs 21 candles",
                    detail: summary.volatilityContext
                )
            }

            rangePanel(summary)

            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "info.circle")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(CosmicTheme.textMuted)

                Text("\(summary.explanation) \(StockTechnicalSummary.disclaimer)")
                    .font(TerminalFont.data(10))
                    .foregroundColor(CosmicTheme.textSecondary)
                    .lineSpacing(3)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(CosmicTheme.cardBackground.opacity(0.6))
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(CosmicTheme.borderDim, lineWidth: 0.75)
            )
        }
    }

    private func unavailableState(_ summary: StockTechnicalSummary?) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "chart.xyaxis.line")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(CosmicTheme.textMuted)

                VStack(alignment: .leading, spacing: 5) {
                    Text(StockTechnicalSummary.unavailableTitle)
                        .font(TerminalFont.data(13, weight: .semibold))
                        .foregroundColor(CosmicTheme.textPrimary)

                    Text(summary?.unavailableDetail ?? "Technical context will appear when provider-backed history is available.")
                        .font(TerminalFont.data(11))
                        .foregroundColor(CosmicTheme.textSecondary)
                        .lineSpacing(3)
                }
            }

            if let summary {
                HStack(spacing: 8) {
                    metadataChip(summary.freshnessLabel)
                    metadataChip("Completeness: \(summary.completeness.label)")
                }
            }

            Button {
                Task { await refreshAction() }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.clockwise")
                    Text(isLoading ? "LOADING HISTORY" : "REFRESH HISTORY")
                        .font(TerminalFont.data(11, weight: .semibold))
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .tint(CosmicTheme.gold)
            .disabled(isLoading)
            .accessibilityIdentifier("stockDetail.technicalSummary.refreshHistory")

            Text(StockTechnicalSummary.disclaimer)
                .font(TerminalFont.data(10))
                .foregroundColor(CosmicTheme.textMuted)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(CosmicTheme.cardBackground.opacity(0.65))
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(CosmicTheme.borderDim, lineWidth: 0.75)
        )
    }

    private func metricCard(title: String, value: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(TerminalFont.data(9, weight: .semibold))
                .foregroundColor(CosmicTheme.textMuted)

            Text(value)
                .font(TerminalFont.data(15, weight: .bold))
                .foregroundColor(CosmicTheme.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.75)

            Text(detail)
                .font(TerminalFont.data(10))
                .foregroundColor(CosmicTheme.textSecondary)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .frame(maxWidth: .infinity, minHeight: 118, alignment: .topLeading)
        .background(CosmicTheme.cardBackground.opacity(0.7))
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(CosmicTheme.borderDim, lineWidth: 0.75)
        )
    }

    private func rangePanel(_ summary: StockTechnicalSummary) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("RANGE / LEVELS")
                .font(TerminalFont.data(9, weight: .semibold))
                .foregroundColor(CosmicTheme.textMuted)

            HStack(spacing: 10) {
                levelItem("20D RANGE", value: rangeText(summary))
                levelItem("SUPPORT", value: summary.supportCandidate.map(StockTechnicalAnalysisService.formatPrice) ?? "Needs 60 candles")
                levelItem("RESISTANCE", value: summary.resistanceCandidate.map(StockTechnicalAnalysisService.formatPrice) ?? "Needs 60 candles")
            }

            Text(summary.rangeContext)
                .font(TerminalFont.data(10))
                .foregroundColor(CosmicTheme.textSecondary)
                .lineSpacing(2)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(CosmicTheme.cardBackground.opacity(0.7))
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(CosmicTheme.borderDim, lineWidth: 0.75)
        )
    }

    private func levelItem(_ title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(TerminalFont.data(8, weight: .semibold))
                .foregroundColor(CosmicTheme.textMuted)
                .lineLimit(1)
                .minimumScaleFactor(0.75)

            Text(value)
                .font(TerminalFont.data(11, weight: .bold))
                .foregroundColor(CosmicTheme.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.65)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func metadataChip(_ text: String) -> some View {
        Text(text)
            .font(TerminalFont.data(9, weight: .semibold))
            .foregroundColor(CosmicTheme.textSecondary)
            .lineLimit(1)
            .minimumScaleFactor(0.75)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Capsule().fill(CosmicTheme.cardBackground.opacity(0.75)))
            .overlay(
                Capsule()
                    .stroke(CosmicTheme.borderDim, lineWidth: 0.75)
            )
    }

    private func movingAverageText(_ summary: StockTechnicalSummary) -> String {
        guard let ma20 = summary.movingAverage20,
              let ma50 = summary.movingAverage50 else {
            return "Needs 50 candles"
        }
        return "20D \(StockTechnicalAnalysisService.formatPrice(ma20)) / 50D \(StockTechnicalAnalysisService.formatPrice(ma50))"
    }

    private func rangeText(_ summary: StockTechnicalSummary) -> String {
        guard let low = summary.recentRangeLow,
              let high = summary.recentRangeHigh else {
            return "Unavailable"
        }
        return "\(StockTechnicalAnalysisService.formatPrice(low)) - \(StockTechnicalAnalysisService.formatPrice(high))"
    }
}
