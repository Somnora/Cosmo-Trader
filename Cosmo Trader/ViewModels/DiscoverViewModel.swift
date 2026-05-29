import Foundation
import SwiftUI

// MARK: - DiscoverViewModel

/// ViewModel for the stock discovery interface.
///
/// `DiscoverViewModel` manages the operational stock discovery experience, handling the card deck,
/// swipe gestures, filtering, and sorting. It integrates with ``AppState`` to track
/// watchlist additions and skipped stocks.
///
/// ## Architecture
///
/// ```
/// DiscoverView ──> DiscoverViewModel ──> AppState
///      │                  │                  │
///      │                  │                  └── Persists watchlist/skipped
///      │                  └── Manages card deck & filters
///      └── Renders swipeable cards
/// ```
///
/// ## Usage
///
/// ```swift
/// struct DiscoverView: View {
///     @State private var viewModel = DiscoverViewModel()
///
///     var body: some View {
///         ForEach(viewModel.cardDeck) { card in
///             StockCardView(card: card)
///                 .gesture(swipeGesture(for: card))
///         }
///     }
/// }
/// ```
///
/// ## Swipe Actions
///
/// | Swipe | Action | Result |
/// |-------|--------|--------|
/// | Right | Like | Added to watchlist |
/// | Left | Skip | Hidden from deck |
/// | Up | Signal | Opens stock detail sheet |
///
/// ## Filtering
///
/// Users can filter by:
/// - **Element**: Fire, Earth, Air, Water (zodiac-based)
/// - **Sector**: Technology, Healthcare, Finance, etc.
/// - **Sort**: Compatibility score or price performance
/// - **Contrarian Mode**: Shows least compatible stocks first
@Observable
class DiscoverViewModel {

    // MARK: - Properties

    /// Reference to shared app state for persisting user actions.
    private var appState: AppState

    /// Curated sample discovery universe. Discover cards must visibly label the
    /// price/change fields as sample until live provider enrichment exists.
    private var allStocks: [Stock] = Stock.samples + MockStockData.all

    /// Field-level source state for the price/change fields on discovery cards.
    private var quoteProvenanceBySymbol: [String: FinancialDataProvenance] = [:]

    /// The current card deck after applying filters and sorting.
    ///
    /// Cards are displayed from index 0 (top of deck) to last (bottom).
    var cardDeck: [StockCard] = []

    /// Currently selected element filter.
    ///
    /// When set, only stocks whose zodiac sign matches this element are shown.
    /// Set to `nil` to show all elements.
    var selectedElement: ZodiacSign.Element?

    /// Currently selected sector filter.
    ///
    /// When set, only stocks in this sector are shown.
    /// Set to `nil` to show all sectors.
    var selectedSector: String?

    /// How cards are sorted in the deck.
    var sortOption: SortOption = .compatibility

    /// When enabled, shows least compatible stocks first for diversification review.
    var cosmicContrarianMode: Bool = false

    /// Whether the filter sheet is currently presented.
    var showingFilters: Bool = false

    /// Stock currently being viewed in the detail sheet (from swipe up).
    var detailStock: Stock?

    /// Work item for debouncing filter changes.
    private var filterDebounceWork: DispatchWorkItem?

    // MARK: - Initialization

    /// Creates a new discover view model.
    ///
    /// - Parameter appState: The app state to use for persistence. Defaults to shared instance.
    init(appState: AppState = AppState.shared) {
        self.appState = appState
        rebuildDeck()
    }

    // MARK: - Computed Properties

    /// Current user from app state (nil if not logged in)
    var user: UserProfile? {
        appState.currentUser
    }

    /// Stocks that pass current filters
    private var filteredStocks: [Stock] {
        guard let user = user else { return [] }
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
            stocks = stocks.filter { $0.foundedElement == element }
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
        user?.watchlist.count ?? 0
    }

    /// Skipped stocks count
    var skippedCount: Int {
        user?.skippedStocks.count ?? 0
    }

    /// Is deck empty?
    var isDeckEmpty: Bool {
        cardDeck.isEmpty
    }

    // MARK: - Card Deck Management

    /// Rebuild the card deck with current filters and sort
    func rebuildDeck() {
        guard let user = user else {
            cardDeck = []
            return
        }
        var stocks = filteredStocks

        // In contrarian mode, prioritize least compatible stocks
        if cosmicContrarianMode {
            // Sort by LOWEST compatibility first
            stocks.sort { stock1, stock2 in
                let score1 = user.compatibility(with: stock1).score
                let score2 = user.compatibility(with: stock2).score
                return score1 < score2  // Ascending order (lowest first)
            }
        } else {
            // Normal sorting logic
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
        }

        // Create stock cards with compatibility and portfolio-aware context
        let previousCount = cardDeck.count
        cardDeck = stocks.map { stock in
            let priceProvenance = priceProvenance(for: stock)
            return StockCard(
                stock: stock,
                compatibility: user.compatibility(with: stock),
                whyToday: whyToday(for: stock, user: user, priceProvenance: priceProvenance),
                priceProvenance: priceProvenance
            )
        }

        // Track deck refresh if cards were added (deck was empty or significantly changed)
        if previousCount == 0 && !cardDeck.isEmpty {
            AnalyticsService.shared.trackDiscoverDeckRefreshed(cardCount: cardDeck.count)
        }
    }

    /// Enrich the visible discovery universe with provider-backed quotes where available.
    @MainActor
    func refreshProviderQuotesForDeck(limit: Int = 8) async {
        let symbols = Array(Set(filteredStocks.prefix(limit).map { $0.symbol.uppercased() }))
        guard !symbols.isEmpty else { return }

        let results = await StockAPIService.shared.getMultipleQuoteResults(symbols: symbols)

        for symbol in symbols {
            guard let result = results[symbol] else { continue }

            if let quote = result.quote {
                if let index = allStocks.firstIndex(where: { $0.symbol.uppercased() == symbol }) {
                    allStocks[index] = allStocks[index].withQuote(quote)
                }
                quoteProvenanceBySymbol[symbol] = result.provenance
            } else {
                quoteProvenanceBySymbol[symbol] = .sample(reason: "Curated sample price; provider quote unavailable")
            }
        }

        rebuildDeck()
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
            zodiacSign: stock.zodiacSign?.displayName ?? "Unknown",
            compatibility: user?.compatibility(with: stock).score ?? 0
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
            zodiacSign: stock.zodiacSign?.displayName ?? "Unknown",
            compatibility: user?.compatibility(with: stock).score ?? 0
        )
    }

    /// View detail
    func viewDetail(_ stock: Stock, source: String = "discover") {
        detailStock = stock

        AnalyticsService.shared.trackStockDetailOpened(symbol: stock.symbol, source: source)
    }

    /// Remove the top card from deck
    private func removeTopCard() {
        guard !cardDeck.isEmpty else { return }
        _ = withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
            cardDeck.removeFirst()
        }

        // Track if deck is now empty
        if cardDeck.isEmpty {
            AnalyticsService.shared.trackDiscoverDeckEmpty()
        }
    }

    /// Undo last skip (if possible)
    func undoLastSkip() {
        guard let user = appState.currentUser,
              user.skippedStocks.last != nil else { return }

        // Remove last skipped
        var updatedUser = user
        updatedUser.skippedStocks.removeLast()
        // Note: AppState would need a method for this
        rebuildDeck()
    }

    // MARK: - Filter Actions

    /// Debounced rebuild deck to prevent excessive computation during rapid filter changes
    private func debouncedRebuildDeck(delay: TimeInterval = 0.15) {
        filterDebounceWork?.cancel()
        let workItem = DispatchWorkItem { [weak self] in
            self?.rebuildDeck()
        }
        filterDebounceWork = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: workItem)
    }

    /// Set element filter
    func setElementFilter(_ element: ZodiacSign.Element?) {
        selectedElement = element
        debouncedRebuildDeck()
    }

    /// Set sector filter
    func setSectorFilter(_ sector: String?) {
        selectedSector = sector
        debouncedRebuildDeck()
    }

    /// Set sort option
    func setSortOption(_ option: SortOption) {
        sortOption = option
        debouncedRebuildDeck()
    }

    /// Clear all filters
    func clearFilters() {
        selectedElement = nil
        selectedSector = nil
        rebuildDeck() // Immediate for clear action
    }

    /// Reset skipped stocks
    func resetSkipped() {
        appState.resetSkippedStocks()
        rebuildDeck()
    }

    // MARK: - Cosmic Contrarian Mode

    /// Toggle Cosmic Contrarian mode
    func toggleContrarianMode() {
        cosmicContrarianMode.toggle()
        rebuildDeck()

        // Track analytics
        AnalyticsService.shared.track(
            cosmicContrarianMode ? .cosmicContrarianEnabled : .cosmicContrarianDisabled
        )
    }

    /// Get the contrarian insight text based on user's sign
    var contrarianInsight: String {
        guard let userSign = user?.sunSign else {
            return "Discover stocks outside your usual cosmic profile."
        }
        let oppositeElement = userSign.element.oppositeElement

        return "Outside your \(userSign.element.displayName) profile. These \(oppositeElement.displayName) names can diversify the reading if the thesis is strong."
    }

    /// Get stocks that are cosmically opposed to user
    var contrarianStocks: [Stock] {
        guard let userSign = user?.sunSign else { return [] }
        return filteredStocks.filter { stock in
            // Opposite sign or opposite element
            stock.zodiacSign == userSign.oppositeSign ||
            stock.foundedElement == userSign.element.oppositeElement
        }
    }

    private func whyToday(
        for stock: Stock,
        user: UserProfile,
        priceProvenance: FinancialDataProvenance
    ) -> String {
        let holdings = user.portfolio.filter(\.isOwned)
        let lunarData = MoonPhaseService.shared.getCurrentLunarData()
        let stockElement = stock.foundedElement

        guard !holdings.isEmpty else {
            if stockElement == lunarData.activatedElement {
                return "\(lunarData.phase.rawValue) activates \(lunarData.activatedElement.displayName.lowercased()) exposure; useful starter candidate for setup."
            }
            return "Useful starter candidate. Add holdings so Today can compare real portfolio exposure."
        }

        let role = portfolioRole(for: stock, holdings: holdings)

        if priceProvenance.isProviderBacked && abs(stock.percentageChange) >= 3 {
            let direction = stock.percentageChange >= 0 ? "Momentum is elevated" : "Volatility is elevated"
            return "\(direction); \(role)"
        }

        if stockElement == lunarData.activatedElement {
            return "\(lunarData.phase.rawValue) activates \(lunarData.activatedElement.displayName.lowercased()) exposure; \(role)"
        }

        let mood = CosmicMoodService.shared.getCurrentMood()
        if mood.isMarketBacked, let value = mood.value {
            if value >= 75 {
                return "Risk appetite is elevated; \(role)"
            }

            if value <= 40 {
                return "Low-conviction tape; \(role)"
            }
        }

        return role
    }

    private func priceProvenance(for stock: Stock) -> FinancialDataProvenance {
        quoteProvenanceBySymbol[stock.symbol.uppercased()] ?? .sample(reason: "Curated sample price")
    }

    private func portfolioRole(for stock: Stock, holdings: [Stock]) -> String {
        guard let element = stock.foundedElement else {
            return "has unknown company-date exposure; verify fundamentals before saving."
        }
        let verifiedHoldings = holdings.filter { $0.foundedElement != nil }
        let sameElementWeight = exposureWeight(
            verifiedHoldings.filter { $0.foundedElement == element }
        )
        let totalWeight = exposureWeight(verifiedHoldings)
        let elementShare = totalWeight > 0 ? sameElementWeight / totalWeight : 0
        let hasElement = sameElementWeight > 0
        let sectorCount = holdings.filter { $0.sector == stock.sector }.count

        if elementShare >= 0.45 {
            return "intensifies \(element.displayName.lowercased())-heavy exposure; lean reading."
        }

        if !hasElement {
            return "adds \(element.displayName.lowercased()) exposure your portfolio does not carry yet."
        }

        if sectorCount > 0 {
            return "adds another \(stock.sector.lowercased()) name; compare concentration before saving."
        }

        return "broadens the mix with \(stock.sector.lowercased()) exposure."
    }

    private func exposureWeight(_ holdings: [Stock]) -> Double {
        holdings.reduce(0) { total, stock in
            total + stock.marketValue
        }
    }
}

// MARK: - Element Extension for Contrarian

extension ZodiacSign.Element {
    /// Get the opposite element (Fire<->Water, Earth<->Air)
    var oppositeElement: ZodiacSign.Element {
        switch self {
        case .fire: return .water
        case .water: return .fire
        case .earth: return .air
        case .air: return .earth
        }
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
    var whyToday: String = "Review alongside today's portfolio posture before saving."
    var priceProvenance: FinancialDataProvenance = .sample(reason: "Curated sample price")

    /// Is this a high cosmic fit (85%+ compatibility)?
    var isCosmicMatch: Bool {
        compatibility.score >= 85
    }

    /// Is this a low-fit challenge?
    var isCosmicChallenge: Bool {
        compatibility.score <= 40
    }
}
