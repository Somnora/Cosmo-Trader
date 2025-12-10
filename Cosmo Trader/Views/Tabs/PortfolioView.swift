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

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                // Full-screen cosmic background
                backgroundGradient

                // Main content
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
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

                        // 4. Holdings list
                        holdingsSection
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 100)
                }
                .refreshable {
                    await refreshPortfolio()
                }
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
        }
    }

    // MARK: - Background

    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                CosmicTheme.background,
                Color(red: 0.08, green: 0.04, blue: 0.20)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }

    // MARK: - Header Section

    private var headerSection: some View {
        PortfolioHeaderView(
            greeting: personalizedGreeting,
            sunSign: user.sunSign,
            portfolioValue: user.formattedPortfolioValue,
            dailyChange: user.formattedDailyChange,
            dailyChangePercent: user.formattedDailyChangePercent,
            isPositive: user.isPortfolioPositive
        )
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
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(CosmicTheme.cardBackground)
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
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .foregroundColor(isSelected ? CosmicTheme.background : CosmicTheme.textSecondary)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
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
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(CosmicTheme.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(CosmicTheme.textMuted.opacity(0.1), lineWidth: 1)
                )
        )
    }

    // MARK: - Actions

    private func refreshPortfolio() async {
        isRefreshing = true
        try? await Task.sleep(nanoseconds: 500_000_000)
        isRefreshing = false
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
