import Foundation
import Testing
@testable import Cosmo_Trader

@MainActor
struct PredictionLedgerStoreTests {

    @Test("Ledger round-trips records through disk")
    func ledgerRoundTripsRecords() throws {
        let directoryURL = temporaryDirectoryURL()
        let store = PredictionLedgerStore(directoryURL: directoryURL)
        defer { try? store.removeAll() }

        let record = record(tradingDay: "2026-07-06", claims: [marketClaim()])
        #expect(store.insert(record))

        // A fresh instance over the same directory must read the same ledger.
        let reloaded = PredictionLedgerStore(directoryURL: directoryURL)
        #expect(reloaded.allRecords() == [record])
        #expect(reloaded.record(forTradingDay: "2026-07-06") == record)
    }

    @Test("Ledger keeps at most one record per trading day")
    func ledgerRejectsDuplicateTradingDay() throws {
        let store = PredictionLedgerStore(directoryURL: temporaryDirectoryURL())
        defer { try? store.removeAll() }

        let first = record(tradingDay: "2026-07-06", claims: [marketClaim()])
        let second = record(tradingDay: "2026-07-06", claims: [marketClaim(direction: .bearish)])

        #expect(store.insert(first))
        #expect(!store.insert(second))
        #expect(store.record(forTradingDay: "2026-07-06") == first)
    }

    @Test("First market-backed record upgrades a same-day no-call record")
    func marketBackedRecordUpgradesNoCall() throws {
        let store = PredictionLedgerStore(directoryURL: temporaryDirectoryURL())
        defer { try? store.removeAll() }

        let noCall = record(tradingDay: "2026-07-06", claims: [])
        let real = record(tradingDay: "2026-07-06", claims: [marketClaim()])

        #expect(store.insert(noCall))
        #expect(store.insert(real))
        #expect(store.record(forTradingDay: "2026-07-06") == real)
        #expect(store.allRecords().count == 1)
    }

    @Test("A record with claims is never downgraded to no-call")
    func claimsRecordIsNeverDowngraded() throws {
        let store = PredictionLedgerStore(directoryURL: temporaryDirectoryURL())
        defer { try? store.removeAll() }

        let real = record(tradingDay: "2026-07-06", claims: [marketClaim()])
        let noCall = record(tradingDay: "2026-07-06", claims: [])

        #expect(store.insert(real))
        #expect(!store.insert(noCall))
        #expect(store.record(forTradingDay: "2026-07-06") == real)
    }

    @Test("Outcome applies exactly once and alters nothing else")
    func outcomeAppliesExactlyOnce() throws {
        let store = PredictionLedgerStore(directoryURL: temporaryDirectoryURL())
        defer { try? store.removeAll() }

        let claim = marketClaim()
        let original = record(tradingDay: "2026-07-06", claims: [claim])
        store.insert(original)

        let outcome = PredictionOutcome(
            result: .hit,
            actualReturnPercent: 0.42,
            resolvedAt: date("2026-07-07"),
            provenance: .live(provider: "Yahoo Finance", fetchedAt: date("2026-07-07"))
        )
        #expect(store.applyOutcome(outcome, claimID: claim.id, tradingDay: "2026-07-06"))

        let resolved = try #require(store.record(forTradingDay: "2026-07-06"))
        let resolvedClaim = try #require(resolved.claims.first)
        #expect(resolvedClaim.outcome == outcome)
        #expect(resolved.isFullyResolved)

        // Everything except the outcome is untouched.
        #expect(resolvedClaim.id == claim.id)
        #expect(resolvedClaim.subject == claim.subject)
        #expect(resolvedClaim.direction == claim.direction)
        #expect(resolvedClaim.cosmicDriver == claim.cosmicDriver)
        #expect(resolvedClaim.historicalWinRate == claim.historicalWinRate)

        // A second outcome must be refused.
        let revision = PredictionOutcome(
            result: .miss,
            actualReturnPercent: -1.0,
            resolvedAt: date("2026-07-08"),
            provenance: .live(provider: "Yahoo Finance", fetchedAt: date("2026-07-08"))
        )
        #expect(!store.applyOutcome(revision, claimID: claim.id, tradingDay: "2026-07-06"))
        #expect(store.record(forTradingDay: "2026-07-06")?.claims.first?.outcome == outcome)
    }

    @Test("Outcome for an unknown claim or day is refused")
    func outcomeForUnknownTargetIsRefused() throws {
        let store = PredictionLedgerStore(directoryURL: temporaryDirectoryURL())
        defer { try? store.removeAll() }

        let claim = marketClaim()
        store.insert(record(tradingDay: "2026-07-06", claims: [claim]))

        let outcome = PredictionOutcome(
            result: .hit,
            actualReturnPercent: 0.5,
            resolvedAt: date("2026-07-07"),
            provenance: .live(provider: "Yahoo Finance", fetchedAt: date("2026-07-07"))
        )

        #expect(!store.applyOutcome(outcome, claimID: UUID(), tradingDay: "2026-07-06"))
        #expect(!store.applyOutcome(outcome, claimID: claim.id, tradingDay: "2026-07-05"))
        #expect(store.record(forTradingDay: "2026-07-06")?.isFullyResolved == false)
    }

    @Test("Pending records are unresolved days strictly before the given day")
    func pendingRecordsFilterAndSort() throws {
        let store = PredictionLedgerStore(directoryURL: temporaryDirectoryURL())
        defer { try? store.removeAll() }

        let unresolvedOld = record(tradingDay: "2026-07-01", claims: [marketClaim()])
        let resolvedClaim = marketClaim(outcome: PredictionOutcome(
            result: .hit,
            actualReturnPercent: 0.3,
            resolvedAt: date("2026-07-03"),
            provenance: .live(provider: "Yahoo Finance", fetchedAt: date("2026-07-03"))
        ))
        let resolved = record(tradingDay: "2026-07-02", claims: [resolvedClaim])
        let unresolvedToday = record(tradingDay: "2026-07-03", claims: [marketClaim()])

        store.insert(unresolvedToday)
        store.insert(unresolvedOld)
        store.insert(resolved)

        #expect(store.pendingRecords(before: "2026-07-03") == [unresolvedOld])
    }

    @Test("No-call records never count as pending")
    func noCallRecordsAreNotPending() throws {
        let store = PredictionLedgerStore(directoryURL: temporaryDirectoryURL())
        defer { try? store.removeAll() }

        store.insert(record(tradingDay: "2026-07-01", claims: []))

        #expect(store.pendingRecords(before: "2026-07-03").isEmpty)
    }

    @Test("A corrupt ledger file recovers empty instead of crashing")
    func corruptLedgerRecoversEmpty() throws {
        let directoryURL = temporaryDirectoryURL()
        let fileManager = FileManager.default
        try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        try Data("not json {".utf8).write(to: directoryURL.appendingPathComponent("prediction-ledger.json"))

        let store = PredictionLedgerStore(directoryURL: directoryURL)
        defer { try? store.removeAll() }

        #expect(store.allRecords().isEmpty)

        // The store must still accept new records after recovery.
        let fresh = record(tradingDay: "2026-07-06", claims: [marketClaim()])
        #expect(store.insert(fresh))
        #expect(store.allRecords() == [fresh])
    }

    @Test("Records list newest trading day first")
    func recordsListNewestFirst() throws {
        let store = PredictionLedgerStore(directoryURL: temporaryDirectoryURL())
        defer { try? store.removeAll() }

        let older = record(tradingDay: "2026-07-01", claims: [])
        let newer = record(tradingDay: "2026-07-02", claims: [])
        store.insert(older)
        store.insert(newer)

        #expect(store.allRecords().map(\.tradingDay) == ["2026-07-02", "2026-07-01"])
    }

    // MARK: - Fixtures

    private func temporaryDirectoryURL() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("PredictionLedgerStoreTests", isDirectory: true)
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
    }

    private func record(tradingDay: String, claims: [PredictionClaim]) -> PredictionRecord {
        PredictionRecord(
            tradingDay: tradingDay,
            recordedAt: date(tradingDay),
            recordedAfterClose: false,
            claims: claims
        )
    }

    private func marketClaim(
        direction: PredictionDirection = .bullish,
        outcome: PredictionOutcome? = nil
    ) -> PredictionClaim {
        PredictionClaim(
            subject: .market,
            direction: direction,
            cosmicDriver: "Full Moon",
            driverKind: AstroOverlayEventKind.fullMoon.rawValue,
            historicalWinRate: 0.6,
            historicalEdge: 0.4,
            confidence: .moderate,
            outcome: outcome
        )
    }

    private func date(_ value: String) -> Date {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter.date(from: value) ?? Date(timeIntervalSince1970: 0)
    }
}
