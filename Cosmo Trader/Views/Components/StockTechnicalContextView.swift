import SwiftUI

struct StockTechnicalContextView: View {
    let summary: StockTechnicalSummary?
    let isLoading: Bool
    let onRefresh: () -> Void

    private var resolvedSummary: StockTechnicalSummary {
        summary ?? .unavailable(
            symbol: "",
            reason: "Provider-backed daily candles have not loaded yet."
        )
    }

    var body: some View {
        let summary = resolvedSummary

        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Rectangle()
                    .fill(CosmicTheme.border)
                    .frame(width: 20, height: 1)

                Text("TECHNICAL CONTEXT")
                    .font(TerminalFont.data(10))
                    .foregroundColor(CosmicTheme.textMuted)
                    .tracking(1)

                Spacer(minLength: 8)

                DataSourceIndicator(provenance: summary.provenance, size: .compact)
            }

            Text(summary.sourceLine)
                .font(TerminalFont.data(10))
                .foregroundColor(CosmicTheme.textSecondary)
                .lineSpacing(2)

            if isLoading {
                loadingState
            } else if summary.canShowNumericMetrics {
                metricsContent(summary)
            } else {
                unavailableContent(summary)
            }
        }
    }

    private var loadingState: some View {
        HStack(spacing: 8) {
            ProgressView()
                .scaleEffect(0.7)
                .tint(CosmicTheme.gold)

            Text("Loading provider-backed daily candles...")
                .font(TerminalFont.data(11))
                .foregroundColor(CosmicTheme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(CosmicTheme.cardBackground.opacity(0.6))
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(CosmicTheme.borderDim, lineWidth: 0.75)
        )
    }

    private func metricsContent(_ summary: StockTechnicalSummary) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 10),
                    GridItem(.flexible(), spacing: 10)
                ],
                alignment: .leading,
                spacing: 10
            ) {
                ForEach(summary.metrics) { metric in
                    metricCard(metric)
                }
            }

            if let rangeMetric = summary.rangeMetric {
                detailRow(rangeMetric)
            }

            if let supportResistanceMetric = summary.supportResistanceMetric {
                detailRow(supportResistanceMetric)
            }

            Text(summary.explanation)
                .font(TerminalFont.data(10))
                .foregroundColor(CosmicTheme.textSecondary)
                .lineSpacing(2)

            Text(summary.disclaimer)
                .font(TerminalFont.data(9, weight: .semibold))
                .foregroundColor(CosmicTheme.textMuted)
                .lineSpacing(2)
        }
    }

    private func unavailableContent(_ summary: StockTechnicalSummary) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Technical context unavailable")
                .font(TerminalFont.data(12, weight: .semibold))
                .foregroundColor(CosmicTheme.textPrimary)

            Text(summary.explanation)
                .font(TerminalFont.data(10))
                .foregroundColor(CosmicTheme.textSecondary)
                .lineSpacing(3)

            Text(summary.disclaimer)
                .font(TerminalFont.data(9, weight: .semibold))
                .foregroundColor(CosmicTheme.textMuted)
                .lineSpacing(2)

            Button(action: onRefresh) {
                HStack(spacing: 7) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 11, weight: .semibold))

                    Text("LOAD PROVIDER HISTORY")
                        .font(TerminalFont.data(10, weight: .bold))
                        .tracking(0.8)
                }
                .foregroundColor(CosmicTheme.gold)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(CosmicTheme.gold.opacity(0.12))
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(CosmicTheme.gold.opacity(0.35), lineWidth: 0.8)
                )
            }
            .buttonStyle(.plain)
            .disabled(isLoading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(CosmicTheme.cardBackground.opacity(0.6))
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(CosmicTheme.borderDim, lineWidth: 0.75)
        )
    }

    private func metricCard(_ metric: StockTechnicalMetric) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(metric.label.uppercased())
                .font(TerminalFont.data(8, weight: .semibold))
                .foregroundColor(CosmicTheme.textMuted)
                .tracking(0.6)
                .lineLimit(1)
                .minimumScaleFactor(0.75)

            Text(metric.value)
                .font(TerminalFont.price(15, weight: .semibold))
                .foregroundColor(CosmicTheme.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.75)

            Text(metric.detail)
                .font(TerminalFont.data(9))
                .foregroundColor(CosmicTheme.textSecondary)
                .lineSpacing(2)
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(10)
        .frame(maxWidth: .infinity, minHeight: 112, alignment: .topLeading)
        .background(CosmicTheme.cardBackground.opacity(0.6))
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(CosmicTheme.borderDim, lineWidth: 0.75)
        )
    }

    private func detailRow(_ metric: StockTechnicalMetric) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(metric.label.uppercased())
                .font(TerminalFont.data(9, weight: .semibold))
                .foregroundColor(CosmicTheme.textMuted)
                .tracking(0.6)

            Text(metric.value)
                .font(TerminalFont.price(13, weight: .semibold))
                .foregroundColor(CosmicTheme.textPrimary)

            Text(metric.detail)
                .font(TerminalFont.data(10))
                .foregroundColor(CosmicTheme.textSecondary)
                .lineSpacing(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(CosmicTheme.cardBackground.opacity(0.45))
    }
}
