import Foundation

// Safe array subscript. Lived in OLEDTerminalTheme.swift until the dead-theme
// purge; extracted because YahooFinanceService, CosmicTickerService, and
// CosmicTickerViews depend on it.
extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
