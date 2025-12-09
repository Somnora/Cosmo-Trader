import Foundation

/// DiscoverViewModel
/// -----------------
/// The "brain" for the Discover tab where users find new stocks.
///
/// This ViewModel handles:
/// - Search functionality
/// - Trending stocks
/// - Stock categories/sectors

@Observable
class DiscoverViewModel {

    // MARK: - Properties

    /// What the user is searching for
    var searchText: String = ""

    /// Trending stocks to show
    var trendingStocks: [Stock] = []

    /// Is search in progress?
    var isSearching: Bool = false

    /// Categories of stocks (Tech, Healthcare, etc.)
    var categories: [StockCategory] = StockCategory.samples

    // MARK: - Computed Properties

    /// Filter trending stocks based on search
    var filteredStocks: [Stock] {
        if searchText.isEmpty {
            return trendingStocks
        }
        return trendingStocks.filter { stock in
            stock.symbol.localizedCaseInsensitiveContains(searchText) ||
            stock.name.localizedCaseInsensitiveContains(searchText)
        }
    }

    // MARK: - Methods

    /// Load trending stocks
    func loadTrendingStocks() async {
        isSearching = true

        // Simulate network delay
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds

        // Use sample data for now
        trendingStocks = Stock.samples
        isSearching = false
    }

    /// Search for stocks (would call API in real app)
    func searchStocks() async {
        guard !searchText.isEmpty else { return }

        isSearching = true
        // Simulate search delay
        try? await Task.sleep(nanoseconds: 300_000_000)
        isSearching = false
    }
}

// MARK: - Supporting Types

/// A category of stocks (e.g., Technology, Healthcare)
struct StockCategory: Identifiable {
    let id = UUID()
    let name: String
    let icon: String // SF Symbol name
    let stockCount: Int

    static let samples: [StockCategory] = [
        StockCategory(name: "Technology", icon: "laptopcomputer", stockCount: 245),
        StockCategory(name: "Healthcare", icon: "heart.fill", stockCount: 189),
        StockCategory(name: "Finance", icon: "dollarsign.circle.fill", stockCount: 167),
        StockCategory(name: "Energy", icon: "bolt.fill", stockCount: 98),
        StockCategory(name: "Consumer", icon: "cart.fill", stockCount: 312)
    ]
}
