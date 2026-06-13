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

    private static let astroOverlayScrollID = "stockDetail.astroOverlay"

    let stock: Stock

    /// Shared app state
    @Environment(AppState.self) private var appState

    /// Dismiss action for sheet presentation
    @Environment(\.dismiss) private var dismiss

    /// User profile from app state (nil if not logged in)
    private var user: UserProfile? {
        appState.currentUser
    }

    /// Verified company sign, nil when the founding/IPO date is unknown.
    private var companyZodiacSign: ZodiacSign? {
        stock.foundedZodiacSign
    }

    private var companyAstroUnavailableText: String {
        "Company founding date is unknown, so zodiac-based readings are unavailable."
    }

    /// Computed compatibility result (nil if no user)
    private var compatibility: CompatibilityResult? {
        guard companyZodiacSign != nil else { return nil }
        return user?.compatibility(with: stock)
    }

    /// Safe compatibility for rendering (uses stock's default when no user)
    private var safeCompatibility: CompatibilityResult {
        guard let companyZodiacSign else {
            return CompatibilityResult(
                userSign: user?.sunSign ?? .aries,
                stockSign: .aries,
                score: 0,
                description: companyAstroUnavailableText,
                advice: "Add a verified founding or IPO date before using company-specific astrology.",
                elementDynamic: companyAstroUnavailableText
            )
        }

        return user?.compatibility(with: stock) ?? CompatibilityResult(
            userSign: .aries,
            stockSign: companyZodiacSign,
            score: 50,
            description: "Sign in to see your personal compatibility",
            advice: "Complete your profile to get personalized cosmic insights.",
            elementDynamic: ""
        )
    }

    /// Check if stock is already in portfolio
    private var isInPortfolio: Bool {
        user?.portfolio.contains { $0.symbol == stock.symbol && $0.sharesOwned > 0 } ?? false
    }

    /// Check if stock is in watchlist
    private var isInWatchlist: Bool {
        user?.watchlist.contains(stock.symbol) ?? false
    }

    /// Animation states
    @State private var appearAnimation: Bool = AppState.isScreenshotMode
    @State private var showShareSheet: Bool = false
    @State private var showAddedConfirmation: Bool = false
    @State private var confirmationMessage: String = ""

    /// Live price data
    @State private var liveStock: Stock
    @State private var isLoadingPrice: Bool = false
    @State private var lastPriceUpdate: Date?
    @State private var priceError: NetworkError?
    @State private var priceProvenance: FinancialDataProvenance = .sample(reason: "Stored local price until provider quote loads")
    @State private var keyStats: StockKeyStats?
    @State private var keyStatsProvenance: FinancialDataProvenance = .unavailable(reason: "Provider fundamentals unavailable")

    /// Chart state
    @State private var selectedTimeframe: ChartTimeframe = .month
    @State private var selectedChartDisplayMode: StockChartDisplayMode = .line
    @State private var chartReloadToken = UUID()
    @State private var historyActivationViewModel = StockDetailHistoryActivationViewModel()

    /// Provider-backed technical context state
    @State private var technicalSummary: StockTechnicalSummary
    @State private var isLoadingTechnicalAnalysis: Bool = !AppState.isScreenshotMode

    /// Cosmic pattern state
    @State private var cosmicInsights: [CosmicPatternInsight] = []
    @State private var isLoadingPatterns: Bool = !AppState.isScreenshotMode

    /// Per-stock framing override (premium feature)
    @State private var showFramingOverrideSheet: Bool = false

    /// Current effective framing level for this stock
    private var effectiveFramingLevel: SignalFramingLevel {
        user?.framingLevel(for: stock.symbol) ?? .balanced
    }

    /// Whether this stock has a custom framing override
    private var hasFramingOverride: Bool {
        user?.stockFramingOverrides[stock.symbol] != nil
    }

    /// Framed zodiac personality description
    private var framedPersonalityDescription: String {
        guard let companyZodiacSign else { return companyAstroUnavailableText }
        return SignalFramingService.shared.frameZodiacPersonality(
            sign: companyZodiacSign,
            level: effectiveFramingLevel
        )
    }

    /// Framed corporate personality description
    private var framedCorporatePersonality: String {
        guard let companyZodiacSign else { return companyAstroUnavailableText }
        return SignalFramingService.shared.frameCorporatePersonality(
            sign: companyZodiacSign,
            level: effectiveFramingLevel
        )
    }

    /// Framed section header for corporate personality
    private var framedCorporateSectionHeader: String {
        switch effectiveFramingLevel {
        case .rational:
            return "Investment Characteristics"
        case .leanRational:
            return "As an Investment, This Company..."
        default:
            return "As an Investor, This Company Is..."
        }
    }

    /// Framed element dynamic description
    private var framedElementDynamic: String {
        guard let companyZodiacSign else { return companyAstroUnavailableText }
        guard let userSign = user?.sunSign else {
            return safeCompatibility.elementDynamic
        }
        return SignalFramingService.shared.frameElementDynamic(
            userElement: userSign.element,
            stockElement: companyZodiacSign.element,
            level: effectiveFramingLevel
        )
    }

    /// Framed CEO leadership insight
    private var framedCEOInsight: String {
        guard let ceoName = stock.ceoName,
              let ceoSign = stock.ceoZodiacSign else {
            return ""
        }
        return SignalFramingService.shared.frameCEOInsight(
            ceoName: ceoName,
            ceoSign: ceoSign,
            level: effectiveFramingLevel
        )
    }

    // MARK: - Init

    init(stock: Stock) {
        self.stock = stock
        self._liveStock = State(initialValue: stock)
        self._technicalSummary = State(initialValue: StockTechnicalAnalysisService.shared.unavailableSummary(
            symbol: stock.symbol,
            reason: "Provider-backed historical candles not loaded"
        ))
    }

    // MARK: - Body

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // 1. Header Section
                    headerSection

                    // 2. Price Chart Section
                    chartSection
                        .id(Self.astroOverlayScrollID)

                    // 3. Technical Lens
                    technicalAnalysisSection

                    // 4. Key Statistics
                    keyStatsSection

                    // 3.25 Upcoming cosmic calendar context
                    upcomingCosmicEventsSection

                    if companyZodiacSign != nil {
                        // 4.5. Cosmic Signals (Technical + Astro Analysis)
                        cosmicSignalsSection

                        // 5. Compatibility Section
                        compatibilitySection

                        // 5.5 Signal Framing Override (Premium)
                        framingOverrideSection

                        // 6. Astrological Profile
                        astrologicalProfileSection
                    } else {
                        unknownCompanyAstroSection
                    }

                    // 3.5 CEO Compatibility (if CEO info available)
                    if stock.hasCEOInfo {
                        ceoCompatibilitySection
                    }

                    if companyZodiacSign != nil {
                        // 4. Saturn Return Analysis (if company is approaching/in Saturn Return)
                        SaturnReturnCard(stock: stock)

                        // 5. Cosmic Rivals (opposition stocks)
                        CosmicRivalCard(stock: stock, allStocks: MockStockData.knownStocks)

                        // 6. Upcoming Earnings with Cosmic Horoscope
                        StockEarningsSection(stock: stock)
                    }

                    // 7. Financial Stats
                    financialStatsSection

                    // 5. Action Buttons
                    actionButtons
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, CosmicTheme.tabBarClearance + 24)
                .iPadReadableContent(maxWidth: 920)
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
                    Button(action: {
                        HapticFeedback.light()
                        showShareSheet = true
                    }) {
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
                if AppState.isScreenshotMode {
                    isLoadingPrice = false
                    isLoadingPatterns = false
                } else {
                    await fetchLivePrice()
                    await fetchKeyStats()
                    await loadTechnicalAnalysis()
                    await loadCosmicPatterns()
                }

                if AppState.shouldFocusAstroOverlayScreenshot {
                    try? await Task.sleep(nanoseconds: 600_000_000)
                    proxy.scrollTo(Self.astroOverlayScrollID, anchor: .top)
                }
            }
            .sheet(isPresented: $showShareSheet) {
                shareSheet
            }
            .sheet(isPresented: $showFramingOverrideSheet) {
                framingOverrideSheet
            }
        }
    }

    // MARK: - Live Price Fetch

    private func fetchLivePrice() async {
        isLoadingPrice = true
        priceError = nil

        let result = await StockAPIService.shared.getQuoteWithProvenance(symbol: stock.symbol)

        await MainActor.run {
            if let quote = result.quote {
                liveStock = stock.withQuote(quote)
                lastPriceUpdate = result.provenance.fetchedAt ?? Date()
                priceProvenance = result.provenance
            } else {
                priceProvenance = .sample(reason: "Stored local price; provider quote unavailable")
            }
            if let error = result.error {
                priceError = error
            }
            isLoadingPrice = false
        }
    }

    private func fetchKeyStats() async {
        let result = await StockAPIService.shared.fetchKeyStatsResult(symbol: stock.symbol)

        await MainActor.run {
            keyStats = result.value
            keyStatsProvenance = result.provenance
        }
    }

    private func loadTechnicalAnalysis() async {
        isLoadingTechnicalAnalysis = true

        do {
            let result = try await HistoricalPriceService.shared.fetchHistoricalPriceResult(
                symbol: liveStock.symbol,
                timeframe: .year
            )
            let summary = StockTechnicalAnalysisService.shared.summary(for: result.dataset)

            await MainActor.run {
                technicalSummary = summary
                isLoadingTechnicalAnalysis = false
            }
        } catch {
            let summary = StockTechnicalAnalysisService.shared.unavailableSummary(
                symbol: liveStock.symbol,
                reason: "Provider-backed historical candles unavailable"
            )

            await MainActor.run {
                technicalSummary = summary
                isLoadingTechnicalAnalysis = false
            }
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
            HStack(alignment: .top, spacing: 14) {
                // Ticker plate. Shows the FULL symbol (not the first two
                // letters) so DIS reads as "DIS", not "DI". Uses
                // monospace + minimumScaleFactor so 1-5 char tickers
                // all fit cleanly.
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(CosmicTheme.panelElevated)
                        .frame(width: 72, height: 72)

                    RoundedRectangle(cornerRadius: 12)
                        .stroke(CosmicTheme.gold.opacity(0.35), lineWidth: 1)
                        .frame(width: 72, height: 72)

                    Text(stock.symbol)
                        .font(TerminalFont.ticker(22))
                        .fontWeight(.bold)
                        .foregroundColor(CosmicTheme.gold)
                        .lineLimit(1)
                        .minimumScaleFactor(0.55)
                        .padding(.horizontal, 6)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(stock.name)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(CosmicTheme.textPrimary)
                        .lineLimit(2)
                        .minimumScaleFactor(0.85)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(stock.sector)
                        .font(.subheadline)
                        .foregroundColor(CosmicTheme.textSecondary)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

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

                if let companyZodiacSign {
                    // Custom zodiac glyph
                    ZodiacSymbolView(sign: companyZodiacSign, size: 28, color: elementColor)
                } else {
                    Image(systemName: "questionmark")
                        .font(TerminalFont.data(18, weight: .semibold))
                        .foregroundColor(CosmicTheme.textMuted)
                }
            }

            Text(companyZodiacSign?.displayName ?? "Unknown")
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

            ViewThatFits(in: .horizontal) {
                HStack(alignment: .top, spacing: 12) {
                    priceValueAndSource
                    Spacer(minLength: 8)
                    unavailableMiniChart
                }

                VStack(alignment: .leading, spacing: 12) {
                    priceValueAndSource
                    unavailableMiniChart
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }

            // Error indicator. Only surface user-actionable connectivity
            // states; suppress configuration/diagnostic errors like
            // `apiKeyMissing` ("Contact support") since we already
            // render the cached price and that copy reads as a bug to
            // the user.
            if let error = priceError, shouldSurface(error) {
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

    private var priceValueAndSource: some View {
        HStack(alignment: .top, spacing: 8) {
            priceValue
                .layoutPriority(1)

            DataSourceIndicator(provenance: priceProvenance, size: .compact)
                .padding(.top, 4)
                .fixedSize()
        }
    }

    @ViewBuilder
    private var priceValue: some View {
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
    }

    private var unavailableMiniChart: some View {
        // No provider-backed 7D sparkline exists here yet, so avoid rendering
        // generated samples as market history.
        VStack(alignment: .trailing, spacing: 4) {
            Text("7D")
                .font(TerminalFont.data(9))
                .foregroundColor(CosmicTheme.textMuted)

            VStack(spacing: 3) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(CosmicTheme.textMuted)
                Text("N/A")
                    .font(TerminalFont.data(9, weight: .bold))
                    .foregroundColor(CosmicTheme.textMuted)
            }
            .frame(width: 80, height: 40)
            .background(CosmicTheme.cardBackground.opacity(0.55))
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(CosmicTheme.borderDim, lineWidth: 0.5)
            )
        }
    }

    /// Whether to surface a price-fetch error to the user inline.
    /// Configuration errors (no API key) read as scary support copy
    /// even though the cached price is fine, so we hide them here.
    private func shouldSurface(_ error: NetworkError) -> Bool {
        switch error {
        case .apiKeyMissing, .invalidSymbol:
            return false
        default:
            return true
        }
    }

    // MARK: - Chart Section

    private var chartSection: some View {
        VStack(spacing: 14) {
            if SubscriptionManager.shared.canAccess(.historicalAstroOverlay) || AppState.isScreenshotMode {
                HistoricalAstroChartView(
                    stock: liveStock,
                    selectedTimeframe: $selectedTimeframe,
                    selectedDisplayMode: $selectedChartDisplayMode
                )
                .id(chartReloadToken)
            } else {
                StockChartView(
                    stock: liveStock,
                    selectedTimeframe: $selectedTimeframe,
                    selectedDisplayMode: $selectedChartDisplayMode
                )
                .id(chartReloadToken)

                HistoricalAstroOverlayLockedCard()
            }

            stockHistoryActivationCard
        }
        .padding(16)
        .background(cardBackground)
        .opacity(appearAnimation ? 1 : 0)
        .offset(y: appearAnimation ? 0 : 20)
        .accessibilityIdentifier("stock.upcomingCosmicEvents")
    }

    private var stockHistoryActivationCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: historyActivationViewModel.state.isLoading ? "arrow.triangle.2.circlepath" : "clock.arrow.circlepath")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(CosmicTheme.gold)

                VStack(alignment: .leading, spacing: 4) {
                    Text(historyActivationViewModel.state.title.uppercased())
                        .font(TerminalFont.data(10, weight: .bold))
                        .foregroundColor(CosmicTheme.textPrimary)
                        .tracking(1)

                    Text(historyActivationViewModel.state.message)
                        .font(TerminalFont.data(10))
                        .foregroundColor(CosmicTheme.textSecondary)
                        .lineSpacing(3)
                }

                Spacer(minLength: 8)

                DataSourceIndicator(provenance: historyActivationViewModel.state.provenance, size: .compact)
                    .fixedSize()
            }

            VStack(spacing: 7) {
                ForEach(historyActivationViewModel.state.contextRows) { row in
                    HStack(spacing: 10) {
                        Text(row.title.uppercased())
                            .font(TerminalFont.data(8, weight: .bold))
                            .foregroundColor(CosmicTheme.textMuted)
                            .tracking(0.8)

                        Spacer()

                        Text(row.status)
                            .font(TerminalFont.data(9))
                            .foregroundColor(CosmicTheme.textSecondary)
                            .multilineTextAlignment(.trailing)
                    }
                }
            }

            Button {
                Task {
                    await refreshProviderHistory()
                }
            } label: {
                HStack(spacing: 8) {
                    if historyActivationViewModel.state.isLoading {
                        ProgressView()
                            .scaleEffect(0.62)
                            .tint(CosmicTheme.terminalBlack)
                    } else {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 11, weight: .bold))
                    }

                    Text(historyActivationViewModel.state.actionTitle.uppercased())
                        .font(TerminalFont.data(10, weight: .bold))
                        .tracking(1)
                }
                .foregroundColor(CosmicTheme.terminalBlack)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(CosmicTheme.gold)
            }
            .buttonStyle(.plain)
            .disabled(historyActivationViewModel.state.isLoading)
            .opacity(historyActivationViewModel.state.isLoading ? 0.72 : 1)

            Text("Historical context only. Not financial advice.")
                .font(TerminalFont.data(8))
                .foregroundColor(CosmicTheme.textMuted)
        }
        .padding(12)
        .background(CosmicTheme.secondaryBackground.opacity(0.7))
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(CosmicTheme.borderDim, lineWidth: 0.5)
        )
    }

    private func refreshProviderHistory() async {
        let didLoad = await historyActivationViewModel.refresh(
            symbol: liveStock.symbol,
            timeframe: selectedTimeframe
        )

        guard didLoad else { return }

        chartReloadToken = UUID()
        await loadTechnicalAnalysis()
        await loadCosmicPatterns()
    }

    // MARK: - Key Stats Section

    private var keyStatsSection: some View {
        StockKeyStatsView(stats: keyStats)
            .padding(16)
            .background(cardBackground)
            .opacity(appearAnimation ? 1 : 0)
            .offset(y: appearAnimation ? 0 : 20)
    }

    // MARK: - Technical Analysis Section

    private var technicalAnalysisSection: some View {
        StockTechnicalAnalysisView(
            summary: technicalSummary,
            isLoading: isLoadingTechnicalAnalysis,
            refreshAction: {
                Task {
                    await loadTechnicalAnalysis()
                }
            }
        )
        .padding(16)
        .background(cardBackground)
        .opacity(appearAnimation ? 1 : 0)
        .offset(y: appearAnimation ? 0 : 20)
    }

    // MARK: - Cosmic Signals Section

    private var cosmicSignalsSection: some View {
        CosmicSignalsSection(
            insights: cosmicInsights,
            isLoading: isLoadingPatterns
        )
        .padding(16)
        .background(cardBackground)
        .opacity(appearAnimation ? 1 : 0)
        .offset(y: appearAnimation ? 0 : 20)
    }

    private func loadCosmicPatterns() async {
        guard companyZodiacSign != nil else {
            await MainActor.run {
                cosmicInsights = []
                isLoadingPatterns = false
            }
            return
        }

        isLoadingPatterns = true

        let interpreter = CosmicPatternInterpreter.shared
        let insights = await interpreter.getProviderBackedInsights(
            for: liveStock,
            userSign: user?.sunSign ?? .aries
        )

        await MainActor.run {
            cosmicInsights = insights
            isLoadingPatterns = false
        }
    }

    // MARK: - Upcoming Cosmic Events

    private var upcomingCosmicEvents: [AstroOverlayEvent] {
        AstroOverlayEventService.shared.upcomingEvents(
            for: liveStock,
            days: 30,
            filters: .stockCosmicCalendar
        )
    }

    private var upcomingCosmicEventsSection: some View {
        let events = upcomingCosmicEvents

        return VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: "calendar.badge.clock")
                    .foregroundColor(CosmicTheme.gold)

                VStack(alignment: .leading, spacing: 2) {
                    Text("UPCOMING COSMIC EVENTS")
                        .font(TerminalFont.data(12, weight: .semibold))
                        .foregroundColor(CosmicTheme.textPrimary)
                        .tracking(0.8)

                    Text("Next 30 days for \(stock.symbol)")
                        .font(TerminalFont.data(10))
                        .foregroundColor(CosmicTheme.textMuted)
                }

                Spacer()

                Text("CALENDAR")
                    .font(TerminalFont.data(8, weight: .bold))
                    .foregroundColor(CosmicTheme.gold)
                    .tracking(0.8)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(CosmicTheme.gold.opacity(0.10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(CosmicTheme.gold.opacity(0.45), lineWidth: 0.75)
                    )
            }

            Text("Cosmic calendar context only. Not predictive and not financial advice.")
                .font(TerminalFont.data(10))
                .foregroundColor(CosmicTheme.textSecondary)
                .lineSpacing(3)

            if events.isEmpty {
                cosmicCalendarEmptyState
            } else {
                VStack(spacing: 8) {
                    ForEach(events.prefix(5)) { event in
                        cosmicCalendarRow(event)
                    }

                    if events.count > 5 {
                        Text("+\(events.count - 5) more calendar events in this window")
                            .font(TerminalFont.data(10))
                            .foregroundColor(CosmicTheme.textMuted)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }

            companySpecificCalendarNote
        }
        .padding(16)
        .background(cardBackground)
        .opacity(appearAnimation ? 1 : 0)
        .offset(y: appearAnimation ? 0 : 20)
    }

    private var cosmicCalendarEmptyState: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "moon")
                .foregroundColor(CosmicTheme.textMuted)

            Text("No enabled cosmic calendar events were found in the next 30 days.")
                .font(TerminalFont.data(11))
                .foregroundColor(CosmicTheme.textSecondary)
                .lineSpacing(3)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(CosmicTheme.secondaryBackground)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(CosmicTheme.borderDim, lineWidth: 0.75)
        )
    }

    private var companySpecificCalendarNote: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: stock.supportsCompanyOverlayEvents ? "checkmark.seal" : "info.circle")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(stock.supportsCompanyOverlayEvents ? CosmicTheme.positive : CosmicTheme.textMuted)

            Text(stock.supportsCompanyOverlayEvents
                ? "Company-specific events use verified founding metadata where available."
                : "Company-specific events need verified founding metadata. Broad moon and Mercury events still appear.")
                .font(TerminalFont.data(10))
                .foregroundColor(CosmicTheme.textMuted)
                .lineSpacing(2)
        }
        .accessibilityIdentifier("stock.upcomingCosmicEvents.metadataNote")
    }

    private func cosmicCalendarRow(_ event: AstroOverlayEvent) -> some View {
        HStack(alignment: .top, spacing: 10) {
            ZStack {
                Circle()
                    .fill(event.kind.overlayColor.opacity(0.16))
                    .frame(width: 34, height: 34)

                Image(systemName: event.iconSystemName)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(event.kind.overlayColor)
            }
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 5) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(event.title.uppercased())
                        .font(TerminalFont.data(11, weight: .bold))
                        .foregroundColor(CosmicTheme.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)

                    Text(cosmicCalendarDateText(for: event))
                        .font(TerminalFont.data(10, weight: .semibold))
                        .foregroundColor(event.kind.overlayColor)
                        .lineLimit(1)

                    Spacer(minLength: 0)
                }

                Text(cosmicCalendarReason(for: event))
                    .font(TerminalFont.data(10))
                    .foregroundColor(CosmicTheme.textSecondary)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)

                Text(event.source.displayLabel.uppercased())
                    .font(TerminalFont.data(8, weight: .bold))
                    .foregroundColor(CosmicTheme.textMuted)
                    .tracking(0.7)
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(CosmicTheme.secondaryBackground)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(event.kind.overlayColor.opacity(0.22), lineWidth: 0.75)
        )
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("stock.upcomingCosmicEvents.row.\(event.kind.rawValue)")
    }

    private func cosmicCalendarDateText(for event: AstroOverlayEvent) -> String {
        if event.isRange, let endDate = event.endDate {
            return "\(Self.cosmicCalendarDateFormatter.string(from: event.startDate)) - \(Self.cosmicCalendarDateFormatter.string(from: endDate))"
        }
        return Self.cosmicCalendarDateFormatter.string(from: event.markerDate)
    }

    private func cosmicCalendarReason(for event: AstroOverlayEvent) -> String {
        switch event.kind {
        case .newMoon:
            return "Broad lunar calendar context for \(stock.symbol)."
        case .fullMoon:
            return "Broad lunar calendar context for \(stock.symbol)."
        case .mercuryRetrograde:
            return "Mercury retrograde range from curated ephemeris. Calendar context only."
        case .moonInSign:
            if let companyZodiacSign {
                return "Moon moves through \(companyZodiacSign.displayName), \(stock.symbol)'s company sign."
            }
            return "Company sign unavailable, so this event is not shown for this stock."
        case .companyBirthMonth:
            return "Uses verified founding month for \(stock.symbol)."
        case .companyFoundingAnniversary:
            return "Uses verified founding date for \(stock.symbol)."
        case .firstQuarter, .lastQuarter:
            return "Broad lunar calendar context for \(stock.symbol)."
        case .eclipse, .planetaryIngress:
            return "Cosmic calendar context for \(stock.symbol)."
        }
    }

    private static let cosmicCalendarDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter
    }()

    private var unknownCompanyAstroSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: "questionmark.circle")
                    .foregroundColor(CosmicTheme.textMuted)

                Text("COMPANY ASTROLOGY")
                    .font(TerminalFont.data(12, weight: .semibold))
                    .foregroundColor(CosmicTheme.textPrimary)

                Spacer()
            }

            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Founded")
                        .font(TerminalFont.data(10))
                        .foregroundColor(CosmicTheme.textMuted)

                    Text("Unknown")
                        .font(TerminalFont.data(13, weight: .semibold))
                        .foregroundColor(CosmicTheme.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Sign")
                        .font(TerminalFont.data(10))
                        .foregroundColor(CosmicTheme.textMuted)

                    Text("Unknown")
                        .font(TerminalFont.data(13, weight: .semibold))
                        .foregroundColor(CosmicTheme.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            Text(companyAstroUnavailableText)
                .font(TerminalFont.data(11))
                .foregroundColor(CosmicTheme.textSecondary)
                .lineSpacing(3)
        }
        .padding(20)
        .background(cardBackground)
        .opacity(appearAnimation ? 1 : 0)
        .offset(y: appearAnimation ? 0 : 20)
        .animation(.easeOut(duration: 0.5).delay(0.1), value: appearAnimation)
    }

    // MARK: - Compatibility Section

    private var compatibilitySection: some View {
        VStack(spacing: 20) {
            // Section header
            HStack {
                Image(systemName: "scope")
                    .foregroundColor(CosmicTheme.gold)

                Text("Cosmic Match")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(CosmicTheme.textPrimary)

                Spacer()

                // Cosmic match badge if applicable
                if safeCompatibility.score >= 85 {
                    cosmicMatchBadge
                }
            }

            // Large compatibility score - monospace terminal style
            HStack(spacing: 12) {
                Text("\(safeCompatibility.score)%")
                    .font(TerminalFont.price(60))
                    .foregroundStyle(scoreGradient)

                VStack(alignment: .leading, spacing: 4) {
                    Text("MATCH")
                        .font(TerminalFont.data(14))
                        .foregroundColor(CosmicTheme.textSecondary)

                    HStack(spacing: 6) {
                        Image(systemName: safeCompatibility.rating.sfSymbol)
                            .foregroundColor(ratingColor)
                        Text(safeCompatibility.rating.displayName.uppercased())
                            .font(TerminalFont.data(12, weight: .semibold))
                            .foregroundColor(ratingColor)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Compatibility description
            Text(safeCompatibility.description)
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

                Text(safeCompatibility.advice)
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
                Image(systemName: "scope")
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

            if let companyZodiacSign {
                // Element synergy
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(userElementColor.opacity(0.2))
                            .frame(width: 36, height: 36)

                        ElementSymbolView(element: (user?.sunSign ?? .aries).element, size: 18)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Element Synergy")
                            .font(TerminalFont.data(11, weight: .semibold))
                            .foregroundColor(CosmicTheme.textPrimary)

                        Text(framedElementDynamic)
                            .font(TerminalFont.data(11))
                            .foregroundColor(CosmicTheme.textSecondary)
                            .lineLimit(2)
                    }
                }

                Divider()
                    .background(CosmicTheme.textMuted.opacity(0.4))

                // Sign connection
                HStack(spacing: 12) {
                    HStack(spacing: 4) {
                        ZodiacSymbolView(sign: user?.sunSign ?? .aries, size: 20, color: userElementColor)
                        ZodiacSymbolView(sign: companyZodiacSign, size: 20, color: elementColor)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("\((user?.sunSign ?? .aries).displayName) + \(companyZodiacSign.displayName)")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(CosmicTheme.textPrimary)

                        Text(signConnectionDescription)
                            .font(.caption)
                            .foregroundColor(CosmicTheme.textSecondary)
                    }
                }
            } else {
                Text(companyAstroUnavailableText)
                    .font(TerminalFont.data(11))
                    .foregroundColor(CosmicTheme.textSecondary)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(CosmicTheme.secondaryBackground)
        )
    }

    private var signConnectionDescription: String {
        guard let companyZodiacSign else { return companyAstroUnavailableText }

        if user?.sunSign ?? .aries == companyZodiacSign {
            return "Same sign energy - deep mutual understanding"
        } else if (user?.sunSign ?? .aries).element == companyZodiacSign.element {
            return "Same element - natural elemental harmony"
        } else if (user?.sunSign ?? .aries).isCompatible(with: companyZodiacSign) {
            return "Traditional compatibility - aligned energy"
        } else {
            return "Contrasting energies - potential for growth"
        }
    }

    // MARK: - Astrological Profile Section

    @ViewBuilder
    private var astrologicalProfileSection: some View {
        if let companyZodiacSign {
            astrologicalProfileContent(for: companyZodiacSign)
        } else {
            unknownCompanyAstroSection
        }
    }

    private func astrologicalProfileContent(for companyZodiacSign: ZodiacSign) -> some View {
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
                    ZodiacSymbolView(sign: companyZodiacSign, size: 36, color: elementColor)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(companyZodiacSign.displayName)
                            .font(TerminalFont.headline(18))
                            .foregroundColor(CosmicTheme.textPrimary)

                        Text(companyZodiacSign.dateRangeDescription)
                            .font(TerminalFont.data(11))
                            .foregroundColor(CosmicTheme.textMuted)
                    }
                }

                Text(framedPersonalityDescription)
                    .font(.subheadline)
                    .foregroundColor(CosmicTheme.textSecondary)
                    .lineSpacing(4)
            }

            Divider()
                .background(CosmicTheme.textMuted.opacity(0.4))

            // Corporate personality (framed)
            VStack(alignment: .leading, spacing: 8) {
                Text(framedCorporateSectionHeader)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(CosmicTheme.textMuted)

                Text(framedCorporatePersonality)
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
                .background(CosmicTheme.textMuted.opacity(0.4))

            // Element
            VStack(alignment: .leading, spacing: 4) {
                Text("Element")
                    .font(TerminalFont.data(10))
                    .foregroundColor(CosmicTheme.textMuted)

                if let companyZodiacSign {
                    HStack(spacing: 6) {
                        ElementSymbolView(element: companyZodiacSign.element, size: 14)

                        Text(companyZodiacSign.element.displayName)
                            .font(TerminalFont.data(13, weight: .semibold))
                            .foregroundColor(elementColor)
                    }
                } else {
                    Text("Unknown")
                        .font(TerminalFont.data(13, weight: .semibold))
                        .foregroundColor(CosmicTheme.textSecondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Divider()
                .frame(height: 40)
                .background(CosmicTheme.textMuted.opacity(0.4))

            // Modality
            VStack(alignment: .leading, spacing: 4) {
                Text("Modality")
                    .font(.caption)
                    .foregroundColor(CosmicTheme.textMuted)

                Text(companyZodiacSign?.modality.displayName ?? "Unknown")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(companyZodiacSign == nil ? CosmicTheme.textSecondary : CosmicTheme.textPrimary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(CosmicTheme.secondaryBackground)
        )
    }

    // MARK: - CEO Compatibility Section

    private var ceoCompatibilitySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section header
            HStack {
                Image(systemName: "person.fill.checkmark")
                    .foregroundColor(CosmicTheme.accentBlue)

                Text("CEO ASTRO PROFILE")
                    .font(TerminalFont.data(12, weight: .semibold))
                    .foregroundColor(CosmicTheme.textPrimary)

                Spacer()
            }

            // CEO info card
            if let ceoName = stock.ceoName, let ceoSign = stock.ceoZodiacSign {
                VStack(spacing: 16) {
                    // CEO header with zodiac
                    HStack(spacing: 16) {
                        // CEO avatar
                        ZStack {
                            Circle()
                                .fill(ceoElementColor.opacity(0.2))
                                .frame(width: 56, height: 56)

                            Circle()
                                .stroke(ceoElementColor.opacity(0.5), lineWidth: 1)
                                .frame(width: 56, height: 56)

                            ZodiacSymbolView(sign: ceoSign, size: 28, color: ceoElementColor)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text(ceoName)
                                .font(TerminalFont.headline(16))
                                .foregroundColor(CosmicTheme.textPrimary)

                            HStack(spacing: 8) {
                                Text(ceoSign.displayName)
                                    .font(TerminalFont.data(12, weight: .semibold))
                                    .foregroundColor(ceoElementColor)

                                Text("•")
                                    .foregroundColor(CosmicTheme.textMuted)

                                Text(ceoSign.element.displayName)
                                    .font(TerminalFont.data(12))
                                    .foregroundColor(CosmicTheme.textSecondary)
                            }

                            Text("Chief Executive Officer")
                                .font(TerminalFont.data(10))
                                .foregroundColor(CosmicTheme.textMuted)
                        }

                        Spacer()
                    }

                    Divider()
                        .background(CosmicTheme.textMuted.opacity(0.4))

                    // CEO-User compatibility
                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Your Alignment with \(ceoName.components(separatedBy: " ").first ?? "CEO")")
                                .font(TerminalFont.data(11, weight: .semibold))
                                .foregroundColor(CosmicTheme.textMuted)

                            HStack(spacing: 12) {
                                // User's sign
                                ZodiacSymbolView(sign: user?.sunSign ?? .aries, size: 24, color: userElementColor)

                                // Connection indicator
                                HStack(spacing: 4) {
                                    ForEach(0..<3) { index in
                                        Circle()
                                            .fill(ceoCompatibilityDots(index))
                                            .frame(width: 6, height: 6)
                                    }
                                }

                                // CEO's sign
                                ZodiacSymbolView(sign: ceoSign, size: 24, color: ceoElementColor)

                                Spacer()

                                // Compatibility score
                                Text("\(ceoCompatibilityScore)%")
                                    .font(TerminalFont.price(24))
                                    .foregroundColor(ceoCompatibilityColor)
                            }

                            Text(ceoCompatibilityDescription)
                                .font(TerminalFont.data(11))
                                .foregroundColor(CosmicTheme.textSecondary)
                                .lineSpacing(2)
                        }
                    }

                    // Leadership insight
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "lightbulb.fill")
                            .foregroundColor(CosmicTheme.accentBlue)

                        Text(framedCEOInsight)
                            .font(TerminalFont.data(11))
                            .foregroundColor(CosmicTheme.textSecondary)
                            .italic()
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(CosmicTheme.accentBlue.opacity(0.1))
                    )
                }
            }
        }
        .padding(20)
        .background(cardBackground)
        .opacity(appearAnimation ? 1 : 0)
        .offset(y: appearAnimation ? 0 : 20)
        .animation(.easeOut(duration: 0.5).delay(0.25), value: appearAnimation)
    }

    // MARK: - CEO Compatibility Helpers

    private var ceoElementColor: Color {
        guard let element = stock.ceoElement else { return CosmicTheme.textSecondary }
        switch element {
        case .fire:  return CosmicTheme.fireElement
        case .earth: return CosmicTheme.earthElement
        case .air:   return CosmicTheme.airElement
        case .water: return CosmicTheme.waterElement
        }
    }

    private var ceoCompatibilityScore: Int {
        guard let ceoSign = stock.ceoZodiacSign else { return 50 }
        return (user?.sunSign ?? .aries).compatibilityScore(with: ceoSign)
    }

    private var ceoCompatibilityColor: Color {
        let score = ceoCompatibilityScore
        if score >= 85 { return CosmicTheme.gold }
        if score >= 70 { return CosmicTheme.accentBlue }
        if score >= 50 { return CosmicTheme.textPrimary }
        return .orange
    }

    private func ceoCompatibilityDots(_ index: Int) -> Color {
        let score = ceoCompatibilityScore
        let threshold = [50, 70, 85]
        return score >= threshold[index] ? ceoCompatibilityColor : CosmicTheme.textMuted.opacity(0.4)
    }

    private var ceoCompatibilityDescription: String {
        guard let ceoSign = stock.ceoZodiacSign else { return "" }
        let score = ceoCompatibilityScore

        if user?.sunSign ?? .aries == ceoSign {
            return "You share the same sign as the CEO - deep natural understanding and aligned vision."
        } else if (user?.sunSign ?? .aries).element == ceoSign.element {
            return "Same elemental energy creates intuitive trust in their leadership decisions."
        } else if score >= 85 {
            return "Excellent alignment - the CEO's profile fits your investment style."
        } else if score >= 70 {
            return "Good compatibility - their leadership approach complements your investor energy."
        } else if score >= 50 {
            return "Balanced dynamics - different perspectives can offer diversified opportunities."
        } else {
            return "Contrasting energies - exercise extra due diligence on leadership decisions."
        }
    }

    private var ceoLeadershipInsight: String {
        guard let ceoSign = stock.ceoZodiacSign, let ceoName = stock.ceoName else { return "" }
        let firstName = ceoName.components(separatedBy: " ").first ?? "The CEO"

        switch ceoSign {
        case .aries:
            return "\(firstName)'s Aries drive brings bold, pioneering leadership. Expect aggressive growth strategies and first-mover initiatives."
        case .taurus:
            return "\(firstName)'s Taurus energy emphasizes stability and long-term value creation. Methodical, patient approach to business."
        case .gemini:
            return "\(firstName)'s Gemini versatility enables quick pivots and excellent communication. Strong media presence and adaptability."
        case .cancer:
            return "\(firstName)'s Cancer intuition creates a nurturing corporate culture focused on employee and customer loyalty."
        case .leo:
            return "\(firstName)'s Leo charisma inspires teams and attracts attention. Bold vision with a flair for brand building."
        case .virgo:
            return "\(firstName)'s Virgo precision drives operational excellence. Detail-oriented approach to quality and efficiency."
        case .libra:
            return "\(firstName)'s Libra diplomacy excels at partnerships and creating balance. Strategic alliance-focused leadership."
        case .scorpio:
            return "\(firstName)'s Scorpio intensity brings transformative leadership. Deep strategic thinking and resilience through challenges."
        case .sagittarius:
            return "\(firstName)'s Sagittarius optimism fuels international expansion and big-picture thinking. Adventurous growth strategy."
        case .capricorn:
            return "\(firstName)'s Capricorn discipline builds sustainable long-term success. Conservative, structured approach to growth."
        case .aquarius:
            return "\(firstName)'s Aquarius innovation disrupts industries. Forward-thinking, technology-focused leadership."
        case .pisces:
            return "\(firstName)'s Pisces creativity brings imaginative solutions. Empathetic leadership with strong brand storytelling."
        }
    }

    // MARK: - Framing Override Section (Premium)

    private var framingOverrideSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section header
            HStack {
                Image(systemName: "slider.horizontal.below.square.filled.and.square")
                    .foregroundColor(CosmicTheme.gold)

                Text("SIGNAL FRAMING")
                    .font(TerminalFont.data(12, weight: .semibold))
                    .foregroundColor(CosmicTheme.textPrimary)

                Spacer()

                // Current level badge
                SignalFramingIndicator(level: effectiveFramingLevel)
            }

            // Framing info
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(hasFramingOverride ? "Custom Framing" : "Using Global Setting")
                            .font(TerminalFont.data(12, weight: .semibold))
                            .foregroundColor(CosmicTheme.textPrimary)

                        Text(effectiveFramingLevel.description)
                            .font(TerminalFont.data(11))
                            .foregroundColor(CosmicTheme.textSecondary)
                            .lineLimit(2)
                    }

                    Spacer()

                    // Customize button
                    if SubscriptionManager.shared.isPremium {
                        Button(action: { showFramingOverrideSheet = true }) {
                            HStack(spacing: 4) {
                                Image(systemName: hasFramingOverride ? "pencil" : "plus")
                                    .font(.caption)
                                Text(hasFramingOverride ? "Edit" : "Customize")
                                    .font(TerminalFont.data(11, weight: .semibold))
                            }
                            .foregroundColor(CosmicTheme.gold)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(CosmicTheme.gold.opacity(0.15))
                        }
                    } else {
                        // Premium locked
                        HStack(spacing: 4) {
                            Image(systemName: "lock.fill")
                                .font(.caption2)
                            Text("ORACLE")
                                .font(TerminalFont.data(9, weight: .bold))
                        }
                        .foregroundColor(CosmicTheme.gold)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(CosmicTheme.gold.opacity(0.15))
                    }
                }

                // Sample framed text
                Text(framingSampleText)
                    .font(TerminalFont.data(10))
                    .foregroundColor(CosmicTheme.textMuted)
                    .italic()
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(CosmicTheme.secondaryBackground)
            }
        }
        .padding(20)
        .background(cardBackground)
        .opacity(appearAnimation ? 1 : 0)
        .offset(y: appearAnimation ? 0 : 20)
        .animation(.easeOut(duration: 0.5).delay(0.15), value: appearAnimation)
    }

    /// Sample text showing how this stock's signals would be framed
    private var framingSampleText: String {
        guard let companyZodiacSign else { return companyAstroUnavailableText }

        return SignalFramingService.shared.frameCompatibility(
            userSign: user?.sunSign ?? .aries,
            stockSign: companyZodiacSign,
            rating: safeCompatibility.rating,
            level: effectiveFramingLevel
        )
    }

    // MARK: - Framing Override Sheet

    private var framingOverrideSheet: some View {
        NavigationStack {
            ZStack {
                CosmicTheme.background.ignoresSafeArea()

                VStack(spacing: 24) {
                    // Stock info header
                    HStack(spacing: 12) {
                        if let companyZodiacSign {
                            ZodiacSymbolView(sign: companyZodiacSign, size: 40, color: elementColor)
                        } else {
                            Image(systemName: "questionmark.circle")
                                .font(.title2)
                                .foregroundColor(CosmicTheme.textMuted)
                                .frame(width: 40, height: 40)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text(stock.symbol)
                                .font(TerminalFont.headline(18))
                                .foregroundColor(CosmicTheme.textPrimary)

                            Text("Reading Framing Override")
                                .font(TerminalFont.data(12))
                                .foregroundColor(CosmicTheme.textSecondary)
                        }

                        Spacer()
                    }
                    .padding(20)
                    .background(CosmicTheme.cardBackground)

                    // Option to use global or custom
                    VStack(alignment: .leading, spacing: 16) {
                        Text("FRAMING PREFERENCE")
                            .font(TerminalFont.data(10, weight: .semibold))
                            .foregroundColor(CosmicTheme.textMuted)
                            .tracking(1)

                        // Use global toggle
                        Button(action: { removeFramingOverride() }) {
                            HStack {
                                Image(systemName: hasFramingOverride ? "circle" : "checkmark.circle.fill")
                                    .foregroundColor(hasFramingOverride ? CosmicTheme.textMuted : CosmicTheme.gold)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Use Global Setting")
                                        .font(TerminalFont.data(14, weight: .semibold))
                                        .foregroundColor(CosmicTheme.textPrimary)

                                    if let globalLevel = user?.signalFramingLevel {
                                        Text("Currently: \(globalLevel.displayName)")
                                            .font(TerminalFont.data(11))
                                            .foregroundColor(CosmicTheme.textSecondary)
                                    }
                                }

                                Spacer()
                            }
                            .padding(16)
                            .background(CosmicTheme.cardBackground)
                        }
                        .buttonStyle(.plain)

                        // Custom framing slider
                        VStack(alignment: .leading, spacing: 16) {
                            Button(action: { enableCustomFraming() }) {
                                HStack {
                                    Image(systemName: hasFramingOverride ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(hasFramingOverride ? CosmicTheme.gold : CosmicTheme.textMuted)

                                    Text("Custom for \(stock.symbol)")
                                        .font(TerminalFont.data(14, weight: .semibold))
                                        .foregroundColor(CosmicTheme.textPrimary)

                                    Spacer()
                                }
                            }
                            .buttonStyle(.plain)

                            if hasFramingOverride {
                                SignalFramingSlider(level: stockFramingBinding)
                                    .padding(.horizontal, 4)
                            }
                        }
                        .padding(16)
                        .background(CosmicTheme.cardBackground)
                    }
                    .padding(.horizontal, 20)

                    Spacer()

                    // Info text
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "info.circle")
                            .font(.caption)
                            .foregroundColor(CosmicTheme.textMuted)

                        Text("Custom framing lets you view this stock's readings differently from your global setting. Useful if you prefer more rational analysis for some stocks and cosmic framing for others.")
                            .font(TerminalFont.data(11))
                            .foregroundColor(CosmicTheme.textMuted)
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Reading Framing")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        showFramingOverrideSheet = false
                    }
                    .foregroundColor(CosmicTheme.gold)
                }
            }
            .toolbarBackground(CosmicTheme.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
        .presentationDetents([.medium])
    }

    /// Binding for the stock-specific framing level (persisted via AppState)
    private var stockFramingBinding: Binding<SignalFramingLevel> {
        Binding(
            get: { appState.framingLevel(for: stock.symbol) },
            set: { appState.setStockFramingOverride(symbol: stock.symbol, level: $0) }
        )
    }

    private func removeFramingOverride() {
        appState.setStockFramingOverride(symbol: stock.symbol, level: nil)
    }

    private func enableCustomFraming() {
        // Initialize with global setting
        let globalLevel = user?.signalFramingLevel ?? .balanced
        appState.setStockFramingOverride(symbol: stock.symbol, level: globalLevel)
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

                DataSourceIndicator(provenance: priceProvenance, size: .compact)
            }

            // Bloomberg-style stats grid
            StatsGridView(stats: [
                .price("Price", liveStock.formattedPrice),
                .change("Today", liveStock.percentageChange),
                matchStat,
                .text("Sector", stock.sector),
                .text("Volume", keyStats?.formattedVolume ?? "Unavailable"),
                .text("Avg Volume", keyStats?.formattedAvgVolume ?? "Unavailable")
            ], columns: 3)

            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "info.circle")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(CosmicTheme.textMuted)

                Text(financialStatsSourceNote)
                    .font(TerminalFont.data(10))
                    .foregroundColor(CosmicTheme.textSecondary)
                    .lineSpacing(3)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(CosmicTheme.cardBackground.opacity(0.6))
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(CosmicTheme.borderDim, lineWidth: 0.75)
            )
        }
        .padding(20)
        .background(cardBackground)
        .opacity(appearAnimation ? 1 : 0)
        .offset(y: appearAnimation ? 0 : 20)
        .animation(.easeOut(duration: 0.5).delay(0.3), value: appearAnimation)
    }

    private var financialStatsSourceNote: String {
        let fundamentalsText: String
        switch keyStatsProvenance {
        case .live, .cached:
            fundamentalsText = "Provider-backed fundamentals and volume are labeled in Key Statistics above."
        case .mixed:
            fundamentalsText = "Key Statistics combine multiple financial data states; each field keeps its own source label above."
        case .unavailable:
            fundamentalsText = "Fundamentals such as market cap, 52-week range, P/E, beta, EPS, and earnings dates stay unavailable until provider data is available."
        case .sample:
            fundamentalsText = "Fundamentals are not using provider data on this surface."
        }

        return "\(fundamentalsText) Sector uses the curated company profile until provider profile data is connected."
    }

    private func formattedVolume(_ volume: Int?) -> String {
        guard let volume, volume > 0 else { return "Unavailable" }
        let value = Double(volume)
        if value >= 1_000_000_000 {
            return String(format: "%.1fB", value / 1_000_000_000)
        } else if value >= 1_000_000 {
            return String(format: "%.1fM", value / 1_000_000)
        } else if value >= 1_000 {
            return String(format: "%.1fK", value / 1_000)
        } else {
            return "\(volume)"
        }
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
            .accessibilityLabel(isInPortfolio ? "\(stock.symbol) is in your portfolio" : "Add \(stock.symbol) to portfolio")

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
                .accessibilityLabel(isInWatchlist ? "Remove \(stock.symbol) from watchlist" : "Add \(stock.symbol) to watchlist")

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

    private var matchStat: StatItem {
        companyZodiacSign == nil
            ? .text("Match", "Unknown")
            : .gold("Match", "\(safeCompatibility.score)%")
    }

    // MARK: - Actions

    private func addToPortfolio() {
        guard !isInPortfolio else { return }

        HapticFeedback.success()
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
        HapticFeedback.medium()
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
                            if let companyZodiacSign {
                                ZodiacSymbolView(sign: companyZodiacSign, size: 40, color: elementColor)
                            } else {
                                Image(systemName: "questionmark.circle")
                                    .font(.title2)
                                    .foregroundColor(CosmicTheme.textMuted)
                                    .frame(width: 40, height: 40)
                            }

                            VStack(alignment: .leading) {
                                Text(stock.name)
                                    .font(TerminalFont.headline(16))
                                    .foregroundColor(CosmicTheme.textPrimary)

                                Text("\(stock.symbol) • \(companyZodiacSign?.displayName ?? "Unknown")")
                                    .font(TerminalFont.data(13))
                                    .foregroundColor(CosmicTheme.textSecondary)
                            }

                            Spacer()

                            Text(companyZodiacSign == nil ? "Unknown Match" : "\(safeCompatibility.score)% Match")
                                .font(TerminalFont.price(16))
                                .foregroundColor(companyZodiacSign == nil ? CosmicTheme.textSecondary : CosmicTheme.gold)
                        }

                        Text("\"\(companyZodiacSign == nil ? companyAstroUnavailableText : safeCompatibility.description)\"")
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

                    Text("Share your stock reading profile.")
                        .font(.subheadline)
                        .foregroundColor(CosmicTheme.textMuted)

                    Spacer()
                }
                .padding(20)
            }
            .navigationTitle("Share Reading Profile")
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
                        shareStock()
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
        guard let element = companyZodiacSign?.element else {
            return CosmicTheme.textMuted
        }

        return color(for: element)
    }

    private func color(for element: ZodiacSign.Element) -> Color {
        switch element {
        case .fire:  return CosmicTheme.fireElement
        case .earth: return CosmicTheme.earthElement
        case .air:   return CosmicTheme.airElement
        case .water: return CosmicTheme.waterElement
        }
    }

    private var userElementColor: Color {
        switch (user?.sunSign ?? .aries).element {
        case .fire:  return CosmicTheme.fireElement
        case .earth: return CosmicTheme.earthElement
        case .air:   return CosmicTheme.airElement
        case .water: return CosmicTheme.waterElement
        }
    }

    private var ratingColor: Color {
        switch safeCompatibility.rating {
        case .cosmicSoulmates:   return CosmicTheme.gold
        case .highCompatibility: return CosmicTheme.accentBlue
        case .neutral:           return CosmicTheme.textSecondary
        case .challenging:       return .orange
        case .cosmicClash:       return CosmicTheme.negative
        }
    }

    private var scoreGradient: LinearGradient {
        if safeCompatibility.score >= 85 {
            return CosmicTheme.goldGradient
        } else if safeCompatibility.score >= 65 {
            return LinearGradient(
                colors: [CosmicTheme.accentBlue, CosmicTheme.nebulaBlue],
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

    // MARK: - Share

    private func shareStock() {
        let zodiacLine: String
        let compatibilityLine: String

        if let companyZodiacSign {
            zodiacLine = "Zodiac: \(companyZodiacSign.textSymbol) \(companyZodiacSign.rawValue)"
            compatibilityLine = "My Compatibility: \(safeCompatibility.score)%"
        } else {
            zodiacLine = "Zodiac: Unknown"
            compatibilityLine = "My Compatibility: Unknown"
        }

        // Create shareable text
        let shareText = """
        Check out $\(stock.symbol) on Cosmo Trader.

        \(stock.name)
        Price: \(stock.formattedPrice)
        \(zodiacLine)
        \(compatibilityLine)

        Download Cosmo Trader to compare market data with an astrology lens.
        """

        // Create share activity
        let activityVC = UIActivityViewController(
            activityItems: [shareText],
            applicationActivities: nil
        )

        // Present
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootVC = window.rootViewController {
            // Find the topmost presented controller
            var topController = rootVC
            while let presented = topController.presentedViewController {
                topController = presented
            }
            topController.present(activityVC, animated: true)
        }

        showShareSheet = false
    }
}

// MARK: - Stock Formatting Extensions

extension Stock {

    var formattedFoundedDate: String {
        guard let foundedDate else { return "Unknown" }

        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, yyyy"
        return formatter.string(from: foundedDate)
    }

}

// MARK: - Preview

#Preview("Stock Detail - High Compatibility") {
    NavigationStack {
        StockDetailView(
            stock: Stock.samples.first { $0.symbol == "AAPL" }!
        )
    }
    .environment(AppState.preview)
    .preferredColorScheme(.dark)
}

#Preview("Stock Detail - Low Compatibility") {
    NavigationStack {
        StockDetailView(
            stock: Stock.samples.first { $0.symbol == "JPM" }!
        )
    }
    .environment(AppState.preview)
    .preferredColorScheme(.dark)
}
