import Foundation

struct StockUpcomingCosmicEventsSummary: Equatable {
    let symbol: String
    let windowLabel: String
    let events: [StockUpcomingCosmicEventRow]
    let companySpecificStatus: String
    let hasCompanySpecificMetadata: Bool
    let footerText: String
}

struct StockUpcomingCosmicEventRow: Identifiable, Equatable {
    let id: String
    let kind: AstroOverlayEventKind
    let name: String
    let dateLabel: String
    let whyText: String
    let sourceLabel: String
    let iconSystemName: String
    let isRange: Bool
}

@MainActor
struct StockUpcomingCosmicEventsService {
    static let shared = StockUpcomingCosmicEventsService()

    private let calendar: Calendar

    init(calendar: Calendar = Calendar(identifier: .gregorian)) {
        self.calendar = calendar
    }

    func summary(
        for stock: Stock,
        startDate: Date = Date(),
        days: Int = 30
    ) -> StockUpcomingCosmicEventsSummary {
        let safeDays = max(1, days)
        let start = calendar.startOfDay(for: startDate)
        let end = calendar.date(byAdding: .day, value: safeDays, to: start) ?? start
        let supportsCompanyEvents = stock.supportsCompanyOverlayEvents && stock.foundedZodiacSign != nil

        var enabledKinds: Set<AstroOverlayEventKind> = [
            .fullMoon,
            .newMoon,
            .mercuryRetrograde
        ]

        if supportsCompanyEvents {
            enabledKinds.formUnion([
                .moonInSign,
                .companyBirthMonth,
                .companyFoundingAnniversary
            ])
        }

        let events = AstroOverlayEventService.shared.events(
            for: stock,
            from: start,
            to: end,
            filters: AstroOverlayFilterState(
                enabledKinds: enabledKinds,
                showEstimatedEvents: true,
                eventWindowDays: 3
            )
        )
        .filter { enabledKinds.contains($0.kind) }

        return StockUpcomingCosmicEventsSummary(
            symbol: stock.symbol,
            windowLabel: "Next \(safeDays) days",
            events: events.map { row(for: $0, stock: stock) },
            companySpecificStatus: supportsCompanyEvents
                ? "Company-specific calendar uses verified founding metadata."
                : "Company-specific events unavailable until verified founding metadata exists.",
            hasCompanySpecificMetadata: supportsCompanyEvents,
            footerText: "Calendar context only. No market or return claims. Historical and entertainment lens, not predictive and not financial advice."
        )
    }

    private func row(for event: AstroOverlayEvent, stock: Stock) -> StockUpcomingCosmicEventRow {
        StockUpcomingCosmicEventRow(
            id: event.id,
            kind: event.kind,
            name: event.title,
            dateLabel: dateLabel(for: event),
            whyText: whyText(for: event, stock: stock),
            sourceLabel: sourceLabel(for: event),
            iconSystemName: event.iconSystemName,
            isRange: event.isRange
        )
    }

    private func dateLabel(for event: AstroOverlayEvent) -> String {
        if event.isRange, let endDate = event.endDate {
            return "\(DateFormatter.astroOverlayMonthDay.string(from: event.startDate))-\(DateFormatter.astroOverlayMonthDay.string(from: endDate))"
        }
        return DateFormatter.astroOverlayMonthDay.string(from: event.markerDate)
    }

    private func whyText(for event: AstroOverlayEvent, stock: Stock) -> String {
        switch event.kind {
        case .fullMoon:
            return "Broad lunar phase in the calendar window."
        case .newMoon:
            return "Broad lunar phase in the calendar window."
        case .mercuryRetrograde:
            return "Broad Mercury retrograde calendar window."
        case .moonInSign:
            return "Moon passes through \(stock.symbol)'s verified company sign."
        case .companyBirthMonth:
            return "Uses \(stock.symbol)'s verified founding month."
        case .companyFoundingAnniversary:
            return "Uses \(stock.symbol)'s verified founding date."
        case .firstQuarter, .lastQuarter, .eclipse, .planetaryIngress:
            return "Calendar context from the selected astro event set."
        }
    }

    private func sourceLabel(for event: AstroOverlayEvent) -> String {
        switch event.source {
        case .calculatedMoonPhase:
            return "Calculated moon phase"
        case .calculatedMoonSign:
            return "Calculated moon sign + company metadata"
        case .verifiedEphemeris:
            return "Verified ephemeris"
        case .companyFoundedDate:
            return "Verified founding metadata"
        case .curatedDataset:
            return event.isEstimated ? "Curated ephemeris estimate" : "Curated ephemeris"
        }
    }
}
