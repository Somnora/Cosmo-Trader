import Foundation
import Testing
@testable import Cosmo_Trader

@MainActor
struct PredictionScoringServiceTests {

    // MARK: - Direction vs. actual move

    @Test(
        "Directional calls score hit or miss on the actual close sign",
        arguments: [
            (PredictionDirection.bullish, 0.5, PredictionResult.hit),
            (.bullish, -0.5, .miss),
            (.bearish, -0.5, .hit),
            (.bearish, 0.5, .miss)
        ]
    )
    func directionalCallsScoreOnCloseSign(
        direction: PredictionDirection,
        returnPercent: Double,
        expected: PredictionResult
    ) async throws {
        let store = freshStore()
        defer { try? store.removeAll() }
        let claim = claim(subject: .market, direction: direction)
        store.insert(record(tradingDay: "2026-07-01", claims: [claim]))

        let service = service(
            store: store,
            datasets: ["SPY": dataset(symbol: "SPY", closesByDay: [
                "2026-06-30": 100.0,
                "2026-07-01": 100.0 * (1 + returnPercent / 100)
            ])]
        )
        let applied = await service.resolvePending()

        #expect(applied == 1)
        let outcome = try #require(store.record(forTradingDay: "2026-07-01")?.claims.first?.outcome)
        #expect(outcome.result == expected)
        let actual = try #require(outcome.actualReturnPercent)
        #expect(abs(actual - returnPercent) < 0.0001)
    }

    @Test(
        "Deadband: ±0.09% is a flat day, ±0.11% is a move",
        arguments: [
            (0.09, PredictionResult.flat),
            (-0.09, .flat),
            (0.11, .hit),
            (-0.11, .miss)
        ]
    )
    func deadbandBoundary(returnPercent: Double, expected: PredictionResult) async throws {
        let store = freshStore()
        defer { try? store.removeAll() }
        store.insert(record(tradingDay: "2026-07-01", claims: [
            claim(subject: .market, direction: .bullish)
        ]))

        let service = service(
            store: store,
            datasets: ["SPY": dataset(symbol: "SPY", closesByDay: [
                "2026-06-30": 100.0,
                "2026-07-01": 100.0 * (1 + returnPercent / 100)
            ])]
        )
        await service.resolvePending()

        let outcome = try #require(store.record(forTradingDay: "2026-07-01")?.claims.first?.outcome)
        #expect(outcome.result == expected)
    }

    @Test("Neutral call hits on a flat day and misses on a move")
    func neutralCallScoring() async throws {
        let store = freshStore()
        defer { try? store.removeAll() }
        let flatClaim = claim(subject: .market, direction: .neutral)
        let movedClaim = claim(subject: .stock(symbol: "AAPL"), direction: .neutral)
        store.insert(record(tradingDay: "2026-07-01", claims: [flatClaim, movedClaim]))

        let service = service(
            store: store,
            datasets: [
                "SPY": dataset(symbol: "SPY", closesByDay: [
                    "2026-06-30": 100.0,
                    "2026-07-01": 100.05
                ]),
                "AAPL": dataset(symbol: "AAPL", closesByDay: [
                    "2026-06-30": 100.0,
                    "2026-07-01": 102.0
                ])
            ]
        )
        await service.resolvePending()

        let resolved = try #require(store.record(forTradingDay: "2026-07-01"))
        #expect(resolved.claims.first { $0.id == flatClaim.id }?.outcome?.result == .hit)
        #expect(resolved.claims.first { $0.id == movedClaim.id }?.outcome?.result == .miss)
    }

    // MARK: - Market closed

    @Test("Missing SPY candle with later candles resolves the whole record marketClosed")
    func missingSpyDayWithLaterCandlesIsMarketClosed() async throws {
        let store = freshStore()
        defer { try? store.removeAll() }
        // July 3 2026 is a market holiday in this fixture: SPY jumps from
        // July 2 to July 6.
        store.insert(record(tradingDay: "2026-07-03", claims: [
            claim(subject: .market, direction: .bullish),
            claim(subject: .stock(symbol: "AAPL"), direction: .bearish)
        ]))

        let service = service(
            store: store,
            datasets: [
                "SPY": dataset(symbol: "SPY", closesByDay: [
                    "2026-07-02": 100.0,
                    "2026-07-06": 101.0
                ]),
                "AAPL": dataset(symbol: "AAPL", closesByDay: [
                    "2026-07-02": 100.0,
                    "2026-07-06": 99.0
                ])
            ],
            today: "2026-07-07"
        )
        let applied = await service.resolvePending()

        #expect(applied == 2)
        let resolved = try #require(store.record(forTradingDay: "2026-07-03"))
        #expect(resolved.claims.allSatisfy { $0.outcome?.result == .marketClosed })
        #expect(resolved.claims.allSatisfy { $0.outcome?.actualReturnPercent == nil })
    }

    // MARK: - Pending and timeout

    @Test("Provider failure leaves the record pending for retry")
    func providerFailureLeavesPending() async throws {
        let store = freshStore()
        defer { try? store.removeAll() }
        store.insert(record(tradingDay: "2026-07-01", claims: [
            claim(subject: .market, direction: .bullish)
        ]))

        let service = PredictionScoringService(
            store: store,
            nowProvider: { self.easternDate("2026-07-02T10:00:00") },
            fetchDataset: { _, _ in throw URLError(.notConnectedToInternet) }
        )
        let applied = await service.resolvePending()

        #expect(applied == 0)
        #expect(store.record(forTradingDay: "2026-07-01")?.claims.first?.outcome == nil)
        #expect(store.pendingRecords(before: "2026-07-03").count == 1)
    }

    @Test("Persistent provider failure past 7 days resolves unresolved")
    func persistentFailurePastTimeoutResolvesUnresolved() async throws {
        let store = freshStore()
        defer { try? store.removeAll() }
        store.insert(record(tradingDay: "2026-07-01", claims: [
            claim(subject: .market, direction: .bullish)
        ]))

        // 8 days later, still failing.
        let service = PredictionScoringService(
            store: store,
            nowProvider: { self.easternDate("2026-07-09T10:00:00") },
            fetchDataset: { _, _ in throw URLError(.notConnectedToInternet) }
        )
        let applied = await service.resolvePending()

        #expect(applied == 1)
        let outcome = try #require(store.record(forTradingDay: "2026-07-01")?.claims.first?.outcome)
        #expect(outcome.result == .unresolved)
        #expect(outcome.actualReturnPercent == nil)
        #expect(!outcome.provenance.isProviderBacked)
    }

    @Test("Exactly 7 days out is still pending, not unresolved")
    func exactlySevenDaysStillPending() async throws {
        let store = freshStore()
        defer { try? store.removeAll() }
        store.insert(record(tradingDay: "2026-07-01", claims: [
            claim(subject: .market, direction: .bullish)
        ]))

        let service = PredictionScoringService(
            store: store,
            nowProvider: { self.easternDate("2026-07-08T10:00:00") },
            fetchDataset: { _, _ in throw URLError(.notConnectedToInternet) }
        )
        let applied = await service.resolvePending()

        #expect(applied == 0)
        #expect(store.record(forTradingDay: "2026-07-01")?.claims.first?.outcome == nil)
    }

    @Test("Sample-provenance datasets are treated as unavailable, never scored")
    func sampleDatasetsAreNeverScored() async throws {
        let store = freshStore()
        defer { try? store.removeAll() }
        store.insert(record(tradingDay: "2026-07-01", claims: [
            claim(subject: .market, direction: .bullish)
        ]))

        let sample = dataset(symbol: "SPY", closesByDay: [
            "2026-06-30": 100.0,
            "2026-07-01": 105.0
        ]).withProvenance(.sample(reason: "Preview data"))

        let service = service(store: store, rawDatasets: ["SPY": sample])
        let applied = await service.resolvePending()

        #expect(applied == 0)
        #expect(store.record(forTradingDay: "2026-07-01")?.claims.first?.outcome == nil)
    }

    @Test("Today's record is never scored early")
    func todaysRecordIsNotScored() async throws {
        let store = freshStore()
        defer { try? store.removeAll() }
        store.insert(record(tradingDay: "2026-07-02", claims: [
            claim(subject: .market, direction: .bullish)
        ]))

        let service = service(
            store: store,
            datasets: ["SPY": dataset(symbol: "SPY", closesByDay: [
                "2026-07-01": 100.0,
                "2026-07-02": 105.0
            ])],
            today: "2026-07-02"
        )
        let applied = await service.resolvePending()

        #expect(applied == 0)
    }

    // MARK: - Portfolio claims

    @Test("Portfolio return uses frozen weights, not equal weighting")
    func portfolioReturnUsesFrozenWeights() async throws {
        let store = freshStore()
        defer { try? store.removeAll() }
        // 90% AAPL (down 2%), 10% MSFT (up 5%): weighted return is clearly
        // negative even though the equal-weight average would be positive.
        let portfolioClaim = claim(
            subject: .portfolio,
            direction: .bearish,
            weights: ["AAPL": 0.9, "MSFT": 0.1]
        )
        store.insert(record(tradingDay: "2026-07-01", claims: [portfolioClaim]))

        let service = service(
            store: store,
            datasets: [
                "SPY": dataset(symbol: "SPY", closesByDay: [
                    "2026-06-30": 100.0, "2026-07-01": 100.0
                ]),
                "AAPL": dataset(symbol: "AAPL", closesByDay: [
                    "2026-06-30": 100.0, "2026-07-01": 98.0
                ]),
                "MSFT": dataset(symbol: "MSFT", closesByDay: [
                    "2026-06-30": 100.0, "2026-07-01": 105.0
                ])
            ]
        )
        await service.resolvePending()

        let outcome = try #require(store.record(forTradingDay: "2026-07-01")?.claims.first?.outcome)
        #expect(outcome.result == .hit)
        let actual = try #require(outcome.actualReturnPercent)
        // 0.9 * (-2%) + 0.1 * (+5%) = -1.3%
        #expect(abs(actual - (-1.3)) < 0.0001)
    }

    @Test("Portfolio coverage below 70% of frozen weight resolves unresolved")
    func portfolioUnderCoverageResolvesUnresolved() async throws {
        let store = freshStore()
        defer { try? store.removeAll() }
        // Only 60% of weight has candles; the 40% symbol's dataset exists
        // but lacks the trading day.
        let portfolioClaim = claim(
            subject: .portfolio,
            direction: .bullish,
            weights: ["AAPL": 0.6, "ZZZZ": 0.4]
        )
        store.insert(record(tradingDay: "2026-07-01", claims: [portfolioClaim]))

        let service = service(
            store: store,
            datasets: [
                "SPY": dataset(symbol: "SPY", closesByDay: [
                    "2026-06-30": 100.0, "2026-07-01": 101.0
                ]),
                "AAPL": dataset(symbol: "AAPL", closesByDay: [
                    "2026-06-30": 100.0, "2026-07-01": 102.0
                ]),
                "ZZZZ": dataset(symbol: "ZZZZ", closesByDay: [
                    "2026-06-28": 10.0, "2026-06-30": 10.0
                ])
            ]
        )
        let applied = await service.resolvePending()

        #expect(applied == 1)
        let outcome = try #require(store.record(forTradingDay: "2026-07-01")?.claims.first?.outcome)
        #expect(outcome.result == .unresolved)
        #expect(outcome.actualReturnPercent == nil)
    }

    @Test("Portfolio at exactly 70% coverage scores numerically")
    func portfolioAtExactCoverageScores() async throws {
        let store = freshStore()
        defer { try? store.removeAll() }
        let portfolioClaim = claim(
            subject: .portfolio,
            direction: .bullish,
            weights: ["AAPL": 0.7, "ZZZZ": 0.3]
        )
        store.insert(record(tradingDay: "2026-07-01", claims: [portfolioClaim]))

        let service = service(
            store: store,
            datasets: [
                "SPY": dataset(symbol: "SPY", closesByDay: [
                    "2026-06-30": 100.0, "2026-07-01": 101.0
                ]),
                "AAPL": dataset(symbol: "AAPL", closesByDay: [
                    "2026-06-30": 100.0, "2026-07-01": 102.0
                ]),
                "ZZZZ": dataset(symbol: "ZZZZ", closesByDay: [
                    "2026-06-28": 10.0, "2026-06-30": 10.0
                ])
            ]
        )
        await service.resolvePending()

        let outcome = try #require(store.record(forTradingDay: "2026-07-01")?.claims.first?.outcome)
        #expect(outcome.result == .hit)
        // Renormalized over covered weight: AAPL's +2% carries the claim.
        let actual = try #require(outcome.actualReturnPercent)
        #expect(abs(actual - 2.0) < 0.0001)
    }

    @Test("Stock with no candle on a traded day resolves unresolved, not a guess")
    func stockMissingOnTradedDayResolvesUnresolved() async throws {
        let store = freshStore()
        defer { try? store.removeAll() }
        store.insert(record(tradingDay: "2026-07-01", claims: [
            claim(subject: .stock(symbol: "HALT"), direction: .bullish)
        ]))

        let service = service(
            store: store,
            datasets: [
                "SPY": dataset(symbol: "SPY", closesByDay: [
                    "2026-06-30": 100.0, "2026-07-01": 101.0
                ]),
                "HALT": dataset(symbol: "HALT", closesByDay: [
                    "2026-06-28": 10.0, "2026-06-30": 10.0, "2026-07-02": 11.0
                ])
            ],
            today: "2026-07-03"
        )
        await service.resolvePending()

        let outcome = try #require(store.record(forTradingDay: "2026-07-01")?.claims.first?.outcome)
        #expect(outcome.result == .unresolved)
    }

    // MARK: - Fixtures

    private func freshStore() -> PredictionLedgerStore {
        PredictionLedgerStore(
            directoryURL: FileManager.default.temporaryDirectory
                .appendingPathComponent("PredictionScoringServiceTests", isDirectory: true)
                .appendingPathComponent(UUID().uuidString, isDirectory: true)
        )
    }

    /// Service over canned provider-backed datasets. `today` fixes the clock
    /// to 10 a.m. ET on that day.
    private func service(
        store: PredictionLedgerStore,
        datasets: [String: HistoricalPriceDataset],
        today: String = "2026-07-02"
    ) -> PredictionScoringService {
        service(store: store, rawDatasets: datasets, today: today)
    }

    private func service(
        store: PredictionLedgerStore,
        rawDatasets: [String: HistoricalPriceDataset],
        today: String = "2026-07-02"
    ) -> PredictionScoringService {
        PredictionScoringService(
            store: store,
            nowProvider: { self.easternDate("\(today)T10:00:00") },
            fetchDataset: { symbol, _ in
                guard let dataset = rawDatasets[symbol.uppercased()] else {
                    throw URLError(.resourceUnavailable)
                }
                return dataset
            }
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
        subject: PredictionSubject,
        direction: PredictionDirection,
        weights: [String: Double]? = nil
    ) -> PredictionClaim {
        PredictionClaim(
            subject: subject,
            direction: direction,
            cosmicDriver: "Full Moon",
            driverKind: AstroOverlayEventKind.fullMoon.rawValue,
            historicalWinRate: 0.6,
            historicalEdge: 0.4,
            confidence: .moderate,
            portfolioWeights: weights
        )
    }

    /// Provider-backed daily dataset with one candle per ET day.
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
