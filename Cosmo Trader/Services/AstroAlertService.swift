import Foundation
import SwiftUI

// MARK: - AstroAlertService
// =========================
// Manages cosmic events and provides alerts for the app.
//
// Responsibilities:
// - Track all cosmic events
// - Return active events
// - Return upcoming events (7 days, 30 days)
// - Check if stocks/elements are affected
// - Generate alert banners for important events
//
// Uses a singleton pattern for easy access across the app.

@Observable
class AstroAlertService {

    // MARK: - Singleton

    static let shared = AstroAlertService()

    // MARK: - Properties

    /// All cosmic events
    private(set) var allEvents: [CosmicEvent]

    /// Dismissed alert IDs (stored in UserDefaults)
    @ObservationIgnored
    private var dismissedAlertIds: Set<UUID> {
        get {
            let ids = UserDefaults.standard.array(forKey: "dismissedAstroAlerts") as? [String] ?? []
            return Set(ids.compactMap { UUID(uuidString: $0) })
        }
        set {
            let ids = newValue.map { $0.uuidString }
            UserDefaults.standard.set(ids, forKey: "dismissedAstroAlerts")
        }
    }

    // MARK: - Initialization

    init() {
        self.allEvents = MockCosmicEvents.all
    }

    /// Initialize with custom events (for testing)
    init(events: [CosmicEvent]) {
        self.allEvents = events
    }

    // MARK: - Active Events

    /// Get all currently active events
    var activeEvents: [CosmicEvent] {
        allEvents.filter { $0.isActive }
    }

    /// Get the most significant active event (for banner display)
    var primaryActiveEvent: CosmicEvent? {
        activeEvents
            .filter { $0.type.isCautionEvent || $0.intensity == .intense }
            .sorted { $0.intensity.glowRadius > $1.intensity.glowRadius }
            .first
    }

    /// Get active events that should show as alerts
    var activeAlertEvents: [CosmicEvent] {
        activeEvents.filter { event in
            (event.type.isCautionEvent || event.intensity == .intense) &&
            !dismissedAlertIds.contains(event.id)
        }
    }

    /// Check if there's an active Mercury Retrograde
    var isMercuryRetrograde: Bool {
        activeEvents.contains { $0.type == .mercuryRetrograde }
    }

    /// Check if there's an active eclipse
    var hasActiveEclipse: Bool {
        activeEvents.contains { $0.type == .lunarEclipse || $0.type == .solarEclipse }
    }

    // MARK: - Upcoming Events

    /// Get events starting in the next N days
    func upcomingEvents(within days: Int) -> [CosmicEvent] {
        let calendar = Calendar.current
        let now = Date()
        guard let futureDate = calendar.date(byAdding: .day, value: days, to: now) else {
            return []
        }

        return allEvents
            .filter { event in
                // Not yet started and starts within the window
                event.startDate > now && event.startDate <= futureDate
            }
            .sorted { $0.startDate < $1.startDate }
    }

    /// Events in the next 7 days
    var eventsNext7Days: [CosmicEvent] {
        upcomingEvents(within: 7)
    }

    /// Events in the next 30 days
    var eventsNext30Days: [CosmicEvent] {
        upcomingEvents(within: 30)
    }

    /// Next upcoming event
    var nextEvent: CosmicEvent? {
        upcomingEvents(within: 365).first
    }

    // MARK: - Affected Checks

    /// Check if a zodiac element is affected by any active events
    func isElementAffected(_ element: ZodiacSign.Element) -> Bool {
        activeEvents.contains { event in
            event.affectedElements.contains(element)
        }
    }

    /// Get active events affecting a specific element
    func eventsAffecting(element: ZodiacSign.Element) -> [CosmicEvent] {
        activeEvents.filter { $0.affectedElements.contains(element) }
    }

    /// Check if a market sector is affected by any active events
    func isSectorAffected(_ sector: MarketSector) -> Bool {
        activeEvents.contains { event in
            event.affectedSectors.contains(sector)
        }
    }

    /// Get active events affecting a specific sector
    func eventsAffecting(sector: MarketSector) -> [CosmicEvent] {
        activeEvents.filter { $0.affectedSectors.contains(sector) }
    }

    /// Check if a stock's zodiac sign is affected by current events
    func isStockAffected(_ stock: Stock) -> Bool {
        guard let element = stock.element else { return false }
        return isElementAffected(element)
    }

    /// Get active events affecting a specific stock
    func eventsAffecting(stock: Stock) -> [CosmicEvent] {
        guard let element = stock.element else { return [] }
        return eventsAffecting(element: element)
    }

    /// Get cosmic caution level for a stock (0-100)
    func cautionLevel(for stock: Stock) -> Int {
        let affectingEvents = eventsAffecting(stock: stock)
        guard !affectingEvents.isEmpty else { return 0 }

        var level = 0
        for event in affectingEvents {
            switch event.intensity {
            case .mild: level += 15
            case .moderate: level += 30
            case .intense: level += 50
            }

            if event.type.isCautionEvent {
                level += 20
            }
        }

        return min(level, 100)
    }

    // MARK: - Alert Management

    /// Dismiss an alert (won't show again until reset)
    func dismissAlert(_ event: CosmicEvent) {
        dismissedAlertIds.insert(event.id)
    }

    /// Reset dismissed alerts (for testing or new cosmic cycle)
    func resetDismissedAlerts() {
        dismissedAlertIds.removeAll()
    }

    /// Check if an alert has been dismissed
    func isAlertDismissed(_ event: CosmicEvent) -> Bool {
        dismissedAlertIds.contains(event.id)
    }

    // MARK: - Calendar Helpers

    /// Group events by month
    func eventsByMonth() -> [String: [CosmicEvent]] {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"

        var grouped: [String: [CosmicEvent]] = [:]
        let futureEvents = allEvents.filter { $0.startDate >= Date() }

        for event in futureEvents {
            let monthKey = formatter.string(from: event.startDate)
            if grouped[monthKey] != nil {
                grouped[monthKey]?.append(event)
            } else {
                grouped[monthKey] = [event]
            }
        }

        return grouped
    }

    /// Get all events in a specific date range
    func events(from startDate: Date, to endDate: Date) -> [CosmicEvent] {
        allEvents.filter { event in
            // Event overlaps with the date range
            event.startDate <= endDate && event.endDate >= startDate
        }
    }

    // MARK: - Summary Generation

    /// Generate a cosmic weather summary for today
    var todaySummary: CosmicWeatherSummary {
        let active = activeEvents
        let upcoming = eventsNext7Days

        let severity: CosmicWeatherSummary.Severity
        let headline: String
        let advice: String

        if let retrograde = active.first(where: { $0.type == .mercuryRetrograde }) {
            severity = .caution
            headline = "Mercury Retrograde Active"
            advice = retrograde.advice
        } else if let eclipse = active.first(where: { $0.type == .lunarEclipse || $0.type == .solarEclipse }) {
            severity = .volatile
            headline = "Eclipse Energy Present"
            advice = eclipse.advice
        } else if active.contains(where: { $0.intensity == .intense }) {
            severity = .heightened
            headline = "Intense Cosmic Activity"
            advice = active.first(where: { $0.intensity == .intense })?.advice ?? "Stay alert to market astrology shifts."
        } else if !active.isEmpty {
            severity = .normal
            headline = "Moderate Cosmic Weather"
            advice = "Cosmic conditions are relatively calm. Proceed with awareness."
        } else {
            severity = .clear
            headline = "Quiet Cosmic Tape"
            advice = "No major cosmic events affecting markets. Let price action lead."
        }

        return CosmicWeatherSummary(
            severity: severity,
            headline: headline,
            advice: advice,
            activeEventCount: active.count,
            upcomingEventCount: upcoming.count,
            primaryEvent: primaryActiveEvent
        )
    }
}

// MARK: - Cosmic Weather Summary

struct CosmicWeatherSummary {
    let severity: Severity
    let headline: String
    let advice: String
    let activeEventCount: Int
    let upcomingEventCount: Int
    let primaryEvent: CosmicEvent?

    enum Severity: String {
        case clear = "Clear"
        case normal = "Normal"
        case heightened = "Heightened"
        case caution = "Caution"
        case volatile = "Volatile"

        var color: Color {
            switch self {
            case .clear: return .green
            case .normal: return .blue
            case .heightened: return .yellow
            case .caution: return .orange
            case .volatile: return .red
            }
        }

        var icon: String {
            switch self {
            case .clear: return "sun.max.fill"
            case .normal: return "cloud.sun.fill"
            case .heightened: return "cloud.fill"
            case .caution: return "exclamationmark.triangle.fill"
            case .volatile: return "bolt.fill"
            }
        }
    }
}

// MARK: - Preview Helpers

extension AstroAlertService {

    /// Preview instance with mock data
    static var preview: AstroAlertService {
        AstroAlertService()
    }

    /// Preview instance with no active events
    static var previewCalm: AstroAlertService {
        let calendar = Calendar.current
        _ = calendar.date(byAdding: .month, value: 2, to: Date())!
        let events = MockCosmicEvents.all.map { event in
            CosmicEvent(
                id: event.id,
                type: event.type,
                title: event.title,
                subtitle: event.subtitle,
                description: event.description,
                advice: event.advice,
                warningMessage: event.warningMessage,
                startDate: calendar.date(byAdding: .month, value: 2, to: event.startDate)!,
                endDate: calendar.date(byAdding: .month, value: 2, to: event.endDate)!,
                intensity: event.intensity,
                affectedElements: event.affectedElements,
                affectedSectors: event.affectedSectors
            )
        }
        return AstroAlertService(events: events)
    }
}
