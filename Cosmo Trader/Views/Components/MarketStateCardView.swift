import SwiftUI

// MARK: - MarketStateCardView
// ===========================
// Where the market stands right now, and what happened after the sessions that
// looked the same. Renders only; every number arrives already measured and
// already worded by TodayMarketHoroscopeComposer.
//
// The verdict line is the point of the card. It usually says the gap is inside
// its own margin of error, because that is what twenty years of data say, and
// an app that only speaks up when it has found something is an app whose
// silence means nothing.

struct MarketStateCardView: View {

    let context: TodayMarketStateContext

    private let columns = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            readingsGrid

            if let historyHeadline = context.historyHeadline {
                historyBlock(headline: historyHeadline)
            }
        }
        .padding(AppLayout.cardHorizontalPadding)
        .background(CosmicTheme.terminalBlack)
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(CosmicTheme.borderDim, lineWidth: 0.75)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityIdentifier("today.marketState")
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("MARKET STATE")
                    .font(TerminalFont.data(9, weight: .bold))
                    .foregroundColor(CosmicTheme.gold)
                    .tracking(0.8)

                Spacer(minLength: 8)

                DataSourceIndicator(provenance: context.provenance, size: .compact)
            }

            Text(context.headline)
                .font(TerminalFont.headline(15))
                .foregroundColor(CosmicTheme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            Text(context.detail)
                .font(TerminalFont.data(9))
                .foregroundColor(CosmicTheme.textMuted)
        }
    }

    // MARK: - Readings

    private var readingsGrid: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(context.readings) { reading in
                VStack(alignment: .leading, spacing: 3) {
                    Text(reading.label)
                        .font(TerminalFont.data(8, weight: .bold))
                        .foregroundColor(CosmicTheme.textMuted)
                        .tracking(0.6)
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)

                    Text(reading.value)
                        .font(TerminalFont.data(15, weight: .bold))
                        .foregroundColor(CosmicTheme.textPrimary)

                    Text(reading.context)
                        .font(TerminalFont.data(8))
                        .foregroundColor(CosmicTheme.textSecondary)
                        .lineSpacing(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, minHeight: 74, alignment: .topLeading)
                .padding(8)
                .background(CosmicTheme.panelElevated.opacity(0.8))
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(CosmicTheme.borderDim, lineWidth: 0.75)
                )
            }
        }
    }

    // MARK: - History

    private func historyBlock(headline: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("WHAT FOLLOWED")
                .font(TerminalFont.data(8, weight: .bold))
                .foregroundColor(CosmicTheme.gold)
                .tracking(0.7)

            Text(headline)
                .font(TerminalFont.data(10, weight: .semibold))
                .foregroundColor(CosmicTheme.textPrimary)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)

            if let detail = context.historyDetail {
                Text(detail)
                    .font(TerminalFont.data(9))
                    .foregroundColor(CosmicTheme.textSecondary)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let verdict = context.verdict {
                Text(verdict)
                    .font(TerminalFont.data(9, weight: .semibold))
                    .foregroundColor(CosmicTheme.textMuted)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 2)
            }
        }
        .padding(10)
        .background(CosmicTheme.panelElevated.opacity(0.8))
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(CosmicTheme.borderDim, lineWidth: 0.75)
        )
    }

    // MARK: - Accessibility

    private var accessibilityLabel: String {
        var parts = [context.headline, context.detail]
        parts.append(contentsOf: context.readings.map { "\($0.label): \($0.value). \($0.context)" })
        if let historyHeadline = context.historyHeadline { parts.append(historyHeadline) }
        if let detail = context.historyDetail { parts.append(detail) }
        if let verdict = context.verdict { parts.append(verdict) }
        parts.append("Historical context only, not financial advice.")
        return parts.joined(separator: " ")
    }
}
