import Foundation
import SwiftUI

struct WatchlistCorrelationAlert: Identifiable, Codable, Equatable {
    let id: UUID
    let message: String
    let affectedSymbols: [String]
    let eventTitle: String
    let dateRangeText: String
    let sector: String

    init(
        id: UUID = UUID(),
        message: String,
        affectedSymbols: [String],
        eventTitle: String,
        dateRangeText: String,
        sector: String
    ) {
        self.id = id
        self.message = message
        self.affectedSymbols = affectedSymbols
        self.eventTitle = eventTitle
        self.dateRangeText = dateRangeText
        self.sector = sector
    }
}

@MainActor
final class WatchlistCorrelationService {
    static let shared = WatchlistCorrelationService()

    private init() {}

    func generateAlerts(
        watchlist: [String],
        events: [CosmicEvent],
        earnings: [EarningsEvent]
    ) -> [WatchlistCorrelationAlert] {
        guard !watchlist.isEmpty else { return [] }
        
        let calendar = Calendar.current
        let today = Date()
        guard let thirtyDaysOut = calendar.date(byAdding: .day, value: 30, to: today) else { return [] }
        
        // Filter upcoming/active cosmic events in the next 30 days
        let upcomingEvents = events.filter { event in
            event.endDate >= today && event.startDate <= thirtyDaysOut
        }
        
        var alerts: [WatchlistCorrelationAlert] = []
        
        for event in upcomingEvents {
            // Check watchlist stocks reporting earnings during this event's window (+/- 2 days buffer)
            let bufferStart = calendar.startOfDay(for: calendar.date(byAdding: .day, value: -2, to: event.startDate) ?? event.startDate)
            let bufferEnd = calendar.startOfDay(for: calendar.date(byAdding: .day, value: 2, to: event.endDate) ?? event.endDate)
            
            // Find watchlist stocks that have earnings in this window
            let reportingWatchlistStocks = earnings.filter { earning in
                watchlist.contains(earning.symbol) &&
                earning.reportDate >= bufferStart &&
                earning.reportDate <= bufferEnd
            }
            
            guard !reportingWatchlistStocks.isEmpty else { continue }
            
            // Group by sector
            let groupedBySector = Dictionary(grouping: reportingWatchlistStocks) { earning -> String in
                // Resolve stock sector
                let stock = MockStockData.knownStocks.first { $0.symbol.uppercased() == earning.symbol.uppercased() }
                return stock?.sector ?? "Other"
            }
            
            var matchedSectors: Set<String> = []
            
            // Generate alerts for sectors with multiple reporting stocks
            for (sector, sectorEarnings) in groupedBySector {
                if sectorEarnings.count >= 2 {
                    let symbols = sectorEarnings.map(\.symbol).sorted()
                    let sectorAdjective = mapSectorToAdjective(sector)
                    let message = "\(symbols.count) of your watchlisted \(sectorAdjective) stocks have earnings during the upcoming \(event.title) \(event.subtitle)."
                    
                    alerts.append(WatchlistCorrelationAlert(
                        message: message,
                        affectedSymbols: symbols,
                        eventTitle: event.title,
                        dateRangeText: event.dateRangeFormatted,
                        sector: sector
                    ))
                    matchedSectors.insert(sector)
                }
            }
            
            // Fallback: if total reporting stocks >= 3 across different sectors, and no single sector alert was generated
            if reportingWatchlistStocks.count >= 3 && !alerts.contains(where: { $0.eventTitle == event.title }) {
                let symbols = reportingWatchlistStocks.map(\.symbol).sorted()
                let message = "\(symbols.count) of your watchlisted stocks have earnings during the upcoming \(event.title) \(event.subtitle)."
                
                alerts.append(WatchlistCorrelationAlert(
                    message: message,
                    affectedSymbols: symbols,
                    eventTitle: event.title,
                    dateRangeText: event.dateRangeFormatted,
                    sector: "Mixed"
                ))
            }
        }
        
        return alerts
    }
    
    private func mapSectorToAdjective(_ sector: String) -> String {
        switch sector.lowercased() {
        case "technology": return "Tech"
        case "healthcare": return "Biotech"
        case "finance", "financial services": return "Financial"
        case "communication services": return "Communications"
        case "consumer discretionary", "consumer staples": return "Consumer"
        default: return sector.lowercased()
        }
    }
}
