//
//  APIConfig.swift
//  Cosmo Trader
//
//  Secure configuration loader for API keys and secrets.
//  Reads from xcconfig via Info.plist, with fallback to Secrets.plist.
//
//  USAGE:
//  ------
//  let key = APIConfig.finnhubKey
//  let baseURL = APIConfig.finnhubBaseURL
//
//  SETUP:
//  ------
//  1. Copy Secrets.xcconfig.sample to Secrets.xcconfig
//  2. Fill in your API keys
//  3. Secrets.xcconfig is gitignored - never committed

import Foundation

enum APIConfig {

    // MARK: - Environment

    /// Current app environment
    static var environment: AppEnvironment {
        AppEnvironment.current
    }

    /// Environment configuration
    static var config: EnvironmentConfig {
        EnvironmentConfig.shared
    }

    // MARK: - Finnhub API

    /// Finnhub API key for stock quotes
    /// Get yours at: https://finnhub.io
    static var finnhubKey: String {
        let key = config.finnhubAPIKey

        if key.isEmpty {
            #if DEBUG
            print("⚠️ Finnhub API key not configured.")
            print("   Set FINNHUB_API_KEY in Secrets.xcconfig or Secrets.plist")
            #endif
        }

        return key
    }

    /// Finnhub base URL (may vary by environment)
    static var finnhubBaseURL: String {
        environment.apiBaseURL
    }

    /// Check if Finnhub is properly configured
    static var isFinnhubConfigured: Bool {
        !finnhubKey.isEmpty
    }

    // MARK: - Mixpanel

    /// Mixpanel token for analytics
    static var mixpanelToken: String {
        config.mixpanelToken
    }

    /// Check if Mixpanel is configured
    static var isMixpanelConfigured: Bool {
        !mixpanelToken.isEmpty
    }

    // MARK: - Legacy Support

    /// Cached secrets dictionary (for backwards compatibility)
    private static var secrets: [String: Any] = {
        loadSecrets()
    }()

    /// Load secrets from plist file (legacy support)
    private static func loadSecrets() -> [String: Any] {
        guard let path = Bundle.main.path(forResource: "Secrets", ofType: "plist") else {
            return [:]
        }

        guard let dict = NSDictionary(contentsOfFile: path) as? [String: Any] else {
            return [:]
        }

        return dict
    }

    /// Reload secrets (useful for testing)
    static func reload() {
        secrets = loadSecrets()
    }

    // MARK: - Validation

    /// Validate all required API keys are present
    static func validateConfiguration() -> [String] {
        return config.missingKeys
    }

    /// Print configuration status (debug only)
    static func printStatus() {
        config.printStatus()
    }
}

// MARK: - URL Helpers

extension APIConfig {

    /// Build a Finnhub API URL with the API key
    static func finnhubURL(endpoint: String, params: [String: String] = [:]) -> URL? {
        var components = URLComponents(string: "\(finnhubBaseURL)/\(endpoint)")

        var queryItems = params.map { URLQueryItem(name: $0.key, value: $0.value) }
        queryItems.append(URLQueryItem(name: "token", value: finnhubKey))

        components?.queryItems = queryItems

        return components?.url
    }
}

// MARK: - Feature Flags

extension APIConfig {

    /// Whether analytics should be enabled for current environment
    static var analyticsEnabled: Bool {
        environment.analyticsEnabled
    }

    /// Whether crash reporting should be enabled
    static var crashReportingEnabled: Bool {
        environment.crashReportingEnabled
    }

    /// Whether to show debug UI
    static var showDebugUI: Bool {
        environment.showsDebugUI
    }

    /// Whether to use mock data
    static var useMockData: Bool {
        environment.useMockData
    }

    /// Whether verbose logging is enabled
    static var verboseLogging: Bool {
        environment.verboseLogging
    }
}
