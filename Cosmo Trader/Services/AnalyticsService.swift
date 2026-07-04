import Foundation

// MARK: - Analytics Service
// ==========================
// LOCAL-ONLY event recorder. No third-party SDK is linked in this build.
//
// PRIVACY (v1 stance):
// - Events stay in an in-memory queue and (in DEBUG) print to the console.
// - Nothing leaves the device.
// - The `setOptOut(_:)` hook clears the queue and stops further appends.
// - All identifiers used here (e.g. the local `analytics_anonymous_id`)
//   are device-local and not shared with any analytics vendor.
// - Method signatures forbid raw free-text inputs (search queries, error
//   `localizedDescription`s, etc.) so that if a tracking SDK is added in
//   the future, sensitive strings cannot accidentally be sent.

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
    case astroOverlayViewed = "astro_overlay_viewed"
    case astroOverlayToggled = "astro_overlay_toggled"
    case astroOverlayFilterChanged = "astro_overlay_filter_changed"
    case astroOverlayEventSelected = "astro_overlay_event_selected"
    case astroCorrelationSummaryViewed = "astro_correlation_summary_viewed"

    // MARK: Cosmic Roast (Viral Feature)
    case roastGenerated = "roast_generated"
    case roastShared = "roast_shared"
    case roastRegenerated = "roast_regenerated"
    case reportCardGenerated = "report_card_generated"
    case reportCardShared = "report_card_shared"

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

    /// Build a privacy-safe error payload. **Never** accepts
    /// `error.localizedDescription` or any free-text message — those can
    /// leak URLs, backend payloads, or user-entered text.
    static func error(
        domain: String,
        code: Int,
        screen: String? = nil,
        feature: String? = nil,
        networkStatus: String? = nil,
        isRetriable: Bool? = nil
    ) -> AnalyticsParameters {
        var params: [String: Any] = [
            "error_domain": domain,
            "error_code": code
        ]
        if let screen { params["screen"] = screen }
        if let feature { params["feature"] = feature }
        if let networkStatus { params["network_status"] = networkStatus }
        if let isRetriable { params["is_retriable"] = isRetriable }
        return AnalyticsParameters(params)
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

    /// Max events held in memory. Local-only; never transmitted.
    private let maxQueuedEvents = 500

    private init() {
        loadOptOutPreference()
    }

    // MARK: - Initialization

    func initialize() {
        // Local-only: nothing to wire up to a remote provider.
        #if DEBUG
        setDebugMode(true)
        #else
        setDebugMode(false)
        #endif

        startSession()
        log("Analytics initialized (local-only, v1)")
    }

    // MARK: - Configuration

    /// Enable or disable analytics
    func setEnabled(_ enabled: Bool) {
        isEnabled = enabled
        log("Analytics \(enabled ? "enabled" : "disabled")")
    }

    /// Set opt-out status for privacy-conscious users.
    /// Local-only means there is no remote service to inform; we simply
    /// clear the in-memory queue and stop accepting further events.
    func setOptOut(_ optOut: Bool) {
        isOptedOut = optOut
        UserDefaults.standard.set(optOut, forKey: "analytics_opted_out")

        if optOut {
            eventQueue.removeAll()
            log("User opted out of analytics — in-memory event queue cleared")
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

        // Local-only: append to in-memory queue and drop oldest if over cap.
        eventQueue.append((event, params, timestamp))
        if eventQueue.count > maxQueuedEvents {
            eventQueue.removeFirst(eventQueue.count - maxQueuedEvents)
        }

        // Log to console in debug mode only.
        #if DEBUG
        logEvent(event, params: params, timestamp: timestamp)
        #endif
    }

    // MARK: - Inspection (for tests)

    /// Snapshot of currently-buffered events. Local-only.
    var bufferedEvents: [(event: AnalyticsEvent, params: AnalyticsParameters?, timestamp: Date)] {
        eventQueue
    }

    /// Clear the in-memory event queue. Used by tests and on opt-out.
    func clearEventBuffer() {
        eventQueue.removeAll()
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

    /// Record an error event with **structured** fields only. Never accepts
    /// `error.localizedDescription` or other free-text strings — those can
    /// leak URLs, backend responses, or user-entered text.
    ///
    /// Call sites are expected to translate a domain `Error` into a domain
    /// string and a stable numeric code (see `NetworkError`-style enums).
    func trackError(
        domain: String,
        code: Int,
        screen: String? = nil,
        feature: String? = nil,
        networkStatus: String? = nil,
        isRetriable: Bool? = nil
    ) {
        track(.apiError, params: .error(
            domain: domain,
            code: code,
            screen: screen,
            feature: feature,
            networkStatus: networkStatus,
            isRetriable: isRetriable
        ))
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

    /// Flush is a no-op in v1 (local-only). Kept so existing call sites
    /// compile; if a tracking SDK is wired up later, this is where its
    /// flush hook would go.
    func flush() {}

    /// Reset on logout. With Path A (no tracking) there's nothing remote
    /// to reset, but we drop the in-memory queue so it can't leak across
    /// sessions on shared devices.
    func resetIdentity() {
        eventQueue.removeAll()
        log("Local analytics buffer cleared on identity reset")
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
    //
    // PRIVACY: Search analytics intentionally do NOT include the raw
    // free-text query. Only privacy-safe properties (length, result count,
    // selected symbol, etc.) are recorded.

    func trackSearchPerformed(
        queryLength: Int,
        resultCount: Int,
        searchSource: String
    ) {
        track(.searchPerformed, params: AnalyticsParameters([
            "query_length": max(0, queryLength),
            "result_count": max(0, resultCount),
            "had_results": resultCount > 0,
            "search_source": searchSource
        ]))
    }

    func trackSearchResultSelected(
        queryLength: Int,
        position: Int,
        selectedSymbol: String,
        assetType: String,
        searchSource: String
    ) {
        track(.searchResultSelected, params: AnalyticsParameters([
            "query_length": max(0, queryLength),
            "result_position": max(0, position),
            "selected_symbol": selectedSymbol,
            "asset_type": assetType,
            "search_source": searchSource
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

    func trackAstroOverlayViewed(symbol: String, timeframe: String) {
        track(.astroOverlayViewed, params: AnalyticsParameters([
            "stock_symbol": symbol,
            "timeframe": timeframe
        ]))
    }

    func trackAstroOverlayToggled(symbol: String, enabled: Bool) {
        track(.astroOverlayToggled, params: AnalyticsParameters([
            "stock_symbol": symbol,
            "enabled": enabled
        ]))
    }

    func trackAstroOverlayFilterChanged(symbol: String, filter: String, enabled: Bool) {
        track(.astroOverlayFilterChanged, params: AnalyticsParameters([
            "stock_symbol": symbol,
            "filter": filter,
            "enabled": enabled
        ]))
    }

    func trackAstroOverlayEventSelected(symbol: String, eventKind: String) {
        track(.astroOverlayEventSelected, params: AnalyticsParameters([
            "stock_symbol": symbol,
            "event_kind": eventKind
        ]))
    }

    func trackAstroCorrelationSummaryViewed(symbol: String, summaryKind: String) {
        track(.astroCorrelationSummaryViewed, params: AnalyticsParameters([
            "stock_symbol": symbol,
            "summary_kind": summaryKind
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

    /// Update local user-property snapshot. Nothing is transmitted —
    /// the snapshot only enriches in-DEBUG log output for `trackWithContext`.
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

 // Track error (structured fields only — never localizedDescription)
 AnalyticsService.shared.trackError(
     domain: "com.cosmotrader.NetworkError",
     code: 1001,
     screen: "Portfolio",
     feature: "refresh",
     networkStatus: "offline",
     isRetriable: true
 )

 // Track paywall
 AnalyticsService.shared.trackPaywallViewed(source: "cosmic_roast")
 */
