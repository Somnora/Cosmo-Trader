import Foundation
import Testing
@testable import Cosmo_Trader

struct PortfolioAllTimePLSummaryTests {

    private let now = Date()

    @Test("Holding with cost basis and live quote is included with real P/L")
    func includedHoldingComputesRealPL() throws {
        let summary = PortfolioAllTimePLSummary.make(
            holdings: [holding(symbol: "AAPL", shares: 10, currentPrice: 200, purchasePrice: 150)],
            quoteProvenanceBySymbol: ["AAPL": .live(provider: "Finnhub", fetchedAt: now)]
        )

        #expect(summary.includedSymbols == ["AAPL"])
        #expect(summary.totalProfitLoss == 500)
        #expect(summary.includedCostBasis == 1500)
        #expect(try #require(summary.profitLossPercent).isApproximatelyEqual(to: 33.333, tolerance: 0.01))
        #expect(summary.provenance.isProviderBacked)
        #expect(summary.isPartialCoverage == false)
    }

    @Test("Holding without cost basis is excluded, never guessed")
    func missingCostBasisExcluded() {
        let summary = PortfolioAllTimePLSummary.make(
            holdings: [
                holding(symbol: "AAPL", shares: 10, currentPrice: 200, purchasePrice: 150),
                holding(symbol: "ZZZZ", shares: 5, currentPrice: 50, purchasePrice: nil)
            ],
            quoteProvenanceBySymbol: [
                "AAPL": .live(provider: "Finnhub", fetchedAt: now),
                "ZZZZ": .live(provider: "Finnhub", fetchedAt: now)
            ]
        )

        #expect(summary.includedSymbols == ["AAPL"])
        #expect(summary.missingCostBasisSymbols == ["ZZZZ"])
        #expect(summary.totalProfitLoss == 500)
        #expect(summary.isPartialCoverage)
        #expect(summary.coverageLabel == "1 OF 2 HOLDINGS")
    }

    @Test("Cost basis without a provider-backed quote is excluded", arguments: [
        FinancialDataProvenance.sample(reason: "stored import price"),
        FinancialDataProvenance.unavailable(reason: "no quote"),
        FinancialDataProvenance.mixed(reason: "mixed fields")
    ])
    func nonProviderQuoteExcluded(provenance: FinancialDataProvenance) {
        let summary = PortfolioAllTimePLSummary.make(
            holdings: [holding(symbol: "TSLA", shares: 4, currentPrice: 250, purchasePrice: 200)],
            quoteProvenanceBySymbol: ["TSLA": provenance]
        )

        #expect(summary.includedSymbols.isEmpty)
        #expect(summary.missingQuoteSymbols == ["TSLA"])
        #expect(summary.totalProfitLoss == nil)
        #expect(summary.hasResult == false)
        #expect(summary.provenance.isProviderBacked == false)
    }

    @Test("Missing quote entry entirely is excluded")
    func absentQuoteEntryExcluded() {
        let summary = PortfolioAllTimePLSummary.make(
            holdings: [holding(symbol: "TSLA", shares: 4, currentPrice: 250, purchasePrice: 200)],
            quoteProvenanceBySymbol: [:]
        )

        #expect(summary.missingQuoteSymbols == ["TSLA"])
        #expect(summary.totalProfitLoss == nil)
        #expect(summary.unavailableReason == "Waiting on provider quotes for holdings with cost basis.")
    }

    @Test("Zero stored price never prices the current leg")
    func zeroCurrentPriceExcluded() {
        let summary = PortfolioAllTimePLSummary.make(
            holdings: [holding(symbol: "ZZZZ", shares: 3, currentPrice: 0, purchasePrice: 12)],
            quoteProvenanceBySymbol: ["ZZZZ": .live(provider: "Finnhub", fetchedAt: now)]
        )

        #expect(summary.includedSymbols.isEmpty)
        #expect(summary.totalProfitLoss == nil)
    }

    @Test("Losses aggregate signed across included holdings")
    func lossesAggregateSigned() {
        let summary = PortfolioAllTimePLSummary.make(
            holdings: [
                holding(symbol: "AAPL", shares: 10, currentPrice: 200, purchasePrice: 150),
                holding(symbol: "NFLX", shares: 2, currentPrice: 400, purchasePrice: 700)
            ],
            quoteProvenanceBySymbol: [
                "AAPL": .live(provider: "Finnhub", fetchedAt: now),
                "NFLX": .live(provider: "Finnhub", fetchedAt: now)
            ]
        )

        // +500 on AAPL, −600 on NFLX
        #expect(summary.totalProfitLoss == -100)
        #expect(summary.isPositive == false)
        #expect(summary.formattedProfitLoss.hasPrefix("-$"))
    }

    @Test("All-gifted (zero basis) shows P/L but no percent")
    func zeroBasisShowsPLWithoutPercent() {
        let summary = PortfolioAllTimePLSummary.make(
            holdings: [holding(symbol: "AAPL", shares: 10, currentPrice: 200, purchasePrice: 0)],
            quoteProvenanceBySymbol: ["AAPL": .live(provider: "Finnhub", fetchedAt: now)]
        )

        #expect(summary.totalProfitLoss == 2000)
        #expect(summary.profitLossPercent == nil)
        #expect(summary.formattedPercent == nil)
    }

    @Test("Cached quotes qualify and aggregate as cached")
    func cachedQuotesQualify() {
        let summary = PortfolioAllTimePLSummary.make(
            holdings: [
                holding(symbol: "AAPL", shares: 10, currentPrice: 200, purchasePrice: 150),
                holding(symbol: "MSFT", shares: 1, currentPrice: 300, purchasePrice: 250)
            ],
            quoteProvenanceBySymbol: [
                "AAPL": .live(provider: "Finnhub", fetchedAt: now),
                "MSFT": FinancialDataProvenance.cached(provider: "Finnhub", fetchedAt: now.addingTimeInterval(-600))
            ]
        )

        #expect(summary.includedSymbols == ["AAPL", "MSFT"])
        #expect(summary.totalProfitLoss == 550)
        if case .cached = summary.provenance {} else {
            Issue.record("Mixed live+cached should aggregate as cached, got \(summary.provenance)")
        }
    }

    @Test("Empty portfolio reads as add-holdings state")
    func emptyPortfolio() {
        let summary = PortfolioAllTimePLSummary.make(holdings: [], quoteProvenanceBySymbol: [:])

        #expect(summary.ownedHoldingCount == 0)
        #expect(summary.totalProfitLoss == nil)
        #expect(summary.unavailableReason == "Add holdings to track all-time P/L.")
    }

    @Test("All holdings missing cost basis reads as add-cost-basis state")
    func allMissingCostBasis() {
        let summary = PortfolioAllTimePLSummary.make(
            holdings: [
                holding(symbol: "AAPL", shares: 10, currentPrice: 200, purchasePrice: nil),
                holding(symbol: "MSFT", shares: 1, currentPrice: 300, purchasePrice: nil)
            ],
            quoteProvenanceBySymbol: [
                "AAPL": .live(provider: "Finnhub", fetchedAt: now),
                "MSFT": .live(provider: "Finnhub", fetchedAt: now)
            ]
        )

        #expect(summary.totalProfitLoss == nil)
        #expect(summary.unavailableReason == "Add cost basis to your holdings to unlock all-time P/L.")
    }

    @Test("Watchlist-style zero-share stocks are ignored")
    func zeroShareStocksIgnored() {
        let summary = PortfolioAllTimePLSummary.make(
            holdings: [holding(symbol: "AAPL", shares: 0, currentPrice: 200, purchasePrice: 150)],
            quoteProvenanceBySymbol: ["AAPL": .live(provider: "Finnhub", fetchedAt: now)]
        )

        #expect(summary.ownedHoldingCount == 0)
        #expect(summary.totalProfitLoss == nil)
    }

    // MARK: - Helpers

    private func holding(
        symbol: String,
        shares: Double,
        currentPrice: Double,
        purchasePrice: Double?
    ) -> Stock {
        Stock(
            symbol: symbol,
            name: symbol,
            currentPrice: currentPrice,
            priceChange: 0,
            percentageChange: 0,
            sharesOwned: shares,
            purchasePrice: purchasePrice,
            purchaseDate: Date(),
            foundedDate: nil,
            sector: "Unknown"
        )
    }
}

private extension Double {
    func isApproximatelyEqual(to other: Double, tolerance: Double) -> Bool {
        abs(self - other) <= tolerance
    }
}
