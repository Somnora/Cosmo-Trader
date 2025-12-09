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

@Observable
class ProfileViewModel {

    // MARK: - Properties

    /// The current user's profile
    var user: UserProfile

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

    // MARK: - Initialization

    init(user: UserProfile = .sampleWithHoldings) {
        self.user = user
        self.editingName = user.displayName
        self.editingBirthDate = user.birthDate
    }

    // MARK: - User Display Properties

    /// Fun title based on sign and element
    var cosmicTitle: String {
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
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: user.birthDate)
    }

    /// Member since formatted
    var memberSinceFormatted: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: user.memberSince)
    }

    /// Cosmic journey duration
    var cosmicJourneyDuration: String {
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
        switch user.sunSign {
        case .aries:
            return ["Bold decision-making", "First-mover advantage", "High risk tolerance"]
        case .taurus:
            return ["Patient long-term focus", "Value recognition", "Steady accumulation"]
        case .gemini:
            return ["Quick information processing", "Diversification instincts", "Adaptable strategies"]
        case .cancer:
            return ["Intuitive market timing", "Protective of gains", "Strong risk management"]
        case .leo:
            return ["Confident positioning", "Brand recognition", "Leadership stock picks"]
        case .virgo:
            return ["Detail-oriented analysis", "Thorough due diligence", "Optimization skills"]
        case .libra:
            return ["Portfolio balance", "Partnership opportunities", "Fair value assessment"]
        case .scorpio:
            return ["Deep research ability", "Contrarian insights", "Transformation plays"]
        case .sagittarius:
            return ["Global market vision", "Growth stock intuition", "Optimistic outlook"]
        case .capricorn:
            return ["Disciplined approach", "Long-term planning", "Institutional quality picks"]
        case .aquarius:
            return ["Innovation spotting", "Tech sector strength", "Unconventional wins"]
        case .pisces:
            return ["Intuitive timing", "Creative sector insights", "Emotional intelligence"]
        }
    }

    /// Weaknesses based on sun sign
    var investorWeaknesses: [String] {
        switch user.sunSign {
        case .aries:
            return ["Impatient with slow gains", "Overtrading tendency", "Ignores red flags"]
        case .taurus:
            return ["Misses momentum plays", "Stubborn on losing positions", "Change-resistant"]
        case .gemini:
            return ["Analysis paralysis", "Scattered focus", "Overthinks entries"]
        case .cancer:
            return ["Emotional attachment", "Fear-based selling", "Comfort zone bias"]
        case .leo:
            return ["Ego-driven decisions", "Overlooks small caps", "Pride prevents pivots"]
        case .virgo:
            return ["Perfectionism delays", "Misses forest for trees", "Overcautious"]
        case .libra:
            return ["Decision paralysis", "Avoids necessary risks", "People-pleasing trades"]
        case .scorpio:
            return ["Obsessive positions", "Revenge trading", "Trust issues with advice"]
        case .sagittarius:
            return ["Overextended positions", "Ignores details", "Premature optimism"]
        case .capricorn:
            return ["Misses disruption plays", "Too conservative", "Slow to adapt"]
        case .aquarius:
            return ["Contrarian for its own sake", "Detached from fundamentals", "Too early on trends"]
        case .pisces:
            return ["Wishful thinking", "Boundary issues", "Easily influenced"]
        }
    }

    /// Best stock sign matches
    var bestMatches: [ZodiacSign] {
        user.sunSign.compatibleSigns
    }

    /// Challenging stock sign matches
    var challengingMatches: [ZodiacSign] {
        // Signs that are traditionally challenging
        let allSigns = ZodiacSign.allCases
        let compatible = Set(user.sunSign.compatibleSigns)
        return allSigns.filter { !compatible.contains($0) && $0 != user.sunSign }.prefix(4).map { $0 }
    }

    // MARK: - Portfolio Stats

    /// Formatted total portfolio value
    var formattedPortfolioValue: String {
        formatCurrency(user.totalPortfolioValue)
    }

    /// Formatted daily change
    var formattedDailyChange: String {
        let sign = user.totalDailyChange >= 0 ? "+" : ""
        return sign + formatCurrency(user.totalDailyChange)
    }

    /// Formatted daily change percent
    var formattedDailyChangePercent: String {
        user.formattedDailyChangePercent
    }

    /// Is portfolio positive today?
    var isPositive: Bool {
        user.isPortfolioPositive
    }

    /// Number of holdings
    var holdingsCount: Int {
        user.numberOfHoldings
    }

    /// Dominant element in portfolio
    var dominantElement: ZodiacSign.Element? {
        let holdings = user.portfolio.filter { $0.sharesOwned > 0 }
        guard !holdings.isEmpty else { return nil }

        var elementValues: [ZodiacSign.Element: Double] = [:]
        for stock in holdings {
            let element = stock.zodiacSign.element
            elementValues[element, default: 0] += stock.totalValue
        }

        return elementValues.max(by: { $0.value < $1.value })?.key
    }

    /// Most compatible stock in portfolio
    var mostCompatibleStock: Stock? {
        let holdings = user.portfolio.filter { $0.sharesOwned > 0 }
        return holdings.max(by: {
            user.compatibility(with: $0).score < user.compatibility(with: $1).score
        })
    }

    /// Least compatible stock in portfolio
    var leastCompatibleStock: Stock? {
        let holdings = user.portfolio.filter { $0.sharesOwned > 0 }
        return holdings.min(by: {
            user.compatibility(with: $0).score < user.compatibility(with: $1).score
        })
    }

    /// All-time gain/loss (mocked for now)
    var allTimeGainLoss: Double {
        // Mock: assume 15% gain on portfolio
        user.totalPortfolioValue * 0.15
    }

    var formattedAllTimeGainLoss: String {
        let sign = allTimeGainLoss >= 0 ? "+" : ""
        return sign + formatCurrency(allTimeGainLoss)
    }

    // MARK: - Actions

    /// Start editing profile
    func startEditing() {
        editingName = user.displayName
        editingBirthDate = user.birthDate
        isEditing = true
    }

    /// Save profile changes
    func saveProfile() {
        user.displayName = editingName
        // Note: birthDate is let, so in a real app you'd need a mutable version
        isEditing = false
    }

    /// Cancel editing
    func cancelEditing() {
        editingName = user.displayName
        editingBirthDate = user.birthDate
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
        """
        My Cosmic Investor Profile

        \(user.sunSign.symbol) \(user.sunSign.displayName) Investor
        Element: \(user.sunSign.element.emoji) \(user.sunSign.element.displayName)
        Modality: \(user.sunSign.modality.displayName)

        "\(user.sunSign.corporatePersonality)"

        Strengths: \(investorStrengths.joined(separator: ", "))

        Portfolio: \(formattedPortfolioValue)
        Average Compatibility: \(user.averagePortfolioCompatibility)%

        #CosmicTrader #\(user.sunSign.displayName)Investor
        """
    }

    /// Sign out the user
    func signOut() {
        // In real app, would clear auth tokens, navigate to login
        print("User signed out")
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
        SettingItem(name: "Price Alerts", icon: "chart.line.uptrend.xyaxis", category: .notifications, isEnabled: false),
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
