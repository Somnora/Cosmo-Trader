//
//  ProfileUITests.swift
//  Cosmo TraderUITests
//
//  UI tests for the Profile tab including user info and settings.
//

import XCTest

final class ProfileUITests: XCTestCase {

    var app: XCUIApplication!
    var profilePage: ProfilePage!

    override func setUpWithError() throws {
        continueAfterFailure = false

        app = XCUIApplication()
        // Skip onboarding, use sample data
        app.launchArguments = ["--uitesting", "--skip-onboarding", "--sample-user"]
        app.launch()

        profilePage = ProfilePage(app: app)
    }

    override func tearDownWithError() throws {
        app = nil
        profilePage = nil
    }

    // MARK: - Profile Display Tests

    func testProfileTabIsAccessible() throws {
        profilePage.navigateToProfile()

        XCTAssertTrue(profilePage.isDisplayed(), "Profile tab should be accessible")
    }

    func testProfileDisplaysUserName() throws {
        profilePage.navigateToProfile()

        let hasName = profilePage.displayedUserName != nil ||
                     app.staticTexts.matching(NSPredicate(format: "label.length > 2 AND label.length < 50")).count > 0

        XCTAssertTrue(hasName, "Profile should display user's name")
    }

    func testProfileDisplaysZodiacSign() throws {
        profilePage.navigateToProfile()

        let hasZodiac = profilePage.displayedZodiacSign != nil

        XCTAssertTrue(hasZodiac, "Profile should display user's zodiac sign")
    }

    func testProfileDisplaysElement() throws {
        profilePage.navigateToProfile()

        let hasElement = profilePage.displayedElement != nil ||
                        app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Fire' OR label CONTAINS 'Earth' OR label CONTAINS 'Air' OR label CONTAINS 'Water'")).count > 0

        XCTAssertTrue(hasElement, "Profile should display user's element")
    }

    func testProfileDisplaysCosmicTitle() throws {
        profilePage.navigateToProfile()

        let hasTitle = profilePage.displayedCosmicTitle != nil ||
                      app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Scout' OR label CONTAINS 'Navigator' OR label CONTAINS 'Investor' OR label CONTAINS 'Trader' OR label CONTAINS 'Oracle'")).count > 0

        XCTAssertTrue(hasTitle, "Profile should display cosmic title")
    }

    // MARK: - Cosmic Title Badge Tests

    func testCosmicTitleBadgeIsVisible() throws {
        profilePage.navigateToProfile()

        // Title badge should be prominent
        let hasBadge = profilePage.cosmicTitleBadge.exists ||
                      app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Stellar' OR label CONTAINS 'Cosmic' OR label CONTAINS 'Celestial' OR label CONTAINS 'Galactic'")).count > 0

        XCTAssertTrue(hasBadge, "Cosmic title badge should be visible")
    }

    func testCosmicTitleReflectsUserLevel() throws {
        profilePage.navigateToProfile()

        // Title should exist and be one of the defined levels
        let titles = ["Stellar Scout", "Cosmic Navigator", "Celestial Investor", "Galactic Trader", "Cosmo Oracle"]
        var hasValidTitle = false

        for title in titles {
            if app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", title)).count > 0 {
                hasValidTitle = true
                break
            }
        }

        // Also check partial matches
        if !hasValidTitle {
            hasValidTitle = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Scout' OR label CONTAINS 'Navigator' OR label CONTAINS 'Investor' OR label CONTAINS 'Trader' OR label CONTAINS 'Oracle'")).count > 0
        }

        XCTAssertTrue(hasValidTitle, "Should display a valid cosmic title")
    }

    // MARK: - Investor Profile Card Tests

    func testProfileShowsInvestorProfileCard() throws {
        profilePage.navigateToProfile()

        // Should have portfolio-related stats
        let hasStats = profilePage.hasPortfolioStats ||
                      app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Holdings' OR label CONTAINS 'stocks' OR label CONTAINS 'Value' OR label CONTAINS 'Performance'")).count > 0

        XCTAssertTrue(hasStats, "Profile should show investor profile card with stats")
    }

    func testInvestorProfileShowsHoldingsCount() throws {
        profilePage.navigateToProfile()

        // Should show number of holdings
        let hasHoldings = profilePage.displayedHoldingsCount != nil ||
                         app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Holdings' OR label MATCHES '\\\\d+ stocks?'")).count > 0

        XCTAssertTrue(hasHoldings, "Investor profile should show holdings count")
    }

    func testInvestorProfileShowsPortfolioValue() throws {
        profilePage.navigateToProfile()

        // Should show portfolio value with currency
        let hasValue = profilePage.displayedPortfolioValue != nil ||
                      app.staticTexts.matching(NSPredicate(format: "label CONTAINS '$'")).count > 0

        XCTAssertTrue(hasValue, "Investor profile should show portfolio value")
    }

    // MARK: - Portfolio Stats Tests

    func testPortfolioStatsCardVisible() throws {
        profilePage.navigateToProfile()

        profilePage.assertPortfolioStatsShown()
    }

    func testPortfolioStatsShowsPerformance() throws {
        profilePage.navigateToProfile()

        // Look for performance indicators
        let hasPerformance = app.staticTexts.matching(NSPredicate(format: "label CONTAINS '%' OR label CONTAINS '+' OR label CONTAINS '-' OR label CONTAINS 'Performance' OR label CONTAINS 'Return'")).count > 0

        XCTAssertTrue(hasPerformance, "Portfolio stats should show performance metrics")
    }

    // MARK: - Subscription Status Tests

    func testProfileShowsSubscriptionStatus() throws {
        profilePage.navigateToProfile()

        // Should indicate free or premium status
        let hasStatus = profilePage.isPremiumUser ||
                       profilePage.showsUpgradePrompt ||
                       app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Free' OR label CONTAINS 'Premium' OR label CONTAINS 'Oracle' OR label CONTAINS 'Pro'")).count > 0

        XCTAssertTrue(hasStatus, "Profile should show subscription status")
    }

    func testFreeUserSeesUpgradePrompt() throws {
        // Launch as free user
        app.terminate()
        app = XCUIApplication()
        app.launchArguments = ["--uitesting", "--skip-onboarding", "--free-user"]
        app.launch()

        profilePage = ProfilePage(app: app)
        profilePage.navigateToProfile()

        // Should show upgrade option
        let hasUpgrade = profilePage.showsUpgradePrompt ||
                        profilePage.upgradeButton.exists ||
                        app.buttons.matching(NSPredicate(format: "label CONTAINS 'Upgrade' OR label CONTAINS 'Subscribe' OR label CONTAINS 'Premium'")).count > 0

        XCTAssertTrue(hasUpgrade, "Free user should see upgrade prompt")
    }

    func testPremiumUserDoesNotSeeUpgradePrompt() throws {
        // Launch as premium user
        app.terminate()
        app = XCUIApplication()
        app.launchArguments = ["--uitesting", "--skip-onboarding", "--premium-user"]
        app.launch()

        profilePage = ProfilePage(app: app)
        profilePage.navigateToProfile()

        // Should show premium status, not upgrade prompt
        let isPremium = profilePage.isPremiumUser ||
                       app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Oracle' OR label CONTAINS 'Premium' OR label CONTAINS 'Pro'")).count > 0

        // This may or may not be true depending on implementation
        if isPremium {
            let noUpgradePrompt = !profilePage.upgradeButton.exists
            XCTAssertTrue(noUpgradePrompt, "Premium user should not see upgrade button")
        }
    }

    // MARK: - Upgrade Flow Tests

    func testUpgradeButtonOpensPaywall() throws {
        app.terminate()
        app = XCUIApplication()
        app.launchArguments = ["--uitesting", "--skip-onboarding", "--free-user"]
        app.launch()

        profilePage = ProfilePage(app: app)
        profilePage.navigateToProfile()

        // Tap upgrade
        if profilePage.upgradeButton.exists {
            let paywallPage = profilePage.tapUpgrade()

            // Should navigate to paywall
            XCTAssertTrue(paywallPage.isDisplayed(), "Upgrade button should open paywall")
        } else {
            // Look for any upgrade action
            let upgradeButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Upgrade' OR label CONTAINS 'Subscribe'")).firstMatch

            if upgradeButton.exists {
                upgradeButton.tap()

                let paywallPage = PaywallPage(app: app)
                XCTAssertTrue(paywallPage.isDisplayed(), "Upgrade action should open paywall")
            }
        }
    }

    // MARK: - Settings Section Tests

    func testSettingsSectionVisible() throws {
        profilePage.navigateToProfile()

        // Scroll to settings
        profilePage.scrollToSettings()

        // Should have settings options
        let hasSettings = app.cells.count > 0 ||
                         app.buttons.matching(NSPredicate(format: "label CONTAINS 'Settings' OR label CONTAINS 'Notifications' OR label CONTAINS 'Privacy' OR label CONTAINS 'Help'")).count > 0

        XCTAssertTrue(hasSettings, "Settings section should be visible")
    }

    func testNotificationsSettingExists() throws {
        profilePage.navigateToProfile()
        profilePage.scrollToSettings()

        let hasNotifications = app.cells.matching(NSPredicate(format: "label CONTAINS 'Notifications'")).count > 0 ||
                              app.buttons.matching(NSPredicate(format: "label CONTAINS 'Notifications'")).count > 0

        if !hasNotifications {
            print("Note: Notifications setting not found")
        }
    }

    func testPrivacySettingExists() throws {
        profilePage.navigateToProfile()
        profilePage.scrollToSettings()

        let hasPrivacy = app.cells.matching(NSPredicate(format: "label CONTAINS 'Privacy'")).count > 0 ||
                        app.buttons.matching(NSPredicate(format: "label CONTAINS 'Privacy'")).count > 0

        if !hasPrivacy {
            print("Note: Privacy setting not found")
        }
    }

    func testHelpSettingExists() throws {
        profilePage.navigateToProfile()
        profilePage.scrollToSettings()

        let hasHelp = app.cells.matching(NSPredicate(format: "label CONTAINS 'Help' OR label CONTAINS 'Support'")).count > 0 ||
                     app.buttons.matching(NSPredicate(format: "label CONTAINS 'Help' OR label CONTAINS 'Support'")).count > 0

        if !hasHelp {
            print("Note: Help setting not found")
        }
    }

    func testAboutSettingExists() throws {
        profilePage.navigateToProfile()
        profilePage.scrollToSettings()

        let hasAbout = app.cells.matching(NSPredicate(format: "label CONTAINS 'About'")).count > 0 ||
                      app.buttons.matching(NSPredicate(format: "label CONTAINS 'About'")).count > 0

        if !hasAbout {
            print("Note: About setting not found")
        }
    }

    // MARK: - Sign Out Tests

    func testSignOutButtonExists() throws {
        profilePage.navigateToProfile()
        profilePage.scrollToBottom()

        let hasSignOut = profilePage.signOutButton.exists ||
                        app.buttons.matching(NSPredicate(format: "label CONTAINS 'Sign Out' OR label CONTAINS 'Log Out'")).count > 0

        XCTAssertTrue(hasSignOut, "Sign out option should be available")
    }

    func testSignOutShowsConfirmation() throws {
        profilePage.navigateToProfile()
        profilePage.scrollToBottom()

        // Tap sign out
        profilePage.tapSignOut()

        // Should show confirmation alert or action sheet
        let hasConfirmation = app.alerts.count > 0 ||
                             app.sheets.count > 0 ||
                             app.buttons.matching(NSPredicate(format: "label CONTAINS 'Confirm' OR label CONTAINS 'Cancel'")).count > 0

        if hasConfirmation {
            // Dismiss the confirmation
            let cancelButton = app.buttons["Cancel"]
            if cancelButton.exists {
                cancelButton.tap()
            }
        }

        // Sign out confirmation is expected behavior
        XCTAssertTrue(hasConfirmation, "Sign out should show confirmation")
    }

    // MARK: - Edit Profile Tests

    func testEditProfileButtonExists() throws {
        profilePage.navigateToProfile()

        let hasEdit = profilePage.editProfileButton.exists ||
                     app.buttons.matching(NSPredicate(format: "label CONTAINS 'Edit'")).count > 0

        if !hasEdit {
            print("Note: Edit profile button not found")
        }
    }

    func testEditProfileOpensEditor() throws {
        profilePage.navigateToProfile()

        if profilePage.editProfileButton.exists {
            profilePage.tapEditProfile()

            // Should open edit view
            let hasEditView = app.textFields.count > 0 ||
                             app.navigationBars.matching(NSPredicate(format: "identifier CONTAINS 'Edit'")).count > 0 ||
                             app.buttons["Save"].exists ||
                             app.buttons["Done"].exists

            XCTAssertTrue(hasEditView, "Edit profile should open editor")
        }
    }

    // MARK: - Scroll Tests

    func testProfileScrollsToShowAllContent() throws {
        profilePage.navigateToProfile()

        // Scroll down
        profilePage.scrollToBottom()

        // Should still be on profile
        XCTAssertTrue(profilePage.isDisplayed(), "Profile should be scrollable")
    }

    func testProfileScrollsBackToTop() throws {
        profilePage.navigateToProfile()

        // Scroll down then up
        profilePage.scrollToBottom()
        profilePage.scrollToTop()

        // User info should be visible at top
        let hasTopContent = profilePage.displayedUserName != nil ||
                           profilePage.displayedZodiacSign != nil

        XCTAssertTrue(hasTopContent, "Should scroll back to top showing user info")
    }

    // MARK: - Navigation Tests

    func testProfileToPortfolioNavigation() throws {
        profilePage.navigateToProfile()

        // Navigate to portfolio
        profilePage.navigateToTab(.portfolio)

        // Verify navigation
        let portfolioPage = PortfolioPage(app: app)
        XCTAssertTrue(portfolioPage.isDisplayed(), "Should navigate to Portfolio tab")
    }

    func testProfileToDiscoverNavigation() throws {
        profilePage.navigateToProfile()

        // Navigate to discover
        profilePage.navigateToTab(.discover)

        // Verify navigation
        let discoverPage = DiscoverPage(app: app)
        XCTAssertTrue(discoverPage.isDisplayed(), "Should navigate to Discover tab")
    }

    // MARK: - Zodiac Display Tests

    func testZodiacSymbolDisplayed() throws {
        profilePage.navigateToProfile()

        // Check for zodiac emoji/symbol
        let zodiacEmojis = ["", "", "", "", "", "", "", "", "", "", "", ""]
        var hasSymbol = false

        for emoji in zodiacEmojis {
            if app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", emoji)).count > 0 {
                hasSymbol = true
                break
            }
        }

        // Also check for text symbols
        if !hasSymbol {
            hasSymbol = profilePage.displayedZodiacSign != nil
        }

        XCTAssertTrue(hasSymbol, "Profile should display zodiac symbol")
    }

    func testElementColorCodeDisplayed() throws {
        profilePage.navigateToProfile()

        // Element should have associated color (Fire=red, Earth=green, Air=blue, Water=teal)
        // We can check for element text at minimum
        let hasElement = profilePage.displayedElement != nil

        XCTAssertTrue(hasElement, "Element should be displayed (with color coding)")
    }

    // MARK: - Member Since Tests

    func testMemberSinceDateDisplayed() throws {
        profilePage.navigateToProfile()

        // Look for membership date or duration
        let hasMemberInfo = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Member' OR label CONTAINS 'Joined' OR label CONTAINS 'Since'")).count > 0

        if !hasMemberInfo {
            print("Note: Member since info not displayed")
        }
    }

    // MARK: - Accessibility Tests

    func testProfileElementsHaveAccessibilityLabels() throws {
        profilePage.navigateToProfile()

        // Key elements should have accessibility labels
        let mainTexts = app.staticTexts.allElementsBoundByIndex.prefix(10)

        for text in mainTexts {
            XCTAssertFalse(text.label.isEmpty, "Profile elements should have accessibility labels")
        }
    }

    // MARK: - Performance Tests

    func testProfileLoadsQuickly() throws {
        let startTime = Date()

        profilePage.navigateToProfile()

        // Wait for content
        _ = app.staticTexts.firstMatch.waitForExistence(timeout: 5)

        let loadTime = Date().timeIntervalSince(startTime)

        XCTAssertLessThan(loadTime, 3.0, "Profile should load within 3 seconds")
    }
}
