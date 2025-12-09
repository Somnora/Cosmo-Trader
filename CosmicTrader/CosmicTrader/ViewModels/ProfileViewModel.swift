import Foundation

/// ProfileViewModel
/// -----------------
/// The "brain" for the Profile tab.
///
/// Handles user data, settings, and account management.

@Observable
class ProfileViewModel {

    // MARK: - Properties

    /// The current user
    var user: User = User.sample

    /// Is the user editing their profile?
    var isEditing: Bool = false

    /// Available settings options
    var settings: [SettingItem] = SettingItem.defaults

    // MARK: - Computed Properties

    /// Formatted member since date
    var memberSinceFormatted: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: user.memberSince)
    }

    /// Formatted portfolio value
    var formattedPortfolioValue: String {
        formatCurrency(user.portfolioValue)
    }

    /// Formatted daily change
    var formattedDailyChange: String {
        let sign = user.dailyChange >= 0 ? "+" : ""
        return sign + formatCurrency(user.dailyChange)
    }

    // MARK: - Methods

    /// Save profile changes
    func saveProfile() {
        isEditing = false
        // In real app, would save to server/local storage
    }

    /// Toggle a setting
    func toggleSetting(_ setting: SettingItem) {
        if let index = settings.firstIndex(where: { $0.id == setting.id }) {
            settings[index].isEnabled.toggle()
        }
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
        return formatter.string(from: NSNumber(value: value)) ?? "$0.00"
    }
}

// MARK: - Supporting Types

/// A toggleable setting item
struct SettingItem: Identifiable {
    let id = UUID()
    let name: String
    let icon: String
    var isEnabled: Bool

    static let defaults: [SettingItem] = [
        SettingItem(name: "Push Notifications", icon: "bell.fill", isEnabled: true),
        SettingItem(name: "Daily Horoscope Alerts", icon: "sparkles", isEnabled: true),
        SettingItem(name: "Price Alerts", icon: "chart.line.uptrend.xyaxis", isEnabled: false),
        SettingItem(name: "Dark Mode", icon: "moon.fill", isEnabled: true),
        SettingItem(name: "Haptic Feedback", icon: "hand.tap.fill", isEnabled: true)
    ]
}
