import Foundation

struct CosmoBackendConfig {
    let baseURL: URL
    let apiKey: String?

    static func load(bundle _: Bundle = .main) -> CosmoBackendConfig {
        load(configValue: CosmoConfig.string)
    }

    static func load(configValue: ([String]) -> String?) -> CosmoBackendConfig {
        let defaultURLString = "https://cosmo-backend-910907383323.us-central1.run.app"
        let canonicalBaseURL = configValue(["COSMO_BACKEND_BASE_URL"])
        let legacyBaseURL = configValue(["BACKEND_BASE_URL"])

        let baseURLString: String?
        if let canonicalBaseURL {
            if let legacyBaseURL, canonicalBaseURL != legacyBaseURL {
                ConfigWarnings.warnOnce(
                    key: "BACKEND_BASE_URL_CONFLICT",
                    message: "Both COSMO_BACKEND_BASE_URL and BACKEND_BASE_URL are set. Using COSMO_BACKEND_BASE_URL."
                )
            }
            baseURLString = canonicalBaseURL
        } else if let legacyBaseURL {
            ConfigWarnings.warnOnce(
                key: "BACKEND_BASE_URL_LEGACY",
                message: "BACKEND_BASE_URL is legacy. Prefer COSMO_BACKEND_BASE_URL."
            )
            baseURLString = legacyBaseURL
        } else {
            baseURLString = nil
        }

        #if DEBUG
        let apiKey = configValue(["COSMO_BACKEND_API_KEY", "BACKEND_API_KEY"])
        #else
        let apiKey: String? = nil
        #endif

        let resolvedBaseURL = normalizedBaseURL(from: baseURLString, defaultURLString: defaultURLString)
        let resolvedApiKey = (apiKey?.isEmpty == false) ? apiKey : nil

        // Note: Replace with Firebase Auth for production.
        return CosmoBackendConfig(baseURL: resolvedBaseURL, apiKey: resolvedApiKey)
    }

    static func normalizedBaseURL(from rawValue: String?, defaultURLString: String) -> URL {
        let fallbackURL = URL(string: defaultURLString)!
        guard let rawValue, !rawValue.isEmpty,
              var components = URLComponents(string: rawValue),
              components.scheme != nil,
              components.host != nil else {
            return fallbackURL
        }

        let originalPath = components.path
        var normalizedPath = originalPath

        while normalizedPath.count > 1, normalizedPath.hasSuffix("/") {
            normalizedPath.removeLast()
        }

        if normalizedPath.lowercased().hasSuffix("/v1") {
            normalizedPath = String(normalizedPath.dropLast(3))
        }

        while normalizedPath.count > 1, normalizedPath.hasSuffix("/") {
            normalizedPath.removeLast()
        }

        if normalizedPath == "/" {
            normalizedPath = ""
        }

        let hasPathSegment = !(normalizedPath.isEmpty || normalizedPath == "/")
        if hasPathSegment {
            normalizedPath = ""
        }

        components.path = normalizedPath
        components.query = nil
        components.fragment = nil

        guard let normalizedURL = components.url else {
            return fallbackURL
        }

        #if DEBUG
        let hadPathSegment = !(originalPath.isEmpty || originalPath == "/")
        if hadPathSegment {
            let sanitizedPath = originalPath.hasSuffix("/") ? String(originalPath.dropLast()) : originalPath
            ConfigWarnings.warnOnce(
                key: "BACKEND_BASE_URL_PATH_STRIPPED",
                message: "[CosmoBackendConfig] base URL contains path '\(sanitizedPath)'. Using host root only."
            )
        }
        #endif

        return normalizedURL
    }
}
