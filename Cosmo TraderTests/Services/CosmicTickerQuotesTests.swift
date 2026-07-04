import Foundation
import Testing
@testable import Cosmo_Trader

// MARK: - Ticker quote feeding (view model)

@MainActor
struct CosmicTickerQuotesViewModelTests {

    @Test("Only provider-backed quotes reach the tape")
    func onlyProviderBackedQuotesReachTape() async throws {
        let results: [String: StockQuoteResult] = [
            "AAPL": liveResult(price: 190, change: 1.5, changePercent: 0.8),
            "TSLA": StockQuoteResult(
                quote: quote(price: 250, change: -2, changePercent: -0.9),
                provenance: .sample(reason: "Preview data"),
                error: nil
            ),
            "MSFT": StockQuoteResult(
                quote: nil,
                provenance: .unavailable(reason: "Rate limited"),
                error: .rateLimited
            )
        ]

        var applied: [Stock]?
        let viewModel = CosmicTickerQuotesViewModel(
            fetchQuote: { symbol in
                results[symbol] ?? StockQuoteResult(
                    quote: nil,
                    provenance: .unavailable(reason: "No fixture"),
                    error: nil
                )
            },
            applyStocks: { applied = $0 }
        )

        await viewModel.load(user: user(watchlist: ["AAPL", "TSLA", "MSFT"], portfolio: []))

        let stocks = try #require(applied)
        #expect(stocks.map(\.symbol) == ["AAPL"])
        #expect(stocks.first?.percentageChange == 0.8)
        #expect(stocks.first?.currentPrice == 190)
    }

    @Test("Watchlist symbols come first, then holdings by market value, capped")
    func symbolPriorityAndCap() {
        let holdings = (1...8).map { index in
            stock(symbol: "H\(index)", sharesOwned: Double(index))  // H8 most valuable
        }
        let symbols = CosmicTickerQuotesViewModel.tickerSymbols(
            for: user(watchlist: ["WLA", "WLB", "H8"], portfolio: holdings)
        )

        #expect(symbols.count == CosmicTickerQuotesViewModel.maximumSymbols)
        // Watchlist first (H8 deduped into its watchlist slot), then
        // holdings in descending market value.
        #expect(symbols[0] == "WLA")
        #expect(symbols[1] == "WLB")
        #expect(symbols[2] == "H8")
        #expect(symbols[3] == "H7")
        #expect(!symbols.dropFirst(3).contains("H8"))
    }

    @Test("No user clears the tape's stock items")
    func noUserClearsStocks() async {
        var applied: [Stock]? = nil
        let viewModel = CosmicTickerQuotesViewModel(
            fetchQuote: { _ in
                Issue.record("Should not fetch with no user")
                return StockQuoteResult(quote: nil, provenance: .unavailable(reason: "x"), error: nil)
            },
            applyStocks: { applied = $0 }
        )

        await viewModel.load(user: nil)

        #expect(applied?.isEmpty == true)
    }

    @Test("Displayed numbers come from the quote, not persisted holding values")
    func numbersComeFromQuoteNotHolding() async throws {
        var holding = stock(symbol: "AAPL", sharesOwned: 3)
        holding.percentageChange = 9.99  // stale persisted value

        var applied: [Stock]?
        let viewModel = CosmicTickerQuotesViewModel(
            fetchQuote: { _ in liveResult(price: 200, change: 0.5, changePercent: 0.25) },
            applyStocks: { applied = $0 }
        )

        await viewModel.load(user: user(watchlist: [], portfolio: [holding]))

        let stocks = try #require(applied)
        #expect(stocks.first?.percentageChange == 0.25)
        #expect(stocks.first?.currentPrice == 200)
    }

    // MARK: Fixtures

    private func user(watchlist: [String], portfolio: [Stock]) -> UserProfile {
        UserProfile(
            displayName: "Ticker Tester",
            email: "ticker@example.com",
            birthDate: Date(timeIntervalSince1970: 0),
            portfolio: portfolio,
            watchlist: watchlist
        )
    }

    private func stock(symbol: String, sharesOwned: Double) -> Stock {
        Stock(
            symbol: symbol,
            name: "\(symbol) Inc.",
            currentPrice: 100,
            priceChange: 1,
            percentageChange: 1,
            sharesOwned: sharesOwned,
            purchasePrice: 90,
            foundedDate: nil,
            sector: "Technology"
        )
    }
}

private func quote(price: Double, change: Double, changePercent: Double) -> StockQuote {
    StockQuote(
        c: price,
        d: change,
        dp: changePercent,
        h: price + 1,
        l: price - 1,
        o: price,
        pc: price - change,
        t: 1_750_000_000
    )
}

private func liveResult(price: Double, change: Double, changePercent: Double) -> StockQuoteResult {
    StockQuoteResult(
        quote: quote(price: price, change: change, changePercent: changePercent),
        provenance: .live(provider: FinancialDataProvenance.finnhubProvider, fetchedAt: Date(timeIntervalSince1970: 1_750_000_000)),
        error: nil
    )
}

// MARK: - Ticker composition (service)

// Serialized: exercises the shared CosmicTickerService singleton's stored
// stock state.
@MainActor
@Suite(.serialized)
struct CosmicTickerServiceCompositionTests {

    @Test("Without stocks the tape is cosmic-only and admits data is unavailable")
    func cosmicOnlyTapeAdmitsUnavailability() {
        let service = CosmicTickerService.shared
        service.updateProviderBackedStocks([])

        let items = service.tickerItems
        #expect(!items.isEmpty)
        #expect(items.allSatisfy { item in
            if case .cosmic = item.type { return true }
            return false
        })
        // The disclosure is deterministic, not a random quip.
        #expect(items.contains { $0.text == "MARKET DATA UNAVAILABLE" })
    }

    @Test("Provider-backed stocks appear on the tape and unavailable quips vanish")
    func providerBackedStocksAppearAndQuipsVanish() {
        let service = CosmicTickerService.shared
        defer { service.updateProviderBackedStocks([]) }

        let stock = Stock(
            symbol: "AAPL",
            name: "Apple Inc.",
            currentPrice: 190,
            priceChange: 1.5,
            percentageChange: 0.8,
            sharesOwned: 0,
            foundedDate: nil,
            sector: "Technology"
        )
        service.updateProviderBackedStocks([stock])

        let items = service.tickerItems
        #expect(items.contains { $0.text == "AAPL +0.8%" })
        #expect(!items.contains { $0.text == "MARKET DATA UNAVAILABLE" })
        #expect(!items.contains { $0.text == "WAIT FOR REAL DATA" })

        // The 30s cosmic refresh must not drop supplied stocks.
        service.refreshTicker()
        #expect(service.tickerItems.contains { $0.text == "AAPL +0.8%" })
    }
}
