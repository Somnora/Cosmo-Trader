//
//  StockTests.swift
//  Cosmo TraderTests
//
//  Comprehensive tests for Stock model including zodiac sign computation,
//  value calculations, and formatting.
//

import Testing
import Foundation
@testable import Cosmo_Trader

// MARK: - Stock Zodiac Sign Tests

struct StockZodiacSignTests {

    @Test("Apple (founded April 1, 1976) is Aries")
    func appleIsAries() {
        let stock = Stock(
            symbol: "AAPL",
            name: "Apple Inc.",
            currentPrice: 178.52,
            priceChange: 2.34,
            percentageChange: 1.33,
            foundedMonth: 4, foundedDay: 1, foundedYear: 1976,
            sector: "Technology"
        )
        #expect(stock.zodiacSign == .aries)
    }

    @Test("Google (founded September 4, 1998) is Virgo")
    func googleIsVirgo() {
        let stock = Stock(
            symbol: "GOOGL",
            name: "Alphabet Inc.",
            currentPrice: 141.80,
            priceChange: -1.20,
            percentageChange: -0.84,
            foundedMonth: 9, foundedDay: 4, foundedYear: 1998,
            sector: "Technology"
        )
        #expect(stock.zodiacSign == .virgo)
    }

    @Test("Tesla (founded July 1, 2003) is Cancer")
    func teslaIsCancer() {
        let stock = Stock(
            symbol: "TSLA",
            name: "Tesla Inc.",
            currentPrice: 248.50,
            priceChange: 12.30,
            percentageChange: 5.21,
            foundedMonth: 7, foundedDay: 1, foundedYear: 2003,
            sector: "Automotive"
        )
        #expect(stock.zodiacSign == .cancer)
    }

    @Test("NVIDIA (founded January 25, 1993) is Aquarius")
    func nvidiaIsAquarius() {
        let stock = Stock(
            symbol: "NVDA",
            name: "NVIDIA Corp.",
            currentPrice: 467.80,
            priceChange: 15.20,
            percentageChange: 3.36,
            foundedMonth: 1, foundedDay: 25, foundedYear: 1993,
            sector: "Technology"
        )
        #expect(stock.zodiacSign == .aquarius)
    }

    @Test("Stock element is derived from zodiac sign")
    func stockElementFromZodiac() {
        let stock = Stock(
            symbol: "AAPL",
            name: "Apple Inc.",
            currentPrice: 178.52,
            priceChange: 2.34,
            percentageChange: 1.33,
            foundedMonth: 4, foundedDay: 1, foundedYear: 1976,
            sector: "Technology"
        )
        #expect(stock.element == .fire) // Aries is fire
    }
}

// MARK: - Stock Value Calculation Tests

struct StockValueCalculationTests {

    @Test("Total value calculation with shares")
    func totalValueWithShares() {
        let stock = Stock(
            symbol: "AAPL",
            name: "Apple Inc.",
            currentPrice: 100.00,
            priceChange: 2.00,
            percentageChange: 2.0,
            sharesOwned: 10,
            foundedMonth: 4, foundedDay: 1, foundedYear: 1976,
            sector: "Technology"
        )
        #expect(stock.totalValue == 1000.00)
    }

    @Test("Total value is zero when no shares owned")
    func totalValueZeroNoShares() {
        let stock = Stock(
            symbol: "AAPL",
            name: "Apple Inc.",
            currentPrice: 100.00,
            priceChange: 2.00,
            percentageChange: 2.0,
            sharesOwned: 0,
            foundedMonth: 4, foundedDay: 1, foundedYear: 1976,
            sector: "Technology"
        )
        #expect(stock.totalValue == 0)
    }

    @Test("Total value with fractional shares")
    func totalValueFractionalShares() {
        let stock = Stock(
            symbol: "AAPL",
            name: "Apple Inc.",
            currentPrice: 100.00,
            priceChange: 2.00,
            percentageChange: 2.0,
            sharesOwned: 2.5,
            foundedMonth: 4, foundedDay: 1, foundedYear: 1976,
            sector: "Technology"
        )
        #expect(stock.totalValue == 250.00)
    }

    @Test("Today's profit/loss calculation - positive")
    func todaysProfitLossPositive() {
        let stock = Stock(
            symbol: "AAPL",
            name: "Apple Inc.",
            currentPrice: 102.00,
            priceChange: 2.00,
            percentageChange: 2.0,
            sharesOwned: 10,
            foundedMonth: 4, foundedDay: 1, foundedYear: 1976,
            sector: "Technology"
        )
        #expect(stock.todaysProfitLoss == 20.00)
    }

    @Test("Today's profit/loss calculation - negative")
    func todaysProfitLossNegative() {
        let stock = Stock(
            symbol: "AAPL",
            name: "Apple Inc.",
            currentPrice: 98.00,
            priceChange: -2.00,
            percentageChange: -2.0,
            sharesOwned: 10,
            foundedMonth: 4, foundedDay: 1, foundedYear: 1976,
            sector: "Technology"
        )
        #expect(stock.todaysProfitLoss == -20.00)
    }

    @Test("Cost basis calculation")
    func costBasisCalculation() {
        let stock = Stock(
            symbol: "AAPL",
            name: "Apple Inc.",
            currentPrice: 110.00,
            priceChange: 2.00,
            percentageChange: 2.0,
            sharesOwned: 10,
            purchasePrice: 100.00,
            foundedMonth: 4, foundedDay: 1, foundedYear: 1976,
            sector: "Technology"
        )
        #expect(stock.totalCostBasis == 1000.00)
    }

    @Test("Total profit/loss since purchase")
    func totalProfitLossSincePurchase() {
        let stock = Stock(
            symbol: "AAPL",
            name: "Apple Inc.",
            currentPrice: 110.00,
            priceChange: 2.00,
            percentageChange: 2.0,
            sharesOwned: 10,
            purchasePrice: 100.00,
            foundedMonth: 4, foundedDay: 1, foundedYear: 1976,
            sector: "Technology"
        )
        #expect(stock.totalProfitLoss == 100.00)
    }

    @Test("Profit/loss percentage calculation")
    func profitLossPercentage() {
        let stock = Stock(
            symbol: "AAPL",
            name: "Apple Inc.",
            currentPrice: 110.00,
            priceChange: 2.00,
            percentageChange: 2.0,
            sharesOwned: 10,
            purchasePrice: 100.00,
            foundedMonth: 4, foundedDay: 1, foundedYear: 1976,
            sector: "Technology"
        )
        #expect(stock.totalProfitLossPercent == 10.0)
    }
}

// MARK: - Stock Formatting Tests

struct StockFormattingTests {

    @Test("Formatted price includes currency symbol")
    func formattedPriceHasCurrency() {
        let stock = Stock(
            symbol: "AAPL",
            name: "Apple Inc.",
            currentPrice: 178.52,
            priceChange: 2.34,
            percentageChange: 1.33,
            foundedMonth: 4, foundedDay: 1, foundedYear: 1976,
            sector: "Technology"
        )
        #expect(stock.formattedPrice.contains("$"))
        #expect(stock.formattedPrice.contains("178"))
    }

    @Test("Formatted price change shows positive sign")
    func formattedPriceChangePositive() {
        let stock = Stock(
            symbol: "AAPL",
            name: "Apple Inc.",
            currentPrice: 178.52,
            priceChange: 2.34,
            percentageChange: 1.33,
            foundedMonth: 4, foundedDay: 1, foundedYear: 1976,
            sector: "Technology"
        )
        #expect(stock.formattedPriceChange.hasPrefix("+"))
    }

    @Test("Formatted price change shows negative without extra sign")
    func formattedPriceChangeNegative() {
        let stock = Stock(
            symbol: "AAPL",
            name: "Apple Inc.",
            currentPrice: 178.52,
            priceChange: -2.34,
            percentageChange: -1.33,
            foundedMonth: 4, foundedDay: 1, foundedYear: 1976,
            sector: "Technology"
        )
        // Should not have double negative
        #expect(!stock.formattedPriceChange.contains("--"))
    }

    @Test("Formatted percentage change includes percent sign")
    func formattedPercentageHasPercent() {
        let stock = Stock(
            symbol: "AAPL",
            name: "Apple Inc.",
            currentPrice: 178.52,
            priceChange: 2.34,
            percentageChange: 1.33,
            foundedMonth: 4, foundedDay: 1, foundedYear: 1976,
            sector: "Technology"
        )
        #expect(stock.formattedPercentageChange.contains("%"))
    }

    @Test("Formatted shares - whole number shows no decimals")
    func formattedSharesWholeNumber() {
        var stock = Stock(
            symbol: "AAPL",
            name: "Apple Inc.",
            currentPrice: 178.52,
            priceChange: 2.34,
            percentageChange: 1.33,
            foundedMonth: 4, foundedDay: 1, foundedYear: 1976,
            sector: "Technology"
        )
        stock.sharesOwned = 10
        #expect(stock.formattedSharesOwned == "10")
    }

    @Test("Formatted shares - fractional shows decimals")
    func formattedSharesFractional() {
        var stock = Stock(
            symbol: "AAPL",
            name: "Apple Inc.",
            currentPrice: 178.52,
            priceChange: 2.34,
            percentageChange: 1.33,
            foundedMonth: 4, foundedDay: 1, foundedYear: 1976,
            sector: "Technology"
        )
        stock.sharesOwned = 10.5
        #expect(stock.formattedSharesOwned.contains(".5"))
    }
}

// MARK: - Stock isPositive Tests

struct StockIsPositiveTests {

    @Test("isPositive true for positive price change")
    func isPositiveTrueForPositive() {
        let stock = Stock(
            symbol: "AAPL",
            name: "Apple Inc.",
            currentPrice: 178.52,
            priceChange: 2.34,
            percentageChange: 1.33,
            foundedMonth: 4, foundedDay: 1, foundedYear: 1976,
            sector: "Technology"
        )
        #expect(stock.isPositive == true)
    }

    @Test("isPositive false for negative price change")
    func isPositiveFalseForNegative() {
        let stock = Stock(
            symbol: "AAPL",
            name: "Apple Inc.",
            currentPrice: 178.52,
            priceChange: -2.34,
            percentageChange: -1.33,
            foundedMonth: 4, foundedDay: 1, foundedYear: 1976,
            sector: "Technology"
        )
        #expect(stock.isPositive == false)
    }

    @Test("isPositive true for zero price change")
    func isPositiveTrueForZero() {
        let stock = Stock(
            symbol: "AAPL",
            name: "Apple Inc.",
            currentPrice: 178.52,
            priceChange: 0,
            percentageChange: 0,
            foundedMonth: 4, foundedDay: 1, foundedYear: 1976,
            sector: "Technology"
        )
        #expect(stock.isPositive == true)
    }
}

// MARK: - Stock Ownership Tests

struct StockOwnershipTests {

    @Test("isOwned true when shares > 0")
    func isOwnedTrueWithShares() {
        let stock = Stock(
            symbol: "AAPL",
            name: "Apple Inc.",
            currentPrice: 178.52,
            priceChange: 2.34,
            percentageChange: 1.33,
            sharesOwned: 10,
            foundedMonth: 4, foundedDay: 1, foundedYear: 1976,
            sector: "Technology"
        )
        #expect(stock.isOwned == true)
    }

    @Test("isOwned false when shares = 0")
    func isOwnedFalseWithoutShares() {
        let stock = Stock(
            symbol: "AAPL",
            name: "Apple Inc.",
            currentPrice: 178.52,
            priceChange: 2.34,
            percentageChange: 1.33,
            sharesOwned: 0,
            foundedMonth: 4, foundedDay: 1, foundedYear: 1976,
            sector: "Technology"
        )
        #expect(stock.isOwned == false)
    }

    @Test("isProfitable true when profit")
    func isProfitableTrue() {
        let stock = Stock(
            symbol: "AAPL",
            name: "Apple Inc.",
            currentPrice: 110.00,
            priceChange: 2.00,
            percentageChange: 2.0,
            sharesOwned: 10,
            purchasePrice: 100.00,
            foundedMonth: 4, foundedDay: 1, foundedYear: 1976,
            sector: "Technology"
        )
        #expect(stock.isProfitable == true)
    }

    @Test("isProfitable false when loss")
    func isProfitableFalse() {
        let stock = Stock(
            symbol: "AAPL",
            name: "Apple Inc.",
            currentPrice: 90.00,
            priceChange: -2.00,
            percentageChange: -2.0,
            sharesOwned: 10,
            purchasePrice: 100.00,
            foundedMonth: 4, foundedDay: 1, foundedYear: 1976,
            sector: "Technology"
        )
        #expect(stock.isProfitable == false)
    }
}

// MARK: - Stock Compatibility Tests

struct StockCompatibilityMethodTests {

    @Test("Stock compatibility with user sign")
    func stockCompatibilityWithUserSign() {
        // Apple is Aries (fire), Leo is fire - should be compatible
        let stock = Stock(
            symbol: "AAPL",
            name: "Apple Inc.",
            currentPrice: 178.52,
            priceChange: 2.34,
            percentageChange: 1.33,
            foundedMonth: 4, foundedDay: 1, foundedYear: 1976,
            sector: "Technology"
        )
        #expect(stock.isCompatible(with: .leo) == true)
    }

    @Test("Stock shares element with user sign")
    func stockSharesElement() {
        // Apple is Aries (fire), Leo is fire - same element
        let stock = Stock(
            symbol: "AAPL",
            name: "Apple Inc.",
            currentPrice: 178.52,
            priceChange: 2.34,
            percentageChange: 1.33,
            foundedMonth: 4, foundedDay: 1, foundedYear: 1976,
            sector: "Technology"
        )
        #expect(stock.sharesElement(with: .leo) == true)
        #expect(stock.sharesElement(with: .cancer) == false) // Cancer is water
    }
}

// MARK: - Stock Sample Data Tests

struct StockSampleDataTests {

    @Test("Sample stocks array is not empty")
    func samplesNotEmpty() {
        #expect(!Stock.samples.isEmpty)
    }

    @Test("Single sample exists")
    func singleSampleExists() {
        let sample = Stock.sample
        #expect(!sample.symbol.isEmpty)
    }

    @Test("Owned samples filter works")
    func ownedSamplesFilter() {
        let owned = Stock.ownedSamples
        for stock in owned {
            #expect(stock.sharesOwned > 0)
        }
    }

    @Test("Watchlist samples filter works")
    func watchlistSamplesFilter() {
        let watchlist = Stock.watchlistSamples
        for stock in watchlist {
            #expect(stock.sharesOwned == 0)
        }
    }
}
