import XCTest

final class SmokeUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    override func tearDownWithError() throws {
        app = nil
    }

    @MainActor
    func testLaunchWithFirebaseUnavailableDoesNotCrash() throws {
        launchApp(arguments: ["--uitesting", "--skip-onboarding", "--disable-firebase"])

        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 10))
        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 10))
    }

    @MainActor
    func testMainTabNavigationSmoke() throws {
        assertScreenshotRoute(additionalArguments: [], reaches: "screen.today")
        assertScreenshotRoute(additionalArguments: ["--tab-portfolio"], reaches: "screen.portfolio")
        assertScreenshotRoute(additionalArguments: ["--tab-discover"], reaches: "screen.discover")
        assertScreenshotRoute(additionalArguments: ["--tab-cosmos"], reaches: "screen.cosmos")
        assertScreenshotRoute(additionalArguments: ["--tab-profile"], reaches: "screen.profile")
        assertStockDetailScreenshotRoute()
    }

    @MainActor
    func testOnboardingCanCompleteViaTestSafePath() throws {
        launchApp(arguments: ["--uitesting", "--reset-onboarding", "--disable-firebase"])

        tapWhenReady(app.buttons["onboarding.primaryButton"])
        tapWhenReady(app.buttons["onboarding.primaryButton"])
        tapWhenReady(app.buttons["onboarding.quoteContinueButton"], timeout: 8)
        tapWhenReady(app.buttons["onboarding.disclaimerAcceptButton"], timeout: 8)
        tapWhenReady(app.buttons["onboarding.primaryButton"])

        let nameField = app.textFields["onboarding.nameField"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 5))
        nameField.tap()
        nameField.typeText("Smoke Tester")
        if app.keyboards.buttons["return"].exists {
            app.keyboards.buttons["return"].tap()
        }

        tapWhenReady(app.buttons["onboarding.primaryButton"])
        tapWhenReady(app.buttons["onboarding.primaryButton"])

        let stockButton = firstStockMatchButton()
        tapWhenReady(stockButton)
        tapWhenReady(app.buttons["onboarding.primaryButton"])
        tapWhenReady(app.buttons["onboarding.launchTerminalButton"])

        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 10))
        XCTAssertTrue(app.otherElements["screen.today"].waitForExistence(timeout: 10))
    }

    @MainActor
    func testBackendStatusSmokeFallbackDoesNotRequireNetwork() throws {
        launchApp(arguments: [
            "--uitesting",
            "--skip-onboarding",
            "--disable-firebase",
            "--backend-status-smoke"
        ])

        assertTab("Profile", reaches: "screen.profile")

        let backendStatusLink = app.buttons["profile.backendStatusLink"]
        scrollToElement(backendStatusLink, maxSwipes: 8)
        tapWhenReady(backendStatusLink)

        // Match by identifier regardless of element type: the screen id sits
        // on a ScrollView since the backend-status rework, and the result id
        // lives on the check card.
        let screen = app.descendants(matching: .any)["backendStatus.screen"]
        XCTAssertTrue(screen.waitForExistence(timeout: 10))
        let fallbackResult = app.descendants(matching: .any)["backendStatus.result.UITestingFallback"]
        XCTAssertTrue(fallbackResult.waitForExistence(timeout: 10))
    }

    private func launchApp(arguments: [String]) {
        app = XCUIApplication()
        app.launchArguments = arguments
        app.launch()
    }

    private func assertScreenshotRoute(additionalArguments: [String], reaches screenIdentifier: String) {
        launchApp(arguments: [
            "--uitesting",
            "--screenshot-mode",
            "--skip-onboarding",
            "--disable-firebase"
        ] + additionalArguments)

        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 10))
        XCTAssertTrue(
            app.otherElements[screenIdentifier].waitForExistence(timeout: 10),
            "Screenshot route should reach \(screenIdentifier)"
        )
    }

    private func assertStockDetailScreenshotRoute() {
        launchApp(arguments: [
            "--uitesting",
            "--screenshot-mode",
            "--skip-onboarding",
            "--disable-firebase",
            "--tab-stock-detail"
        ])

        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 10))
        XCTAssertTrue(
            app.staticTexts["AAPL"].waitForExistence(timeout: 10)
                || app.staticTexts["Apple Inc."].waitForExistence(timeout: 10),
            "Screenshot route should reach Stock Detail"
        )
    }

    private func assertTab(_ label: String, reaches screenIdentifier: String) {
        if app.otherElements[screenIdentifier].waitForExistence(timeout: 2) {
            return
        }

        let tab = app.tabBars.buttons[label]
        tapWhenReady(tab)
        XCTAssertTrue(
            app.otherElements[screenIdentifier].waitForExistence(timeout: 10),
            "\(label) tab should reach \(screenIdentifier)"
        )
    }

    private func tapWhenReady(_ element: XCUIElement, timeout: TimeInterval = 5) {
        XCTAssertTrue(element.waitForExistence(timeout: timeout), "Expected \(element) to exist")
        XCTAssertTrue(element.isHittable, "Expected \(element) to be hittable")
        element.tap()
    }

    private func scrollToElement(_ element: XCUIElement, maxSwipes: Int) {
        var remainingSwipes = maxSwipes
        while !element.isHittable && remainingSwipes > 0 {
            app.swipeUp()
            remainingSwipes -= 1
        }
        XCTAssertTrue(element.exists, "Expected \(element) to exist after scrolling")
    }

    private func firstStockMatchButton() -> XCUIElement {
        let stockButtons = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "onboarding.stockMatch."))
        let first = stockButtons.firstMatch
        XCTAssertTrue(first.waitForExistence(timeout: 5), "Expected at least one onboarding stock match")
        return first
    }
}
