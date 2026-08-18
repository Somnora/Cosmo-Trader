import Foundation
import Testing
@testable import Cosmo_Trader

extension AppStatePersistenceSuites {
    // Serialized: AppState persists through the real UserDefaults profile key,
    // so parallel siblings saving their own users can interleave (same reason
    // PortfolioImportCommitTests is serialized).
    @Suite(.serialized)
    struct PortfolioManualEditTests {

        @Test("Manual add stores the chosen share count and cost basis")
        func manualAddStoresSharesAndCostBasis() throws {
            let appState = AppState(user: testUser())
            let stock = try #require(MockStockData.knownStocks.first { $0.symbol == "AAPL" })

            appState.addToPortfolio(stock, shares: 12.5, costBasisPerShare: 150)

            let holding = try #require(appState.currentUser?.portfolio.first)
            #expect(holding.symbol == "AAPL")
            #expect(holding.sharesOwned == 12.5)
            #expect(holding.purchasePrice == 150)
            #expect(appState.lastSaveTimestamp != nil)
        }

        @Test("Manual add without cost basis stays honestly unknown")
        func manualAddWithoutCostBasisStaysNil() throws {
            let appState = AppState(user: testUser())
            let stock = try #require(MockStockData.knownStocks.first { $0.symbol == "AAPL" })

            appState.addToPortfolio(stock, shares: 3)

            let holding = try #require(appState.currentUser?.portfolio.first)
            #expect(holding.sharesOwned == 3)
            #expect(holding.purchasePrice == nil)
        }

        @Test("updateHolding rewrites shares and cost basis and persists")
        func updateHoldingRewritesSharesAndCostBasis() throws {
            let appState = AppState(user: testUser(portfolio: [
                ownedStock(symbol: "TSLA", shares: 4, purchasePrice: 200)
            ]))

            appState.updateHolding(symbol: "TSLA", shares: 10, costBasisPerShare: 180)

            let holding = try #require(appState.currentUser?.portfolio.first)
            #expect(holding.sharesOwned == 10)
            #expect(holding.purchasePrice == 180)
            #expect(appState.lastSaveTimestamp != nil)
        }

        @Test("updateHolding with nil cost basis clears the stored value")
        func updateHoldingClearsCostBasis() throws {
            let appState = AppState(user: testUser(portfolio: [
                ownedStock(symbol: "TSLA", shares: 4, purchasePrice: 200)
            ]))

            appState.updateHolding(symbol: "TSLA", shares: 4, costBasisPerShare: nil)

            let holding = try #require(appState.currentUser?.portfolio.first)
            #expect(holding.purchasePrice == nil)
        }

        @Test("updateHolding on an unknown symbol is a no-op")
        func updateHoldingUnknownSymbolIsNoOp() {
            let appState = AppState(user: testUser(portfolio: [
                ownedStock(symbol: "TSLA", shares: 4)
            ]))

            appState.updateHolding(symbol: "ZZZZ", shares: 10, costBasisPerShare: 1)

            #expect(appState.currentUser?.portfolio.count == 1)
            #expect(appState.currentUser?.portfolio.first?.sharesOwned == 4)
        }

        @Test("removeFromPortfolio deletes the holding and persists")
        func removeFromPortfolioDeletesHolding() {
            let appState = AppState(user: testUser(portfolio: [
                ownedStock(symbol: "TSLA", shares: 4),
                ownedStock(symbol: "AAPL", shares: 2)
            ]))

            appState.removeFromPortfolio(symbol: "TSLA")

            #expect(appState.currentUser?.portfolio.map(\.symbol) == ["AAPL"])
            #expect(appState.ownsStock(symbol: "TSLA") == false)
            #expect(appState.lastSaveTimestamp != nil)
        }

        // MARK: - Helpers (mirrors PortfolioImportCommitTests)

        private func testUser(portfolio: [Stock] = []) -> UserProfile {
            UserProfile(
                displayName: "Manual Edit Tester",
                email: "manual.edit.tester@example.com",
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
}
