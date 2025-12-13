import SwiftUI

// MARK: - PortfolioHeaderView
// ============================
// Data only. No greeting. No decoration.
// Just the numbers that matter.

struct PortfolioHeaderView: View {

    // MARK: - Properties

    let greeting: String  // Ignored - kept for API compatibility
    let sunSign: ZodiacSign  // Ignored
    let portfolioValue: String
    let dailyChange: String
    let dailyChangePercent: String
    let isPositive: Bool

    // MARK: - Body

    var body: some View {
        HStack(spacing: 0) {
            // Portfolio value
            VStack(alignment: .leading, spacing: 2) {
                Text("PORTFOLIO VALUE")
                    .font(TerminalFont.data(10))
                    .foregroundColor(CosmicTheme.textMuted)
                    .tracking(1)

                Text(portfolioValue)
                    .font(TerminalFont.price(24))
                    .foregroundColor(CosmicTheme.textPrimary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Rectangle()
                .fill(CosmicTheme.border)
                .frame(width: 1)
                .padding(.vertical, 4)

            // Daily P/L
            VStack(alignment: .trailing, spacing: 2) {
                Text("DAILY P/L")
                    .font(TerminalFont.data(10))
                    .foregroundColor(CosmicTheme.textMuted)
                    .tracking(1)

                HStack(spacing: 4) {
                    Text(dailyChange)
                        .font(TerminalFont.price(18))
                    Text("(\(dailyChangePercent))")
                        .font(TerminalFont.price(14))
                }
                .foregroundColor(isPositive ? CosmicTheme.positive : CosmicTheme.negative)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
    }
}

// MARK: - Preview

#Preview("Portfolio Header") {
    VStack(spacing: 0) {
        PortfolioHeaderView(
            greeting: "",
            sunSign: .leo,
            portfolioValue: "$45,678.90",
            dailyChange: "+$1,234.56",
            dailyChangePercent: "+2.78%",
            isPositive: true
        )

        Rectangle()
            .fill(CosmicTheme.border)
            .frame(height: 1)

        PortfolioHeaderView(
            greeting: "",
            sunSign: .scorpio,
            portfolioValue: "$32,456.78",
            dailyChange: "-$567.89",
            dailyChangePercent: "-1.72%",
            isPositive: false
        )
    }
    .background(CosmicTheme.background)
}
