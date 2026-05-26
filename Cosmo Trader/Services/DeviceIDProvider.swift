import Foundation
import Security

// MARK: - DeviceIDProvider
// =========================
// Stable per-install identifier, stored in Keychain with UserDefaults cache.

final class DeviceIDProvider {

    static let shared = DeviceIDProvider()

    private let service = "com.cosmotrader.deviceid"
    private let account = "deviceId"
    private let userDefaultsKey = "com.cosmotrader.deviceId"

    private init() {}

    func getOrCreateDeviceId() -> String {
        if let cached = UserDefaults.standard.string(forKey: userDefaultsKey) {
            return cached
        }
        if let existing = readKeychain() {
            UserDefaults.standard.set(existing, forKey: userDefaultsKey)
            return existing
        }

        let newId = UUID().uuidString
        _ = writeKeychain(value: newId)
        UserDefaults.standard.set(newId, forKey: userDefaultsKey)
        return newId
    }

    private func readKeychain() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var item: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess,
              let data = item as? Data,
              let value = String(data: data, encoding: .utf8) else {
            return nil
        }
        return value
    }

    private func writeKeychain(value: String) -> Bool {
        let data = Data(value.utf8)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock,
            kSecValueData as String: data
        ]

        SecItemDelete(query as CFDictionary)
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }
}
