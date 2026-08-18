import Foundation

/// Which cosmic drivers are actually occurring right now
/// (specs/prediction-ledger-mvp.md: the market claim is the best summary
/// "among active events").
///
/// The correlation summaries describe a full year of history, so on their own
/// they say nothing about today. Without this join a Full Moon claim records
/// on every trading day and gets scored against that day's return — the label
/// says "Full Moon" while the measurement is "is SPY up on a random Tuesday."
///
/// Two rules keep this honest:
/// - Events come from `AstroOverlayEventService` + the Mercury ephemeris, the
///   same generator that produced the historical event set the statistics
///   were computed from. Never from `AstroAlertService`, whose mock events are
///   dated relative to `Date()` and are therefore permanently "active".
/// - Activeness uses `AstroCorrelationService.priceWindow(for:filterState:calendar:)`,
///   the same window the historical sample drew candles from.
struct ActiveCosmicDriverSnapshot: Equatable {
    let date: Date
    let activeKinds: Set<AstroOverlayEventKind>
    let activeEvents: [AstroOverlayEvent]

    /// Moon markers are emitted only on phase transitions, so the marker whose
    /// window covers today may sit up to a full lunation back. 35 days clears
    /// one 29.5-day cycle with room for the window itself.
    static let lookbackDays = 35
    /// A short lookahead so a marker generated for tomorrow still contributes
    /// its `markerDate - 1` day.
    static let lookaheadDays = 2

    /// The single event query that feeds `make(date:candidateEvents:...)`.
    static func queryInterval(around date: Date, calendar: Calendar = .current) -> DateInterval {
        let start = calendar.date(byAdding: .day, value: -lookbackDays, to: date) ?? date
        let end = calendar.date(byAdding: .day, value: lookaheadDays, to: date) ?? date
        return DateInterval(start: start, end: end)
    }

    /// Keeps the events whose correlation window contains `date`.
    static func make(
        date: Date,
        candidateEvents: [AstroOverlayEvent],
        filterState: AstroOverlayFilterState,
        calendar: Calendar = .current
    ) -> ActiveCosmicDriverSnapshot {
        let active = candidateEvents.filter { event in
            AstroCorrelationService.priceWindow(
                for: event,
                filterState: filterState,
                calendar: calendar
            ).contains(date)
        }

        return ActiveCosmicDriverSnapshot(
            date: date,
            activeKinds: Set(active.map(\.kind)),
            activeEvents: active
        )
    }
}
