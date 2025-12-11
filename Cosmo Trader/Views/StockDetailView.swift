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

                // 4. Financial Stats
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
        LinearGradient(
            colors: [
                CosmicTheme.background,
                Color(red: 0.05, green: 0.02, blue: 0.15),
                Color(red: 0.08, green: 0.04, blue: 0.20)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
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
                    .stroke(elementColor.opacity(0.5), lineWidth: 2)
                    .frame(width: 56, height: 56)

                Text(stock.zodiacSign.symbol)
                    .font(.system(size: 28))
            }

            Text(stock.zodiacSign.displayName)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(CosmicTheme.textSecondary)
        }
    }

    private var priceDisplay: some View {
        VStack(spacing: 8) {
            HStack(alignment: .bottom) {
                // Current price
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 4) {
                        Text("Current Price")
                            .font(.caption)
                            .foregroundColor(CosmicTheme.textMuted)

                        if isLoadingPrice {
                            ProgressView()
                                .scaleEffect(0.5)
                                .tint(CosmicTheme.gold)
                        } else if let updateText = lastUpdateText {
                            Text("• \(updateText)")
                                .font(.caption2)
                                .foregroundColor(CosmicTheme.positive)
                        }
                    }

                    if isLoadingPrice && lastPriceUpdate == nil {
                        Text("Loading...")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundColor(CosmicTheme.textMuted)
                    } else {
                        Text(liveStock.formattedPrice)
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundColor(CosmicTheme.textPrimary)
                    }
                }

                Spacer()

                // Daily change
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Today")
                        .font(.caption)
                        .foregroundColor(CosmicTheme.textMuted)

                    HStack(spacing: 6) {
                        Image(systemName: liveStock.isPositive ? "arrow.up.right" : "arrow.down.right")
                            .font(.headline)

                        Text(liveStock.formattedPriceChange)
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(liveStock.isPositive ? CosmicTheme.positive : CosmicTheme.negative)

                    Text(liveStock.formattedPercentageChange)
                        .font(.subheadline)
                        .foregroundColor(liveStock.isPositive ? CosmicTheme.positive : CosmicTheme.negative)
                }
            }

            // Error indicator
            if let error = priceError {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.caption2)
                    Text(error.suggestedAction)
                        .font(.caption2)
                }
                .foregroundColor(.orange)
                .frame(maxWidth: .infinity, alignment: .leading)
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

            // Large compatibility score
            HStack(spacing: 12) {
                Text("\(compatibility.score)%")
                    .font(.system(size: 64, weight: .bold, design: .rounded))
                    .foregroundStyle(scoreGradient)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Match")
                        .font(.title3)
                        .foregroundColor(CosmicTheme.textSecondary)

                    HStack(spacing: 6) {
                        Text(compatibility.rating.emoji)
                        Text(compatibility.rating.displayName)
                            .font(.subheadline)
                            .fontWeight(.semibold)
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

                    Text(user.sunSign.element.emoji)
                        .font(.caption)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Element Synergy")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(CosmicTheme.textPrimary)

                    Text(compatibility.elementDynamic)
                        .font(.caption)
                        .foregroundColor(CosmicTheme.textSecondary)
                        .lineLimit(2)
                }
            }

            Divider()
                .background(CosmicTheme.textMuted.opacity(0.3))

            // Sign connection
            HStack(spacing: 12) {
                HStack(spacing: -8) {
                    Text(user.sunSign.symbol)
                        .font(.title3)

                    Text(stock.zodiacSign.symbol)
                        .font(.title3)
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
                    .foregroundColor(CosmicTheme.cosmicPurple)

                Text("Astrological Profile")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(CosmicTheme.textPrimary)

                Spacer()
            }

            // Birth info
            birthInfoCard

            // Sign description
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(stock.zodiacSign.symbol)
                        .font(.title)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(stock.zodiacSign.displayName)
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(CosmicTheme.textPrimary)

                        Text(stock.zodiacSign.dateRangeDescription)
                            .font(.caption)
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
                    .font(.caption)
                    .foregroundColor(CosmicTheme.textMuted)

                HStack(spacing: 4) {
                    Text(stock.zodiacSign.element.emoji)
                        .font(.caption)

                    Text(stock.zodiacSign.element.displayName)
                        .font(.subheadline)
                        .fontWeight(.semibold)
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

                Text("Financial Stats")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(CosmicTheme.textPrimary)

                Spacer()
            }

            // Stats grid
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                statItem(title: "Price", value: stock.formattedPrice)
                statItem(title: "Market Cap", value: stock.formattedMarketCap)
                statItem(title: "52W High", value: stock.formatted52WeekHigh)
                statItem(title: "52W Low", value: stock.formatted52WeekLow)
                statItem(title: "Sector", value: stock.sector)
                statItem(title: "Industry", value: stock.industry)
            }
        }
        .padding(20)
        .background(cardBackground)
        .opacity(appearAnimation ? 1 : 0)
        .offset(y: appearAnimation ? 0 : 20)
        .animation(.easeOut(duration: 0.5).delay(0.3), value: appearAnimation)
    }

    private func statItem(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(CosmicTheme.textMuted)

            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(CosmicTheme.textPrimary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(CosmicTheme.secondaryBackground)
        )
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
                // Add to Watchlist
                Button(action: addToWatchlist) {
                    HStack {
                        Image(systemName: isInWatchlist ? "heart.fill" : "heart")

                        Text(isInWatchlist ? "Watching" : "Watchlist")
                            .fontWeight(.medium)
                    }
                    .foregroundColor(isInWatchlist ? CosmicTheme.cosmicPurple : CosmicTheme.textPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(isInWatchlist ? CosmicTheme.cosmicPurple.opacity(0.2) : Color.clear)
                    )
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isInWatchlist ? CosmicTheme.cosmicPurple : CosmicTheme.textMuted, lineWidth: 1)
                    )
                }

                // Share
                Button(action: { showShareSheet = true }) {
                    HStack {
                        Image(systemName: "square.and.arrow.up")

                        Text("Share")
                            .fontWeight(.medium)
                    }
                    .foregroundColor(CosmicTheme.textPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(CosmicTheme.textMuted, lineWidth: 1)
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
                        HStack {
                            Text(stock.zodiacSign.symbol)
                                .font(.largeTitle)

                            VStack(alignment: .leading) {
                                Text(stock.name)
                                    .font(.headline)
                                    .foregroundColor(CosmicTheme.textPrimary)

                                Text("\(stock.symbol) • \(stock.zodiacSign.displayName)")
                                    .font(.subheadline)
                                    .foregroundColor(CosmicTheme.textSecondary)
                            }

                            Spacer()

                            Text("\(compatibility.score)% Match")
                                .font(.headline)
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
        RoundedRectangle(cornerRadius: 20)
            .fill(CosmicTheme.cardBackground)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(CosmicTheme.cosmicPurple.opacity(0.2), lineWidth: 1)
            )
    }

    // MARK: - Helpers

    private var elementColor: Color {
        switch stock.zodiacSign.element {
        case .fire:  return Color(red: 1.0, green: 0.4, blue: 0.3)
        case .earth: return Color(red: 0.4, green: 0.75, blue: 0.4)
        case .air:   return Color(red: 0.4, green: 0.6, blue: 0.9)
        case .water: return Color(red: 0.5, green: 0.3, blue: 0.8)
        }
    }

    private var userElementColor: Color {
        switch user.sunSign.element {
        case .fire:  return Color(red: 1.0, green: 0.4, blue: 0.3)
        case .earth: return Color(red: 0.4, green: 0.75, blue: 0.4)
        case .air:   return Color(red: 0.4, green: 0.6, blue: 0.9)
        case .water: return Color(red: 0.5, green: 0.3, blue: 0.8)
        }
    }

    private var ratingColor: Color {
        switch compatibility.rating {
        case .cosmicSoulmates:   return CosmicTheme.gold
        case .highCompatibility: return CosmicTheme.cosmicPurple
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
