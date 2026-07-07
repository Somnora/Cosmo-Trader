import Foundation
import SwiftUI

// MARK: - ProfileViewModel
// ========================
// The brain for the Profile tab - the user's cosmic investor identity.
//
// Responsibilities:
// - User profile data and editing
// - Portfolio stats calculations
// - Settings management
// - Share profile functionality
//
// Now works with AppState for shared user data.

@Observable
class ProfileViewModel {

    // MARK: - Properties

    /// Reference to shared app state
    private var appState: AppState

    /// Is the user editing their profile?
    var isEditing: Bool = false

    /// Is birth date picker showing?
    var showingBirthDatePicker: Bool = false

    /// Is share sheet showing?
    var showingShareSheet: Bool = false

    /// Available settings options
    var settings: [SettingItem] = SettingItem.defaults

    /// Temporary name for editing
    var editingName: String = ""

    /// Temporary birth date for editing
    var editingBirthDate: Date = Date()

    /// Temporary time of birth for editing (nil = unknown)
    var editingTimeOfBirth: Date?

    /// Whether user knows their birth time (for toggle in edit sheet)
    var knowsBirthTime: Bool = false

    // MARK: - Initialization

    init(appState: AppState = AppState.shared) {
        self.appState = appState
        if let currentUser = appState.currentUser {
            self.editingName = currentUser.displayName
            self.editingBirthDate = currentUser.birthDate
            self.editingTimeOfBirth = currentUser.timeOfBirth
            self.knowsBirthTime = currentUser.timeOfBirth != nil
        }
    }

    // MARK: - User Access

    /// The current user's profile (nil if not logged in)
    var user: UserProfile? {
        appState.currentUser
    }

    // MARK: - User Display Properties

    /// Fun title based on sign and element
    var cosmicTitle: String {
        guard let user = user else { return "Cosmic Investor" }
        let element = user.sunSign.element.displayName
        let sign = user.sunSign.displayName
        let titles = [
            "\(sign) Investor",
            "\(element) Sign Trader",
            "Cosmic \(sign)",
            "\(element) Energy Investor"
        ]
        // Use consistent title based on user ID
        let index = abs(user.id.hashValue) % titles.count
        return titles[index]
    }

    /// Formatted birth date
    var formattedBirthDate: String {
        guard let user = user else { return "" }
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: user.birthDate)
    }

    /// Member since formatted
    var memberSinceFormatted: String {
        guard let user = user else { return "" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: user.memberSince)
    }

    /// Cosmic journey duration
    var cosmicJourneyDuration: String {
        guard let user = user else { return "" }
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: user.memberSince, to: Date())

        if let years = components.year, years > 0 {
            return years == 1 ? "1 year" : "\(years) years"
        } else if let months = components.month, months > 0 {
            return months == 1 ? "1 month" : "\(months) months"
        } else if let days = components.day, days > 0 {
            return days == 1 ? "1 day" : "\(days) days"
        } else {
            return "Just started"
        }
    }

    // MARK: - Investor Profile Properties

    /// Strengths based on sun sign
    var investorStrengths: [String] {
        guard let user = user else { return [] }
        switch user.sunSign {
        case .aries:
            return ["Drawn to bold themes", "Notices fresh starts", "Comfortable with intensity"]
        case .taurus:
            return ["Patient with slow cycles", "Attentive to durability", "Prefers steady rhythm"]
        case .gemini:
            return ["Quick with new information", "Curious across categories", "Adaptable in perspective"]
        case .cancer:
            return ["Protective of familiar themes", "Attentive to emotional tone", "Careful with comfort zones"]
        case .leo:
            return ["Confident sense of style", "Drawn to brand-name leaders", "Notices standout stories"]
        case .virgo:
            return ["Detail-oriented reading", "Thorough with context", "Prefers organized information"]
        case .libra:
            return ["Drawn to balance", "Attentive to relationships", "Notices symmetry and fairness"]
        case .scorpio:
            return ["Comfortable with depth", "Notices hidden pressure", "Drawn to transformation stories"]
        case .sagittarius:
            return ["Wide-angle curiosity", "Drawn to growth stories", "Naturally optimistic lens"]
        case .capricorn:
            return ["Disciplined attention", "Patient with long arcs", "Drawn to established quality"]
        case .aquarius:
            return ["Notices innovation early", "Drawn to future-facing themes", "Comfortable with unusual angles"]
        case .pisces:
            return ["Intuitive pattern sense", "Drawn to creative themes", "Attentive to emotional undercurrents"]
        }
    }

    /// Weaknesses based on sun sign
    var investorWeaknesses: [String] {
        guard let user = user else { return [] }
        switch user.sunSign {
        case .aries:
            return ["Impatient with slow rhythms", "Easily bored by quiet periods", "May miss softer warnings"]
        case .taurus:
            return ["Slow to welcome change", "Attached to familiar stories", "May resist fresh evidence"]
        case .gemini:
            return ["Scattered attention", "Overthinks simple reads", "May chase too many threads"]
        case .cancer:
            return ["Strong emotional attachment", "Cautious about uncertainty", "Comfort-zone bias"]
        case .leo:
            return ["Pride can color the read", "May overlook quieter names", "Slow to soften a strong opinion"]
        case .virgo:
            return ["Perfectionism delays clarity", "Can miss the forest for trees", "Sometimes overcautious"]
        case .libra:
            return ["Can linger in comparison", "Avoids uncomfortable tension", "Too influenced by outside tone"]
        case .scorpio:
            return ["Can fixate on one story", "Intensity clouds neutrality", "Slow to trust outside context"]
        case .sagittarius:
            return ["Can stretch a narrative", "May skip small details", "Premature optimism"]
        case .capricorn:
            return ["Skeptical of disruption", "Sometimes too guarded", "Slow to adapt tone"]
        case .aquarius:
            return ["Different for its own sake", "Can feel detached from basics", "Often early to new themes"]
        case .pisces:
            return ["Wishful thinking", "Blurry boundaries", "Easily influenced by mood"]
        }
    }

    /// Best stock sign matches
    var bestMatches: [ZodiacSign] {
        user?.sunSign.compatibleSigns ?? []
    }

    /// Challenging stock sign matches
    var challengingMatches: [ZodiacSign] {
        guard let user = user else { return [] }
        let allSigns = ZodiacSign.allCases
        let compatible = Set(user.sunSign.compatibleSigns)
        return allSigns.filter { !compatible.contains($0) && $0 != user.sunSign }.prefix(4).map { $0 }
    }

    // MARK: - Portfolio Stats

    /// Formatted total portfolio value
    var formattedPortfolioValue: String {
        guard let user = user else { return "$0" }
        return formatCurrency(user.totalPortfolioValue)
    }

    /// Formatted daily change
    var formattedDailyChange: String {
        guard let user = user else { return "$0" }
        let sign = user.totalDailyChange >= 0 ? "+" : ""
        return sign + formatCurrency(user.totalDailyChange)
    }

    /// Formatted daily change percent
    var formattedDailyChangePercent: String {
        user?.formattedDailyChangePercent ?? "0%"
    }

    /// Is portfolio positive today?
    var isPositive: Bool {
        user?.isPortfolioPositive ?? true
    }

    /// Number of holdings
    var holdingsCount: Int {
        user?.numberOfHoldings ?? 0
    }

    /// Dominant element in portfolio
    var dominantElement: ZodiacSign.Element? {
        guard let user = user else { return nil }
        let holdings = user.portfolio.filter { $0.sharesOwned > 0 }
        guard !holdings.isEmpty else { return nil }

        var elementValues: [ZodiacSign.Element: Double] = [:]
        for stock in holdings {
            guard let element = stock.foundedElement else { continue }
            elementValues[element, default: 0] += stock.totalValue
        }

        return elementValues.max(by: { $0.value < $1.value })?.key
    }

    /// Most compatible stock in portfolio
    var mostCompatibleStock: Stock? {
        guard let user = user else { return nil }
        let holdings = user.portfolio.filter { $0.sharesOwned > 0 && $0.foundedZodiacSign != nil }
        return holdings.max(by: {
            (user.verifiedCompatibility(with: $0)?.score ?? 0) < (user.verifiedCompatibility(with: $1)?.score ?? 0)
        })
    }

    /// Least compatible stock in portfolio
    var leastCompatibleStock: Stock? {
        guard let user = user else { return nil }
        let holdings = user.portfolio.filter { $0.sharesOwned > 0 && $0.foundedZodiacSign != nil }
        return holdings.min(by: {
            (user.verifiedCompatibility(with: $0)?.score ?? 0) < (user.verifiedCompatibility(with: $1)?.score ?? 0)
        })
    }

    // All-time P/L lives on the Portfolio tab (PortfolioAllTimePLSummary),
    // where per-symbol quote provenance exists to gate it honestly.

    // MARK: - Actions

    /// Start editing profile
    func startEditing() {
        guard let user = user else { return }
        editingName = user.displayName
        editingBirthDate = user.birthDate
        editingTimeOfBirth = user.timeOfBirth
        knowsBirthTime = user.timeOfBirth != nil
        isEditing = true
    }

    /// Save profile changes
    func saveProfile() {
        guard let user = user else { return }
        appState.updateDisplayName(editingName)

        // Check if birth date changed (this will recalculate sun sign)
        if editingBirthDate != user.birthDate {
            appState.updateBirthDate(editingBirthDate)
        }

        // Update time of birth
        let newTimeOfBirth = knowsBirthTime ? editingTimeOfBirth : nil
        if newTimeOfBirth != user.timeOfBirth {
            appState.updateTimeOfBirth(newTimeOfBirth)
        }

        isEditing = false
    }

    /// Cancel editing
    func cancelEditing() {
        guard let user = user else { return }
        editingName = user.displayName
        editingBirthDate = user.birthDate
        editingTimeOfBirth = user.timeOfBirth
        knowsBirthTime = user.timeOfBirth != nil
        isEditing = false
    }

    /// Toggle a setting
    func toggleSetting(_ setting: SettingItem) {
        if let index = settings.firstIndex(where: { $0.id == setting.id }) {
            settings[index].isEnabled.toggle()
        }
    }

    /// Generate shareable profile text
    var shareableProfileText: String {
        guard let user = user else { return "" }
        let averageCompatibility = user.averagePortfolioCompatibility.map { "\($0)%" } ?? "Unknown"

        return """
        My Cosmic Investor Profile

        \(user.sunSign.textSymbol) \(user.sunSign.displayName) Investor
        Element: \(user.sunSign.element.displayName)
        Modality: \(user.sunSign.modality.displayName)

        "\(user.sunSign.corporatePersonality)"

        Strengths: \(investorStrengths.joined(separator: ", "))

        Portfolio: \(formattedPortfolioValue)
        Average Compatibility: \(averageCompatibility)

        #CosmicTrader #\(user.sunSign.displayName)Investor
        """
    }

    /// Sign out the user
    func signOut() {
        appState.resetOnboarding()
    }

    // MARK: - Private Helpers

    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "$0"
    }
}

// MARK: - Supporting Types

/// A toggleable setting item
struct SettingItem: Identifiable {
    let id = UUID()
    let name: String
    let icon: String
    let category: SettingCategory
    var isEnabled: Bool

    enum SettingCategory {
        case notifications
        case appearance
        case preferences
    }

    static let defaults: [SettingItem] = [
        // Notifications
        SettingItem(name: "Daily Horoscope", icon: "sparkles", category: .notifications, isEnabled: true),
        SettingItem(name: "Astro Alerts", icon: "moon.stars.fill", category: .notifications, isEnabled: true),
        SettingItem(name: "Portfolio Check Reminders", icon: "chart.line.uptrend.xyaxis", category: .notifications, isEnabled: false),
        SettingItem(name: "Weekly Digest", icon: "envelope.fill", category: .notifications, isEnabled: true),

        // Appearance
        SettingItem(name: "Dark Mode", icon: "moon.fill", category: .appearance, isEnabled: true),
        SettingItem(name: "Haptic Feedback", icon: "hand.tap.fill", category: .appearance, isEnabled: true),

        // Preferences
        SettingItem(name: "Show Compatibility %", icon: "percent", category: .preferences, isEnabled: true),
        SettingItem(name: "Element Animations", icon: "wand.and.stars", category: .preferences, isEnabled: true)
    ]

    static var notifications: [SettingItem] {
        defaults.filter { $0.category == .notifications }
    }

    static var appearance: [SettingItem] {
        defaults.filter { $0.category == .appearance }
    }

    static var preferences: [SettingItem] {
        defaults.filter { $0.category == .preferences }
    }
}
