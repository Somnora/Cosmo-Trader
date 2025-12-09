import Foundation
import SwiftUI

/// PortfolioViewModel
/// ------------------
/// The "brain" for the Portfolio tab.
///
/// WHY DO WE NEED THIS?
/// Views should ONLY handle displaying things. They shouldn't:
/// - Fetch data from servers
/// - Calculate totals
/// - Format numbers
///
/// That's the ViewModel's job! It takes raw data and prepares it for display.
///
/// THE @Observable MACRO:
/// This tells SwiftUI "watch this class for changes!"
/// When any property changes, SwiftUI automatically updates the UI.
/// (In older code, you might see @ObservableObject instead)

@Observable
class PortfolioViewModel {

    // MARK: - Published Properties

    /// The user's stocks - when this changes, the UI updates
    var stocks: [Stock] = Stock.samples

    /// Is data currently loading?
    var isLoading: Bool = false

    /// Any error message to display
    var errorMessage: String?

    // MARK: - Computed Properties

    /// Total portfolio value (sum of all stock values)
    var totalPortfolioValue: Double {
        stocks.reduce(0) { total, stock in
            total + stock.totalValue
        }
    }

    /// Total daily change across all stocks
    var totalDailyChange: Double {
        stocks.reduce(0) { total, stock in
            total + (stock.priceChange * stock.sharesOwned)
        }
    }

    /// Is the portfolio up today overall?
    var isPortfolioPositive: Bool {
        totalDailyChange >= 0
    }

    /// Formatted portfolio value (e.g., "$25,432.50")
    var formattedPortfolioValue: String {
        formatCurrency(totalPortfolioValue)
    }

    /// Formatted daily change with sign (e.g., "+$342.18")
    var formattedDailyChange: String {
        let sign = totalDailyChange >= 0 ? "+" : ""
        return sign + formatCurrency(totalDailyChange)
    }

    // MARK: - Methods

    /// Refresh stock data (would call API in real app)
    func refreshStocks() async {
        isLoading = true
        errorMessage = nil

        // Simulate network delay
        // In a real app, you'd fetch from an API here
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second

        // For now, just use sample data
        stocks = Stock.samples
        isLoading = false
    }

    // MARK: - Private Helpers

    /// Format a number as currency
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: value)) ?? "$0.00"
    }
}
