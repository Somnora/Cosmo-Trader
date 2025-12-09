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

    // MARK: - Properties

    /// The ViewModel containing all portfolio data and logic
    @State private var viewModel = PortfolioViewModel()

    /// Track if we're showing a selected stock detail
    @State private var selectedStock: Stock?

    /// Toggle between wheel view and simple card view
    @State private var showWheelView: Bool = true

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
                        visualizationToggle

                        // 3. Cosmic Balance visualization (wheel or card)
                        cosmicBalanceSection

                        // 4. Holdings list
                        holdingsSection
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 100) // Extra padding for tab bar
                }
                .refreshable {
                    await viewModel.refreshPortfolio()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    // Custom title in nav bar
                    HStack(spacing: 6) {
                        Image(systemName: "chart.pie.fill")
                            .foregroundColor(CosmicTheme.gold)
                        Text("Portfolio")
                            .font(.headline)
                            .foregroundColor(CosmicTheme.textPrimary)
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    // Notification/Settings button
                    Button(action: {}) {
                        Image(systemName: "bell.badge")
                            .foregroundColor(CosmicTheme.textSecondary)
                    }
                }
            }
            .toolbarBackground(CosmicTheme.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .navigationDestination(item: $selectedStock) { stock in
                StockDetailView(stock: stock, user: viewModel.user)
            }
        }
    }

    // MARK: - Background

    /// Cosmic gradient background
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

    /// The header showing greeting, sun sign, and portfolio value
    private var headerSection: some View {
        PortfolioHeaderView(
            greeting: viewModel.personalizedGreeting,
            sunSign: viewModel.user.sunSign,
            portfolioValue: viewModel.formattedPortfolioValue,
            dailyChange: viewModel.formattedDailyChange,
            dailyChangePercent: viewModel.formattedDailyChangePercent,
            isPositive: viewModel.isPortfolioPositive
        )
    }

    // MARK: - Visualization Toggle

    /// Toggle between wheel and card view
    private var visualizationToggle: some View {
        HStack(spacing: 0) {
            // Wheel view button
            toggleButton(
                title: "Wheel",
                icon: "circle.hexagongrid.fill",
                isSelected: showWheelView
            ) {
                withAnimation(.spring(response: 0.3)) {
                    showWheelView = true
                }
            }

            // Card view button
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

    /// The elemental breakdown visualization (wheel or card)
    @ViewBuilder
    private var cosmicBalanceSection: some View {
        if showWheelView {
            // Interactive zodiac wheel
            ZodiacWheelView(
                breakdown: viewModel.elementBreakdown,
                stocksByElement: viewModel.holdingsByElement,
                totalValue: viewModel.formattedPortfolioValue
            )
            .transition(.asymmetric(
                insertion: .scale(scale: 0.9).combined(with: .opacity),
                removal: .scale(scale: 0.9).combined(with: .opacity)
            ))
        } else {
            // Simple card view
            CosmicBalanceCard(
                breakdown: viewModel.elementBreakdown,
                insight: viewModel.elementInsight
            )
            .transition(.asymmetric(
                insertion: .scale(scale: 0.9).combined(with: .opacity),
                removal: .scale(scale: 0.9).combined(with: .opacity)
            ))
        }
    }

    // MARK: - Holdings Section

    /// The list of stock holdings
    private var holdingsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section header
            holdingsSectionHeader

            // Stock rows
            if viewModel.holdings.isEmpty {
                emptyHoldingsView
            } else {
                holdingsList
            }
        }
    }

    /// Holdings section header with count
    private var holdingsSectionHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Your Holdings")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(CosmicTheme.textPrimary)

                Text("\(viewModel.holdingsCount) positions · \(viewModel.averageCompatibility)% avg. compatibility")
                    .font(.caption)
                    .foregroundColor(CosmicTheme.textMuted)
            }

            Spacer()

            // Sort/Filter button (placeholder for now)
            Button(action: {}) {
                Image(systemName: "line.3.horizontal.decrease.circle")
                    .font(.title3)
                    .foregroundColor(CosmicTheme.textSecondary)
            }
        }
        .padding(.top, 8)
    }

    /// List of holding rows
    private var holdingsList: some View {
        LazyVStack(spacing: 12) {
            ForEach(viewModel.holdings) { stock in
                HoldingRow(
                    stock: stock,
                    compatibility: viewModel.compatibility(for: stock),
                    onTap: {
                        selectedStock = stock
                    }
                )
            }
        }
    }

    /// Empty state when no holdings
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

            Button(action: {}) {
                Text("Discover Stocks")
                    .font(.headline)
                    .foregroundColor(CosmicTheme.background)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(CosmicTheme.goldGradient)
                    .cornerRadius(25)
            }
            .padding(.top, 8)
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
}

// MARK: - Preview

#Preview("Portfolio View - Wheel") {
    PortfolioView()
        .preferredColorScheme(.dark)
}

#Preview("Portfolio View - Empty") {
    let emptyUser = UserProfile(
        displayName: "New User",
        email: "new@test.com",
        birthMonth: 3,
        birthDay: 21,
        birthYear: 1995,
        portfolio: []
    )

    return PortfolioView()
        .preferredColorScheme(.dark)
        .onAppear {
            // Note: In a real app, you'd inject this via environment
        }
}
