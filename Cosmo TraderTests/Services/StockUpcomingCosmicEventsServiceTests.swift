import Foundation
import Testing
@testable import Cosmo_Trader

@MainActor
struct StockUpcomingCosmicEventsServiceTests {

    @Test("Upcoming events are generated for future date ranges")
    func upcomingEventsGenerateForFutureDateRanges() {
        let summary = StockUpcomingCosmicEventsService.shared.summary(
            for: knownStock(),
            startDate: date("2026-06-14")
        )

        #expect(summary.windowLabel == "Next 30 days")
        #expect(!summary.events.isEmpty)
        #expect(summary.events.contains { $0.kind == .fullMoon || $0.kind == .newMoon || $0.kind == .mercuryRetrograde })
        #expect(summary.events.allSatisfy { !$0.name.isEmpty && !$0.dateLabel.isEmpty && !$0.sourceLabel.isEmpty })
    }

    @Test("Company-specific events require verified founding metadata")
    func companySpecificEventsRequireVerifiedFoundingMetadata() {
        let known = StockUpcomingCosmicEventsService.shared.summary(
            for: knownStock(),
            startDate: date("2026-03-20")
        )
        let unknown = StockUpcomingCosmicEventsService.shared.summary(
            for: unknownStock(),
            startDate: date("2026-03-20")
        )

        #expect(known.hasCompanySpecificMetadata)
        #expect(known.events.contains { $0.kind == .companyFoundingAnniversary || $0.kind == .companyBirthMonth })
        #expect(!unknown.hasCompanySpecificMetadata)
        #expect(unknown.companySpecificStatus.localizedCaseInsensitiveContains("unavailable"))
        #expect(!unknown.events.contains { companySpecificKinds.contains($0.kind) })
    }

    @Test("Unknown-founded stocks still show broad cosmic events")
    func unknownFoundedStocksStillShowBroadEvents() {
        let summary = StockUpcomingCosmicEventsService.shared.summary(
            for: unknownStock(),
            startDate: date("2026-06-14")
        )

        #expect(!summary.events.isEmpty)
        #expect(summary.events.contains { $0.kind == .mercuryRetrograde || $0.kind == .fullMoon || $0.kind == .newMoon })
        #expect(summary.events.allSatisfy { !companySpecificKinds.contains($0.kind) })
    }

    @Test("Mercury Retrograde renders as a range")
    func mercuryRetrogradeRendersAsRange() {
        let summary = StockUpcomingCosmicEventsService.shared.summary(
            for: knownStock(),
            startDate: date("2026-06-14")
        )
        let mercury = summary.events.first { $0.kind == .mercuryRetrograde }

        #expect(mercury?.isRange == true)
        #expect(mercury?.dateLabel.contains("-") == true)
        #expect(mercury?.sourceLabel.localizedCaseInsensitiveContains("ephemeris") == true)
    }

    @Test("Section renders without price or history data")
    func sectionRendersWithoutPriceOrHistoryData() {
        let noHistoryStock = Stock(
            symbol: "NOH",
            name: "No History Corp.",
            currentPrice: 0,
            priceChange: 0,
            percentageChange: 0,
            foundedDate: nil,
            sector: "Unknown"
        )
        let summary = StockUpcomingCosmicEventsService.shared.summary(
            for: noHistoryStock,
            startDate: date("2026-06-14")
        )
        let view = StockUpcomingCosmicEventsView(summary: summary)

        _ = view.body
        #expect(!summary.events.isEmpty)
        #expect(summary.footerText.localizedCaseInsensitiveContains("No market or return claims"))
    }

    @Test("Upcoming event copy does not include trading action language")
    func upcomingEventCopyDoesNotIncludeTradingActionLanguage() {
        let summary = StockUpcomingCosmicEventsService.shared.summary(
            for: knownStock(),
            startDate: date("2026-06-14")
        )
        let copy = ([summary.companySpecificStatus, summary.footerText] + summary.events.flatMap {
            [$0.name, $0.dateLabel, $0.whyText, $0.sourceLabel]
        }).joined(separator: " ")

        for blocked in ["buy", "sell", "hold", "reduce", "avoid", "expected upside", "expected downside"] {
            #expect(copy.range(of: "\\b\(blocked)\\b", options: [.regularExpression, .caseInsensitive]) == nil)
        }
    }

    private var companySpecificKinds: Set<AstroOverlayEventKind> {
        [.moonInSign, .companyBirthMonth, .companyFoundingAnniversary]
    }

    private func knownStock() -> Stock {
        Stock(
            symbol: "AAPL",
            name: "Apple Inc.",
            currentPrice: 180,
            priceChange: 1,
            percentageChange: 0.5,
            foundedMonth: 4,
            foundedDay: 1,
            foundedYear: 1976,
            sector: "Technology"
        )
    }

    private func unknownStock() -> Stock {
        Stock(
            symbol: "ZZZZ",
            name: "Unknown Listing",
            currentPrice: 0,
            priceChange: 0,
            percentageChange: 0,
            foundedDate: nil,
            sector: "Unknown"
        )
    }

    private func date(_ value: String) -> Date {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: value) ?? Date(timeIntervalSince1970: 0)
    }
}
