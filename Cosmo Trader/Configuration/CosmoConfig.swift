import Foundation

enum CosmoConfig {

    nonisolated static func string(_ keys: [String]) -> String? {
        for key in keys {
            if let value = valueFromEnvironment(for: key) {
                return value
            }

            if let value = valueFromInfoPlist(for: key) {
                return value
            }

            // The shipping delivery path: Secrets.plist is bundled as a
            // resource and read here in ALL configurations. (The Info.plist
            // path above never carries the key — GENERATE_INFOPLIST_FILE
            // drops custom keys — so without this read the app has no
            // Finnhub key and every quote is disabled.)
            if let value = valueFromBundledSecretsPlist(for: key) {
                return value
            }

            #if DEBUG
            if let value = valueFromDebugSecretsPlist(for: key) {
                return value
            }
            #endif
        }

        return nil
    }

    /// Reads a bundled `Secrets.plist` resource. Xcode re-serializes the
    /// plist into the bundle at build time, so it parses cleanly here even
    /// when the source-tree copy does not.
    nonisolated private static func valueFromBundledSecretsPlist(for key: String) -> String? {
        guard let url = Bundle.main.url(forResource: "Secrets", withExtension: "plist"),
              let dict = NSDictionary(contentsOf: url) as? [String: Any],
              let value = dict[key] as? String else {
            return nil
        }
        return normalized(value)
    }

    nonisolated private static func valueFromEnvironment(for key: String) -> String? {
        normalized(ProcessInfo.processInfo.environment[key])
    }

    nonisolated private static func valueFromInfoPlist(for key: String) -> String? {
        normalized(Bundle.main.object(forInfoDictionaryKey: key) as? String)
    }

    #if DEBUG
    nonisolated private static func valueFromDebugSecretsPlist(for key: String) -> String? {
        for path in debugSecretsPlistPaths {
            guard FileManager.default.fileExists(atPath: path),
                  let dict = NSDictionary(contentsOfFile: path) as? [String: Any],
                  let value = dict[key] as? String,
                  let normalizedValue = normalized(value) else {
                continue
            }
            return normalizedValue
        }
        return nil
    }

    nonisolated private static var debugSecretsPlistPaths: [String] {
        // #filePath (not #file): #file is the concise "Module/File.swift"
        // form under the app target's build settings, so its
        // deletingLastPathComponent is a bare module name and the computed
        // Secrets.plist paths never resolve. #filePath is always the full
        // source path.
        let sourceDirectory = (#filePath as NSString).deletingLastPathComponent
        return [
            (sourceDirectory as NSString).appendingPathComponent("Secrets.plist"),
            ((sourceDirectory as NSString).deletingLastPathComponent as NSString).appendingPathComponent("Secrets.plist"),
            ((sourceDirectory as NSString).deletingLastPathComponent as NSString).appendingPathComponent("Configuration/Secrets.plist")
        ]
    }
    #endif

    nonisolated private static func normalized(_ value: String?) -> String? {
        guard let rawValue = value?.trimmingCharacters(in: .whitespacesAndNewlines),
              !rawValue.isEmpty,
              !rawValue.hasPrefix("$("),
              !rawValue.hasPrefix("YOUR_") else {
            return nil
        }
        return rawValue
    }
}
