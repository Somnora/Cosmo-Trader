import Foundation
import SwiftUI

// MARK: - AppState
// ================
// Central state management for the entire app.
//
// This class holds the current user profile and provides:
// - Shared user data across all tabs
// - Portfolio management (buy/sell stocks)
// - Watchlist management
// - Profile editing (including birth date)
// - Persistence to UserDefaults
//
// Injected via .environmentObject so all views can access it.

@Observable
class AppState {

    // MARK: - Singleton for Persistence
    // (Optional pattern - you can also inject via environment)

    static let shared = AppState()

    // MARK: - Properties

    /// The current user's profile (nil if not onboarded)
    var currentUser: UserProfile?

    /// Has the user completed onboarding?
    var hasCompletedOnboarding: Bool {
        currentUser != nil
    }

    /// Is the app currently loading/saving?
    var isLoading: Bool = false

    // MARK: - Storage Keys

    private let userProfileKey = "com.cosmotrader.userProfile"
    private let hasOnboardedKey = "com.cosmotrader.hasOnboarded"

    // MARK: - Initialization

    init() {
        loadUserFromStorage()
    }

    /// Initialize with a specific user (for previews/testing)
    init(user: UserProfile?) {
        self.currentUser = user
    }

    // MARK: - Onboarding

    /// Complete onboarding with a new user
    func completeOnboarding(name: String, birthDate: Date) {
        let newUser = UserProfile(
            displayName: name,
            email: "\(name.lowercased().replacingOccurrences(of: " ", with: "."))@cosmictrader.com",
            birthDate: birthDate,
            portfolio: [], // Start with empty portfolio
            watchlist: [],
            skippedStocks: [],
            memberSince: Date()
        )

        currentUser = newUser
        saveUserToStorage()
    }

    /// Reset onboarding (for testing or logout)
    func resetOnboarding() {
        currentUser = nil
        UserDefaults.standard.removeObject(forKey: userProfileKey)
        UserDefaults.standard.set(false, forKey: hasOnboardedKey)
    }

    // MARK: - Profile Editing

    /// Update the user's display name
    func updateDisplayName(_ name: String) {
        currentUser?.displayName = name
        saveUserToStorage()
    }

    /// Update the user's birth date (recalculates sun sign automatically)
    func updateBirthDate(_ date: Date) {
        guard var user = currentUser else { return }

        // Create a new user profile with updated birth date
        // Note: birthDate is `let` so we recreate the user
        let updatedUser = UserProfile(
            id: user.id,
            displayName: user.displayName,
            email: user.email,
            birthDate: date,
            portfolio: user.portfolio,
            watchlist: user.watchlist,
            skippedStocks: user.skippedStocks,
            memberSince: user.memberSince,
            preferredCurrency: user.preferredCurrency
        )

        currentUser = updatedUser
        saveUserToStorage()
    }

    // MARK: - Portfolio Management

    /// Add a stock to the portfolio
    func addToPortfolio(_ stock: Stock, shares: Double = 1) {
        guard var user = currentUser else { return }

        var stockWithShares = stock
        stockWithShares.sharesOwned = shares
        user.addStock(stockWithShares)

        currentUser = user
        saveUserToStorage()
    }

    /// Remove a stock from the portfolio
    func removeFromPortfolio(symbol: String) {
        guard var user = currentUser else { return }

        user.removeStock(symbol: symbol)
        currentUser = user
        saveUserToStorage()
    }

    /// Update shares for a stock
    func updateShares(symbol: String, shares: Double) {
        guard var user = currentUser else { return }

        user.updateShares(symbol: symbol, newAmount: shares)
        currentUser = user
        saveUserToStorage()
    }

    /// Check if user owns a stock
    func ownsStock(symbol: String) -> Bool {
        guard let user = currentUser else { return false }
        return user.portfolio.contains { $0.symbol == symbol && $0.sharesOwned > 0 }
    }

    // MARK: - Watchlist Management

    /// Add a stock to the watchlist
    func addToWatchlist(_ symbol: String) {
        guard var user = currentUser else { return }

        user.addToWatchlist(symbol)
        currentUser = user
        saveUserToStorage()
    }

    /// Remove a stock from the watchlist
    func removeFromWatchlist(_ symbol: String) {
        guard var user = currentUser else { return }

        user.removeFromWatchlist(symbol)
        currentUser = user
        saveUserToStorage()
    }

    /// Skip a stock (dismiss from discover)
    func skipStock(_ symbol: String) {
        guard var user = currentUser else { return }

        user.skipStock(symbol)
        currentUser = user
        saveUserToStorage()
    }

    /// Reset skipped stocks
    func resetSkippedStocks() {
        guard var user = currentUser else { return }

        user.resetSkippedStocks()
        currentUser = user
        saveUserToStorage()
    }

    // MARK: - Persistence

    /// Save user profile to UserDefaults
    private func saveUserToStorage() {
        guard let user = currentUser else { return }

        do {
            let encoded = try JSONEncoder().encode(user)
            UserDefaults.standard.set(encoded, forKey: userProfileKey)
            UserDefaults.standard.set(true, forKey: hasOnboardedKey)
        } catch {
            print("Failed to save user profile: \(error)")
        }
    }

    /// Load user profile from UserDefaults
    private func loadUserFromStorage() {
        guard let data = UserDefaults.standard.data(forKey: userProfileKey) else {
            // No saved user - check if we should show demo data
            #if DEBUG
            // For development, start with sample user
            // currentUser = .sampleWithHoldings
            #endif
            return
        }

        do {
            currentUser = try JSONDecoder().decode(UserProfile.self, from: data)
        } catch {
            print("Failed to load user profile: \(error)")
            // Clear corrupted data
            UserDefaults.standard.removeObject(forKey: userProfileKey)
        }
    }
}

// MARK: - Preview Helpers

extension AppState {

    /// Sample app state with user for previews
    static var preview: AppState {
        let state = AppState(user: .sampleWithHoldings)
        return state
    }

    /// Empty app state for onboarding previews
    static var previewEmpty: AppState {
        AppState(user: nil)
    }
}
