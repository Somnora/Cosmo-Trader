import XCTest

// Local-only journey test for the manual holdings shares editor (CI runs
// only SmokeUITests; see ios-ci.yml). Drives Portfolio long-press → edit →
// remove and the StockDetail edit affordance end-to-end, network-free.
final class HoldingSharesEditorUITests: XCTestCase {

    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    override func tearDownWithError() throws {
        app = nil
    }

    func testManualHoldingEditJourney() throws {
        app = XCUIApplication()
        app.launchArguments = [
            "--uitesting",
            "--disable-firebase",
            "--skip-onboarding",
            "--tab-portfolio"
        ]
        app.launch()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 10))

        // 1. Scroll to the holdings table. Target the row's identifier:
        //    bare staticTexts["MSFT"] also matches the TOP HOLDINGS and
        //    HISTORY STATUS rows higher up the page.
        let msftRow = app.buttons["portfolio.holdingRow.MSFT"]
        scrollToElement(msftRow, maxSwipes: 30)
        attach("01-holdings-table")

        // 2. Long-press a holding row → context menu.
        msftRow.press(forDuration: 1.2)
        let editShares = app.buttons["Edit Shares"]
        XCTAssertTrue(editShares.waitForExistence(timeout: 10), "Long-press should surface Edit Shares")
        attach("02-context-menu")
        editShares.tap()

        // 3. Editor sheet opens prefilled with the current share count.
        let sharesField = app.textFields["holding.sharesEditor.shares"]
        XCTAssertTrue(sharesField.waitForExistence(timeout: 10))
        let prefilled = (sharesField.value as? String) ?? ""
        XCTAssertFalse(prefilled.isEmpty, "Shares field should be prefilled")
        attach("03-editor-prefilled")

        // 4. Probe: zero shares → inline error and disabled Save.
        let save = app.buttons["holding.sharesEditor.save"]
        replaceText(in: sharesField, with: "0")
        XCTAssertTrue(
            app.staticTexts["Enter a share count above zero."].waitForExistence(timeout: 5),
            "Zero shares should show the inline validation error"
        )
        XCTAssertFalse(save.isEnabled, "Save must be disabled for invalid shares")
        attach("04-invalid-zero-disables-save")

        // 5. Valid edit: 25 shares + cost basis, then Save.
        replaceText(in: sharesField, with: "25")
        let costField = app.textFields["holding.sharesEditor.costBasis"]
        replaceText(in: costField, with: "150")
        XCTAssertTrue(save.isEnabled)
        attach("05-valid-edit")
        save.tap()

        // 6. Re-open the editor: the new values persisted.
        XCTAssertTrue(waitForDisappearance(of: sharesField, timeout: 10))
        msftRow.press(forDuration: 1.2)
        XCTAssertTrue(editShares.waitForExistence(timeout: 10))
        editShares.tap()
        XCTAssertTrue(sharesField.waitForExistence(timeout: 10))
        XCTAssertEqual(sharesField.value as? String, "25", "Edited share count should persist")
        XCTAssertEqual(costField.value as? String, "150.00", "Edited cost basis should persist")
        attach("06-reopened-persisted")

        // 7. Remove flow: dismiss the keyboard, remove behind confirmation.
        let keyboardDone = app.buttons["Done"].firstMatch
        if keyboardDone.waitForExistence(timeout: 3) {
            keyboardDone.tap()
        }
        let remove = app.buttons["holding.sharesEditor.remove"]
        XCTAssertTrue(remove.waitForExistence(timeout: 5))
        XCTAssertTrue(remove.isHittable, "Remove button must be reachable with the keyboard dismissed")
        remove.tap()
        let confirmRemove = app.buttons["Remove MSFT"]
        XCTAssertTrue(confirmRemove.waitForExistence(timeout: 10), "Removal must be confirmed, never one-tap")
        attach("07-remove-confirmation")
        confirmRemove.tap()
        XCTAssertTrue(waitForDisappearance(of: sharesField, timeout: 10))
        attach("08-after-remove")

        // 8. StockDetail edit affordance: an owned stock's button reads
        //    "<n> Shares — Edit" and opens the same editor.
        let aaplRow = app.buttons["portfolio.holdingRow.AAPL"]
        scrollToElement(aaplRow, maxSwipes: 10)
        aaplRow.tap()
        let detailButton = app.buttons["stockDetail.portfolioButton"]
        scrollToElement(detailButton, maxSwipes: 30)
        // .label surfaces the accessibility label ("Edit your AAPL shares"),
        // not the visible "<n> Shares — Edit" title.
        let detailLabel = detailButton.label
        XCTAssertTrue(detailLabel.contains("Edit your AAPL shares"), "Owned stock should offer share editing, got: \(detailLabel)")
        attach("09-detail-edit-button")
        detailButton.tap()
        XCTAssertTrue(sharesField.waitForExistence(timeout: 10))
        attach("10-detail-editor")
        app.buttons["Cancel"].tap()
        XCTAssertTrue(waitForDisappearance(of: sharesField, timeout: 10))
    }

    // MARK: - Helpers (SmokeUITests idioms)

    private func attach(_ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    private func replaceText(in field: XCUIElement, with text: String) {
        field.tap()
        let current = (field.value as? String) ?? ""
        let deletes = String(repeating: XCUIKeyboardKey.delete.rawValue, count: current.count + 2)
        field.typeText(deletes)
        field.typeText(text)
    }

    private func waitForDisappearance(of element: XCUIElement, timeout: TimeInterval) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if !element.exists { return true }
            Thread.sleep(forTimeInterval: 0.3)
        }
        return !element.exists
    }

    private func scrollToElement(_ element: XCUIElement, maxSwipes: Int) {
        var remainingSwipes = maxSwipes
        while !element.isHittable && remainingSwipes > 0 {
            app.swipeUp()
            remainingSwipes -= 1
        }
        XCTAssertTrue(element.exists, "Expected \(element) to exist after scrolling")
        waitForStableFrame(element)
    }

    private func waitForStableFrame(_ element: XCUIElement, timeout: TimeInterval = 5) {
        let deadline = Date().addingTimeInterval(timeout)
        var lastFrame = element.frame
        while Date() < deadline {
            Thread.sleep(forTimeInterval: 0.3)
            let frame = element.frame
            if frame == lastFrame { return }
            lastFrame = frame
        }
    }
}
