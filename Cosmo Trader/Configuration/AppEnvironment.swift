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

    /// The current app environment, determined by scheme env or build configuration.
    static var current: AppEnvironment {
        if let environment = resolved(from: EnvironmentKey.environment.value) {
            return environment
        }

        #if DEBUG
        return .development
        #else
        return .production
        #endif
    }

    static func resolved(from rawValue: String?) -> AppEnvironment? {
        guard let normalizedValue = rawValue?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(),
              !normalizedValue.isEmpty else {
            return nil
        }

        switch normalizedValue {
        case "development", "develop", "dev", "debug":
            return .development
        case "staging", "stage", "stg":
            return .staging
        case "production", "prod", "release":
            return .production
        default:
            return nil
        }
    }

    static func defaultForBuildConfiguration() -> AppEnvironment {
        #if DEBUG
        return .development
        #else
        return .production
        #endif
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

// MARK: - Launch Surface Policy

enum LaunchSurfacePolicy {
    static var showsInternalDiagnostics: Bool {
        #if DEBUG
        true
        #else
        false
        #endif
    }

    static var showsUnprovenGrowthSurfaces: Bool {
        #if DEBUG
        true
        #else
        false
        #endif
    }

    static var showsTestNotificationControls: Bool {
        #if DEBUG
        true
        #else
        false
        #endif
    }

    static var showsCosmicGraveyard: Bool {
        #if DEBUG
        true
        #else
        false
        #endif
    }
}

// MARK: - Environment Keys

/// Keys for reading environment configuration from Info.plist
enum EnvironmentKey: String {
    case environment = "APP_ENVIRONMENT"
    case finnhubAPIKey = "FINNHUB_API_KEY"
    case backendBaseURL = "COSMO_BACKEND_BASE_URL"
    case bundleDisplayName = "CFBundleDisplayName"
    case bundleIdentifier = "CFBundleIdentifier"

    /// Read value from Info.plist
    var value: String? {
        ProcessInfo.processInfo.environment[rawValue]
            ?? Bundle.main.infoDictionary?[rawValue] as? String
    }
}

// MARK: - Environment Configuration

/// Centralized configuration that reads from xcconfig via Info.plist
struct EnvironmentConfig {

    // MARK: - Singleton

    static let shared = EnvironmentConfig()
    private static let defaultBackendURL = "https://cosmo-backend-910907383323.us-central1.run.app"

    // MARK: - Properties

    /// Current environment
    let environment: AppEnvironment

    /// Finnhub API key
    let finnhubAPIKey: String

    /// Backend base URL
    let backendBaseURL: String

    /// App display name
    let appDisplayName: String

    /// Bundle identifier
    let bundleIdentifier: String

    // MARK: - Initialization

    private init() {
        // Read environment
        if let env = AppEnvironment.resolved(from: EnvironmentKey.environment.value) {
            environment = env
        } else {
            environment = AppEnvironment.defaultForBuildConfiguration()
        }

        // Read API keys through shared config resolver.
        finnhubAPIKey = Self.readAPIKey(keys: ["FINNHUB_API_KEY", "FINNHUB_KEY"])
        backendBaseURL = Self.readValue(
            keys: ["COSMO_BACKEND_BASE_URL", "BACKEND_BASE_URL"],
            defaultValue: Self.defaultBackendURL
        )

        // Read app info
        appDisplayName = EnvironmentKey.bundleDisplayName.value ?? "Cosmo Trader"
        bundleIdentifier = EnvironmentKey.bundleIdentifier.value ?? "com.cosmotrader.app"
    }

    // MARK: - Private Helpers

    private static func readAPIKey(keys: [String]) -> String {
        CosmoConfig.string(keys) ?? ""
    }

    private static func readValue(keys: [String], defaultValue: String) -> String {
        let resolvedValue = readAPIKey(keys: keys)
        if !resolvedValue.isEmpty {
            return resolvedValue
        }

        ConfigWarnings.warnOnce(
            key: "BACKEND_BASE_URL_DEFAULTED",
            message: "Backend base URL missing. Using default Cloud Run URL for this session."
        )
        return defaultValue
    }

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
        print("  Backend Base URL: \(backendBaseURL.isEmpty ? "✗ Missing" : "✓ Configured")")
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
