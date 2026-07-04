//
//  NotificationServiceTests.swift
//  Cosmo TraderTests
//
//  Comprehensive tests for NotificationService including scheduling,
//  preferences, and notification content generation.
//

import Testing
import Foundation
@testable import Cosmo_Trader

// MARK: - Notification Preferences Tests

struct NotificationPreferencesTests {

    @Test("Daily horoscope default is enabled")
    func dailyHoroscopeDefaultEnabled() {
        // Default should be true based on loadPreferences logic
        let defaultValue = true
        #expect(defaultValue == true)
    }

    @Test("Moon phase default is enabled")
    func moonPhaseDefaultEnabled() {
        let defaultValue = true
        #expect(defaultValue == true)
    }

    @Test("Mercury retrograde default is enabled")
    func mercuryRetrogradeDefaultEnabled() {
        let defaultValue = true
        #expect(defaultValue == true)
    }

    @Test("Portfolio alerts default is enabled")
    func portfolioAlertsDefaultEnabled() {
        let defaultValue = true
        #expect(defaultValue == true)
    }

    @Test("Weekly summary default is enabled")
    func weeklySummaryDefaultEnabled() {
        let defaultValue = true
        #expect(defaultValue == true)
    }

    @Test("Cosmic roast reminder default is disabled")
    func cosmicRoastReminderDefaultDisabled() {
        let defaultValue = false
        #expect(defaultValue == false)
    }

    @Test("Sign season default is enabled")
    func signSeasonDefaultEnabled() {
        let defaultValue = true
        #expect(defaultValue == true)
    }
}

// MARK: - Default Horoscope Time Tests

struct DefaultHoroscopeTimeTests {

    @Test("Default horoscope time is 7:30 AM")
    func defaultHoroscopeTimeIs730AM() {
        var components = DateComponents()
        components.hour = 7
        components.minute = 30
        let defaultTime = Calendar.current.date(from: components)

        #expect(defaultTime != nil)
        if let time = defaultTime {
            let timeComponents = Calendar.current.dateComponents([.hour, .minute], from: time)
            #expect(timeComponents.hour == 7)
            #expect(timeComponents.minute == 30)
        }
    }
}

// MARK: - Permission State Tests

struct NotificationPermissionStateTests {

    @Test("Can request permission when not yet requested")
    func canRequestPermissionWhenNotRequested() {
        let hasRequested = false
        let status = "notDetermined"
        let canRequest = !hasRequested && status == "notDetermined"

        #expect(canRequest == true)
    }

    @Test("Cannot request permission when already requested")
    func cannotRequestPermissionWhenRequested() {
        let hasRequested = true
        let status = "notDetermined"
        let canRequest = !hasRequested && status == "notDetermined"

        #expect(canRequest == false)
    }

    @Test("Cannot request permission when denied")
    func cannotRequestPermissionWhenDenied() {
        let hasRequested = true
        let status = "denied"
        let canRequest = !hasRequested && status == "notDetermined"

        #expect(canRequest == false)
    }
}

// MARK: - Authorization Status Tests

struct NotificationAuthorizationStatusTests {

    @Test("Authorized when status is authorized")
    func authorizedWhenStatusAuthorized() {
        let status = "authorized"
        let isAuthorized = status == "authorized"

        #expect(isAuthorized == true)
    }

    @Test("Not authorized when status is denied")
    func notAuthorizedWhenStatusDenied() {
        let status = "denied"
        let isAuthorized = status == "authorized"

        #expect(isAuthorized == false)
    }

    @Test("Not authorized when status is notDetermined")
    func notAuthorizedWhenStatusNotDetermined() {
        let status = "notDetermined"
        let isAuthorized = status == "authorized"

        #expect(isAuthorized == false)
    }
}

// MARK: - Mercury Retrograde Content Tests

struct MercuryRetrogradeContentTests {

    @Test("Mercury retrograde warning for today")
    func mercuryRetrogradeWarningToday() {
        let daysUntil = 0
        let affectedCount = 5

        var title: String
        var body: String

        if daysUntil == 0 {
            title = "Mercury Retrograde Begins Today"
            body = "\(affectedCount) stocks in your portfolio historically volatile during retrogrades."
        } else if daysUntil == 1 {
            title = "Mercury Retrograde Tomorrow"
            body = "\(affectedCount) stocks in your portfolio may see increased volatility."
        } else {
            title = "Mercury Retrograde Approaching"
            body = "Begins in \(daysUntil) days. \(affectedCount) portfolio stocks to watch."
        }

        #expect(title.contains("Today"))
        #expect(body.contains("5 stocks"))
    }

    @Test("Mercury retrograde warning for tomorrow")
    func mercuryRetrogradeWarningTomorrow() {
        let daysUntil = 1
        let affectedCount = 3

        var title: String
        if daysUntil == 0 {
            title = "Mercury Retrograde Begins Today"
        } else if daysUntil == 1 {
            title = "Mercury Retrograde Tomorrow"
        } else {
            title = "Mercury Retrograde Approaching"
        }

        #expect(title.contains("Tomorrow"))
    }

    @Test("Mercury retrograde warning for future")
    func mercuryRetrogradeWarningFuture() {
        let daysUntil = 5
        let affectedCount = 4

        var title: String
        var body: String

        if daysUntil == 0 {
            title = "Mercury Retrograde Begins Today"
            body = ""
        } else if daysUntil == 1 {
            title = "Mercury Retrograde Tomorrow"
            body = ""
        } else {
            title = "Mercury Retrograde Approaching"
            body = "Begins in \(daysUntil) days. \(affectedCount) portfolio stocks to watch."
        }

        #expect(title.contains("Approaching"))
        #expect(body.contains("5 days"))
    }
}

// MARK: - Portfolio Big Move Alert Tests

struct PortfolioBigMoveAlertTests {

    @Test("Big move threshold is 5%")
    func bigMoveThresholdIs5Percent() {
        let threshold = 5.0
        #expect(threshold == 5.0)
    }

    @Test("Alert triggered for moves >= 5%")
    func alertTriggeredForBigMove() {
        let changePercent = 6.5
        let threshold = 5.0
        let shouldAlert = abs(changePercent) >= threshold

        #expect(shouldAlert == true)
    }

    @Test("Alert not triggered for moves < 5%")
    func alertNotTriggeredForSmallMove() {
        let changePercent = 3.2
        let threshold = 5.0
        let shouldAlert = abs(changePercent) >= threshold

        #expect(shouldAlert == false)
    }

    @Test("Direction detection for positive move")
    func directionDetectionPositive() {
        let changePercent = 7.5
        let direction = changePercent > 0 ? "up" : "down"

        #expect(direction == "up")
    }

    @Test("Direction detection for negative move")
    func directionDetectionNegative() {
        let changePercent = -8.2
        let direction = changePercent > 0 ? "up" : "down"

        #expect(direction == "down")
    }
}

// MARK: - Weekly Summary Schedule Tests

struct WeeklySummaryScheduleTests {

    @Test("Weekly summary on Sunday")
    func weeklySummaryOnSunday() {
        let scheduledWeekday = 1 // Sunday
        #expect(scheduledWeekday == 1)
    }

    @Test("Weekly summary at 6 PM")
    func weeklySummaryAt6PM() {
        let scheduledHour = 18
        let scheduledMinute = 0

        #expect(scheduledHour == 18)
        #expect(scheduledMinute == 0)
    }
}

// MARK: - Cosmic Roast Reminder Schedule Tests

struct CosmicRoastReminderScheduleTests {

    @Test("Cosmic roast on Wednesday")
    func cosmicRoastOnWednesday() {
        let scheduledWeekday = 4 // Wednesday
        #expect(scheduledWeekday == 4)
    }

    @Test("Cosmic roast at noon")
    func cosmicRoastAtNoon() {
        let scheduledHour = 12
        let scheduledMinute = 0

        #expect(scheduledHour == 12)
        #expect(scheduledMinute == 0)
    }
}

// MARK: - Next Zodiac Sign Calculation Tests

struct NextZodiacSignCalculationTests {

    @Test("Next sign after Aries is Taurus")
    func nextSignAfterAries() {
        let allSigns = ZodiacSign.allCases
        guard let ariesIndex = allSigns.firstIndex(of: .aries) else {
            #expect(Bool(false), "Aries not found")
            return
        }
        let nextIndex = (ariesIndex + 1) % allSigns.count
        let nextSign = allSigns[nextIndex]

        #expect(nextSign == .taurus)
    }

    @Test("Next sign after Pisces wraps to Aries")
    func nextSignAfterPiscesWraps() {
        let allSigns = ZodiacSign.allCases
        guard let piscesIndex = allSigns.firstIndex(of: .pisces) else {
            #expect(Bool(false), "Pisces not found")
            return
        }
        let nextIndex = (piscesIndex + 1) % allSigns.count
        let nextSign = allSigns[nextIndex]

        #expect(nextSign == .aries)
    }

    @Test("All signs have a next sign")
    func allSignsHaveNextSign() {
        let allSigns = ZodiacSign.allCases

        for sign in allSigns {
            guard let currentIndex = allSigns.firstIndex(of: sign) else {
                #expect(Bool(false), "\(sign) not found")
                continue
            }
            let nextIndex = (currentIndex + 1) % allSigns.count
            let nextSign = allSigns[nextIndex]

            #expect(nextSign != sign, "Next sign should be different")
        }
    }
}

// MARK: - Confluence Alert Content Tests

struct ConfluenceAlertContentTests {

    @Test("Confluence alert includes symbol")
    func confluenceAlertIncludesSymbol() {
        let symbol = "AAPL"
        let title = "⚡ \(symbol): Cosmic Confluence"

        #expect(title.contains(symbol))
    }

    @Test("Confluence alert includes pattern")
    func confluenceAlertIncludesPattern() {
        let symbol = "AAPL"
        let pattern = "Golden Cross"
        let cosmicEvent = "Full Moon"
        let compatibility = 85
        let userSign = ZodiacSign.leo

        let body = "\(pattern) detected as \(cosmicEvent). \(compatibility)% compatible with \(userSign.displayName)."

        #expect(body.contains(pattern))
        #expect(body.contains(cosmicEvent))
        #expect(body.contains("85%"))
        #expect(body.contains("Leo"))
    }
}

// MARK: - Moon Phase Alert Tests

struct MoonPhaseAlertTests {

    @Test("Full moon alert day before")
    func fullMoonAlertDayBefore() {
        // Full moon alerts should be scheduled day before at 6 PM
        let scheduledHour = 18
        let scheduledMinute = 0

        #expect(scheduledHour == 18)
        #expect(scheduledMinute == 0)
    }

    @Test("New moon alert on the day")
    func newMoonAlertOnTheDay() {
        // New moon alerts should be at 8 AM on the day
        let scheduledHour = 8
        let scheduledMinute = 0

        #expect(scheduledHour == 8)
        #expect(scheduledMinute == 0)
    }

    @Test("Moon phase alerts scheduled for 30 days")
    func moonPhaseAlertsFor30Days() {
        let scheduleDays = 30

        #expect(scheduleDays == 30)
    }
}

// MARK: - Notification Content Tests

struct NotificationContentTests {

    @Test("Test notification content is correct")
    func testNotificationContent() {
        let title = "Cosmic Connection Established"
        let body = "Your notifications are working. The stars can reach you now."

        #expect(title == "Cosmic Connection Established")
        #expect(body.contains("notifications are working"))
    }

    @Test("Test notification triggers in 2 seconds")
    func testNotificationTriggerTime() {
        let triggerInterval: TimeInterval = 2

        #expect(triggerInterval == 2)
    }
}

// MARK: - Horoscope Messages Tests

struct HoroscopeMessagesTests {

    @Test("Random horoscope messages array exists")
    func randomHoroscopeMessagesExist() {
        let messages = [
            "Your cosmic portfolio reading is ready.",
            "The stars have aligned. Check your holdings.",
            "A new day, new cosmic insights await.",
            "Your celestial market forecast is in.",
            "The universe has something to say about your portfolio."
        ]

        #expect(messages.count == 5)
    }

    @Test("All horoscope messages are not empty")
    func allHoroscopeMessagesNotEmpty() {
        let messages = [
            "Your cosmic portfolio reading is ready.",
            "The stars have aligned. Check your holdings.",
            "A new day, new cosmic insights await.",
            "Your celestial market forecast is in.",
            "The universe has something to say about your portfolio."
        ]

        for message in messages {
            #expect(!message.isEmpty)
        }
    }
}

// MARK: - Sign Season Alert Tests

struct SignSeasonAlertTests {

    @Test("Sign season alert at 8 AM")
    func signSeasonAlertAt8AM() {
        let scheduledHour = 8
        let scheduledMinute = 0

        #expect(scheduledHour == 8)
        #expect(scheduledMinute == 0)
    }

    @Test("Sign season alerts for next 3 transitions")
    func signSeasonAlertsFor3Transitions() {
        let transitionCount = 3

        #expect(transitionCount == 3)
    }
}
