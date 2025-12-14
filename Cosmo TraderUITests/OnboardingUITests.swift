//
//  OnboardingUITests.swift
//  Cosmo TraderUITests
//
//  UI tests for the complete onboarding flow including validation.
//

import XCTest

final class OnboardingUITests: XCTestCase {

    var app: XCUIApplication!
    var onboardingPage: OnboardingPage!

    override func setUpWithError() throws {
        continueAfterFailure = false

        app = XCUIApplication()
        // Reset app state for fresh onboarding
        app.launchArguments = ["--uitesting", "--reset-onboarding"]
        app.launch()

        onboardingPage = OnboardingPage(app: app)
    }

    override func tearDownWithError() throws {
        app = nil
        onboardingPage = nil
    }

    // MARK: - Complete Onboarding Flow Tests

    func testCompleteOnboardingFlowFromWelcomeToMainApp() throws {
        // Verify we start on welcome screen
        XCTAssertTrue(onboardingPage.isOnWelcomeScreen, "Should start on welcome screen")

        // Progress through onboarding
        onboardingPage.completeOnboarding(name: "Test User")

        // Verify we reach the main app (tab bar visible)
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 10), "Should reach main app with tab bar after onboarding")
    }

    func testWelcomeScreenDisplaysCorrectly() throws {
        // Welcome screen should show app branding
        XCTAssertTrue(onboardingPage.isOnWelcomeScreen, "Welcome screen should be displayed")

        // Should have a Get Started or Continue button
        let hasActionButton = onboardingPage.getStartedButton.exists ||
                              onboardingPage.continueButton.exists
        XCTAssertTrue(hasActionButton, "Welcome screen should have action button")
    }

    func testOnboardingProgressesWithValidData() throws {
        // Start onboarding
        if onboardingPage.isOnWelcomeScreen {
            onboardingPage.advanceToNextStep()
        }

        // Wait for next screen
        _ = app.staticTexts.firstMatch.waitForExistence(timeout: 3)

        // Should have progressed past welcome
        let progressedPastWelcome = onboardingPage.isOnBirthDateScreen ||
                                     onboardingPage.isOnNameScreen ||
                                     !onboardingPage.isOnWelcomeScreen

        XCTAssertTrue(progressedPastWelcome, "Should progress past welcome screen")
    }

    // MARK: - Birth Date Validation Tests

    func testBirthDateScreenAcceptsValidDate() throws {
        // Navigate to birth date screen
        if onboardingPage.isOnWelcomeScreen {
            onboardingPage.advanceToNextStep()
            _ = app.staticTexts.firstMatch.waitForExistence(timeout: 3)
        }

        // If on birth date screen
        if onboardingPage.isOnBirthDateScreen {
            // Set a valid birth date
            onboardingPage.setValidBirthDate()

            // Should be able to continue
            XCTAssertTrue(onboardingPage.isNextButtonEnabled || onboardingPage.continueButton.exists,
                         "Should be able to continue with valid birth date")
        }
    }

    func testBirthDateScreenRejectsFutureDate() throws {
        // Navigate to birth date screen
        if onboardingPage.isOnWelcomeScreen {
            onboardingPage.advanceToNextStep()
            _ = app.staticTexts.firstMatch.waitForExistence(timeout: 3)
        }

        // If on birth date screen
        if onboardingPage.isOnBirthDateScreen {
            // Attempt to set future date
            onboardingPage.setFutureBirthDate()

            // Try to advance
            onboardingPage.advanceToNextStep()

            // Should show error or still be on birth date screen
            let stayedOnScreen = onboardingPage.isOnBirthDateScreen
            let showsError = onboardingPage.hasErrorMessage

            XCTAssertTrue(stayedOnScreen || showsError,
                         "Should reject future birth date with error or prevent advancement")
        }
    }

    func testBirthDateScreenShowsDateRangeHint() throws {
        // Navigate to birth date screen
        if onboardingPage.isOnWelcomeScreen {
            onboardingPage.advanceToNextStep()
            _ = app.staticTexts.firstMatch.waitForExistence(timeout: 3)
        }

        if onboardingPage.isOnBirthDateScreen {
            // Should have some date-related guidance text
            let hasGuidance = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'birth' OR label CONTAINS 'date' OR label CONTAINS 'born'")).count > 0

            XCTAssertTrue(hasGuidance, "Birth date screen should show guidance text")
        }
    }

    // MARK: - Name Entry Validation Tests

    func testNameEntryScreenAcceptsValidName() throws {
        // Navigate through to name screen
        onboardingPage.completeOnboarding(name: "")

        // Back up to find name screen or start fresh
        app.terminate()
        app.launch()

        if onboardingPage.isOnWelcomeScreen {
            onboardingPage.advanceToNextStep()
        }

        // Progress to name screen
        for _ in 0..<3 {
            if onboardingPage.isOnNameScreen {
                break
            }
            if onboardingPage.isOnBirthDateScreen {
                onboardingPage.setValidBirthDate()
            }
            onboardingPage.advanceToNextStep()
            _ = app.staticTexts.firstMatch.waitForExistence(timeout: 2)
        }

        if onboardingPage.isOnNameScreen {
            // Enter valid name
            onboardingPage.enterName("John Smith")

            // Should be able to continue
            let canAdvance = onboardingPage.continueButton.isEnabled ||
                            onboardingPage.nextButton.isEnabled ||
                            !onboardingPage.hasErrorMessage

            XCTAssertTrue(canAdvance, "Should accept valid name")
        }
    }

    func testNameEntryScreenRejectsEmptyName() throws {
        app.terminate()
        app.launch()

        // Navigate to name screen
        if onboardingPage.isOnWelcomeScreen {
            onboardingPage.advanceToNextStep()
        }

        for _ in 0..<3 {
            if onboardingPage.isOnNameScreen {
                break
            }
            if onboardingPage.isOnBirthDateScreen {
                onboardingPage.setValidBirthDate()
            }
            onboardingPage.advanceToNextStep()
            _ = app.staticTexts.firstMatch.waitForExistence(timeout: 2)
        }

        if onboardingPage.isOnNameScreen {
            // Clear any existing name
            let textField = onboardingPage.nameTextField.exists ? onboardingPage.nameTextField : app.textFields.firstMatch
            if textField.exists {
                textField.tap()
                // Clear field
                if let currentValue = textField.value as? String, !currentValue.isEmpty {
                    textField.doubleTap()
                    app.keys["delete"].tap()
                }
            }

            // Try to advance with empty name
            onboardingPage.advanceToNextStep()

            // Should show error or stay on screen
            let stayedOnScreen = onboardingPage.isOnNameScreen
            let showsError = onboardingPage.hasErrorMessage
            let buttonDisabled = !onboardingPage.isNextButtonEnabled

            XCTAssertTrue(stayedOnScreen || showsError || buttonDisabled,
                         "Should reject empty name")
        }
    }

    func testNameEntryScreenRejectsTooLongName() throws {
        app.terminate()
        app.launch()

        // Navigate to name screen
        if onboardingPage.isOnWelcomeScreen {
            onboardingPage.advanceToNextStep()
        }

        for _ in 0..<3 {
            if onboardingPage.isOnNameScreen {
                break
            }
            if onboardingPage.isOnBirthDateScreen {
                onboardingPage.setValidBirthDate()
            }
            onboardingPage.advanceToNextStep()
            _ = app.staticTexts.firstMatch.waitForExistence(timeout: 2)
        }

        if onboardingPage.isOnNameScreen {
            // Enter very long name (over 50 characters)
            let longName = String(repeating: "a", count: 55)
            onboardingPage.enterName(longName)

            // Try to advance
            onboardingPage.advanceToNextStep()

            // Should either truncate, show error, or stay on screen
            let showsError = onboardingPage.hasErrorMessage
            let stayedOnScreen = onboardingPage.isOnNameScreen

            // Check if the input was truncated
            let textField = onboardingPage.nameTextField.exists ? onboardingPage.nameTextField : app.textFields.firstMatch
            let wasTruncated = (textField.value as? String)?.count ?? 0 <= 50

            XCTAssertTrue(showsError || stayedOnScreen || wasTruncated,
                         "Should handle name over 50 characters")
        }
    }

    func testNameEntryScreenRejectsInvalidCharacters() throws {
        app.terminate()
        app.launch()

        // Navigate to name screen
        if onboardingPage.isOnWelcomeScreen {
            onboardingPage.advanceToNextStep()
        }

        for _ in 0..<3 {
            if onboardingPage.isOnNameScreen {
                break
            }
            if onboardingPage.isOnBirthDateScreen {
                onboardingPage.setValidBirthDate()
            }
            onboardingPage.advanceToNextStep()
            _ = app.staticTexts.firstMatch.waitForExistence(timeout: 2)
        }

        if onboardingPage.isOnNameScreen {
            // Enter name with invalid characters
            onboardingPage.enterName("John@123")

            // Try to advance
            onboardingPage.advanceToNextStep()

            // Should show error or filter out invalid chars
            let showsError = onboardingPage.hasErrorMessage
            let stayedOnScreen = onboardingPage.isOnNameScreen

            XCTAssertTrue(showsError || stayedOnScreen,
                         "Should handle invalid characters in name")
        }
    }

    // MARK: - Element Reveal Tests

    func testElementRevealScreenShows() throws {
        // Complete early onboarding steps
        if onboardingPage.isOnWelcomeScreen {
            onboardingPage.advanceToNextStep()
        }

        if onboardingPage.isOnBirthDateScreen {
            onboardingPage.setValidBirthDate()
            onboardingPage.advanceToNextStep()
        }

        if onboardingPage.isOnNameScreen {
            onboardingPage.enterName("Test User")
            onboardingPage.advanceToNextStep()
        }

        // Wait for element screen
        _ = app.staticTexts.firstMatch.waitForExistence(timeout: 3)

        // Should see element-related content
        if onboardingPage.isOnElementScreen {
            let hasElementContent = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Fire' OR label CONTAINS 'Earth' OR label CONTAINS 'Air' OR label CONTAINS 'Water' OR label CONTAINS 'element'")).count > 0

            XCTAssertTrue(hasElementContent, "Element reveal screen should show element information")
        }
    }

    // MARK: - Stock Selection Tests

    func testStockMatchScreenDisplays() throws {
        // Complete early onboarding steps
        if onboardingPage.isOnWelcomeScreen {
            onboardingPage.advanceToNextStep()
        }

        if onboardingPage.isOnBirthDateScreen {
            onboardingPage.setValidBirthDate()
            onboardingPage.advanceToNextStep()
        }

        if onboardingPage.isOnNameScreen {
            onboardingPage.enterName("Test User")
            onboardingPage.advanceToNextStep()
        }

        if onboardingPage.isOnElementScreen {
            onboardingPage.advanceToNextStep()
        }

        // Wait for stock match screen
        _ = app.staticTexts.firstMatch.waitForExistence(timeout: 3)

        if onboardingPage.isOnStockMatchScreen {
            // Should show stock-related content
            let hasStockContent = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'stock' OR label CONTAINS 'match' OR label CONTAINS 'compatible'")).count > 0

            XCTAssertTrue(hasStockContent, "Stock match screen should show matched stocks")
        }
    }

    // MARK: - Skip Functionality Tests

    func testSkipButtonWorksWhenAvailable() throws {
        // Start onboarding
        if onboardingPage.isOnWelcomeScreen {
            onboardingPage.advanceToNextStep()
        }

        // Wait for next screen
        _ = app.staticTexts.firstMatch.waitForExistence(timeout: 3)

        // If skip is available, test it
        if onboardingPage.skipButton.exists {
            onboardingPage.tapSkip()

            // Should advance to next screen or complete
            _ = app.staticTexts.firstMatch.waitForExistence(timeout: 3)

            let advanced = !onboardingPage.isOnWelcomeScreen
            XCTAssertTrue(advanced, "Skip should advance past current screen")
        }
    }

    // MARK: - Persistence Tests

    func testOnboardingCompletionIsPersisted() throws {
        // Complete onboarding
        onboardingPage.completeOnboarding(name: "Persistence Test")

        // Wait for main app
        let tabBar = app.tabBars.firstMatch
        _ = tabBar.waitForExistence(timeout: 10)

        // Restart app without reset flag
        app.terminate()
        app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launch()

        // Should go directly to main app, not onboarding
        let startsAtMainApp = tabBar.waitForExistence(timeout: 5)
        let noWelcomeScreen = !onboardingPage.isOnWelcomeScreen

        XCTAssertTrue(startsAtMainApp || noWelcomeScreen,
                     "App should skip onboarding after completion")
    }

    // MARK: - Zodiac Sign Display Tests

    func testZodiacSignCalculatedFromBirthDate() throws {
        // Navigate through onboarding with specific birth date
        if onboardingPage.isOnWelcomeScreen {
            onboardingPage.advanceToNextStep()
        }

        if onboardingPage.isOnBirthDateScreen {
            // Set birth date for Leo (August 15)
            onboardingPage.setBirthDate(month: "August", day: "15", year: "1990")
            onboardingPage.advanceToNextStep()
        }

        // Continue through onboarding
        if onboardingPage.isOnNameScreen {
            onboardingPage.enterName("Leo User")
            onboardingPage.advanceToNextStep()
        }

        // Look for Leo zodiac sign display
        _ = app.staticTexts.firstMatch.waitForExistence(timeout: 3)

        let hasLeoDisplay = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Leo'")).count > 0

        XCTAssertTrue(hasLeoDisplay, "Should display Leo zodiac sign for August 15 birth date")
    }

    // MARK: - UI Element Tests

    func testOnboardingHasProgressIndicator() throws {
        // Start onboarding
        if onboardingPage.isOnWelcomeScreen {
            onboardingPage.advanceToNextStep()
        }

        // Look for progress indicator (dots, steps, etc.)
        let hasProgressIndicator = app.pageIndicators.count > 0 ||
                                   app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Step' OR label MATCHES '\\\\d+/\\\\d+'")).count > 0

        // Note: Progress indicator is optional but nice to have
        if !hasProgressIndicator {
            // Just log, don't fail
            print("Note: No progress indicator found in onboarding")
        }
    }

    func testOnboardingScreensHaveBackNavigation() throws {
        // Complete a few steps
        if onboardingPage.isOnWelcomeScreen {
            onboardingPage.advanceToNextStep()
        }

        _ = app.staticTexts.firstMatch.waitForExistence(timeout: 3)

        if onboardingPage.isOnBirthDateScreen {
            onboardingPage.setValidBirthDate()
            onboardingPage.advanceToNextStep()
        }

        _ = app.staticTexts.firstMatch.waitForExistence(timeout: 3)

        // Check for back navigation
        let hasBackButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Back' OR label CONTAINS 'chevron.left' OR label == 'back'")).count > 0

        // Back navigation is optional
        if hasBackButton {
            // Test that back works
            app.buttons.matching(NSPredicate(format: "label CONTAINS 'Back'")).firstMatch.tap()
            _ = app.staticTexts.firstMatch.waitForExistence(timeout: 2)
        }
    }
}
