import Foundation

#if canImport(FirebaseAuth)
import FirebaseAuth
#endif
#if canImport(FirebaseCore)
import FirebaseCore
#endif

// MARK: - AuthManager
// ====================
// Minimal Firebase Auth wrapper for anonymous sign-in and token access.

final class AuthManager {

    static let shared = AuthManager()

    private init() {}

    @MainActor
    func ensureSignedIn(appState: AppState? = nil) async {
        #if canImport(FirebaseAuth) && canImport(FirebaseCore)
        guard FirebaseConfigurator.isConfigured else {
            return
        }

        if let user = Auth.auth().currentUser {
            appState?.firebaseUID = user.uid
            return
        }

        do {
            let result = try await signInAnonymously()
            appState?.firebaseUID = result.user.uid
        } catch {
            Log.error("[AuthManager] Anonymous sign-in failed: \(error)")
        }
        #else
        Log.warning("[AuthManager] FirebaseAuth not available. Skipping auth.")
        #endif
    }

    func getIDTokenIfAvailable(forceRefresh: Bool = false) async -> String? {
        #if canImport(FirebaseAuth) && canImport(FirebaseCore)
        guard FirebaseConfigurator.isConfigured else {
            return nil
        }

        await ensureSignedIn()
        guard let user = Auth.auth().currentUser else {
            return nil
        }
        return try? await getIDToken(user: user, forceRefresh: forceRefresh)
        #else
        return nil
        #endif
    }

    func getIDToken(forceRefresh: Bool = false) async throws -> String {
        if let token = await getIDTokenIfAvailable(forceRefresh: forceRefresh) {
            return token
        }

        #if canImport(FirebaseAuth) && canImport(FirebaseCore)
        guard FirebaseConfigurator.isConfigured else {
            throw AuthError.unavailable
        }
        throw AuthError.notSignedIn
        #else
        throw AuthError.unavailable
        #endif
    }

    @MainActor
    func signUpAndLink(email: String, password: String, appState: AppState) async throws {
        #if canImport(FirebaseAuth) && canImport(FirebaseCore)
        guard FirebaseConfigurator.isConfigured else {
            throw AuthError.unavailable
        }
        await ensureSignedIn(appState: appState)
        guard let user = Auth.auth().currentUser else {
            throw AuthError.notSignedIn
        }
        let credential = EmailAuthProvider.credential(withEmail: email, password: password)
        _ = try await linkUser(user, with: credential)
        appState.currentUser?.email = email
        appState.saveUserToStorage()
        await appState.syncProfileToCloud()
        #else
        throw AuthError.unavailable
        #endif
    }

    @MainActor
    func signIn(email: String, password: String, appState: AppState) async throws {
        #if canImport(FirebaseAuth) && canImport(FirebaseCore)
        guard FirebaseConfigurator.isConfigured else {
            throw AuthError.unavailable
        }
        let result = try await signInWithEmail(email: email, password: password)
        appState.firebaseUID = result.user.uid
        await appState.fetchProfileFromCloud()
        appState.currentUser?.email = email
        appState.saveUserToStorage()
        #else
        throw AuthError.unavailable
        #endif
    }

    @MainActor
    func signOut(appState: AppState) async throws {
        #if canImport(FirebaseAuth) && canImport(FirebaseCore)
        guard FirebaseConfigurator.isConfigured else {
            throw AuthError.unavailable
        }
        try Auth.auth().signOut()
        appState.deleteAllUserData()
        await ensureSignedIn(appState: appState)
        #else
        throw AuthError.unavailable
        #endif
    }

    // MARK: - Private

    #if canImport(FirebaseAuth)
    private func signInAnonymously() async throws -> AuthDataResult {
        try await withCheckedThrowingContinuation { continuation in
            Auth.auth().signInAnonymously { result, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if let result {
                    continuation.resume(returning: result)
                } else {
                    continuation.resume(throwing: AuthError.unknown)
                }
            }
        }
    }

    private func linkUser(_ user: User, with credential: AuthCredential) async throws -> AuthDataResult {
        try await withCheckedThrowingContinuation { continuation in
            user.link(with: credential) { result, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if let result {
                    continuation.resume(returning: result)
                } else {
                    continuation.resume(throwing: AuthError.unknown)
                }
            }
        }
    }

    private func signInWithEmail(email: String, password: String) async throws -> AuthDataResult {
        try await withCheckedThrowingContinuation { continuation in
            Auth.auth().signIn(withEmail: email, password: password) { result, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if let result {
                    continuation.resume(returning: result)
                } else {
                    continuation.resume(throwing: AuthError.unknown)
                }
            }
        }
    }

    private func getIDToken(user: User, forceRefresh: Bool) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            user.getIDTokenForcingRefresh(forceRefresh) { token, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if let token {
                    continuation.resume(returning: token)
                } else {
                    continuation.resume(throwing: AuthError.unknown)
                }
            }
        }
    }
    #endif
}

enum AuthError: Error {
    case notSignedIn
    case unavailable
    case unknown
}
