import SwiftUI

/// PortfolioView
/// -------------
/// The main Portfolio tab - shows the user's stock holdings.
///
/// WHAT'S HAPPENING HERE:
/// 1. We create a ViewModel using @State (SwiftUI manages it for us)
/// 2. The View reads data FROM the ViewModel
/// 3. When ViewModel data changes, the View automatically updates!
///
/// Notice how this View doesn't calculate anything - it just displays
/// what the ViewModel tells it to. That's the MVVM pattern!

struct PortfolioView: View {

    /// The ViewModel - our "brain" for this screen
    /// @State tells SwiftUI to watch this and re-render when it changes
    @State private var viewModel = PortfolioViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                // Background color fills the whole screen
                CosmicTheme.background
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Portfolio summary card at the top
                        portfolioSummaryCard

                        // List of owned stocks
                        stocksSection
                    }
                    .padding()
                }
            }
            .navigationTitle("Portfolio")
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(CosmicTheme.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
        .task {
            // Load data when view appears
            await viewModel.refreshStocks()
        }
    }

    // MARK: - Subviews

    /// The big card showing total portfolio value
    private var portfolioSummaryCard: some View {
        VStack(spacing: 16) {
            Text("Total Value")
                .font(.subheadline)
                .foregroundColor(CosmicTheme.textSecondary)

            Text(viewModel.formattedPortfolioValue)
                .font(.system(size: 42, weight: .bold))
                .foregroundColor(CosmicTheme.textPrimary)

            // Daily change indicator
            HStack(spacing: 4) {
                Image(systemName: viewModel.isPortfolioPositive ? "arrow.up.right" : "arrow.down.right")
                Text(viewModel.formattedDailyChange)
                Text("today")
                    .foregroundColor(CosmicTheme.textSecondary)
            }
            .font(.headline)
            .foregroundColor(viewModel.isPortfolioPositive ? CosmicTheme.positive : CosmicTheme.negative)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(CosmicTheme.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(CosmicTheme.gold.opacity(0.3), lineWidth: 1)
                )
        )
    }

    /// Section showing all owned stocks
    private var stocksSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Your Holdings")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(CosmicTheme.textPrimary)

            ForEach(viewModel.stocks) { stock in
                StockRowView(stock: stock)
            }
        }
    }
}

// MARK: - Stock Row Component

/// A single row displaying one stock
/// This is a separate View because it might be reused elsewhere
struct StockRowView: View {
    let stock: Stock

    var body: some View {
        HStack(spacing: 12) {
            // Zodiac symbol badge
            ZStack {
                Circle()
                    .fill(CosmicTheme.cosmicPurple.opacity(0.3))
                    .frame(width: 50, height: 50)

                Text(stock.zodiacSign.symbol)
                    .font(.title2)
            }

            // Stock info
            VStack(alignment: .leading, spacing: 4) {
                Text(stock.symbol)
                    .font(.headline)
                    .foregroundColor(CosmicTheme.textPrimary)

                Text(stock.name)
                    .font(.caption)
                    .foregroundColor(CosmicTheme.textSecondary)
            }

            Spacer()

            // Price and change
            VStack(alignment: .trailing, spacing: 4) {
                Text(formatCurrency(stock.currentPrice))
                    .font(.headline)
                    .foregroundColor(CosmicTheme.textPrimary)

                HStack(spacing: 2) {
                    Image(systemName: stock.isPositive ? "arrow.up.right" : "arrow.down.right")
                        .font(.caption2)
                    Text(String(format: "%.2f%%", stock.percentageChange))
                        .font(.caption)
                }
                .foregroundColor(stock.isPositive ? CosmicTheme.positive : CosmicTheme.negative)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(CosmicTheme.cardBackground)
        )
    }

    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: value)) ?? "$0.00"
    }
}

// MARK: - Preview

#Preview {
    PortfolioView()
        .preferredColorScheme(.dark)
}
