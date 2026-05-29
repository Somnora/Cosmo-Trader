import Foundation
import Testing
@testable import Cosmo_Trader

@MainActor
struct PortfolioWeightingTests {

    @Test("Portfolio composition is weighted by market value instead of share count")
    func valueWeightedCompositionBeatsShareCount() {
        let fire = stock(
            symbol: "FIRE",
            currentPrice: 2,
            sharesOwned: 100,
            foundedDate: date(month: 4, day: 1, year: 2000)
        )
        let earth = stock(
            symbol: "EARTH",
            currentPrice: 200,
            sharesOwned: 1,
            foundedDate: date(month: 5, day: 1, year: 2000)
        )

        let result = PortfolioCompatibilityService.calculateWeightedCompatibility(
            portfolio: [fire, earth],
            userSign: .leo
        )

        #expect(isClose(result.totalMarketValue, 400))
        #expect(isClose(result.elementBreakdown[.fire, default: 0], 50))
        #expect(isClose(result.elementBreakdown[.earth, default: 0], 50))
        #expect(!isClose(result.elementBreakdown[.fire, default: 0], 99.0099, tolerance: 0.01))
    }

    @Test("Unknown-founded holdings stay excluded from composition denominator")
    func unknownFoundedHoldingsRemainExcluded() {
        let verified = stock(
            symbol: "KNOWN",
            currentPrice: 10,
            sharesOwned: 10,
            foundedDate: date(month: 4, day: 1, year: 2000)
        )
        let unknown = stock(
            symbol: "UNKNOWN",
            currentPrice: 1000,
            sharesOwned: 100,
            foundedDate: nil
        )

        let result = PortfolioCompatibilityService.calculateWeightedCompatibility(
            portfolio: [verified, unknown],
            userSign: .leo
        )

        #expect(isClose(result.totalMarketValue, 100))
        #expect(isClose(result.elementBreakdown[.fire, default: 0], 100))
        #expect(result.elementBreakdown[.earth, default: 0] == 0)
        #expect(result.signBreakdown.count == 1)
    }

    @Test("Zero current price uses purchase price as composition fallback")
    func zeroCurrentPriceUsesPurchasePriceFallback() {
        let fire = stock(
            symbol: "COST",
            currentPrice: 0,
            sharesOwned: 100,
            purchasePrice: 2,
            foundedDate: date(month: 4, day: 1, year: 2000)
        )
        let earth = stock(
            symbol: "LIVE",
            currentPrice: 200,
            sharesOwned: 1,
            foundedDate: date(month: 5, day: 1, year: 2000)
        )

        let result = PortfolioCompatibilityService.calculateWeightedCompatibility(
            portfolio: [fire, earth],
            userSign: .leo
        )

        #expect(isClose(fire.marketValue, 200))
        #expect(isClose(result.totalMarketValue, 400))
        #expect(isClose(result.elementBreakdown[.fire, default: 0], 50))
        #expect(isClose(result.elementBreakdown[.earth, default: 0], 50))
    }

    @Test("All zero-price holdings produce empty composition state")
    func allZeroPriceHoldingsProduceEmptyComposition() {
        let fire = stock(
            symbol: "ZERO1",
            currentPrice: 0,
            sharesOwned: 100,
            purchasePrice: 0,
            foundedDate: date(month: 4, day: 1, year: 2000)
        )
        let earth = stock(
            symbol: "ZERO2",
            currentPrice: 0,
            sharesOwned: 1,
            purchasePrice: nil,
            foundedDate: date(month: 5, day: 1, year: 2000)
        )

        let result = PortfolioCompatibilityService.calculateWeightedCompatibility(
            portfolio: [fire, earth],
            userSign: .leo
        )

        #expect(result.totalMarketValue == 0)
        #expect(result.overallScore == 0)
        #expect(result.elementBreakdown.isEmpty)
        #expect(result.signBreakdown.isEmpty)
        #expect(result.cosmicInsight == "Add holdings with verified founding dates to generate a portfolio-specific market astrology read.")
    }

    private func stock(
        symbol: String,
        currentPrice: Double,
        sharesOwned: Double,
        purchasePrice: Double? = nil,
        foundedDate: Date?
    ) -> Stock {
        Stock(
            symbol: symbol,
            name: "\(symbol) Corp.",
            currentPrice: currentPrice,
            priceChange: 0,
            percentageChange: 0,
            sharesOwned: sharesOwned,
            purchasePrice: purchasePrice,
            foundedDate: foundedDate,
            sector: "Test"
        )
    }

    private func date(month: Int, day: Int, year: Int) -> Date {
        Calendar(identifier: .gregorian).date(from: DateComponents(year: year, month: month, day: day))
            ?? Date(timeIntervalSince1970: 0)
    }

    private func isClose(_ actual: Double, _ expected: Double, tolerance: Double = 0.0001) -> Bool {
        abs(actual - expected) <= tolerance
    }
}
