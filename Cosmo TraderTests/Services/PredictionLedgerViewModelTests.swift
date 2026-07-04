import Foundation
import SwiftUI
import Testing
@testable import Cosmo_Trader

@MainActor
struct PredictionLedgerViewModelTests {

    @Test("Load surfaces today's record, resolves earlier days, and computes the scorecard")
    func loadSurfacesTodayResolvesAndComputes() async throws {
        let store = freshStore()
        defer { try? store.removeAll() }

        // Yesterday: an unresolved bullish market call; today: a fresh call.
        let yesterdayClaim = claim(direction: .bullish)
        store.insert(record(tradingDay: "2026-07-01", claims: [yesterdayClaim]))
        let todayClaim = claim(direction: .bearish)
        store.insert(record(tradingDay: "2026-07-02", claims: [todayClaim]))

        let viewModel = viewModel(
            store: store,
            spyCloses: ["2026-06-30": 100.0, "2026-07-01": 101.0, "2026-07-02": 100.5],
            today: "2026-07-02"
        )
        await viewModel.load()

        // Today's record surfaces unscored.
        let today = try #require(viewModel.todayRecord)
        #expect(today.tradingDay == "2026-07-02")
        #expect(today.claims.first?.outcome == nil)

        // Yesterday resolved during load and becomes the last scored record.
        let lastScored = try #require(viewModel.lastScoredRecord)
        #expect(lastScored.tradingDay == "2026-07-01")
        #expect(lastScored.claims.first?.outcome?.result == .hit)

        // Scorecard picked the resolution up in the same load.
        #expect(viewModel.scorecard.scoredCount == 1)
        #expect(viewModel.scorecard.hitCount == 1)
        #expect(viewModel.history.map(\.tradingDay) == ["2026-07-02", "2026-07-01"])
        #expect(viewModel.hasAnyLedgerContent)
        #expect(viewModel.isEarlyDays)
        #expect(!viewModel.isLoading)
    }

    @Test("Empty ledger loads to a zeroed, content-free state")
    func emptyLedgerLoadsToZeroedState() async throws {
        let store = freshStore()
        defer { try? store.removeAll() }

        let viewModel = viewModel(store: store, spyCloses: [:], today: "2026-07-02")
        await viewModel.load()

        #expect(viewModel.todayRecord == nil)
        #expect(viewModel.lastScoredRecord == nil)
        #expect(viewModel.history.isEmpty)
        #expect(!viewModel.hasAnyLedgerContent)
        #expect(viewModel.scorecard.scoredCount == 0)
    }

    @Test("Last scored record skips unresolved days and never points at today")
    func lastScoredSkipsUnresolvedAndToday() async throws {
        let store = freshStore()
        defer { try? store.removeAll() }

        // June 30 resolved by fixture data; July 1 has no candles (stays
        // pending); July 2 is today.
        store.insert(record(tradingDay: "2026-06-30", claims: [claim(direction: .bullish)]))
        store.insert(record(tradingDay: "2026-07-01", claims: [claim(direction: .bullish)]))
        store.insert(record(tradingDay: "2026-07-02", claims: [claim(direction: .bullish)]))

        let viewModel = viewModel(
            store: store,
            spyCloses: ["2026-06-29": 100.0, "2026-06-30": 101.0],
            today: "2026-07-02"
        )
        await viewModel.load()

        #expect(viewModel.lastScoredRecord?.tradingDay == "2026-06-30")
        #expect(viewModel.todayRecord?.tradingDay == "2026-07-02")
    }

    @Test("Display labels map every direction, result, and subject")
    func displayLabelsMapEverything() {
        #expect(PredictionDirection.bullish.displayLabel == "LEANS BULLISH")
        #expect(PredictionDirection.bearish.displayLabel == "LEANS BEARISH")
        #expect(PredictionDirection.neutral.displayLabel == "READS NEUTRAL")

        #expect(PredictionResult.hit.displayLabel == "HIT")
        #expect(PredictionResult.miss.displayLabel == "MISS")
        #expect(PredictionResult.flat.displayLabel == "PUSH")
        #expect(PredictionResult.unresolved.displayLabel == "UNSCORED")
        #expect(PredictionResult.marketClosed.displayLabel == "MKT CLOSED")
        #expect(PredictionResult.hit.isScored && PredictionResult.miss.isScored)
        #expect(!PredictionResult.flat.isScored && !PredictionResult.unresolved.isScored)

        #expect(PredictionSubject.market.displayLabel == "MARKET (SPY)")
        #expect(PredictionSubject.portfolio.displayLabel == "PORTFOLIO")
        #expect(PredictionSubject.stock(symbol: "aapl").displayLabel == "AAPL")
    }

    @Test("Historical context line renders win rate and edge")
    func historicalContextLineRendersStats() {
        let claim = claim(direction: .bullish, winRate: 0.62, edge: 0.4)
        #expect(claim.historicalContextLine == "Full Moon · 62% of past windows up · edge +0.40%")
    }

    @Test("Trading day display label renders the ET month and day")
    func tradingDayDisplayLabel() {
        let record = record(tradingDay: "2026-07-06", claims: [])
        #expect(record.tradingDayDisplayLabel == "JUL 6")
    }

    @Test("Scorecard views instantiate against loaded state")
    func scorecardViewsInstantiate() async throws {
        let store = freshStore()
        defer { try? store.removeAll() }
        store.insert(record(tradingDay: "2026-07-01", claims: [claim(direction: .bullish)]))
        store.insert(record(tradingDay: "2026-07-02", claims: []))

        let viewModel = viewModel(
            store: store,
            spyCloses: ["2026-06-30": 100.0, "2026-07-01": 101.0],
            today: "2026-07-02"
        )
        await viewModel.load()

        let card = TodayPredictionCard(viewModel: viewModel)
        let scorecard = CosmicScorecardView(viewModel: viewModel)
        #expect(ImageRenderer(content: card.frame(width: 390)).uiImage != nil)
        #expect(ImageRenderer(content: scorecard.frame(width: 390, height: 800)).uiImage != nil)
    }

    // MARK: - Fixtures

    private func freshStore() -> PredictionLedgerStore {
        PredictionLedgerStore(
            directoryURL: FileManager.default.temporaryDirectory
                .appendingPathComponent("PredictionLedgerViewModelTests", isDirectory: true)
                .appendingPathComponent(UUID().uuidString, isDirectory: true)
        )
    }

    private func viewModel(
        store: PredictionLedgerStore,
        spyCloses: [String: Double],
        today: String
    ) -> PredictionLedgerViewModel {
        let scoringService = PredictionScoringService(
            store: store,
            nowProvider: { self.easternDate("\(today)T10:00:00") },
            fetchDataset: { symbol, _ in
                guard symbol.uppercased() == "SPY", !spyCloses.isEmpty else {
                    throw URLError(.resourceUnavailable)
                }
                return self.dataset(symbol: "SPY", closesByDay: spyCloses)
            }
        )
        return PredictionLedgerViewModel(
            store: store,
            scoringService: scoringService,
            nowProvider: { self.easternDate("\(today)T10:00:00") }
        )
    }

    private func record(tradingDay: String, claims: [PredictionClaim]) -> PredictionRecord {
        PredictionRecord(
            tradingDay: tradingDay,
            recordedAt: easternDate("\(tradingDay)T09:35:00"),
            recordedAfterClose: false,
            claims: claims
        )
    }

    private func claim(
        direction: PredictionDirection,
        winRate: Double = 0.6,
        edge: Double = 0.4
    ) -> PredictionClaim {
        PredictionClaim(
            subject: .market,
            direction: direction,
            cosmicDriver: "Full Moon",
            driverKind: AstroOverlayEventKind.fullMoon.rawValue,
            historicalWinRate: winRate,
            historicalEdge: edge,
            confidence: .moderate
        )
    }

    private func dataset(symbol: String, closesByDay: [String: Double]) -> HistoricalPriceDataset {
        let candles = closesByDay
            .sorted { $0.key < $1.key }
            .map { day, close in
                OHLCData(
                    date: easternDate("\(day)T16:00:00"),
                    open: close,
                    high: close + 1,
                    low: max(0.01, close - 1),
                    close: close,
                    volume: 1_000
                )
            }
        let fetchedAt = easternDate("2026-07-02T09:00:00")
        return HistoricalPriceDataset.providerBacked(
            symbol: symbol,
            candles: candles,
            provider: FinancialDataProvenance.yahooProvider,
            fetchedAt: fetchedAt,
            requestedRange: DateInterval(
                start: easternDate("2026-06-01T00:00:00"),
                end: fetchedAt
            ),
            provenance: .live(provider: FinancialDataProvenance.yahooProvider, fetchedAt: fetchedAt)
        )
    }

    private func easternDate(_ value: String) -> Date {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "America/New_York")
        guard let date = formatter.date(from: value) else {
            Issue.record("Invalid fixture date: \(value)")
            return Date(timeIntervalSince1970: 0)
        }
        return date
    }
}
