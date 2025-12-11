import Foundation

// MARK: - APIConfig
// =================
// Secure configuration loader for API keys and secrets.
// Reads from Secrets.plist which is gitignored.
//
// USAGE:
// ------
// let key = APIConfig.finnhubKey
// let baseURL = APIConfig.finnhubBaseURL
//
// SETUP:
// ------
// 1. Copy Secrets-template.plist to Secrets.plist
// 2. Fill in your API keys
// 3. Secrets.plist is gitignored - never committed

enum APIConfig {

    // MARK: - Finnhub API

    /// Finnhub API key for stock quotes
    /// Get yours at: https://finnhub.io
    static var finnhubKey: String {
        guard let key = secrets["FINNHUB_API_KEY"] as? String,
              !key.isEmpty,
              key != "YOUR_FINNHUB_API_KEY_HERE" else {
            #if DEBUG
            print("⚠️ Finnhub API key not configured. Copy Secrets-template.plist to Secrets.plist")
            #endif
            return ""
        }
        return key
    }

    /// Finnhub base URL
    static let finnhubBaseURL = "https://finnhub.io/api/v1"

    /// Check if Finnhub is properly configured
    static var isFinnhubConfigured: Bool {
        !finnhubKey.isEmpty
    }

    // MARK: - Private

    /// Cached secrets dictionary
    private static var secrets: [String: Any] = {
        loadSecrets()
    }()

    /// Load secrets from plist file
    private static func loadSecrets() -> [String: Any] {
        // Try to find Secrets.plist in the main bundle
        guard let path = Bundle.main.path(forResource: "Secrets", ofType: "plist") else {
            #if DEBUG
            print("⚠️ Secrets.plist not found in bundle.")
            print("   Copy Secrets-template.plist to Secrets.plist and add your API keys.")
            #endif
            return [:]
        }

        guard let dict = NSDictionary(contentsOfFile: path) as? [String: Any] else {
            #if DEBUG
            print("⚠️ Failed to read Secrets.plist")
            #endif
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
        var missingKeys: [String] = []

        if !isFinnhubConfigured {
            missingKeys.append("FINNHUB_API_KEY")
        }

        return missingKeys
    }

    /// Print configuration status (debug only)
    static func printStatus() {
        #if DEBUG
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("API Configuration Status")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("Finnhub: \(isFinnhubConfigured ? "✓ Configured" : "✗ Missing")")

        let missing = validateConfiguration()
        if !missing.isEmpty {
            print("\n⚠️ Missing keys: \(missing.joined(separator: ", "))")
            print("Add them to Secrets.plist")
        }
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        #endif
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
