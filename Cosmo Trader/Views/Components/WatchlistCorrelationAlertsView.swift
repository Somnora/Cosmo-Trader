import SwiftUI

struct WatchlistCorrelationAlertsView: View {
    let alerts: [WatchlistCorrelationAlert]

    init(alerts: [WatchlistCorrelationAlert]) {
        self.alerts = alerts
    }

    /// Convenience wiring for host views: computes the alerts from the
    /// watchlist and event feeds so hosts don't carry that logic.
    init(watchlist: [String], events: [CosmicEvent], earnings: [EarningsEvent]) {
        self.alerts = WatchlistCorrelationService.shared.generateAlerts(
            watchlist: watchlist,
            events: events,
            earnings: earnings
        )
    }

    var body: some View {
        if !alerts.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    Image(systemName: "bell.badge.fill")
                        .font(.caption)
                        .foregroundColor(CosmicTheme.gold)

                    Text("WATCHLIST CORRELATION ALERTS")
                        .font(TerminalFont.data(10, weight: .bold))
                        .foregroundColor(CosmicTheme.gold)
                        .tracking(1.1)
                }
                .padding(.horizontal, 4)

                VStack(spacing: 8) {
                    ForEach(alerts) { alert in
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.orange)
                                .padding(.top, 2)

                            VStack(alignment: .leading, spacing: 5) {
                                Text(alert.message)
                                    .font(TerminalFont.data(11, weight: .medium))
                                    .foregroundColor(CosmicTheme.textPrimary)
                                    .lineSpacing(3)
                                    .fixedSize(horizontal: false, vertical: true)

                                HStack {
                                    Text(alert.dateRangeText)
                                        .font(TerminalFont.data(9))
                                        .foregroundColor(CosmicTheme.textMuted)
                                    Spacer()
                                    Text(alert.affectedSymbols.joined(separator: ", "))
                                        .font(TerminalFont.data(9, weight: .bold))
                                        .foregroundColor(CosmicTheme.accentBlue)
                                }
                            }
                        }
                        .padding(10)
                        .background(CosmicTheme.cardBackground.opacity(0.6))
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(CosmicTheme.borderDim, lineWidth: 0.75)
                        )
                    }
                }
            }
        }
    }
}
