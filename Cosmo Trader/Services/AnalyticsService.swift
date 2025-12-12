import Foundation

// MARK: - Analytics Service
// ==========================
// Lightweight analytics tracking for app usage insights.
// Currently logs to console in debug mode.
// Ready for integration with Mixpanel, Amplitude, Firebase Analytics, etc.
//
// PRIVACY: No personally identifiable information is collected.
// All events are anonymous and focused on feature usage patterns.

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
    case onboardingCompleted = "onboarding_completed"
    case onboardingSkipped = "onboarding_skipped"
    case birthdateEntered = "birthdate_entered"

    // MARK: Navigation
    case tabSwitched = "tab_switched"
    case screenViewed = "screen_viewed"

    // MARK: Portfolio
    case stockAddedToPortfolio = "stock_added_to_portfolio"
    case stockRemovedFromPortfolio = "stock_removed_from_portfolio"
    case portfolioViewed = "portfolio_viewed"
    case stockDetailViewed = "stock_detail_viewed"

    // MARK: Discovery (Swipe)
    case stockSwiped = "stock_swiped"
    case stockLiked = "stock_liked"
    case stockSkipped = "stock_skipped"
    case discoverSessionStarted = "discover_session_started"

    // MARK: Cosmic Features
    case horoscopeViewed = "horoscope_viewed"
    case horoscopeRefreshed = "horoscope_refreshed"
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
    case subscriptionStarted = "subscription_started"
    case trialStarted = "trial_started"
    case subscriptionCancelled = "subscription_cancelled"
    case featureGated = "feature_gated"

    // MARK: Settings
    case settingsViewed = "settings_viewed"
    case notificationToggled = "notification_toggled"
    case privacyPolicyViewed = "privacy_policy_viewed"
    case termsViewed = "terms_viewed"
    case disclaimerViewed = "disclaimer_viewed"

    // MARK: Errors
    case apiError = "api_error"
    case networkError = "network_error"
    case errorDisplayed = "error_displayed"
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

    private var isEnabled: Bool = true
    private var sessionStartTime: Date?
    private var eventQueue: [(event: AnalyticsEvent, params: AnalyticsParameters?, timestamp: Date)] = []

    private init() {
        startSession()
    }

    // MARK: - Configuration

    func setEnabled(_ enabled: Bool) {
        isEnabled = enabled
        log("Analytics \(enabled ? "enabled" : "disabled")")
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
        guard isEnabled else { return }

        let timestamp = Date()

        // Queue event for batch processing (future implementation)
        eventQueue.append((event, params, timestamp))

        // Log to console in debug mode
        #if DEBUG
        logEvent(event, params: params, timestamp: timestamp)
        #endif

        // TODO: Send to analytics provider
        // sendToProvider(event: event, params: params)
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
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        let timeString = formatter.string(from: timestamp)

        var logMessage = "📊 [\(timeString)] \(event.rawValue)"
        if let params = params, !params.dictionary.isEmpty {
            let paramsString = params.dictionary.map { "\($0.key)=\($0.value)" }.joined(separator: ", ")
            logMessage += " {\(paramsString)}"
        }

        print(logMessage)
    }

    private func log(_ message: String) {
        #if DEBUG
        print("📊 Analytics: \(message)")
        #endif
    }

    // MARK: - Provider Integration (Future)

    // Placeholder for analytics provider integration
    // Uncomment and implement when adding Mixpanel, Amplitude, or Firebase

    /*
    private func sendToProvider(event: AnalyticsEvent, params: AnalyticsParameters?) {
        // Mixpanel example:
        // Mixpanel.mainInstance().track(event: event.rawValue, properties: params?.dictionary)

        // Amplitude example:
        // Amplitude.instance().logEvent(event.rawValue, withEventProperties: params?.dictionary)

        // Firebase example:
        // Analytics.logEvent(event.rawValue, parameters: params?.dictionary)
    }
    */
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
