import Foundation
import Testing
@testable import Cosmo_Trader

struct ConfigurationTests {

    @Test("App environment resolves scheme aliases")
    func appEnvironmentResolvesSchemeAliases() {
        #expect(AppEnvironment.resolved(from: "development") == .development)
        #expect(AppEnvironment.resolved(from: "debug") == .development)
        #expect(AppEnvironment.resolved(from: "staging") == .staging)
        #expect(AppEnvironment.resolved(from: "release") == .production)
        #expect(AppEnvironment.resolved(from: "production") == .production)
        #expect(AppEnvironment.resolved(from: "unexpected") == nil)
    }

    @Test("Backend config prefers canonical base URL")
    func backendConfigPrefersCanonicalBaseURL() {
        let config = CosmoBackendConfig.load(configValue: resolver([
            "COSMO_BACKEND_BASE_URL": "https://canonical.example.com/v1",
            "BACKEND_BASE_URL": "https://legacy.example.com"
        ]))

        #expect(config.baseURL.absoluteString == "https://canonical.example.com")
    }

    @Test("Backend config accepts legacy base URL")
    func backendConfigAcceptsLegacyBaseURL() {
        let config = CosmoBackendConfig.load(configValue: resolver([
            "BACKEND_BASE_URL": "https://legacy.example.com/v1/"
        ]))

        #expect(config.baseURL.absoluteString == "https://legacy.example.com")
    }

    @Test("Backend config strips accidental path and query")
    func backendConfigStripsAccidentalPathAndQuery() {
        let config = CosmoBackendConfig.load(configValue: resolver([
            "COSMO_BACKEND_BASE_URL": "https://api.example.com/v1/brief/today?token=redacted"
        ]))

        #expect(config.baseURL.absoluteString == "https://api.example.com")
    }

    @Test("Backend config falls back to production URL")
    func backendConfigFallsBackToProductionURL() {
        let config = CosmoBackendConfig.load(configValue: resolver([:]))

        #expect(config.baseURL.absoluteString == "https://cosmo-backend-910907383323.us-central1.run.app")
    }

    @Test("Backend API key is Debug-only")
    func backendAPIKeyIsDebugOnly() {
        let config = CosmoBackendConfig.load(configValue: resolver([
            "COSMO_BACKEND_API_KEY": "test-debug-key"
        ]))

        #if DEBUG
        #expect(config.apiKey == "test-debug-key")
        #else
        #expect(config.apiKey == nil)
        #endif
    }

    private func resolver(_ values: [String: String]) -> ([String]) -> String? {
        { keys in
            keys.lazy.compactMap { values[$0] }.first
        }
    }
}
