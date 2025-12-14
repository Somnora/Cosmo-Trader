//
//  MixpanelProvider.swift
//  Cosmo Trader
//
//  Analytics provider implementing Mixpanel SDK integration.
//  Forwards all analytics events while ensuring no PII is collected.
//
//  NOTE: Mixpanel SDK is optional. If not installed, analytics will be no-op.
//

import Foundation
#if canImport(Mixpanel)
import Mixpanel
/// Type alias for Mixpanel values when SDK is available
typealias AnalyticsValue = MixpanelType
#else
/// Stub type for Mixpanel values when SDK is not available
protocol AnalyticsValue {}
extension String: AnalyticsValue {}
extension Int: AnalyticsValue {}
extension Double: AnalyticsValue {}
extension Bool: AnalyticsValue {}
extension Array: AnalyticsValue where Element: AnalyticsValue {}
extension Dictionary: AnalyticsValue where Key == String, Value: AnalyticsValue {}
#endif

// MARK: - Analytics Provider Protocol

/// Protocol for analytics providers to implement
protocol AnalyticsProvider {
    /// Initialize the provider with token
    func initialize(token: String)

    /// Track an event with optional properties
    func track(event: String, properties: [String: AnalyticsValue]?)

    /// Set user properties (super properties)
    func setSuperProperties(_ properties: [String: AnalyticsValue])

    /// Identify user with anonymous ID
    func identify(anonymousId: String)

    /// Reset user identity
    func reset()

    /// Set opt-out status
    func setOptOut(_ optOut: Bool)

    /// Check if opted out
    var isOptedOut: Bool { get }

    /// Flush events to server
    func flush()
}

// MARK: - Mixpanel Provider

/// Mixpanel implementation of AnalyticsProvider
/// Works as a no-op when Mixpanel SDK is not installed
final class MixpanelProvider: AnalyticsProvider {

    // MARK: - Singleton

    static let shared = MixpanelProvider()

    // MARK: - Properties

    private var isInitialized = false
    private var debugModeEnabled = false
    private var _isOptedOut = false

    var isOptedOut: Bool {
        return _isOptedOut
    }

    // MARK: - Initialization

    private init() {}

    /// Initialize Mixpanel with token from Secrets.plist
    func initialize(token: String) {
        guard !token.isEmpty, token != "YOUR_MIXPANEL_TOKEN" else {
            logDebug("Mixpanel token not configured. Analytics disabled.")
            return
        }

        #if canImport(Mixpanel)
        // Initialize Mixpanel
        Mixpanel.initialize(token: token, trackAutomaticEvents: false)

        // Configure for privacy
        Mixpanel.mainInstance().loggingEnabled = debugModeEnabled

        isInitialized = true
        logDebug("Mixpanel initialized successfully")

        // Set initial super properties
        setDefaultSuperProperties()
        #else
        logDebug("Mixpanel SDK not installed. Analytics will be logged locally only.")
        isInitialized = true
        #endif
    }

    /// Initialize from Secrets.plist
    func initializeFromSecrets() {
        guard let token = SecretsManager.mixpanelToken else {
            logDebug("Mixpanel token not found in Secrets.plist")
            return
        }
        initialize(token: token)
    }

    // MARK: - Event Tracking

    /// Track an event with optional properties
    func track(event: String, properties: [String: AnalyticsValue]?) {
        guard isInitialized, !_isOptedOut else { return }

        #if canImport(Mixpanel)
        // Sanitize properties to remove any potential PII
        if let props = properties as? [String: MixpanelType] {
            let sanitizedProps = sanitizeProperties(props)
            Mixpanel.mainInstance().track(event: event, properties: sanitizedProps)
        } else {
            Mixpanel.mainInstance().track(event: event)
        }
        #endif

        logDebug("Tracked: \(event) \(properties?.description ?? "{}")")
    }

    /// Track event from AnalyticsEvent and AnalyticsParameters
    func track(event: AnalyticsEvent, params: AnalyticsParameters?) {
        let properties = convertToAnalyticsValues(params?.dictionary)
        track(event: event.rawValue, properties: properties)
    }

    // MARK: - Super Properties

    /// Set super properties that are sent with every event
    func setSuperProperties(_ properties: [String: AnalyticsValue]) {
        guard isInitialized, !_isOptedOut else { return }

        #if canImport(Mixpanel)
        if let props = properties as? [String: MixpanelType] {
            let sanitized = sanitizeProperties(props)
            if let sanitizedProps = sanitized {
                Mixpanel.mainInstance().registerSuperProperties(sanitizedProps)
                logDebug("Super properties set: \(sanitizedProps)")
            }
        }
        #else
        logDebug("Super properties set: \(properties)")
        #endif
    }

    /// Set default super properties
    private func setDefaultSuperProperties() {
        let properties: [String: AnalyticsValue] = [
            "app_version": Bundle.main.appVersion,
            "build_number": Bundle.main.buildNumber,
            "device_type": deviceType,
            "os_version": osVersion,
            "platform": "iOS"
        ]
        setSuperProperties(properties)
    }

    /// Update super properties with user's sun sign
    func setSunSignProperty(_ sunSign: String) {
        setSuperProperties(["sun_sign": sunSign])
    }

    /// Update super properties with subscription status
    func setSubscriptionProperty(isPremium: Bool) {
        setSuperProperties(["is_premium": isPremium])
    }

    // MARK: - User Identification

    /// Identify user with anonymous ID (no PII)
    func identify(anonymousId: String) {
        guard isInitialized, !_isOptedOut else { return }

        #if canImport(Mixpanel)
        Mixpanel.mainInstance().identify(distinctId: anonymousId)
        #endif
        logDebug("User identified: \(anonymousId)")
    }

    /// Generate or retrieve anonymous user ID
    func getOrCreateAnonymousId() -> String {
        let key = "analytics_anonymous_id"

        if let existingId = UserDefaults.standard.string(forKey: key) {
            return existingId
        }

        // Generate new anonymous ID (UUID-based, no PII)
        let newId = UUID().uuidString
        UserDefaults.standard.set(newId, forKey: key)
        return newId
    }

    /// Reset user identity (for logout)
    func reset() {
        guard isInitialized else { return }

        #if canImport(Mixpanel)
        Mixpanel.mainInstance().reset()
        #endif
        logDebug("User identity reset")

        // Re-set default super properties
        setDefaultSuperProperties()
    }

    // MARK: - Opt-Out

    /// Set opt-out status for users who disable analytics
    func setOptOut(_ optOut: Bool) {
        _isOptedOut = optOut

        #if canImport(Mixpanel)
        if isInitialized {
            if optOut {
                Mixpanel.mainInstance().optOutTracking()
                logDebug("User opted out of analytics")
            } else {
                Mixpanel.mainInstance().optInTracking()
                logDebug("User opted in to analytics")
            }
        }
        #else
        logDebug("Opt-out set to: \(optOut)")
        #endif

        // Persist preference
        UserDefaults.standard.set(optOut, forKey: "analytics_opted_out")
    }

    /// Load opt-out preference from storage
    func loadOptOutPreference() {
        _isOptedOut = UserDefaults.standard.bool(forKey: "analytics_opted_out")
        #if canImport(Mixpanel)
        if _isOptedOut && isInitialized {
            Mixpanel.mainInstance().optOutTracking()
        }
        #endif
    }

    // MARK: - Debug Mode

    /// Enable or disable debug mode
    func setDebugMode(_ enabled: Bool) {
        debugModeEnabled = enabled

        #if canImport(Mixpanel)
        if isInitialized {
            Mixpanel.mainInstance().loggingEnabled = enabled
        }
        #endif

        logDebug("Debug mode: \(enabled ? "enabled" : "disabled")")
    }

    // MARK: - Flush

    /// Flush events to server immediately
    func flush() {
        guard isInitialized, !_isOptedOut else { return }
        #if canImport(Mixpanel)
        Mixpanel.mainInstance().flush()
        logDebug("Events flushed to server")
        #endif
    }

    // MARK: - User Profile Properties

    /// Set user profile properties (different from super properties)
    func setUserProfileProperties(_ properties: [String: AnalyticsValue]) {
        guard isInitialized, !_isOptedOut else { return }

        #if canImport(Mixpanel)
        if let props = properties as? [String: MixpanelType] {
            let sanitized = sanitizeProperties(props)
            if let sanitizedProps = sanitized {
                Mixpanel.mainInstance().people.set(properties: sanitizedProps)
                logDebug("User profile properties set: \(sanitizedProps)")
            }
        }
        #else
        logDebug("User profile properties set: \(properties)")
        #endif
    }

    /// Increment a user profile property
    func incrementUserProperty(_ property: String, by amount: Double = 1) {
        guard isInitialized, !_isOptedOut else { return }

        #if canImport(Mixpanel)
        Mixpanel.mainInstance().people.increment(property: property, by: amount)
        #endif
        logDebug("Incremented \(property) by \(amount)")
    }

    // MARK: - Time Tracking

    /// Start timing an event
    func timeEvent(_ event: String) {
        guard isInitialized, !_isOptedOut else { return }
        #if canImport(Mixpanel)
        Mixpanel.mainInstance().time(event: event)
        #endif
        logDebug("Started timing: \(event)")
    }

    // MARK: - Private Helpers

    #if canImport(Mixpanel)
    /// Sanitize properties to remove any potential PII
    private func sanitizeProperties(_ properties: [String: MixpanelType]?) -> [String: MixpanelType]? {
        guard var props = properties else { return nil }

        // List of keys that might contain PII - remove them
        let piiKeys = [
            "email", "name", "phone", "address", "user_name", "display_name",
            "first_name", "last_name", "birth_date", "birthdate", "dob",
            "ip_address", "ip", "location", "lat", "lon", "latitude", "longitude"
        ]

        for key in piiKeys {
            props.removeValue(forKey: key)
            props.removeValue(forKey: key.lowercased())
            props.removeValue(forKey: key.uppercased())
        }

        return props
    }
    #endif

    /// Convert dictionary values to AnalyticsValue
    private func convertToAnalyticsValues(_ dictionary: [String: Any]?) -> [String: AnalyticsValue]? {
        guard let dict = dictionary else { return nil }

        var result: [String: AnalyticsValue] = [:]

        for (key, value) in dict {
            if let stringValue = value as? String {
                result[key] = stringValue
            } else if let intValue = value as? Int {
                result[key] = intValue
            } else if let doubleValue = value as? Double {
                result[key] = doubleValue
            } else if let boolValue = value as? Bool {
                result[key] = boolValue
            } else {
                // Convert to string as fallback
                result[key] = String(describing: value)
            }
        }

        return result.isEmpty ? nil : result
    }

    /// Get device type string
    private var deviceType: String {
        #if targetEnvironment(simulator)
        return "Simulator"
        #else
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        return identifier
        #endif
    }

    /// Get OS version string
    private var osVersion: String {
        let version = ProcessInfo.processInfo.operatingSystemVersion
        return "\(version.majorVersion).\(version.minorVersion).\(version.patchVersion)"
    }

    /// Debug logging
    private func logDebug(_ message: String) {
        #if DEBUG
        if debugModeEnabled {
            print("📊 [Mixpanel] \(message)")
        }
        #endif
    }
}

// MARK: - Secrets Manager Extension

struct SecretsManager {

    /// Load Mixpanel token from Secrets.plist
    static var mixpanelToken: String? {
        guard let path = Bundle.main.path(forResource: "Secrets", ofType: "plist"),
              let dict = NSDictionary(contentsOfFile: path),
              let token = dict["MIXPANEL_TOKEN"] as? String else {
            return nil
        }
        return token
    }

    /// Load all secrets
    static var secrets: [String: Any]? {
        guard let path = Bundle.main.path(forResource: "Secrets", ofType: "plist"),
              let dict = NSDictionary(contentsOfFile: path) as? [String: Any] else {
            return nil
        }
        return dict
    }
}

// MARK: - Analytics Events Extension

extension MixpanelProvider {

    // MARK: - Predefined Event Tracking

    /// Track app opened with context
    func trackAppOpened() {
        track(event: "app_opened", properties: [
            "app_version": Bundle.main.appVersion,
            "build_number": Bundle.main.buildNumber
        ])
    }

    /// Track screen view
    func trackScreenView(_ screenName: String) {
        track(event: "screen_viewed", properties: [
            "screen_name": screenName
        ])
    }

    /// Track onboarding completion
    func trackOnboardingCompleted(sunSign: String) {
        track(event: "onboarding_completed", properties: [
            "sun_sign": sunSign
        ])

        // Also set as super property
        setSunSignProperty(sunSign)
    }

    /// Track subscription event
    func trackSubscription(event: String, tier: String, source: String) {
        track(event: event, properties: [
            "tier": tier,
            "source": source
        ])
    }

    /// Track feature usage
    func trackFeatureUsage(_ feature: String, properties: [String: AnalyticsValue]? = nil) {
        var props: [String: AnalyticsValue] = ["feature_name": feature]
        if let additional = properties {
            props.merge(additional) { _, new in new }
        }
        track(event: "feature_used", properties: props)
    }
}
