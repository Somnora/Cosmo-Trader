import SwiftUI

// MARK: - PortfolioView
// ======================
// Bloomberg Terminal aesthetic. Data only. No decoration.
// If it looks "designed" it's wrong.

struct PortfolioView: View {

    // MARK: - Environment

    @Environment(AppState.self) private var appState

    // MARK: - State

    @State private var selectedStock: Stock?
    @State private var lastPriceUpdate: Date = Date()
    @State private var isFetchingPrices: Bool = false
    @State private var quoteProvenanceBySymbol: [String: FinancialDataProvenance] = [:]
    @State private var watchlistQuoteOverrides: [String: Stock] = [:]
    @ObservedObject private var stockAPI = StockAPIService.shared
    @State private var showRebalancingSuggestions: Bool = false
    @State private var chartTimeframe: ChartTimeframe = .month
    @State private var showPerformanceChart: Bool = true
    @State private var portfolioCorrelationViewModel = PortfolioCorrelationViewModel()

    // MARK: - Computed Properties

    private var user: UserProfile? {
        appState.currentUser
    }

    /// Safe user access for rendering (only call when user is known to exist)
    private var safeUser: UserProfile {
        appState.currentUser ?? UserProfile(
            displayName: "",
            email: "",
            birthDate: Date()
        )
    }

    private var holdings: [Stock] {
        safeUser.portfolio.filter { $0.sharesOwned > 0 }
    }

    /// Stocks in the user's watchlist (not owned)
    private var watchlistStocks: [Stock] {
        let watchlistSymbols = Set(safeUser.watchlist)
        return MockStockData.knownStocks
            .filter { watchlistSymbols.contains($0.symbol) }
            .map { watchlistQuoteOverrides[$0.symbol] ?? $0 }
    }

    private var portfolioPriceProvenance: FinancialDataProvenance {
        aggregateQuoteProvenance(
            for: holdings + watchlistStocks,
            storedReason: "Stored portfolio and curated watchlist prices until provider quote refresh succeeds",
            unavailableReason: "No visible portfolio or watchlist quotes"
        )
    }

    private var portfolioDailyPLProvenance: FinancialDataProvenance {
        aggregateQuoteProvenance(
            for: holdings,
            storedReason: "Stored daily P/L and change percent until provider quote refresh succeeds",
            unavailableReason: "No holdings available for daily P/L"
        )
    }

    private var portfolioCorrelationSignature: String {
        holdings
            .map { "\($0.symbol.uppercased()):\($0.sharesOwned):\($0.marketValue)" }
            .sorted()
            .joined(separator: "|")
    }

    private var elementBreakdown: [(element: ZodiacSign.Element, percentage: Double, value: Double)] {
        var elementValues: [ZodiacSign.Element: Double] = [:]
        var analyzedTotalValue: Double = 0

        for stock in holdings {
            guard let element = stock.foundedElement else { continue }
            elementValues[element, default: 0] += stock.totalValue
            analyzedTotalValue += stock.totalValue
        }

        guard analyzedTotalValue > 0 else { return [] }

        return ZodiacSign.Element.allCases.compactMap { element in
            let value = elementValues[element] ?? 0
            let percentage = (value / analyzedTotalValue) * 100
            guard percentage > 0 else { return nil }
            return (element: element, percentage: percentage, value: value)
        }.sorted { $0.percentage > $1.percentage }
    }

    private var timestampText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        formatter.timeZone = TimeZone(identifier: "America/New_York")
        return "Last updated: \(formatter.string(from: lastPriceUpdate)) ET"
    }

    /// Weighted portfolio compatibility result
    private var portfolioCompatibility: PortfolioCompatibilityResult {
        PortfolioCompatibilityService.calculateWeightedCompatibility(
            portfolio: safeUser.portfolio,
            userSign: safeUser.sunSign
        )
    }

    /// Rebalancing suggestions
    private var rebalancingSuggestions: [RebalancingSuggestion] {
        PortfolioCompatibilityService.generateRebalancingSuggestions(
            result: portfolioCompatibility,
            userSign: safeUser.sunSign
        )
    }

    /// Show search sheet
    @State private var showSearch: Bool = false
    @State private var showImportPortfolio: Bool = false

    // MARK: - Framing

    /// User's signal framing level
    private var framingLevel: SignalFramingLevel {
        appState.currentUser?.signalFramingLevel ?? .balanced
    }

    /// Framed section header for cosmic health
    private var framedHealthSectionHeader: String {
        switch framingLevel {
        case .rational:
            return "PORTFOLIO ANALYSIS"
        case .leanRational:
            return "PORTFOLIO HEALTH"
        default:
            return "COSMIC PORTFOLIO HEALTH"
        }
    }

    /// Framed section header for rebalancing
    private var framedRebalancingSectionHeader: String {
        switch framingLevel {
        case .rational:
            return "REBALANCING"
        case .leanRational:
            return "REBALANCING SUGGESTIONS"
        default:
            return "COSMIC REBALANCING"
        }
    }

    /// Framed rebalancing intro text
    private var framedRebalancingIntro: String {
        switch framingLevel {
        case .rational:
            return "To improve diversification, consider:"
        case .leanRational:
            return "To improve balance, consider:"
        default:
            return "To improve cosmic alignment, consider:"
        }
    }

    /// Whether the portfolio is balanced (no element dominates >40%)
    private var isPortfolioBalanced: Bool {
        let maxPercentage = portfolioCompatibility.elementBreakdown.values.max() ?? 0
        return maxPercentage < 40
    }

    /// Framed cosmic insight text
    private var framedCosmicInsight: String {
        SignalFramingService.shared.framePortfolioBalance(
            dominantElement: portfolioCompatibility.dominantElement,
            isBalanced: isPortfolioBalanced,
            level: framingLevel
        )
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                // Flat black background
                CosmicTheme.background
                    .ignoresSafeArea()

                if user == nil {
                    // No user - show empty state
                    CosmicEmptyStateView(
                        title: "No Portfolio",
                        message: "Complete onboarding, then add holdings to generate a portfolio-specific daily reading.",
                        icon: "chart.pie",
                        actionTitle: "Start Onboarding",
                        action: { appState.selectedTab = .profile }
                    )
                } else {
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 0) {
                        // Portfolio value header
                        portfolioHeader

                        dividerLine

                        if !holdings.isEmpty {
                            screenshotProofSection
                            dividerLine
                        }

                        // Performance chart section (collapsible)
                        if !holdings.isEmpty && showPerformanceChart {
                            performanceChartSection
                            dividerLine
                        }

                        // Portfolio-level historical cosmic correlation
                        if !holdings.isEmpty {
                            portfolioCorrelationSection
                            dividerLine
                        }

                        // Cosmic Portfolio Health section
                        if !holdings.isEmpty {
                            cosmicHealthSection
                            dividerLine
                        }

                        // Element allocation bar chart
                        if !holdings.isEmpty {
                            elementAllocationSection
                            dividerLine
                        }

                        // Rebalancing suggestions
                        if !rebalancingSuggestions.isEmpty && showRebalancingSuggestions {
                            rebalancingSection
                            dividerLine
                        }

                        // Holdings table
                        holdingsSection

                        // Watchlist section
                        if !watchlistStocks.isEmpty {
                            dividerLine
                            watchingSection
                        }

                        // Timestamp footer
                        footerSection
                    }
                    .iPadReadableContent(maxWidth: 980)
                }
                .contentShape(Rectangle())
                .tabBarSafeBottomPadding()
                .refreshable {
                    await fetchLivePrices()
                }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("PORTFOLIO")
                        .font(TerminalFont.data(13, weight: .semibold))
                        .tracking(1.8)
                        .foregroundColor(CosmicTheme.textPrimary)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSearch = true
                    } label: {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(CosmicTheme.gold)
                            .frame(width: 32, height: 32)
                            .background(
                                Circle()
                                    .fill(CosmicTheme.cardBackground)
                            )
                            .overlay(
                                Circle()
                                    .stroke(CosmicTheme.gold.opacity(0.3), lineWidth: 0.5)
                            )
                    }
                    .accessibilityLabel("Search stocks")
                }
            }
            .toolbarBackground(CosmicTheme.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .navigationDestination(item: $selectedStock) { stock in
                StockDetailView(stock: stock)
            }
            .sheet(isPresented: $showSearch) {
                SearchView()
                    .environment(appState)
            }
            .sheet(isPresented: $showImportPortfolio) {
                ImportPortfolioView()
                    .environment(appState)
            }
        }
        .onAppear {
            consumeNavigationIntentIfNeeded()
        }
        .onChange(of: appState.pendingNavigationIntent) { _, _ in
            consumeNavigationIntentIfNeeded()
        }
        .task {
            openStockDetailForScreenshotIfNeeded()
            if !AppState.isScreenshotMode {
                await fetchLivePrices()
            }
        }
    }

    private func consumeNavigationIntentIfNeeded() {
        guard let intent = appState.pendingNavigationIntent else { return }

        switch intent {
        case .portfolioAddHolding:
            showImportPortfolio = false
            showSearch = true
            appState.pendingNavigationIntent = nil
        case .portfolioImport:
            showSearch = false
            showImportPortfolio = true
            appState.pendingNavigationIntent = nil
        case .discoverSearch:
            break
        }
    }

    private func openStockDetailForScreenshotIfNeeded() {
        guard AppState.isScreenshotMode, selectedStock == nil else { return }
        guard let symbol = AppState.screenshotStockDetailSymbol?.uppercased(), !symbol.isEmpty else { return }

        selectedStock = holdings.first { $0.symbol.uppercased() == symbol }
            ?? MockStockData.knownStocks.first { $0.symbol.uppercased() == symbol }
            ?? Stock.sample
    }

    // MARK: - Divider

    private var dividerLine: some View {
        Rectangle()
            .fill(CosmicTheme.border)
            .frame(height: 1)
    }

    // MARK: - Performance Chart Section

    private var performanceChartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section header with toggle
            HStack {
                HStack(spacing: 8) {
                    Rectangle()
                        .fill(CosmicTheme.border)
                        .frame(height: 1)
                        .frame(width: 20)

                    HStack(spacing: 6) {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.caption2)
                            .foregroundColor(CosmicTheme.gold.opacity(0.7))

                        Text("PERFORMANCE")
                            .font(TerminalFont.data(10))
                            .foregroundColor(CosmicTheme.textMuted)
                            .tracking(1)
                    }

                    Rectangle()
                        .fill(CosmicTheme.border)
                        .frame(height: 1)
                }

                Spacer()

                // Collapse toggle
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showPerformanceChart.toggle()
                    }
                }) {
                    Image(systemName: showPerformanceChart ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(CosmicTheme.textMuted)
                }
            }
            .padding(.horizontal, 12)
            .padding(.top, 12)

            // Chart
            PortfolioChartView(
                portfolio: holdings,
                userSign: safeUser.sunSign,
                selectedTimeframe: $chartTimeframe
            )
            .padding(.horizontal, 12)
            .padding(.bottom, 18)
        }
    }

    // MARK: - Portfolio Header

    private var portfolioHeader: some View {
        HStack(spacing: 0) {
            // Portfolio value
            VStack(alignment: .leading, spacing: 2) {
                Text("PORTFOLIO VALUE")
                    .font(TerminalFont.data(10))
                    .foregroundColor(CosmicTheme.textMuted)
                    .tracking(1)

                Text(safeUser.formattedPortfolioValue)
                    .font(TerminalFont.price(24))
                    .foregroundColor(CosmicTheme.textPrimary)

                DataSourceIndicator(provenance: portfolioPriceProvenance, size: .compact)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Rectangle()
                .fill(CosmicTheme.border)
                .frame(width: 1)

            // Daily P/L
            VStack(alignment: .trailing, spacing: 2) {
                Text("DAILY P/L")
                    .font(TerminalFont.data(10))
                    .foregroundColor(CosmicTheme.textMuted)
                    .tracking(1)

                HStack(spacing: 4) {
                    Text(safeUser.formattedDailyChange)
                        .font(TerminalFont.price(18))
                    Text("(\(safeUser.formattedDailyChangePercent))")
                        .font(TerminalFont.price(14))
                }
                .foregroundColor(safeUser.isPortfolioPositive ? CosmicTheme.positive : CosmicTheme.negative)

                DataSourceIndicator(provenance: portfolioDailyPLProvenance, size: .compact)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
    }

    private var screenshotProofSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "scope")
                    .font(.caption)
                    .foregroundColor(CosmicTheme.gold)

                Text("PORTFOLIO-AWARE READING")
                    .font(TerminalFont.data(10, weight: .semibold))
                    .foregroundColor(CosmicTheme.gold)
                    .tracking(1)
            }

            Text(portfolioProofHeadline)
                .font(TerminalFont.data(16, weight: .semibold))
                .foregroundColor(CosmicTheme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            Text("Cosmo maps holdings, daily P/L, dominant element, and concentration before the reading lands.")
                .font(TerminalFont.data(11))
                .foregroundColor(CosmicTheme.textSecondary)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .terminalPanel(.navy)
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    private var portfolioProofHeadline: String {
        "\(holdings.count) holdings tracked. \(portfolioCompatibility.dominantElement.displayName) exposure is the active portfolio layer."
    }

    // MARK: - Cosmic Health Section

    private var portfolioCorrelationSection: some View {
        Group {
            if SubscriptionManager.shared.canAccess(.historicalAstroOverlay) || AppState.isScreenshotMode {
                PortfolioCosmicCorrelationView(viewModel: portfolioCorrelationViewModel)
                    .task(id: portfolioCorrelationSignature) {
                        await portfolioCorrelationViewModel.load(holdings: holdings)
                    }
            } else {
                PortfolioCorrelationLockedCard()
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 14)
    }

    private var cosmicHealthSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section header with toggle
            HStack {
                HStack(spacing: 8) {
                    Rectangle()
                        .fill(CosmicTheme.border)
                        .frame(height: 1)
                        .frame(width: 20)

                    Text(framedHealthSectionHeader)
                        .font(TerminalFont.data(10))
                        .foregroundColor(CosmicTheme.textMuted)
                        .tracking(1)

                    Rectangle()
                        .fill(CosmicTheme.border)
                        .frame(height: 1)
                }

                Spacer()

                // Suggestions toggle
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showRebalancingSuggestions.toggle()
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: showRebalancingSuggestions ? "lightbulb.fill" : "lightbulb")
                            .font(.caption)
                        Text(showRebalancingSuggestions ? "HIDE" : "TIPS")
                            .font(TerminalFont.data(9))
                    }
                    .foregroundColor(showRebalancingSuggestions ? CosmicTheme.gold : CosmicTheme.textMuted)
                }
            }
            .padding(.horizontal, 12)
            .padding(.top, 12)

            // Main health display
            HStack(spacing: 0) {
                // Big score display
                VStack(alignment: .leading, spacing: 4) {
                    Text("WEIGHTED SCORE")
                        .font(TerminalFont.data(9))
                        .foregroundColor(CosmicTheme.textMuted)
                        .tracking(1)

                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(String(format: "%.0f", portfolioCompatibility.overallScore))
                            .font(TerminalFont.price(36))
                            .foregroundStyle(cosmicScoreGradient)

                        Text("%")
                            .font(TerminalFont.price(18))
                            .foregroundColor(CosmicTheme.textSecondary)
                    }

                    // Rating badge
                    HStack(spacing: 4) {
                        Image(systemName: portfolioCompatibility.rating.sfSymbol)
                            .font(.caption)

                        Text(portfolioCompatibility.rating.displayName.uppercased())
                            .font(TerminalFont.data(9, weight: .semibold))
                            .foregroundColor(cosmicRatingColor)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 2)
                            .fill(cosmicRatingColor.opacity(0.15))
                    )
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Rectangle()
                    .fill(CosmicTheme.border)
                    .frame(width: 1)
                    .padding(.vertical, 8)

                // Dominant sign & element
                VStack(alignment: .trailing, spacing: 8) {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("DOMINANT SIGN")
                            .font(TerminalFont.data(9))
                            .foregroundColor(CosmicTheme.textMuted)
                            .tracking(1)

                        HStack(spacing: 6) {
                            ZodiacSymbolView(
                                sign: portfolioCompatibility.dominantSign,
                                size: 16,
                                color: CosmicTheme.gold
                            )
                            Text(portfolioCompatibility.dominantSign.displayName)
                                .font(TerminalFont.data(14, weight: .semibold))
                                .foregroundColor(CosmicTheme.textPrimary)
                        }
                    }

                    VStack(alignment: .trailing, spacing: 2) {
                        Text("DOMINANT ELEMENT")
                            .font(TerminalFont.data(9))
                            .foregroundColor(CosmicTheme.textMuted)
                            .tracking(1)

                        HStack(spacing: 6) {
                            Image(systemName: portfolioCompatibility.dominantElement.sfSymbol)
                                .font(.caption)
                                .foregroundColor(portfolioCompatibility.dominantElement.color)
                            Text(portfolioCompatibility.dominantElement.displayName)
                                .font(TerminalFont.data(12))
                                .foregroundColor(portfolioCompatibility.dominantElement.color)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .padding(.horizontal, 12)

            // Portfolio insight (framed)
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "chart.bar.xaxis")
                    .font(.caption)
                    .foregroundColor(CosmicTheme.gold.opacity(0.7))

                Text(framedCosmicInsight)
                    .font(TerminalFont.data(11))
                    .foregroundColor(CosmicTheme.textSecondary)
                    .italic()
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 16)
        }
    }

    private var cosmicScoreGradient: LinearGradient {
        let score = portfolioCompatibility.overallScore
        if score >= 85 {
            return CosmicTheme.goldGradient
        } else if score >= 65 {
            return LinearGradient(
                colors: [CosmicTheme.accentBlue, CosmicTheme.gold.opacity(0.85)],
                startPoint: .top,
                endPoint: .bottom
            )
        } else {
            return LinearGradient(
                colors: [CosmicTheme.textPrimary, CosmicTheme.textSecondary],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }

    private var cosmicRatingColor: Color {
        switch portfolioCompatibility.rating {
        case .cosmicSoulmates: return CosmicTheme.gold
        case .highCompatibility: return CosmicTheme.accentBlue
        case .neutral: return CosmicTheme.textSecondary
        case .challenging: return .orange
        case .cosmicClash: return CosmicTheme.negative
        }
    }

    // MARK: - Rebalancing Section

    private var rebalancingSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader(framedRebalancingSectionHeader)

            VStack(alignment: .leading, spacing: 6) {
                Text(framedRebalancingIntro)
                    .font(TerminalFont.data(10))
                    .foregroundColor(CosmicTheme.textMuted)
                    .padding(.horizontal, 12)

                ForEach(rebalancingSuggestions.prefix(4)) { suggestion in
                    suggestionRow(suggestion)
                }
            }
            .padding(.bottom, 8)
        }
    }

    private func suggestionRow(_ suggestion: RebalancingSuggestion) -> some View {
        HStack(spacing: 10) {
            Image(systemName: suggestion.icon)
                .font(.caption)
                .foregroundColor(suggestionColor(for: suggestion.priority))
                .frame(width: 20)

            Text(suggestion.message)
                .font(TerminalFont.data(11))
                .foregroundColor(suggestionColor(for: suggestion.priority))
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            Spacer()

            // Priority indicator
            Circle()
                .fill(suggestionColor(for: suggestion.priority))
                .frame(width: 6, height: 6)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Rectangle()
                .fill(suggestionColor(for: suggestion.priority).opacity(0.05))
        )
    }

    private func suggestionColor(for priority: RebalancingSuggestion.Priority) -> Color {
        switch priority {
        case .high: return CosmicTheme.gold
        case .medium: return CosmicTheme.textSecondary
        case .low: return CosmicTheme.textMuted
        }
    }

    // MARK: - Element Allocation Section

    private var elementAllocationSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader("ELEMENT ALLOCATION")

            // Horizontal bar chart
            VStack(spacing: 4) {
                ForEach(elementBreakdown, id: \.element) { item in
                    elementBar(item)
                }
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 8)
        }
    }

    private func elementBar(_ item: (element: ZodiacSign.Element, percentage: Double, value: Double)) -> some View {
        HStack(spacing: 8) {
            // Element glyph (small, muted gold)
            ZodiacSymbolView(
                sign: item.element.signs.first ?? .aries,
                size: 12,
                color: CosmicTheme.gold
            )
            .frame(width: 16)

            // Element name
            Text(item.element.displayName.uppercased())
                .font(TerminalFont.data(10))
                .foregroundColor(CosmicTheme.textSecondary)
                .frame(width: 50, alignment: .leading)

            // Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(CosmicTheme.border)
                        .frame(height: 8)

                    Rectangle()
                        .fill(item.element.color)
                        .frame(width: geometry.size.width * CGFloat(item.percentage / 100), height: 8)
                }
            }
            .frame(height: 8)

            // Percentage
            Text(String(format: "%.1f%%", item.percentage))
                .font(TerminalFont.price(11))
                .foregroundColor(CosmicTheme.textPrimary)
                .frame(width: 45, alignment: .trailing)
        }
        .frame(height: 20)
    }

    // MARK: - Holdings Section

    private var holdingsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader("HOLDINGS")

            if holdings.isEmpty {
                emptyState
            } else {
                // Table header
                tableHeader
                dividerLine

                // Holdings rows
                ForEach(holdings) { stock in
                    holdingRow(stock)
                    dividerLine
                }
            }
        }
    }

    private var tableHeader: some View {
        HStack(spacing: 0) {
            Text("SYMBOL")
                .frame(width: 60, alignment: .leading)
            Text("NAME")
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("PRICE")
                .frame(width: 70, alignment: .trailing)
            Text("CHG%")
                .frame(width: 60, alignment: .trailing)
            Text("ALLOC")
                .frame(width: 50, alignment: .trailing)
        }
        .font(TerminalFont.data(9))
        .foregroundColor(CosmicTheme.textMuted)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(CosmicTheme.cardBackground)
    }

    private func holdingRow(_ stock: Stock) -> some View {
        Button(action: { selectedStock = stock }) {
            HStack(spacing: 0) {
                // Symbol with zodiac glyph
                HStack(spacing: 4) {
                    if let foundedZodiacSign = stock.foundedZodiacSign {
                        ZodiacSymbolView(
                            sign: foundedZodiacSign,
                            size: 10,
                            color: CosmicTheme.gold.opacity(0.7)
                        )
                    } else {
                        Text("?")
                            .font(TerminalFont.data(10, weight: .semibold))
                            .foregroundColor(CosmicTheme.textMuted)
                    }
                    Text(stock.symbol)
                        .font(TerminalFont.ticker(11))
                        .foregroundColor(CosmicTheme.textPrimary)
                }
                .frame(width: 60, alignment: .leading)

                // Name
                Text(stock.name)
                    .font(TerminalFont.data(11))
                    .foregroundColor(CosmicTheme.textSecondary)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)

                // Price
                priceCell(for: stock, fallbackReason: "Stored portfolio price; provider quote unavailable")
                    .frame(width: 70, alignment: .trailing)

                // Change %
                changeCell(for: stock, fallbackReason: "Stored portfolio change; provider quote unavailable")
                    .frame(width: 60, alignment: .trailing)

                // Allocation bar
                allocationBar(for: stock)
                    .frame(width: 50)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
    }

    private func allocationBar(for stock: Stock) -> some View {
        let totalValue = safeUser.totalPortfolioValue
        let allocation = totalValue > 0 ? (stock.totalValue / totalValue) * 100 : 0
        let barWidth = min(allocation / 50, 1.0) // Max bar at 50% allocation

        return HStack(spacing: 2) {
            // Mini bar
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(CosmicTheme.border)
                    .frame(width: 30, height: 6)
                Rectangle()
                    .fill(CosmicTheme.textSecondary)
                    .frame(width: 30 * CGFloat(barWidth), height: 6)
            }
        }
    }

    private func priceCell(for stock: Stock, fallbackReason: String) -> some View {
        let provenance = quoteProvenance(for: stock, fallbackReason: fallbackReason)
        let hasDisplayablePrice = stock.currentPrice > 0

        return VStack(alignment: .trailing, spacing: 2) {
            Text(hasDisplayablePrice ? stock.formattedPrice : "—")
                .font(TerminalFont.price(11))
                .foregroundColor(hasDisplayablePrice ? CosmicTheme.textPrimary : CosmicTheme.textMuted)

            Text(provenance.shortLabel.uppercased())
                .font(TerminalFont.data(7, weight: .bold))
                .foregroundColor(provenance.color)
                .tracking(0.5)
        }
    }

    private func quoteProvenance(for stock: Stock, fallbackReason: String) -> FinancialDataProvenance {
        if let provenance = quoteProvenanceBySymbol[stock.symbol.uppercased()] {
            return provenance
        }

        guard stock.currentPrice > 0 else {
            return .unavailable(reason: "Provider quote unavailable; no stored import price")
        }

        return .sample(reason: fallbackReason)
    }

    private func changeCell(for stock: Stock, fallbackReason: String) -> some View {
        let provenance = quoteProvenance(for: stock, fallbackReason: fallbackReason)
        let hasDisplayableChange = provenance.isProviderBacked
            || stock.priceChange != 0
            || stock.percentageChange != 0

        return VStack(alignment: .trailing, spacing: 2) {
            Text(hasDisplayableChange ? stock.formattedPercentageChange : "—")
                .font(TerminalFont.price(11))
                .foregroundColor(hasDisplayableChange ? (stock.isPositive ? CosmicTheme.positive : CosmicTheme.negative) : CosmicTheme.textMuted)

            Text(provenance.shortLabel.uppercased())
                .font(TerminalFont.data(7, weight: .bold))
                .foregroundColor(provenance.color)
                .tracking(0.5)
        }
    }

    private func aggregateQuoteProvenance(
        for stocks: [Stock],
        storedReason: String,
        unavailableReason: String
    ) -> FinancialDataProvenance {
        let symbols = Array(Set(stocks.map { $0.symbol.uppercased() }))
        guard !symbols.isEmpty else {
            return .unavailable(reason: unavailableReason)
        }

        let provenances = symbols.map { symbol in
            quoteProvenanceBySymbol[symbol] ?? .sample(reason: storedReason)
        }

        let liveFetches = provenances.compactMap { provenance -> Date? in
            guard case .live(_, let fetchedAt) = provenance else { return nil }
            return fetchedAt
        }
        let cachedFetches = provenances.compactMap { provenance -> Date? in
            guard case .cached(_, let fetchedAt, _) = provenance else { return nil }
            return fetchedAt
        }

        if liveFetches.count == provenances.count, let newest = liveFetches.max() {
            return .live(provider: FinancialDataProvenance.finnhubProvider, fetchedAt: newest)
        }

        if cachedFetches.count == provenances.count, let newest = cachedFetches.max() {
            return .cached(provider: FinancialDataProvenance.finnhubProvider, fetchedAt: newest)
        }

        if provenances.allSatisfy({ if case .sample = $0 { return true }; return false }) {
            return .sample(reason: storedReason)
        }

        if provenances.allSatisfy({ if case .unavailable = $0 { return true }; return false }) {
            return .unavailable(reason: unavailableReason)
        }

        return .mixed(reason: "Portfolio values combine live, cached, stored, or unavailable quote fields")
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "briefcase")
                    .font(.system(size: 26, weight: .medium))
                    .foregroundColor(CosmicTheme.gold)
                    .frame(width: 42, height: 42)
                    .background(CosmicTheme.cardBackground)
                    .overlay(
                        Rectangle()
                            .stroke(CosmicTheme.border, lineWidth: 1)
                    )

                VStack(alignment: .leading, spacing: 8) {
                    Text("PORTFOLIO SETUP")
                        .font(TerminalFont.data(10, weight: .semibold))
                        .foregroundColor(CosmicTheme.gold)
                        .tracking(1.2)

                    Text("Add your holdings to generate a daily financial astrology reading.")
                        .font(TerminalFont.data(16, weight: .semibold))
                        .foregroundColor(CosmicTheme.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)

                    Text("Your reading gets sharper once Cosmo knows what you own. Start with 3-5 tickers, then refine shares later.")
                        .font(TerminalFont.data(12))
                        .foregroundColor(CosmicTheme.textSecondary)
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                setupOutcomeRow("Today can rank holdings that deserve attention.")
                setupOutcomeRow("Portfolio value, daily P/L, and element exposure become part of the reading.")
                setupOutcomeRow("Discover starts explaining whether candidates balance or intensify your exposure.")
            }

            HStack(spacing: 10) {
                Button {
                    showImportPortfolio = true
                } label: {
                    Label("IMPORT", systemImage: "square.and.arrow.down")
                        .font(TerminalFont.data(11, weight: .semibold))
                        .foregroundColor(CosmicTheme.background)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(CosmicTheme.gold)
                }
                .buttonStyle(.plain)

                Button {
                    showSearch = true
                } label: {
                    Label("ADD TICKER", systemImage: "magnifyingglass")
                        .font(TerminalFont.data(11, weight: .semibold))
                        .foregroundColor(CosmicTheme.gold)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .overlay(
                            Rectangle()
                                .stroke(CosmicTheme.gold.opacity(0.45), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .background(CosmicTheme.background)
    }

    private func setupOutcomeRow(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "checkmark.seal")
                .font(.caption2)
                .foregroundColor(CosmicTheme.textMuted)
                .frame(width: 14)

            Text(text)
                .font(TerminalFont.data(11))
                .foregroundColor(CosmicTheme.textMuted)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Watching Section

    private var watchingSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Section header with count
            HStack(spacing: 8) {
                Rectangle()
                    .fill(CosmicTheme.border)
                    .frame(height: 1)
                    .frame(width: 20)

                HStack(spacing: 6) {
                    Image(systemName: "eye.fill")
                        .font(.caption2)
                        .foregroundColor(CosmicTheme.gold.opacity(0.7))

                    Text("WATCHING")
                        .font(TerminalFont.data(10))
                        .foregroundColor(CosmicTheme.textMuted)
                        .tracking(1)

                    Text("(\(watchlistStocks.count))")
                        .font(TerminalFont.data(10))
                        .foregroundColor(CosmicTheme.textMuted)
                }

                Rectangle()
                    .fill(CosmicTheme.border)
                    .frame(height: 1)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            HStack(alignment: .top, spacing: 6) {
                Image(systemName: "info.circle")
                    .font(.system(size: 10, weight: .semibold))
                Text("Watchlist prices are labeled live, cached, or sample depending on the latest provider quote refresh.")
                    .font(TerminalFont.data(9))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .foregroundColor(CosmicTheme.textMuted)
            .padding(.horizontal, 12)
            .padding(.bottom, 8)

            // Watchlist table header
            watchlistTableHeader
            dividerLine

            // Watchlist rows with swipe to remove
            ForEach(watchlistStocks) { stock in
                watchlistRow(stock)
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                appState.removeFromWatchlist(stock.symbol)
                            }
                        } label: {
                            Label("Remove", systemImage: "eye.slash")
                        }
                        .tint(CosmicTheme.negative)
                    }
                dividerLine
            }

            // Hint text
            HStack(spacing: 4) {
                Image(systemName: "arrow.left")
                    .font(.system(size: 8))
                Text("Swipe left to remove from watchlist")
                    .font(TerminalFont.data(9))
            }
            .foregroundColor(CosmicTheme.textMuted.opacity(0.6))
            .padding(.horizontal, 12)
            .padding(.top, 4)
            .padding(.bottom, 8)
        }
    }

    private var watchlistTableHeader: some View {
        HStack(spacing: 0) {
            Text("SYMBOL")
                .frame(width: 60, alignment: .leading)
            Text("NAME")
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("PRICE")
                .frame(width: 70, alignment: .trailing)
            Text("CHG%")
                .frame(width: 60, alignment: .trailing)
            Text("MATCH")
                .frame(width: 50, alignment: .trailing)
        }
        .font(TerminalFont.data(9))
        .foregroundColor(CosmicTheme.textMuted)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(CosmicTheme.cardBackground.opacity(0.5))
    }

    private func watchlistRow(_ stock: Stock) -> some View {
        let compatibility = safeUser.compatibility(with: stock)

        return Button(action: { selectedStock = stock }) {
            HStack(spacing: 0) {
                // Symbol with zodiac glyph
                HStack(spacing: 4) {
                    if let foundedZodiacSign = stock.foundedZodiacSign {
                        ZodiacSymbolView(
                            sign: foundedZodiacSign,
                            size: 10,
                            color: CosmicTheme.gold.opacity(0.7)
                        )
                    } else {
                        Text("?")
                            .font(TerminalFont.data(10, weight: .semibold))
                            .foregroundColor(CosmicTheme.textMuted)
                    }
                    Text(stock.symbol)
                        .font(TerminalFont.ticker(11))
                        .foregroundColor(CosmicTheme.textPrimary)
                }
                .frame(width: 60, alignment: .leading)

                // Name
                Text(stock.name)
                    .font(TerminalFont.data(11))
                    .foregroundColor(CosmicTheme.textSecondary)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)

                // Price
                priceCell(for: stock, fallbackReason: "Curated sample price; provider quote unavailable")
                    .frame(width: 70, alignment: .trailing)

                // Change %
                changeCell(for: stock, fallbackReason: "Curated sample change; provider quote unavailable")
                    .frame(width: 60, alignment: .trailing)

                // Compatibility score
                compatibilityBadge(score: compatibility.score)
                    .frame(width: 50, alignment: .trailing)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
    }

    private func compatibilityBadge(score: Int) -> some View {
        let color: Color = score >= 85 ? CosmicTheme.gold :
                           score >= 65 ? CosmicTheme.accentBlue :
                           score >= 45 ? CosmicTheme.textSecondary : CosmicTheme.negative

        return Text("\(score)%")
            .font(TerminalFont.data(10, weight: .semibold))
            .foregroundColor(color)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(
                RoundedRectangle(cornerRadius: 2)
                    .fill(color.opacity(0.15))
            )
    }

    // MARK: - Section Header

    private func sectionHeader(_ title: String) -> some View {
        HStack(spacing: 8) {
            Rectangle()
                .fill(CosmicTheme.border)
                .frame(height: 1)
                .frame(width: 20)

            Text(title)
                .font(TerminalFont.data(10))
                .foregroundColor(CosmicTheme.textMuted)
                .tracking(1)

            Rectangle()
                .fill(CosmicTheme.border)
                .frame(height: 1)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    // MARK: - Footer

    private var footerSection: some View {
        VStack(spacing: 4) {
            Rectangle()
                .fill(CosmicTheme.border)
                .frame(height: 1)

            Text(timestampText)
                .font(TerminalFont.timestamp(10))
                .foregroundColor(CosmicTheme.textMuted)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)

            HStack {
                Spacer()
                DataSourceIndicator(provenance: portfolioPriceProvenance, size: .compact)
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 8)
        }
    }

    // MARK: - Actions

    private func fetchLivePrices() async {
        let symbols = Array(Set((holdings + watchlistStocks).map { $0.symbol.uppercased() }))
        guard !symbols.isEmpty else { return }
        isFetchingPrices = true

        let results = await stockAPI.getMultipleQuoteResults(symbols: symbols)
        let quotes = results.compactMapValues(\.quote)

        await MainActor.run {
            var nextProvenance = quoteProvenanceBySymbol
            for symbol in symbols {
                if let result = results[symbol], result.quote != nil {
                    nextProvenance[symbol] = result.provenance
                } else if holdings.contains(where: { $0.symbol.uppercased() == symbol }) {
                    nextProvenance[symbol] = .sample(reason: "Stored portfolio price; provider quote unavailable")
                } else {
                    nextProvenance[symbol] = .sample(reason: "Curated sample price; provider quote unavailable")
                }
            }
            quoteProvenanceBySymbol = nextProvenance

            if !quotes.isEmpty {
                appState.updatePortfolioPrices(with: quotes)
                watchlistQuoteOverrides = watchlistStocks.reduce(into: watchlistQuoteOverrides) { partialResult, stock in
                    if let quote = quotes[stock.symbol.uppercased()] {
                        partialResult[stock.symbol] = stock.withQuote(quote)
                    }
                }
                lastPriceUpdate = results.values.compactMap { $0.provenance.fetchedAt }.max() ?? Date()
            }
        }

        isFetchingPrices = false
    }
}

// MARK: - Preview

#Preview("Portfolio View") {
    PortfolioView()
        .environment(AppState.preview)
        .preferredColorScheme(.dark)
}
