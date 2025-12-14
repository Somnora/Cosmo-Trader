//
//  UserDataExport.swift
//  Cosmo Trader
//
//  GDPR-compliant data export structure.
//  Contains all user data in a portable, readable JSON format.
//

import Foundation

// MARK: - User Data Export

/// Complete export of user data for GDPR compliance
struct UserDataExport: Codable {

    // MARK: - Metadata

    let exportVersion: String
    let exportDate: String
    let appVersion: String
    let appName: String

    // MARK: - Profile Data

    let profile: ProfileExport

    // MARK: - Portfolio Data

    let portfolio: [StockExport]

    // MARK: - Watchlist

    let watchlist: [String]

    // MARK: - Skipped Stocks

    let skippedStocks: [String]

    // MARK: - Preferences

    let preferences: PreferencesExport

    // MARK: - Subscription

    let subscription: SubscriptionExport

    // MARK: - Statistics

    let statistics: StatisticsExport
}

// MARK: - Profile Export

struct ProfileExport: Codable {
    let id: String
    let displayName: String
    let email: String
    let birthDate: String
    let timeOfBirth: String?
    let birthLocation: String?
    let sunSign: String
    let element: String
    let modality: String
    let memberSince: String
    let preferredCurrency: String
}

// MARK: - Stock Export

struct StockExport: Codable {
    let symbol: String
    let companyName: String
    let sharesOwned: Double
    let purchasePrice: Double?
    let currentPrice: Double
    let zodiacSign: String
    let element: String
    let dateAdded: String?
}

// MARK: - Preferences Export

struct PreferencesExport: Codable {
    let notifications: NotificationPreferencesExport
    let appearance: AppearancePreferencesExport
    let audio: AudioPreferencesExport
    let analytics: AnalyticsPreferencesExport
}

struct NotificationPreferencesExport: Codable {
    let dailyHoroscopeEnabled: Bool
    let priceAlertsEnabled: Bool
    let fullMoonAlertsEnabled: Bool
    let newMoonAlertsEnabled: Bool
    let moonInSignAlertsEnabled: Bool
    let mercuryRetrogradeAlertsEnabled: Bool
}

struct AppearancePreferencesExport: Codable {
    let showCompatibilityScores: Bool
    let showElementIndicators: Bool
    let animationsEnabled: Bool
}

struct AudioPreferencesExport: Codable {
    let terminalSoundsEnabled: Bool
    let ambientVolume: Double
    let effectsVolume: Double
}

struct AnalyticsPreferencesExport: Codable {
    let analyticsOptedOut: Bool
}

// MARK: - Subscription Export

struct SubscriptionExport: Codable {
    let tier: String
    let isPremium: Bool
    let isInTrial: Bool
    let trialStartDate: String?
    let subscriptionExpirationDate: String?
}

// MARK: - Statistics Export

struct StatisticsExport: Codable {
    let totalPortfolioValue: Double
    let numberOfHoldings: Int
    let watchlistCount: Int
    let membershipDuration: String
    let averageCompatibilityScore: Int
}

// MARK: - Export Builder

enum UserDataExportBuilder {

    /// Build a complete data export from app state
    static func build(from appState: AppState) -> UserDataExport? {
        guard let user = appState.currentUser else { return nil }

        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withFullDate, .withTime, .withTimeZone]

        let displayDateFormatter = DateFormatter()
        displayDateFormatter.dateStyle = .long
        displayDateFormatter.timeStyle = .none

        // Format time of birth if available
        let timeFormatter = DateFormatter()
        timeFormatter.timeStyle = .short

        // Build profile export
        let profile = ProfileExport(
            id: user.id.uuidString,
            displayName: user.displayName,
            email: user.email,
            birthDate: displayDateFormatter.string(from: user.birthDate),
            timeOfBirth: user.timeOfBirth.map { timeFormatter.string(from: $0) },
            birthLocation: user.birthLocation,
            sunSign: user.sunSign.displayName,
            element: user.sunSign.element.displayName,
            modality: user.sunSign.modality.displayName,
            memberSince: displayDateFormatter.string(from: user.memberSince),
            preferredCurrency: user.preferredCurrency
        )

        // Build portfolio export
        let portfolio = user.portfolio.map { stock in
            StockExport(
                symbol: stock.symbol,
                companyName: stock.name,
                sharesOwned: stock.sharesOwned,
                purchasePrice: stock.purchasePrice,
                currentPrice: stock.currentPrice,
                zodiacSign: stock.zodiacSign.displayName,
                element: stock.element.displayName,
                dateAdded: nil // Not currently tracked
            )
        }

        // Build preferences export
        let moonService = MoonPhaseService.shared
        let audioService = TerminalAudioService.shared
        let defaults = UserDefaults.standard

        let notificationPrefs = NotificationPreferencesExport(
            dailyHoroscopeEnabled: defaults.bool(forKey: "notification_dailyHoroscope"),
            priceAlertsEnabled: defaults.bool(forKey: "notification_priceAlerts"),
            fullMoonAlertsEnabled: moonService.notifyOnFullMoon,
            newMoonAlertsEnabled: moonService.notifyOnNewMoon,
            moonInSignAlertsEnabled: moonService.notifyOnMoonInUserSign,
            mercuryRetrogradeAlertsEnabled: defaults.bool(forKey: "notification_mercuryRetrograde")
        )

        let appearancePrefs = AppearancePreferencesExport(
            showCompatibilityScores: defaults.bool(forKey: "appearance_showCompatibility"),
            showElementIndicators: defaults.bool(forKey: "appearance_showElements"),
            animationsEnabled: defaults.bool(forKey: "appearance_animations")
        )

        let audioPrefs = AudioPreferencesExport(
            terminalSoundsEnabled: audioService.isEnabled,
            ambientVolume: Double(audioService.ambientVolume),
            effectsVolume: Double(audioService.effectsVolume)
        )

        let analyticsPrefs = AnalyticsPreferencesExport(
            analyticsOptedOut: AnalyticsService.shared.hasOptedOut
        )

        let preferences = PreferencesExport(
            notifications: notificationPrefs,
            appearance: appearancePrefs,
            audio: audioPrefs,
            analytics: analyticsPrefs
        )

        // Build subscription export
        let subscriptionManager = SubscriptionManager.shared
        let subscription = SubscriptionExport(
            tier: subscriptionManager.isPremium ? "Oracle" : "Free",
            isPremium: subscriptionManager.isPremium,
            isInTrial: subscriptionManager.isInTrial,
            trialStartDate: subscriptionManager.isInTrial ? dateFormatter.string(from: Date()) : nil,
            subscriptionExpirationDate: subscriptionManager.subscriptionExpirationDate.map { dateFormatter.string(from: $0) }
        )

        // Build statistics export
        let statistics = StatisticsExport(
            totalPortfolioValue: user.totalPortfolioValue,
            numberOfHoldings: user.numberOfHoldings,
            watchlistCount: user.watchlist.count,
            membershipDuration: user.membershipDuration,
            averageCompatibilityScore: user.averagePortfolioCompatibility
        )

        // Build final export
        return UserDataExport(
            exportVersion: "1.0",
            exportDate: dateFormatter.string(from: Date()),
            appVersion: BuildInfo.fullVersion,
            appName: BuildInfo.appName,
            profile: profile,
            portfolio: portfolio,
            watchlist: user.watchlist,
            skippedStocks: user.skippedStocks,
            preferences: preferences,
            subscription: subscription,
            statistics: statistics
        )
    }

    /// Convert export to pretty-printed JSON string
    static func toJSON(_ export: UserDataExport) -> String? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        guard let data = try? encoder.encode(export) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    /// Convert export to Data for sharing
    static func toData(_ export: UserDataExport) -> Data? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try? encoder.encode(export)
    }
}

