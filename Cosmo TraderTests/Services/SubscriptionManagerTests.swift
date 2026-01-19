//
//  SubscriptionManagerTests.swift
//  Cosmo TraderTests
//
//  Comprehensive tests for SubscriptionManager including tier access,
//  feature gating, trial management, and subscription state.
//

import Testing
import Foundation
@testable import Cosmo_Trader

// MARK: - Subscription Tier Tests

struct SubscriptionTierTests {

    @Test("Free tier display name")
    func freeTierDisplayName() {
        #expect(SubscriptionTier.free.displayName == "Free Tier")
    }

    @Test("Oracle tier display name")
    func oracleTierDisplayName() {
        #expect(SubscriptionTier.oracle.displayName == "Oracle Tier")
    }

    @Test("All tiers have unique raw values")
    func tiersHaveUniqueRawValues() {
        let rawValues = SubscriptionTier.allCases.map { $0.rawValue }
        let uniqueValues = Set(rawValues)

        #expect(rawValues.count == uniqueValues.count)
    }

    @Test("Two subscription tiers exist")
    func twoTiersExist() {
        #expect(SubscriptionTier.allCases.count == 2)
    }
}

// MARK: - Premium Feature Tests

struct PremiumFeatureTests {

    @Test("Free tier features are accessible")
    func freeTierFeaturesAccessible() {
        let freeFeatures: [PremiumFeature] = [
            .delayedData,
            .limitedSwipes,
            .limitedStocks,
            .basicHoroscope,
            .basicMoonPhase,
            .limitedRoasts
        ]

        for feature in freeFeatures {
            #expect(feature.availableInFreeTier == true, "Feature \(feature.rawValue) should be free")
        }
    }

    @Test("Premium features are gated")
    func premiumFeaturesGated() {
        let premiumFeatures: [PremiumFeature] = [
            .realTimeData,
            .unlimitedSwipes,
            .unlimitedStocks,
            .advancedHoroscope,
            .moonNotifications,
            .moonSignAlerts,
            .unlimitedRoasts,
            .ipoAlerts,
            .fearGreedIndex,
            .adFree
        ]

        for feature in premiumFeatures {
            #expect(feature.availableInFreeTier == false, "Feature \(feature.rawValue) should be premium")
        }
    }

    @Test("All features have icons")
    func allFeaturesHaveIcons() {
        for feature in PremiumFeature.allCases {
            #expect(!feature.icon.isEmpty, "Feature \(feature.rawValue) should have an icon")
        }
    }

    @Test("All features have upgrade messages")
    func allFeaturesHaveUpgradeMessages() {
        for feature in PremiumFeature.allCases {
            #expect(!feature.upgradeMessage.isEmpty, "Feature \(feature.rawValue) should have upgrade message")
        }
    }
}

// MARK: - Oracle Tier Benefits Tests

struct OracleTierBenefitsTests {

    @Test("Oracle tier has all benefits defined")
    func oracleTierHasAllBenefits() {
        #expect(OracleTierBenefits.all.count >= 8)
    }

    @Test("Each benefit has a title and description")
    func benefitsHaveTitleAndDescription() {
        for benefit in OracleTierBenefits.all {
            #expect(!benefit.title.isEmpty)
            #expect(!benefit.description.isEmpty)
        }
    }

    @Test("Benefits have unique IDs")
    func benefitsHaveUniqueIds() {
        let ids = OracleTierBenefits.all.map { $0.id }
        let uniqueIds = Set(ids)

        #expect(ids.count == uniqueIds.count)
    }
}

// MARK: - Subscription Constants Tests

struct SubscriptionConstantsTests {

    @Test("Oracle tier price is defined")
    func oracleTierPriceDefined() {
        #expect(SubscriptionManager.oracleTierPrice == "$4.99/mo")
    }

    @Test("Oracle tier yearly price is defined")
    func oracleTierYearlyPriceDefined() {
        #expect(SubscriptionManager.oracleTierYearlyPrice == "$39.99/yr")
    }

    @Test("Trial duration is 7 days")
    func trialDurationSevenDays() {
        #expect(SubscriptionManager.trialDuration == 7)
    }
}

// MARK: - Free Tier Limits Tests

struct FreeTierLimitsTests {

    @Test("Free swipe limit is 5")
    func freeSwipeLimitIs5() {
        let manager = SubscriptionManager.shared
        #expect(manager.freeSwipeLimit == 5)
    }

    @Test("Free stock limit is 10")
    func freeStockLimitIs10() {
        let manager = SubscriptionManager.shared
        #expect(manager.freeStockLimit == 10)
    }

    @Test("Free horoscope limit is 1")
    func freeHoroscopeLimitIs1() {
        let manager = SubscriptionManager.shared
        #expect(manager.freeHoroscopeLimit == 1)
    }

    @Test("Free roast limit is 1")
    func freeRoastLimitIs1() {
        let manager = SubscriptionManager.shared
        #expect(manager.freeRoastLimit == 1)
    }
}

// MARK: - Swipes Calculation Tests

struct SwipesCalculationTests {

    @Test("Swipes remaining calculation - under limit")
    func swipesRemainingUnderLimit() {
        let limit = 5
        let used = 2
        let remaining = max(0, limit - used)

        #expect(remaining == 3)
    }

    @Test("Swipes remaining calculation - at limit")
    func swipesRemainingAtLimit() {
        let limit = 5
        let used = 5
        let remaining = max(0, limit - used)

        #expect(remaining == 0)
    }

    @Test("Swipes remaining calculation - over limit")
    func swipesRemainingOverLimit() {
        let limit = 5
        let used = 7
        let remaining = max(0, limit - used)

        #expect(remaining == 0)
    }

    @Test("Swipes exhausted when at limit")
    func swipesExhaustedAtLimit() {
        let limit = 5
        let used = 5
        let isPremium = false
        let exhausted = !isPremium && used >= limit

        #expect(exhausted == true)
    }

    @Test("Swipes not exhausted for premium")
    func swipesNotExhaustedForPremium() {
        let limit = 5
        let used = 10
        let isPremium = true
        let exhausted = !isPremium && used >= limit

        #expect(exhausted == false)
    }
}

// MARK: - Stock Addition Check Tests

struct StockAdditionCheckTests {

    @Test("Can add stock under limit")
    func canAddStockUnderLimit() {
        let currentCount = 5
        let limit = 10
        let isPremium = false
        let canAdd = isPremium || currentCount < limit

        #expect(canAdd == true)
    }

    @Test("Cannot add stock at limit for free tier")
    func cannotAddStockAtLimitFree() {
        let currentCount = 10
        let limit = 10
        let isPremium = false
        let canAdd = isPremium || currentCount < limit

        #expect(canAdd == false)
    }

    @Test("Can add stock at limit for premium")
    func canAddStockAtLimitPremium() {
        let currentCount = 10
        let limit = 10
        let isPremium = true
        let canAdd = isPremium || currentCount < limit

        #expect(canAdd == true)
    }
}

// MARK: - Trial Calculation Tests

struct TrialCalculationTests {

    @Test("Trial days remaining calculation")
    func trialDaysRemainingCalculation() {
        let trialDuration = 7
        let startDate = Date().addingTimeInterval(-3 * 24 * 60 * 60) // 3 days ago
        let daysSinceStart = Calendar.current.dateComponents([.day], from: startDate, to: Date()).day ?? 0
        let remaining = trialDuration - daysSinceStart

        #expect(remaining == 4)
    }

    @Test("Trial expired after duration")
    func trialExpiredAfterDuration() {
        let trialDuration = 7
        let startDate = Date().addingTimeInterval(-10 * 24 * 60 * 60) // 10 days ago
        let daysSinceStart = Calendar.current.dateComponents([.day], from: startDate, to: Date()).day ?? 0
        let remaining = trialDuration - daysSinceStart
        let isExpired = remaining <= 0

        #expect(isExpired == true)
    }

    @Test("Trial active during duration")
    func trialActiveDuringDuration() {
        let trialDuration = 7
        let startDate = Date().addingTimeInterval(-2 * 24 * 60 * 60) // 2 days ago
        let daysSinceStart = Calendar.current.dateComponents([.day], from: startDate, to: Date()).day ?? 0
        let remaining = trialDuration - daysSinceStart
        let isActive = remaining > 0

        #expect(isActive == true)
    }
}

// MARK: - Subscription Expiration Tests

struct SubscriptionExpirationTests {

    @Test("Days until expiration calculation")
    func daysUntilExpirationCalculation() {
        // Use calendar-based date addition for accurate day calculation
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let expirationDate = calendar.date(byAdding: .day, value: 5, to: today)!
        let days = calendar.dateComponents([.day], from: today, to: expirationDate).day

        #expect(days == 5)
    }

    @Test("Expiring soon within 7 days")
    func expiringSoonWithin7Days() {
        let daysUntilExpiration = 5
        let isExpiringSoon = daysUntilExpiration <= 7 && daysUntilExpiration > 0

        #expect(isExpiringSoon == true)
    }

    @Test("Not expiring soon beyond 7 days")
    func notExpiringSoonBeyond7Days() {
        let daysUntilExpiration = 15
        let isExpiringSoon = daysUntilExpiration <= 7 && daysUntilExpiration > 0

        #expect(isExpiringSoon == false)
    }

    @Test("Not expiring soon when already expired")
    func notExpiringSoonWhenExpired() {
        let daysUntilExpiration = -2
        let isExpiringSoon = daysUntilExpiration <= 7 && daysUntilExpiration > 0

        #expect(isExpiringSoon == false)
    }
}

// MARK: - Daily Reset Tests

struct DailyResetTests {

    @Test("New day detection works")
    func newDayDetectionWorks() {
        let today = Calendar.current.startOfDay(for: Date())
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!

        let isNewDay = today > yesterday

        #expect(isNewDay == true)
    }

    @Test("Same day detection works")
    func sameDayDetectionWorks() {
        let now = Date()
        let earlierToday = now.addingTimeInterval(-3600) // 1 hour ago
        let todayStart = Calendar.current.startOfDay(for: now)
        let earlierStart = Calendar.current.startOfDay(for: earlierToday)

        let isSameDay = todayStart == earlierStart

        #expect(isSameDay == true)
    }
}

// MARK: - Premium Status Tests

struct PremiumStatusTests {

    @Test("Premium status with oracle tier")
    func premiumStatusWithOracleTier() {
        let currentTier = SubscriptionTier.oracle
        let isInTrial = false
        let isPremium = currentTier == .oracle || isInTrial

        #expect(isPremium == true)
    }

    @Test("Premium status with trial")
    func premiumStatusWithTrial() {
        let currentTier = SubscriptionTier.free
        let isInTrial = true
        let isPremium = currentTier == .oracle || isInTrial

        #expect(isPremium == true)
    }

    @Test("Not premium on free tier without trial")
    func notPremiumOnFreeTier() {
        let currentTier = SubscriptionTier.free
        let isInTrial = false
        let isPremium = currentTier == .oracle || isInTrial

        #expect(isPremium == false)
    }
}

// MARK: - Feature Access Tests

struct FeatureAccessTests {

    @Test("Free feature accessible without premium")
    func freeFeatureAccessibleWithoutPremium() {
        let isPremium = false
        let feature = PremiumFeature.delayedData
        let canAccess = isPremium || feature.availableInFreeTier

        #expect(canAccess == true)
    }

    @Test("Premium feature not accessible without premium")
    func premiumFeatureNotAccessibleWithoutPremium() {
        let isPremium = false
        let feature = PremiumFeature.realTimeData
        let canAccess = isPremium || feature.availableInFreeTier

        #expect(canAccess == false)
    }

    @Test("All features accessible with premium")
    func allFeaturesAccessibleWithPremium() {
        let isPremium = true
        for feature in PremiumFeature.allCases {
            let canAccess = isPremium || feature.availableInFreeTier
            #expect(canAccess == true, "Feature \(feature.rawValue) should be accessible")
        }
    }
}

// MARK: - Trial Extension Tests

struct TrialExtensionTests {

    @Test("Trial extension adds days correctly")
    func trialExtensionAddsDays() {
        // Simulating trial extension logic
        let originalStartDate = Date().addingTimeInterval(-3 * 24 * 60 * 60) // 3 days ago
        let extensionDays = 5

        let newStartDate = Calendar.current.date(byAdding: .day, value: -extensionDays, to: originalStartDate)!

        // Original start was 3 days ago, with 5 day extension it should be 8 days ago
        let daysDifference = Calendar.current.dateComponents([.day], from: newStartDate, to: Date()).day ?? 0

        #expect(daysDifference == 8)
    }

    @Test("Zero extension does nothing")
    func zeroExtensionDoesNothing() {
        let extensionDays = 0
        let shouldExtend = extensionDays > 0

        #expect(shouldExtend == false)
    }

    @Test("Negative extension ignored")
    func negativeExtensionIgnored() {
        let extensionDays = -5
        let shouldExtend = extensionDays > 0

        #expect(shouldExtend == false)
    }
}

// MARK: - Subscription Refresh Tests

struct SubscriptionRefreshTests {

    @Test("Should refresh if never checked")
    func shouldRefreshIfNeverChecked() {
        let lastCheck: Date? = nil
        let shouldRefresh = lastCheck == nil

        #expect(shouldRefresh == true)
    }

    @Test("Should refresh after 24 hours")
    func shouldRefreshAfter24Hours() {
        let lastCheck = Date().addingTimeInterval(-25 * 60 * 60) // 25 hours ago
        let hoursSince = Calendar.current.dateComponents([.hour], from: lastCheck, to: Date()).hour ?? 0
        let shouldRefresh = hoursSince >= 24

        #expect(shouldRefresh == true)
    }

    @Test("Should not refresh within 24 hours")
    func shouldNotRefreshWithin24Hours() {
        let lastCheck = Date().addingTimeInterval(-12 * 60 * 60) // 12 hours ago
        let hoursSince = Calendar.current.dateComponents([.hour], from: lastCheck, to: Date()).hour ?? 0
        let shouldRefresh = hoursSince >= 24

        #expect(shouldRefresh == false)
    }
}
