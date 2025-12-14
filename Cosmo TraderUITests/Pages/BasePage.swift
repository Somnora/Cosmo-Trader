//
//  BasePage.swift
//  Cosmo TraderUITests
//
//  Base class for Page Object pattern providing common UI test utilities.
//

import XCTest

/// Base class for all page objects providing common functionality
class BasePage {
    let app: XCUIApplication

    init(app: XCUIApplication) {
        self.app = app
    }

    // MARK: - Wait Helpers

    /// Wait for an element to exist with timeout
    @discardableResult
    func waitForElement(_ element: XCUIElement, timeout: TimeInterval = 5) -> Bool {
        return element.waitForExistence(timeout: timeout)
    }

    /// Wait for element to be hittable (visible and enabled)
    @discardableResult
    func waitForHittable(_ element: XCUIElement, timeout: TimeInterval = 5) -> Bool {
        let predicate = NSPredicate(format: "isHittable == true")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: element)
        let result = XCTWaiter.wait(for: [expectation], timeout: timeout)
        return result == .completed
    }

    /// Wait for element to disappear
    @discardableResult
    func waitForElementToDisappear(_ element: XCUIElement, timeout: TimeInterval = 5) -> Bool {
        let predicate = NSPredicate(format: "exists == false")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: element)
        let result = XCTWaiter.wait(for: [expectation], timeout: timeout)
        return result == .completed
    }

    // MARK: - Tap Helpers

    /// Tap element with wait
    func tapElement(_ element: XCUIElement, timeout: TimeInterval = 5) {
        _ = waitForHittable(element, timeout: timeout)
        element.tap()
    }

    /// Tap button by identifier
    func tapButton(_ identifier: String, timeout: TimeInterval = 5) {
        let button = app.buttons[identifier]
        tapElement(button, timeout: timeout)
    }

    // MARK: - Text Entry Helpers

    /// Clear and type text into a text field
    func clearAndType(_ element: XCUIElement, text: String) {
        tapElement(element)

        // Select all and delete
        if let currentValue = element.value as? String, !currentValue.isEmpty {
            element.tap()
            element.press(forDuration: 1.0)
            if app.menuItems["Select All"].waitForExistence(timeout: 1) {
                app.menuItems["Select All"].tap()
                element.typeText(XCUIKeyboardKey.delete.rawValue)
            }
        }

        element.typeText(text)
    }

    /// Type text into text field by identifier
    func typeInTextField(_ identifier: String, text: String) {
        let textField = app.textFields[identifier]
        _ = waitForElement(textField)
        clearAndType(textField, text: text)
    }

    // MARK: - Swipe Helpers

    /// Swipe left on an element
    func swipeLeft(on element: XCUIElement) {
        element.swipeLeft()
    }

    /// Swipe right on an element
    func swipeRight(on element: XCUIElement) {
        element.swipeRight()
    }

    /// Swipe up on an element
    func swipeUp(on element: XCUIElement) {
        element.swipeUp()
    }

    /// Swipe down on an element
    func swipeDown(on element: XCUIElement) {
        element.swipeDown()
    }

    // MARK: - Drag Helpers

    /// Perform a drag gesture with specific coordinates
    func drag(element: XCUIElement, byX: CGFloat, byY: CGFloat) {
        let start = element.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        let end = start.withOffset(CGVector(dx: byX, dy: byY))
        start.press(forDuration: 0.1, thenDragTo: end)
    }

    // MARK: - Scroll Helpers

    /// Scroll until element is visible
    func scrollToElement(_ element: XCUIElement, direction: UISwipeGestureRecognizer.Direction = .up, maxScrolls: Int = 10) {
        var scrollCount = 0
        while !element.isHittable && scrollCount < maxScrolls {
            switch direction {
            case .up:
                app.swipeUp()
            case .down:
                app.swipeDown()
            case .left:
                app.swipeLeft()
            case .right:
                app.swipeRight()
            @unknown default:
                app.swipeUp()
            }
            scrollCount += 1
        }
    }

    // MARK: - Alert Helpers

    /// Handle system alert if present
    func handleSystemAlert(accept: Bool = true) {
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let alertButton = accept ? springboard.buttons["Allow"] : springboard.buttons["Don't Allow"]
        if alertButton.waitForExistence(timeout: 2) {
            alertButton.tap()
        }
    }

    // MARK: - Assertion Helpers

    /// Assert element exists
    func assertExists(_ element: XCUIElement, message: String = "") {
        XCTAssertTrue(element.exists, message.isEmpty ? "Element should exist" : message)
    }

    /// Assert element does not exist
    func assertNotExists(_ element: XCUIElement, message: String = "") {
        XCTAssertFalse(element.exists, message.isEmpty ? "Element should not exist" : message)
    }

    /// Assert element has expected value
    func assertValue(_ element: XCUIElement, equals expectedValue: String) {
        XCTAssertEqual(element.value as? String, expectedValue)
    }

    /// Assert element label contains text
    func assertLabelContains(_ element: XCUIElement, text: String) {
        XCTAssertTrue(element.label.contains(text), "Element label should contain '\(text)'")
    }
}

// MARK: - Navigation Protocol

protocol NavigableScreen {
    var app: XCUIApplication { get }
    func isDisplayed() -> Bool
}

// MARK: - Tab Bar Navigation

enum TabBarItem: String {
    case portfolio = "Portfolio"
    case discover = "Discover"
    case profile = "Profile"
}

extension BasePage {
    /// Navigate to a specific tab
    func navigateToTab(_ tab: TabBarItem) {
        let tabButton = app.tabBars.buttons[tab.rawValue]
        tapElement(tabButton)
    }

    /// Check if currently on a specific tab
    func isOnTab(_ tab: TabBarItem) -> Bool {
        let tabButton = app.tabBars.buttons[tab.rawValue]
        return tabButton.isSelected
    }
}
