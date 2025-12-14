//
//  PortfolioPage.swift
//  Cosmo TraderUITests
//
//  Page Object for the Portfolio tab screen.
//

import XCTest

class PortfolioPage: BasePage {

    // MARK: - Element Identifiers

    private enum Identifiers {
        static let portfolioTab = "Portfolio"
        static let portfolioTitle = "Portfolio"
        static let totalValueLabel = "totalValue"
        static let dailyChangeLabel = "dailyChange"
        static let stockCell = "stockCell"
        static let emptyStateMessage = "emptyState"
        static let buyButton = "Buy"
        static let sellButton = "Sell"
        static let addStockButton = "addStock"
    }

    // MARK: - Elements

    var portfolioTab: XCUIElement {
        app.tabBars.buttons[Identifiers.portfolioTab]
    }

    var portfolioTitle: XCUIElement {
        app.navigationBars[Identifiers.portfolioTitle]
    }

    var totalValueLabel: XCUIElement {
        app.staticTexts[Identifiers.totalValueLabel]
    }

    var dailyChangeLabel: XCUIElement {
        app.staticTexts[Identifiers.dailyChangeLabel]
    }

    var stockCells: XCUIElementQuery {
        app.cells.matching(identifier: Identifiers.stockCell)
    }

    var emptyStateMessage: XCUIElement {
        app.staticTexts[Identifiers.emptyStateMessage]
    }

    var addStockButton: XCUIElement {
        app.buttons[Identifiers.addStockButton]
    }

    // MARK: - Screen Detection

    func isDisplayed() -> Bool {
        return portfolioTab.isSelected || portfolioTitle.exists ||
               app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Portfolio'")).count > 0
    }

    var hasStocks: Bool {
        stockCells.count > 0 ||
        app.cells.count > 0
    }

    var isEmpty: Bool {
        emptyStateMessage.exists ||
        app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'empty' OR label CONTAINS 'no stocks' OR label CONTAINS 'add your first'")).count > 0
    }

    // MARK: - Navigation

    @discardableResult
    func navigateToPortfolio() -> PortfolioPage {
        navigateToTab(.portfolio)
        _ = waitForElement(portfolioTab)
        return self
    }

    // MARK: - Stock Cell Actions

    /// Get stock cell by symbol
    func stockCell(symbol: String) -> XCUIElement {
        return app.cells.containing(NSPredicate(format: "label CONTAINS %@", symbol)).firstMatch
    }

    /// Tap on a stock cell
    @discardableResult
    func tapStock(symbol: String) -> PortfolioPage {
        let cell = stockCell(symbol: symbol)
        tapElement(cell)
        return self
    }

    /// Get count of stock holdings
    var holdingsCount: Int {
        return app.cells.count
    }

    /// Check if specific stock exists in portfolio
    func hasStock(symbol: String) -> Bool {
        return stockCell(symbol: symbol).exists
    }

    // MARK: - Portfolio Value Helpers

    /// Get displayed total value text
    var displayedTotalValue: String? {
        // Look for currency value in header area
        let valueLabels = app.staticTexts.matching(NSPredicate(format: "label CONTAINS '$'"))
        return valueLabels.firstMatch.exists ? valueLabels.firstMatch.label : nil
    }

    /// Get displayed daily change text
    var displayedDailyChange: String? {
        // Look for percentage or +/- value
        let changeLabels = app.staticTexts.matching(NSPredicate(format: "label CONTAINS '%' OR label CONTAINS '+' OR label CONTAINS '-'"))
        return changeLabels.firstMatch.exists ? changeLabels.firstMatch.label : nil
    }

    /// Check if portfolio shows positive daily change
    var isPositiveChange: Bool {
        if let change = displayedDailyChange {
            return change.contains("+") || !change.contains("-")
        }
        // Check for green color indicator
        return app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'up' OR label CONTAINS '+'")).count > 0
    }

    // MARK: - Stock Detail Actions

    /// Swipe to reveal buy/sell actions
    @discardableResult
    func swipeToRevealActions(symbol: String) -> PortfolioPage {
        let cell = stockCell(symbol: symbol)
        swipeLeft(on: cell)
        return self
    }

    /// Tap buy button on stock
    @discardableResult
    func tapBuy(symbol: String) -> PortfolioPage {
        swipeToRevealActions(symbol: symbol)
        let buyButton = app.buttons[Identifiers.buyButton]
        tapElement(buyButton)
        return self
    }

    /// Tap sell button on stock
    @discardableResult
    func tapSell(symbol: String) -> PortfolioPage {
        swipeToRevealActions(symbol: symbol)
        let sellButton = app.buttons[Identifiers.sellButton]
        tapElement(sellButton)
        return self
    }

    // MARK: - Scroll Actions

    /// Scroll to specific stock
    @discardableResult
    func scrollToStock(symbol: String) -> PortfolioPage {
        let cell = stockCell(symbol: symbol)
        scrollToElement(cell)
        return self
    }

    /// Scroll to top of portfolio
    @discardableResult
    func scrollToTop() -> PortfolioPage {
        app.swipeDown()
        app.swipeDown()
        return self
    }

    /// Scroll to bottom of portfolio
    @discardableResult
    func scrollToBottom() -> PortfolioPage {
        app.swipeUp()
        app.swipeUp()
        return self
    }

    // MARK: - Assertions

    /// Assert portfolio is displayed
    func assertPortfolioDisplayed() {
        XCTAssertTrue(isDisplayed(), "Portfolio should be displayed")
    }

    /// Assert stock is in portfolio
    func assertStockInPortfolio(symbol: String) {
        XCTAssertTrue(hasStock(symbol: symbol), "Stock \(symbol) should be in portfolio")
    }

    /// Assert stock is not in portfolio
    func assertStockNotInPortfolio(symbol: String) {
        XCTAssertFalse(hasStock(symbol: symbol), "Stock \(symbol) should not be in portfolio")
    }

    /// Assert portfolio has expected number of holdings
    func assertHoldingsCount(_ expected: Int) {
        XCTAssertEqual(holdingsCount, expected, "Portfolio should have \(expected) holdings")
    }

    /// Assert portfolio shows total value
    func assertTotalValueDisplayed() {
        XCTAssertNotNil(displayedTotalValue, "Total value should be displayed")
    }
}
