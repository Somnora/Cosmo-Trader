import Foundation

/// Feeds the cosmic ticker tape with provider-backed quotes.
///
/// The ticker itself never invents stock data — `CosmicTickerService` only
/// renders price items a caller supplies. This view model is that caller:
/// it picks the user's most relevant symbols (watchlist first, then owned
/// holdings by market value), fetches quotes through the `StockAPIService`
/// actor (cached, coalesced, rate-limited), and forwards only the symbols
/// whose quote is provider-backed. Anything sample, stale-unavailable, or
/// failed is silently omitted — the tape degrades to cosmic-only content
/// rather than showing a number the app cannot stand behind.
@MainActor
@Observable
final class CosmicTickerQuotesViewModel {
    typealias QuoteFetcher = (String) async -> StockQuoteResult

    /// Ticker legibility cap: more than this and the tape becomes noise.
    static let maximumSymbols = 8

    private(set) var isLoading = false

    private let fetchQuote: QuoteFetcher
    private let applyStocks: ([Stock]) -> Void

    init(
        fetchQuote: QuoteFetcher? = nil,
        applyStocks: (([Stock]) -> Void)? = nil
    ) {
        self.fetchQuote = fetchQuote ?? { symbol in
            await StockAPIService.shared.getQuoteWithProvenance(symbol: symbol)
        }
        self.applyStocks = applyStocks ?? { stocks in
            CosmicTickerService.shared.updateProviderBackedStocks(stocks)
        }
    }

    /// Refreshes ticker quotes for the user's symbols. Safe to call on every
    /// Today load: the quote actor coalesces in-flight requests and serves
    /// its cache when fresh.
    func load(user: UserProfile?) async {
        let symbols = Self.tickerSymbols(for: user)
        guard !symbols.isEmpty else {
            applyStocks([])
            return
        }

        isLoading = true

        var stocksBySymbol: [String: Stock] = [:]
        await withTaskGroup(of: (String, StockQuoteResult).self) { group in
            for symbol in symbols {
                group.addTask { [fetchQuote] in
                    (symbol, await fetchQuote(symbol))
                }
            }
            for await (symbol, result) in group {
                guard let stock = Self.tickerStock(symbol: symbol, result: result, user: user) else {
                    continue
                }
                stocksBySymbol[symbol] = stock
            }
        }

        // Task-group completion order is nondeterministic; restore the
        // watchlist-first ordering.
        let ordered = symbols.compactMap { stocksBySymbol[$0] }
        applyStocks(ordered)
        isLoading = false
    }

    /// Watchlist symbols first (discovery intent), then owned holdings by
    /// market value; deduplicated, capped for tape legibility.
    static func tickerSymbols(for user: UserProfile?) -> [String] {
        guard let user else { return [] }

        var seen: Set<String> = []
        var symbols: [String] = []

        for symbol in user.watchlist.map({ $0.uppercased() }) where !seen.contains(symbol) {
            seen.insert(symbol)
            symbols.append(symbol)
        }

        for holding in user.portfolio.filter(\.isOwned).sorted(by: { $0.marketValue > $1.marketValue }) {
            let symbol = holding.symbol.uppercased()
            guard !seen.contains(symbol) else { continue }
            seen.insert(symbol)
            symbols.append(symbol)
        }

        return Array(symbols.prefix(maximumSymbols))
    }

    /// Builds the tape entry for one symbol, or nil when the quote is not
    /// provider-backed. Every displayed number comes from the quote itself,
    /// never from persisted holding values or bundled company metadata.
    private static func tickerStock(
        symbol: String,
        result: StockQuoteResult,
        user: UserProfile?
    ) -> Stock? {
        guard result.provenance.isProviderBacked, let quote = result.quote else {
            return nil
        }

        // Prefer the user's holding for display metadata (name/sector);
        // otherwise a minimal entry — the tape only renders symbol + change.
        // foundedDate stays nil: the ticker makes no astrology claims, and
        // inventing founding metadata is exactly what the guards forbid.
        var stock = user?.portfolio.first { $0.symbol.uppercased() == symbol }
            ?? Stock(
                symbol: symbol,
                name: symbol,
                currentPrice: 0,
                priceChange: 0,
                percentageChange: 0,
                sharesOwned: 0,
                foundedDate: nil,
                sector: "Unknown"
            )
        stock.currentPrice = quote.currentPrice
        stock.priceChange = quote.priceChange
        stock.percentageChange = quote.percentageChange
        return stock
    }
}
