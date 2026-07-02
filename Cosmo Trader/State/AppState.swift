import Foundation
import SwiftUI

enum AppNavigationIntent: Equatable {
    case portfolioAddHolding
    case portfolioImport
    case discoverSearch
}

struct PortfolioImportFeedback: Equatable, Identifiable {
    let id = UUID()
    let mode: PortfolioImportCommitMode
    let importedCount: Int
    let totalHoldings: Int

    static func == (lhs: PortfolioImportFeedback, rhs: PortfolioImportFeedback) -> Bool {
        lhs.mode == rhs.mode
            && lhs.importedCount == rhs.importedCount
            && lhs.totalHoldings == rhs.totalHoldings
    }

    var title: String {
        switch mode {
        case .replace:
            return "Portfolio replaced"
        case .append:
            return "Portfolio updated"
        }
    }

    var detail: String {
        switch mode {
        case .replace:
            return "\(importedCount) imported holdings replaced your previous portfolio. \(totalHoldings) holdings are now tracked."
        case .append:
            return "\(importedCount) imported holdings were appended. Matching symbols were merged with weighted cost basis."
        }
    }
}

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
// - Error handling and state recovery
//
// Injected via .environmentObject so all views can access it.

@Observable
class AppState {
    private static let firstRunDataSetupSkippedKey = "com.cosmotrader.firstRunDataSetupSkipped"
    private static let firstRunDataSetupCompletedKey = "com.cosmotrader.firstRunDataSetupCompleted"

    // MARK: - Singleton for Persistence
    // (Optional pattern - you can also inject via environment)

    static let shared = AppState()

    // MARK: - Properties

    /// The current user's profile (nil if not onboarded)
    var currentUser: UserProfile?

    /// Firebase Auth uid (if signed in)
    var firebaseUID: String?

    /// Has the user completed onboarding?
    var hasCompletedOnboarding: Bool {
        currentUser != nil
    }

    /// Is the app currently loading/saving?
    var isLoading: Bool = false

    /// Current error state
    var errorState: ErrorState = ErrorState()

    /// Whether the app detected and recovered from data corruption
    var didRecoverFromCorruption: Bool = false

    /// Last successful save timestamp
    var lastSaveTimestamp: Date?

    /// Is the app in offline mode?
    var isOfflineMode: Bool = false

    /// Currently selected tab (for cross-tab navigation)
    var selectedTab: Tab = .today

    /// One-shot request for a tab to open a specific existing flow.
    var pendingNavigationIntent: AppNavigationIntent?

    /// Transient confirmation shown after manual, CSV, or screenshot import commits.
    var portfolioImportFeedback: PortfolioImportFeedback?

    /// First-run data setup is separate from profile onboarding: users can
    /// skip it and still enter the app, while Today keeps surfacing the next
    /// real-data unlock step until the checklist is complete.
    var hasSkippedFirstRunDataSetup: Bool = UserDefaults.standard.bool(forKey: AppState.firstRunDataSetupSkippedKey)
    var hasCompletedFirstRunDataSetup: Bool = UserDefaults.standard.bool(forKey: AppState.firstRunDataSetupCompletedKey)

    func requestNavigation(_ intent: AppNavigationIntent) {
        pendingNavigationIntent = intent

        switch intent {
        case .portfolioAddHolding, .portfolioImport:
            selectedTab = .portfolio
        case .discoverSearch:
            selectedTab = .discover
        }
    }

    func skipFirstRunDataSetup() {
        hasSkippedFirstRunDataSetup = true
        UserDefaults.standard.set(true, forKey: Self.firstRunDataSetupSkippedKey)
    }

    func updateFirstRunDataSetupCompletion(_ isComplete: Bool) {
        guard isComplete, !hasCompletedFirstRunDataSetup else { return }
        hasCompletedFirstRunDataSetup = true
        UserDefaults.standard.set(true, forKey: Self.firstRunDataSetupCompletedKey)
    }

    func resetFirstRunDataSetup() {
        hasSkippedFirstRunDataSetup = false
        hasCompletedFirstRunDataSetup = false
        UserDefaults.standard.set(false, forKey: Self.firstRunDataSetupSkippedKey)
        UserDefaults.standard.set(false, forKey: Self.firstRunDataSetupCompletedKey)
    }

    // MARK: - Storage Keys

    private let userProfileKey = "com.cosmotrader.userProfile"
    private let hasOnboardedKey = "com.cosmotrader.hasOnboarded"
    private let lastSaveKey = "com.cosmotrader.lastSave"
    private let backupProfileKey = "com.cosmotrader.backupProfile"

    // MARK: - Initialization

    init() {
        if configureForAutomationIfNeeded() {
            return
        }

        loadUserFromStorage()
    }

    /// Initialize with a specific user (for previews/testing)
    init(user: UserProfile?) {
        self.currentUser = user
        self.hasSkippedFirstRunDataSetup = false
        self.hasCompletedFirstRunDataSetup = false
    }

    static var launchArguments: Set<String> {
        Set(CommandLine.arguments)
    }

    static var isUITesting: Bool {
        launchArguments.contains("--uitesting")
    }

    static var isScreenshotMode: Bool {
        launchArguments.contains("--screenshot-mode")
    }

    static var shouldDisableFirebase: Bool {
        launchArguments.contains("--disable-firebase")
    }

    static var isScreenshotCalendarMode: Bool {
        launchArguments.contains("--tab-calendar")
    }

    static var screenshotStockDetailSymbol: String? {
        if let explicitSymbol = launchArguments.first(where: { $0.hasPrefix("--stock-detail=") })?
            .replacingOccurrences(of: "--stock-detail=", with: "")
        {
            return explicitSymbol
        }

        return launchArguments.contains("--tab-stock-detail") ? "AAPL" : nil
    }

    static var shouldFocusAstroOverlayScreenshot: Bool {
        launchArguments.contains("--focus-astro-overlay")
    }

    static var usesProviderBackedChartFixture: Bool {
        #if DEBUG
        ProviderBackedChartFixtureSeeder.shouldSeed(arguments: launchArguments)
        #else
        false
        #endif
    }

    static var providerBackedChartFixtureTimeframe: ChartTimeframe? {
        #if DEBUG
        guard usesProviderBackedChartFixture else { return nil }
        guard let rawValue = launchArguments.first(where: { $0.hasPrefix("--chart-timeframe=") })?
            .replacingOccurrences(of: "--chart-timeframe=", with: "")
            .uppercased()
        else {
            return nil
        }
        return ChartTimeframe(rawValue: rawValue)
        #else
        return nil
        #endif
    }

    static var shouldOpenAutomationStockDetail: Bool {
        isScreenshotMode || usesProviderBackedChartFixture
    }

    @discardableResult
    private func configureForAutomationIfNeeded() -> Bool {
        let arguments = Self.launchArguments
        guard arguments.contains("--uitesting") || arguments.contains("--screenshot-mode") else { return false }

        #if DEBUG
        try? ProviderBackedChartFixtureSeeder.seedIfRequested(arguments: arguments)
        #endif

        configureSubscriptionStateForAutomation(arguments: arguments)

        if arguments.contains("--reset-onboarding") {
            clearStoredUserForAutomation()
            currentUser = nil
            return true
        }

        guard arguments.contains("--skip-onboarding") else {
            return true
        }

        currentUser = makeAutomationUser(arguments: arguments)
        selectedTab = makeAutomationStartTab(arguments: arguments)
        saveUserToStorage()
        UserDefaults.standard.set(true, forKey: hasOnboardedKey)
        return true
    }

    private func makeAutomationStartTab(arguments: Set<String>) -> Tab {
        if arguments.contains("--tab-today") { return .today }
        if arguments.contains("--tab-stock-detail") { return .portfolio }
        if arguments.contains("--tab-portfolio") { return .portfolio }
        if arguments.contains("--tab-discover") { return .discover }
        if arguments.contains("--tab-calendar") { return .cosmos }
        if arguments.contains("--tab-cosmos") { return .cosmos }
        if arguments.contains("--tab-profile") { return .profile }
        return .today
    }

    private func makeAutomationUser(arguments: Set<String>) -> UserProfile {
        if arguments.contains("--empty-discover") {
            return UserProfile(
                displayName: "Empty Discover",
                email: "empty.discover@cosmictrader.com",
                birthMonth: 4,
                birthDay: 10,
                birthYear: 2000,
                portfolio: [],
                skippedStocks: MockStockData.knownStocks.map(\.symbol)
            )
        }

        if arguments.contains("--empty-portfolio") {
            return UserProfile.newUser
        }

        if arguments.contains("--sample-stocks") {
            return UserProfile(
                displayName: "Discover Tester",
                email: "discover.tester@cosmictrader.com",
                birthMonth: 8,
                birthDay: 15,
                birthYear: 1990,
                portfolio: [],
                watchlist: [],
                skippedStocks: []
            )
        }

        return UserProfile.sample
    }

    private func configureSubscriptionStateForAutomation(arguments: Set<String>) {
        let isPremium = arguments.contains("--premium-user")

        if isPremium {
            let expirationDate = Calendar.current.date(byAdding: .year, value: 1, to: Date()) ?? Date()
            UserDefaults.standard.set(true, forKey: "subscription_isPremium")
            UserDefaults.standard.set(expirationDate, forKey: "subscription_expirationDate")
            UserDefaults.standard.removeObject(forKey: "subscription_trialStartDate")
            UserDefaults.standard.removeObject(forKey: "subscription_trialUsed")
        } else {
            UserDefaults.standard.set(false, forKey: "subscription_isPremium")
            UserDefaults.standard.removeObject(forKey: "subscription_expirationDate")
            UserDefaults.standard.removeObject(forKey: "subscription_trialStartDate")
            UserDefaults.standard.removeObject(forKey: "subscription_trialUsed")
        }

        UserDefaults.standard.removeObject(forKey: "subscription_dailySwipeCount")
        UserDefaults.standard.removeObject(forKey: "subscription_lastSwipeDate")
        UserDefaults.standard.removeObject(forKey: "subscription_horoscopeCountToday")
        UserDefaults.standard.removeObject(forKey: "subscription_lastHoroscopeDate")
        UserDefaults.standard.removeObject(forKey: "subscription_roastCountToday")
        UserDefaults.standard.removeObject(forKey: "subscription_lastRoastDate")
    }

    private func clearStoredUserForAutomation() {
        UserDefaults.standard.removeObject(forKey: userProfileKey)
        UserDefaults.standard.removeObject(forKey: backupProfileKey)
        UserDefaults.standard.removeObject(forKey: lastSaveKey)
        UserDefaults.standard.set(false, forKey: hasOnboardedKey)
        resetFirstRunDataSetup()
        firebaseUID = nil
        didRecoverFromCorruption = false
        errorState.clear()
    }

    // MARK: - Onboarding

    /// Complete onboarding with a new user
    /// Returns validation error if inputs are invalid
    @discardableResult
    func completeOnboarding(name: String, birthDate: Date, timeOfBirth: Date? = nil) -> ValidationError? {
        // Validate name
        if let nameError = InputValidator.validateName(name) {
            errorState.showValidation(nameError)
            return nameError
        }

        // Validate birth date
        if let dateError = InputValidator.validateBirthDate(birthDate) {
            errorState.showValidation(dateError)
            return dateError
        }

        // Sanitize name
        let sanitizedName = InputValidator.sanitizeName(name)

        let newUser = UserProfile(
            displayName: sanitizedName,
            email: "\(sanitizedName.lowercased().replacingOccurrences(of: " ", with: "."))@cosmictrader.com",
            birthDate: birthDate,
            timeOfBirth: timeOfBirth,
            portfolio: [], // Start with empty portfolio
            watchlist: [],
            skippedStocks: [],
            memberSince: Date()
        )

        currentUser = newUser
        resetFirstRunDataSetup()
        saveUserToStorage()
        return nil
    }

    /// Reset onboarding (for testing or logout)
    func resetOnboarding() {
        currentUser = nil
        firebaseUID = nil
        UserDefaults.standard.removeObject(forKey: userProfileKey)
        UserDefaults.standard.removeObject(forKey: backupProfileKey)
        UserDefaults.standard.set(false, forKey: hasOnboardedKey)
        resetFirstRunDataSetup()
        didRecoverFromCorruption = false
        errorState.clear()
    }

    // MARK: - Profile Editing

    /// Update the user's display name
    /// Returns validation error if name is invalid
    @discardableResult
    func updateDisplayName(_ name: String) -> ValidationError? {
        // Validate
        if let error = InputValidator.validateName(name) {
            errorState.showValidation(error)
            return error
        }

        // Sanitize and update
        let sanitized = InputValidator.sanitizeName(name)
        currentUser?.displayName = sanitized
        saveUserToStorage()
        return nil
    }

    /// Update the user's birth date (recalculates sun sign automatically)
    /// Returns validation error if date is invalid
    @discardableResult
    func updateBirthDate(_ date: Date) -> ValidationError? {
        guard let user = currentUser else { return nil }

        // Validate
        if let error = InputValidator.validateBirthDate(date) {
            errorState.showValidation(error)
            return error
        }

        // Create a new user profile with updated birth date
        // Note: birthDate is `let` so we recreate the user
        let updatedUser = UserProfile(
            id: user.id,
            displayName: user.displayName,
            email: user.email,
            birthDate: date,
            timeOfBirth: user.timeOfBirth,
            birthLocation: user.birthLocation,
            portfolio: user.portfolio,
            watchlist: user.watchlist,
            skippedStocks: user.skippedStocks,
            memberSince: user.memberSince,
            preferredCurrency: user.preferredCurrency
        )

        currentUser = updatedUser
        saveUserToStorage()
        return nil
    }

    /// Update the user's time of birth (for rising sign calculations)
    func updateTimeOfBirth(_ time: Date?) {
        guard var user = currentUser else { return }
        user.timeOfBirth = time
        currentUser = user
        saveUserToStorage()
    }

    /// Update the user's birth location (for accurate timezone calculations)
    func updateBirthLocation(_ location: String?) {
        guard var user = currentUser else { return }
        user.birthLocation = location
        currentUser = user
        saveUserToStorage()
    }

    // MARK: - Signal Framing

    /// Update the user's global signal framing level
    func updateSignalFramingLevel(_ level: SignalFramingLevel) {
        guard var user = currentUser else { return }
        user.signalFramingLevel = level
        currentUser = user
        saveUserToStorage()
    }

    /// Set or remove a per-stock signal framing override
    /// - Parameters:
    ///   - symbol: The stock symbol
    ///   - level: The framing level to set, or nil to remove the override
    func setStockFramingOverride(symbol: String, level: SignalFramingLevel?) {
        guard var user = currentUser else { return }

        if let level = level {
            user.stockFramingOverrides[symbol] = level
        } else {
            user.stockFramingOverrides.removeValue(forKey: symbol)
        }

        currentUser = user
        saveUserToStorage()
    }

    /// Get the effective framing level for a stock (uses override or global)
    func framingLevel(for symbol: String) -> SignalFramingLevel {
        currentUser?.framingLevel(for: symbol) ?? .balanced
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

    /// Update portfolio prices from live API quotes
    func updatePortfolioPrices(with quotes: [String: StockQuote]) {
        guard var user = currentUser else { return }

        for (index, stock) in user.portfolio.enumerated() {
            if let quote = quotes[stock.symbol.uppercased()] {
                user.portfolio[index].currentPrice = quote.currentPrice
                user.portfolio[index].priceChange = quote.priceChange
                user.portfolio[index].percentageChange = quote.percentageChange
            }
        }

        currentUser = user
        // Don't persist price updates - they're ephemeral
    }

    // MARK: - Watchlist Management

    /// Add a stock to the watchlist
    func addToWatchlist(_ symbol: String) {
        guard var user = currentUser else { return }

        let wasEmpty = user.watchlist.isEmpty
        user.addToWatchlist(symbol)
        currentUser = user
        saveUserToStorage()

        if wasEmpty {
            Task { @MainActor in
                await ReferralService.shared.qualifyReferralIfNeeded(
                    milestone: .firstWatchlistAdd,
                    storageKey: ReferralMilestone.firstWatchlistAdd.qualificationStorageKey
                )
            }
        }
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

    /// Save user profile to UserDefaults with backup
    func saveUserToStorage() {
        guard let user = currentUser else { return }

        // Validate before saving
        if let dataError = DataValidator.validateUserProfile(user) {
            errorState.showData(dataError)
            return
        }

        do {
            let encoded = try JSONEncoder().encode(user)

            // Create backup before overwriting
            if let existingData = UserDefaults.standard.data(forKey: userProfileKey) {
                UserDefaults.standard.set(existingData, forKey: backupProfileKey)
            }

            UserDefaults.standard.set(encoded, forKey: userProfileKey)
            UserDefaults.standard.set(true, forKey: hasOnboardedKey)
            UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: lastSaveKey)

            lastSaveTimestamp = Date()
        } catch {
            #if DEBUG
            print("Failed to save user profile: \(error)")
            #endif
            errorState.showData(.encodingFailed)
        }
    }

    /// Load user profile from UserDefaults with recovery
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
            var user = try JSONDecoder().decode(UserProfile.self, from: data)

            // Validate loaded data
            if DataValidator.validateUserProfile(user) != nil {
                // Try to repair
                DataValidator.repairUserProfile(&user)

                // Revalidate after repair
                if DataValidator.validateUserProfile(user) != nil {
                    throw DataError.corruptedData
                }

                // Save repaired data
                currentUser = user
                saveUserToStorage()
                didRecoverFromCorruption = true
            } else {
                currentUser = user
            }

            // Load last save timestamp
            if let timestamp = UserDefaults.standard.object(forKey: lastSaveKey) as? TimeInterval {
                lastSaveTimestamp = Date(timeIntervalSince1970: timestamp)
            }

        } catch {
            #if DEBUG
            print("Failed to load user profile: \(error)")
            #endif

            // Attempt recovery from backup
            if attemptRecoveryFromBackup() {
                didRecoverFromCorruption = true
            } else {
                // Clear corrupted data completely
                UserDefaults.standard.removeObject(forKey: userProfileKey)
                UserDefaults.standard.removeObject(forKey: backupProfileKey)
                errorState.showData(.corruptedData)
            }
        }
    }

    /// Attempt to recover user profile from backup
    private func attemptRecoveryFromBackup() -> Bool {
        guard let backupData = UserDefaults.standard.data(forKey: backupProfileKey) else {
            return false
        }

        do {
            var user = try JSONDecoder().decode(UserProfile.self, from: backupData)

            // Validate and repair if needed
            if DataValidator.validateUserProfile(user) != nil {
                DataValidator.repairUserProfile(&user)
            }

            currentUser = user

            // Restore from backup to main storage
            UserDefaults.standard.set(backupData, forKey: userProfileKey)
            UserDefaults.standard.set(true, forKey: hasOnboardedKey)

            #if DEBUG
            print("Successfully recovered user profile from backup")
            #endif
            return true

        } catch {
            Log.error("Failed to recover from backup: \(error)")
            return false
        }
    }

    /// Force save current state (useful before app terminates)
    func forceSave() {
        saveUserToStorage()
    }

    /// Check if critical data is missing and re-onboarding is needed
    var needsReonboarding: Bool {
        guard let user = currentUser else { return false }
        return user.displayName.isEmpty || DataValidator.validateUserProfile(user) != nil
    }

    /// Export user data as JSON (for debugging/support)
    func exportUserData() -> String? {
        guard let user = currentUser else { return nil }
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(user)
            return String(data: data, encoding: .utf8)
        } catch {
            return nil
        }
    }

    // MARK: - GDPR Data Export

    /// Export complete user data for GDPR compliance
    /// Returns a UserDataExport struct containing all user data
    func exportUserDataGDPR() -> UserDataExport? {
        return UserDataExportBuilder.build(from: self)
    }

    /// Export complete user data as formatted JSON string
    func exportUserDataAsJSON() -> String? {
        guard let export = exportUserDataGDPR() else { return nil }
        return UserDataExportBuilder.toJSON(export)
    }

    /// Export complete user data as Data for file sharing
    func exportUserDataAsData() -> Data? {
        guard let export = exportUserDataGDPR() else { return nil }
        return UserDataExportBuilder.toData(export)
    }

    /// Generate filename for data export
    func generateExportFilename() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HHmmss"
        let timestamp = dateFormatter.string(from: Date())
        return "CosmoTrader_DataExport_\(timestamp).json"
    }

    // MARK: - GDPR Data Deletion

    /// Delete all user data (GDPR right to erasure)
    /// This permanently removes all user data from the device
    func deleteAllUserData() {
        // Track analytics event before deletion
        AnalyticsService.shared.track(.dataDeleted)

        // Reset analytics identity
        AnalyticsService.shared.resetIdentity()

        // Clear current user
        currentUser = nil

        // Clear all UserDefaults keys related to the app
        let userDefaultsKeys = [
            userProfileKey,
            backupProfileKey,
            hasOnboardedKey,
            lastSaveKey,
            // Subscription keys (from SubscriptionManager.Keys)
            "subscription_isPremium",
            "subscription_trialStartDate",
            "subscription_trialUsed",
            "subscription_dailySwipeCount",
            "subscription_lastSwipeDate",
            "subscription_lastHoroscopeDate",
            "subscription_horoscopeCountToday",
            "subscription_roastCountToday",
            "subscription_lastRoastDate",
            "subscription_expirationDate",
            "subscription_lastCheck",
            // Notification keys (from NotificationService.StorageKeys)
            "notifications_hasRequested",
            "notifications_status",
            "notifications_dailyHoroscope",
            "notifications_dailyHoroscopeTime",
            "notifications_moonPhase",
            "notifications_mercuryRetrograde",
            "notifications_portfolioAlerts",
            "notifications_ipoAlerts",
            "notifications_cosmicRoast",
            "notifications_weeklySummary",
            "notifications_signSeason",
            // Appearance keys (from UserDataExport)
            "appearance_showCompatibility",
            "appearance_showElements",
            "appearance_animations",
            // Audio keys (from TerminalAudioService.StorageKeys)
            "terminalAudio_enabled",
            "terminalAudio_ambientVolume",
            "terminalAudio_effectsVolume",
            // Analytics keys (from AnalyticsService)
            "analytics_opted_out",
            Self.firstRunDataSetupSkippedKey,
            Self.firstRunDataSetupCompletedKey,
            // Moon phase keys (from MoonPhaseService)
            "notifyOnFullMoon",
            "notifyOnNewMoon",
            "notifyOnMoonInUserSign"
        ]

        for key in userDefaultsKeys {
            UserDefaults.standard.removeObject(forKey: key)
        }

        // Synchronize UserDefaults
        UserDefaults.standard.synchronize()

        // Reset state
        errorState.clear()
        didRecoverFromCorruption = false
        lastSaveTimestamp = nil
        isOfflineMode = false
        hasSkippedFirstRunDataSetup = false
        hasCompletedFirstRunDataSetup = false

        Log.debug("[AppState] All user data has been deleted")
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
