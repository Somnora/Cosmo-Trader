import SwiftUI

struct TodayMarketHoroscopeShareCard: View {
    let card: TodayShareCardSummary

    private let cardWidth: CGFloat = 390

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            divider
            headline
            divider
            lensRows
            divider
            footer
        }
        .frame(width: cardWidth)
        .background(CosmicTheme.background)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "moon.stars.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(CosmicTheme.gold)

                Text("COSMO TRADER")
                    .font(TerminalFont.data(16, weight: .bold))
                    .foregroundColor(CosmicTheme.textPrimary)
                    .tracking(1.6)

                Spacer(minLength: 8)

                Text(formattedDate(card.date))
                    .font(TerminalFont.data(9, weight: .semibold))
                    .foregroundColor(CosmicTheme.textMuted)
            }

            HStack(spacing: 8) {
                Text("DAILY MARKET HOROSCOPE")
                    .font(TerminalFont.data(10, weight: .bold))
                    .foregroundColor(CosmicTheme.gold)
                    .tracking(0.9)

                Spacer(minLength: 8)

                DataSourceIndicator(provenance: card.provenance, size: .compact)
            }
        }
        .padding(18)
        .background(CosmicTheme.terminalBlack)
    }

    private var headline: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(card.headline)
                .font(TerminalFont.headline(22))
                .foregroundColor(CosmicTheme.textPrimary)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)

            Text("Source: \(card.sourceLabel). \(card.sourceDetail)")
                .font(TerminalFont.data(9))
                .foregroundColor(CosmicTheme.textMuted)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(18)
        .background(CosmicTheme.cardBackground)
    }

    private var lensRows: some View {
        VStack(spacing: 10) {
            ForEach(card.lenses) { lens in
                lensRow(lens)
            }
        }
        .padding(18)
        .background(CosmicTheme.secondaryBackground)
    }

    private func lensRow(_ lens: TodayShareCardLens) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon(for: lens.id))
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(CosmicTheme.gold)
                .frame(width: 18)

            VStack(alignment: .leading, spacing: 5) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(lens.title.uppercased())
                        .font(TerminalFont.data(8, weight: .bold))
                        .foregroundColor(CosmicTheme.gold)
                        .tracking(0.7)

                    Spacer(minLength: 8)

                    DataSourceIndicator(provenance: lens.provenance, size: .compact)
                }

                Text(lens.status)
                    .font(TerminalFont.data(13, weight: .semibold))
                    .foregroundColor(CosmicTheme.textPrimary)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)

                Text(lens.detail)
                    .font(TerminalFont.data(9))
                    .foregroundColor(CosmicTheme.textMuted)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)

                if let metric = lens.metric {
                    HStack(spacing: 6) {
                        Text(metric.value)
                            .font(TerminalFont.data(12, weight: .bold))
                            .foregroundColor(CosmicTheme.textPrimary)

                        Text(metric.label.uppercased())
                            .font(TerminalFont.data(8, weight: .bold))
                            .foregroundColor(CosmicTheme.textMuted)
                            .tracking(0.5)
                    }
                    .padding(.horizontal, 9)
                    .padding(.vertical, 6)
                    .background(CosmicTheme.panelElevated)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(CosmicTheme.borderStrong, lineWidth: 0.75)
                    )
                }
            }
        }
        .padding(12)
        .background(CosmicTheme.terminalBlack.opacity(0.82))
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(CosmicTheme.borderDim, lineWidth: 0.75)
        )
    }

    private var footer: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(card.disclaimer)
                .font(TerminalFont.data(9))
                .foregroundColor(CosmicTheme.textMuted)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)

            HStack {
                Text("COSMO TRADER")
                    .font(TerminalFont.data(9, weight: .bold))
                    .foregroundColor(CosmicTheme.gold)
                    .tracking(0.8)

                Spacer()

                Text("MARKET DATA + ASTROLOGY LENS")
                    .font(TerminalFont.data(8, weight: .bold))
                    .foregroundColor(CosmicTheme.textMuted)
                    .tracking(0.6)
            }
        }
        .padding(18)
        .background(CosmicTheme.terminalBlack)
    }

    private var divider: some View {
        Rectangle()
            .fill(CosmicTheme.borderDim)
            .frame(height: 1)
    }

    private func icon(for id: String) -> String {
        switch id {
        case "market":
            return "cloud.sun.fill"
        case "portfolio":
            return "chart.pie.fill"
        case "stock":
            return "scope"
        default:
            return "sparkles"
        }
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date).uppercased()
    }
}

@MainActor
struct TodayMarketHoroscopeShareCardRenderer {
    static func render(card: TodayShareCardSummary, scale: CGFloat = 3.0) -> UIImage? {
        let renderer = ImageRenderer(content: TodayMarketHoroscopeShareCard(card: card))
        renderer.scale = scale
        return renderer.uiImage
    }

    static func shareText(for card: TodayShareCardSummary) -> String {
        "My Cosmo Trader daily market horoscope: \(card.headline). \(card.disclaimer)"
    }
}

#Preview("Today Share Card") {
    TodayMarketHoroscopeShareCard(
        card: TodayShareCardSummary(
            date: Date(),
            headline: "Today is in context-building mode",
            lenses: [
                TodayShareCardLens(
                    id: "market",
                    title: "Market Weather",
                    status: "Market Weather unavailable",
                    detail: "Provider-backed market ETF history unavailable.",
                    metric: nil,
                    provenance: .unavailable(reason: "Provider-backed market ETF history unavailable")
                ),
                TodayShareCardLens(
                    id: "portfolio",
                    title: "Portfolio Context",
                    status: "Portfolio context needs holdings",
                    detail: "Add holdings or import a portfolio to unlock portfolio context.",
                    metric: nil,
                    provenance: .unavailable(reason: "Portfolio holdings unavailable")
                ),
                TodayShareCardLens(
                    id: "stock",
                    title: "Watchlist / Stock Lens",
                    status: "Stock lens needs a ticker",
                    detail: "Add a watchlist symbol to unlock stock-level historical context.",
                    metric: nil,
                    provenance: .unavailable(reason: "No portfolio or watchlist stock available")
                )
            ],
            sourceLabel: "Unavailable",
            sourceDetail: "Provider-backed data unavailable",
            provenance: .unavailable(reason: "Provider-backed data unavailable"),
            disclaimer: "Historical context only. Not a prediction or financial advice."
        )
    )
    .padding()
    .background(Color.black)
}
