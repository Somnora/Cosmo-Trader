import SwiftUI

struct DailyFinancialReadingCockpitView: View {
    let reading: DailyFinancialReading
    let setupAction: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            header
            signalBlock
            postureBlock
            metricsStrip
            portfolioImpactBlock
            if !AppState.isScreenshotMode {
                watchBlock
                moveBlock
                groundingBlock
            }
        }
        .padding(16)
        .background(CosmicTheme.cardBackground)
        .overlay(
            Rectangle()
                .stroke(CosmicTheme.border, lineWidth: 1)
        )
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 4) {
                Text("DAILY MARKET READING")
                    .font(TerminalFont.caption(10, weight: .semibold))
                    .tracking(1.4)
                    .foregroundColor(CosmicTheme.gold)

                Text(formattedDate)
                    .font(TerminalFont.caption(10))
                    .foregroundColor(CosmicTheme.textMuted)
            }

            Spacer(minLength: 12)

            Text(reading.framingLevel.shortName)
                .font(TerminalFont.caption(10, weight: .semibold))
                .foregroundColor(CosmicTheme.textPrimary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(CosmicTheme.terminalNavy.opacity(0.9))
                .overlay(
                    Rectangle()
                        .stroke(CosmicTheme.accentBlue.opacity(0.45), lineWidth: 1)
                )
        }
    }

    private var signalBlock: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("TODAY'S LENS")

            Text(reading.signalHeadline)
                .font(TerminalFont.headline(24))
                .foregroundColor(CosmicTheme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
                .lineLimit(3)
                .minimumScaleFactor(0.82)
        }
    }

    private var postureBlock: some View {
        readingSection(title: "MARKET / COSMIC POSTURE", body: reading.marketCosmicPosture)
    }

    private var metricsStrip: some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: 8),
                GridItem(.flexible(), spacing: 8)
            ],
            spacing: 8
        ) {
            metricCell(label: "PORTFOLIO", value: reading.portfolioValue ?? "SETUP", color: CosmicTheme.textPrimary)
            metricCell(label: "TODAY", value: reading.portfolioReturn ?? "NO HOLDINGS", color: returnColor)
            metricCell(label: "LUNAR", value: reading.lunarPhase, color: CosmicTheme.gold)
            metricCell(label: "MERCURY", value: reading.mercuryStatus, color: CosmicTheme.textPrimary)
            metricCell(label: "MARKET TONE", value: reading.marketTone, color: CosmicTheme.textPrimary)

            if let dominantExposure = reading.dominantExposure {
                metricCell(label: dominantExposure.label.uppercased(), value: dominantExposure.detail, color: dominantExposure.color)
            } else {
                metricCell(label: "EXPOSURE", value: "PENDING", color: CosmicTheme.textMuted)
            }
        }
    }

    private var portfolioImpactBlock: some View {
        readingSection(title: "PORTFOLIO IMPACT", body: reading.portfolioImpact)
    }

    private var watchBlock: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("WATCH CLOSELY")

            if reading.watchItems.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text("No holdings are available for portfolio-specific watch notes. Add a few tickers and this block becomes today's highest-attention names.")
                        .font(TerminalFont.body(14))
                        .foregroundColor(CosmicTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)

                    Button(action: setupAction) {
                        HStack(spacing: 8) {
                            Image(systemName: "plus")
                                .font(.caption)
                            Text("SET UP PORTFOLIO")
                                .font(TerminalFont.caption(11, weight: .semibold))
                        }
                        .foregroundColor(CosmicTheme.background)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(CosmicTheme.gold)
                    }
                    .buttonStyle(.plain)
                }
                .padding(12)
                .background(CosmicTheme.background)
                .overlay(
                    Rectangle()
                        .stroke(CosmicTheme.border, lineWidth: 1)
                )
            } else {
                VStack(spacing: 0) {
                    ForEach(reading.watchItems) { item in
                        watchRow(item)

                        if item.id != reading.watchItems.last?.id {
                            Rectangle()
                                .fill(CosmicTheme.divider)
                                .frame(height: 1)
                        }
                    }
                }
                .background(CosmicTheme.background)
                .overlay(
                    Rectangle()
                        .stroke(CosmicTheme.border, lineWidth: 1)
                )
            }
        }
    }

    private var moveBlock: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("TODAY'S READ")

            HStack(alignment: .center, spacing: 12) {
                Image(systemName: reading.bestMove.systemImage)
                    .font(.headline)
                    .foregroundColor(reading.bestMove.color)
                    .frame(width: 24, height: 24)

                Text(reading.bestMove.rawValue.uppercased())
                    .font(TerminalFont.data(18, weight: .semibold))
                    .foregroundColor(CosmicTheme.textPrimary)

                Spacer()
            }
            .padding(12)
            .background(reading.bestMove.color.opacity(0.10))
            .overlay(
                Rectangle()
                    .stroke(reading.bestMove.color.opacity(0.35), lineWidth: 1)
            )
        }
    }

    private var groundingBlock: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("CONFIDENCE / GROUNDING")

            Text(reading.grounding)
                .font(TerminalFont.caption(11))
                .foregroundColor(CosmicTheme.textMuted)
                .fixedSize(horizontal: false, vertical: true)

            if !reading.activeEvents.isEmpty {
                HStack(alignment: .top, spacing: 6) {
                    Text("ACTIVE")
                        .font(TerminalFont.caption(10, weight: .semibold))
                        .foregroundColor(CosmicTheme.gold)

                    Text(reading.activeEvents.joined(separator: " / "))
                        .font(TerminalFont.caption(10))
                        .foregroundColor(CosmicTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private func readingSection(title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel(title)

            Text(body)
                .font(TerminalFont.body(14))
                .foregroundColor(CosmicTheme.textSecondary)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func metricCell(label: String, value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(TerminalFont.caption(9, weight: .semibold))
                .foregroundColor(CosmicTheme.textMuted)
                .lineLimit(1)
                .minimumScaleFactor(0.72)

            Text(value)
                .font(TerminalFont.data(12, weight: .medium))
                .foregroundColor(color)
                .lineLimit(2)
                .minimumScaleFactor(0.74)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, minHeight: 54, alignment: .topLeading)
        .padding(10)
        .background(CosmicTheme.panelElevated)
        .overlay(
            Rectangle()
                .stroke(CosmicTheme.borderStrong, lineWidth: 1)
        )
    }

    private func watchRow(_ item: DailyReadingWatchItem) -> some View {
        HStack(alignment: .top, spacing: 10) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(item.symbol)
                        .font(TerminalFont.ticker(13))
                        .foregroundColor(CosmicTheme.textPrimary)

                    Text(item.source == .holding ? "HOLDING" : "WATCHLIST")
                        .font(TerminalFont.caption(9, weight: .semibold))
                        .foregroundColor(item.source == .holding ? CosmicTheme.gold : CosmicTheme.accentBlue)
                }

                Text(item.reason)
                    .font(TerminalFont.body(12))
                    .foregroundColor(CosmicTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 8)

            if let changeText = item.changeText {
                Text(changeText)
                    .font(TerminalFont.data(12, weight: .semibold))
                    .foregroundColor((item.isPositive ?? true) ? CosmicTheme.positive : CosmicTheme.negative)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
        .padding(12)
    }

    private func sectionLabel(_ title: String) -> some View {
        Text(title)
            .font(TerminalFont.caption(10, weight: .semibold))
            .tracking(1.2)
            .foregroundColor(CosmicTheme.gold)
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE MMM d, h:mm a"
        return formatter.string(from: reading.date).uppercased()
    }

    private var returnColor: Color {
        guard let returnText = reading.portfolioReturn else { return CosmicTheme.textMuted }
        if returnText.contains("-") {
            return CosmicTheme.negative
        }
        if returnText.contains("+") {
            return CosmicTheme.positive
        }
        return CosmicTheme.textSecondary
    }
}
