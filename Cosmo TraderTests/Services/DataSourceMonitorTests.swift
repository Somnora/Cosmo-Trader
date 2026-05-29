import Foundation
import Testing
@testable import Cosmo_Trader

@MainActor
struct DataSourceMonitorTests {

    @Test("Offline state takes precedence over key and response status")
    func offlineStateTakesPrecedence() {
        let now = date("2026-05-27T12:00:00Z")
        let lastUpdated = date("2026-05-27T11:59:30Z")

        let withoutKey = DataSourceMonitor.resolveSource(
            isOnline: false,
            hasValidFinnhubKey: false,
            mostRecentSuccessfulResponseAt: nil,
            now: now,
            liveWindow: 60
        )
        let withRecentResponse = DataSourceMonitor.resolveSource(
            isOnline: false,
            hasValidFinnhubKey: true,
            mostRecentSuccessfulResponseAt: lastUpdated,
            now: now,
            liveWindow: 60
        )

        #expect(withoutKey == .offline)
        #expect(withRecentResponse == .offline)
    }

    @Test("Missing Finnhub key reports sample data")
    func missingFinnhubKeyReportsSampleData() {
        let now = date("2026-05-27T12:00:00Z")
        let lastUpdated = date("2026-05-27T11:59:30Z")

        let source = DataSourceMonitor.resolveSource(
            isOnline: true,
            hasValidFinnhubKey: false,
            mostRecentSuccessfulResponseAt: lastUpdated,
            now: now,
            liveWindow: 60
        )

        #expect(source == .sample)
    }

    @Test("Valid key without successful response reports sample data")
    func validKeyWithoutSuccessfulResponseReportsSampleData() {
        let source = DataSourceMonitor.resolveSource(
            isOnline: true,
            hasValidFinnhubKey: true,
            mostRecentSuccessfulResponseAt: nil,
            now: date("2026-05-27T12:00:00Z"),
            liveWindow: 60
        )

        #expect(source == .sample)
    }

    @Test("Recent successful response reports live data")
    func recentSuccessfulResponseReportsLiveData() {
        let now = date("2026-05-27T12:00:00Z")
        let lastUpdated = date("2026-05-27T11:59:30Z")

        let source = DataSourceMonitor.resolveSource(
            isOnline: true,
            hasValidFinnhubKey: true,
            mostRecentSuccessfulResponseAt: lastUpdated,
            now: now,
            liveWindow: 60
        )

        #expect(source == .live)
    }

    @Test("Older successful response reports cached data with timestamp")
    func olderSuccessfulResponseReportsCachedData() {
        let now = date("2026-05-27T12:00:00Z")
        let lastUpdated = date("2026-05-27T11:58:30Z")

        let source = DataSourceMonitor.resolveSource(
            isOnline: true,
            hasValidFinnhubKey: true,
            mostRecentSuccessfulResponseAt: lastUpdated,
            now: now,
            liveWindow: 60
        )

        #expect(source == .cached(lastUpdated: lastUpdated))
    }

    private func date(_ value: String) -> Date {
        let formatter = ISO8601DateFormatter()
        return formatter.date(from: value) ?? Date(timeIntervalSince1970: 0)
    }
}
