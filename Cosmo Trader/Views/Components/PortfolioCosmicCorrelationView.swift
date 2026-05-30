import SwiftUI

struct PortfolioCosmicCorrelationView: View {
    let viewModel: PortfolioCorrelationViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            contextRows
            content

            Text("Portfolio lens only. Correlation does not imply causation and this is not financial advice.")
                .font(TerminalFont.data(9))
                .foregroundColor(CosmicTheme.textMuted)
                .lineSpacing(3)
        }
        .padding(12)
        .background(CosmicTheme.terminalBlack)
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(CosmicTheme.borderDim, lineWidth: 0.75)
        )
    }

    private var header: some View {
        HStack(spacing: 8) {
            Image(systemName: "chart.pie.fill")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(CosmicTheme.gold)

            Text("PORTFOLIO COSMIC CORRELATION")
                .font(TerminalFont.data(11, weight: .bold))
                .foregroundColor(CosmicTheme.textPrimary)
                .tracking(1)
                .lineLimit(1)
                .minimumScaleFactor(0.75)

            Spacer()

            DataSourceIndicator(provenance: viewModel.historicalPriceProvenance, size: .compact)
        }
    }

    private var contextRows: some View {
        VStack(alignment: .leading, spacing: 5) {
            contextRow(label: "CHECKED", value: checkedEventLabel)
            contextRow(label: "WINDOW", value: viewModel.windowLabel)
            contextRow(label: "COVERAGE", value: coverageLabel)
            contextRow(label: "SOURCE", value: viewModel.historicalPriceProvenance.detailText)
        }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading {
            loadingState
        } else if viewModel.summaries.isEmpty {
            unavailableState("Add initialized holdings before portfolio correlation context can be calculated.")
        } else {
            VStack(spacing: 8) {
                ForEach(viewModel.summaries) { summary in
                    summaryCard(summary)
                }
            }

            if !viewModel.unavailableHoldings.isEmpty {
                unavailableHoldingsNote
            }
        }
    }

    private func contextRow(label: String, value: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(label)
                .font(TerminalFont.data(8, weight: .bold))
                .foregroundColor(CosmicTheme.textMuted)
                .tracking(0.5)
                .frame(width: 62, alignment: .leading)

            Text(value)
                .font(TerminalFont.data(10))
                .foregroundColor(CosmicTheme.textSecondary)
                .lineLimit(2)
                .minimumScaleFactor(0.75)
        }
    }

    private var loadingState: some View {
        HStack(spacing: 10) {
            ProgressView()
                .tint(CosmicTheme.gold)
            Text("Loading provider-backed portfolio history")
                .font(TerminalFont.data(10))
                .foregroundColor(CosmicTheme.textSecondary)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(CosmicTheme.cardBackground.opacity(0.55))
    }

    private func unavailableState(_ message: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "info.circle")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(CosmicTheme.textMuted)
                .padding(.top, 1)

            Text(message)
                .font(TerminalFont.data(10))
                .foregroundColor(CosmicTheme.textMuted)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(CosmicTheme.cardBackground.opacity(0.55))
    }

    private func summaryCard(_ summary: PortfolioCosmicCorrelationSummary) -> some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack(spacing: 7) {
                Image(systemName: summary.eventType.iconSystemName)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(summary.eventType.overlayColor)

                Text(summary.eventName.uppercased())
                    .font(TerminalFont.data(10, weight: .bold))
                    .foregroundColor(CosmicTheme.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)

                Spacer()

                confidenceBadge(summary.confidence)
            }

            HStack(spacing: 8) {
                smallStat(label: "EVENTS", value: "\(summary.eventCount)")
                smallStat(label: "SAMPLE", value: "\(summary.sampleSize)")
                smallStat(label: "INCLUDED", value: percentRate(summary.includedPortfolioWeight))
            }

            if summary.displayMode == .marketBackedResult {
                marketBackedMetrics(summary)
            } else {
                Text(summary.disclaimer)
                    .font(TerminalFont.data(9))
                    .foregroundColor(CosmicTheme.textMuted)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if !summary.affectedHoldings.isEmpty {
                affectedHoldingsRow(summary.affectedHoldings)
            }

            HStack {
                Text(summary.provenance.detailText)
                    .font(TerminalFont.data(8))
                    .foregroundColor(CosmicTheme.textMuted)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                Spacer()
                DataSourceIndicator(provenance: summary.provenance, size: .compact)
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(CosmicTheme.cardBackground.opacity(0.5))
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(CosmicTheme.borderDim, lineWidth: 0.75)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel(for: summary))
    }

    private func marketBackedMetrics(_ summary: PortfolioCosmicCorrelationSummary) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                metricColumn(
                    label: "AVG PORT",
                    value: percent(summary.averagePortfolioReturn),
                    color: color(for: summary.averagePortfolioReturn),
                    alignment: .leading
                )

                Spacer(minLength: 4)

                metricColumn(
                    label: "WIN",
                    value: percentRate(summary.winRate),
                    color: CosmicTheme.textPrimary,
                    alignment: .trailing
                )
            }

            HStack(alignment: .firstTextBaseline, spacing: 8) {
                smallStat(label: "MEDIAN", value: percent(summary.medianPortfolioReturn))
                smallStat(label: "BASE", value: percent(summary.baselinePortfolioReturn))
                smallStat(label: "MAX DD", value: percent(summary.maxDrawdown.map { -abs($0) }))
            }

            Text(summary.disclaimer)
                .font(TerminalFont.data(9))
                .foregroundColor(CosmicTheme.textMuted)
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func affectedHoldingsRow(_ holdings: [PortfolioCorrelationHoldingImpact]) -> some View {
        let topHoldings = holdings.prefix(4)
            .map { "\($0.symbol) \(percentRate($0.portfolioWeight))" }
            .joined(separator: "  ")

        return HStack(alignment: .firstTextBaseline, spacing: 7) {
            Text("INCLUDED")
                .font(TerminalFont.data(8, weight: .bold))
                .foregroundColor(CosmicTheme.textMuted)
                .tracking(0.5)
            Text(topHoldings)
                .font(TerminalFont.data(9))
                .foregroundColor(CosmicTheme.textSecondary)
                .lineLimit(2)
                .minimumScaleFactor(0.75)
        }
    }

    private var unavailableHoldingsNote: some View {
        let symbols = viewModel.unavailableHoldings.prefix(6).joined(separator: ", ")
        let suffix = viewModel.unavailableHoldings.count > 6 ? " +" : ""
        return unavailableState("Excluded from this lens: \(symbols)\(suffix). Provider-backed historical prices were unavailable for those holdings.")
    }

    private func metricColumn(label: String, value: String, color: Color, alignment: HorizontalAlignment) -> some View {
        VStack(alignment: alignment, spacing: 2) {
            Text(value)
                .font(TerminalFont.price(15))
                .foregroundColor(color)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(label)
                .font(TerminalFont.data(8, weight: .bold))
                .foregroundColor(CosmicTheme.textMuted)
                .tracking(0.5)
        }
    }

    private func smallStat(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(TerminalFont.data(10, weight: .bold))
                .foregroundColor(CosmicTheme.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            Text(label)
                .font(TerminalFont.data(8, weight: .bold))
                .foregroundColor(CosmicTheme.textMuted)
                .tracking(0.5)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func confidenceBadge(_ confidence: CorrelationConfidence) -> some View {
        Text(confidence.displayName.uppercased())
            .font(TerminalFont.data(8, weight: .bold))
            .foregroundColor(confidenceColor(confidence))
            .lineLimit(1)
            .minimumScaleFactor(0.65)
            .padding(.horizontal, 5)
            .padding(.vertical, 2)
            .background(confidenceColor(confidence).opacity(0.12))
            .overlay(
                RoundedRectangle(cornerRadius: 3)
                    .stroke(confidenceColor(confidence).opacity(0.35), lineWidth: 0.5)
            )
    }

    private var checkedEventLabel: String {
        viewModel.checkedEventKinds.map(\.displayName).joined(separator: ", ")
    }

    private var coverageLabel: String {
        "\(percentRate(viewModel.includedPortfolioWeight)) included / \(percentRate(viewModel.excludedPortfolioWeight)) excluded"
    }

    private func percent(_ value: Double?) -> String {
        guard let value, value.isFinite else { return "N/A" }
        let sign = value >= 0 ? "+" : ""
        return String(format: "%@%.1f%%", sign, value)
    }

    private func percentRate(_ value: Double?) -> String {
        guard let value, value.isFinite else { return "N/A" }
        return String(format: "%.0f%%", value * 100)
    }

    private func color(for value: Double?) -> Color {
        guard let value else { return CosmicTheme.textMuted }
        return value >= 0 ? CosmicTheme.positive : CosmicTheme.negative
    }

    private func confidenceColor(_ confidence: CorrelationConfidence) -> Color {
        switch confidence {
        case .strong:
            return CosmicTheme.positive
        case .moderate:
            return CosmicTheme.gold
        case .thin:
            return CosmicTheme.accentBlue
        case .insufficient, .unavailable:
            return CosmicTheme.textMuted
        }
    }

    private func accessibilityLabel(for summary: PortfolioCosmicCorrelationSummary) -> String {
        if summary.displayMode == .marketBackedResult {
            return "\(summary.eventName), \(summary.sampleSize) portfolio observations, average portfolio return \(percent(summary.averagePortfolioReturn)), win rate \(percentRate(summary.winRate)). Historical context only, not financial advice."
        }
        return "\(summary.eventName), \(summary.sampleSize) portfolio observations. \(summary.disclaimer)"
    }
}

struct PortfolioCorrelationLockedCard: View {
    @State private var showUpgradeSheet = false

    var body: some View {
        Button {
            AnalyticsService.shared.trackPaywallViewed(source: "portfolio_cosmic_correlation")
            showUpgradeSheet = true
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "chart.pie.fill")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(CosmicTheme.gold)

                    Text("PORTFOLIO COSMIC CORRELATION")
                        .font(TerminalFont.data(12, weight: .bold))
                        .foregroundColor(CosmicTheme.textPrimary)
                        .tracking(1)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)

                    Spacer()

                    Text("ORACLE")
                        .font(TerminalFont.data(8, weight: .bold))
                        .foregroundColor(CosmicTheme.gold)
                }

                Text("Compare provider-backed portfolio history with full moons, new moons, and Mercury retrograde windows.")
                    .font(TerminalFont.data(11))
                    .foregroundColor(CosmicTheme.textSecondary)
                    .lineSpacing(3)
                    .multilineTextAlignment(.leading)

                HStack {
                    Text("UNLOCK WITH ORACLE")
                        .font(TerminalFont.data(10, weight: .bold))
                        .foregroundColor(CosmicTheme.terminalBlack)
                        .tracking(1)
                    Spacer()
                    Image(systemName: "arrow.right")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(CosmicTheme.terminalBlack)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(CosmicTheme.gold)

                Text("Historical context only. Not financial advice.")
                    .font(TerminalFont.data(9))
                    .foregroundColor(CosmicTheme.textMuted)
            }
            .padding(14)
            .background(CosmicTheme.terminalBlack)
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(CosmicTheme.gold.opacity(0.45), lineWidth: 0.75)
            )
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showUpgradeSheet) {
            FeatureUpgradeSheet(feature: .historicalAstroOverlay)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
        .accessibilityLabel("Unlock portfolio cosmic correlation with Oracle")
    }
}
