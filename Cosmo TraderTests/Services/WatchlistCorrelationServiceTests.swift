import Foundation
import Testing
@testable import Cosmo_Trader

@MainActor
struct WatchlistCorrelationServiceTests {
    
    @Test("Empty watchlist returns no alerts")
    func emptyWatchlistReturnsNoAlerts() {
        let event = mockEvent(
            title: "Full Moon",
            subtitle: "in Scorpio",
            startDate: date("2026-06-20"),
            endDate: date("2026-06-20")
        )
        let earning = mockEarnings(
            symbol: "AAPL",
            reportDate: date("2026-06-20")
        )
        
        let alerts = WatchlistCorrelationService.shared.generateAlerts(
            watchlist: [],
            events: [event],
            earnings: [earning],
            now: date("2026-06-18")
        )
        
        #expect(alerts.isEmpty)
    }
    
    @Test("Sector specific alert triggers when >= 2 stocks in the same sector have earnings overlapping a cosmic event")
    func sectorSpecificAlertForOverlappingEarnings() {
        let event = mockEvent(
            title: "Mercury Retrograde",
            subtitle: "in Scorpio",
            startDate: date("2026-06-20"),
            endDate: date("2026-06-25")
        )
        // AAPL and MSFT are Technology sector stocks
        let earning1 = mockEarnings(
            symbol: "AAPL",
            reportDate: date("2026-06-21")
        )
        let earning2 = mockEarnings(
            symbol: "MSFT",
            reportDate: date("2026-06-24")
        )
        
        let alerts = WatchlistCorrelationService.shared.generateAlerts(
            watchlist: ["AAPL", "MSFT"],
            events: [event],
            earnings: [earning1, earning2],
            now: date("2026-06-18")
        )
        
        #expect(alerts.count == 1)
        let alert = alerts.first
        #expect(alert?.affectedSymbols == ["AAPL", "MSFT"])
        #expect(alert?.eventTitle == "Mercury Retrograde")
        #expect(alert?.sector == "Technology")
        #expect(alert?.message.contains("2 of your watchlisted Tech stocks") == true)
    }
    
    @Test("Fallback general alert triggers when >= 3 stocks across different sectors have earnings overlapping a cosmic event")
    func generalFallbackAlertForMultiSectorEarnings() {
        let event = mockEvent(
            title: "Solar Eclipse",
            subtitle: "in Cancer",
            startDate: date("2026-06-20"),
            endDate: date("2026-06-20")
        )
        // AAPL (Tech), JPM (Financial Services / Finance), and DIS (Other/Entertainment)
        let earning1 = mockEarnings(symbol: "AAPL", reportDate: date("2026-06-20"))
        let earning2 = mockEarnings(symbol: "JPM", reportDate: date("2026-06-20"))
        let earning3 = mockEarnings(symbol: "DIS", reportDate: date("2026-06-20"))
        
        let alerts = WatchlistCorrelationService.shared.generateAlerts(
            watchlist: ["AAPL", "JPM", "DIS"],
            events: [event],
            earnings: [earning1, earning2, earning3],
            now: date("2026-06-18")
        )
        
        #expect(alerts.count == 1)
        let alert = alerts.first
        #expect(alert?.affectedSymbols == ["AAPL", "DIS", "JPM"])
        #expect(alert?.eventTitle == "Solar Eclipse")
        #expect(alert?.sector == "Mixed")
        #expect(alert?.message.contains("3 of your watchlisted stocks have earnings") == true)
    }
    
    @Test("Earnings reports outside the event window (with +/- 2 days buffer) do not trigger alerts")
    func earningsOutsideWindowDoNotTriggerAlerts() {
        let event = mockEvent(
            title: "New Moon",
            subtitle: "in Leo",
            startDate: date("2026-06-20"),
            endDate: date("2026-06-20")
        )
        // Window is 2026-06-18 to 2026-06-22
        let earning1 = mockEarnings(symbol: "AAPL", reportDate: date("2026-06-17")) // Outside before
        let earning2 = mockEarnings(symbol: "MSFT", reportDate: date("2026-06-23")) // Outside after
        
        let alerts = WatchlistCorrelationService.shared.generateAlerts(
            watchlist: ["AAPL", "MSFT"],
            events: [event],
            earnings: [earning1, earning2],
            now: date("2026-06-18")
        )
        
        #expect(alerts.isEmpty)
    }
    
    @Test("Cosmic events outside 30 days range are ignored")
    func eventsOutsideThirtyDaysAreIgnored() {
        let calendar = Calendar.current
        let today = Date()
        guard let fortyDaysOut = calendar.date(byAdding: .day, value: 40, to: today) else { return }
        
        let event = mockEvent(
            title: "Future Eclipse",
            subtitle: "",
            startDate: fortyDaysOut,
            endDate: fortyDaysOut
        )
        let earning1 = mockEarnings(symbol: "AAPL", reportDate: fortyDaysOut)
        let earning2 = mockEarnings(symbol: "MSFT", reportDate: fortyDaysOut)
        
        let alerts = WatchlistCorrelationService.shared.generateAlerts(
            watchlist: ["AAPL", "MSFT"],
            events: [event],
            earnings: [earning1, earning2],
            now: date("2026-06-18")
        )
        
        #expect(alerts.isEmpty)
    }
    
    // MARK: - Helpers
    
    private func date(_ value: String) -> Date {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: value) ?? Date(timeIntervalSince1970: 0)
    }
    
    private func mockEvent(
        title: String,
        subtitle: String,
        startDate: Date,
        endDate: Date
    ) -> CosmicEvent {
        CosmicEvent(
            type: .fullMoon,
            title: title,
            subtitle: subtitle,
            description: "Test description",
            advice: "Test advice",
            startDate: startDate,
            endDate: endDate,
            intensity: .moderate,
            affectedElements: [],
            affectedSectors: []
        )
    }
    
    private func mockEarnings(symbol: String, reportDate: Date) -> EarningsEvent {
        EarningsEvent(
            id: UUID(),
            symbol: symbol,
            companyName: "Test Company",
            reportDate: reportDate,
            timing: .beforeMarket,
            consensusEPS: 1.00,
            previousEPS: 0.90,
            fiscalQuarter: "Q2",
            fiscalYear: 2026
        )
    }
}
