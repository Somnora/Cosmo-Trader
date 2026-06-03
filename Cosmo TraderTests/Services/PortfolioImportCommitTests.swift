import Foundation
import Testing
@testable import Cosmo_Trader

struct PortfolioImportCommitTests {

    @Test("Replace import commits reviewed holdings and persists")
    func replaceImportCommitsReviewedHoldingsAndPersists() {
        let appState = AppState(user: testUser(portfolio: [ownedStock(symbol: "TSLA", shares: 4)]))

        PortfolioImportService.commitPortfolio(
            with: [
                ParsedHolding(
                    symbol: "AAPL",
                    shares: 2,
                    marketValue: 400,
                    costBasisPerShare: 150,
                    confidence: 1,
                    rawSource: "AAPL,2,$400,$300"
                )
            ],
            in: appState,
            mode: .replace
        )

        let portfolio = appState.currentUser?.portfolio ?? []
        #expect(portfolio.map(\.symbol) == ["AAPL"])
        #expect(portfolio.first?.sharesOwned == 2)
        #expect(portfolio.first?.currentPrice == 200)
        #expect(portfolio.first?.purchasePrice == 150)
        #expect(appState.lastSaveTimestamp != nil)
    }

    @Test("Append import combines duplicate symbols with weighted cost basis")
    func appendImportCombinesDuplicateSymbolsWithWeightedCostBasis() throws {
        let existing = ownedStock(
            symbol: "AAPL",
            shares: 1,
            currentPrice: 180,
            purchasePrice: 100
        )
        let appState = AppState(user: testUser(portfolio: [existing]))

        PortfolioImportService.commitPortfolio(
            with: [
                ParsedHolding(
                    symbol: "AAPL",
                    shares: 3,
                    marketValue: 600,
                    costBasisPerShare: 200,
                    confidence: 1,
                    rawSource: "AAPL,3,$600,$600"
                )
            ],
            in: appState,
            mode: .append
        )

        let holding = try #require(appState.currentUser?.portfolio.first)
        #expect(appState.currentUser?.portfolio.count == 1)
        #expect(holding.symbol == "AAPL")
        #expect(holding.sharesOwned == 4)
        #expect(holding.currentPrice == 200)
        #expect(holding.purchasePrice == 175)
    }

    @Test("Known imported stock without quote or market value does not inherit sample price")
    func knownImportedStockWithoutQuoteOrMarketValueDoesNotInheritSamplePrice() throws {
        let appState = AppState(user: testUser())

        PortfolioImportService.commitPortfolio(
            with: [
                ParsedHolding(
                    symbol: "AAPL",
                    shares: 5,
                    marketValue: nil,
                    costBasisPerShare: 123,
                    confidence: 0.8,
                    rawSource: "AAPL,5"
                )
            ],
            in: appState,
            mode: .replace
        )

        let holding = try #require(appState.currentUser?.portfolio.first)
        #expect(holding.symbol == "AAPL")
        #expect(holding.currentPrice == 0)
        #expect(holding.purchasePrice == 123)
        #expect(holding.foundedDate != nil)
    }

    @Test("Unknown imported stock preserves holding without fabricated astrology")
    func unknownImportedStockPreservesHoldingWithoutFabricatedAstrology() throws {
        let appState = AppState(user: testUser())

        PortfolioImportService.commitPortfolio(
            with: [
                ParsedHolding(
                    symbol: "ZZZZ",
                    shares: 7,
                    marketValue: nil,
                    costBasisPerShare: 10,
                    confidence: 0.5,
                    rawSource: "ZZZZ,7"
                )
            ],
            in: appState,
            mode: .replace
        )

        let holding = try #require(appState.currentUser?.portfolio.first)
        #expect(holding.symbol == "ZZZZ")
        #expect(holding.name == "ZZZZ")
        #expect(holding.currentPrice == 0)
        #expect(holding.purchasePrice == 10)
        #expect(holding.foundedDate == nil)
        #expect(holding.zodiacSign == nil)
        #expect(holding.foundedElement == nil)
    }

    private func testUser(portfolio: [Stock] = []) -> UserProfile {
        UserProfile(
            displayName: "Import Tester",
            email: "import.tester@example.com",
            birthMonth: 4,
            birthDay: 10,
            birthYear: 1990,
            portfolio: portfolio
        )
    }

    private func ownedStock(
        symbol: String,
        shares: Double,
        currentPrice: Double = 100,
        purchasePrice: Double? = nil
    ) -> Stock {
        var stock = MockStockData.knownStocks.first { $0.symbol == symbol } ?? Stock(
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

        stock.currentPrice = currentPrice
        stock.priceChange = 0
        stock.percentageChange = 0
        stock.sharesOwned = shares
        stock.purchasePrice = purchasePrice
        stock.purchaseDate = Date()
        return stock
    }
}
