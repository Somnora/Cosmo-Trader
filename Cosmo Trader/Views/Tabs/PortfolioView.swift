import SwiftUI

// MARK: - PortfolioView
// ======================
// The main Portfolio tab - the home screen of the app.
//
// STRUCTURE:
// 1. PortfolioHeaderView - Greeting, sun sign, total value, daily change
// 2. Visualization toggle - Switch between Zodiac Wheel and Cosmic Balance card
// 3. Holdings List - Scrollable list of owned stocks
//
// DESIGN PHILOSOPHY:
// - Dark cosmic theme with gold accents
// - Important numbers are prominent
// - Zodiac elements add personality without overwhelming
// - Smooth scrolling with clear visual hierarchy

struct PortfolioView: View {

    // MARK: - Environment

    @Environment(AppState.self) private var appState

    // MARK: - State

    /// Track if we're showing a selected stock detail
    @State private var selectedStock: Stock?

    /// Toggle between wheel view and simple card view
    @State private var showWheelView: Bool = true

    /// Is data refreshing?
    @State private var isRefreshing: Bool = false

    /// Astro alert service for cosmic event tracking
    @State private var astroService = AstroAlertService.shared

    /// Show cosmic event detail sheet
    @State private var selectedCosmicEvent: CosmicEvent?

    /// Track dismissed alerts for this session
    @State private var sessionDismissedAlerts: Set<UUID> = []

    /// Track if data recovery alert was dismissed
    @State private var showDataRecoveryAlert: Bool = false

    /// Current error to display
    @State private var currentError: NetworkError?

    /// Stock API service for live quotes
    @State private var stockAPI = StockAPIService.shared

    /// Last update timestamp for display
    @State private var lastPriceUpdate: Date?

    /// Is currently fetching prices
    @State private var isFetchingPrices: Bool = false

    /// Cosmic mood service for Fear & Greed index
    @State private var moodService = CosmicMoodService.shared

    /// Show cosmic mood detail sheet
    @State private var showMoodDetail: Bool = false

    // MARK: - Computed Properties

    /// Get current user from app state
    private var user: UserProfile {
        appState.currentUser ?? .sampleWithHoldings
    }

    /// Stocks in portfolio that are owned
    private var holdings: [Stock] {
        user.portfolio.filter { $0.sharesOwned > 0 }
    }

    /// Holdings count
    private var holdingsCount: Int {
        holdings.count
    }

    /// Holdings grouped by element
    private var holdingsByElement: [ZodiacSign.Element: [Stock]] {
        Dictionary(grouping: holdings) { $0.zodiacSign.element }
    }

    /// Element breakdown for visualization
    private var elementBreakdown: [ElementBreakdown] {
        let totalValue = user.totalPortfolioValue
        guard totalValue > 0 else {
            return ZodiacSign.Element.allCases.map {
                ElementBreakdown(element: $0, percentage: 0, value: 0)
            }
        }

        var elementValues: [ZodiacSign.Element: Double] = [:]
        for stock in holdings {
            let element = stock.zodiacSign.element
            elementValues[element, default: 0] += stock.totalValue
        }

        return ZodiacSign.Element.allCases.map { element in
            let value = elementValues[element] ?? 0
            let percentage = (value / totalValue) * 100
            return ElementBreakdown(element: element, percentage: percentage, value: value)
        }.sorted { $0.percentage > $1.percentage }
    }

    /// Dominant element
    private var dominantElement: ZodiacSign.Element? {
        elementBreakdown.first { $0.percentage > 0 }?.element
    }

    /// Element insight text
    private var elementInsight: String {
        guard let dominant = dominantElement else {
            return "Add some holdings to see your cosmic balance."
        }

        let dominantPct = elementBreakdown.first?.percentage ?? 0

        if dominantPct > 60 {
            switch dominant {
            case .fire:
                return "Heavy in Fire energy - high growth potential, high volatility."
            case .earth:
                return "Grounded in Earth energy - stable and practical."
            case .air:
                return "Dominated by Air energy - intellectual picks, diversified."
            case .water:
                return "Deep in Water energy - intuitive choices, emotionally driven."
            }
        } else if dominantPct > 40 {
            return "\(dominant.displayName) leads your portfolio with balanced risk."
        } else {
            return "Elementally balanced - diversified across cosmic energies."
        }
    }

    /// Time-appropriate greeting
    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12:  return "Good morning"
        case 12..<17: return "Good afternoon"
        case 17..<21: return "Good evening"
        default:      return "Good night"
        }
    }

    /// Personalized greeting
    private var personalizedGreeting: String {
        "\(greeting), \(user.displayName)"
    }

    /// Average portfolio compatibility
    private var averageCompatibility: Int {
        user.averagePortfolioCompatibility
    }

    /// Alert events to show (caution events not dismissed this session)
    private var visibleAlertEvents: [CosmicEvent] {
        astroService.activeAlertEvents.filter { !sessionDismissedAlerts.contains($0.id) }
    }

    /// Primary alert event to show in banner
    private var primaryAlertEvent: CosmicEvent? {
        visibleAlertEvents.first
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                // Full-screen cosmic background
                backgroundGradient

                // Ticker tape at top (outside scroll)
                VStack(spacing: 0) {
                    if !holdings.isEmpty {
                        TickerTapeView(stocks: holdings, speed: 35, showPrice: true)
                    }

                    // Main content
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 20) {
                            // 0. Market status indicator
                            HStack {
                                MarketStatusIndicator(size: .small)
                                Spacer()
                            }
                            .padding(.top, 8)

                            // 0a. Data Recovery Alert (if recovered from corruption)
                            if appState.didRecoverFromCorruption && !showDataRecoveryAlert {
                                dataRecoveryBanner
                            }

                            // 0b. Error Banner (if there's a current error)
                            if let error = currentError {
                                CosmicErrorView(
                                    networkError: error,
                                    style: .banner,
                                    onRetry: { await refreshPortfolio() },
                                    onDismiss: { currentError = nil }
                                )
                                .transition(.move(edge: .top).combined(with: .opacity))
                            }

                            // 0c. Cosmic Alert Banner (if active events)
                            if let alertEvent = primaryAlertEvent {
                                cosmicAlertBanner(for: alertEvent)
                            }

                            // 1. Header with greeting and portfolio value
                            headerSection

                            // 2. Visualization toggle
                            if !holdings.isEmpty {
                                visualizationToggle
                            }

                            // 3. Cosmic Balance visualization (wheel or card)
                            if !holdings.isEmpty {
                                cosmicBalanceSection
                            }

                            // 4. Cosmic Mood Index widget
                            cosmicMoodSection

                            // 5. Saturn Return alerts (if any approaching)
                            if !holdings.isEmpty {
                                SaturnReturnListSection(stocks: holdings)
                            }

                            // 6. Holdings list
                            holdingsSection
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 100)
                    }
                    .refreshable {
                        await refreshPortfolio()
                    }
                }
            }
            .onAppear {
                // Show data recovery alert if needed
                if appState.didRecoverFromCorruption {
                    showDataRecoveryAlert = false
                }
            }
            .task {
                // Fetch live prices on appear
                await fetchLivePrices()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 6) {
                        Image(systemName: "chart.pie.fill")
                            .foregroundColor(CosmicTheme.gold)
                        Text("Portfolio")
                            .font(.headline)
                            .foregroundColor(CosmicTheme.textPrimary)
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {}) {
                        Image(systemName: "bell.badge")
                            .foregroundColor(CosmicTheme.textSecondary)
                    }
                }
            }
            .toolbarBackground(CosmicTheme.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .navigationDestination(item: $selectedStock) { stock in
                StockDetailView(stock: stock)
            }
            .sheet(item: $selectedCosmicEvent) { event in
                cosmicEventDetailSheet(for: event)
            }
            .sheet(isPresented: $showMoodDetail) {
                CosmicMoodDetailSheet(moodData: moodService.getCurrentMood())
            }
        }
    }

    // MARK: - Cosmic Alert Banner

    private func cosmicAlertBanner(for event: CosmicEvent) -> some View {
        HStack(spacing: 12) {
            // Pulsing icon
            ZStack {
                Circle()
                    .fill(event.themeColor.opacity(0.2))
                    .frame(width: 36, height: 36)

                Image(systemName: event.icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(event.themeColor)
            }

            // Text content
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(event.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(CosmicTheme.textPrimary)

                    if event.intensity == .intense {
                        Text("!")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(width: 16, height: 16)
                            .background(Circle().fill(Color.red))
                    }
                }

                Text(event.warningMessage ?? event.subtitle)
                    .font(.caption)
                    .foregroundColor(CosmicTheme.textSecondary)
                    .lineLimit(1)
            }

            Spacer()

            // More info button
            Button(action: { selectedCosmicEvent = event }) {
                Image(systemName: "info.circle")
                    .font(.system(size: 18))
                    .foregroundColor(event.themeColor)
            }

            // Dismiss button
            Button(action: {
                withAnimation(.easeOut(duration: 0.2)) {
                    _ = sessionDismissedAlerts.insert(event.id)
                }
            }) {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(CosmicTheme.textMuted)
                    .frame(width: 24, height: 24)
                    .background(Circle().fill(CosmicTheme.cardBackground))
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(CosmicTheme.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(event.themeColor.opacity(0.4), lineWidth: 0.5)
                )
        )
        .transition(.asymmetric(
            insertion: .move(edge: .top).combined(with: .opacity),
            removal: .opacity
        ))
    }

    // MARK: - Cosmic Event Detail Sheet

    private func cosmicEventDetailSheet(for event: CosmicEvent) -> some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    HStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(event.themeColor.opacity(0.2))
                                .frame(width: 60, height: 60)

                            Image(systemName: event.icon)
                                .font(.system(size: 28))
                                .foregroundColor(event.themeColor)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text(event.title)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(CosmicTheme.textPrimary)

                            Text(event.subtitle)
                                .font(.subheadline)
                                .foregroundColor(event.themeColor)
                        }
                    }

                    // Status badge
                    HStack(spacing: 8) {
                        Text(event.isActive ? "ACTIVE NOW" : event.statusText.uppercased())
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Capsule().fill(event.isActive ? event.themeColor : CosmicTheme.textMuted))

                        Text(event.dateRangeFormatted)
                            .font(.caption)
                            .foregroundColor(CosmicTheme.textSecondary)
                    }

                    Divider()
                        .background(CosmicTheme.textMuted.opacity(0.3))

                    // Description
                    Text(event.description)
                        .font(.body)
                        .foregroundColor(CosmicTheme.textSecondary)
                        .lineSpacing(4)

                    // Warning if present
                    if let warning = event.warningMessage {
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)

                            Text(warning)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.orange)
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.orange.opacity(0.1))
                        )
                    }

                    // Trading advice
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 6) {
                            Image(systemName: "sparkles")
                                .foregroundColor(CosmicTheme.gold)
                            Text("Trading Advice")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(CosmicTheme.gold)
                        }

                        Text(event.advice)
                            .font(.subheadline)
                            .foregroundColor(CosmicTheme.textPrimary)
                            .lineSpacing(4)
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(CosmicTheme.gold.opacity(0.1))
                    )

                    // Affected areas
                    if !event.affectedElements.isEmpty || !event.affectedSectors.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            if !event.affectedElements.isEmpty {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Affected Elements")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .foregroundColor(CosmicTheme.textMuted)

                                    HStack(spacing: 8) {
                                        ForEach(event.affectedElements, id: \.self) { element in
                                            HStack(spacing: 4) {
                                                ElementSymbolView(element: element, size: 14)
                                                Text(element.displayName)
                                                    .font(TerminalFont.data(11))
                                                    .foregroundColor(CosmicTheme.textSecondary)
                                            }
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 6)
                                            .background(
                                                Capsule().fill(CosmicTheme.cardBackground)
                                            )
                                        }
                                    }
                                }
                            }

                            if !event.affectedSectors.isEmpty {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Affected Sectors")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .foregroundColor(CosmicTheme.textMuted)

                                    Text(event.affectedSectors.map { $0.rawValue }.joined(separator: ", "))
                                        .font(.caption)
                                        .foregroundColor(CosmicTheme.textSecondary)
                                }
                            }
                        }
                    }
                }
                .padding(20)
            }
            .background(CosmicTheme.background)
            .navigationTitle("Cosmic Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        selectedCosmicEvent = nil
                    }
                    .foregroundColor(CosmicTheme.gold)
                }
            }
            .toolbarBackground(CosmicTheme.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Background

    private var backgroundGradient: some View {
        TerminalBackground(starCount: 35, showGrid: false)
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 8) {
            PortfolioHeaderView(
                greeting: personalizedGreeting,
                sunSign: user.sunSign,
                portfolioValue: user.formattedPortfolioValue,
                dailyChange: user.formattedDailyChange,
                dailyChangePercent: user.formattedDailyChangePercent,
                isPositive: user.isPortfolioPositive
            )

            // Last update indicator
            HStack(spacing: 6) {
                if isFetchingPrices {
                    ProgressView()
                        .scaleEffect(0.6)
                        .tint(CosmicTheme.gold)
                    Text("Updating prices...")
                        .font(.caption2)
                        .foregroundColor(CosmicTheme.textMuted)
                } else if stockAPI.isOfflineMode {
                    Image(systemName: "wifi.slash")
                        .font(.caption2)
                    Text("Prices may be delayed")
                        .font(.caption2)
                        .foregroundColor(.orange)
                } else if let updateText = lastUpdateText {
                    Image(systemName: "clock")
                        .font(.caption2)
                    Text(updateText)
                        .font(.caption2)
                        .foregroundColor(CosmicTheme.textMuted)
                }
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
            .padding(.trailing, 4)
        }
    }

    // MARK: - Visualization Toggle

    private var visualizationToggle: some View {
        HStack(spacing: 0) {
            toggleButton(
                title: "Wheel",
                icon: "circle.hexagongrid.fill",
                isSelected: showWheelView
            ) {
                withAnimation(.spring(response: 0.3)) {
                    showWheelView = true
                }
            }

            toggleButton(
                title: "Card",
                icon: "rectangle.fill",
                isSelected: !showWheelView
            ) {
                withAnimation(.spring(response: 0.3)) {
                    showWheelView = false
                }
            }
        }
        .padding(2)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(CosmicTheme.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(CosmicTheme.border, lineWidth: 0.5)
                )
        )
    }

    private func toggleButton(
        title: String,
        icon: String,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                Text(title)
                    .font(TerminalFont.data(11))
            }
            .foregroundColor(isSelected ? CosmicTheme.background : CosmicTheme.textSecondary)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 2)
                    .fill(isSelected ? CosmicTheme.gold : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Cosmic Balance Section

    @ViewBuilder
    private var cosmicBalanceSection: some View {
        if showWheelView {
            ZodiacWheelView(
                breakdown: elementBreakdown,
                stocksByElement: holdingsByElement,
                totalValue: user.formattedPortfolioValue
            )
            .transition(.asymmetric(
                insertion: .scale(scale: 0.9).combined(with: .opacity),
                removal: .scale(scale: 0.9).combined(with: .opacity)
            ))
        } else {
            CosmicBalanceCard(
                breakdown: elementBreakdown,
                insight: elementInsight
            )
            .transition(.asymmetric(
                insertion: .scale(scale: 0.9).combined(with: .opacity),
                removal: .scale(scale: 0.9).combined(with: .opacity)
            ))
        }
    }

    // MARK: - Cosmic Mood Section

    private var cosmicMoodSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section header
            HStack {
                Image(systemName: "gauge.with.needle.fill")
                    .foregroundColor(CosmicTheme.gold)
                Text("Market Mood")
                    .font(TerminalFont.headline(14))
                    .foregroundColor(CosmicTheme.textPrimary)

                Spacer()

                Text("Fear & Greed")
                    .font(TerminalFont.data(10))
                    .foregroundColor(CosmicTheme.textMuted)
            }

            // Mood widget
            CosmicMoodWidget(moodData: moodService.getCurrentMood()) {
                showMoodDetail = true
            }
        }
    }

    // MARK: - Holdings Section

    private var holdingsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            holdingsSectionHeader

            if holdings.isEmpty {
                emptyHoldingsView
            } else {
                holdingsList
            }
        }
    }

    private var holdingsSectionHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Your Holdings")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(CosmicTheme.textPrimary)

                if !holdings.isEmpty {
                    Text("\(holdingsCount) positions - \(averageCompatibility)% avg. compatibility")
                        .font(.caption)
                        .foregroundColor(CosmicTheme.textMuted)
                }
            }

            Spacer()

            if !holdings.isEmpty {
                Button(action: {}) {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                        .font(.title3)
                        .foregroundColor(CosmicTheme.textSecondary)
                }
            }
        }
        .padding(.top, 8)
    }

    private var holdingsList: some View {
        LazyVStack(spacing: 12) {
            ForEach(holdings) { stock in
                HoldingRow(
                    stock: stock,
                    compatibility: user.compatibility(with: stock),
                    onTap: {
                        selectedStock = stock
                    }
                )
            }
        }
    }

    private var emptyHoldingsView: some View {
        VStack(spacing: 16) {
            Image(systemName: "sparkles")
                .font(.system(size: 48))
                .foregroundStyle(CosmicTheme.goldGradient)

            Text("Your portfolio is empty")
                .font(.headline)
                .foregroundColor(CosmicTheme.textPrimary)

            Text("Explore stocks to find ones aligned with your cosmic energy.")
                .font(.subheadline)
                .foregroundColor(CosmicTheme.textSecondary)
                .multilineTextAlignment(.center)

            Text("Swipe right to the Discover tab to get started!")
                .font(.caption)
                .foregroundColor(CosmicTheme.textMuted)
                .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .padding(40)
        .terminalCard()
    }

    // MARK: - Data Recovery Banner

    private var dataRecoveryBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "arrow.triangle.2.circlepath")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(CosmicTheme.accentBlue)
                .frame(width: 36, height: 36)
                .background(
                    Circle()
                        .fill(CosmicTheme.accentBlue.opacity(0.15))
                )

            VStack(alignment: .leading, spacing: 2) {
                Text("Cosmic Data Restored")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(CosmicTheme.textPrimary)

                Text("Your profile was recovered from backup")
                    .font(.caption)
                    .foregroundColor(CosmicTheme.textSecondary)
            }

            Spacer()

            Button(action: {
                withAnimation(.easeOut(duration: 0.2)) {
                    showDataRecoveryAlert = true
                }
            }) {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(CosmicTheme.textMuted)
                    .frame(width: 24, height: 24)
                    .background(Circle().fill(CosmicTheme.cardBackground))
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(CosmicTheme.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(CosmicTheme.accentBlue.opacity(0.4), lineWidth: 0.5)
                )
        )
        .transition(.asymmetric(
            insertion: .move(edge: .top).combined(with: .opacity),
            removal: .opacity
        ))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Cosmic data restored. Your profile was recovered from backup.")
        .accessibilityAddTraits(.isButton)
        .accessibilityHint("Double tap to dismiss")
    }

    // MARK: - Actions

    private func refreshPortfolio() async {
        isRefreshing = true
        isFetchingPrices = true
        currentError = nil

        await fetchLivePrices()

        isRefreshing = false
        isFetchingPrices = false
    }

    /// Fetch live prices for all holdings
    private func fetchLivePrices() async {
        guard !holdings.isEmpty else { return }

        let symbols = holdings.map { $0.symbol }

        // Fetch quotes for all holdings
        let quotes = await stockAPI.getMultipleQuotes(symbols: symbols)

        // Update portfolio with live prices
        if !quotes.isEmpty {
            await MainActor.run {
                appState.updatePortfolioPrices(with: quotes)
                lastPriceUpdate = Date()

                // Check for any errors
                if let error = stockAPI.lastError {
                    currentError = error
                }
            }
        } else if let error = stockAPI.lastError {
            currentError = error
        }
    }

    /// Format the last update time
    private var lastUpdateText: String? {
        guard let lastUpdate = lastPriceUpdate else { return nil }
        let age = Date().timeIntervalSince(lastUpdate)
        let minutes = Int(age / 60)

        if minutes < 1 {
            return "Updated just now"
        } else if minutes == 1 {
            return "Updated 1 min ago"
        } else if minutes < 60 {
            return "Updated \(minutes) mins ago"
        } else {
            return "Updated \(minutes / 60)h ago"
        }
    }
}

// MARK: - Preview

#Preview("Portfolio View") {
    PortfolioView()
        .environment(AppState.preview)
        .preferredColorScheme(.dark)
}

#Preview("Portfolio View - Empty") {
    PortfolioView()
        .environment(AppState(user: .newUser))
        .preferredColorScheme(.dark)
}
