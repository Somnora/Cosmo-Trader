import Foundation
#if canImport(Mixpanel)
import Mixpanel
#endif

// MARK: - Analytics Service
// ==========================
// Lightweight analytics tracking for app usage insights.
// Integrated with Mixpanel for production analytics.
//
// PRIVACY: No personally identifiable information is collected.
// All events are anonymous and focused on feature usage patterns.
// Users can opt-out of analytics tracking via settings.

// MARK: - Analytics Events

enum AnalyticsEvent: String {
    // MARK: App Lifecycle
    case appOpened = "app_opened"
    case appBackgrounded = "app_backgrounded"
    case appForegrounded = "app_foregrounded"
    case sessionStarted = "session_started"
    case sessionEnded = "session_ended"

    // MARK: Onboarding
    case onboardingStarted = "onboarding_started"
    case onboardingSignSelected = "onboarding_sign_selected"
    case onboardingDisclaimerAccepted = "onboarding_disclaimer_accepted"
    case onboardingNotificationsPrompted = "onboarding_notifications_prompted"
    case onboardingNotificationsGranted = "onboarding_notifications_granted"
    case onboardingNotificationsDenied = "onboarding_notifications_denied"
    case onboardingCompleted = "onboarding_completed"
    case onboardingSkipped = "onboarding_skipped"
    case onboardingAbandoned = "onboarding_abandoned"
    case birthdateEntered = "birthdate_entered"

    // MARK: Navigation
    case tabSwitched = "tab_switched"
    case screenViewed = "screen_viewed"

    // MARK: Portfolio
    case stockAddedToPortfolio = "stock_added_to_portfolio"
    case stockRemovedFromPortfolio = "stock_removed_from_portfolio"
    case watchlistAdded = "watchlist_added"
    case watchlistRemoved = "watchlist_removed"
    case portfolioViewed = "portfolio_viewed"
    case portfolioStockTapped = "portfolio_stock_tapped"
    case stockDetailViewed = "stock_detail_viewed"
    case stockShared = "stock_shared"
    case chartTimeframeChanged = "chart_timeframe_changed"

    // MARK: Discovery (Swipe)
    case stockSwiped = "stock_swiped"
    case stockLiked = "stock_liked"
    case stockSkipped = "stock_skipped"
    case discoveryCardViewed = "discovery_card_viewed"
    case discoverSessionStarted = "discover_session_started"
    case discoverDeckEmpty = "discover_deck_empty"
    case discoverDeckRefreshed = "discover_deck_refreshed"

    // MARK: Search
    case searchOpened = "search_opened"
    case searchPerformed = "search_performed"
    case searchResultSelected = "search_result_selected"

    // MARK: Cosmic Features
    case horoscopeViewed = "horoscope_viewed"
    case horoscopeRefreshed = "horoscope_refreshed"
    case horoscopeShared = "horoscope_shared"
    case compatibilityChecked = "compatibility_checked"
    case moonPhaseViewed = "moon_phase_viewed"

    // MARK: Cosmic Roast (Viral Feature)
    case roastGenerated = "roast_generated"
    case roastShared = "roast_shared"
    case roastRegenerated = "roast_regenerated"
    case reportCardGenerated = "report_card_generated"
    case reportCardShared = "report_card_shared"

    // MARK: IPO
    case ipoListViewed = "ipo_list_viewed"
    case ipoDetailViewed = "ipo_detail_viewed"
    case ipoCompatibilityViewed = "ipo_compatibility_viewed"

    // MARK: Subscription
    case paywallViewed = "paywall_viewed"
    case paywallDismissed = "paywall_dismissed"
    case subscriptionStarted = "subscription_started"
    case trialStarted = "trial_started"
    case subscriptionCancelled = "subscription_cancelled"
    case subscriptionRestored = "subscription_restored"
    case featureGated = "feature_gated"

    // MARK: Referral
    case referralCodeUsed = "referral_code_used"
    case referralCompleted = "referral_completed"
    case referralRewardRedeemed = "referral_reward_redeemed"
    case referralRewardApplied = "referral_reward_applied"

    // MARK: Settings
    case settingsViewed = "settings_viewed"
    case notificationToggled = "notification_toggled"
    case notificationSettingsChanged = "notification_settings_changed"
    case privacyPolicyViewed = "privacy_policy_viewed"
    case termsViewed = "terms_viewed"
    case disclaimerViewed = "disclaimer_viewed"

    // MARK: Notifications
    case notificationPermissionGranted = "notification_permission_granted"
    case notificationPermissionDenied = "notification_permission_denied"
    case notificationReceived = "notification_received"
    case notificationTapped = "notification_tapped"

    // MARK: GDPR / Privacy
    case dataExported = "data_exported"
    case dataDeleted = "data_deleted"
    case deleteDataRequested = "delete_data_requested"
    case deleteDataConfirmed = "delete_data_confirmed"
    case deleteDataCancelled = "delete_data_cancelled"

    // MARK: Errors
    case apiError = "api_error"
    case networkError = "network_error"
    case errorDisplayed = "error_displayed"
    case offlineDetected = "offline_detected"

    // MARK: Confluence Alerts
    case confluenceAlertSent = "confluence_alert_sent"

    // MARK: Cosmic Contrarian
    case cosmicContrarianEnabled = "cosmic_contrarian_enabled"
    case cosmicContrarianDisabled = "cosmic_contrarian_disabled"

    // MARK: Cosmic Obituary
    case cosmicObituaryAdded = "cosmic_obituary_added"
    case cosmicObituaryShared = "cosmic_obituary_shared"
    case cosmicObituaryViewed = "cosmic_obituary_viewed"

    // MARK: Cosmic Rival
    case cosmicRivalViewed = "cosmic_rival_viewed"

    // MARK: Cosmic Ticker
    case cosmicTickerViewed = "cosmic_ticker_viewed"

    // MARK: Daily Ritual
    case dailyRitualStarted = "daily_ritual_started"
    case dailyRitualCompleted = "daily_ritual_completed"
    case dailyRitualStepViewed = "daily_ritual_step_viewed"

    // MARK: Earnings Calendar
    case earningsCalendarViewed = "earnings_calendar_viewed"
    case earningsHoroscopeViewed = "earnings_horoscope_viewed"
    case earningsStockSelected = "earnings_stock_selected"

    // MARK: Karmic Ledger
    case karmicLedgerViewed = "karmic_ledger_viewed"
    case karmicLessonRecorded = "karmic_lesson_recorded"
    case karmicWisdomViewed = "karmic_wisdom_viewed"

    // MARK: Mercury Retrograde
    case mercuryRetrogradeViewed = "mercury_retrograde_viewed"

    // MARK: Notifications (Extended)
    case notificationOpened = "notification_opened"
    case testNotificationSent = "test_notification_sent"

    // MARK: On This Day
    case onThisDayViewed = "on_this_day_viewed"
    case onThisDayShared = "on_this_day_shared"

    // MARK: Portfolio Ascendant
    case portfolioAscendantViewed = "portfolio_ascendant_viewed"
    case portfolioAscendantShared = "portfolio_ascendant_shared"
    case portfolioMilestoneReached = "portfolio_milestone_reached"
    case portfolioTensionViewed = "portfolio_tension_viewed"

    // MARK: Referral (Extended)
    case referralShareTapped = "referral_share_tapped"

    // MARK: Saturn Return
    case saturnReturnViewed = "saturn_return_viewed"
    case saturnReturnAlertTapped = "saturn_return_alert_tapped"

    // MARK: Sign Season
    case signSeasonViewed = "sign_season_viewed"
    case signSeasonSpotlightTapped = "sign_season_spotlight_tapped"
    case signSeasonHoroscopeViewed = "sign_season_horoscope_viewed"

    // MARK: Sign Stack
    case signStackGenerated = "sign_stack_generated"
    case signStackShared = "sign_stack_shared"

    // MARK: Terminal Audio
    case terminalAudioEnabled = "terminal_audio_enabled"
    case terminalAudioDisabled = "terminal_audio_disabled"

    // MARK: Void of Course
    case vocDetailViewed = "voc_detail_viewed"
    case vocWarningViewed = "voc_warning_viewed"
    case vocWarningDismissed = "voc_warning_dismissed"
}

// MARK: - Event Parameters

struct AnalyticsParameters {
    var dictionary: [String: Any]

    init(_ params: [String: Any] = [:]) {
        self.dictionary = params
    }

    // Common parameter builders
    static func tab(_ tabName: String) -> AnalyticsParameters {
        AnalyticsParameters(["tab_name": tabName])
    }

    static func screen(_ screenName: String) -> AnalyticsParameters {
        AnalyticsParameters(["screen_name": screenName])
    }

    static func stock(_ symbol: String, sign: String? = nil) -> AnalyticsParameters {
        var params: [String: Any] = ["stock_symbol": symbol]
        if let sign = sign {
            params["zodiac_sign"] = sign
        }
        return AnalyticsParameters(params)
    }

    static func swipe(direction: String, symbol: String) -> AnalyticsParameters {
        AnalyticsParameters([
            "swipe_direction": direction,
            "stock_symbol": symbol
        ])
    }

    static func subscription(tier: String, source: String) -> AnalyticsParameters {
        AnalyticsParameters([
            "subscription_tier": tier,
            "source": source
        ])
    }

    static func error(type: String, message: String) -> AnalyticsParameters {
        AnalyticsParameters([
            "error_type": type,
            "error_message": message
        ])
    }

    static func feature(_ featureName: String) -> AnalyticsParameters {
        AnalyticsParameters(["feature_name": featureName])
    }
}

// MARK: - Analytics Service

@MainActor
final class AnalyticsService {

    static let shared = AnalyticsService()

    // MARK: - Properties

    private var isEnabled: Bool = true
    private var isOptedOut: Bool = false
    private var debugModeEnabled: Bool = false
    private var sessionStartTime: Date?
    private var eventQueue: [(event: AnalyticsEvent, params: AnalyticsParameters?, timestamp: Date)] = []
    private var anonymousId: String?

    /// The Mixpanel provider instance
    private let provider = MixpanelProvider.shared

    private init() {
        loadOptOutPreference()
    }

    // MARK: - Initialization

    /// Initialize analytics with Mixpanel token from Secrets.plist
    func initialize() {
        provider.initializeFromSecrets()
        provider.loadOptOutPreference()

        // Generate and set anonymous ID
        anonymousId = provider.getOrCreateAnonymousId()
        if let anonId = anonymousId {
            provider.identify(anonymousId: anonId)
        }

        // Set debug mode based on build configuration
        #if DEBUG
        setDebugMode(true)
        #else
        setDebugMode(false)
        #endif

        startSession()
        log("Analytics initialized")
    }

    // MARK: - Configuration

    /// Enable or disable analytics
    func setEnabled(_ enabled: Bool) {
        isEnabled = enabled
        log("Analytics \(enabled ? "enabled" : "disabled")")
    }

    /// Set opt-out status for privacy-conscious users
    func setOptOut(_ optOut: Bool) {
        isOptedOut = optOut
        provider.setOptOut(optOut)
        UserDefaults.standard.set(optOut, forKey: "analytics_opted_out")

        if optOut {
            log("User opted out of analytics tracking")
        } else {
            log("User opted in to analytics tracking")
        }
    }

    /// Check if user has opted out
    var hasOptedOut: Bool {
        return isOptedOut
    }

    /// Load opt-out preference from storage
    private func loadOptOutPreference() {
        isOptedOut = UserDefaults.standard.bool(forKey: "analytics_opted_out")
    }

    /// Enable or disable debug mode for development
    func setDebugMode(_ enabled: Bool) {
        debugModeEnabled = enabled
        provider.setDebugMode(enabled)
        log("Debug mode \(enabled ? "enabled" : "disabled")")
    }

    /// Check if debug mode is enabled
    var isDebugMode: Bool {
        return debugModeEnabled
    }

    // MARK: - Session Management

    func startSession() {
        sessionStartTime = Date()
        track(.sessionStarted)
    }

    func endSession() {
        if let start = sessionStartTime {
            let duration = Date().timeIntervalSince(start)
            track(.sessionEnded, params: AnalyticsParameters(["session_duration_seconds": Int(duration)]))
        }
        sessionStartTime = nil
    }

    // MARK: - Event Tracking

    func track(_ event: AnalyticsEvent, params: AnalyticsParameters? = nil) {
        guard isEnabled, !isOptedOut else { return }

        let timestamp = Date()

        // Queue event for batch processing (future implementation)
        eventQueue.append((event, params, timestamp))

        // Log to console in debug mode
        #if DEBUG
        logEvent(event, params: params, timestamp: timestamp)
        #endif

        // Send to analytics provider
        sendToProvider(event: event, params: params)
    }

    // MARK: - Convenience Methods

    func trackScreenView(_ screenName: String) {
        track(.screenViewed, params: .screen(screenName))
    }

    func trackTabSwitch(_ tabName: String) {
        track(.tabSwitched, params: .tab(tabName))
    }

    func trackStockAction(_ action: AnalyticsEvent, symbol: String, sign: String? = nil) {
        track(action, params: .stock(symbol, sign: sign))
    }

    func trackError(_ error: Error, type: String = "unknown") {
        track(.apiError, params: .error(type: type, message: error.localizedDescription))
    }

    // MARK: - Private Helpers

    private func logEvent(_ event: AnalyticsEvent, params: AnalyticsParameters?, timestamp: Date) {
        #if DEBUG
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        let timeString = formatter.string(from: timestamp)

        var logMessage = "📊 [\(timeString)] \(event.rawValue)"
        if let params = params, !params.dictionary.isEmpty {
            let paramsString = params.dictionary.map { "\($0.key)=\($0.value)" }.joined(separator: ", ")
            logMessage += " {\(paramsString)}"
        }

        print(logMessage)
        #endif
    }

    private func log(_ message: String) {
        #if DEBUG
        print("📊 Analytics: \(message)")
        #endif
    }

    // MARK: - Provider Integration

    /// Send event to Mixpanel analytics provider
    private func sendToProvider(event: AnalyticsEvent, params: AnalyticsParameters?) {
        provider.track(event: event, params: params)
    }

    /// Flush events to server immediately
    func flush() {
        provider.flush()
    }

    /// Reset user identity (call on logout)
    func resetIdentity() {
        provider.reset()
        anonymousId = provider.getOrCreateAnonymousId()
        if let anonId = anonymousId {
            provider.identify(anonymousId: anonId)
        }
        log("User identity reset")
    }

    // MARK: - Super Properties

    /// Set super properties that are sent with every event
    func setSuperProperties(_ properties: [String: Any]) {
        var analyticsProps: [String: AnalyticsValue] = [:]
        for (key, value) in properties {
            if let stringValue = value as? String {
                analyticsProps[key] = stringValue
            } else if let intValue = value as? Int {
                analyticsProps[key] = intValue
            } else if let doubleValue = value as? Double {
                analyticsProps[key] = doubleValue
            } else if let boolValue = value as? Bool {
                analyticsProps[key] = boolValue
            }
        }
        provider.setSuperProperties(analyticsProps)
    }

    /// Set default super properties based on app state
    func setDefaultSuperProperties(sunSign: String?, isPremium: Bool) {
        var properties: [String: AnalyticsValue] = [
            "app_version": Bundle.main.appVersion,
            "build_number": Bundle.main.buildNumber,
            "is_premium": isPremium
        ]
        if let sign = sunSign {
            properties["sun_sign"] = sign
        }
        provider.setSuperProperties(properties)
    }
}

// MARK: - Analytics Extensions

extension AnalyticsService {

    // MARK: Predefined Event Helpers

    func trackAppOpened() {
        track(.appOpened, params: AnalyticsParameters([
            "app_version": Bundle.main.appVersion,
            "build_number": Bundle.main.buildNumber
        ]))
    }

    func trackRoastGenerated(forSign sign: String) {
        track(.roastGenerated, params: AnalyticsParameters(["user_sign": sign]))
    }

    func trackRoastShared(forSign sign: String) {
        track(.roastShared, params: AnalyticsParameters(["user_sign": sign]))
    }

    func trackPaywallViewed(source: String) {
        track(.paywallViewed, params: AnalyticsParameters(["source": source]))
    }

    func trackFeatureGated(_ feature: String) {
        track(.featureGated, params: .feature(feature))
    }

    // MARK: - Onboarding Tracking

    func trackOnboardingStarted() {
        track(.onboardingStarted)
    }

    func trackOnboardingCompleted(sunSign: String) {
        track(.onboardingCompleted, params: AnalyticsParameters([
            "sun_sign": sunSign
        ]))
    }

    func trackOnboardingAbandoned(atStep step: String) {
        track(.onboardingAbandoned, params: AnalyticsParameters([
            "abandoned_at_step": step
        ]))
    }

    func trackBirthdateEntered(sunSign: String) {
        track(.birthdateEntered, params: AnalyticsParameters([
            "sun_sign": sunSign
        ]))
    }

    // MARK: - Discovery Tracking

    func trackDiscoverySwipe(direction: String, symbol: String, zodiacSign: String, compatibility: Int) {
        track(.stockSwiped, params: AnalyticsParameters([
            "swipe_direction": direction,
            "stock_symbol": symbol,
            "stock_zodiac_sign": zodiacSign,
            "compatibility_score": compatibility
        ]))
    }

    func trackDiscoveryCardViewed(symbol: String, zodiacSign: String) {
        track(.discoveryCardViewed, params: AnalyticsParameters([
            "stock_symbol": symbol,
            "stock_zodiac_sign": zodiacSign
        ]))
    }

    // MARK: - Search Tracking

    func trackSearch(query: String, resultCount: Int) {
        track(.searchPerformed, params: AnalyticsParameters([
            "search_query": query,
            "result_count": resultCount
        ]))
    }

    func trackSearchResultSelected(query: String, symbol: String, position: Int) {
        track(.searchResultSelected, params: AnalyticsParameters([
            "search_query": query,
            "stock_symbol": symbol,
            "result_position": position
        ]))
    }

    // MARK: - Portfolio Tracking

    func trackStockAddedToPortfolio(symbol: String, zodiacSign: String, source: String) {
        track(.stockAddedToPortfolio, params: AnalyticsParameters([
            "stock_symbol": symbol,
            "stock_zodiac_sign": zodiacSign,
            "source": source
        ]))
    }

    func trackStockRemovedFromPortfolio(symbol: String) {
        track(.stockRemovedFromPortfolio, params: AnalyticsParameters([
            "stock_symbol": symbol
        ]))
    }

    func trackWatchlistAdded(symbol: String, source: String) {
        track(.watchlistAdded, params: AnalyticsParameters([
            "stock_symbol": symbol,
            "source": source
        ]))
    }

    func trackWatchlistRemoved(symbol: String) {
        track(.watchlistRemoved, params: AnalyticsParameters([
            "stock_symbol": symbol
        ]))
    }

    // MARK: - Stock Detail Tracking

    func trackStockDetailOpened(symbol: String, source: String) {
        track(.stockDetailViewed, params: AnalyticsParameters([
            "stock_symbol": symbol,
            "source": source
        ]))
    }

    // MARK: - Cosmic Features Tracking

    func trackHoroscopeViewed(sunSign: String) {
        track(.horoscopeViewed, params: AnalyticsParameters([
            "sun_sign": sunSign
        ]))
    }

    func trackHoroscopeRefreshed(sunSign: String) {
        track(.horoscopeRefreshed, params: AnalyticsParameters([
            "sun_sign": sunSign
        ]))
    }

    func trackMoonPhaseViewed(phase: String) {
        track(.moonPhaseViewed, params: AnalyticsParameters([
            "moon_phase": phase
        ]))
    }

    // MARK: - IPO Tracking

    func trackIPOListViewed() {
        track(.ipoListViewed)
    }

    func trackIPODetailViewed(ticker: String, zodiacSign: String) {
        track(.ipoDetailViewed, params: AnalyticsParameters([
            "ipo_ticker": ticker,
            "ipo_zodiac_sign": zodiacSign
        ]))
    }

    // MARK: - Subscription Tracking

    func trackPaywallDismissed(source: String) {
        track(.paywallDismissed, params: AnalyticsParameters([
            "source": source
        ]))
    }

    func trackSubscriptionStarted(tier: String, source: String, trialEnabled: Bool) {
        track(.subscriptionStarted, params: AnalyticsParameters([
            "tier": tier,
            "source": source,
            "trial_enabled": trialEnabled
        ]))
    }

    func trackTrialStarted(source: String) {
        track(.trialStarted, params: AnalyticsParameters([
            "source": source
        ]))
    }

    func trackSubscriptionRestored() {
        track(.subscriptionRestored)
    }

    // MARK: - Additional Event Tracking

    func trackOnboardingSignSelected(sign: String, method: String) {
        track(.onboardingSignSelected, params: AnalyticsParameters([
            "sign": sign,
            "method": method
        ]))
    }

    func trackOnboardingDisclaimerAccepted() {
        track(.onboardingDisclaimerAccepted)
    }

    func trackOnboardingNotificationsPrompted() {
        track(.onboardingNotificationsPrompted)
    }

    func trackOnboardingNotificationsResult(granted: Bool) {
        track(granted ? .onboardingNotificationsGranted : .onboardingNotificationsDenied)
    }

    func trackDiscoverDeckEmpty() {
        track(.discoverDeckEmpty)
    }

    func trackDiscoverDeckRefreshed(cardCount: Int) {
        track(.discoverDeckRefreshed, params: AnalyticsParameters([
            "card_count": cardCount
        ]))
    }

    func trackSearchOpened() {
        track(.searchOpened)
    }

    func trackStockShared(symbol: String) {
        track(.stockShared, params: AnalyticsParameters([
            "stock_symbol": symbol
        ]))
    }

    func trackChartTimeframeChanged(symbol: String, timeframe: String) {
        track(.chartTimeframeChanged, params: AnalyticsParameters([
            "stock_symbol": symbol,
            "timeframe": timeframe
        ]))
    }

    func trackHoroscopeShared(sunSign: String) {
        track(.horoscopeShared, params: AnalyticsParameters([
            "sun_sign": sunSign
        ]))
    }

    func trackPortfolioStockTapped(symbol: String) {
        track(.portfolioStockTapped, params: AnalyticsParameters([
            "stock_symbol": symbol
        ]))
    }

    func trackNotificationPermissionResult(granted: Bool) {
        track(granted ? .notificationPermissionGranted : .notificationPermissionDenied)
    }

    func trackNotificationReceived(type: String) {
        track(.notificationReceived, params: AnalyticsParameters([
            "notification_type": type
        ]))
    }

    func trackNotificationTapped(type: String, symbol: String? = nil) {
        var params: [String: Any] = ["notification_type": type]
        if let symbol = symbol {
            params["stock_symbol"] = symbol
        }
        track(.notificationTapped, params: AnalyticsParameters(params))
    }

    func trackNotificationSettingsChanged(setting: String, enabled: Bool) {
        track(.notificationSettingsChanged, params: AnalyticsParameters([
            "setting": setting,
            "enabled": enabled
        ]))
    }

    func trackOfflineDetected() {
        track(.offlineDetected)
    }

    func trackPortfolioViewed(stockCount: Int, totalValue: Double) {
        track(.portfolioViewed, params: AnalyticsParameters([
            "stock_count": stockCount,
            "total_value": totalValue
        ]))
    }
}

// MARK: - User Properties

struct AnalyticsUserProperties {
    var sunSign: String?
    var portfolioSize: Int = 0
    var accountAgeDays: Int = 0
    var isPremium: Bool = false
    var appVersion: String = Bundle.main.appVersion
    var deviceType: String = "iPhone"

    var dictionary: [String: Any] {
        var props: [String: Any] = [
            "portfolio_size": portfolioSize,
            "account_age_days": accountAgeDays,
            "is_premium": isPremium,
            "app_version": appVersion,
            "device_type": deviceType
        ]
        if let sign = sunSign {
            props["sun_sign"] = sign
        }
        return props
    }
}

extension AnalyticsService {

    // MARK: - User Properties

    /// Current user properties (cached)
    private static var _userProperties = AnalyticsUserProperties()

    /// Get current user properties
    var userProperties: AnalyticsUserProperties {
        Self._userProperties
    }

    /// Update user properties
    func setUserProperties(
        sunSign: String? = nil,
        portfolioSize: Int? = nil,
        accountAgeDays: Int? = nil,
        isPremium: Bool? = nil
    ) {
        if let sign = sunSign {
            Self._userProperties.sunSign = sign
        }
        if let size = portfolioSize {
            Self._userProperties.portfolioSize = size
        }
        if let days = accountAgeDays {
            Self._userProperties.accountAgeDays = days
        }
        if let premium = isPremium {
            Self._userProperties.isPremium = premium
        }

        #if DEBUG
        log("User properties updated: \(Self._userProperties.dictionary)")
        #endif

        // Send to analytics provider
        sendUserPropertiesToProvider(Self._userProperties)
    }

    /// Send user properties to analytics provider
    private func sendUserPropertiesToProvider(_ properties: AnalyticsUserProperties) {
        var analyticsProps: [String: AnalyticsValue] = [
            "portfolio_size": properties.portfolioSize,
            "account_age_days": properties.accountAgeDays,
            "is_premium": properties.isPremium,
            "app_version": properties.appVersion,
            "device_type": properties.deviceType
        ]
        if let sign = properties.sunSign {
            analyticsProps["sun_sign"] = sign
        }
        provider.setUserProfileProperties(analyticsProps)
    }

    /// Refresh user properties from current app state
    func refreshUserProperties(from appState: AppState) {
        guard let user = appState.currentUser else { return }

        let calendar = Calendar.current
        let accountAge = calendar.dateComponents([.day], from: user.memberSince, to: Date()).day ?? 0

        setUserProperties(
            sunSign: user.sunSign.displayName,
            portfolioSize: user.portfolio.count,
            accountAgeDays: accountAge,
            isPremium: SubscriptionManager.shared.isPremium
        )
    }

    // MARK: - Enhanced Tracking with Context

    /// Track event with automatic user context
    func trackWithContext(_ event: AnalyticsEvent, params: AnalyticsParameters? = nil) {
        var enrichedParams = params?.dictionary ?? [:]

        // Add user context
        enrichedParams["user_sun_sign"] = Self._userProperties.sunSign ?? "unknown"
        enrichedParams["is_premium"] = Self._userProperties.isPremium

        track(event, params: AnalyticsParameters(enrichedParams))
    }
}

// MARK: - Bundle Extension

extension Bundle {
    var appVersion: String {
        infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"
    }

    var buildNumber: String {
        infoDictionary?["CFBundleVersion"] as? String ?? "0"
    }
}

// MARK: - Usage Examples
/*
 // Track app opened
 AnalyticsService.shared.trackAppOpened()

 // Track tab switch
 AnalyticsService.shared.trackTabSwitch("Portfolio")

 // Track screen view
 AnalyticsService.shared.trackScreenView("StockDetail")

 // Track stock added to portfolio
 AnalyticsService.shared.track(.stockAddedToPortfolio, params: .stock("AAPL", sign: "Aries"))

 // Track swipe
 AnalyticsService.shared.track(.stockSwiped, params: .swipe(direction: "right", symbol: "TSLA"))

 // Track roast generated and shared
 AnalyticsService.shared.trackRoastGenerated(forSign: "Leo")
 AnalyticsService.shared.trackRoastShared(forSign: "Leo")

 // Track error
 AnalyticsService.shared.trackError(someError, type: "network")

 // Track paywall
 AnalyticsService.shared.trackPaywallViewed(source: "cosmic_roast")
 */
