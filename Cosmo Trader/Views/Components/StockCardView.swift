import SwiftUI

// MARK: - StockCardView
// ======================
// A "dating app profile" style card for stocks.
//
// DISPLAYS:
// - Company name, ticker, logo placeholder
// - Zodiac sign with symbol
// - Price and performance
// - Sector and description
// - Compatibility score (big and prominent)
// - Co-Star style compatibility description
//
// DESIGN: Premium, clean, swipeable dating app aesthetic

struct StockCardView: View {

    // MARK: - Properties

    let card: StockCard
    let cardOffset: CGSize
    let isTopCard: Bool

    /// Swipe threshold before triggering action
    private let swipeThreshold: CGFloat = 100

    // MARK: - Computed Properties

    /// Normalized swipe progress (-1 to 1)
    private var swipeProgress: CGFloat {
        cardOffset.width / swipeThreshold
    }

    /// Show like indicator
    private var showLikeIndicator: Bool {
        cardOffset.width > 30
    }

    /// Show skip indicator
    private var showSkipIndicator: Bool {
        cardOffset.width < -30
    }

    /// Show detail indicator (swipe up)
    private var showDetailIndicator: Bool {
        cardOffset.height < -30
    }

    // MARK: - Body

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Top section: Company info and zodiac
                topSection

                // Middle section: Compatibility score
                compatibilitySection

                // Bottom section: Description and advice
                bottomSection
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .background(cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .overlay(swipeIndicators)
            .overlay(cosmicMatchBadge, alignment: .top)
        }
    }

    // MARK: - Top Section

    private var topSection: some View {
        VStack(spacing: 16) {
            // Company logo placeholder and zodiac badge
            HStack {
                // Logo placeholder
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(CosmicTheme.secondaryBackground)
                        .frame(width: 60, height: 60)

                    Text(String(card.stock.symbol.prefix(2)))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(CosmicTheme.gold)
                }

                Spacer()

                // Zodiac sign badge
                zodiacBadge
            }

            // Company name and ticker
            VStack(alignment: .leading, spacing: 4) {
                Text(card.stock.name)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(CosmicTheme.textPrimary)
                    .lineLimit(2)

                HStack(spacing: 8) {
                    Text(card.stock.symbol)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(CosmicTheme.gold)

                    Text("•")
                        .foregroundColor(CosmicTheme.textMuted)

                    Text(card.stock.sector)
                        .font(.subheadline)
                        .foregroundColor(CosmicTheme.textSecondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Price and performance
            priceSection
        }
        .padding(20)
    }

    private var zodiacBadge: some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .fill(elementColor.opacity(0.2))
                    .frame(width: 56, height: 56)

                Text(card.stock.zodiacSign.symbol)
                    .font(.system(size: 32))
            }

            Text(card.stock.zodiacSign.displayName)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(CosmicTheme.textSecondary)
        }
    }

    private var priceSection: some View {
        HStack {
            // Current price
            VStack(alignment: .leading, spacing: 2) {
                Text("Current Price")
                    .font(.caption)
                    .foregroundColor(CosmicTheme.textMuted)

                Text(card.stock.formattedPrice)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(CosmicTheme.textPrimary)
            }

            Spacer()

            // Daily change
            VStack(alignment: .trailing, spacing: 2) {
                Text("Today")
                    .font(.caption)
                    .foregroundColor(CosmicTheme.textMuted)

                HStack(spacing: 4) {
                    Image(systemName: card.stock.isPositive ? "arrow.up.right" : "arrow.down.right")
                        .font(.caption)

                    Text(card.stock.formattedPercentageChange)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                .foregroundColor(card.stock.isPositive ? CosmicTheme.positive : CosmicTheme.negative)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(CosmicTheme.secondaryBackground)
        )
    }

    // MARK: - Compatibility Section

    private var compatibilitySection: some View {
        VStack(spacing: 12) {
            // Big compatibility score
            HStack(spacing: 8) {
                Text("\(card.compatibility.score)%")
                    .font(.system(size: 56, weight: .bold, design: .rounded))
                    .foregroundStyle(compatibilityGradient)

                Text("Match")
                    .font(.title2)
                    .fontWeight(.medium)
                    .foregroundColor(CosmicTheme.textSecondary)
            }

            // Rating badge
            HStack(spacing: 6) {
                Text(card.compatibility.rating.emoji)

                Text(card.compatibility.rating.displayName)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(ratingColor)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(ratingColor.opacity(0.15))
            )
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }

    // MARK: - Bottom Section

    private var bottomSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Element dynamic
            HStack(spacing: 8) {
                Text(card.stock.zodiacSign.element.emoji)
                    .font(.caption)

                Text(card.compatibility.elementDynamic)
                    .font(.subheadline)
                    .foregroundColor(CosmicTheme.textSecondary)
                    .italic()
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Divider()
                .background(CosmicTheme.textMuted.opacity(0.3))

            // Co-Star style description
            Text(card.compatibility.description)
                .font(.body)
                .foregroundColor(CosmicTheme.textPrimary)
                .lineSpacing(4)
                .lineLimit(4)
                .fixedSize(horizontal: false, vertical: true)

            // Advice
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "lightbulb.fill")
                    .font(.caption)
                    .foregroundColor(CosmicTheme.gold)

                Text(card.compatibility.advice)
                    .font(.caption)
                    .foregroundColor(CosmicTheme.textMuted)
                    .lineLimit(2)
            }
            .padding(.top, 4)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Swipe Indicators

    private var swipeIndicators: some View {
        ZStack {
            // Like indicator (right swipe)
            if showLikeIndicator {
                likeIndicator
                    .opacity(Double(min(swipeProgress, 1)))
            }

            // Skip indicator (left swipe)
            if showSkipIndicator {
                skipIndicator
                    .opacity(Double(min(-swipeProgress, 1)))
            }

            // Detail indicator (up swipe)
            if showDetailIndicator {
                detailIndicator
                    .opacity(Double(min(-cardOffset.height / swipeThreshold, 1)))
            }
        }
    }

    private var likeIndicator: some View {
        VStack {
            HStack {
                Spacer()
                ZStack {
                    Circle()
                        .fill(CosmicTheme.positive.opacity(0.9))
                        .frame(width: 60, height: 60)

                    Image(systemName: "heart.fill")
                        .font(.title)
                        .foregroundColor(.white)
                }
                .padding(24)
            }
            Spacer()
        }
    }

    private var skipIndicator: some View {
        VStack {
            HStack {
                ZStack {
                    Circle()
                        .fill(CosmicTheme.negative.opacity(0.9))
                        .frame(width: 60, height: 60)

                    Image(systemName: "xmark")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                .padding(24)
                Spacer()
            }
            Spacer()
        }
    }

    private var detailIndicator: some View {
        VStack {
            ZStack {
                Capsule()
                    .fill(CosmicTheme.gold.opacity(0.9))
                    .frame(width: 120, height: 44)

                HStack(spacing: 6) {
                    Image(systemName: "star.fill")
                        .font(.headline)

                    Text("View")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                .foregroundColor(CosmicTheme.background)
            }
            .padding(.top, 24)
            Spacer()
        }
    }

    // MARK: - Cosmic Match Badge

    @ViewBuilder
    private var cosmicMatchBadge: some View {
        if card.isCosmicMatch {
            HStack(spacing: 6) {
                Image(systemName: "sparkles")
                    .font(.caption)

                Text("COSMIC MATCH")
                    .font(.caption)
                    .fontWeight(.bold)
            }
            .foregroundColor(CosmicTheme.background)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(CosmicTheme.goldGradient)
            )
            .offset(y: -12)
        }
    }

    // MARK: - Card Background

    private var cardBackground: some View {
        ZStack {
            // Base color
            CosmicTheme.cardBackground

            // Gradient overlay based on element
            LinearGradient(
                colors: [
                    elementColor.opacity(0.1),
                    Color.clear
                ],
                startPoint: .topTrailing,
                endPoint: .bottomLeading
            )
        }
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(
                    LinearGradient(
                        colors: [
                            elementColor.opacity(0.4),
                            CosmicTheme.cosmicPurple.opacity(0.2)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
    }

    // MARK: - Helpers

    private var elementColor: Color {
        switch card.stock.zodiacSign.element {
        case .fire:  return Color(red: 1.0, green: 0.4, blue: 0.3)
        case .earth: return Color(red: 0.4, green: 0.75, blue: 0.4)
        case .air:   return Color(red: 0.4, green: 0.6, blue: 0.9)
        case .water: return Color(red: 0.5, green: 0.3, blue: 0.8)
        }
    }

    private var ratingColor: Color {
        switch card.compatibility.rating {
        case .cosmicSoulmates:   return CosmicTheme.gold
        case .highCompatibility: return CosmicTheme.cosmicPurple
        case .neutral:           return CosmicTheme.textSecondary
        case .challenging:       return .orange
        case .cosmicClash:       return CosmicTheme.negative
        }
    }

    private var compatibilityGradient: LinearGradient {
        if card.isCosmicMatch {
            return CosmicTheme.goldGradient
        } else {
            return LinearGradient(
                colors: [CosmicTheme.textPrimary, CosmicTheme.textSecondary],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }
}

// MARK: - Preview

#Preview("Stock Card - Cosmic Match") {
    let stock = MockStockData.all.first { $0.symbol == "AAPL" }!
    let user = UserProfile.sampleWithHoldings
    let card = StockCard(
        stock: stock,
        compatibility: user.compatibility(with: stock)
    )

    ZStack {
        CosmicTheme.background.ignoresSafeArea()

        StockCardView(card: card, cardOffset: .zero, isTopCard: true)
            .frame(height: 600)
            .padding(20)
    }
}

#Preview("Stock Card - Challenging") {
    let stock = MockStockData.all.first { $0.symbol == "JPM" }!
    let user = UserProfile.sampleWithHoldings
    let card = StockCard(
        stock: stock,
        compatibility: user.compatibility(with: stock)
    )

    ZStack {
        CosmicTheme.background.ignoresSafeArea()

        StockCardView(card: card, cardOffset: .zero, isTopCard: true)
            .frame(height: 600)
            .padding(20)
    }
}
