import SwiftUI

// MARK: - StockDetailView
// ========================
// Full profile view for a single stock.
//
// SECTIONS:
// 1. Header: Company name, ticker, price, zodiac badge
// 2. Compatibility: Score, description, why you match
// 3. Astrological Profile: Birth date, sign traits, corporate personality
// 4. Financial Stats: Price, market cap, 52-week range
// 5. Action Buttons: Add to portfolio/watchlist, share
//
// DESIGN: Premium cosmic dark theme, immersive experience

struct StockDetailView: View {

    // MARK: - Properties

    let stock: Stock

    /// Shared app state
    @Environment(AppState.self) private var appState

    /// Dismiss action for sheet presentation
    @Environment(\.dismiss) private var dismiss

    /// User profile from app state
    private var user: UserProfile {
        appState.currentUser ?? .sampleWithHoldings
    }

    /// Computed compatibility result
    private var compatibility: CompatibilityResult {
        user.compatibility(with: stock)
    }

    /// Check if stock is already in portfolio
    private var isInPortfolio: Bool {
        user.portfolio.contains { $0.symbol == stock.symbol && $0.sharesOwned > 0 }
    }

    /// Check if stock is in watchlist
    private var isInWatchlist: Bool {
        user.watchlist.contains(stock.symbol)
    }

    /// Animation states
    @State private var appearAnimation: Bool = false
    @State private var showShareSheet: Bool = false
    @State private var showAddedConfirmation: Bool = false
    @State private var confirmationMessage: String = ""

    /// Live price data
    @State private var liveStock: Stock
    @State private var isLoadingPrice: Bool = false
    @State private var lastPriceUpdate: Date?
    @State private var priceError: NetworkError?

    // MARK: - Init

    init(stock: Stock) {
        self.stock = stock
        self._liveStock = State(initialValue: stock)
    }

    // MARK: - Body

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                // 1. Header Section
                headerSection

                // 2. Compatibility Section
                compatibilitySection

                // 3. Astrological Profile
                astrologicalProfileSection

                // 4. Saturn Return Analysis (if company is approaching/in Saturn Return)
                SaturnReturnCard(stock: stock)

                // 5. Cosmic Rivals (opposition stocks)
                CosmicRivalCard(stock: stock, allStocks: MockStockData.all)

                // 6. Financial Stats
                financialStatsSection

                // 5. Action Buttons
                actionButtons
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 100)
        }
        .background(backgroundGradient)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(stock.symbol)
                    .font(.headline)
                    .foregroundColor(CosmicTheme.textPrimary)
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button(action: { showShareSheet = true }) {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundColor(CosmicTheme.textSecondary)
                }
            }
        }
        .toolbarBackground(CosmicTheme.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                appearAnimation = true
            }
        }
        .task {
            await fetchLivePrice()
        }
        .sheet(isPresented: $showShareSheet) {
            shareSheet
        }
    }

    // MARK: - Live Price Fetch

    private func fetchLivePrice() async {
        isLoadingPrice = true
        priceError = nil

        let result = await StockAPIService.shared.getQuoteWithFallback(symbol: stock.symbol)

        await MainActor.run {
            if let quote = result.quote {
                liveStock = stock.withQuote(quote)
                lastPriceUpdate = Date()
            }
            if let error = result.error {
                priceError = error
            }
            isLoadingPrice = false
        }
    }

    /// Format the last update time
    private var lastUpdateText: String? {
        guard let lastUpdate = lastPriceUpdate else { return nil }
        let age = Date().timeIntervalSince(lastUpdate)
        let minutes = Int(age / 60)
        if minutes < 1 {
            return "Live"
        } else {
            return "\(minutes)m ago"
        }
    }

    // MARK: - Background

    private var backgroundGradient: some View {
        TerminalBackground(starCount: 30, showGrid: false)
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 20) {
            HStack(alignment: .top) {
                // Company logo placeholder
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(CosmicTheme.secondaryBackground)
                        .frame(width: 72, height: 72)

                    Text(String(stock.symbol.prefix(2)))
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(CosmicTheme.gold)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(stock.name)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(CosmicTheme.textPrimary)

                    HStack(spacing: 8) {
                        Text(stock.symbol)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(CosmicTheme.gold)

                        Text("•")
                            .foregroundColor(CosmicTheme.textMuted)

                        Text(stock.sector)
                            .font(.subheadline)
                            .foregroundColor(CosmicTheme.textSecondary)
                    }
                }

                Spacer()

                // Zodiac badge
                zodiacBadge
            }

            // Price display
            priceDisplay
        }
        .padding(20)
        .background(cardBackground)
        .opacity(appearAnimation ? 1 : 0)
        .offset(y: appearAnimation ? 0 : 20)
    }

    private var zodiacBadge: some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .fill(elementColor.opacity(0.2))
                    .frame(width: 56, height: 56)

                Circle()
                    .stroke(elementColor.opacity(0.5), lineWidth: 1)
                    .frame(width: 56, height: 56)

                // Custom zodiac glyph
                ZodiacSymbolView(sign: stock.zodiacSign, size: 28, color: elementColor)
            }

            Text(stock.zodiacSign.displayName)
                .font(TerminalFont.data(11))
                .foregroundColor(CosmicTheme.textSecondary)
        }
    }

    private var priceDisplay: some View {
        VStack(spacing: 12) {
            // Status and update indicator
            HStack(spacing: 8) {
                MarketStatusBadge()

                Spacer()

                if isLoadingPrice {
                    HStack(spacing: 4) {
                        ProgressView()
                            .scaleEffect(0.5)
                            .tint(CosmicTheme.gold)
                        Text("Updating...")
                            .font(TerminalFont.data(10))
                            .foregroundColor(CosmicTheme.textMuted)
                    }
                } else if let updateText = lastUpdateText {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(CosmicTheme.positive)
                            .frame(width: 6, height: 6)
                        Text(updateText)
                            .font(TerminalFont.data(10))
                            .foregroundColor(CosmicTheme.textMuted)
                    }
                }
            }

            // Main price display using new component
            HStack(alignment: .top) {
                if isLoadingPrice && lastPriceUpdate == nil {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("$----.--")
                            .font(TerminalFont.price(36))
                            .foregroundColor(CosmicTheme.textMuted)
                        Text("---.-- (--.--%)")
                            .font(TerminalFont.data(14))
                            .foregroundColor(CosmicTheme.textMuted)
                    }
                } else {
                    PriceDisplayView(
                        price: liveStock.currentPrice,
                        change: liveStock.priceChange,
                        changePercent: liveStock.percentageChange,
                        size: .hero
                    )
                }

                Spacer()

                // Mini chart placeholder
                VStack(alignment: .trailing, spacing: 4) {
                    Text("7D")
                        .font(TerminalFont.data(9))
                        .foregroundColor(CosmicTheme.textMuted)

                    SmoothMiniChartView(
                        data: generateMockChartData(),
                        width: 80,
                        height: 40,
                        showFill: true,
                        overrideColor: liveStock.isPositive ? CosmicTheme.positive : CosmicTheme.negative
                    )
                }
            }

            // Error indicator
            if let error = priceError {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.caption2)
                    Text(error.suggestedAction)
                        .font(TerminalFont.data(10))
                }
                .foregroundColor(.orange)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(16)
        .background(
            Rectangle()
                .fill(CosmicTheme.secondaryBackground)
        )
        .overlay(
            Rectangle()
                .stroke(CosmicTheme.border, lineWidth: 0.5)
        )
    }

    /// Generate mock chart data based on stock performance
    private func generateMockChartData() -> [Double] {
        let basePrice = liveStock.currentPrice
        let trend = liveStock.isPositive ? 0.005 : -0.005
        return MiniChartView.sampleData(days: 7, trend: trend, volatility: 0.015, startPrice: basePrice * 0.98)
    }

    // MARK: - Compatibility Section

    private var compatibilitySection: some View {
        VStack(spacing: 20) {
            // Section header
            HStack {
                Image(systemName: "sparkles")
                    .foregroundColor(CosmicTheme.gold)

                Text("Cosmic Compatibility")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(CosmicTheme.textPrimary)

                Spacer()

                // Cosmic match badge if applicable
                if compatibility.score >= 85 {
                    cosmicMatchBadge
                }
            }

            // Large compatibility score - monospace terminal style
            HStack(spacing: 12) {
                Text("\(compatibility.score)%")
                    .font(TerminalFont.price(60))
                    .foregroundStyle(scoreGradient)

                VStack(alignment: .leading, spacing: 4) {
                    Text("MATCH")
                        .font(TerminalFont.data(14))
                        .foregroundColor(CosmicTheme.textSecondary)

                    HStack(spacing: 6) {
                        Text(compatibility.rating.emoji)
                        Text(compatibility.rating.displayName.uppercased())
                            .font(TerminalFont.data(12, weight: .semibold))
                            .foregroundColor(ratingColor)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Compatibility description
            Text(compatibility.description)
                .font(.body)
                .foregroundColor(CosmicTheme.textPrimary)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)

            // Why you match breakdown
            whyYouMatchSection

            // Advice
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(CosmicTheme.gold)

                Text(compatibility.advice)
                    .font(.subheadline)
                    .foregroundColor(CosmicTheme.textSecondary)
                    .italic()
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(CosmicTheme.gold.opacity(0.1))
            )
        }
        .padding(20)
        .background(cardBackground)
        .opacity(appearAnimation ? 1 : 0)
        .offset(y: appearAnimation ? 0 : 20)
        .animation(.easeOut(duration: 0.5).delay(0.1), value: appearAnimation)
    }

    private var cosmicMatchBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: "sparkles")
                .font(.caption2)

            Text("COSMIC MATCH")
                .font(.caption2)
                .fontWeight(.bold)
        }
        .foregroundColor(CosmicTheme.background)
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(CosmicTheme.goldGradient)
        )
    }

    private var whyYouMatchSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Why You Match")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(CosmicTheme.textMuted)

            // Element synergy
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(userElementColor.opacity(0.2))
                        .frame(width: 36, height: 36)

                    ElementSymbolView(element: user.sunSign.element, size: 18)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Element Synergy")
                        .font(TerminalFont.data(11, weight: .semibold))
                        .foregroundColor(CosmicTheme.textPrimary)

                    Text(compatibility.elementDynamic)
                        .font(TerminalFont.data(11))
                        .foregroundColor(CosmicTheme.textSecondary)
                        .lineLimit(2)
                }
            }

            Divider()
                .background(CosmicTheme.textMuted.opacity(0.3))

            // Sign connection
            HStack(spacing: 12) {
                HStack(spacing: 4) {
                    ZodiacSymbolView(sign: user.sunSign, size: 20, color: userElementColor)
                    ZodiacSymbolView(sign: stock.zodiacSign, size: 20, color: elementColor)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("\(user.sunSign.displayName) + \(stock.zodiacSign.displayName)")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(CosmicTheme.textPrimary)

                    Text(signConnectionDescription)
                        .font(.caption)
                        .foregroundColor(CosmicTheme.textSecondary)
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(CosmicTheme.secondaryBackground)
        )
    }

    private var signConnectionDescription: String {
        if user.sunSign == stock.zodiacSign {
            return "Same sign energy - deep mutual understanding"
        } else if user.sunSign.element == stock.zodiacSign.element {
            return "Same element - natural elemental harmony"
        } else if user.sunSign.isCompatible(with: stock.zodiacSign) {
            return "Traditional compatibility - cosmic alignment"
        } else {
            return "Contrasting energies - potential for growth"
        }
    }

    // MARK: - Astrological Profile Section

    private var astrologicalProfileSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Section header
            HStack {
                Image(systemName: "moon.stars.fill")
                    .foregroundColor(CosmicTheme.cosmicBlue)

                Text("ASTROLOGICAL PROFILE")
                    .font(TerminalFont.data(12, weight: .semibold))
                    .foregroundColor(CosmicTheme.textPrimary)

                Spacer()
            }

            // Birth info
            birthInfoCard

            // Sign description
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    ZodiacSymbolView(sign: stock.zodiacSign, size: 36, color: elementColor)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(stock.zodiacSign.displayName)
                            .font(TerminalFont.headline(18))
                            .foregroundColor(CosmicTheme.textPrimary)

                        Text(stock.zodiacSign.dateRangeDescription)
                            .font(TerminalFont.data(11))
                            .foregroundColor(CosmicTheme.textMuted)
                    }
                }

                Text(stock.zodiacSign.personalityDescription)
                    .font(.subheadline)
                    .foregroundColor(CosmicTheme.textSecondary)
                    .lineSpacing(4)
            }

            Divider()
                .background(CosmicTheme.textMuted.opacity(0.3))

            // Corporate personality
            VStack(alignment: .leading, spacing: 8) {
                Text("As an Investor, This Company Is...")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(CosmicTheme.textMuted)

                Text(stock.zodiacSign.corporatePersonality)
                    .font(.body)
                    .foregroundColor(CosmicTheme.textPrimary)
                    .lineSpacing(4)
                    .italic()
            }
        }
        .padding(20)
        .background(cardBackground)
        .opacity(appearAnimation ? 1 : 0)
        .offset(y: appearAnimation ? 0 : 20)
        .animation(.easeOut(duration: 0.5).delay(0.2), value: appearAnimation)
    }

    private var birthInfoCard: some View {
        HStack(spacing: 16) {
            // Founded date
            VStack(alignment: .leading, spacing: 4) {
                Text("Founded")
                    .font(.caption)
                    .foregroundColor(CosmicTheme.textMuted)

                Text(stock.formattedFoundedDate)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(CosmicTheme.textPrimary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Divider()
                .frame(height: 40)
                .background(CosmicTheme.textMuted.opacity(0.3))

            // Element
            VStack(alignment: .leading, spacing: 4) {
                Text("Element")
                    .font(TerminalFont.data(10))
                    .foregroundColor(CosmicTheme.textMuted)

                HStack(spacing: 6) {
                    ElementSymbolView(element: stock.zodiacSign.element, size: 14)

                    Text(stock.zodiacSign.element.displayName)
                        .font(TerminalFont.data(13, weight: .semibold))
                        .foregroundColor(elementColor)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Divider()
                .frame(height: 40)
                .background(CosmicTheme.textMuted.opacity(0.3))

            // Modality
            VStack(alignment: .leading, spacing: 4) {
                Text("Modality")
                    .font(.caption)
                    .foregroundColor(CosmicTheme.textMuted)

                Text(stock.zodiacSign.modality.displayName)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(CosmicTheme.textPrimary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(CosmicTheme.secondaryBackground)
        )
    }

    // MARK: - Financial Stats Section

    private var financialStatsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section header
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundColor(CosmicTheme.nebulaBlue)

                Text("FINANCIAL DATA")
                    .font(TerminalFont.data(12, weight: .semibold))
                    .foregroundColor(CosmicTheme.textPrimary)

                Spacer()
            }

            // Day range visualization
            DayRangeDisplayView(
                low: stock.currentPrice * 0.98,
                high: stock.currentPrice * 1.02,
                current: liveStock.currentPrice
            )

            // Bloomberg-style stats grid
            StatsGridView(stats: [
                .price("Price", liveStock.formattedPrice),
                .change("Today", liveStock.percentageChange),
                .gold("Match", "\(compatibility.score)%"),
                .text("Sector", stock.sector),
                .price("Mkt Cap", stock.formattedMarketCap),
                .text("Industry", stock.industry)
            ], columns: 3)

            // 52-week high/low
            HighLowDisplayView(
                high: stock.currentPrice * 1.25,
                low: stock.currentPrice * 0.75
            )
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(CosmicTheme.cardBackground)
            .overlay(
                Rectangle()
                    .stroke(CosmicTheme.border, lineWidth: 0.5)
            )
        }
        .padding(20)
        .background(cardBackground)
        .opacity(appearAnimation ? 1 : 0)
        .offset(y: appearAnimation ? 0 : 20)
        .animation(.easeOut(duration: 0.5).delay(0.3), value: appearAnimation)
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        VStack(spacing: 12) {
            // Add to Portfolio button
            Button(action: addToPortfolio) {
                HStack {
                    Image(systemName: isInPortfolio ? "checkmark.circle.fill" : "plus.circle.fill")

                    Text(isInPortfolio ? "In Portfolio" : "Add to Portfolio")
                        .fontWeight(.semibold)
                }
                .foregroundColor(isInPortfolio ? CosmicTheme.positive : CosmicTheme.background)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(isInPortfolio ? CosmicTheme.positive.opacity(0.2) : nil)
                .background(isInPortfolio ? nil : CosmicTheme.goldGradient)
                .cornerRadius(14)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(isInPortfolio ? CosmicTheme.positive : Color.clear, lineWidth: 2)
                )
            }
            .disabled(isInPortfolio)

            HStack(spacing: 12) {
                // Add to Watchlist - terminal style
                Button(action: addToWatchlist) {
                    HStack {
                        Image(systemName: isInWatchlist ? "heart.fill" : "heart")

                        Text(isInWatchlist ? "Watching" : "Watchlist")
                            .fontWeight(.medium)
                    }
                    .foregroundColor(isInWatchlist ? CosmicTheme.accentBlue : CosmicTheme.textPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(isInWatchlist ? CosmicTheme.accentBlue.opacity(0.2) : Color.clear)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(isInWatchlist ? CosmicTheme.accentBlue : CosmicTheme.border, lineWidth: 0.5)
                    )
                }

                // Share - terminal style
                Button(action: { showShareSheet = true }) {
                    HStack {
                        Image(systemName: "square.and.arrow.up")

                        Text("Share")
                            .fontWeight(.medium)
                    }
                    .foregroundColor(CosmicTheme.textPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(CosmicTheme.border, lineWidth: 0.5)
                    )
                }
            }

            // Confirmation message
            if showAddedConfirmation {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(CosmicTheme.positive)

                    Text(confirmationMessage)
                        .font(.subheadline)
                        .foregroundColor(CosmicTheme.textPrimary)
                }
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(CosmicTheme.positive.opacity(0.15))
                )
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
        }
        .padding(20)
        .background(cardBackground)
        .opacity(appearAnimation ? 1 : 0)
        .offset(y: appearAnimation ? 0 : 20)
        .animation(.easeOut(duration: 0.5).delay(0.4), value: appearAnimation)
    }

    // MARK: - Actions

    private func addToPortfolio() {
        guard !isInPortfolio else { return }

        appState.addToPortfolio(stock, shares: 1)

        confirmationMessage = "\(stock.symbol) added to your portfolio!"
        withAnimation(.spring(response: 0.4)) {
            showAddedConfirmation = true
        }

        // Hide confirmation after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation(.easeOut) {
                showAddedConfirmation = false
            }
        }
    }

    private func addToWatchlist() {
        if isInWatchlist {
            // Remove from watchlist
            appState.removeFromWatchlist(stock.symbol)
            confirmationMessage = "\(stock.symbol) removed from watchlist"
        } else {
            // Add to watchlist
            appState.addToWatchlist(stock.symbol)
            confirmationMessage = "\(stock.symbol) added to watchlist!"
        }

        withAnimation(.spring(response: 0.4)) {
            showAddedConfirmation = true
        }

        // Hide confirmation after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(.easeOut) {
                showAddedConfirmation = false
            }
        }
    }

    // MARK: - Share Sheet

    private var shareSheet: some View {
        NavigationStack {
            ZStack {
                CosmicTheme.background.ignoresSafeArea()

                VStack(spacing: 24) {
                    // Preview card
                    VStack(spacing: 16) {
                        HStack(spacing: 16) {
                            ZodiacSymbolView(sign: stock.zodiacSign, size: 40, color: elementColor)

                            VStack(alignment: .leading) {
                                Text(stock.name)
                                    .font(TerminalFont.headline(16))
                                    .foregroundColor(CosmicTheme.textPrimary)

                                Text("\(stock.symbol) • \(stock.zodiacSign.displayName)")
                                    .font(TerminalFont.data(13))
                                    .foregroundColor(CosmicTheme.textSecondary)
                            }

                            Spacer()

                            Text("\(compatibility.score)% Match")
                                .font(TerminalFont.price(16))
                                .foregroundColor(CosmicTheme.gold)
                        }

                        Text("\"\(compatibility.description)\"")
                            .font(.subheadline)
                            .foregroundColor(CosmicTheme.textSecondary)
                            .italic()
                            .lineLimit(3)
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(CosmicTheme.cardBackground)
                    )

                    Text("Share your cosmic stock match!")
                        .font(.subheadline)
                        .foregroundColor(CosmicTheme.textMuted)

                    Spacer()
                }
                .padding(20)
            }
            .navigationTitle("Share Cosmic Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        showShareSheet = false
                    }
                    .foregroundColor(CosmicTheme.textSecondary)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Share") {
                        // TODO: Implement actual share
                        showShareSheet = false
                    }
                    .foregroundColor(CosmicTheme.gold)
                }
            }
            .toolbarBackground(CosmicTheme.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
        .presentationDetents([.medium])
    }

    // MARK: - Card Background

    private var cardBackground: some View {
        Rectangle()
            .fill(CosmicTheme.cardBackground)
            .overlay(
                Rectangle()
                    .stroke(CosmicTheme.border, lineWidth: 0.5)
            )
    }

    // MARK: - Helpers

    private var elementColor: Color {
        switch stock.zodiacSign.element {
        case .fire:  return CosmicTheme.fireElement
        case .earth: return CosmicTheme.earthElement
        case .air:   return CosmicTheme.airElement
        case .water: return CosmicTheme.waterElement
        }
    }

    private var userElementColor: Color {
        switch user.sunSign.element {
        case .fire:  return CosmicTheme.fireElement
        case .earth: return CosmicTheme.earthElement
        case .air:   return CosmicTheme.airElement
        case .water: return CosmicTheme.waterElement
        }
    }

    private var ratingColor: Color {
        switch compatibility.rating {
        case .cosmicSoulmates:   return CosmicTheme.gold
        case .highCompatibility: return CosmicTheme.accentBlue
        case .neutral:           return CosmicTheme.textSecondary
        case .challenging:       return .orange
        case .cosmicClash:       return CosmicTheme.negative
        }
    }

    private var scoreGradient: LinearGradient {
        if compatibility.score >= 85 {
            return CosmicTheme.goldGradient
        } else if compatibility.score >= 65 {
            return LinearGradient(
                colors: [CosmicTheme.cosmicPurple, CosmicTheme.nebulaBlue],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            return LinearGradient(
                colors: [CosmicTheme.textPrimary, CosmicTheme.textSecondary],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }
}

// MARK: - Stock Formatting Extensions

extension Stock {

    var formattedFoundedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, yyyy"
        return formatter.string(from: foundedDate)
    }

    var formattedMarketCap: String {
        // Mock market cap based on price
        let cap = currentPrice * 1_000_000_000 * Double.random(in: 0.5...2.0)
        if cap >= 1_000_000_000_000 {
            return String(format: "$%.1fT", cap / 1_000_000_000_000)
        } else if cap >= 1_000_000_000 {
            return String(format: "$%.1fB", cap / 1_000_000_000)
        } else {
            return String(format: "$%.1fM", cap / 1_000_000)
        }
    }

    var formatted52WeekHigh: String {
        // Mock 52-week high (10-30% above current)
        let high = currentPrice * Double.random(in: 1.1...1.3)
        return String(format: "$%.2f", high)
    }

    var formatted52WeekLow: String {
        // Mock 52-week low (10-30% below current)
        let low = currentPrice * Double.random(in: 0.7...0.9)
        return String(format: "$%.2f", low)
    }

    var industry: String {
        // Return sector as industry for now
        sector
    }
}

// MARK: - Preview

#Preview("Stock Detail - High Compatibility") {
    NavigationStack {
        StockDetailView(
            stock: MockStockData.all.first { $0.symbol == "AAPL" }!
        )
    }
    .environment(AppState.preview)
    .preferredColorScheme(.dark)
}

#Preview("Stock Detail - Low Compatibility") {
    NavigationStack {
        StockDetailView(
            stock: MockStockData.all.first { $0.symbol == "JPM" }!
        )
    }
    .environment(AppState.preview)
    .preferredColorScheme(.dark)
}
