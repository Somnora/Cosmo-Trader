import Foundation
#if canImport(FirebaseCore)
import FirebaseCore
#endif

enum FirebaseConfigurator {
    private static var didAttemptConfigure = false
    private(set) static var isConfigured = false

    @discardableResult
    static func configureIfPossible() -> Bool {
        if AppState.shouldDisableFirebase {
            didAttemptConfigure = true
            isConfigured = false
            return false
        }

        #if canImport(FirebaseCore)
        if isConfigured {
            return true
        }

        if FirebaseApp.app() != nil {
            isConfigured = true
            didAttemptConfigure = true
            return true
        }

        guard !didAttemptConfigure else {
            return false
        }
        didAttemptConfigure = true

        let candidatePlists = ["GoogleService-Info", "GoogleService-Info_CT"]
        for plistName in candidatePlists {
            guard let path = Bundle.main.path(forResource: plistName, ofType: "plist"),
                  let options = FirebaseOptions(contentsOfFile: path) else {
                continue
            }

            FirebaseApp.configure(options: options)
            isConfigured = true
            return true
        }

        return false
        #else
        isConfigured = false
        didAttemptConfigure = true
        return false
        #endif
    }
}

// Backward-compatible wrapper while call sites migrate to FirebaseConfigurator.
enum FirebaseBootstrap {
    static var isConfigured: Bool {
        FirebaseConfigurator.isConfigured
    }

    @discardableResult
    static func configureIfPossible() -> Bool {
        FirebaseConfigurator.configureIfPossible()
    }
}
