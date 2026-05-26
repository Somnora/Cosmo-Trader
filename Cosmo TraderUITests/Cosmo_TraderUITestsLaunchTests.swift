//
//  Cosmo_TraderUITestsLaunchTests.swift
//  Cosmo TraderUITests
//
//  Created by James McShane on 12/9/25.
//

import XCTest

final class Cosmo_TraderUITestsLaunchTests: XCTestCase {

    override class var runsForEachTargetApplicationUIConfiguration: Bool {
        true
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testLaunch() throws {
        let app = XCUIApplication()
        app.launchArguments = [
            "--screenshot-mode",
            "--skip-onboarding",
            "--disable-firebase"
        ]
        app.launch()

        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 10))
        XCTAssertTrue(app.otherElements["screen.today"].waitForExistence(timeout: 10))

        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Screenshot Ready Today"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
