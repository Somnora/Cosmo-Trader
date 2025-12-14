//
//  ProfilePage.swift
//  Cosmo TraderUITests
//
//  Page Object for the Profile tab screen.
//

import XCTest

class ProfilePage: BasePage {

    // MARK: - Element Identifiers

    private enum Identifiers {
        static let profileTab = "Profile"
        static let userNameLabel = "userName"
        static let zodiacSignLabel = "zodiacSign"
        static let cosmicTitleBadge = "cosmicTitle"
        static let portfolioStatsCard = "portfolioStats"
        static let settingsSection = "settings"
        static let upgradeButton = "Upgrade"
        static let signOutButton = "Sign Out"
        static let editProfileButton = "Edit Profile"
    }

    // MARK: - Elements

    var profileTab: XCUIElement {
        app.tabBars.buttons[Identifiers.profileTab]
    }

    var userNameLabel: XCUIElement {
        app.staticTexts[Identifiers.userNameLabel]
    }

    var zodiacSignLabel: XCUIElement {
        app.staticTexts[Identifiers.zodiacSignLabel]
    }

    var cosmicTitleBadge: XCUIElement {
        app.staticTexts[Identifiers.cosmicTitleBadge]
    }

    var portfolioStatsCard: XCUIElement {
        app.otherElements[Identifiers.portfolioStatsCard]
    }

    var upgradeButton: XCUIElement {
        app.buttons[Identifiers.upgradeButton]
    }

    var signOutButton: XCUIElement {
        app.buttons[Identifiers.signOutButton]
    }

    var editProfileButton: XCUIElement {
        app.buttons[Identifiers.editProfileButton]
    }

    // MARK: - Screen Detection

    func isDisplayed() -> Bool {
        return profileTab.isSelected ||
               app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Profile'")).count > 0 ||
               userNameLabel.exists
    }

    // MARK: - Navigation

    @discardableResult
    func navigateToProfile() -> ProfilePage {
        navigateToTab(.profile)
        _ = waitForElement(profileTab)
        return self
    }

    // MARK: - User Information

    /// Get displayed user name
    var displayedUserName: String? {
        if userNameLabel.exists {
            return userNameLabel.label
        }
        // Search for name in header area
        let nameLabels = app.staticTexts.allElementsBoundByIndex
        for label in nameLabels.prefix(5) {
            let text = label.label
            // Name typically has first letter capitalized and reasonable length
            if text.count > 2 && text.count < 50 && text.first?.isUppercase == true {
                return text
            }
        }
        return nil
    }

    /// Get displayed zodiac sign
    var displayedZodiacSign: String? {
        if zodiacSignLabel.exists {
            return zodiacSignLabel.label
        }
        let signs = ["Aries", "Taurus", "Gemini", "Cancer", "Leo", "Virgo",
                     "Libra", "Scorpio", "Sagittarius", "Capricorn", "Aquarius", "Pisces"]
        for sign in signs {
            if app.staticTexts[sign].exists {
                return sign
            }
        }
        return nil
    }

    /// Get displayed cosmic title
    var displayedCosmicTitle: String? {
        if cosmicTitleBadge.exists {
            return cosmicTitleBadge.label
        }
        // Look for cosmic title patterns
        let titles = ["Stellar Scout", "Cosmic Navigator", "Celestial Investor", "Galactic Trader", "Oracle"]
        for title in titles {
            if app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", title)).count > 0 {
                return title
            }
        }
        return nil
    }

    /// Get displayed element (Fire, Earth, Air, Water)
    var displayedElement: String? {
        let elements = ["Fire", "Earth", "Air", "Water"]
        for element in elements {
            if app.staticTexts[element].exists {
                return element
            }
        }
        return nil
    }

    // MARK: - Portfolio Stats

    /// Check if portfolio stats are displayed
    var hasPortfolioStats: Bool {
        return portfolioStatsCard.exists ||
               app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Holdings' OR label CONTAINS 'Value' OR label CONTAINS 'Performance'")).count > 0
    }

    /// Get total holdings count if displayed
    var displayedHoldingsCount: String? {
        let holdingsLabels = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Holdings' OR label CONTAINS 'stocks' OR label CONTAINS 'positions'"))
        return holdingsLabels.firstMatch.exists ? holdingsLabels.firstMatch.label : nil
    }

    /// Get portfolio value if displayed
    var displayedPortfolioValue: String? {
        let valueLabels = app.staticTexts.matching(NSPredicate(format: "label CONTAINS '$'"))
        return valueLabels.firstMatch.exists ? valueLabels.firstMatch.label : nil
    }

    // MARK: - Subscription Status

    /// Check if user is premium/oracle
    var isPremiumUser: Bool {
        return app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Oracle' OR label CONTAINS 'Premium' OR label CONTAINS 'Pro'")).count > 0
    }

    /// Check if upgrade prompt is shown
    var showsUpgradePrompt: Bool {
        return upgradeButton.exists ||
               app.buttons.matching(NSPredicate(format: "label CONTAINS 'Upgrade' OR label CONTAINS 'Subscribe'")).count > 0
    }

    // MARK: - Actions

    /// Tap upgrade button
    @discardableResult
    func tapUpgrade() -> PaywallPage {
        if upgradeButton.exists {
            tapElement(upgradeButton)
        } else {
            let upgradeBtn = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Upgrade' OR label CONTAINS 'Subscribe'")).firstMatch
            tapElement(upgradeBtn)
        }
        return PaywallPage(app: app)
    }

    /// Tap edit profile button
    @discardableResult
    func tapEditProfile() -> ProfilePage {
        if editProfileButton.exists {
            tapElement(editProfileButton)
        } else {
            let editBtn = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Edit'")).firstMatch
            tapElement(editBtn)
        }
        return self
    }

    /// Tap sign out button
    @discardableResult
    func tapSignOut() -> ProfilePage {
        // Scroll to find sign out if needed
        scrollToBottom()
        if signOutButton.exists {
            tapElement(signOutButton)
        } else {
            let signOutBtn = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Sign Out' OR label CONTAINS 'Log Out'")).firstMatch
            tapElement(signOutBtn)
        }
        return self
    }

    /// Tap on settings row by name
    @discardableResult
    func tapSettingsRow(_ rowName: String) -> ProfilePage {
        let row = app.cells.matching(NSPredicate(format: "label CONTAINS %@", rowName)).firstMatch
        if row.exists {
            tapElement(row)
        } else {
            let button = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", rowName)).firstMatch
            tapElement(button)
        }
        return self
    }

    // MARK: - Settings Navigation

    /// Navigate to Notifications settings
    @discardableResult
    func tapNotifications() -> ProfilePage {
        return tapSettingsRow("Notifications")
    }

    /// Navigate to Privacy settings
    @discardableResult
    func tapPrivacy() -> ProfilePage {
        return tapSettingsRow("Privacy")
    }

    /// Navigate to Help/Support
    @discardableResult
    func tapHelp() -> ProfilePage {
        return tapSettingsRow("Help")
    }

    /// Navigate to About
    @discardableResult
    func tapAbout() -> ProfilePage {
        return tapSettingsRow("About")
    }

    // MARK: - Scroll Actions

    /// Scroll to settings section
    @discardableResult
    func scrollToSettings() -> ProfilePage {
        scrollToBottom()
        return self
    }

    /// Scroll to top of profile
    @discardableResult
    func scrollToTop() -> ProfilePage {
        app.swipeDown()
        return self
    }

    /// Scroll to bottom
    @discardableResult
    func scrollToBottom() -> ProfilePage {
        app.swipeUp()
        app.swipeUp()
        return self
    }

    // MARK: - Assertions

    /// Assert profile is displayed
    func assertProfileDisplayed() {
        XCTAssertTrue(isDisplayed(), "Profile screen should be displayed")
    }

    /// Assert user name is shown
    func assertUserNameShown() {
        XCTAssertNotNil(displayedUserName, "User name should be displayed")
    }

    /// Assert zodiac sign is shown
    func assertZodiacSignShown() {
        XCTAssertNotNil(displayedZodiacSign, "Zodiac sign should be displayed")
    }

    /// Assert expected user name
    func assertUserName(_ expected: String) {
        XCTAssertEqual(displayedUserName, expected, "User name should match expected")
    }

    /// Assert expected zodiac sign
    func assertZodiacSign(_ expected: String) {
        XCTAssertEqual(displayedZodiacSign, expected, "Zodiac sign should match expected")
    }

    /// Assert cosmic title is shown
    func assertCosmicTitleShown() {
        XCTAssertNotNil(displayedCosmicTitle, "Cosmic title should be displayed")
    }

    /// Assert portfolio stats are shown
    func assertPortfolioStatsShown() {
        XCTAssertTrue(hasPortfolioStats, "Portfolio stats should be displayed")
    }

    /// Assert user is premium
    func assertIsPremium() {
        XCTAssertTrue(isPremiumUser, "User should have premium status")
    }

    /// Assert user is not premium (shows upgrade)
    func assertIsNotPremium() {
        XCTAssertTrue(showsUpgradePrompt, "Upgrade prompt should be shown for non-premium user")
    }
}
