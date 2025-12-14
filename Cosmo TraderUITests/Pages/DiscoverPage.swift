//
//  DiscoverPage.swift
//  Cosmo TraderUITests
//
//  Page Object for the Discover tab with swipeable stock cards.
//

import XCTest

class DiscoverPage: BasePage {

    // MARK: - Element Identifiers

    private enum Identifiers {
        static let discoverTab = "Discover"
        static let stockCard = "stockCard"
        static let filterBar = "filterBar"
        static let addButton = "addButton"
        static let skipButton = "skipButton"
        static let compatibilityBadge = "compatibilityBadge"
        static let stockSymbol = "stockSymbol"
        static let stockName = "stockName"
        static let zodiacBadge = "zodiacBadge"
    }

    // MARK: - Elements

    var discoverTab: XCUIElement {
        app.tabBars.buttons[Identifiers.discoverTab]
    }

    var stockCard: XCUIElement {
        app.otherElements[Identifiers.stockCard]
    }

    var allStockCards: XCUIElementQuery {
        app.otherElements.matching(identifier: Identifiers.stockCard)
    }

    var filterBar: XCUIElement {
        app.otherElements[Identifiers.filterBar]
    }

    var addButton: XCUIElement {
        app.buttons[Identifiers.addButton]
    }

    var skipButton: XCUIElement {
        app.buttons[Identifiers.skipButton]
    }

    var compatibilityBadge: XCUIElement {
        app.staticTexts[Identifiers.compatibilityBadge]
    }

    // MARK: - Screen Detection

    func isDisplayed() -> Bool {
        return discoverTab.isSelected ||
               stockCard.exists ||
               app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Discover'")).count > 0
    }

    var hasCards: Bool {
        return stockCard.exists || allStockCards.count > 0
    }

    var isEmptyState: Bool {
        return app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'no more' OR label CONTAINS 'all caught up' OR label CONTAINS 'check back'")).count > 0
    }

    // MARK: - Navigation

    @discardableResult
    func navigateToDiscover() -> DiscoverPage {
        navigateToTab(.discover)
        _ = waitForElement(discoverTab)
        return self
    }

    // MARK: - Card Information

    /// Get current stock card symbol
    var currentCardSymbol: String? {
        let symbolLabel = app.staticTexts[Identifiers.stockSymbol]
        if symbolLabel.exists {
            return symbolLabel.label
        }
        // Try to find symbol pattern (1-5 uppercase letters)
        let allTexts = app.staticTexts.allElementsBoundByIndex
        for text in allTexts {
            let label = text.label
            if label.count >= 1 && label.count <= 5 && label == label.uppercased() && label.allSatisfy({ $0.isLetter }) {
                return label
            }
        }
        return nil
    }

    /// Get current stock card name
    var currentCardName: String? {
        let nameLabel = app.staticTexts[Identifiers.stockName]
        return nameLabel.exists ? nameLabel.label : nil
    }

    /// Get compatibility score from current card
    var currentCardCompatibility: String? {
        if compatibilityBadge.exists {
            return compatibilityBadge.label
        }
        let percentLabels = app.staticTexts.matching(NSPredicate(format: "label CONTAINS '%'"))
        return percentLabels.firstMatch.exists ? percentLabels.firstMatch.label : nil
    }

    /// Get zodiac sign from current card
    var currentCardZodiacSign: String? {
        let zodiacLabel = app.staticTexts[Identifiers.zodiacBadge]
        return zodiacLabel.exists ? zodiacLabel.label : nil
    }

    // MARK: - Swipe Actions

    /// Swipe right on current card (add to watchlist/portfolio)
    @discardableResult
    func swipeRightOnCard() -> DiscoverPage {
        let card = stockCard.exists ? stockCard : app.otherElements.firstMatch
        swipeRight(on: card)
        _ = waitForElement(stockCard, timeout: 2)
        return self
    }

    /// Swipe left on current card (skip stock)
    @discardableResult
    func swipeLeftOnCard() -> DiscoverPage {
        let card = stockCard.exists ? stockCard : app.otherElements.firstMatch
        swipeLeft(on: card)
        _ = waitForElement(stockCard, timeout: 2)
        return self
    }

    /// Perform drag gesture to the right (like/add)
    @discardableResult
    func dragCardRight() -> DiscoverPage {
        let card = stockCard.exists ? stockCard : app.otherElements.firstMatch
        drag(element: card, byX: 200, byY: 0)
        _ = waitForElement(stockCard, timeout: 2)
        return self
    }

    /// Perform drag gesture to the left (skip)
    @discardableResult
    func dragCardLeft() -> DiscoverPage {
        let card = stockCard.exists ? stockCard : app.otherElements.firstMatch
        drag(element: card, byX: -200, byY: 0)
        _ = waitForElement(stockCard, timeout: 2)
        return self
    }

    // MARK: - Button Actions

    /// Tap add button (alternative to swipe right)
    @discardableResult
    func tapAddButton() -> DiscoverPage {
        if addButton.exists {
            tapElement(addButton)
        } else {
            // Look for common add button patterns
            let likeButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'add' OR label CONTAINS 'like' OR label CONTAINS 'heart' OR label CONTAINS '+'")).firstMatch
            if likeButton.exists {
                tapElement(likeButton)
            }
        }
        return self
    }

    /// Tap skip button (alternative to swipe left)
    @discardableResult
    func tapSkipButton() -> DiscoverPage {
        if skipButton.exists {
            tapElement(skipButton)
        } else {
            // Look for common skip button patterns
            let passButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'skip' OR label CONTAINS 'pass' OR label CONTAINS 'x'")).firstMatch
            if passButton.exists {
                tapElement(passButton)
            }
        }
        return self
    }

    /// Tap on card to view details
    @discardableResult
    func tapCard() -> DiscoverPage {
        let card = stockCard.exists ? stockCard : app.otherElements.firstMatch
        tapElement(card)
        return self
    }

    // MARK: - Filter Actions

    /// Select filter option
    @discardableResult
    func selectFilter(_ filterName: String) -> DiscoverPage {
        let filterButton = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", filterName)).firstMatch
        if filterButton.exists {
            tapElement(filterButton)
        }
        return self
    }

    /// Select "All" filter
    @discardableResult
    func selectAllFilter() -> DiscoverPage {
        return selectFilter("All")
    }

    /// Select "Fire" element filter
    @discardableResult
    func selectFireFilter() -> DiscoverPage {
        return selectFilter("Fire")
    }

    /// Select "Earth" element filter
    @discardableResult
    func selectEarthFilter() -> DiscoverPage {
        return selectFilter("Earth")
    }

    /// Select "Air" element filter
    @discardableResult
    func selectAirFilter() -> DiscoverPage {
        return selectFilter("Air")
    }

    /// Select "Water" element filter
    @discardableResult
    func selectWaterFilter() -> DiscoverPage {
        return selectFilter("Water")
    }

    // MARK: - Card Count

    /// Count of remaining cards (if shown)
    var remainingCardsCount: Int? {
        let countLabels = app.staticTexts.matching(NSPredicate(format: "label MATCHES '\\\\d+ (left|remaining|more)'"))
        if countLabels.firstMatch.exists {
            let label = countLabels.firstMatch.label
            if let number = label.components(separatedBy: CharacterSet.decimalDigits.inverted).first(where: { !$0.isEmpty }) {
                return Int(number)
            }
        }
        return nil
    }

    // MARK: - Assertions

    /// Assert discover screen is displayed
    func assertDiscoverDisplayed() {
        XCTAssertTrue(isDisplayed(), "Discover screen should be displayed")
    }

    /// Assert cards are available
    func assertCardsAvailable() {
        XCTAssertTrue(hasCards, "Stock cards should be available")
    }

    /// Assert current card shows compatibility score
    func assertCompatibilityShown() {
        XCTAssertNotNil(currentCardCompatibility, "Compatibility score should be displayed")
    }

    /// Assert current card has stock symbol
    func assertStockSymbolShown() {
        XCTAssertNotNil(currentCardSymbol, "Stock symbol should be displayed")
    }

    /// Assert empty state is shown
    func assertEmptyState() {
        XCTAssertTrue(isEmptyState, "Empty state should be displayed when no cards remain")
    }

    /// Assert a new card appeared after action
    func assertCardChanged(from previousSymbol: String?) {
        let newSymbol = currentCardSymbol
        if previousSymbol != nil {
            XCTAssertNotEqual(previousSymbol, newSymbol, "Card should change after swipe action")
        }
    }
}
