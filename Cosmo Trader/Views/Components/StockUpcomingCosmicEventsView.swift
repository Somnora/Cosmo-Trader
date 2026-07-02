import SwiftUI

struct StockUpcomingCosmicEventsView: View {
    let summary: StockUpcomingCosmicEventsSummary

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header
            metadataStatus

            if summary.events.isEmpty {
                unavailableState
            } else {
                VStack(spacing: 0) {
                    ForEach(summary.events) { event in
                        eventRow(event)
                        if event.id != summary.events.last?.id {
                            Divider()
                                .background(CosmicTheme.borderDim)
                                .padding(.leading, 32)
                        }
                    }
                }
            }

            Text(summary.footerText)
                .font(TerminalFont.data(8))
                .foregroundColor(CosmicTheme.textMuted)
                .accessibilityIdentifier("stock.upcomingCosmicEvents.footer")
        }
        .accessibilityIdentifier("stock.upcomingCosmicEvents")
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 8) {
                Image(systemName: "calendar.badge.clock")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(CosmicTheme.gold)

                Text("UPCOMING COSMIC EVENTS")
                    .font(TerminalFont.data(12, weight: .bold))
                    .foregroundColor(CosmicTheme.textPrimary)
                    .tracking(1)

                Spacer()

                Text(summary.windowLabel.uppercased())
                    .font(TerminalFont.data(8, weight: .bold))
                    .foregroundColor(CosmicTheme.gold)
                    .tracking(0.8)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(CosmicTheme.gold.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(CosmicTheme.gold.opacity(0.45), lineWidth: 0.75)
                    )
            }

            Text("Forward calendar context for \(summary.symbol). No market or return claims are shown here.")
                .font(TerminalFont.data(10))
                .foregroundColor(CosmicTheme.textSecondary)
                .lineSpacing(3)
        }
    }

    private var metadataStatus: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: summary.hasCompanySpecificMetadata ? "checkmark.seal.fill" : "info.circle")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(summary.hasCompanySpecificMetadata ? CosmicTheme.positive : CosmicTheme.textMuted)
                .padding(.top, 1)

            Text(summary.companySpecificStatus)
                .font(TerminalFont.data(9))
                .foregroundColor(CosmicTheme.textSecondary)
                .lineSpacing(2)

            Spacer(minLength: 0)
        }
        .padding(10)
        .background(CosmicTheme.secondaryBackground.opacity(0.55))
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(CosmicTheme.borderDim, lineWidth: 0.5)
        )
        .accessibilityIdentifier("stock.upcomingCosmicEvents.metadataStatus")
    }

    private var unavailableState: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "moon")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(CosmicTheme.textMuted)

            Text("No supported cosmic calendar events appear in this window. Broad moon phase and Mercury retrograde context will appear when the calendar window includes them.")
                .font(TerminalFont.data(10))
                .foregroundColor(CosmicTheme.textSecondary)
                .lineSpacing(3)
        }
        .padding(12)
        .background(CosmicTheme.secondaryBackground.opacity(0.55))
        .accessibilityIdentifier("stock.upcomingCosmicEvents.empty")
    }

    private func eventRow(_ event: StockUpcomingCosmicEventRow) -> some View {
        HStack(alignment: .top, spacing: 10) {
            ZStack {
                Circle()
                    .fill(event.kind.overlayColor.opacity(0.14))
                    .frame(width: 26, height: 26)

                Image(systemName: event.iconSystemName)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(event.kind.overlayColor)
            }
            .padding(.top, 1)

            VStack(alignment: .leading, spacing: 5) {
                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        eventTitle(event)
                        Spacer(minLength: 8)
                        dateBadge(event)
                    }

                    VStack(alignment: .leading, spacing: 5) {
                        eventTitle(event)
                        dateBadge(event)
                    }
                }

                Text(event.whyText)
                    .font(TerminalFont.data(10))
                    .foregroundColor(CosmicTheme.textSecondary)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)

                Text(event.sourceLabel.uppercased())
                    .font(TerminalFont.data(8, weight: .bold))
                    .foregroundColor(CosmicTheme.textMuted)
                    .tracking(0.7)
            }
        }
        .padding(.vertical, 10)
        .accessibilityIdentifier("stock.upcomingCosmicEvents.row.\(event.id)")
    }

    private func eventTitle(_ event: StockUpcomingCosmicEventRow) -> some View {
        Text(event.name)
            .font(TerminalFont.data(12, weight: .semibold))
            .foregroundColor(CosmicTheme.textPrimary)
            .lineLimit(2)
            .minimumScaleFactor(0.85)
    }

    private func dateBadge(_ event: StockUpcomingCosmicEventRow) -> some View {
        HStack(spacing: 4) {
            if event.isRange {
                Image(systemName: "arrow.left.and.right")
                    .font(.system(size: 8, weight: .bold))
            }

            Text(event.dateLabel.uppercased())
                .font(TerminalFont.data(8, weight: .bold))
                .tracking(0.6)
        }
        .foregroundColor(event.kind.overlayColor)
        .padding(.horizontal, 7)
        .padding(.vertical, 3)
        .background(event.kind.overlayColor.opacity(0.1))
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(event.kind.overlayColor.opacity(0.35), lineWidth: 0.5)
        )
        .fixedSize()
    }
}
