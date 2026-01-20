//
//  AppEnvironment.swift
//  Cosmo Trader
//
//  Environment configuration for development, staging, and production builds.
//  Reads from Info.plist values set via xcconfig files.
//

import Foundation
import SwiftUI

// MARK: - App Environment

/// Represents the different build environments
enum AppEnvironment: String, CaseIterable {
    case development = "development"
    case staging = "staging"
    case production = "production"

    // MARK: - Current Environment

    /// The current app environment, determined by build configuration
    static var current: AppEnvironment {
        guard let environmentString = Bundle.main.infoDictionary?["APP_ENVIRONMENT"] as? String else {
            #if DEBUG
            return .development
            #else
            return .production
            #endif
        }

        return AppEnvironment(rawValue: environmentString.lowercased()) ?? .production
    }

    // MARK: - Properties

    /// Display name for the environment
    var displayName: String {
        switch self {
        case .development:
            return "Development"
        case .staging:
            return "Staging"
        case .production:
            return "Production"
        }
    }

    /// Short name for badges/indicators
    var shortName: String {
        switch self {
        case .development:
            return "DEV"
        case .staging:
            return "STG"
        case .production:
            return "PROD"
        }
    }

    /// Color associated with the environment
    var color: Color {
        switch self {
        case .development:
            return .orange
        case .staging:
            return .purple
        case .production:
            return .green
        }
    }

    /// Whether this is a debug environment
    var isDebug: Bool {
        self == .development
    }

    /// Whether this is a production environment
    var isProduction: Bool {
        self == .production
    }

    /// Whether to show debug UI elements
    var showsDebugUI: Bool {
        self != .production
    }

    /// Whether to enable verbose logging
    var verboseLogging: Bool {
        self == .development
    }

    // MARK: - API Configuration

    /// Base URL for API requests (if different per environment)
    var apiBaseURL: String {
        switch self {
        case .development:
            return "https://finnhub.io/api/v1"
        case .staging:
            return "https://finnhub.io/api/v1"
        case .production:
            return "https://finnhub.io/api/v1"
        }
    }

    // MARK: - Feature Flags

    /// Whether analytics should be enabled
    var analyticsEnabled: Bool {
        switch self {
        case .development:
            return false // Don't pollute analytics with dev data
        case .staging:
            return true
        case .production:
            return true
        }
    }

    /// Whether crash reporting should be enabled
    var crashReportingEnabled: Bool {
        switch self {
        case .development:
            return false
        case .staging:
            return true
        case .production:
            return true
        }
    }

    /// Whether to use mock data
    var useMockData: Bool {
        self == .development
    }
}

// MARK: - Environment Keys

/// Keys for reading environment configuration from Info.plist
enum EnvironmentKey: String {
    case environment = "APP_ENVIRONMENT"
    case finnhubAPIKey = "FINNHUB_API_KEY"
    case mixpanelToken = "MIXPANEL_TOKEN"
    case bundleDisplayName = "CFBundleDisplayName"
    case bundleIdentifier = "CFBundleIdentifier"

    /// Read value from Info.plist
    var value: String? {
        Bundle.main.infoDictionary?[rawValue] as? String
    }
}

// MARK: - Environment Configuration

/// Centralized configuration that reads from xcconfig via Info.plist
struct EnvironmentConfig {

    // MARK: - Singleton

    static let shared = EnvironmentConfig()

    // MARK: - Properties

    /// Current environment
    let environment: AppEnvironment

    /// Finnhub API key
    let finnhubAPIKey: String

    /// Mixpanel token
    let mixpanelToken: String

    /// App display name
    let appDisplayName: String

    /// Bundle identifier
    let bundleIdentifier: String

    // MARK: - Initialization

    private init() {
        // Read environment
        if let envString = EnvironmentKey.environment.value?.lowercased(),
           let env = AppEnvironment(rawValue: envString) {
            environment = env
        } else {
            #if DEBUG
            environment = .development
            #else
            environment = .production
            #endif
        }

        // Read API keys (with fallback to Secrets.plist for backwards compatibility)
        finnhubAPIKey = Self.readAPIKey(.finnhubAPIKey, secretsKey: "FINNHUB_API_KEY")
        mixpanelToken = Self.readAPIKey(.mixpanelToken, secretsKey: "MIXPANEL_TOKEN")

        // Read app info
        appDisplayName = EnvironmentKey.bundleDisplayName.value ?? "Cosmo Trader"
        bundleIdentifier = EnvironmentKey.bundleIdentifier.value ?? "com.cosmotrader.app"
    }

    // MARK: - Private Helpers

    /// Read API key from Info.plist, falling back to Secrets.plist (from project directory in DEBUG)
    private static func readAPIKey(_ envKey: EnvironmentKey, secretsKey: String) -> String {
        // 1. First try Info.plist (from xcconfig) - works for Release builds with injected keys
        if let value = envKey.value,
           !value.isEmpty,
           !value.hasPrefix("$("),
           value != "YOUR_\(secretsKey)_HERE" {
            return value
        }

        // 2. Try reading Secrets.plist from project directory (DEBUG builds only)
        #if DEBUG
        if let value = readSecretFromProjectDirectory(secretsKey) {
            return value
        }
        #endif

        // 3. Fall back to bundled Secrets.plist (legacy support)
        if let path = Bundle.main.path(forResource: "Secrets", ofType: "plist"),
           let dict = NSDictionary(contentsOfFile: path) as? [String: Any],
           let value = dict[secretsKey] as? String,
           !value.isEmpty,
           !value.hasPrefix("$("),
           value != "YOUR_\(secretsKey)_HERE" {
            return value
        }

        // No key found - print helpful error
        #if DEBUG
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("ERROR: \(secretsKey) not found!")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("")
        print("For DEBUG builds:")
        print("  1. Create Secrets.plist in the project folder")
        print("  2. Add key '\(secretsKey)' with your API key")
        print("  3. Path: Cosmo Trader/Cosmo Trader/Configuration/Secrets.plist")
        print("")
        print("For RELEASE builds:")
        print("  1. Set \(secretsKey) in your CI/CD environment")
        print("  2. Or add to Secrets.xcconfig")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        #endif

        return ""
    }

    #if DEBUG
    /// Read a secret from Secrets.plist in the project directory (not bundled)
    private static func readSecretFromProjectDirectory(_ key: String) -> String? {
        // Get the source file directory and navigate to find Secrets.plist
        let sourceFile = #file
        let sourceDirectory = (sourceFile as NSString).deletingLastPathComponent

        // Try common locations relative to this source file
        let possiblePaths = [
            (sourceDirectory as NSString).appendingPathComponent("Secrets.plist"),
            ((sourceDirectory as NSString).deletingLastPathComponent as NSString).appendingPathComponent("Secrets.plist"),
            ((sourceDirectory as NSString).deletingLastPathComponent as NSString).appendingPathComponent("Configuration/Secrets.plist")
        ]

        for path in possiblePaths {
            if FileManager.default.fileExists(atPath: path),
               let dict = NSDictionary(contentsOfFile: path) as? [String: Any],
               let value = dict[key] as? String,
               !value.isEmpty,
               !value.hasPrefix("$("),
               value != "YOUR_\(key)_HERE" {
                return value
            }
        }

        return nil
    }
    #endif

    // MARK: - Validation

    /// Check if all required configuration is present
    var isValid: Bool {
        !finnhubAPIKey.isEmpty
    }

    /// Get list of missing configuration keys
    var missingKeys: [String] {
        var missing: [String] = []

        if finnhubAPIKey.isEmpty {
            missing.append("FINNHUB_API_KEY")
        }

        // Mixpanel is optional but log if missing
        if mixpanelToken.isEmpty {
            #if DEBUG
            print("⚠️ MIXPANEL_TOKEN not configured (optional)")
            #endif
        }

        return missing
    }

    /// Print configuration status
    func printStatus() {
        #if DEBUG
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("Environment Configuration")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("Environment: \(environment.displayName)")
        print("Bundle ID: \(bundleIdentifier)")
        print("App Name: \(appDisplayName)")
        print("")
        print("API Keys:")
        print("  Finnhub: \(finnhubAPIKey.isEmpty ? "✗ Missing" : "✓ Configured")")
        print("  Mixpanel: \(mixpanelToken.isEmpty ? "✗ Missing" : "✓ Configured")")
        print("")
        print("Features:")
        print("  Analytics: \(environment.analyticsEnabled ? "Enabled" : "Disabled")")
        print("  Crash Reporting: \(environment.crashReportingEnabled ? "Enabled" : "Disabled")")
        print("  Debug UI: \(environment.showsDebugUI ? "Enabled" : "Disabled")")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        #endif
    }
}

// MARK: - Debug Helpers

#if DEBUG
extension AppEnvironment {
    /// Force a specific environment (testing only)
    static var _testOverride: AppEnvironment?

    /// Get current environment with test override support
    static var currentOrOverride: AppEnvironment {
        _testOverride ?? current
    }
}
#endif
