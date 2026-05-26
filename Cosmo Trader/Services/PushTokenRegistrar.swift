import Foundation

// MARK: - PushTokenRegistrar
// ==========================
// Debounced push token registration with a single retry after auth.

final class PushTokenRegistrar {

    static let shared = PushTokenRegistrar()

    private let queue = DispatchQueue(label: "com.cosmotrader.push.token", qos: .utility)
    private var pendingWork: DispatchWorkItem?
    private let debounceInterval: TimeInterval = 0.5
    private let maxAge: TimeInterval = 7 * 24 * 60 * 60
    private let storage = PushTokenStorage.shared
    private let apiClient = CosmoAPIClient()

    private init() {}

    func register(token: String, tokenType: PushTokenType) {
        queue.async { [weak self] in
            guard let self else { return }

            let previousToken = storage.lastToken
            let lastRegisterDate = storage.lastRegisterDate

            // Debounce repeated updates
            pendingWork?.cancel()
            let work = DispatchWorkItem { [weak self] in
                self?.attemptSend(
                    token: token,
                    tokenType: tokenType,
                    previousToken: previousToken,
                    lastRegisterDate: lastRegisterDate
                )
            }
            pendingWork = work
            queue.asyncAfter(deadline: .now() + debounceInterval, execute: work)
        }
    }

    func registerIfNeeded() {
        guard let token = storage.lastToken else { return }
        register(token: token, tokenType: .apns)
    }

    private func attemptSend(
        token: String,
        tokenType: PushTokenType,
        previousToken: String?,
        lastRegisterDate: Date?
    ) {
        let now = Date()

        // Compare against the previously stored token before writing new values.
        if token == previousToken,
           let lastRegisterDate,
           now.timeIntervalSince(lastRegisterDate) < maxAge {
            return
        }

        storage.lastToken = token
        Task {
            await sendToken(token: token, tokenType: tokenType)
        }
    }

#if DEBUG
    func forceRegisterIfAvailable() {
        guard let token = storage.lastToken else { return }
        queue.async { [weak self] in
            guard let self else { return }
            pendingWork?.cancel()
            let work = DispatchWorkItem { [weak self] in
                Task {
                    await self?.sendToken(token: token, tokenType: .apns)
                }
            }
            pendingWork = work
            queue.asyncAfter(deadline: .now() + 0.1, execute: work)
        }
    }
#endif

    private func sendToken(token: String, tokenType: PushTokenType) async {
        guard FirebaseConfigurator.isConfigured else {
            storage.lastStatus = .authUnavailable
            NotificationCenter.default.post(name: .pushRegistrationUpdated, object: nil)
            return
        }

        guard await AuthManager.shared.getIDTokenIfAvailable(forceRefresh: false) != nil else {
            storage.lastStatus = .authUnavailable
            NotificationCenter.default.post(name: .pushRegistrationUpdated, object: nil)
            return
        }

        let request = PushRegisterRequest(
            deviceId: DeviceIDProvider.shared.getOrCreateDeviceId(),
            token: token,
            tokenType: tokenType,
            appVersion: Self.nonEmptyBundleString("CFBundleShortVersionString", fallback: "unknown"),
            buildNumber: Self.nonEmptyBundleString("CFBundleVersion", fallback: "unknown"),
            platform: "ios",
            locale: Self.currentLocaleIdentifier()
        )

        do {
            _ = try await apiClient.registerPushToken(request)
            storage.lastToken = token
            storage.lastRegisterDate = Date()
            storage.lastStatus = .success
            NotificationCenter.default.post(name: .pushRegistrationUpdated, object: nil)
        } catch let error as CosmoAPIError {
            if case .unauthorized = error {
                storage.lastStatus = .unauthorized
            } else {
                storage.lastStatus = .failed
            }
            NotificationCenter.default.post(name: .pushRegistrationUpdated, object: nil)
        } catch {
            storage.lastStatus = .failed
            NotificationCenter.default.post(name: .pushRegistrationUpdated, object: nil)
        }
    }

    private static func nonEmptyBundleString(_ key: String, fallback: String) -> String {
        guard let value = Bundle.main.object(forInfoDictionaryKey: key) as? String,
              !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return fallback
        }
        return value
    }

    private static func currentLocaleIdentifier() -> String {
        let identifier = Locale.current.identifier
        return identifier.isEmpty ? "und" : identifier
    }
}

extension Notification.Name {
    static let pushRegistrationUpdated = Notification.Name("com.cosmotrader.pushRegistrationUpdated")
}
