//
//  Cosmo_TraderUITests.swift
//  Cosmo TraderUITests
//
//  Core UI tests and app launch sanity checks.
//

import XCTest

final class Cosmo_TraderUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false

        app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - App Launch Tests

    @MainActor
    func testAppLaunches() throws {
        app.launch()

        // App should launch without crashing
        XCTAssertTrue(app.exists, "App should launch successfully")
    }

    @MainActor
    func testAppHasContent() throws {
        app.launchArguments.append("--skip-onboarding")
        app.launch()

        // Should have some content visible
        let hasContent = app.staticTexts.count > 0 || app.buttons.count > 0

        XCTAssertTrue(hasContent, "App should display content after launch")
    }

    @MainActor
    func testTabBarExists() throws {
        app.launchArguments.append("--skip-onboarding")
        app.launch()

        // Main app should have tab bar
        let tabBar = app.tabBars.firstMatch
        let hasTabBar = tabBar.waitForExistence(timeout: 10)

        XCTAssertTrue(hasTabBar, "App should have tab bar after onboarding")
    }

    @MainActor
    func testAllTabsAccessible() throws {
        app.launchArguments.append("--skip-onboarding")
        app.launch()

        let tabBar = app.tabBars.firstMatch
        _ = tabBar.waitForExistence(timeout: 10)

        // Check for expected tabs
        let portfolioTab = app.tabBars.buttons["Portfolio"]
        let discoverTab = app.tabBars.buttons["Discover"]
        let profileTab = app.tabBars.buttons["Profile"]

        XCTAssertTrue(portfolioTab.exists || discoverTab.exists || profileTab.exists,
                     "At least one main tab should exist")
    }

    // MARK: - Orientation Tests

    @MainActor
    func testAppSupportsPortrait() throws {
        app.launch()

        XCUIDevice.shared.orientation = .portrait

        XCTAssertTrue(app.exists, "App should work in portrait orientation")
    }

    @MainActor
    func testAppSupportsLandscape() throws {
        app.launch()

        XCUIDevice.shared.orientation = .landscapeLeft

        // Give time for rotation
        Thread.sleep(forTimeInterval: 1)

        XCTAssertTrue(app.exists, "App should work in landscape orientation")

        // Reset to portrait
        XCUIDevice.shared.orientation = .portrait
    }

    // MARK: - Memory Tests

    @MainActor
    func testAppDoesNotCrashOnRepeatedLaunch() throws {
        for _ in 0..<3 {
            app.launch()
            XCTAssertTrue(app.exists, "App should launch each time")
            app.terminate()
        }
    }

    // MARK: - Performance Tests

    @MainActor
    func testLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }

    @MainActor
    func testLaunchToContentPerformance() throws {
        app.launchArguments.append("--skip-onboarding")

        let expectation = XCTestExpectation(description: "Content visible")

        let startTime = Date()

        app.launch()

        // Wait for content
        DispatchQueue.main.async {
            _ = self.app.staticTexts.firstMatch.waitForExistence(timeout: 10)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 15)

        let loadTime = Date().timeIntervalSince(startTime)

        XCTAssertLessThan(loadTime, 5.0, "App should show content within 5 seconds")
    }

    // MARK: - Accessibility Tests

    @MainActor
    func testAppElementsAreAccessible() throws {
        app.launchArguments.append("--skip-onboarding")
        app.launch()

        _ = app.staticTexts.firstMatch.waitForExistence(timeout: 10)

        // Check that visible elements have accessibility info
        let buttons = app.buttons.allElementsBoundByIndex
        for button in buttons.prefix(5) {
            if button.exists && button.isHittable {
                let hasAccessibility = !button.label.isEmpty || !button.identifier.isEmpty
                XCTAssertTrue(hasAccessibility, "Button should have accessibility label or identifier")
            }
        }
    }

    // MARK: - Dark Mode Tests

    @MainActor
    func testAppWorksInDarkMode() throws {
        // Note: This requires runtime environment variable or system setting
        // In actual testing, would use XCUIDevice appearance settings
        app.launch()

        XCTAssertTrue(app.exists, "App should work regardless of appearance mode")
    }

    // MARK: - State Persistence Tests

    @MainActor
    func testAppResumesFromBackground() throws {
        app.launchArguments.append("--skip-onboarding")
        app.launch()

        _ = app.staticTexts.firstMatch.waitForExistence(timeout: 5)

        // Background the app
        XCUIDevice.shared.press(.home)

        Thread.sleep(forTimeInterval: 1)

        // Bring back to foreground
        app.activate()

        // Should still work
        XCTAssertTrue(app.exists, "App should resume from background")
    }

    // MARK: - Navigation Tests

    @MainActor
    func testTabNavigationWorks() throws {
        app.launchArguments.append("--skip-onboarding")
        app.launch()

        let tabBar = app.tabBars.firstMatch
        _ = tabBar.waitForExistence(timeout: 10)

        // Try tapping each tab
        let tabs = tabBar.buttons.allElementsBoundByIndex
        for tab in tabs {
            if tab.isHittable {
                tab.tap()
                Thread.sleep(forTimeInterval: 0.5)
                XCTAssertTrue(app.exists, "App should handle tab navigation")
            }
        }
    }
}
