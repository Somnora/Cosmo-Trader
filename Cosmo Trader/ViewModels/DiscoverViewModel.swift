import Foundation
import SwiftUI

// MARK: - DiscoverViewModel
// =========================
// The brain behind the "dating app for stocks" Discover tab.
//
// Responsibilities:
// - Manage stock card deck
// - Handle swipe actions (like, skip, view detail)
// - Filter by element and sector
// - Sort by compatibility or performance
// - Track watchlist and skipped stocks
//
// Now works with AppState for shared user data.

@Observable
class DiscoverViewModel {

    // MARK: - Properties

    /// Reference to shared app state
    private var appState: AppState

    /// All available stocks from MockStockData
    private var allStocks: [Stock] = MockStockData.all

    /// Current card deck (filtered and sorted)
    var cardDeck: [StockCard] = []

    /// Currently selected element filter (nil = all)
    var selectedElement: ZodiacSign.Element?

    /// Currently selected sector filter (nil = all)
    var selectedSector: String?

    /// Current sort option
    var sortOption: SortOption = .compatibility

    /// Whether filter sheet is showing
    var showingFilters: Bool = false

    /// The stock being viewed in detail (swipe up)
    var detailStock: Stock?

    /// Animation state for card removal
    var removingCard: Bool = false

    // MARK: - Initialization

    init(appState: AppState = AppState.shared) {
        self.appState = appState
        rebuildDeck()
    }

    // MARK: - Computed Properties

    /// Current user from app state
    var user: UserProfile {
        appState.currentUser ?? .sampleWithHoldings
    }

    /// Stocks that pass current filters
    private var filteredStocks: [Stock] {
        var stocks = allStocks

        // Exclude already owned stocks
        let ownedSymbols = Set(user.portfolio.map { $0.symbol })
        stocks = stocks.filter { !ownedSymbols.contains($0.symbol) }

        // Exclude skipped stocks
        stocks = stocks.filter { !user.isSkipped($0.symbol) }

        // Exclude stocks already in watchlist
        stocks = stocks.filter { !user.isInWatchlist($0.symbol) }

        // Apply element filter
        if let element = selectedElement {
            stocks = stocks.filter { $0.zodiacSign.element == element }
        }

        // Apply sector filter
        if let sector = selectedSector {
            stocks = stocks.filter { $0.sector == sector }
        }

        return stocks
    }

    /// Available sectors for filtering
    var availableSectors: [String] {
        let sectors = Set(allStocks.map { $0.sector })
        return Array(sectors).sorted()
    }

    /// Number of stocks in deck
    var deckCount: Int {
        cardDeck.count
    }

    /// Top card in the deck
    var topCard: StockCard? {
        cardDeck.first
    }

    /// Watchlist count for display
    var watchlistCount: Int {
        user.watchlist.count
    }

    /// Skipped stocks count
    var skippedCount: Int {
        user.skippedStocks.count
    }

    /// Is deck empty?
    var isDeckEmpty: Bool {
        cardDeck.isEmpty
    }

    // MARK: - Card Deck Management

    /// Rebuild the card deck with current filters and sort
    func rebuildDeck() {
        var stocks = filteredStocks

        // Sort stocks
        switch sortOption {
        case .compatibility:
            stocks.sort { stock1, stock2 in
                let score1 = user.compatibility(with: stock1).score
                let score2 = user.compatibility(with: stock2).score
                return score1 > score2
            }
        case .performance:
            stocks.sort { $0.percentageChange > $1.percentageChange }
        case .price:
            stocks.sort { $0.currentPrice < $1.currentPrice }
        case .alphabetical:
            stocks.sort { $0.name < $1.name }
        }

        // Create stock cards with compatibility
        cardDeck = stocks.map { stock in
            StockCard(
                stock: stock,
                compatibility: user.compatibility(with: stock)
            )
        }
    }

    // MARK: - Swipe Actions

    /// Swipe right - add to watchlist
    func likeStock(_ stock: Stock) {
        appState.addToWatchlist(stock.symbol)
        removeTopCard()

        // Track swipe right (like)
        AnalyticsService.shared.trackDiscoverySwipe(
            direction: "right",
            symbol: stock.symbol,
            zodiacSign: stock.zodiacSign.displayName,
            compatibility: user.compatibility(with: stock).score
        )
        AnalyticsService.shared.trackWatchlistAdded(symbol: stock.symbol, source: "discover_swipe")
    }

    /// Swipe left - skip stock
    func skipStock(_ stock: Stock) {
        appState.skipStock(stock.symbol)
        removeTopCard()

        // Track swipe left (skip)
        AnalyticsService.shared.trackDiscoverySwipe(
            direction: "left",
            symbol: stock.symbol,
            zodiacSign: stock.zodiacSign.displayName,
            compatibility: user.compatibility(with: stock).score
        )
    }

    /// Swipe up - view detail
    func viewDetail(_ stock: Stock) {
        detailStock = stock

        // Track swipe up (view detail)
        AnalyticsService.shared.trackStockDetailOpened(symbol: stock.symbol, source: "discover_swipe")
    }

    /// Remove the top card from deck
    private func removeTopCard() {
        guard !cardDeck.isEmpty else { return }
        removingCard = true

        // Small delay for animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.cardDeck.removeFirst()
            self?.removingCard = false
        }
    }

    /// Undo last skip (if possible)
    func undoLastSkip() {
        guard let user = appState.currentUser,
              let lastSkipped = user.skippedStocks.last else { return }

        // Remove last skipped
        var updatedUser = user
        updatedUser.skippedStocks.removeLast()
        // Note: AppState would need a method for this
        rebuildDeck()
    }

    // MARK: - Filter Actions

    /// Set element filter
    func setElementFilter(_ element: ZodiacSign.Element?) {
        selectedElement = element
        rebuildDeck()
    }

    /// Set sector filter
    func setSectorFilter(_ sector: String?) {
        selectedSector = sector
        rebuildDeck()
    }

    /// Set sort option
    func setSortOption(_ option: SortOption) {
        sortOption = option
        rebuildDeck()
    }

    /// Clear all filters
    func clearFilters() {
        selectedElement = nil
        selectedSector = nil
        rebuildDeck()
    }

    /// Reset skipped stocks
    func resetSkipped() {
        appState.resetSkippedStocks()
        rebuildDeck()
    }
}

// MARK: - Supporting Types

/// Sort options for the discover deck
enum SortOption: String, CaseIterable, Identifiable {
    case compatibility = "Cosmic Match"
    case performance = "Performance"
    case price = "Price"
    case alphabetical = "A-Z"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .compatibility: return "sparkles"
        case .performance: return "chart.line.uptrend.xyaxis"
        case .price: return "dollarsign.circle"
        case .alphabetical: return "textformat.abc"
        }
    }
}

/// A stock card with pre-computed compatibility
struct StockCard: Identifiable {
    let id = UUID()
    let stock: Stock
    let compatibility: CompatibilityResult

    /// Is this a "Cosmic Match" (85%+ compatibility)?
    var isCosmicMatch: Bool {
        compatibility.score >= 85
    }
}
