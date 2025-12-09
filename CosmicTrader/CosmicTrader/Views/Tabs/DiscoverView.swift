import SwiftUI

/// DiscoverView
/// ------------
/// The Discover tab - where users find new stocks to invest in.
///
/// Features a search bar, trending stocks, and stock categories.

struct DiscoverView: View {

    @State private var viewModel = DiscoverViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                CosmicTheme.background
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Search bar
                        searchBar

                        // Categories
                        categoriesSection

                        // Trending stocks
                        trendingSection
                    }
                    .padding()
                }
            }
            .navigationTitle("Discover")
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(CosmicTheme.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
        .task {
            await viewModel.loadTrendingStocks()
        }
    }

    // MARK: - Subviews

    /// Search input field
    private var searchBar: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(CosmicTheme.textMuted)

            TextField("Search stocks...", text: $viewModel.searchText)
                .foregroundColor(CosmicTheme.textPrimary)

            if !viewModel.searchText.isEmpty {
                Button(action: { viewModel.searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(CosmicTheme.textMuted)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(CosmicTheme.cardBackground)
        )
    }

    /// Horizontal scrolling categories
    private var categoriesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Categories")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(CosmicTheme.textPrimary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(viewModel.categories) { category in
                        CategoryCard(category: category)
                    }
                }
            }
        }
    }

    /// Trending stocks section
    private var trendingSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Trending")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(CosmicTheme.textPrimary)

                Spacer()

                Image(systemName: "flame.fill")
                    .foregroundColor(CosmicTheme.gold)
            }

            if viewModel.isSearching {
                ProgressView()
                    .tint(CosmicTheme.gold)
                    .frame(maxWidth: .infinity, minHeight: 100)
            } else {
                ForEach(viewModel.filteredStocks) { stock in
                    DiscoverStockRow(stock: stock)
                }
            }
        }
    }
}

// MARK: - Category Card Component

struct CategoryCard: View {
    let category: StockCategory

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(CosmicTheme.cosmicGradient)
                    .frame(width: 50, height: 50)

                Image(systemName: category.icon)
                    .font(.title2)
                    .foregroundColor(.white)
            }

            Text(category.name)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(CosmicTheme.textPrimary)

            Text("\(category.stockCount) stocks")
                .font(.caption2)
                .foregroundColor(CosmicTheme.textMuted)
        }
        .frame(width: 90)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(CosmicTheme.cardBackground)
        )
    }
}

// MARK: - Discover Stock Row Component

struct DiscoverStockRow: View {
    let stock: Stock

    var body: some View {
        HStack(spacing: 12) {
            // Stock symbol badge
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(CosmicTheme.nebulaBlue.opacity(0.3))
                    .frame(width: 50, height: 50)

                Text(String(stock.symbol.prefix(2)))
                    .font(.headline)
                    .foregroundColor(CosmicTheme.gold)
            }

            // Stock info
            VStack(alignment: .leading, spacing: 4) {
                Text(stock.symbol)
                    .font(.headline)
                    .foregroundColor(CosmicTheme.textPrimary)

                Text(stock.name)
                    .font(.caption)
                    .foregroundColor(CosmicTheme.textSecondary)
                    .lineLimit(1)
            }

            Spacer()

            // Add button
            Button(action: {}) {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .foregroundColor(CosmicTheme.gold)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(CosmicTheme.cardBackground)
        )
    }
}

// MARK: - Preview

#Preview {
    DiscoverView()
        .preferredColorScheme(.dark)
}
