//
//  PaywallPage.swift
//  Cosmo TraderUITests
//
//  Page Object for the Paywall/Subscription screen.
//

import XCTest

class PaywallPage: BasePage {

    // MARK: - Element Identifiers

    private enum Identifiers {
        static let paywallTitle = "Become a Cosmo Oracle"
        static let monthlyOption = "Monthly"
        static let yearlyOption = "Yearly"
        static let subscribeButton = "Subscribe"
        static let restorePurchasesButton = "Restore Purchases"
        static let closeButton = "Close"
        static let termsButton = "Terms"
        static let privacyButton = "Privacy"
        static let priceLabel = "price"
        static let featuresList = "features"
    }

    // MARK: - Elements

    var paywallTitle: XCUIElement {
        app.staticTexts[Identifiers.paywallTitle]
    }

    var monthlyOption: XCUIElement {
        app.buttons[Identifiers.monthlyOption]
    }

    var yearlyOption: XCUIElement {
        app.buttons[Identifiers.yearlyOption]
    }

    var subscribeButton: XCUIElement {
        app.buttons[Identifiers.subscribeButton]
    }

    var restorePurchasesButton: XCUIElement {
        app.buttons[Identifiers.restorePurchasesButton]
    }

    var closeButton: XCUIElement {
        app.buttons[Identifiers.closeButton]
    }

    var termsButton: XCUIElement {
        app.buttons[Identifiers.termsButton]
    }

    var privacyButton: XCUIElement {
        app.buttons[Identifiers.privacyButton]
    }

    // MARK: - Screen Detection

    func isDisplayed() -> Bool {
        return paywallTitle.exists ||
               app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Oracle' OR label CONTAINS 'Premium' OR label CONTAINS 'Subscribe' OR label CONTAINS 'Upgrade'")).count > 0 ||
               subscribeButton.exists
    }

    var hasMonthlyOption: Bool {
        return monthlyOption.exists ||
               app.buttons.matching(NSPredicate(format: "label CONTAINS 'Monthly' OR label CONTAINS '/month' OR label CONTAINS 'month'")).count > 0
    }

    var hasYearlyOption: Bool {
        return yearlyOption.exists ||
               app.buttons.matching(NSPredicate(format: "label CONTAINS 'Yearly' OR label CONTAINS '/year' OR label CONTAINS 'Annual'")).count > 0
    }

    // MARK: - Price Information

    /// Get displayed monthly price
    var monthlyPrice: String? {
        let priceLabels = app.staticTexts.matching(NSPredicate(format: "label CONTAINS '$' AND (label CONTAINS 'month' OR label CONTAINS '/mo')"))
        return priceLabels.firstMatch.exists ? priceLabels.firstMatch.label : nil
    }

    /// Get displayed yearly price
    var yearlyPrice: String? {
        let priceLabels = app.staticTexts.matching(NSPredicate(format: "label CONTAINS '$' AND (label CONTAINS 'year' OR label CONTAINS '/yr' OR label CONTAINS 'annual')"))
        return priceLabels.firstMatch.exists ? priceLabels.firstMatch.label : nil
    }

    /// Check if prices are loaded (not placeholder)
    var hasPricesLoaded: Bool {
        let priceLabels = app.staticTexts.matching(NSPredicate(format: "label CONTAINS '$'"))
        if priceLabels.count > 0 {
            // Check that price is not a placeholder like "$--" or "Loading"
            let firstPrice = priceLabels.firstMatch.label
            return !firstPrice.contains("--") && !firstPrice.contains("Loading")
        }
        return false
    }

    // MARK: - Feature List

    /// Get displayed features
    var displayedFeatures: [String] {
        var features: [String] = []
        let featureLabels = app.staticTexts.allElementsBoundByIndex

        for label in featureLabels {
            let text = label.label
            // Features typically have checkmarks or bullets
            if text.contains("") || text.contains("") || text.hasPrefix("-") || text.hasPrefix("") {
                features.append(text)
            }
        }
        return features
    }

    /// Check if specific feature is mentioned
    func hasFeature(_ featureText: String) -> Bool {
        return app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", featureText)).count > 0
    }

    // MARK: - Subscription Plan Selection

    /// Select monthly plan
    @discardableResult
    func selectMonthly() -> PaywallPage {
        if monthlyOption.exists {
            tapElement(monthlyOption)
        } else {
            let monthlyBtn = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Monthly' OR label CONTAINS 'month'")).firstMatch
            tapElement(monthlyBtn)
        }
        return self
    }

    /// Select yearly plan
    @discardableResult
    func selectYearly() -> PaywallPage {
        if yearlyOption.exists {
            tapElement(yearlyOption)
        } else {
            let yearlyBtn = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Yearly' OR label CONTAINS 'year' OR label CONTAINS 'Annual'")).firstMatch
            tapElement(yearlyBtn)
        }
        return self
    }

    /// Check which plan is currently selected
    var selectedPlan: String? {
        if monthlyOption.exists && monthlyOption.isSelected {
            return "Monthly"
        }
        if yearlyOption.exists && yearlyOption.isSelected {
            return "Yearly"
        }
        return nil
    }

    // MARK: - Actions

    /// Tap subscribe button
    @discardableResult
    func tapSubscribe() -> PaywallPage {
        if subscribeButton.exists {
            tapElement(subscribeButton)
        } else {
            let subBtn = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Subscribe' OR label CONTAINS 'Continue' OR label CONTAINS 'Purchase'")).firstMatch
            tapElement(subBtn)
        }
        return self
    }

    /// Tap restore purchases button
    @discardableResult
    func tapRestorePurchases() -> PaywallPage {
        if restorePurchasesButton.exists {
            tapElement(restorePurchasesButton)
        } else {
            let restoreBtn = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Restore'")).firstMatch
            tapElement(restoreBtn)
        }
        return self
    }

    /// Close the paywall
    @discardableResult
    func close() -> ProfilePage {
        if closeButton.exists {
            tapElement(closeButton)
        } else {
            // Look for X button or back button
            let closeBtn = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Close' OR label CONTAINS 'X' OR label == 'xmark'")).firstMatch
            if closeBtn.exists {
                tapElement(closeBtn)
            } else {
                // Try swipe down to dismiss
                swipeDown(on: app.otherElements.firstMatch)
            }
        }
        return ProfilePage(app: app)
    }

    /// Tap terms of service
    @discardableResult
    func tapTerms() -> PaywallPage {
        if termsButton.exists {
            tapElement(termsButton)
        } else {
            let termsLink = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Terms'")).firstMatch
            tapElement(termsLink)
        }
        return self
    }

    /// Tap privacy policy
    @discardableResult
    func tapPrivacy() -> PaywallPage {
        if privacyButton.exists {
            tapElement(privacyButton)
        } else {
            let privacyLink = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Privacy'")).firstMatch
            tapElement(privacyLink)
        }
        return self
    }

    // MARK: - StoreKit Alert Handling

    /// Handle App Store subscription confirmation dialog
    func handleSubscriptionConfirmation(confirm: Bool = true) {
        let confirmButton = app.buttons["Confirm"]
        let cancelButton = app.buttons["Cancel"]

        if confirm && confirmButton.waitForExistence(timeout: 5) {
            confirmButton.tap()
        } else if !confirm && cancelButton.waitForExistence(timeout: 5) {
            cancelButton.tap()
        }
    }

    /// Handle password/Face ID prompt
    func handleAuthentication() {
        // Wait for system authentication prompt
        sleep(2)

        // In UI tests, StoreKit testing config handles this
        // For real device, Face ID or password dialog would appear
        handleSystemAlert(accept: true)
    }

    /// Check if subscription successful
    var isSubscriptionSuccessful: Bool {
        return app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Success' OR label CONTAINS 'Thank you' OR label CONTAINS 'subscribed'")).count > 0
    }

    /// Check if error is displayed
    var hasError: Bool {
        return app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Error' OR label CONTAINS 'failed' OR label CONTAINS 'try again'")).count > 0
    }

    /// Get error message if present
    var errorMessage: String? {
        let errorLabels = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Error' OR label CONTAINS 'failed'"))
        return errorLabels.firstMatch.exists ? errorLabels.firstMatch.label : nil
    }

    // MARK: - Loading State

    /// Check if paywall is loading products
    var isLoading: Bool {
        return app.activityIndicators.count > 0 ||
               app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Loading'")).count > 0
    }

    /// Wait for products to load
    @discardableResult
    func waitForProductsToLoad(timeout: TimeInterval = 10) -> PaywallPage {
        let startTime = Date()
        while isLoading && Date().timeIntervalSince(startTime) < timeout {
            Thread.sleep(forTimeInterval: 0.5)
        }
        return self
    }

    // MARK: - Assertions

    /// Assert paywall is displayed
    func assertPaywallDisplayed() {
        XCTAssertTrue(isDisplayed(), "Paywall should be displayed")
    }

    /// Assert both subscription options available
    func assertSubscriptionOptionsAvailable() {
        XCTAssertTrue(hasMonthlyOption, "Monthly option should be available")
        XCTAssertTrue(hasYearlyOption, "Yearly option should be available")
    }

    /// Assert prices are loaded
    func assertPricesLoaded() {
        XCTAssertTrue(hasPricesLoaded, "Prices should be loaded from StoreKit")
    }

    /// Assert monthly price matches expected
    func assertMonthlyPrice(_ expected: String) {
        XCTAssertTrue(monthlyPrice?.contains(expected) == true, "Monthly price should contain \(expected)")
    }

    /// Assert features are listed
    func assertFeaturesListed() {
        XCTAssertTrue(displayedFeatures.count > 0 || hasFeature("Oracle"), "Features should be listed")
    }

    /// Assert subscription was successful
    func assertSubscriptionSuccess() {
        XCTAssertTrue(isSubscriptionSuccessful, "Subscription should be successful")
    }

    /// Assert no error displayed
    func assertNoError() {
        XCTAssertFalse(hasError, "No error should be displayed")
    }

    /// Assert error is displayed
    func assertErrorDisplayed() {
        XCTAssertTrue(hasError, "Error should be displayed")
    }
}
