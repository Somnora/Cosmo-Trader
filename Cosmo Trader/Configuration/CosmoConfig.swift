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

            // Check Secrets.plist bundled as an app resource (works on physical devices)
            if let value = valueFromBundledSecretsPlist(for: key) {
                return value
            }

            #if DEBUG
            // Fallback: source-tree Secrets.plist via #file (Simulator only)
            if let value = valueFromDebugSecretsPlist(for: key) {
                return value
            }
            #endif
        }

        return nil
    }

    nonisolated private static func valueFromEnvironment(for key: String) -> String? {
        normalized(ProcessInfo.processInfo.environment[key])
    }

    nonisolated private static func valueFromInfoPlist(for key: String) -> String? {
        normalized(Bundle.main.object(forInfoDictionaryKey: key) as? String)
    }

    /// Read from Secrets.plist if it was added to "Copy Bundle Resources".
    /// This works on both Simulator and physical devices.
    nonisolated private static func valueFromBundledSecretsPlist(for key: String) -> String? {
        guard let path = Bundle.main.path(forResource: "Secrets", ofType: "plist"),
              let dict = NSDictionary(contentsOfFile: path) as? [String: Any],
              let value = dict[key] as? String,
              let normalizedValue = normalized(value) else {
            return nil
        }
        return normalizedValue
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
        let sourceDirectory = (#file as NSString).deletingLastPathComponent
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
