import Foundation
import Testing
@testable import Cosmo_Trader

extension AppStatePersistenceSuites {
    // Serialized: these tests share the real UserDefaults profile key through
    // AppState persistence, and `relaunchLoadRestoresImportedHoldings` reads it
    // back to simulate a relaunch. Parallel siblings saving their own users
    // between its commit and reload made it flaky.
    @Suite(.serialized)
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

        @Test("Import success routes to Portfolio with confirmation")
        func importSuccessRoutesToPortfolioWithConfirmation() throws {
            let appState = AppState(user: testUser(portfolio: [
                ownedStock(symbol: "AAPL", shares: 1, currentPrice: 150, purchasePrice: 100)
            ]))
            appState.selectedTab = .today

            PortfolioImportService.commitPortfolio(
                with: [
                    ParsedHolding(
                        symbol: "MSFT",
                        shares: 2,
                        marketValue: nil,
                        costBasisPerShare: 250,
                        confidence: 1,
                        rawSource: "MSFT,2"
                    )
                ],
                in: appState,
                mode: .append
            )

            let feedback = try #require(appState.portfolioImportFeedback)
            #expect(appState.selectedTab == .portfolio)
            #expect(feedback.mode == .append)
            #expect(feedback.importedCount == 1)
            #expect(feedback.totalHoldings == 2)
            #expect(feedback.detail.contains("weighted cost basis"))
        }

        @Test("Relaunch load restores imported holdings")
        func relaunchLoadRestoresImportedHoldings() throws {
            AppState(user: nil).deleteAllUserData()
            defer { AppState(user: nil).deleteAllUserData() }

            let appState = AppState(user: testUser())

            PortfolioImportService.commitPortfolio(
                with: [
                    ParsedHolding(
                        symbol: "AAPL",
                        shares: 2,
                        marketValue: nil,
                        costBasisPerShare: 150,
                        confidence: 1,
                        rawSource: "AAPL,2"
                    ),
                    ParsedHolding(
                        symbol: "ZZZZ",
                        shares: 3,
                        marketValue: nil,
                        costBasisPerShare: 12,
                        confidence: 0.5,
                        rawSource: "ZZZZ,3"
                    )
                ],
                in: appState,
                mode: .replace
            )

            let reloaded = AppState()
            let portfolio = try #require(reloaded.currentUser?.portfolio)
            #expect(portfolio.map(\.symbol) == ["AAPL", "ZZZZ"])
            #expect(portfolio.first { $0.symbol == "AAPL" }?.sharesOwned == 2)
            #expect(portfolio.first { $0.symbol == "AAPL" }?.currentPrice == 0)
            #expect(portfolio.first { $0.symbol == "ZZZZ" }?.foundedDate == nil)
            #expect(reloaded.lastSaveTimestamp != nil)
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

        @Test("Screenshot parser holdings append through hardened commit flow")
        func screenshotParserHoldingsAppendThroughHardenedCommitFlow() throws {
            let parser = SchwabMobileParser()
            let parsed = try parser.parse([
                "Schwab",
                "Positions",
                "Symbol Qty Last Mkt Value",
                "AAPL",
                "2 $200.00 $400.00",
                "MSFT",
                "3 $300.00 $900.00"
            ])
            let appState = AppState(user: testUser(portfolio: [
                ownedStock(symbol: "AAPL", shares: 1, currentPrice: 150, purchasePrice: 100)
            ]))

            PortfolioImportService.commitPortfolio(
                with: parsed.holdings,
                in: appState,
                mode: .append
            )

            let portfolio = appState.currentUser?.portfolio ?? []
            let aapl = try #require(portfolio.first { $0.symbol == "AAPL" })
            let msft = try #require(portfolio.first { $0.symbol == "MSFT" })

            #expect(portfolio.count == 2)
            #expect(aapl.sharesOwned == 3)
            #expect(aapl.currentPrice == 200)
            #expect(aapl.purchasePrice == 100)
            #expect(msft.sharesOwned == 3)
            #expect(msft.currentPrice == 300)
            #expect(appState.lastSaveTimestamp != nil)
        }

        @Test("Screenshot parser unknown ticker survives replace without sample price or astrology")
        func screenshotParserUnknownTickerSurvivesReplaceWithoutSamplePriceOrAstrology() throws {
            let parser = SchwabMobileParser()
            let parsed = try parser.parse([
                "Schwab",
                "Positions",
                "Symbol Qty Last Mkt Value",
                "ZZZZ",
                "12 $10.00 $120.00"
            ])
            let appState = AppState(user: testUser(portfolio: [
                ownedStock(symbol: "TSLA", shares: 4)
            ]))

            PortfolioImportService.commitPortfolio(
                with: parsed.holdings,
                in: appState,
                mode: .replace
            )

            let holding = try #require(appState.currentUser?.portfolio.first)
            #expect(appState.currentUser?.portfolio.count == 1)
            #expect(holding.symbol == "ZZZZ")
            #expect(holding.currentPrice == 10)
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
}
