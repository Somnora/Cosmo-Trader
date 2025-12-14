//
//  CrashReportingService.swift
//  Cosmo Trader
//
//  Firebase Crashlytics integration for crash reporting and error tracking.
//  Ensures user privacy - no PII in crash reports.
//
//  NOTE: Firebase SDK is optional. If not installed, crash reporting will be no-op.
//

import Foundation
#if canImport(FirebaseCore)
import FirebaseCore
#endif
#if canImport(FirebaseCrashlytics)
import FirebaseCrashlytics
#endif

// MARK: - Crash Reporting Service

/// Service for managing crash reporting via Firebase Crashlytics
@MainActor
final class CrashReportingService {

    // MARK: - Singleton

    static let shared = CrashReportingService()

    // MARK: - Properties

    private var isInitialized = false
    private var isEnabled = true
    private var breadcrumbs: [Breadcrumb] = []
    private let maxBreadcrumbs = 100

    // MARK: - Initialization

    private init() {}

    /// Initialize Firebase and Crashlytics
    func initialize() {
        guard !isInitialized else { return }

        #if canImport(FirebaseCore) && canImport(FirebaseCrashlytics)
        // Check if GoogleService-Info.plist exists
        guard Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") != nil else {
            logDebug("GoogleService-Info.plist not found. Crashlytics disabled.")
            return
        }

        // Configure Firebase if not already configured
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }

        isInitialized = true

        // Set default custom keys
        setDefaultCustomKeys()

        logDebug("Crashlytics initialized successfully")
        #else
        logDebug("Firebase SDK not installed. Crash reporting disabled.")
        isInitialized = true
        #endif
    }

    // MARK: - Configuration

    /// Enable or disable crash reporting
    func setEnabled(_ enabled: Bool) {
        isEnabled = enabled
        #if canImport(FirebaseCrashlytics)
        Crashlytics.crashlytics().setCrashlyticsCollectionEnabled(enabled)
        #endif
        logDebug("Crashlytics collection \(enabled ? "enabled" : "disabled")")
    }

    /// Check if crash reporting is enabled
    var crashReportingEnabled: Bool {
        return isEnabled && isInitialized
    }

    // MARK: - Custom Keys

    /// Set default custom keys for debugging
    private func setDefaultCustomKeys() {
        guard isInitialized else { return }

        setCustomKey("app_version", value: Bundle.main.appVersion)
        setCustomKey("build_number", value: Bundle.main.buildNumber)
        setCustomKey("device_type", value: deviceType)
        setCustomKey("os_version", value: osVersion)
    }

    /// Set a custom key-value pair for crash reports
    func setCustomKey(_ key: String, value: String) {
        guard isInitialized, isEnabled else { return }
        #if canImport(FirebaseCrashlytics)
        Crashlytics.crashlytics().setCustomValue(value, forKey: key)
        #endif
    }

    /// Set a custom key with an integer value
    func setCustomKey(_ key: String, value: Int) {
        guard isInitialized, isEnabled else { return }
        #if canImport(FirebaseCrashlytics)
        Crashlytics.crashlytics().setCustomValue(value, forKey: key)
        #endif
    }

    /// Set a custom key with a boolean value
    func setCustomKey(_ key: String, value: Bool) {
        guard isInitialized, isEnabled else { return }
        #if canImport(FirebaseCrashlytics)
        Crashlytics.crashlytics().setCustomValue(value, forKey: key)
        #endif
    }

    /// Set multiple custom keys at once
    func setCustomKeys(_ keys: [String: Any]) {
        guard isInitialized, isEnabled else { return }
        #if canImport(FirebaseCrashlytics)
        Crashlytics.crashlytics().setCustomKeysAndValues(keys)
        #endif
    }

    // MARK: - User Context (Anonymous)

    /// Set anonymous user identifier (no PII)
    func setAnonymousUserId(_ anonymousId: String) {
        guard isInitialized, isEnabled else { return }
        #if canImport(FirebaseCrashlytics)
        Crashlytics.crashlytics().setUserID(anonymousId)
        #endif
    }

    /// Set user's sun sign for debugging
    func setUserSunSign(_ sunSign: String) {
        setCustomKey("user_sun_sign", value: sunSign)
    }

    /// Set user's premium status for debugging
    func setUserPremiumStatus(_ isPremium: Bool) {
        setCustomKey("is_premium", value: isPremium)
    }

    /// Set user's portfolio size for debugging
    func setPortfolioSize(_ size: Int) {
        setCustomKey("portfolio_size", value: size)
    }

    /// Update all user context at once
    func updateUserContext(sunSign: String?, isPremium: Bool, portfolioSize: Int) {
        if let sign = sunSign {
            setUserSunSign(sign)
        }
        setUserPremiumStatus(isPremium)
        setPortfolioSize(portfolioSize)
    }

    // MARK: - Error Recording

    /// Record a non-fatal error
    func recordError(_ error: Error, userInfo: [String: Any]? = nil) {
        guard isInitialized, isEnabled else { return }

        // Sanitize user info to remove any PII
        let sanitizedInfo = sanitizeUserInfo(userInfo)

        // Create NSError with domain and code
        let nsError: NSError
        if let networkError = error as? NetworkError {
            nsError = createNSError(from: networkError, userInfo: sanitizedInfo)
        } else if let dataError = error as? DataError {
            nsError = createNSError(from: dataError, userInfo: sanitizedInfo)
        } else if let validationError = error as? ValidationError {
            nsError = createNSError(from: validationError, userInfo: sanitizedInfo)
        } else if let appError = error as? AppError {
            nsError = createNSError(from: appError, userInfo: sanitizedInfo)
        } else {
            nsError = error as NSError
        }

        #if canImport(FirebaseCrashlytics)
        Crashlytics.crashlytics().record(error: nsError)
        #endif
        logDebug("Recorded error: \(nsError.domain) - \(nsError.code)")
    }

    /// Record an AppError
    func recordAppError(_ error: AppError) {
        recordError(error.underlyingError)
    }

    /// Record a NetworkError
    func recordNetworkError(_ error: NetworkError) {
        recordError(error, userInfo: [
            "error_type": "network",
            "is_retryable": error.isRetryable
        ])
    }

    /// Record a DataError
    func recordDataError(_ error: DataError) {
        recordError(error, userInfo: ["error_type": "data"])
    }

    /// Record a ValidationError
    func recordValidationError(_ error: ValidationError) {
        recordError(error, userInfo: ["error_type": "validation"])
    }

    // MARK: - Breadcrumbs

    /// Log a breadcrumb for navigation tracking
    func logBreadcrumb(_ message: String, category: BreadcrumbCategory = .navigation) {
        guard isInitialized, isEnabled else { return }

        let breadcrumb = Breadcrumb(message: message, category: category, timestamp: Date())

        // Add to local queue
        breadcrumbs.append(breadcrumb)
        if breadcrumbs.count > maxBreadcrumbs {
            breadcrumbs.removeFirst()
        }

        // Log to Crashlytics
        #if canImport(FirebaseCrashlytics)
        Crashlytics.crashlytics().log("\(category.prefix) \(message)")
        #endif
    }

    /// Log navigation breadcrumb
    func logNavigation(to screen: String, from previousScreen: String? = nil) {
        var message = "Navigated to \(screen)"
        if let previous = previousScreen {
            message += " from \(previous)"
        }
        logBreadcrumb(message, category: .navigation)
    }

    /// Log user action breadcrumb
    func logAction(_ action: String, on element: String? = nil) {
        var message = action
        if let element = element {
            message += " on \(element)"
        }
        logBreadcrumb(message, category: .userAction)
    }

    /// Log state change breadcrumb
    func logStateChange(_ change: String) {
        logBreadcrumb(change, category: .stateChange)
    }

    /// Log network breadcrumb
    func logNetworkEvent(_ event: String) {
        logBreadcrumb(event, category: .network)
    }

    /// Get recent breadcrumbs
    func getRecentBreadcrumbs(count: Int = 20) -> [Breadcrumb] {
        return Array(breadcrumbs.suffix(count))
    }

    // MARK: - Crash Testing (Debug Only)

    #if DEBUG
    /// Force a crash for testing (DEBUG ONLY)
    func forceCrash() {
        fatalError("Test crash triggered")
    }

    /// Force a test exception
    func forceTestException() {
        #if canImport(FirebaseCrashlytics)
        let exception = NSException(
            name: NSExceptionName("TestException"),
            reason: "This is a test exception",
            userInfo: nil
        )
        Crashlytics.crashlytics().record(exceptionModel:
            ExceptionModel(name: exception.name.rawValue, reason: exception.reason ?? "Unknown")
        )
        #endif
    }
    #endif

    // MARK: - Private Helpers

    /// Sanitize user info to remove any PII
    private func sanitizeUserInfo(_ userInfo: [String: Any]?) -> [String: Any] {
        guard var info = userInfo else { return [:] }

        // List of keys that might contain PII - remove them
        let piiKeys = [
            "email", "name", "phone", "address", "user_name", "display_name",
            "first_name", "last_name", "birth_date", "birthdate", "dob",
            "ip_address", "ip", "location", "lat", "lon", "latitude", "longitude",
            "password", "token", "api_key", "secret"
        ]

        for key in piiKeys {
            info.removeValue(forKey: key)
            info.removeValue(forKey: key.lowercased())
            info.removeValue(forKey: key.uppercased())
        }

        return info
    }

    /// Create NSError from NetworkError
    private func createNSError(from error: NetworkError, userInfo: [String: Any]) -> NSError {
        var info = userInfo
        info[NSLocalizedDescriptionKey] = error.errorDescription

        let code: Int
        switch error {
        case .noConnection: code = 1001
        case .timeout: code = 1002
        case .serverError(let statusCode): code = statusCode
        case .rateLimited: code = 429
        case .invalidResponse: code = 1003
        case .decodingError: code = 1004
        case .invalidSymbol: code = 1005
        case .apiKeyMissing: code = 1006
        case .unknown: code = 1099
        }

        return NSError(domain: "com.cosmotrader.NetworkError", code: code, userInfo: info)
    }

    /// Create NSError from DataError
    private func createNSError(from error: DataError, userInfo: [String: Any]) -> NSError {
        var info = userInfo
        info[NSLocalizedDescriptionKey] = error.errorDescription

        let code: Int
        switch error {
        case .corruptedData: code = 2001
        case .missingRequiredField: code = 2002
        case .encodingFailed: code = 2003
        case .decodingFailed: code = 2004
        case .storageFull: code = 2005
        case .invalidFormat: code = 2006
        }

        return NSError(domain: "com.cosmotrader.DataError", code: code, userInfo: info)
    }

    /// Create NSError from ValidationError
    private func createNSError(from error: ValidationError, userInfo: [String: Any]) -> NSError {
        var info = userInfo
        info[NSLocalizedDescriptionKey] = error.errorDescription

        let code: Int
        switch error {
        case .emptyName: code = 3001
        case .nameTooLong: code = 3002
        case .invalidCharacters: code = 3003
        case .futureBirthDate: code = 3004
        case .unreasonableBirthDate: code = 3005
        case .invalidSearchQuery: code = 3006
        case .invalidShareAmount: code = 3007
        }

        return NSError(domain: "com.cosmotrader.ValidationError", code: code, userInfo: info)
    }

    /// Create NSError from AppError
    private func createNSError(from error: AppError, userInfo: [String: Any]) -> NSError {
        switch error {
        case .network(let networkError):
            return createNSError(from: networkError, userInfo: userInfo)
        case .data(let dataError):
            return createNSError(from: dataError, userInfo: userInfo)
        case .validation(let validationError):
            return createNSError(from: validationError, userInfo: userInfo)
        }
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
        print("💥 [Crashlytics] \(message)")
        #endif
    }
}

// MARK: - Breadcrumb Types

/// Categories for breadcrumb logging
enum BreadcrumbCategory: String {
    case navigation = "navigation"
    case userAction = "user_action"
    case stateChange = "state_change"
    case network = "network"
    case error = "error"
    case lifecycle = "lifecycle"

    var prefix: String {
        switch self {
        case .navigation: return "🧭"
        case .userAction: return "👆"
        case .stateChange: return "🔄"
        case .network: return "🌐"
        case .error: return "❌"
        case .lifecycle: return "📱"
        }
    }
}

/// Breadcrumb data structure
struct Breadcrumb {
    let message: String
    let category: BreadcrumbCategory
    let timestamp: Date

    var formattedTimestamp: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter.string(from: timestamp)
    }
}

// MARK: - ErrorState Integration

extension ErrorState {

    /// Show an error and report to Crashlytics
    func showAndReport(_ error: AppError) {
        show(error)
        Task { @MainActor in
            CrashReportingService.shared.recordAppError(error)
        }
    }

    /// Show a network error and report to Crashlytics
    func showAndReportNetwork(_ error: NetworkError) {
        showNetwork(error)
        Task { @MainActor in
            CrashReportingService.shared.recordNetworkError(error)
        }
    }

    /// Show a data error and report to Crashlytics
    func showAndReportData(_ error: DataError) {
        showData(error)
        Task { @MainActor in
            CrashReportingService.shared.recordDataError(error)
        }
    }

    /// Show a validation error and report to Crashlytics
    func showAndReportValidation(_ error: ValidationError) {
        showValidation(error)
        Task { @MainActor in
            CrashReportingService.shared.recordValidationError(error)
        }
    }
}

// MARK: - Convenience Extensions

extension CrashReportingService {

    /// Log screen view breadcrumb
    func logScreenView(_ screenName: String) {
        logNavigation(to: screenName)
    }

    /// Log tab switch breadcrumb
    func logTabSwitch(to tabName: String) {
        logBreadcrumb("Switched to \(tabName) tab", category: .navigation)
    }

    /// Log app lifecycle event
    func logLifecycleEvent(_ event: String) {
        logBreadcrumb(event, category: .lifecycle)
    }

    /// Log when app enters background
    func logAppBackgrounded() {
        logLifecycleEvent("App entered background")
    }

    /// Log when app enters foreground
    func logAppForegrounded() {
        logLifecycleEvent("App entered foreground")
    }

    /// Log onboarding step
    func logOnboardingStep(_ step: String) {
        logBreadcrumb("Onboarding: \(step)", category: .stateChange)
    }

    /// Log subscription event
    func logSubscriptionEvent(_ event: String) {
        logBreadcrumb("Subscription: \(event)", category: .stateChange)
    }

    /// Log stock action
    func logStockAction(_ action: String, symbol: String) {
        logBreadcrumb("\(action): \(symbol)", category: .userAction)
    }
}
