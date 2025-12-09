import Foundation
import SwiftUI

// MARK: - PortfolioViewModel
// ==========================
// The "brain" for the Portfolio tab.
//
// This ViewModel now works with UserProfile to provide:
// - User information (name, sun sign)
// - Portfolio data and calculations
// - Element breakdown analysis
// - Compatibility scores
//
// The @Observable macro tells SwiftUI to watch for changes
// and automatically update the UI when data changes.

@Observable
class PortfolioViewModel {

    // MARK: - Properties

    /// The current user's profile (contains portfolio)
    var user: UserProfile

    /// Is data currently loading?
    var isLoading: Bool = false

    /// Any error message to display
    var errorMessage: String?

    // MARK: - Initialization

    init(user: UserProfile = .sampleWithHoldings) {
        self.user = user
    }

    // MARK: - User Info

    /// Time-appropriate greeting
    var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12:  return "Good morning"
        case 12..<17: return "Good afternoon"
        case 17..<21: return "Good evening"
        default:      return "Good night"
        }
    }

    /// Full greeting with user's name
    var personalizedGreeting: String {
        "\(greeting), \(user.displayName)"
    }

    // MARK: - Portfolio Value Calculations

    /// Total portfolio value
    var totalPortfolioValue: Double {
        user.totalPortfolioValue
    }

    /// Total daily change in dollars
    var totalDailyChange: Double {
        user.totalDailyChange
    }

    /// Total daily change as percentage
    var totalDailyChangePercent: Double {
        user.totalDailyChangePercent
    }

    /// Is the portfolio up today?
    var isPortfolioPositive: Bool {
        user.isPortfolioPositive
    }

    /// Formatted portfolio value
    var formattedPortfolioValue: String {
        user.formattedPortfolioValue
    }

    /// Formatted daily change with sign
    var formattedDailyChange: String {
        user.formattedDailyChange
    }

    /// Formatted daily change percentage
    var formattedDailyChangePercent: String {
        user.formattedDailyChangePercent
    }

    // MARK: - Holdings

    /// All stocks in the portfolio (only owned ones)
    var holdings: [Stock] {
        user.portfolio.filter { $0.sharesOwned > 0 }
    }

    /// Number of different holdings
    var holdingsCount: Int {
        holdings.count
    }

    /// Holdings grouped by zodiac element (for ZodiacWheelView)
    var holdingsByElement: [ZodiacSign.Element: [Stock]] {
        Dictionary(grouping: holdings) { $0.zodiacSign.element }
    }

    // MARK: - Element Breakdown

    /// Calculate the percentage breakdown by element
    var elementBreakdown: [ElementBreakdown] {
        let totalValue = totalPortfolioValue
        guard totalValue > 0 else {
            return ZodiacSign.Element.allCases.map {
                ElementBreakdown(element: $0, percentage: 0, value: 0)
            }
        }

        // Group holdings by element and sum values
        var elementValues: [ZodiacSign.Element: Double] = [:]
        for stock in holdings {
            let element = stock.zodiacSign.element
            elementValues[element, default: 0] += stock.totalValue
        }

        // Convert to breakdown structs
        return ZodiacSign.Element.allCases.map { element in
            let value = elementValues[element] ?? 0
            let percentage = (value / totalValue) * 100
            return ElementBreakdown(element: element, percentage: percentage, value: value)
        }.sorted { $0.percentage > $1.percentage }
    }

    /// The dominant element in the portfolio
    var dominantElement: ZodiacSign.Element? {
        elementBreakdown.first { $0.percentage > 0 }?.element
    }

    /// A one-line insight about the portfolio's elemental balance
    var elementInsight: String {
        guard let dominant = dominantElement else {
            return "Add some holdings to see your cosmic balance."
        }

        let breakdown = elementBreakdown
        let dominantPct = breakdown.first?.percentage ?? 0

        // Check for balance or imbalance
        if dominantPct > 60 {
            // Heavy concentration in one element
            switch dominant {
            case .fire:
                return "Heavy in Fire energy — high growth potential, high volatility. Bold moves ahead."
            case .earth:
                return "Grounded in Earth energy — stable and practical. Patience will be rewarded."
            case .air:
                return "Dominated by Air energy — intellectual picks, but watch for overthinking."
            case .water:
                return "Deep in Water energy — intuitive choices, but emotions may cloud judgment."
            }
        } else if dominantPct > 40 {
            // Moderate concentration
            switch dominant {
            case .fire:
                return "Fire leads your portfolio — growth-oriented with balanced risk."
            case .earth:
                return "Earth anchors your portfolio — solid foundation for steady gains."
            case .air:
                return "Air guides your portfolio — diversified and analytically chosen."
            case .water:
                return "Water flows through your portfolio — intuitive balance of risk and reward."
            }
        } else {
            // Well-balanced
            return "Elementally balanced — you're diversified across cosmic energies. The universe approves."
        }
    }

    // MARK: - Compatibility

    /// Get compatibility result for a stock with the user
    func compatibility(for stock: Stock) -> CompatibilityResult {
        user.compatibility(with: stock)
    }

    /// Average compatibility across the portfolio
    var averageCompatibility: Int {
        user.averagePortfolioCompatibility
    }

    // MARK: - Actions

    /// Refresh portfolio data
    func refreshPortfolio() async {
        isLoading = true
        errorMessage = nil

        // Simulate network delay
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds

        // In a real app, you'd fetch updated prices here
        isLoading = false
    }

    /// Add a stock to the portfolio
    func addStock(_ stock: Stock, shares: Double) {
        var stockWithShares = stock
        stockWithShares.sharesOwned = shares
        user.addStock(stockWithShares)
    }

    /// Remove a stock from the portfolio
    func removeStock(symbol: String) {
        user.removeStock(symbol: symbol)
    }
}

// MARK: - Element Breakdown Model

/// Represents one element's share of the portfolio
struct ElementBreakdown: Identifiable {
    let id = UUID()
    let element: ZodiacSign.Element
    let percentage: Double
    let value: Double

    /// Formatted percentage
    var formattedPercentage: String {
        String(format: "%.0f%%", percentage)
    }

    /// Formatted value
    var formattedValue: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "$0"
    }
}

// MARK: - Sample Data for Previews

extension UserProfile {

    /// A sample user with actual stock holdings for previews
    static var sampleWithHoldings: UserProfile {
        // Create a Leo user (August 15, 1990)
        var user = UserProfile(
            displayName: "Alex",
            email: "alex@cosmictrader.com",
            birthMonth: 8,
            birthDay: 15,
            birthYear: 1990,
            portfolio: [],
            memberSince: Calendar.current.date(byAdding: .month, value: -8, to: Date()) ?? Date()
        )

        // Add stocks from MockStockData with varying share amounts
        // Mix of different elements for interesting breakdown

        // Fire signs
        var apple = MockStockData.all.first { $0.symbol == "AAPL" }!
        apple.sharesOwned = 15
        user.addStock(apple)

        var ford = MockStockData.all.first { $0.symbol == "F" }!
        ford.sharesOwned = 50
        user.addStock(ford)

        // Earth signs
        var google = MockStockData.all.first { $0.symbol == "GOOGL" }!
        google.sharesOwned = 8
        user.addStock(google)

        var berkshire = MockStockData.all.first { $0.symbol == "BRK.B" }!
        berkshire.sharesOwned = 5
        user.addStock(berkshire)

        // Water signs
        var tesla = MockStockData.all.first { $0.symbol == "TSLA" }!
        tesla.sharesOwned = 10
        user.addStock(tesla)

        var amazon = MockStockData.all.first { $0.symbol == "AMZN" }!
        amazon.sharesOwned = 12
        user.addStock(amazon)

        // Air signs
        var nvidia = MockStockData.all.first { $0.symbol == "NVDA" }!
        nvidia.sharesOwned = 6
        user.addStock(nvidia)

        var meta = MockStockData.all.first { $0.symbol == "META" }!
        meta.sharesOwned = 4
        user.addStock(meta)

        return user
    }
}
