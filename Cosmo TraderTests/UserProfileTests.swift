//
//  UserProfileTests.swift
//  Cosmo TraderTests
//
//  Comprehensive tests for UserProfile model including sun sign computation,
//  portfolio management, and watchlist operations.
//

import Testing
import Foundation
@testable import Cosmo_Trader

// MARK: - UserProfile Sun Sign Tests

struct UserProfileSunSignTests {

    @Test("Sun sign computed from birth date - Leo")
    func sunSignLeo() {
        let profile = UserProfile(
            displayName: "Test User",
            email: "test@example.com",
            birthMonth: 8,
            birthDay: 15,
            birthYear: 1990
        )
        #expect(profile.sunSign == .leo)
    }

    @Test("Sun sign computed from birth date - Aquarius")
    func sunSignAquarius() {
        let profile = UserProfile(
            displayName: "Test User",
            email: "test@example.com",
            birthMonth: 1,
            birthDay: 25,
            birthYear: 1985
        )
        #expect(profile.sunSign == .aquarius)
    }

    @Test("Sun sign computed from birth date - Capricorn (December)")
    func sunSignCapricornDecember() {
        let profile = UserProfile(
            displayName: "Test User",
            email: "test@example.com",
            birthMonth: 12,
            birthDay: 25,
            birthYear: 1990
        )
        #expect(profile.sunSign == .capricorn)
    }

    @Test("Sun sign computed from birth date - Capricorn (January)")
    func sunSignCapricornJanuary() {
        let profile = UserProfile(
            displayName: "Test User",
            email: "test@example.com",
            birthMonth: 1,
            birthDay: 5,
            birthYear: 1990
        )
        #expect(profile.sunSign == .capricorn)
    }

    @Test("Element derived from sun sign")
    func elementFromSunSign() {
        let profile = UserProfile(
            displayName: "Test User",
            email: "test@example.com",
            birthMonth: 8,
            birthDay: 15,
            birthYear: 1990
        )
        #expect(profile.element == .fire) // Leo is fire
    }
}

// MARK: - Portfolio Management Tests

struct UserProfilePortfolioTests {

    @Test("Add stock to empty portfolio")
    func addStockToEmptyPortfolio() {
        var profile = UserProfile(
            displayName: "Test User",
            email: "test@example.com",
            birthMonth: 8,
            birthDay: 15,
            birthYear: 1990
        )

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

        profile.addStock(stock)

        #expect(profile.portfolio.count == 1)
        #expect(profile.portfolio[0].symbol == "AAPL")
    }

    @Test("Add duplicate stock increases shares")
    func addDuplicateStockIncreasesShares() {
        var profile = UserProfile(
            displayName: "Test User",
            email: "test@example.com",
            birthMonth: 8,
            birthDay: 15,
            birthYear: 1990
        )

        let stock1 = Stock(
            symbol: "AAPL",
            name: "Apple Inc.",
            currentPrice: 178.52,
            priceChange: 2.34,
            percentageChange: 1.33,
            sharesOwned: 10,
            foundedMonth: 4, foundedDay: 1, foundedYear: 1976,
            sector: "Technology"
        )

        let stock2 = Stock(
            symbol: "AAPL",
            name: "Apple Inc.",
            currentPrice: 180.00,
            priceChange: 3.00,
            percentageChange: 1.5,
            sharesOwned: 5,
            foundedMonth: 4, foundedDay: 1, foundedYear: 1976,
            sector: "Technology"
        )

        profile.addStock(stock1)
        profile.addStock(stock2)

        #expect(profile.portfolio.count == 1)
        #expect(profile.portfolio[0].sharesOwned == 15)
    }

    @Test("Remove stock from portfolio")
    func removeStockFromPortfolio() {
        var profile = UserProfile(
            displayName: "Test User",
            email: "test@example.com",
            birthMonth: 8,
            birthDay: 15,
            birthYear: 1990,
            portfolio: Stock.ownedSamples
        )

        let initialCount = profile.portfolio.count
        profile.removeStock(symbol: "AAPL")

        #expect(profile.portfolio.count == initialCount - 1)
        #expect(!profile.portfolio.contains { $0.symbol == "AAPL" })
    }

    @Test("Remove non-existent stock does nothing")
    func removeNonExistentStock() {
        var profile = UserProfile(
            displayName: "Test User",
            email: "test@example.com",
            birthMonth: 8,
            birthDay: 15,
            birthYear: 1990,
            portfolio: Stock.ownedSamples
        )

        let initialCount = profile.portfolio.count
        profile.removeStock(symbol: "NONEXISTENT")

        #expect(profile.portfolio.count == initialCount)
    }

    @Test("Update shares for existing stock")
    func updateSharesForExistingStock() {
        var profile = UserProfile(
            displayName: "Test User",
            email: "test@example.com",
            birthMonth: 8,
            birthDay: 15,
            birthYear: 1990,
            portfolio: Stock.ownedSamples
        )

        profile.updateShares(symbol: "AAPL", newAmount: 100)

        let appleStock = profile.portfolio.first { $0.symbol == "AAPL" }
        #expect(appleStock?.sharesOwned == 100)
    }
}

// MARK: - Portfolio Value Tests

struct UserProfileValueTests {

    @Test("Total portfolio value calculation")
    func totalPortfolioValue() {
        let profile = UserProfile.sample
        let manualTotal = profile.portfolio.reduce(0) { $0 + $1.totalValue }

        #expect(profile.totalPortfolioValue == manualTotal)
    }

    @Test("Empty portfolio has zero value")
    func emptyPortfolioZeroValue() {
        let profile = UserProfile(
            displayName: "Test User",
            email: "test@example.com",
            birthMonth: 8,
            birthDay: 15,
            birthYear: 1990,
            portfolio: []
        )

        #expect(profile.totalPortfolioValue == 0)
    }

    @Test("Total daily change calculation")
    func totalDailyChange() {
        let profile = UserProfile.sample
        let manualChange = profile.portfolio.reduce(0) { $0 + $1.todaysProfitLoss }

        #expect(profile.totalDailyChange == manualChange)
    }

    @Test("Number of holdings count")
    func numberOfHoldings() {
        let profile = UserProfile.sample
        let ownedCount = profile.portfolio.filter { $0.sharesOwned > 0 }.count

        #expect(profile.numberOfHoldings == ownedCount)
    }

    @Test("isPortfolioPositive reflects daily change")
    func isPortfolioPositiveReflectsDailyChange() {
        let profile = UserProfile.sample
        #expect(profile.isPortfolioPositive == (profile.totalDailyChange >= 0))
    }
}

// MARK: - Watchlist Management Tests

struct UserProfileWatchlistTests {

    @Test("Add to watchlist")
    func addToWatchlist() {
        var profile = UserProfile(
            displayName: "Test User",
            email: "test@example.com",
            birthMonth: 8,
            birthDay: 15,
            birthYear: 1990
        )

        profile.addToWatchlist("AAPL")

        #expect(profile.watchlist.contains("AAPL"))
        #expect(profile.isInWatchlist("AAPL"))
    }

    @Test("Adding duplicate to watchlist does nothing")
    func addDuplicateToWatchlist() {
        var profile = UserProfile(
            displayName: "Test User",
            email: "test@example.com",
            birthMonth: 8,
            birthDay: 15,
            birthYear: 1990
        )

        profile.addToWatchlist("AAPL")
        profile.addToWatchlist("AAPL")

        #expect(profile.watchlist.filter { $0 == "AAPL" }.count == 1)
    }

    @Test("Remove from watchlist")
    func removeFromWatchlist() {
        var profile = UserProfile(
            displayName: "Test User",
            email: "test@example.com",
            birthMonth: 8,
            birthDay: 15,
            birthYear: 1990,
            watchlist: ["AAPL", "GOOGL", "TSLA"]
        )

        profile.removeFromWatchlist("GOOGL")

        #expect(!profile.watchlist.contains("GOOGL"))
        #expect(profile.watchlist.contains("AAPL"))
        #expect(profile.watchlist.contains("TSLA"))
    }

    @Test("Skip stock adds to skipped list")
    func skipStockAddsToSkippedList() {
        var profile = UserProfile(
            displayName: "Test User",
            email: "test@example.com",
            birthMonth: 8,
            birthDay: 15,
            birthYear: 1990
        )

        profile.skipStock("AAPL")

        #expect(profile.skippedStocks.contains("AAPL"))
        #expect(profile.isSkipped("AAPL"))
    }

    @Test("Skip stock removes from watchlist")
    func skipStockRemovesFromWatchlist() {
        var profile = UserProfile(
            displayName: "Test User",
            email: "test@example.com",
            birthMonth: 8,
            birthDay: 15,
            birthYear: 1990,
            watchlist: ["AAPL", "GOOGL"]
        )

        profile.skipStock("AAPL")

        #expect(!profile.watchlist.contains("AAPL"))
        #expect(profile.skippedStocks.contains("AAPL"))
    }

    @Test("Add to watchlist removes from skipped")
    func addToWatchlistRemovesFromSkipped() {
        var profile = UserProfile(
            displayName: "Test User",
            email: "test@example.com",
            birthMonth: 8,
            birthDay: 15,
            birthYear: 1990,
            skippedStocks: ["AAPL", "GOOGL"]
        )

        profile.addToWatchlist("AAPL")

        #expect(profile.watchlist.contains("AAPL"))
        #expect(!profile.skippedStocks.contains("AAPL"))
    }

    @Test("Reset skipped stocks clears list")
    func resetSkippedStocks() {
        var profile = UserProfile(
            displayName: "Test User",
            email: "test@example.com",
            birthMonth: 8,
            birthDay: 15,
            birthYear: 1990,
            skippedStocks: ["AAPL", "GOOGL", "TSLA"]
        )

        profile.resetSkippedStocks()

        #expect(profile.skippedStocks.isEmpty)
    }
}

// MARK: - Compatible Stocks Tests

struct UserProfileCompatibleStocksTests {

    @Test("Compatible stocks filtered correctly")
    func compatibleStocksFiltered() {
        let profile = UserProfile.sample // Leo
        let compatible = profile.compatibleStocks

        for stock in compatible {
            #expect(stock.isCompatible(with: profile.sunSign))
        }
    }

    @Test("Same element stocks filtered correctly")
    func sameElementStocksFiltered() {
        let profile = UserProfile.sample // Leo = fire
        let sameElement = profile.sameElementStocks

        for stock in sameElement {
            #expect(stock.element == profile.element)
        }
    }
}

// MARK: - User Age and Membership Tests

struct UserProfileAgeTests {

    @Test("Age calculation")
    func ageCalculation() {
        var components = DateComponents()
        components.year = 1990
        components.month = 8
        components.day = 15
        let birthDate = Calendar.current.date(from: components)!

        let profile = UserProfile(
            displayName: "Test User",
            email: "test@example.com",
            birthDate: birthDate
        )

        let expectedAge = Calendar.current.dateComponents([.year], from: birthDate, to: Date()).year ?? 0
        #expect(profile.age == expectedAge)
    }

    @Test("Membership duration for new member")
    func membershipDurationNewMember() {
        let profile = UserProfile(
            displayName: "Test User",
            email: "test@example.com",
            birthMonth: 8,
            birthDay: 15,
            birthYear: 1990,
            memberSince: Date()
        )

        #expect(profile.membershipDuration == "New member")
    }
}

// MARK: - Sample Data Tests

struct UserProfileSampleDataTests {

    @Test("Sample user has Leo sign")
    func sampleUserIsLeo() {
        let sample = UserProfile.sample
        #expect(sample.sunSign == .leo)
    }

    @Test("Sample Aquarius user has Aquarius sign")
    func sampleAquariusUser() {
        let sample = UserProfile.sampleAquarius
        #expect(sample.sunSign == .aquarius)
    }

    @Test("New user has empty portfolio")
    func newUserEmptyPortfolio() {
        let newUser = UserProfile.newUser
        #expect(newUser.portfolio.isEmpty)
    }
}
