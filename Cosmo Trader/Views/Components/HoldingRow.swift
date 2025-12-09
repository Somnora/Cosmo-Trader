import SwiftUI

// MARK: - HoldingRow
// ===================
// A single row in the holdings list showing:
// - Company name and ticker symbol
// - The stock's zodiac sign symbol
// - Current price and daily change (color-coded)
// - Number of shares and total value
// - Compatibility indicator with the user (star rating)
//
// DESIGN PHILOSOPHY:
// - Information hierarchy: Name/symbol → Price → Holdings → Compatibility
// - Compact but readable
// - Zodiac symbol adds cosmic flavor without overwhelming
// - Compatibility indicator is subtle but present

struct HoldingRow: View {

    // MARK: - Properties

    /// The stock being displayed
    let stock: Stock

    /// Compatibility result with the user
    let compatibility: CompatibilityResult

    /// Optional tap action
    var onTap: (() -> Void)? = nil

    // MARK: - Body

    var body: some View {
        Button(action: { onTap?() }) {
            HStack(spacing: 12) {
                // Left: Zodiac badge
                zodiacBadge

                // Center: Stock info
                stockInfo

                Spacer()

                // Right: Price and holdings
                priceSection
            }
            .padding(16)
            .background(rowBackground)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Subviews

    /// Zodiac sign badge
    private var zodiacBadge: some View {
        ZStack {
            // Background circle with element-based color
            Circle()
                .fill(elementColor.opacity(0.2))
                .frame(width: 48, height: 48)

            // Inner circle
            Circle()
                .fill(CosmicTheme.cardBackground)
                .frame(width: 40, height: 40)

            // Zodiac symbol
            Text(stock.zodiacSign.symbol)
                .font(.title3)
        }
    }

    /// Stock name, symbol, and compatibility
    private var stockInfo: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Company name with zodiac hint
            HStack(spacing: 6) {
                Text(stock.symbol)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(CosmicTheme.textPrimary)

                // Small zodiac indicator
                Text(stock.zodiacSign.symbol)
                    .font(.caption2)
                    .foregroundColor(CosmicTheme.textMuted)
            }

            // Full name
            Text(stock.name)
                .font(.caption)
                .foregroundColor(CosmicTheme.textSecondary)
                .lineLimit(1)

            // Compatibility stars
            compatibilityStars
        }
    }

    /// Price and holdings info
    private var priceSection: some View {
        VStack(alignment: .trailing, spacing: 4) {
            // Current price
            Text(stock.formattedPrice)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(CosmicTheme.textPrimary)

            // Daily change
            HStack(spacing: 4) {
                Image(systemName: stock.isPositive ? "arrow.up.right" : "arrow.down.right")
                    .font(.caption2)

                Text(stock.formattedPercentageChange)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .foregroundColor(stock.isPositive ? CosmicTheme.positive : CosmicTheme.negative)

            // Holdings value
            HStack(spacing: 4) {
                Text("\(stock.formattedSharesOwned) shares")
                    .font(.caption2)
                    .foregroundColor(CosmicTheme.textMuted)

                Text("·")
                    .foregroundColor(CosmicTheme.textMuted)

                Text(stock.formattedTotalValue)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(CosmicTheme.textSecondary)
            }
        }
    }

    /// Star rating for compatibility
    private var compatibilityStars: some View {
        HStack(spacing: 2) {
            // Convert score to 1-5 stars
            let starCount = compatibilityToStars(compatibility.score)

            ForEach(1...5, id: \.self) { index in
                Image(systemName: index <= starCount ? "star.fill" : "star")
                    .font(.system(size: 8))
                    .foregroundColor(index <= starCount ? CosmicTheme.gold : CosmicTheme.textMuted.opacity(0.3))
            }

            Text("\(compatibility.score)%")
                .font(.system(size: 9))
                .foregroundColor(CosmicTheme.textMuted)
                .padding(.leading, 4)
        }
    }

    /// Row background
    private var rowBackground: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(CosmicTheme.cardBackground)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(borderColor, lineWidth: 1)
            )
    }

    // MARK: - Helpers

    /// Color based on stock's element
    private var elementColor: Color {
        switch stock.zodiacSign.element {
        case .fire:  return Color(red: 1.0, green: 0.4, blue: 0.3)
        case .earth: return Color(red: 0.4, green: 0.75, blue: 0.4)
        case .air:   return Color(red: 0.95, green: 0.85, blue: 0.4)
        case .water: return Color(red: 0.3, green: 0.6, blue: 0.9)
        }
    }

    /// Border color based on compatibility
    private var borderColor: Color {
        switch compatibility.rating {
        case .cosmicSoulmates:
            return CosmicTheme.gold.opacity(0.4)
        case .highCompatibility:
            return CosmicTheme.cosmicPurple.opacity(0.3)
        default:
            return CosmicTheme.textMuted.opacity(0.1)
        }
    }

    /// Convert 0-100 score to 1-5 stars
    private func compatibilityToStars(_ score: Int) -> Int {
        switch score {
        case 85...100: return 5
        case 70...84:  return 4
        case 50...69:  return 3
        case 30...49:  return 2
        default:       return 1
        }
    }
}

// MARK: - Compact Holding Row

/// A more compact version for tighter lists
struct CompactHoldingRow: View {

    let stock: Stock
    let compatibility: CompatibilityResult

    var body: some View {
        HStack(spacing: 12) {
            // Zodiac symbol
            Text(stock.zodiacSign.symbol)
                .font(.title3)
                .frame(width: 36)

            // Stock info
            VStack(alignment: .leading, spacing: 2) {
                Text(stock.symbol)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(CosmicTheme.textPrimary)

                Text(stock.name)
                    .font(.caption2)
                    .foregroundColor(CosmicTheme.textMuted)
                    .lineLimit(1)
            }

            Spacer()

            // Price and change
            VStack(alignment: .trailing, spacing: 2) {
                Text(stock.formattedPrice)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(CosmicTheme.textPrimary)

                Text(stock.formattedPercentageChange)
                    .font(.caption)
                    .foregroundColor(stock.isPositive ? CosmicTheme.positive : CosmicTheme.negative)
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(CosmicTheme.cardBackground)
        )
    }
}

// MARK: - Preview

#Preview("Holding Row - High Compatibility") {
    ZStack {
        CosmicTheme.background.ignoresSafeArea()

        VStack(spacing: 12) {
            // Create sample stock with holdings
            let stock: Stock = {
                var s = MockStockData.all.first { $0.symbol == "AAPL" }!
                s.sharesOwned = 15
                return s
            }()

            HoldingRow(
                stock: stock,
                compatibility: CompatibilityResult(
                    userSign: .leo,
                    stockSign: .aries,
                    score: 92,
                    description: "Fire meets fire",
                    advice: "Trust this cosmic connection",
                    elementDynamic: "Two fires burning"
                )
            )
        }
        .padding()
    }
}

#Preview("Holding Row - Various") {
    ZStack {
        CosmicTheme.background.ignoresSafeArea()

        ScrollView {
            VStack(spacing: 12) {
                // High compatibility (Fire - Aries)
                let apple: Stock = {
                    var s = MockStockData.all.first { $0.symbol == "AAPL" }!
                    s.sharesOwned = 15
                    return s
                }()

                HoldingRow(
                    stock: apple,
                    compatibility: CompatibilityResult(
                        userSign: .leo,
                        stockSign: .aries,
                        score: 92,
                        description: "",
                        advice: "",
                        elementDynamic: ""
                    )
                )

                // Medium compatibility (Water - Cancer)
                let tesla: Stock = {
                    var s = MockStockData.all.first { $0.symbol == "TSLA" }!
                    s.sharesOwned = 10
                    return s
                }()

                HoldingRow(
                    stock: tesla,
                    compatibility: CompatibilityResult(
                        userSign: .leo,
                        stockSign: .cancer,
                        score: 55,
                        description: "",
                        advice: "",
                        elementDynamic: ""
                    )
                )

                // Low compatibility
                let nvidia: Stock = {
                    var s = MockStockData.all.first { $0.symbol == "NVDA" }!
                    s.sharesOwned = 6
                    return s
                }()

                HoldingRow(
                    stock: nvidia,
                    compatibility: CompatibilityResult(
                        userSign: .leo,
                        stockSign: .aquarius,
                        score: 35,
                        description: "",
                        advice: "",
                        elementDynamic: ""
                    )
                )
            }
            .padding()
        }
    }
}
