import Foundation
import SwiftUI
import StoreKit

// MARK: - SubscriptionManager
// ===========================
// Manages subscription status and feature access for freemium model.
// Integrates with StoreKit 2 via StoreKitManager for real purchases.
//
// Philosophy: Free tier should be genuinely useful.
// Premium ("Oracle Tier") should feel like "more," not "finally usable."

@Observable
final class SubscriptionManager {

    // MARK: - Singleton

    static let shared = SubscriptionManager()

    // MARK: - Constants

    static let oracleTierPrice = "$4.99/mo"
    static let oracleTierYearlyPrice = "$39.99/yr"
    static let trialDuration = 7 // days

    // MARK: - Storage Keys

    private enum Keys {
        static let isPremium = "subscription_isPremium"
        static let trialStartDate = "subscription_trialStartDate"
        static let trialUsed = "subscription_trialUsed"
        static let dailySwipeCount = "subscription_dailySwipeCount"
        static let lastSwipeDate = "subscription_lastSwipeDate"
        static let lastHoroscopeDate = "subscription_lastHoroscopeDate"
        static let horoscopeCountToday = "subscription_horoscopeCountToday"
        static let roastCountToday = "subscription_roastCountToday"
        static let lastRoastDate = "subscription_lastRoastDate"
        static let subscriptionExpirationDate = "subscription_expirationDate"
        static let lastSubscriptionCheck = "subscription_lastCheck"
    }

    // MARK: - State

    /// Current subscription tier
    private(set) var currentTier: SubscriptionTier = .free

    /// Whether user is currently in trial period
    private(set) var isInTrial: Bool = false

    /// Days remaining in trial (if active)
    private(set) var trialDaysRemaining: Int = 0

    /// Daily swipe count (resets at midnight)
    private(set) var dailySwipeCount: Int = 0

    /// Subscription expiration date (if subscribed)
    private(set) var subscriptionExpirationDate: Date?

    /// Whether a purchase is in progress
    private(set) var isPurchasing: Bool = false

    /// Last purchase error
    private(set) var purchaseError: StoreKitError?

    /// Maximum swipes for free tier
    let freeSwipeLimit = 5

    /// Maximum stocks for free tier
    let freeStockLimit = 10

    /// Horoscope refreshes for free tier
    let freeHoroscopeLimit = 1

    /// Roast generations for free tier (per day)
    let freeRoastLimit = 1

    // MARK: - Computed

    /// Whether user has premium access (paid or trial)
    var isPremium: Bool {
        currentTier == .oracle || isInTrial
    }

    /// Swipes remaining today for free tier
    var swipesRemaining: Int {
        isPremium ? .max : max(0, freeSwipeLimit - dailySwipeCount)
    }

    /// Whether user has exhausted daily swipes
    var swipesExhausted: Bool {
        !isPremium && dailySwipeCount >= freeSwipeLimit
    }

    /// Days until subscription expires (nil if not subscribed)
    var daysUntilExpiration: Int? {
        guard let expirationDate = subscriptionExpirationDate else { return nil }
        let days = Calendar.current.dateComponents([.day], from: Date(), to: expirationDate).day
        return days
    }

    /// Whether subscription is expiring soon (within 7 days)
    var isExpiringSoon: Bool {
        guard let days = daysUntilExpiration else { return false }
        return days <= 7 && days > 0
    }

    // MARK: - Init

    private init() {
        loadSubscriptionState()
        checkAndResetDailyLimits()

        // Check StoreKit status on launch
        Task { @MainActor in
            await StoreKitManager.shared.checkSubscriptionStatus()
        }
    }

    // MARK: - Public Methods

    /// Check if user can access a specific premium feature
    func canAccess(_ feature: PremiumFeature) -> Bool {
        if isPremium { return true }
        return feature.availableInFreeTier
    }

    /// Record a swipe action (for Discovery)
    func recordSwipe() {
        guard !isPremium else { return }
        dailySwipeCount += 1
        saveDailySwipeCount()
    }

    /// Check if user can add more stocks
    func canAddStock(currentCount: Int) -> Bool {
        isPremium || currentCount < freeStockLimit
    }

    /// Check if user can refresh horoscope
    func canRefreshHoroscope() -> Bool {
        if isPremium { return true }
        return getHoroscopeCountToday() < freeHoroscopeLimit
    }

    /// Record horoscope generation
    func recordHoroscopeRefresh() {
        guard !isPremium else { return }
        let today = Calendar.current.startOfDay(for: Date())
        let count = getHoroscopeCountToday() + 1
        UserDefaults.standard.set(count, forKey: Keys.horoscopeCountToday)
        UserDefaults.standard.set(today, forKey: Keys.lastHoroscopeDate)
    }

    /// Check if user can generate roast
    func canGenerateRoast() -> Bool {
        if isPremium { return true }
        return getRoastCountToday() < freeRoastLimit
    }

    /// Record roast generation
    func recordRoastGeneration() {
        guard !isPremium else { return }
        let today = Calendar.current.startOfDay(for: Date())
        let count = getRoastCountToday() + 1
        UserDefaults.standard.set(count, forKey: Keys.roastCountToday)
        UserDefaults.standard.set(today, forKey: Keys.lastRoastDate)
    }

    /// Get roasts remaining today
    func roastsRemainingToday() -> Int {
        isPremium ? .max : max(0, freeRoastLimit - getRoastCountToday())
    }

    // MARK: - Trial Management

    /// Start free trial
    func startFreeTrial() {
        guard !hasUsedTrial() else { return }

        let startDate = Date()
        UserDefaults.standard.set(startDate, forKey: Keys.trialStartDate)
        UserDefaults.standard.set(true, forKey: Keys.trialUsed)

        isInTrial = true
        trialDaysRemaining = Self.trialDuration
    }

    /// Check if user has already used their trial
    func hasUsedTrial() -> Bool {
        UserDefaults.standard.bool(forKey: Keys.trialUsed)
    }

    /// Check if trial is still active
    private func checkTrialStatus() {
        guard let startDate = UserDefaults.standard.object(forKey: Keys.trialStartDate) as? Date else {
            isInTrial = false
            trialDaysRemaining = 0
            return
        }

        let daysSinceStart = Calendar.current.dateComponents([.day], from: startDate, to: Date()).day ?? 0
        let remaining = Self.trialDuration - daysSinceStart

        if remaining > 0 {
            isInTrial = true
            trialDaysRemaining = remaining
        } else {
            isInTrial = false
            trialDaysRemaining = 0
        }
    }

    // MARK: - Subscription Management (StoreKit Integration)

    /// Purchase Oracle tier subscription (monthly)
    @MainActor
    func purchaseMonthly() async throws {
        isPurchasing = true
        purchaseError = nil

        defer { isPurchasing = false }

        do {
            _ = try await StoreKitManager.shared.purchase(productID: .oracleMonthly)
        } catch let error as StoreKitError {
            purchaseError = error
            throw error
        } catch {
            purchaseError = .purchaseFailed(error)
            throw error
        }
    }

    /// Purchase Oracle tier subscription (yearly)
    @MainActor
    func purchaseYearly() async throws {
        isPurchasing = true
        purchaseError = nil

        defer { isPurchasing = false }

        do {
            _ = try await StoreKitManager.shared.purchase(productID: .oracleYearly)
        } catch let error as StoreKitError {
            purchaseError = error
            throw error
        } catch {
            purchaseError = .purchaseFailed(error)
            throw error
        }
    }

    /// Purchase a specific product
    @MainActor
    func purchase(product: Product) async throws {
        isPurchasing = true
        purchaseError = nil

        defer { isPurchasing = false }

        do {
            _ = try await StoreKitManager.shared.purchase(product)
        } catch let error as StoreKitError {
            purchaseError = error
            throw error
        } catch {
            purchaseError = .purchaseFailed(error)
            throw error
        }
    }

    /// Upgrade to Oracle tier (legacy method for backward compatibility)
    @MainActor
    func upgradeToOracle() {
        // This now triggers the paywall flow
        // For direct upgrade, use purchaseMonthly() or purchaseYearly()
        Task {
            do {
                try await purchaseMonthly()
            } catch {
                #if DEBUG
                print("[Subscription] Upgrade failed: \(error)")
                #endif
            }
        }
    }

    /// Restore purchases from App Store
    @MainActor
    func restorePurchases() async -> Bool {
        isPurchasing = true
        purchaseError = nil

        defer { isPurchasing = false }

        let restored = await StoreKitManager.shared.restorePurchases()
        return restored
    }

    /// Manually refresh subscription status
    @MainActor
    func refreshSubscriptionStatus() async {
        await StoreKitManager.shared.checkSubscriptionStatus()
    }

    /// Handle subscription activated (called by StoreKitManager)
    func handleSubscriptionActivated() {
        currentTier = .oracle
        subscriptionExpirationDate = StoreKitManager.shared.subscriptionExpirationDate
        UserDefaults.standard.set(true, forKey: Keys.isPremium)

        if let expirationDate = subscriptionExpirationDate {
            UserDefaults.standard.set(expirationDate, forKey: Keys.subscriptionExpirationDate)
        }

        UserDefaults.standard.set(Date(), forKey: Keys.lastSubscriptionCheck)

        #if DEBUG
        print("[Subscription] Subscription activated, expires: \(subscriptionExpirationDate?.description ?? "unknown")")
        #endif
    }

    /// Handle subscription expired (called by StoreKitManager)
    func handleSubscriptionExpired() {
        // Only downgrade if we were previously subscribed (not in trial)
        guard currentTier == .oracle && !isInTrial else { return }

        currentTier = .free
        subscriptionExpirationDate = nil
        UserDefaults.standard.set(false, forKey: Keys.isPremium)
        UserDefaults.standard.removeObject(forKey: Keys.subscriptionExpirationDate)

        #if DEBUG
        print("[Subscription] Subscription expired")
        #endif
    }

    /// Downgrade to free tier (for testing/debugging only)
    func downgradeToFree() {
        currentTier = .free
        isInTrial = false
        subscriptionExpirationDate = nil
        UserDefaults.standard.set(false, forKey: Keys.isPremium)
        UserDefaults.standard.removeObject(forKey: Keys.subscriptionExpirationDate)
    }

    /// Check if subscription needs refresh (called periodically)
    func shouldRefreshSubscription() -> Bool {
        guard let lastCheck = UserDefaults.standard.object(forKey: Keys.lastSubscriptionCheck) as? Date else {
            return true
        }

        // Refresh every 24 hours
        let hoursSinceLastCheck = Calendar.current.dateComponents([.hour], from: lastCheck, to: Date()).hour ?? 0
        return hoursSinceLastCheck >= 24
    }

    // MARK: - Private Methods

    private func loadSubscriptionState() {
        // Load premium status
        let isPremiumStored = UserDefaults.standard.bool(forKey: Keys.isPremium)
        currentTier = isPremiumStored ? .oracle : .free

        // Load subscription expiration date
        if let expirationDate = UserDefaults.standard.object(forKey: Keys.subscriptionExpirationDate) as? Date {
            subscriptionExpirationDate = expirationDate

            // Check if subscription has expired locally
            if expirationDate < Date() && !isInTrial {
                currentTier = .free
                UserDefaults.standard.set(false, forKey: Keys.isPremium)
            }
        }

        // Check trial status
        checkTrialStatus()

        // Load daily counts
        dailySwipeCount = UserDefaults.standard.integer(forKey: Keys.dailySwipeCount)
    }

    private func checkAndResetDailyLimits() {
        let today = Calendar.current.startOfDay(for: Date())

        // Reset swipe count if it's a new day
        if let lastSwipeDate = UserDefaults.standard.object(forKey: Keys.lastSwipeDate) as? Date {
            let lastDay = Calendar.current.startOfDay(for: lastSwipeDate)
            if today > lastDay {
                dailySwipeCount = 0
                saveDailySwipeCount()
            }
        }
    }

    private func saveDailySwipeCount() {
        UserDefaults.standard.set(dailySwipeCount, forKey: Keys.dailySwipeCount)
        UserDefaults.standard.set(Date(), forKey: Keys.lastSwipeDate)
    }

    private func getHoroscopeCountToday() -> Int {
        let today = Calendar.current.startOfDay(for: Date())
        if let lastDate = UserDefaults.standard.object(forKey: Keys.lastHoroscopeDate) as? Date {
            let lastDay = Calendar.current.startOfDay(for: lastDate)
            if today > lastDay {
                // New day, reset count
                return 0
            }
        }
        return UserDefaults.standard.integer(forKey: Keys.horoscopeCountToday)
    }

    private func getRoastCountToday() -> Int {
        let today = Calendar.current.startOfDay(for: Date())
        if let lastDate = UserDefaults.standard.object(forKey: Keys.lastRoastDate) as? Date {
            let lastDay = Calendar.current.startOfDay(for: lastDate)
            if today > lastDay {
                return 0
            }
        }
        return UserDefaults.standard.integer(forKey: Keys.roastCountToday)
    }
}

// MARK: - Subscription Tier

enum SubscriptionTier: String, CaseIterable {
    case free = "Free"
    case oracle = "Oracle"

    var displayName: String {
        switch self {
        case .free: return "Free Tier"
        case .oracle: return "Oracle Tier"
        }
    }

    var color: Color {
        switch self {
        case .free: return CosmicTheme.textSecondary
        case .oracle: return CosmicTheme.gold
        }
    }
}

// MARK: - Premium Feature

enum PremiumFeature: String, CaseIterable {
    // Data Features
    case realTimeData = "Real-time market data"
    case delayedData = "End-of-day prices"

    // Discovery
    case unlimitedSwipes = "Unlimited Discovery swipes"
    case limitedSwipes = "5 Discovery swipes/day"

    // Portfolio
    case unlimitedStocks = "Unlimited portfolio stocks"
    case limitedStocks = "Up to 10 portfolio stocks"

    // Horoscope
    case advancedHoroscope = "Advanced horoscopes (refresh anytime)"
    case basicHoroscope = "Basic daily horoscope"

    // Moon Features
    case moonNotifications = "Moon phase notifications"
    case moonSignAlerts = "Moon sign sector alerts"
    case basicMoonPhase = "Basic moon phase display"

    // Social/Fun
    case unlimitedRoasts = "Unlimited Cosmic Roasts"
    case limitedRoasts = "1 Cosmic Roast per day"

    // IPO
    case ipoAlerts = "IPO compatibility alerts"

    // Analytics
    case fearGreedIndex = "Cosmic Fear & Greed Index"

    // Experience
    case adFree = "Ad-free experience"

    /// Whether this feature is available in free tier
    var availableInFreeTier: Bool {
        switch self {
        case .delayedData,
             .limitedSwipes,
             .limitedStocks,
             .basicHoroscope,
             .basicMoonPhase,
             .limitedRoasts:
            return true
        default:
            return false
        }
    }

    /// Icon for the feature
    var icon: String {
        switch self {
        case .realTimeData, .delayedData:
            return "chart.line.uptrend.xyaxis"
        case .unlimitedSwipes, .limitedSwipes:
            return "hand.tap.fill"
        case .unlimitedStocks, .limitedStocks:
            return "briefcase.fill"
        case .advancedHoroscope, .basicHoroscope:
            return "sparkles"
        case .moonNotifications, .moonSignAlerts, .basicMoonPhase:
            return "moon.fill"
        case .unlimitedRoasts, .limitedRoasts:
            return "flame.fill"
        case .ipoAlerts:
            return "bell.badge.fill"
        case .fearGreedIndex:
            return "gauge.with.needle.fill"
        case .adFree:
            return "xmark.circle.fill"
        }
    }

    /// Upgrade message when blocked
    var upgradeMessage: String {
        switch self {
        case .realTimeData:
            return "Real-time data requires Oracle Tier"
        case .unlimitedSwipes:
            return "Daily swipes exhausted. Reset at midnight or upgrade."
        case .unlimitedStocks:
            return "Free tier limited to 10 holdings"
        case .advancedHoroscope:
            return "Unlimited horoscope refreshes with Oracle Tier"
        case .moonNotifications:
            return "Moon phase alerts require Oracle Tier"
        case .moonSignAlerts:
            return "Moon sign alerts require Oracle Tier"
        case .unlimitedRoasts:
            return "Unlimited roasts with Oracle Tier"
        case .ipoAlerts:
            return "IPO alerts require Oracle Tier"
        case .fearGreedIndex:
            return "Fear & Greed Index requires Oracle Tier"
        case .adFree:
            return "Go ad-free with Oracle Tier"
        default:
            return "Upgrade to Oracle Tier for full access"
        }
    }
}

// MARK: - Oracle Tier Benefits

struct OracleTierBenefits {

    static let all: [OracleBenefit] = [
        OracleBenefit(
            feature: .realTimeData,
            title: "Real-Time Data",
            description: "Live Finnhub market data, no delays"
        ),
        OracleBenefit(
            feature: .unlimitedSwipes,
            title: "Unlimited Discovery",
            description: "Swipe through unlimited stocks daily"
        ),
        OracleBenefit(
            feature: .advancedHoroscope,
            title: "Advanced Horoscopes",
            description: "Refresh anytime, more detailed readings"
        ),
        OracleBenefit(
            feature: .unlimitedStocks,
            title: "Unlimited Portfolio",
            description: "Track as many stocks as you want"
        ),
        OracleBenefit(
            feature: .moonNotifications,
            title: "Lunar Alerts",
            description: "Full & new moon notifications"
        ),
        OracleBenefit(
            feature: .moonSignAlerts,
            title: "Personal Moon Alerts",
            description: "Know when the moon enters your sign"
        ),
        OracleBenefit(
            feature: .unlimitedRoasts,
            title: "Unlimited Roasts",
            description: "Generate Cosmic Roasts anytime"
        ),
        OracleBenefit(
            feature: .ipoAlerts,
            title: "IPO Compatibility",
            description: "Alerts for cosmically aligned IPOs"
        ),
        OracleBenefit(
            feature: .fearGreedIndex,
            title: "Cosmic Fear & Greed",
            description: "Market sentiment through a cosmic lens"
        ),
        OracleBenefit(
            feature: .adFree,
            title: "Ad-Free",
            description: "Pure, uninterrupted cosmic experience"
        )
    ]
}

struct OracleBenefit: Identifiable {
    let id = UUID()
    let feature: PremiumFeature
    let title: String
    let description: String
}
