import Foundation
import Testing
@testable import Cosmo_Trader

struct CloudProfileMergeTests {

    @Test("Empty cloud portfolio never deletes local holdings")
    func emptyCloudNeverDeletesLocalHoldings() {
        let local = [stock("AAPL", shares: 10)]

        let merged = CloudProfileMerge.merge(
            localPortfolio: local,
            localWatchlist: ["TSLA"],
            cloudPortfolio: [],
            cloudWatchlist: []
        )

        #expect(merged.portfolio.map(\.symbol) == ["AAPL"])
        #expect(merged.watchlist == ["TSLA"])
    }

    @Test("Nil cloud fields keep local data")
    func nilCloudKeepsLocal() {
        let merged = CloudProfileMerge.merge(
            localPortfolio: [stock("AAPL", shares: 10)],
            localWatchlist: ["TSLA"],
            cloudPortfolio: nil,
            cloudWatchlist: nil
        )

        #expect(merged.portfolio.map(\.symbol) == ["AAPL"])
        #expect(merged.watchlist == ["TSLA"])
    }

    @Test("Stale cloud copy never overwrites non-empty local holdings")
    func staleCloudNeverOverwritesLocal() {
        let merged = CloudProfileMerge.merge(
            localPortfolio: [stock("AAPL", shares: 25)],
            localWatchlist: ["NVDA"],
            cloudPortfolio: [stock("AAPL", shares: 1), stock("MSFT", shares: 3)],
            cloudWatchlist: ["GME"]
        )

        #expect(merged.portfolio.map(\.symbol) == ["AAPL"])
        #expect(merged.portfolio.first?.sharesOwned == 25)
        #expect(merged.watchlist == ["NVDA"])
    }

    @Test("Fresh device restore adopts the cloud copy")
    func freshDeviceRestoreAdoptsCloud() {
        let merged = CloudProfileMerge.merge(
            localPortfolio: [],
            localWatchlist: [],
            cloudPortfolio: [stock("MSFT", shares: 3)],
            cloudWatchlist: ["AAPL"]
        )

        #expect(merged.portfolio.map(\.symbol) == ["MSFT"])
        #expect(merged.watchlist == ["AAPL"])
    }

    @Test("Portfolio and watchlist merge independently")
    func fieldsMergeIndependently() {
        let merged = CloudProfileMerge.merge(
            localPortfolio: [stock("AAPL", shares: 10)],
            localWatchlist: [],
            cloudPortfolio: [],
            cloudWatchlist: ["NVDA"]
        )

        #expect(merged.portfolio.map(\.symbol) == ["AAPL"])
        #expect(merged.watchlist == ["NVDA"])
    }

    private func stock(_ symbol: String, shares: Double) -> Stock {
        Stock(
            symbol: symbol,
            name: symbol,
            currentPrice: 100,
            priceChange: 0,
            percentageChange: 0,
            sharesOwned: shares,
            purchasePrice: nil,
            purchaseDate: nil,
            foundedDate: nil,
            sector: "Unknown"
        )
    }
}
