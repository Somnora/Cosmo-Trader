import SwiftUI

// MARK: - PortfolioHeaderView
// ============================
// The header section of the Portfolio tab displaying:
// - Personalized greeting with time of day
// - User's sun sign with symbol
// - Total portfolio value (large, prominent)
// - Daily change in dollars and percentage
//
// DESIGN PHILOSOPHY:
// - The most important number (total value) is the largest
// - Green/red coloring for daily change provides instant feedback
// - Sun sign adds personality without overwhelming

struct PortfolioHeaderView: View {

    // MARK: - Properties

    /// Personalized greeting (e.g., "Good morning, Alex")
    let greeting: String

    /// User's zodiac sign
    let sunSign: ZodiacSign

    /// Total portfolio value formatted (e.g., "$45,678.90")
    let portfolioValue: String

    /// Daily change formatted (e.g., "+$1,234.56")
    let dailyChange: String

    /// Daily change percentage formatted (e.g., "+2.78%")
    let dailyChangePercent: String

    /// Whether the portfolio is up today
    let isPositive: Bool

    // MARK: - Body

    var body: some View {
        VStack(spacing: 20) {
            // Top row: Greeting and Sun Sign
            greetingRow

            // Main value display
            portfolioValueSection

            // Daily change
            dailyChangeSection
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(headerBackground)
    }

    // MARK: - Subviews

    /// Top row with greeting and zodiac badge
    private var greetingRow: some View {
        HStack(alignment: .center) {
            // Greeting text
            VStack(alignment: .leading, spacing: 4) {
                Text(greeting)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(CosmicTheme.textPrimary)

                Text("Your cosmic portfolio")
                    .font(.subheadline)
                    .foregroundColor(CosmicTheme.textSecondary)
            }

            Spacer()

            // Sun sign badge
            sunSignBadge
        }
    }

    /// Zodiac sign badge with symbol
    private var sunSignBadge: some View {
        HStack(spacing: 6) {
            Text(sunSign.symbol)
                .font(.title2)

            Text(sunSign.displayName)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(CosmicTheme.textSecondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(CosmicTheme.secondaryBackground)
                .overlay(
                    Capsule()
                        .stroke(CosmicTheme.cosmicPurple.opacity(0.3), lineWidth: 1)
                )
        )
    }

    /// Large portfolio value display
    private var portfolioValueSection: some View {
        VStack(spacing: 8) {
            Text("Total Value")
                .font(.subheadline)
                .foregroundColor(CosmicTheme.textMuted)
                .textCase(.uppercase)
                .tracking(1.2)

            Text(portfolioValue)
                .font(.system(size: 44, weight: .bold, design: .rounded))
                .foregroundColor(CosmicTheme.textPrimary)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
        }
        .padding(.vertical, 8)
    }

    /// Daily change indicator
    private var dailyChangeSection: some View {
        HStack(spacing: 12) {
            // Change arrow icon
            Image(systemName: isPositive ? "arrow.up.right.circle.fill" : "arrow.down.right.circle.fill")
                .font(.title2)
                .foregroundColor(isPositive ? CosmicTheme.positive : CosmicTheme.negative)

            // Dollar change
            Text(dailyChange)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(isPositive ? CosmicTheme.positive : CosmicTheme.negative)

            // Percentage change in a pill
            Text(dailyChangePercent)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(isPositive ? CosmicTheme.positive : CosmicTheme.negative)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill((isPositive ? CosmicTheme.positive : CosmicTheme.negative).opacity(0.15))
                )

            Text("today")
                .font(.subheadline)
                .foregroundColor(CosmicTheme.textMuted)
        }
    }

    /// Background with subtle gradient border
    private var headerBackground: some View {
        RoundedRectangle(cornerRadius: 24)
            .fill(CosmicTheme.cardBackground)
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(
                        LinearGradient(
                            colors: [
                                CosmicTheme.gold.opacity(0.4),
                                CosmicTheme.cosmicPurple.opacity(0.2)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: CosmicTheme.cosmicPurple.opacity(0.1), radius: 20, y: 10)
    }
}

// MARK: - Preview

#Preview("Portfolio Header - Up") {
    ZStack {
        CosmicTheme.background.ignoresSafeArea()

        PortfolioHeaderView(
            greeting: "Good morning, Alex",
            sunSign: .leo,
            portfolioValue: "$45,678.90",
            dailyChange: "+$1,234.56",
            dailyChangePercent: "+2.78%",
            isPositive: true
        )
        .padding()
    }
}

#Preview("Portfolio Header - Down") {
    ZStack {
        CosmicTheme.background.ignoresSafeArea()

        PortfolioHeaderView(
            greeting: "Good evening, Sam",
            sunSign: .scorpio,
            portfolioValue: "$32,456.78",
            dailyChange: "-$567.89",
            dailyChangePercent: "-1.72%",
            isPositive: false
        )
        .padding()
    }
}
