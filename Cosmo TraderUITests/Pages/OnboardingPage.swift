//
//  OnboardingPage.swift
//  Cosmo TraderUITests
//
//  Page Object for the onboarding flow screens.
//

import XCTest

class OnboardingPage: BasePage {

    // MARK: - Element Identifiers

    private enum Identifiers {
        static let welcomeTitle = "Welcome to Cosmo Trader"
        static let getStartedButton = "Get Started"
        static let continueButton = "Continue"
        static let nextButton = "Next"
        static let skipButton = "Skip"
        static let finishButton = "Finish"
        static let enterCosmosButton = "Enter the Cosmos"

        static let birthDatePicker = "birthDatePicker"
        static let nameTextField = "nameTextField"
        static let errorMessage = "errorMessage"
    }

    // MARK: - Elements

    var welcomeTitle: XCUIElement {
        app.staticTexts[Identifiers.welcomeTitle]
    }

    var getStartedButton: XCUIElement {
        app.buttons[Identifiers.getStartedButton]
    }

    var continueButton: XCUIElement {
        app.buttons[Identifiers.continueButton]
    }

    var nextButton: XCUIElement {
        app.buttons[Identifiers.nextButton]
    }

    var skipButton: XCUIElement {
        app.buttons[Identifiers.skipButton]
    }

    var finishButton: XCUIElement {
        app.buttons[Identifiers.finishButton]
    }

    var enterCosmosButton: XCUIElement {
        app.buttons[Identifiers.enterCosmosButton]
    }

    var birthDatePicker: XCUIElement {
        app.datePickers[Identifiers.birthDatePicker]
    }

    var nameTextField: XCUIElement {
        app.textFields[Identifiers.nameTextField]
    }

    var errorMessage: XCUIElement {
        app.staticTexts[Identifiers.errorMessage]
    }

    // MARK: - Screen Detection

    var isOnWelcomeScreen: Bool {
        welcomeTitle.exists || getStartedButton.exists
    }

    var isOnBirthDateScreen: Bool {
        app.staticTexts["When were you born?"].exists ||
        birthDatePicker.exists ||
        app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'birth'")).count > 0
    }

    var isOnNameScreen: Bool {
        nameTextField.exists ||
        app.staticTexts["What's your name?"].exists ||
        app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'name'")).count > 0
    }

    var isOnElementScreen: Bool {
        app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'element'")).count > 0 ||
        app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Fire' OR label CONTAINS 'Earth' OR label CONTAINS 'Air' OR label CONTAINS 'Water'")).count > 0
    }

    var isOnStockMatchScreen: Bool {
        app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'match' OR label CONTAINS 'stock'")).count > 0
    }

    var isOnCompleteScreen: Bool {
        enterCosmosButton.exists ||
        app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'ready' OR label CONTAINS 'complete'")).count > 0
    }

    // MARK: - Actions

    /// Tap Get Started to begin onboarding
    @discardableResult
    func tapGetStarted() -> OnboardingPage {
        tapElement(getStartedButton)
        return self
    }

    /// Tap Continue button
    @discardableResult
    func tapContinue() -> OnboardingPage {
        tapElement(continueButton)
        return self
    }

    /// Tap Next button
    @discardableResult
    func tapNext() -> OnboardingPage {
        tapElement(nextButton)
        return self
    }

    /// Tap Skip button
    @discardableResult
    func tapSkip() -> OnboardingPage {
        tapElement(skipButton)
        return self
    }

    /// Tap Finish button
    @discardableResult
    func tapFinish() -> OnboardingPage {
        tapElement(finishButton)
        return self
    }

    /// Tap Enter the Cosmos button
    @discardableResult
    func tapEnterCosmos() -> OnboardingPage {
        tapElement(enterCosmosButton)
        return self
    }

    /// Enter name in text field
    @discardableResult
    func enterName(_ name: String) -> OnboardingPage {
        let textField = nameTextField.exists ? nameTextField : app.textFields.firstMatch
        clearAndType(textField, text: name)
        return self
    }

    /// Set birth date using date picker
    @discardableResult
    func setBirthDate(month: String, day: String, year: String) -> OnboardingPage {
        // Interact with date picker wheels
        if birthDatePicker.exists {
            let picker = birthDatePicker
            picker.pickerWheels.element(boundBy: 0).adjust(toPickerWheelValue: month)
            picker.pickerWheels.element(boundBy: 1).adjust(toPickerWheelValue: day)
            picker.pickerWheels.element(boundBy: 2).adjust(toPickerWheelValue: year)
        }
        return self
    }

    /// Set birth date to future date (for validation testing)
    @discardableResult
    func setFutureBirthDate() -> OnboardingPage {
        let futureYear = String(Calendar.current.component(.year, from: Date()) + 1)
        return setBirthDate(month: "January", day: "1", year: futureYear)
    }

    /// Set birth date to valid past date
    @discardableResult
    func setValidBirthDate() -> OnboardingPage {
        return setBirthDate(month: "August", day: "15", year: "1990")
    }

    /// Advance through any action button on current screen
    @discardableResult
    func advanceToNextStep() -> OnboardingPage {
        if getStartedButton.exists {
            tapElement(getStartedButton)
        } else if continueButton.exists {
            tapElement(continueButton)
        } else if nextButton.exists {
            tapElement(nextButton)
        } else if finishButton.exists {
            tapElement(finishButton)
        } else if enterCosmosButton.exists {
            tapElement(enterCosmosButton)
        }
        return self
    }

    /// Complete entire onboarding flow with valid data
    func completeOnboarding(name: String = "Test User") {
        // Welcome screen
        if isOnWelcomeScreen {
            advanceToNextStep()
            _ = waitForElement(app.staticTexts.firstMatch, timeout: 3)
        }

        // Birth date screen
        if isOnBirthDateScreen {
            setValidBirthDate()
            advanceToNextStep()
            _ = waitForElement(app.staticTexts.firstMatch, timeout: 3)
        }

        // Name screen
        if isOnNameScreen {
            enterName(name)
            advanceToNextStep()
            _ = waitForElement(app.staticTexts.firstMatch, timeout: 3)
        }

        // Element reveal screen
        if isOnElementScreen {
            advanceToNextStep()
            _ = waitForElement(app.staticTexts.firstMatch, timeout: 3)
        }

        // Stock match screen
        if isOnStockMatchScreen {
            advanceToNextStep()
            _ = waitForElement(app.staticTexts.firstMatch, timeout: 3)
        }

        // Complete screen
        if isOnCompleteScreen {
            advanceToNextStep()
        }
    }

    // MARK: - Validation Helpers

    /// Check if error message is displayed
    var hasErrorMessage: Bool {
        errorMessage.exists ||
        app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'error' OR label CONTAINS 'invalid' OR label CONTAINS 'required'")).count > 0
    }

    /// Get current error message text
    var errorMessageText: String? {
        if errorMessage.exists {
            return errorMessage.label
        }
        let errors = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'error' OR label CONTAINS 'invalid' OR label CONTAINS 'required'"))
        return errors.firstMatch.exists ? errors.firstMatch.label : nil
    }

    /// Check if Continue/Next button is enabled
    var isNextButtonEnabled: Bool {
        if continueButton.exists {
            return continueButton.isEnabled
        }
        if nextButton.exists {
            return nextButton.isEnabled
        }
        return false
    }
}
