import Foundation
import Testing
@testable import Cosmo_Trader

@MainActor
struct ActiveCosmicDriverSnapshotTests {

    private let filterState = AstroOverlayFilterState(
        enabledKinds: [.fullMoon, .newMoon, .mercuryRetrograde],
        showEstimatedEvents: true,
        eventWindowDays: 3
    )

    // MARK: - Point-event windows (moon markers)

    @Test("A moon marker is active from the day before the marker")
    func pointEventActiveFromDayBeforeMarker() {
        let marker = localMidnight("2026-07-06")
        let events = [moonMarker(on: marker)]

        #expect(activeKinds(at: addingDays(-1, to: marker), events: events) == [.fullMoon])
        #expect(activeKinds(at: marker, events: events) == [.fullMoon])
        #expect(activeKinds(at: marker.addingTimeInterval(9.5 * 3_600), events: events) == [.fullMoon])
    }

    @Test("A moon marker stays active through markerDate plus the event window")
    func pointEventActiveThroughEventWindow() {
        let marker = localMidnight("2026-07-06")
        let events = [moonMarker(on: marker)]

        // eventWindowDays is 3, so the window closes at markerDate + 3 days.
        #expect(activeKinds(at: addingDays(2, to: marker), events: events) == [.fullMoon])
        #expect(activeKinds(at: addingDays(3, to: marker), events: events) == [.fullMoon])
    }

    @Test("A moon marker is inactive one day past the event window")
    func pointEventInactivePastEventWindow() {
        let marker = localMidnight("2026-07-06")
        let events = [moonMarker(on: marker)]

        #expect(activeKinds(at: addingDays(4, to: marker), events: events).isEmpty)
        #expect(activeKinds(at: addingDays(3, to: marker).addingTimeInterval(1), events: events).isEmpty)
        #expect(activeKinds(at: addingDays(-1, to: marker).addingTimeInterval(-1), events: events).isEmpty)
    }

    @Test("A filter state with a wider event window widens the active span")
    func pointEventWindowFollowsFilterState() {
        let marker = localMidnight("2026-07-06")
        let events = [moonMarker(on: marker)]
        let wide = AstroOverlayFilterState(
            enabledKinds: filterState.enabledKinds,
            showEstimatedEvents: true,
            eventWindowDays: 5
        )

        let snapshot = ActiveCosmicDriverSnapshot.make(
            date: addingDays(5, to: marker),
            candidateEvents: events,
            filterState: wide
        )
        #expect(snapshot.activeKinds == [.fullMoon])
        #expect(activeKinds(at: addingDays(5, to: marker), events: events).isEmpty)
    }

    // MARK: - Range-event windows (Mercury retrograde)

    @Test("Mercury retrograde range endpoints are inclusive")
    func mercuryRangeEndpointsAreInclusive() throws {
        let event = try #require(
            MercuryRetrogradeEphemerisProvider.shared
                .events(from: utcDate("2026-06-01"), to: utcDate("2026-08-01"))
                .first
        )
        let endDate = try #require(event.endDate)

        #expect(activeKinds(at: event.startDate, events: [event]) == [.mercuryRetrograde])
        #expect(activeKinds(at: endDate, events: [event]) == [.mercuryRetrograde])
        #expect(activeKinds(at: event.startDate.addingTimeInterval(-1), events: [event]).isEmpty)
        #expect(activeKinds(at: endDate.addingTimeInterval(1), events: [event]).isEmpty)
    }

    @Test("A date inside the retrograde window is active, a date outside is not")
    func mercuryRangeCoversItsInterior() throws {
        let event = try #require(
            MercuryRetrogradeEphemerisProvider.shared
                .events(from: utcDate("2026-06-01"), to: utcDate("2026-08-01"))
                .first
        )

        #expect(activeKinds(at: utcDate("2026-07-10"), events: [event]) == [.mercuryRetrograde])
        #expect(activeKinds(at: utcDate("2026-08-01"), events: [event]).isEmpty)
    }

    @Test("Active events carry the events themselves, not just their kinds")
    func snapshotCarriesActiveEvents() {
        let marker = localMidnight("2026-07-06")
        let active = moonMarker(on: marker)
        let dormant = moonMarker(on: addingDays(-20, to: marker), kind: .newMoon)

        let snapshot = ActiveCosmicDriverSnapshot.make(
            date: marker,
            candidateEvents: [dormant, active],
            filterState: filterState
        )

        #expect(snapshot.date == marker)
        #expect(snapshot.activeKinds == [.fullMoon])
        #expect(snapshot.activeEvents.map(\.id) == [active.id])
    }

    // MARK: - Lookback range

    @Test("The lookback clears a full lunation")
    func queryIntervalClearsAFullLunation() {
        let date = utcDate("2026-07-06")
        let interval = ActiveCosmicDriverSnapshot.queryInterval(around: date)
        let calendar = Calendar.current

        #expect(calendar.dateComponents([.day], from: interval.start, to: date).day == 35)
        #expect(calendar.dateComponents([.day], from: date, to: interval.end).day == 2)
        // A 29.53-day synodic month has to fit inside the lookback, or the
        // marker that owns today's window can fall outside the query.
        #expect(Double(ActiveCosmicDriverSnapshot.lookbackDays) > 29.53)
    }

    @Test("The lookback query reproduces a year-long scan's active drivers")
    func lookbackMatchesYearLongScan() {
        // The correlation statistics were computed from a year-long event
        // scan. The snapshot must agree with that scan on every day of a
        // lunation, or claims cite markers the statistics never saw.
        for offset in 0..<35 {
            let date = addingDays(offset, to: localMidnight("2026-05-01"))
                .addingTimeInterval(9.5 * 3_600)

            let lookback = ActiveCosmicDriverSnapshot.queryInterval(around: date)
            let fromLookback = activeKinds(
                at: date,
                events: overlayEvents(from: lookback.start, to: lookback.end)
            )
            let fromYearScan = activeKinds(
                at: date,
                events: overlayEvents(from: addingDays(-365, to: date), to: lookback.end)
            )

            #expect(fromLookback == fromYearScan, "Disagreed on day offset \(offset)")
        }
    }

    @Test("A one-day lookback disagrees with the year-long scan")
    func shortLookbackDisagreesWithYearLongScan() {
        // Justifies the 35 days: moon markers are emitted on phase
        // transitions, so a scan that starts yesterday invents a marker on its
        // own first day and reports a driver that a full scan places days
        // earlier, outside today's window.
        var disagreements = 0

        for offset in 0..<35 {
            let date = addingDays(offset, to: localMidnight("2026-05-01"))
                .addingTimeInterval(9.5 * 3_600)

            let lookback = ActiveCosmicDriverSnapshot.queryInterval(around: date)
            let fromYearScan = activeKinds(
                at: date,
                events: overlayEvents(from: addingDays(-365, to: date), to: lookback.end)
            )
            let fromShortScan = activeKinds(
                at: date,
                events: overlayEvents(from: addingDays(-1, to: date), to: lookback.end)
            )

            if fromShortScan != fromYearScan {
                disagreements += 1
            }
        }

        #expect(disagreements > 0)
    }

    // MARK: - Fixtures

    private func activeKinds(at date: Date, events: [AstroOverlayEvent]) -> Set<AstroOverlayEventKind> {
        ActiveCosmicDriverSnapshot.make(
            date: date,
            candidateEvents: events,
            filterState: filterState
        ).activeKinds
    }

    private func overlayEvents(from startDate: Date, to endDate: Date) -> [AstroOverlayEvent] {
        AstroOverlayEventService.shared.events(
            for: MarketWeatherService.marketProxyStock,
            from: startDate,
            to: endDate,
            filters: filterState
        )
    }

    private func moonMarker(
        on markerDate: Date,
        kind: AstroOverlayEventKind = .fullMoon
    ) -> AstroOverlayEvent {
        AstroOverlayEvent(
            id: "moon-\(kind.rawValue)-\(markerDate.timeIntervalSince1970)",
            kind: kind,
            title: kind.displayName,
            subtitle: nil,
            startDate: markerDate,
            endDate: nil,
            markerDate: markerDate,
            intensity: .high,
            affectedElements: [],
            affectedSectors: [],
            iconSystemName: kind.iconSystemName,
            source: .calculatedMoonPhase,
            isEstimated: false
        )
    }

    private func addingDays(_ days: Int, to date: Date) -> Date {
        Calendar.current.date(byAdding: .day, value: days, to: date) ?? date
    }

    /// Local midnight, matching how `AstroOverlayEventService` stamps moon
    /// markers (`Calendar.current.startOfDay`).
    private func localMidnight(_ value: String) -> Date {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = Calendar.current.timeZone
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: value) ?? Date(timeIntervalSince1970: 0)
    }

    /// UTC midnight, matching how the Mercury ephemeris table parses its dates.
    private func utcDate(_ value: String) -> Date {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: value) ?? Date(timeIntervalSince1970: 0)
    }
}
