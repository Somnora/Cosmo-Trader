import SwiftUI

struct AstroCorrelationSummaryView: View {
    let summaries: [StockCosmicCorrelationSummary]
    let provenance: FinancialDataProvenance
    let checkedEventKinds: [AstroOverlayEventKind]
    let eventCount: Int
    let windowLabel: String
    let hasHistoricalPrices: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 11) {
            header
            contextRows

            if !hasHistoricalPrices {
                unavailableState("Historical price data unavailable. Correlation context will appear when provider-backed history is available.")
            } else if eventCount == 0 {
                unavailableState("No enabled cosmic events were found in this price range. Try a longer timeframe or enable more event types.")
            } else if summaries.isEmpty {
                unavailableState("Not enough historical observations for this event. No return claim is shown.")
            } else {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    ForEach(summaries.prefix(4)) { summary in
                        summaryCard(summary)
                    }
                }
            }

            Text("Historical context only. Correlation does not imply causation and this is not financial advice.")
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
            Image(systemName: "waveform.path.ecg.rectangle")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(CosmicTheme.gold)

            Text("HISTORICAL COSMIC CORRELATION")
                .font(TerminalFont.data(11, weight: .bold))
                .foregroundColor(CosmicTheme.textPrimary)
                .tracking(1)

            Spacer()

            DataSourceIndicator(provenance: provenance, size: .compact)
        }
    }

    private var contextRows: some View {
        VStack(alignment: .leading, spacing: 5) {
            contextRow(label: "CHECKED", value: checkedEventLabel)
            contextRow(label: "WINDOW", value: windowLabel)
            contextRow(label: "SOURCE", value: provenance.detailText)
        }
    }

    private func contextRow(label: String, value: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(label)
                .font(TerminalFont.data(8, weight: .bold))
                .foregroundColor(CosmicTheme.textMuted)
                .tracking(0.5)
                .frame(width: 54, alignment: .leading)

            Text(value)
                .font(TerminalFont.data(10))
                .foregroundColor(CosmicTheme.textSecondary)
                .lineLimit(2)
                .minimumScaleFactor(0.75)
        }
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

    private func summaryCard(_ summary: StockCosmicCorrelationSummary) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: summary.eventType.iconSystemName)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(summary.eventType.overlayColor)

                Text(summary.eventName.uppercased())
                    .font(TerminalFont.data(9, weight: .bold))
                    .foregroundColor(CosmicTheme.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)

                Spacer()

                confidenceBadge(summary.confidence)
            }

            HStack(spacing: 8) {
                smallStat(label: "EVENTS", value: "\(summary.eventCount)")
                smallStat(label: "SAMPLE", value: "\(summary.sampleSize)")
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

            calculationDisclosure(summary)
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

    private func marketBackedMetrics(_ summary: StockCosmicCorrelationSummary) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                metricColumn(
                    label: "AVG",
                    value: percent(summary.averageReturn),
                    color: color(for: summary.averageReturn),
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
                smallStat(label: "MEDIAN", value: percent(summary.medianReturn))
                smallStat(label: "BASE", value: percent(summary.baselineReturn))
            }

            HStack(alignment: .firstTextBaseline, spacing: 8) {
                smallStat(label: "VOL", value: ratio(summary.volatilityRatio))
                smallStat(label: "MAX DD", value: percent(summary.maxDrawdown.map { -abs($0) }))
            }

            distributionContext(summary)

            Text(summary.disclaimer)
                .font(TerminalFont.data(9))
                .foregroundColor(CosmicTheme.textMuted)
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    @ViewBuilder
    private func distributionContext(_ summary: StockCosmicCorrelationSummary) -> some View {
        if summary.displayMode == .marketBackedResult,
           summary.bestHistoricalReturn != nil,
           summary.medianReturn != nil,
           summary.weakestHistoricalReturn != nil {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                smallStat(label: "BEST OBS", value: percent(summary.bestHistoricalReturn))
                smallStat(label: "MEDIAN OBS", value: percent(summary.medianReturn))
                smallStat(label: "WEAKEST OBS", value: percent(summary.weakestHistoricalReturn))
            }
        }
    }

    private func calculationDisclosure(_ summary: StockCosmicCorrelationSummary) -> some View {
        DisclosureGroup {
            VStack(alignment: .leading, spacing: 5) {
                disclosureRow(label: "EVENT TYPE", value: summary.eventName)
                disclosureRow(label: "SAMPLE", value: sampleExplanation(summary))
                disclosureRow(label: "WINDOW", value: summary.window.displayName)
                disclosureRow(label: "DATA", value: "\(summary.provenance.detailText) - \(summary.dataCompleteness.label) history")
                disclosureRow(label: "BASELINE", value: baselineExplanation(summary))
                disclosureRow(label: "CONFIDENCE", value: summary.confidence.displayName)

                if summary.displayMode != .marketBackedResult {
                    disclosureRow(label: "WHY NO METRICS", value: unavailableExplanation(summary))
                }

                Text("Historical context only. Correlation lens, not predictive and not financial advice. Correlation does not imply causation.")
                    .font(TerminalFont.data(8))
                    .foregroundColor(CosmicTheme.textMuted)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 2)
            }
            .padding(.top, 5)
        } label: {
            Text("HOW THIS WAS CALCULATED")
                .font(TerminalFont.data(8, weight: .bold))
                .foregroundColor(CosmicTheme.gold)
                .tracking(0.6)
        }
        .tint(CosmicTheme.gold)
        .font(TerminalFont.data(9))
    }

    private func disclosureRow(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(TerminalFont.data(7, weight: .bold))
                .foregroundColor(CosmicTheme.textMuted)
                .tracking(0.5)

            Text(value)
                .font(TerminalFont.data(9))
                .foregroundColor(CosmicTheme.textSecondary)
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func sampleExplanation(_ summary: StockCosmicCorrelationSummary) -> String {
        if summary.displayMode == .marketBackedResult {
            return "\(summary.sampleSize) usable observations from \(summary.eventCount) checked \(summary.eventName) events."
        }
        return "\(summary.sampleSize) usable observations from \(summary.eventCount) checked \(summary.eventName) events. At least 3 provider-backed observations are required for a numeric context view."
    }

    private func baselineExplanation(_ summary: StockCosmicCorrelationSummary) -> String {
        guard summary.displayMode == .marketBackedResult,
              let baselineReturn = summary.baselineReturn else {
            return "Baseline comparison appears when provider-backed history and sample size gates pass."
        }
        return "Same-window baseline: \(percent(baselineReturn))."
    }

    private func unavailableExplanation(_ summary: StockCosmicCorrelationSummary) -> String {
        switch summary.displayMode {
        case .insufficientSample:
            return "This event does not have enough provider-backed historical observations."
        case .partialDataset:
            return "The historical dataset is partial, so return metrics are withheld."
        case .insufficientDataset:
            return "The historical dataset is insufficient, so return metrics are withheld."
        case .sampleOnly:
            return "Sample data is preview-only and cannot produce numeric correlation metrics."
        case .unavailable:
            return "Provider-backed historical price data is unavailable."
        case .partialCoverage:
            return "Coverage is partial, so numeric metrics are withheld."
        case .marketBackedResult:
            return "Numeric context is available."
        }
    }

    private func metricColumn(label: String, value: String, color: Color, alignment: HorizontalAlignment) -> some View {
        VStack(alignment: alignment, spacing: 2) {
            Text(value)
                .font(TerminalFont.price(14))
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
        let names = checkedEventKinds.map(\.displayName)
        guard !names.isEmpty else { return "No cosmic events enabled" }
        return names.joined(separator: ", ")
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

    private func ratio(_ value: Double?) -> String {
        guard let value, value.isFinite else { return "N/A" }
        return String(format: "%.1fx", value)
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

    private func accessibilityLabel(for summary: StockCosmicCorrelationSummary) -> String {
        if summary.displayMode == .marketBackedResult {
            return "\(summary.eventName), \(summary.sampleSize) historical observations, average return \(percent(summary.averageReturn)), win rate \(percentRate(summary.winRate)). Historical context only, not financial advice."
        }
        return "\(summary.eventName), \(summary.sampleSize) historical observations. \(summary.disclaimer)"
    }
}
