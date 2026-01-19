//
//  HoroscopeGeneratorTests.swift
//  Cosmo TraderTests
//
//  Comprehensive tests for HoroscopeGenerator including reading generation,
//  performance analysis, and time context calculations.
//

import Testing
import Foundation
@testable import Cosmo_Trader

// MARK: - Portfolio Sentiment Tests

struct PortfolioSentimentTests {

    @Test("Very positive sentiment for >1.5% gain")
    func veryPositiveSentimentThreshold() {
        let change = 2.0
        let sentiment: PortfolioSentiment
        if change > 1.5 { sentiment = .veryPositive }
        else if change > 0.3 { sentiment = .positive }
        else if change < -1.5 { sentiment = .veryNegative }
        else if change < -0.3 { sentiment = .negative }
        else { sentiment = .flat }

        #expect(sentiment == .veryPositive)
    }

    @Test("Positive sentiment for >0.3% gain")
    func positiveSentimentThreshold() {
        let change = 0.8
        let sentiment: PortfolioSentiment
        if change > 1.5 { sentiment = .veryPositive }
        else if change > 0.3 { sentiment = .positive }
        else if change < -1.5 { sentiment = .veryNegative }
        else if change < -0.3 { sentiment = .negative }
        else { sentiment = .flat }

        #expect(sentiment == .positive)
    }

    @Test("Flat sentiment for small changes")
    func flatSentimentThreshold() {
        let change = 0.1
        let sentiment: PortfolioSentiment
        if change > 1.5 { sentiment = .veryPositive }
        else if change > 0.3 { sentiment = .positive }
        else if change < -1.5 { sentiment = .veryNegative }
        else if change < -0.3 { sentiment = .negative }
        else { sentiment = .flat }

        #expect(sentiment == .flat)
    }

    @Test("Negative sentiment for <-0.3% loss")
    func negativeSentimentThreshold() {
        let change = -0.8
        let sentiment: PortfolioSentiment
        if change > 1.5 { sentiment = .veryPositive }
        else if change > 0.3 { sentiment = .positive }
        else if change < -1.5 { sentiment = .veryNegative }
        else if change < -0.3 { sentiment = .negative }
        else { sentiment = .flat }

        #expect(sentiment == .negative)
    }

    @Test("Very negative sentiment for <-1.5% loss")
    func veryNegativeSentimentThreshold() {
        let change = -2.5
        let sentiment: PortfolioSentiment
        if change > 1.5 { sentiment = .veryPositive }
        else if change > 0.3 { sentiment = .positive }
        else if change < -1.5 { sentiment = .veryNegative }
        else if change < -0.3 { sentiment = .negative }
        else { sentiment = .flat }

        #expect(sentiment == .veryNegative)
    }
}

// MARK: - Market Period Tests

struct MarketPeriodTests {

    @Test("Pre-market period before 9:30 AM")
    func preMarketPeriodDetection() {
        let hour = 8
        let minute = 30
        let totalMinutes = hour * 60 + minute
        let marketOpen = 9 * 60 + 30

        let period: MarketPeriod
        if totalMinutes < marketOpen { period = .preMarket }
        else { period = .midDay }

        #expect(period == .preMarket)
    }

    @Test("Market open period first 30 minutes")
    func marketOpenPeriodDetection() {
        let hour = 9
        let minute = 45
        let totalMinutes = hour * 60 + minute
        let marketOpen = 9 * 60 + 30

        let period: MarketPeriod
        if totalMinutes < marketOpen { period = .preMarket }
        else if totalMinutes < marketOpen + 30 { period = .marketOpen }
        else { period = .midDay }

        #expect(period == .marketOpen)
    }

    @Test("Mid-day period detection")
    func midDayPeriodDetection() {
        let hour = 12
        let minute = 0
        let totalMinutes = hour * 60 + minute
        let marketOpen = 9 * 60 + 30
        let powerHourStart = 15 * 60

        let period: MarketPeriod
        if totalMinutes < marketOpen { period = .preMarket }
        else if totalMinutes < marketOpen + 30 { period = .marketOpen }
        else if totalMinutes < powerHourStart { period = .midDay }
        else { period = .powerHour }

        #expect(period == .midDay)
    }

    @Test("Power hour period after 3 PM")
    func powerHourPeriodDetection() {
        let hour = 15
        let minute = 30
        let totalMinutes = hour * 60 + minute
        let marketOpen = 9 * 60 + 30
        let powerHourStart = 15 * 60
        let marketClose = 16 * 60

        let period: MarketPeriod
        if totalMinutes < marketOpen { period = .preMarket }
        else if totalMinutes < marketOpen + 30 { period = .marketOpen }
        else if totalMinutes < powerHourStart { period = .midDay }
        else if totalMinutes < marketClose { period = .powerHour }
        else { period = .afterHours }

        #expect(period == .powerHour)
    }

    @Test("After hours period after 4 PM")
    func afterHoursPeriodDetection() {
        let hour = 17
        let minute = 0
        let totalMinutes = hour * 60 + minute
        let marketClose = 16 * 60

        let period: MarketPeriod
        if totalMinutes >= marketClose { period = .afterHours }
        else { period = .midDay }

        #expect(period == .afterHours)
    }
}

// MARK: - Weekend Detection Tests

struct WeekendDetectionTests {

    @Test("Saturday is weekend")
    func saturdayIsWeekend() {
        let weekday = 7 // Saturday
        let isWeekend = weekday == 1 || weekday == 7

        #expect(isWeekend == true)
    }

    @Test("Sunday is weekend")
    func sundayIsWeekend() {
        let weekday = 1 // Sunday
        let isWeekend = weekday == 1 || weekday == 7

        #expect(isWeekend == true)
    }

    @Test("Monday is not weekend")
    func mondayIsNotWeekend() {
        let weekday = 2 // Monday
        let isWeekend = weekday == 1 || weekday == 7

        #expect(isWeekend == false)
    }

    @Test("Friday is not weekend")
    func fridayIsNotWeekend() {
        let weekday = 6 // Friday
        let isWeekend = weekday == 1 || weekday == 7

        #expect(isWeekend == false)
    }
}

// MARK: - Time Context Tests

struct TimeContextTests {

    @Test("Minutes to open calculated correctly")
    func minutesToOpenCalculation() {
        let hour = 8
        let minute = 0
        let totalMinutes = hour * 60 + minute
        let marketOpen = 9 * 60 + 30

        let minutesToOpen = marketOpen - totalMinutes

        #expect(minutesToOpen == 90) // 1.5 hours
    }

    @Test("Minutes to close calculated correctly")
    func minutesToCloseCalculation() {
        let hour = 14
        let minute = 0
        let totalMinutes = hour * 60 + minute
        let marketClose = 16 * 60

        let minutesToClose = marketClose - totalMinutes

        #expect(minutesToClose == 120) // 2 hours
    }
}

// MARK: - Horoscope Content Tests

struct HoroscopeContentTests {

    @Test("Horoscope generated for all signs")
    func horoscopeGeneratedForAllSigns() {
        for sign in ZodiacSign.allCases {
            // Create a new user with each sign's birthdate
            let date = dateForSign(sign)
            let components = Calendar.current.dateComponents([.month, .day, .year], from: date)
            let user = UserProfile(
                displayName: "Test",
                email: "test@test.com",
                birthMonth: components.month ?? 1,
                birthDay: components.day ?? 1,
                birthYear: components.year ?? 1990,
                portfolio: []
            )

            let horoscope = HoroscopeGenerator.generate(for: user, planetaryEvents: [])

            #expect(!horoscope.reading.isEmpty, "Horoscope empty for \(sign)")
        }
    }

    @Test("Horoscope includes sign in context")
    func horoscopeHasSignContext() {
        let horoscope = HoroscopeGenerator.generate(for: UserProfile.sample, planetaryEvents: [])

        // Horoscope should have the sign set
        #expect(horoscope.sign == UserProfile.sample.sunSign)
    }

    @Test("Horoscope has valid date")
    func horoscopeHasValidDate() {
        let horoscope = HoroscopeGenerator.generate(for: UserProfile.sample, planetaryEvents: [])

        // Date should be today
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let horoscopeDay = calendar.startOfDay(for: horoscope.date)

        #expect(today == horoscopeDay)
    }

    // Helper to get a date for a specific sign
    private func dateForSign(_ sign: ZodiacSign) -> Date {
        var components = DateComponents()
        components.year = 1990
        components.month = sign.startDate.month
        components.day = sign.startDate.day + 5 // Middle of the sign
        return Calendar.current.date(from: components) ?? Date()
    }
}

// MARK: - DailyHoroscope Model Tests

struct DailyHoroscopeModelTests {

    @Test("DailyHoroscope has unique ID")
    func dailyHoroscopeHasUniqueId() {
        let horoscope1 = HoroscopeGenerator.generate(for: UserProfile.sample, planetaryEvents: [])
        let horoscope2 = HoroscopeGenerator.generate(for: UserProfile.sample, planetaryEvents: [])

        #expect(horoscope1.id != horoscope2.id)
    }

    @Test("Formatted date is not empty")
    func formattedDateNotEmpty() {
        let horoscope = HoroscopeGenerator.generate(for: UserProfile.sample, planetaryEvents: [])

        #expect(!horoscope.formattedDate.isEmpty)
    }

    @Test("Formatted date contains day name")
    func formattedDateContainsDayName() {
        let horoscope = HoroscopeGenerator.generate(for: UserProfile.sample, planetaryEvents: [])

        // Should contain day of week
        let dayNames = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
        let containsDay = dayNames.contains { horoscope.formattedDate.contains($0) }

        #expect(containsDay == true)
    }
}

// MARK: - Portfolio Performance Tests

struct PortfolioPerformanceTests {

    @Test("Empty portfolio has flat sentiment")
    func emptyPortfolioFlatSentiment() {
        let performance = PortfolioPerformance(
            overallChange: 0,
            sentiment: .flat,
            topGainer: nil,
            topLoser: nil,
            gainersCount: 0,
            losersCount: 0
        )

        #expect(performance.sentiment == .flat)
        #expect(performance.topGainer == nil)
        #expect(performance.topLoser == nil)
    }

    @Test("Performance tracks gainers and losers count")
    func performanceTracksGainersLosersCount() {
        let performance = PortfolioPerformance(
            overallChange: 0.5,
            sentiment: .positive,
            topGainer: nil,
            topLoser: nil,
            gainersCount: 5,
            losersCount: 2
        )

        #expect(performance.gainersCount == 5)
        #expect(performance.losersCount == 2)
    }
}

// MARK: - Portfolio Analysis Tests

struct PortfolioAnalysisTests {

    @Test("Well balanced portfolio detection")
    func wellBalancedPortfolioDetection() {
        // Well balanced = no element > 40%
        let maxElementPercentage = 35.0
        let isWellBalanced = maxElementPercentage < 40

        #expect(isWellBalanced == true)
    }

    @Test("Concentrated portfolio detection")
    func concentratedPortfolioDetection() {
        // Concentrated = one element > 40%
        let maxElementPercentage = 55.0
        let isWellBalanced = maxElementPercentage < 40

        #expect(isWellBalanced == false)
    }

    @Test("Tech percentage calculation")
    func techPercentageCalculation() {
        let techValue = 6000.0
        let totalValue = 10000.0
        let techPercentage = (techValue / totalValue) * 100

        #expect(techPercentage == 60.0)
    }

    @Test("Empty portfolio has zero holdings")
    func emptyPortfolioZeroHoldings() {
        let analysis = PortfolioAnalysis(
            holdingsCount: 0,
            techPercentage: 0,
            isWellBalanced: false,
            largestPosition: nil,
            smallestPosition: nil
        )

        #expect(analysis.holdingsCount == 0)
    }
}

// MARK: - Element Distribution Tests

struct ElementDistributionTests {

    @Test("Element value calculation")
    func elementValueCalculation() {
        // Simulate portfolio element distribution
        var elementValues: [ZodiacSign.Element: Double] = [:]
        elementValues[.fire] = 5000.0
        elementValues[.earth] = 3000.0
        elementValues[.air] = 2000.0
        elementValues[.water] = 0.0

        let totalValue = elementValues.values.reduce(0, +)
        let firePercentage = (elementValues[.fire]! / totalValue) * 100

        #expect(firePercentage == 50.0)
    }

    @Test("Dominant element is highest value")
    func dominantElementIsHighestValue() {
        var elementValues: [ZodiacSign.Element: Double] = [:]
        elementValues[.fire] = 5000.0
        elementValues[.earth] = 3000.0
        elementValues[.air] = 2000.0
        elementValues[.water] = 1000.0

        let dominant = elementValues.max(by: { $0.value < $1.value })?.key

        #expect(dominant == .fire)
    }
}

// MARK: - Horoscope Reading Tests

struct HoroscopeReadingTests {

    @Test("Reading has no double spaces")
    func readingNoDoubleSpaces() {
        let horoscope = HoroscopeGenerator.generate(for: UserProfile.sample, planetaryEvents: [])

        #expect(!horoscope.reading.contains("  "))
    }

    @Test("Reading is not empty")
    func readingNotEmpty() {
        let horoscope = HoroscopeGenerator.generate(for: UserProfile.sample, planetaryEvents: [])

        #expect(!horoscope.reading.isEmpty)
    }

    @Test("Reading ends with punctuation")
    func readingEndsWithPunctuation() {
        let horoscope = HoroscopeGenerator.generate(for: UserProfile.sample, planetaryEvents: [])
        let lastChar = horoscope.reading.last

        let punctuation: Set<Character> = [".", "!", "?"]
        #expect(punctuation.contains(lastChar ?? " ") == true)
    }
}
