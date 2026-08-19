import Foundation
import Testing
@testable import Cosmo_Trader

struct MercuryNotificationScheduleTests {

    @Test("Windows are found for a date years past the retired hardcoded table")
    func windowsExistWellPastTheOldHardcodedTable() {
        // The regression this file exists for. The scheduler used to carry its
        // own list of 2025 windows, so from January 2026 onward it produced
        // nothing at all and the feature failed silently. Any date the curated
        // dataset covers must yield work to do.
        let windows = NotificationService.upcomingRetrogradeWindows(from: date("2026-08-18"))

        #expect(!windows.isEmpty)
        #expect(windows.allSatisfy { $0.endDate > date("2026-08-18") })
    }

    @Test("Windows already finished are never scheduled")
    func finishedWindowsAreExcluded() {
        let now = date("2027-01-01")
        let windows = NotificationService.upcomingRetrogradeWindows(from: now)

        #expect(!windows.isEmpty)
        #expect(windows.allSatisfy { $0.endDate > now })
    }

    @Test("Windows come back in order and within the pending-request budget")
    func windowsAreOrderedAndBounded() {
        let windows = NotificationService.upcomingRetrogradeWindows(from: date("2026-01-01"))

        #expect(windows.count <= 4)
        #expect(windows == windows.sorted { $0.startDate < $1.startDate })
    }

    @Test("Notification bodies state the window and assure nothing")
    func bodiesStateTheWindowWithoutAssurance() {
        guard let window = NotificationService.upcomingRetrogradeWindows(from: date("2026-08-18")).first else {
            Issue.record("Expected at least one upcoming retrograde window")
            return
        }

        let begins = NotificationService.retrogradeBeginsBody(for: window)
        let ends = NotificationService.retrogradeEndsBody(for: window)

        #expect(begins.contains("Mercury turns retrograde today"))
        #expect(ends.contains("Mercury stations direct today"))
        // The retired copy promised a reader that a legal commitment was safe,
        // on astrological grounds, from a lock screen.
        #expect(!begins.localizedCaseInsensitiveContains("safe to sign"))
        #expect(!ends.localizedCaseInsensitiveContains("safe to sign"))
    }

    @Test("Both bodies clear the compliance scanner")
    func bodiesAreComplianceSafe() {
        let windows = NotificationService.upcomingRetrogradeWindows(from: date("2026-08-18"))

        for window in windows {
            for body in [
                NotificationService.retrogradeBeginsBody(for: window),
                NotificationService.retrogradeEndsBody(for: window)
            ] {
                #expect(!body.localizedCaseInsensitiveContains("buy"))
                #expect(!body.localizedCaseInsensitiveContains("sell"))
                #expect(!body.localizedCaseInsensitiveContains("position"))
            }
        }
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
