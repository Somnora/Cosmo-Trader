import SwiftUI

// MARK: - StockCardView
// ======================
// A portfolio-aware signal card for stock discovery.
//
// COMPOSITION (visual redesign pass):
//   1. Header row    - ticker plate + name/sector + zodiac glyph
//   2. Price row     - price | daily change (no eyebrow labels)
//   3. Hero score    - large MATCH % + cosmic match pill
//   4. Why Today     - single navy panel with one rationale (the only
//                      explainer on the card)
//
// REMOVED FROM THE ROOT CARD:
//   - CEO context row  → lives in StockDetailView
//   - Standalone advice line → lives in StockDetailView
//   - "PRICE" / "TODAY" eyebrow labels → noise
//   - Separate compatibility section vstack → consolidated
//   - Element-dynamic row → was duplicating Why Today
//
// COMPACT DIFFERENCES:
//   - Tighter padding, smaller score, single-line Why Today.
//   - Zodiac shows glyph only (no sign label).
//   - Subtitle drops sector when name is long.

struct StockCardView: View {

    // MARK: - Environment

    @Environment(AppState.self) private var appState

    // MARK: - Properties

    let card: StockCard
    let cardOffset: CGSize
    let isTopCard: Bool
    let isCompact: Bool
    let onOpenProfile: (() -> Void)?

    init(
        card: StockCard,
        cardOffset: CGSize,
        isTopCard: Bool,
        isCompact: Bool = false,
        onOpenProfile: (() -> Void)? = nil
    ) {
        self.card = card
        self.cardOffset = cardOffset
        self.isTopCard = isTopCard
        self.isCompact = isCompact
        self.onOpenProfile = onOpenProfile
    }

    private let swipeThreshold: CGFloat = 100

    // MARK: - Framing

    private var framingLevel: SignalFramingLevel {
        appState.currentUser?.framingLevel(for: card.stock.symbol) ?? .balanced
    }

    private var signalRatingLabel: String {
        switch card.compatibility.rating {
        case .cosmicSoulmates:   return "STRONG COSMIC MATCH"
        case .highCompatibility: return "POSITIVE MATCH"
        case .neutral:           return "NEUTRAL MATCH"
        case .challenging:       return "MIXED MATCH"
        case .cosmicClash:       return "OPPOSITE ENERGY"
        }
    }

    // MARK: - Computed Properties

    private var swipeProgress: CGFloat {
        cardOffset.width / swipeThreshold
    }

    private var showLikeIndicator: Bool {
        cardOffset.width > 30
    }

    private var showSkipIndicator: Bool {
        cardOffset.width < -30
    }

    private var companyZodiacSign: ZodiacSign? {
        card.stock.foundedZodiacSign
    }

    private var signDisplayName: String {
        companyZodiacSign?.displayName ?? "Unknown"
    }

    // MARK: - Body

    var body: some View {
        GeometryReader { geometry in
            // Hero composition. Score block is centered with VStack
            // spacing balancing the header and the why-today block.
            VStack(spacing: 0) {
                headerSection

                priceSection
                    .padding(.top, isCompact ? 10 : 14)

                Spacer(minLength: isCompact ? 12 : 18)

                scoreSection

                Spacer(minLength: isCompact ? 12 : 18)

                whyTodayPanel
            }
            .padding(.horizontal, isCompact ? 14 : 18)
            .padding(.top, isCompact ? 14 : 20)
            .padding(.bottom, isCompact ? 12 : 18)
            .frame(width: geometry.size.width, height: geometry.size.height, alignment: .top)
            .background(cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(swipeIndicators)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityValue(accessibilityValue)
        .accessibilityHint(accessibilityHint)
        .accessibilityAddTraits(.isButton)
    }

    // MARK: - Accessibility

    private var accessibilityLabel: String {
        var label = "\(card.stock.name), ticker \(card.stock.symbol)"
        if card.isCosmicMatch {
            label += ". High cosmic match."
        }
        return label
    }

    private var accessibilityValue: String {
        let direction = card.stock.isPositive ? "up" : "down"
        var value = "\(card.compatibility.score) percent cosmic match. "
        value += "Price \(card.stock.formattedPrice), \(direction) \(card.stock.formattedPercentageChange). "
        value += "Price source \(card.priceProvenance.shortLabel). "
        if let companyZodiacSign {
            value += "\(companyZodiacSign.displayName) sign, \(companyZodiacSign.element.displayName) element. "
        } else {
            value += "unknown sign, unknown element. "
        }
        value += card.whyToday
        return value
    }

    private var accessibilityHint: String {
        "Swipe right to add to watchlist, swipe left to skip, tap the company name to view profile."
    }

    // MARK: - Header Section

    /// Single-row header. Ticker plate sits left as the brand chip, the
    /// flexible name/subtitle column reads as the primary identifier,
    /// and the zodiac glyph sits right as a small contextual mark.
    private var headerSection: some View {
        let plateSize: CGFloat = isCompact ? 40 : 48
        let glyphBox: CGFloat = isCompact ? 36 : 42
        let glyphSize: CGFloat = isCompact ? 20 : 24

        return HStack(alignment: .center, spacing: 12) {
            // Ticker plate
            ZStack {
                RoundedRectangle(cornerRadius: 4)
                    .fill(CosmicTheme.panelElevated)

                RoundedRectangle(cornerRadius: 4)
                    .stroke(CosmicTheme.borderStrong, lineWidth: 1)

                Text(card.stock.symbol)
                    .font(TerminalFont.ticker(isCompact ? 13 : 15))
                    .fontWeight(.bold)
                    .foregroundColor(CosmicTheme.gold)
                    .lineLimit(1)
                    .minimumScaleFactor(0.55)
                    .padding(.horizontal, 4)
            }
            .frame(width: plateSize, height: plateSize)

            // Name + subtitle. Tapping it opens profile.
            companyTitle

            Spacer(minLength: 4)

            // Zodiac glyph — element-tinted, no label, no decorative box
            // border. Smaller and quieter than before so it reads as
            // contextual ornament rather than a third primary widget.
            ZStack {
                Rectangle()
                    .fill(elementColor.opacity(0.18))

                Rectangle()
                    .stroke(elementColor.opacity(0.45), lineWidth: 1)

                if let companyZodiacSign {
                    ZodiacSymbolView(sign: companyZodiacSign, size: glyphSize, color: elementColor)
                } else {
                    Text("?")
                        .font(.system(size: glyphSize, weight: .semibold, design: .monospaced))
                        .foregroundColor(CosmicTheme.textMuted)
                }
            }
            .frame(width: glyphBox, height: glyphBox)
        }
    }

    @ViewBuilder
    private var companyTitle: some View {
        let nameFont: Font = isCompact ? .title3 : .title2
        let subFont: Font = isCompact ? .caption : .footnote

        let content = VStack(alignment: .leading, spacing: 2) {
            Text(card.stock.name)
                .font(nameFont)
                .fontWeight(.bold)
                .foregroundColor(CosmicTheme.textPrimary)
                .lineLimit(2)
                .minimumScaleFactor(0.8)

            HStack(spacing: 6) {
                Text(signDisplayName.uppercased())
                    .font(TerminalFont.data(isCompact ? 9 : 10, weight: .semibold))
                    .foregroundColor(elementColor)
                    .tracking(1)

                Text("·")
                    .font(.caption2)
                    .foregroundColor(CosmicTheme.textMuted)

                Text(card.stock.sector)
                    .font(subFont)
                    .foregroundColor(CosmicTheme.textSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)

        if onOpenProfile != nil {
            content
                .contentShape(Rectangle())
                .onTapGesture {
                    onOpenProfile?()
                }
        } else {
            content
        }
    }

    // MARK: - Price Section

    /// Confident price + daily move on one row. No "PRICE / TODAY"
    /// eyebrow labels — the values are self-evident, and removing the
    /// labels reclaims ~16pt of vertical real estate for the score.
    private var priceSection: some View {
        let priceSize: CGFloat = isCompact ? 22 : 28
        let changeSize: CGFloat = isCompact ? 13 : 15

        return VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline) {
                Text(card.stock.formattedPrice)
                    .font(TerminalFont.price(priceSize, weight: .semibold))
                    .foregroundColor(CosmicTheme.textPrimary)

                Spacer()

                HStack(spacing: 5) {
                    Image(systemName: card.stock.isPositive ? "arrow.up.right" : "arrow.down.right")
                        .font(.system(size: changeSize - 2, weight: .bold))

                    Text(card.stock.formattedPercentageChange)
                        .font(TerminalFont.data(changeSize, weight: .semibold))
                }
                .foregroundColor(card.stock.isPositive ? CosmicTheme.positive : CosmicTheme.negative)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    Capsule()
                        .fill(card.stock.isPositive ? CosmicTheme.positive.opacity(0.10) : CosmicTheme.negative.opacity(0.10))
                )
                .overlay(
                    Capsule()
                        .stroke(
                            (card.stock.isPositive ? CosmicTheme.positive : CosmicTheme.negative).opacity(0.32),
                            lineWidth: 0.75
                        )
                )
            }

            HStack(spacing: 6) {
                Text(card.priceProvenance.shortLabel.uppercased())
                    .font(TerminalFont.data(8, weight: .bold))
                    .foregroundColor(card.priceProvenance.color)
                    .tracking(0.8)

                Text(card.priceProvenance.detailText.uppercased())
                    .font(TerminalFont.data(8))
                    .foregroundColor(CosmicTheme.textMuted)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
        }
    }

    // MARK: - Score Section (Hero)

    /// The large MATCH score is the visual centerpiece: what the user
    /// reads first. The cosmic match pill below it is the single
    /// rating-language treatment on the card.
    private var scoreSection: some View {
        let scoreSize: CGFloat = isCompact ? 56 : 84
        let pctSize: CGFloat = isCompact ? 26 : 36
        let pillFont: CGFloat = isCompact ? 11 : 12

        return VStack(spacing: isCompact ? 8 : 12) {
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("\(card.compatibility.score)")
                    .font(.system(size: scoreSize, weight: .bold, design: .monospaced))
                    .foregroundStyle(scoreGradient)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)

                Text("%")
                    .font(.system(size: pctSize, weight: .semibold, design: .monospaced))
                    .foregroundStyle(scoreGradient)
                    .baselineOffset(2)

                Text("MATCH")
                    .font(TerminalFont.data(isCompact ? 14 : 16, weight: .semibold))
                    .foregroundColor(CosmicTheme.textSecondary)
                    .tracking(2)
                    .padding(.leading, 6)
            }

            HStack(spacing: 6) {
                Image(systemName: card.compatibility.rating.sfSymbol)
                    .font(.system(size: pillFont, weight: .semibold))
                    .foregroundColor(ratingColor)

                Text(signalRatingLabel)
                    .font(TerminalFont.data(pillFont, weight: .semibold))
                    .foregroundColor(ratingColor)
                    .tracking(1.4)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(ratingColor.opacity(0.12))
            )
            .overlay(
                Capsule()
                    .stroke(ratingColor.opacity(0.32), lineWidth: 0.75)
            )
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Why Today Panel

    /// The single explainer on the card. Replaces the CEO row, the
    /// element-dynamic row, and the standalone advice line — all of
    /// which were competing for the same "context" slot.
    private var whyTodayPanel: some View {
        let bodySize: CGFloat = isCompact ? 11 : 12
        let bodyLines: Int = isCompact ? 3 : 3

        return HStack(alignment: .top, spacing: 10) {
            Image(systemName: "scope")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(CosmicTheme.gold)
                .frame(width: 14, height: 14)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 4) {
                Text("WHY TODAY")
                    .font(TerminalFont.data(9, weight: .semibold))
                    .foregroundColor(CosmicTheme.gold)
                    .tracking(1.4)

                Text(card.whyToday)
                    .font(TerminalFont.data(bodySize))
                    .foregroundColor(CosmicTheme.textPrimary.opacity(0.92))
                    .lineSpacing(2)
                    .lineLimit(bodyLines)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, isCompact ? 12 : 14)
        .padding(.vertical, isCompact ? 10 : 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(CosmicTheme.panelNavy)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .stroke(CosmicTheme.borderNavy, lineWidth: 1)
        )
    }

    // MARK: - Swipe Indicators

    private var swipeIndicators: some View {
        ZStack {
            if showLikeIndicator {
                likeIndicator
                    .opacity(Double(min(swipeProgress, 1)))
            }

            if showSkipIndicator {
                skipIndicator
                    .opacity(Double(min(-swipeProgress, 1)))
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

    // MARK: - Card Background

    private var cardBackground: some View {
        ZStack {
            CosmicTheme.panelElevated

            LinearGradient(
                colors: [
                    elementColor.opacity(0.06),
                    Color.clear
                ],
                startPoint: .topTrailing,
                endPoint: .bottomLeading
            )
        }
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(
                    LinearGradient(
                        colors: [
                            elementColor.opacity(0.4),
                            CosmicTheme.borderStrong
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
        guard let foundedElement = card.stock.foundedElement else {
            return CosmicTheme.textMuted
        }

        switch foundedElement {
        case .fire:  return CosmicTheme.fireElement
        case .earth: return CosmicTheme.earthElement
        case .air:   return CosmicTheme.airElement
        case .water: return CosmicTheme.waterElement
        }
    }

    private var ratingColor: Color {
        switch card.compatibility.rating {
        case .cosmicSoulmates:   return CosmicTheme.gold
        case .highCompatibility: return CosmicTheme.accentBlue
        case .neutral:           return CosmicTheme.textSecondary
        case .challenging:       return .orange
        case .cosmicClash:       return CosmicTheme.negative
        }
    }

    private var scoreGradient: LinearGradient {
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
    let stock = MockStockData.knownStocks.first { $0.symbol == "AAPL" }!
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
    let stock = MockStockData.knownStocks.first { $0.symbol == "JPM" }!
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

#Preview("Stock Card - Compact") {
    let stock = MockStockData.knownStocks.first { $0.symbol == "DIS" } ?? MockStockData.knownStocks.first!
    let user = UserProfile.sampleWithHoldings
    let card = StockCard(
        stock: stock,
        compatibility: user.compatibility(with: stock)
    )

    ZStack {
        CosmicTheme.background.ignoresSafeArea()

        StockCardView(card: card, cardOffset: .zero, isTopCard: true, isCompact: true)
            .frame(height: 380)
            .padding(20)
    }
}
