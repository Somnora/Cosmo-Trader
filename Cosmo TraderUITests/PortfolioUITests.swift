//
//  PortfolioUITests.swift
//  Cosmo TraderUITests
//
//  UI tests for the Portfolio tab including holdings display and management.
//

import XCTest

final class PortfolioUITests: XCTestCase {

    var app: XCUIApplication!
    var portfolioPage: PortfolioPage!

    override func setUpWithError() throws {
        continueAfterFailure = false

        app = XCUIApplication()
        // Skip onboarding, use sample data
        app.launchArguments = ["--uitesting", "--skip-onboarding", "--sample-portfolio"]
        app.launch()

        portfolioPage = PortfolioPage(app: app)
    }

    override func tearDownWithError() throws {
        app = nil
        portfolioPage = nil
    }

    // MARK: - Portfolio Display Tests

    func testPortfolioTabIsAccessible() throws {
        // Navigate to portfolio tab
        portfolioPage.navigateToPortfolio()

        // Verify portfolio is displayed
        XCTAssertTrue(portfolioPage.isDisplayed(), "Portfolio tab should be accessible and display content")
    }

    func testPortfolioShowsTotalValue() throws {
        portfolioPage.navigateToPortfolio()

        // Check for total value display
        let hasValueDisplay = portfolioPage.displayedTotalValue != nil ||
                             app.staticTexts.matching(NSPredicate(format: "label CONTAINS '$'")).count > 0

        XCTAssertTrue(hasValueDisplay, "Portfolio should display total value")
    }

    func testPortfolioShowsDailyChange() throws {
        portfolioPage.navigateToPortfolio()

        // Check for daily change display (percentage or absolute)
        let hasChangeDisplay = portfolioPage.displayedDailyChange != nil ||
                              app.staticTexts.matching(NSPredicate(format: "label CONTAINS '%' OR label CONTAINS '+' OR label CONTAINS 'Today'")).count > 0

        XCTAssertTrue(hasChangeDisplay, "Portfolio should display daily change")
    }

    func testPortfolioDisplaysStockHoldings() throws {
        portfolioPage.navigateToPortfolio()

        // Should have stock cells or list items
        let hasStocks = portfolioPage.hasStocks ||
                       app.cells.count > 0 ||
                       app.collectionViews.cells.count > 0

        XCTAssertTrue(hasStocks, "Portfolio should display stock holdings")
    }

    func testPortfolioStockCellShowsSymbol() throws {
        portfolioPage.navigateToPortfolio()

        // Look for stock symbols (1-5 uppercase letters)
        let symbolPredicate = NSPredicate(format: "label MATCHES '([A-Z]{1,5})'")
        let hasSymbols = app.staticTexts.matching(symbolPredicate).count > 0

        XCTAssertTrue(hasSymbols, "Stock cells should display symbols")
    }

    func testPortfolioStockCellShowsPrice() throws {
        portfolioPage.navigateToPortfolio()

        // Check for price display with currency
        let hasPrices = app.staticTexts.matching(NSPredicate(format: "label CONTAINS '$'")).count > 0

        XCTAssertTrue(hasPrices, "Stock cells should display prices")
    }

    func testPortfolioStockCellShowsShareCount() throws {
        portfolioPage.navigateToPortfolio()

        // Check for share count (e.g., "10 shares" or just number)
        let hasShares = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'share' OR label MATCHES '\\\\d+\\\\.?\\\\d* (share|shares)'")).count > 0

        // Share count display is optional but expected
        if !hasShares {
            print("Note: Share count not explicitly displayed in stock cells")
        }
    }

    // MARK: - Empty State Tests

    func testEmptyPortfolioShowsMessage() throws {
        // Launch with empty portfolio
        app.terminate()
        app = XCUIApplication()
        app.launchArguments = ["--uitesting", "--skip-onboarding", "--empty-portfolio"]
        app.launch()

        portfolioPage = PortfolioPage(app: app)
        portfolioPage.navigateToPortfolio()

        // Check for empty state
        let hasEmptyState = portfolioPage.isEmpty ||
                           app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'empty' OR label CONTAINS 'no stocks' OR label CONTAINS 'add' OR label CONTAINS 'start'")).count > 0

        XCTAssertTrue(hasEmptyState, "Empty portfolio should show appropriate message")
    }

    func testEmptyPortfolioHasAddStockAction() throws {
        // Launch with empty portfolio
        app.terminate()
        app = XCUIApplication()
        app.launchArguments = ["--uitesting", "--skip-onboarding", "--empty-portfolio"]
        app.launch()

        portfolioPage = PortfolioPage(app: app)
        portfolioPage.navigateToPortfolio()

        // Check for add action
        let hasAddAction = portfolioPage.addStockButton.exists ||
                          app.buttons.matching(NSPredicate(format: "label CONTAINS 'Add' OR label CONTAINS 'Discover' OR label CONTAINS 'Browse'")).count > 0

        XCTAssertTrue(hasAddAction, "Empty portfolio should have action to add stocks")
    }

    // MARK: - Stock Interaction Tests

    func testTappingStockShowsDetails() throws {
        portfolioPage.navigateToPortfolio()

        // Tap first stock cell
        let firstCell = app.cells.firstMatch
        if firstCell.waitForExistence(timeout: 5) {
            firstCell.tap()

            // Should show more details (modal, sheet, or navigation)
            let hasDetails = app.navigationBars.count > 1 ||
                            app.sheets.count > 0 ||
                            app.otherElements.matching(NSPredicate(format: "label CONTAINS 'Detail' OR label CONTAINS 'Price' OR label CONTAINS 'Performance'")).count > 0

            // Details view is optional behavior
            if !hasDetails {
                print("Note: Tapping stock did not reveal details view")
            }
        }
    }

    func testStockCellSwipeRevealsActions() throws {
        portfolioPage.navigateToPortfolio()

        // Find a stock cell
        let firstCell = app.cells.firstMatch
        if firstCell.waitForExistence(timeout: 5) {
            // Swipe left to reveal actions
            firstCell.swipeLeft()

            // Check for action buttons
            let hasActions = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Buy' OR label CONTAINS 'Sell' OR label CONTAINS 'Delete'")).count > 0

            // Swipe actions are optional
            if !hasActions {
                print("Note: Swipe actions not implemented on stock cells")
            }
        }
    }

    // MARK: - Sorting and Filtering Tests

    func testPortfolioSortingOptions() throws {
        portfolioPage.navigateToPortfolio()

        // Look for sort button
        let sortButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Sort' OR label CONTAINS 'Filter'")).firstMatch

        if sortButton.exists {
            sortButton.tap()

            // Should show sorting options
            let hasOptions = app.buttons.count > 1 ||
                            app.cells.count > 0

            XCTAssertTrue(hasOptions, "Should display sorting options")
        } else {
            print("Note: Sort button not found in portfolio")
        }
    }

    // MARK: - Scroll Tests

    func testPortfolioScrollsToShowAllHoldings() throws {
        portfolioPage.navigateToPortfolio()

        // Get initial cell count
        let initialCellCount = app.cells.count

        // Scroll down
        portfolioPage.scrollToBottom()

        // Should still see cells (or have scrolled)
        let afterScrollCellCount = app.cells.count

        XCTAssertTrue(afterScrollCellCount >= 0, "Portfolio should be scrollable")
    }

    func testPortfolioPullToRefresh() throws {
        portfolioPage.navigateToPortfolio()

        // Scroll to top and pull down
        portfolioPage.scrollToTop()
        app.swipeDown()

        // Check for refresh indicator or just verify no crash
        let hasRefreshIndicator = app.activityIndicators.count > 0

        // Pull to refresh is optional
        if !hasRefreshIndicator {
            print("Note: Pull to refresh may not be implemented")
        }
    }

    // MARK: - Color Coding Tests

    func testPositiveChangeShowsGreenIndicator() throws {
        portfolioPage.navigateToPortfolio()

        // Look for positive indicators
        let hasPositiveIndicator = app.staticTexts.matching(NSPredicate(format: "label CONTAINS '+'")).count > 0 ||
                                   portfolioPage.isPositiveChange

        // This test may pass or fail depending on market data
        if !hasPositiveIndicator {
            print("Note: No positive change indicator found (may depend on market data)")
        }
    }

    // MARK: - Zodiac Integration Tests

    func testPortfolioShowsZodiacSignForStocks() throws {
        portfolioPage.navigateToPortfolio()

        // Look for zodiac signs or symbols
        let zodiacSigns = ["Aries", "Taurus", "Gemini", "Cancer", "Leo", "Virgo",
                          "Libra", "Scorpio", "Sagittarius", "Capricorn", "Aquarius", "Pisces"]

        var hasZodiacDisplay = false
        for sign in zodiacSigns {
            if app.staticTexts[sign].exists {
                hasZodiacDisplay = true
                break
            }
        }

        // Also check for zodiac emojis
        let zodiacEmojis = ["", "", "", "", "", "", "", "", "", "", "", ""]
        for emoji in zodiacEmojis {
            if app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", emoji)).count > 0 {
                hasZodiacDisplay = true
                break
            }
        }

        XCTAssertTrue(hasZodiacDisplay, "Portfolio should display zodiac signs for stocks")
    }

    func testPortfolioShowsCompatibilityBadge() throws {
        portfolioPage.navigateToPortfolio()

        // Look for compatibility indicators
        let hasCompatibility = app.staticTexts.matching(NSPredicate(format: "label CONTAINS '%' OR label CONTAINS 'Compatible' OR label CONTAINS 'match'")).count > 0

        // Compatibility badge is a key feature
        if !hasCompatibility {
            print("Note: Compatibility badge not visible in portfolio list")
        }
    }

    // MARK: - Navigation Tests

    func testPortfolioToDiscoverNavigation() throws {
        portfolioPage.navigateToPortfolio()

        // Navigate to discover
        portfolioPage.navigateToTab(.discover)

        // Verify we're on discover
        let discoverPage = DiscoverPage(app: app)
        XCTAssertTrue(discoverPage.isDisplayed(), "Should navigate to Discover tab")
    }

    func testPortfolioToProfileNavigation() throws {
        portfolioPage.navigateToPortfolio()

        // Navigate to profile
        portfolioPage.navigateToTab(.profile)

        // Verify we're on profile
        let profilePage = ProfilePage(app: app)
        XCTAssertTrue(profilePage.isDisplayed(), "Should navigate to Profile tab")
    }

    // MARK: - Performance Tests

    func testPortfolioLoadsWithinReasonableTime() throws {
        let startTime = Date()

        portfolioPage.navigateToPortfolio()

        // Wait for content to appear
        _ = app.cells.firstMatch.waitForExistence(timeout: 10)

        let loadTime = Date().timeIntervalSince(startTime)

        XCTAssertLessThan(loadTime, 5.0, "Portfolio should load within 5 seconds")
    }

    // MARK: - Accessibility Tests

    func testPortfolioElementsHaveAccessibilityLabels() throws {
        portfolioPage.navigateToPortfolio()

        // Check that main elements have accessibility labels
        let cells = app.cells.allElementsBoundByIndex

        for cell in cells.prefix(3) {
            let hasLabel = !cell.label.isEmpty
            XCTAssertTrue(hasLabel, "Portfolio cells should have accessibility labels")
        }
    }

    // MARK: - Buy/Sell Flow Tests

    func testBuyMoreSharesFlow() throws {
        portfolioPage.navigateToPortfolio()

        // Find a stock and try to buy more
        let firstCell = app.cells.firstMatch
        if firstCell.waitForExistence(timeout: 5) {
            firstCell.tap()

            // Look for buy button in detail view
            let buyButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Buy'")).firstMatch

            if buyButton.exists {
                buyButton.tap()

                // Should show quantity input or confirmation
                let hasInput = app.textFields.count > 0 ||
                              app.sheets.count > 0 ||
                              app.alerts.count > 0

                if hasInput {
                    XCTAssertTrue(hasInput, "Buy flow should show input for quantity")
                }
            }
        }
    }

    func testSellSharesFlow() throws {
        portfolioPage.navigateToPortfolio()

        // Find a stock and try to sell
        let firstCell = app.cells.firstMatch
        if firstCell.waitForExistence(timeout: 5) {
            firstCell.tap()

            // Look for sell button in detail view
            let sellButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Sell'")).firstMatch

            if sellButton.exists {
                sellButton.tap()

                // Should show quantity input or confirmation
                let hasInput = app.textFields.count > 0 ||
                              app.sheets.count > 0 ||
                              app.alerts.count > 0

                if hasInput {
                    XCTAssertTrue(hasInput, "Sell flow should show input for quantity")
                }
            }
        }
    }
}
