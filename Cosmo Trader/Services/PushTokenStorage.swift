import Foundation
import Security

final class PushTokenStorage {

    static let shared = PushTokenStorage()

    private let service = "com.cosmotrader.push"
    private let tokenAccount = "apnsToken"
    private let lastRegisterAccount = "lastRegisterDate"
    private let statusKey = "com.cosmotrader.push.lastStatus"

    enum RegistrationStatus: String {
        case success
        case unauthorized
        case authUnavailable
        case failed
    }

    private init() {}

    var lastToken: String? {
        get { readKeychain(account: tokenAccount) }
        set { _ = writeKeychain(account: tokenAccount, value: newValue) }
    }

    var lastRegisterDate: Date? {
        get {
            guard let value = readKeychain(account: lastRegisterAccount),
                  let interval = TimeInterval(value) else {
                return nil
            }
            return Date(timeIntervalSince1970: interval)
        }
        set {
            let value = newValue.map { String($0.timeIntervalSince1970) }
            _ = writeKeychain(account: lastRegisterAccount, value: value)
        }
    }

    var lastStatus: RegistrationStatus? {
        get {
            guard let raw = UserDefaults.standard.string(forKey: statusKey) else { return nil }
            return RegistrationStatus(rawValue: raw)
        }
        set {
            UserDefaults.standard.set(newValue?.rawValue, forKey: statusKey)
        }
    }

    private func readKeychain(account: String) -> String? {
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

    private func writeKeychain(account: String, value: String?) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]

        SecItemDelete(query as CFDictionary)

        guard let value else { return true }
        let data = Data(value.utf8)
        var newQuery = query
        newQuery[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
        newQuery[kSecValueData as String] = data
        let status = SecItemAdd(newQuery as CFDictionary, nil)
        return status == errSecSuccess
    }
}
