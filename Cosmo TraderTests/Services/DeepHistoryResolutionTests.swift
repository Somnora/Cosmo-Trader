import Foundation
import Testing
@testable import Cosmo_Trader

/// Covers the twenty year daily depth and the defenses it needs. Yahoo answers
/// an unbounded daily request with monthly candles at HTTP 200 and a well
/// formed body, so nothing in the transport reports the downgrade, and span
/// coverage alone scores that payload as complete daily history.
struct DeepHistoryResolutionTests {

    @MainActor
    @Test("Daily and finer requests never carry the unbounded Yahoo range")
    func dailyAndFinerRequestsNeverCarryUnboundedYahooRange() {
        let service = YahooFinanceService.shared
        let to = date("2026-08-18")
        let daySpans = [0, 1, 7, 30, 90, 180, 365, 730, 1_830, 1_831, 3_650, 7_305, 18_263]
        let tokens = HistoricalCandleResolution.allCases
            .filter(\.isDailyOrFiner)
            .map(\.rawValue) + ["unrecognized"]

        for daySpan in daySpans {
            let from = Calendar.current.date(byAdding: .day, value: -daySpan, to: to) ?? to
            for token in tokens {
                let range = service.mapRange(from: from, to: to, resolution: token)
                #expect(
                    range != YahooFinanceService.unboundedRange,
                    "resolution \(token) over \(daySpan) days requested the unbounded range"
                )
            }
        }

        // The invariant is a substitution, not a comment on the range ladder,
        // so a later edit to that ladder cannot reintroduce the downgrade.
        #expect(
            YahooFinanceService.rangeEnforcingDailyResolution("max", resolution: "D")
                == YahooFinanceService.deepestDailyRange
        )
        #expect(YahooFinanceService.rangeEnforcingDailyResolution("max", resolution: "W") == "max")
    }

    @MainActor
    @Test("Twenty year timeframe requests daily resolution over twenty years")
    func twentyYearTimeframeRequestsDailyResolutionOverTwentyYears() {
        let now = date("2026-08-18")
        let cache = HistoricalPriceCache(directoryURL: temporaryCacheURL(), nowProvider: { now })
        defer { try? cache.removeAll() }
        let service = HistoricalPriceService.testingInstance(
            historicalPriceCache: cache,
            nowProvider: { now },
            candleFetcher: { _, _, from, to in
                candleResponse(dates: weekdayDates(from: from, to: to), metadata: .unknown)
            }
        )

        let request = service.requestParameters(for: .twentyYear)

        #expect(request.resolution == "D")
        #expect(request.to == now)
        #expect(Calendar.current.dateComponents([.year], from: request.from, to: request.to).year == 20)
        #expect(ChartTimeframe.twentyYear.tradingDays == 5030)

        // The depth is analysis only: it must stay out of every picker.
        #expect(!ChartTimeframe.stockDetailHistoricalCases.contains(.twentyYear))

        #expect(
            YahooFinanceService.shared.mapRange(
                from: request.from,
                to: request.to,
                resolution: request.resolution
            ) == YahooFinanceService.deepestDailyRange
        )
    }

    @MainActor
    @Test("Reported granularity that disagrees with the request is marked insufficient")
    func reportedGranularityDisagreementIsMarkedInsufficient() async throws {
        let now = date("2026-08-18")
        let cache = HistoricalPriceCache(directoryURL: temporaryCacheURL(), nowProvider: { now })
        defer { try? cache.removeAll() }
        let service = HistoricalPriceService.testingInstance(
            historicalPriceCache: cache,
            nowProvider: { now },
            candleFetcher: { _, _, from, to in
                candleResponse(
                    dates: spacedDates(from: from, to: to, everyDays: 30),
                    metadata: HistoricalCandleMetadata(reportedGranularity: "1mo")
                )
            }
        )

        let result = try await service.fetchHistoricalPriceResult(symbol: "AAPL", timeframe: .twentyYear)

        #expect(
            result.completeness
                == .insufficient(reason: "Provider returned 1mo candles instead of the requested 1d")
        )
        #expect(!result.completeness.isUsableForCorrelation)
        #expect(!result.dataset.isUsableForCorrelation)

        // A downgraded payload must not take the durable slot for a day.
        #expect(cache.dataset(symbol: "AAPL", timeframe: .twentyYear, resolution: "D", now: now) == nil)
    }

    @Test("Equivalent granularity spellings do not read as a downgrade")
    func equivalentGranularitySpellingsDoNotReadAsDowngrade() {
        // Yahoo spells an hourly bar `1h` in some responses and `60m` in
        // others. Comparing the labels rather than the bar durations would
        // silence every intraday chart the moment the spelling changed.
        #expect(!HistoricalDatasetExpectation(
            resolution: .hour,
            metadata: HistoricalCandleMetadata(reportedGranularity: "60m")
        ).hasResolutionDowngrade)
        #expect(!HistoricalDatasetExpectation(
            resolution: .week,
            metadata: HistoricalCandleMetadata(reportedGranularity: "1w")
        ).hasResolutionDowngrade)
        #expect(!HistoricalDatasetExpectation(
            resolution: .day,
            metadata: HistoricalCandleMetadata(reportedGranularity: "1d")
        ).hasResolutionDowngrade)

        #expect(HistoricalDatasetExpectation(
            resolution: .day,
            metadata: HistoricalCandleMetadata(reportedGranularity: "1mo")
        ).hasResolutionDowngrade)

        // Silence is not evidence of a downgrade; density has to carry it.
        #expect(!HistoricalDatasetExpectation(resolution: .day).hasResolutionDowngrade)
    }

    @MainActor
    @Test("Density backstop rejects monthly candles presented as daily history")
    func densityBackstopRejectsMonthlyCandlesPresentedAsDailyHistory() async throws {
        let now = date("2026-08-18")
        let cache = HistoricalPriceCache(directoryURL: temporaryCacheURL(), nowProvider: { now })
        defer { try? cache.removeAll() }
        let service = HistoricalPriceService.testingInstance(
            historicalPriceCache: cache,
            nowProvider: { now },
            candleFetcher: { _, _, from, to in
                // Same monthly payload, but with no granularity reported at all,
                // so density is the only thing left to catch it.
                candleResponse(dates: spacedDates(from: from, to: to, everyDays: 30), metadata: .unknown)
            }
        )

        let result = try await service.fetchHistoricalPriceResult(symbol: "AAPL", timeframe: .twentyYear)

        #expect(
            result.completeness
                == .insufficient(reason: "Provider returned fewer candles than the requested resolution allows")
        )
        #expect(!result.completeness.allowsNumericCorrelationClaims)

        // Span coverage on its own would have called this complete twenty year
        // daily history, which is exactly why resolution has to reach scoring.
        let actualDuration = result.actualRange?.duration ?? 0
        #expect(actualDuration / result.requestedRange.duration > 0.9)
    }

    @MainActor
    @Test("First trade date clamps the requested range so a young listing is not scored down")
    func firstTradeDateClampsRequestedRangeForYoungListing() async throws {
        let now = date("2026-08-18")
        let firstTradeDate = date("2021-04-14")
        let cache = HistoricalPriceCache(directoryURL: temporaryCacheURL(), nowProvider: { now })
        defer { try? cache.removeAll() }
        let service = HistoricalPriceService.testingInstance(
            historicalPriceCache: cache,
            nowProvider: { now },
            candleFetcher: { _, _, _, to in
                candleResponse(
                    dates: weekdayDates(from: firstTradeDate, to: to),
                    metadata: HistoricalCandleMetadata(
                        reportedGranularity: "1d",
                        firstTradeDate: firstTradeDate
                    )
                )
            }
        )

        let result = try await service.fetchHistoricalPriceResult(symbol: "COIN", timeframe: .twentyYear)

        #expect(result.requestedRange.start == firstTradeDate)
        #expect(result.completeness == .complete)
        #expect(result.completeness.allowsNumericCorrelationClaims)
        #expect(result.dataset.isUsableForCorrelation)
    }

    @MainActor
    @Test("Without a first trade date the same young listing loses its numeric claims")
    func withoutFirstTradeDateTheSameYoungListingLosesNumericClaims() async throws {
        let now = date("2026-08-18")
        let firstTradeDate = date("2021-04-14")
        let cache = HistoricalPriceCache(directoryURL: temporaryCacheURL(), nowProvider: { now })
        defer { try? cache.removeAll() }
        let service = HistoricalPriceService.testingInstance(
            historicalPriceCache: cache,
            nowProvider: { now },
            candleFetcher: { _, _, _, to in
                candleResponse(
                    dates: weekdayDates(from: firstTradeDate, to: to),
                    metadata: HistoricalCandleMetadata(reportedGranularity: "1d")
                )
            }
        )

        // Control for the clamp above: the identical, perfectly dense daily
        // series is silenced when the provider does not say when the symbol
        // started trading, because coverage is then measured against fifteen
        // years the listing could never have filled.
        let result = try await service.fetchHistoricalPriceResult(symbol: "COIN", timeframe: .twentyYear)

        #expect(result.requestedRange.start < firstTradeDate)
        #expect(!result.completeness.allowsNumericCorrelationClaims)
    }

    @MainActor
    @Test("Deep history writes a cache entry separate from the shallower depths")
    func deepHistoryWritesACacheEntrySeparateFromShallowerDepths() async throws {
        let now = date("2026-08-18")
        let cache = HistoricalPriceCache(directoryURL: temporaryCacheURL(), nowProvider: { now })
        defer { try? cache.removeAll() }
        let service = HistoricalPriceService.testingInstance(
            historicalPriceCache: cache,
            nowProvider: { now },
            candleFetcher: { _, _, from, to in
                candleResponse(
                    dates: weekdayDates(from: from, to: to),
                    metadata: HistoricalCandleMetadata(reportedGranularity: "1d")
                )
            }
        )

        _ = try await service.fetchHistoricalPriceResult(symbol: "AAPL", timeframe: .twoYear)

        // Cache keys already carry the timeframe raw value, so the new depth
        // lands in its own file and no invalidation or migration is required.
        #expect(cache.dataset(symbol: "AAPL", timeframe: .twoYear, resolution: "D", now: now) != nil)
        #expect(cache.dataset(symbol: "AAPL", timeframe: .twentyYear, resolution: "D", now: now) == nil)

        _ = try await service.fetchHistoricalPriceResult(symbol: "AAPL", timeframe: .twentyYear)

        let deep = try #require(cache.dataset(symbol: "AAPL", timeframe: .twentyYear, resolution: "D", now: now))
        let shallow = try #require(cache.dataset(symbol: "AAPL", timeframe: .twoYear, resolution: "D", now: now))
        #expect(deep.candles.count > shallow.candles.count)
    }

    @MainActor
    @Test("Deep history holds for a day while shallower depths keep refetching hourly")
    func deepHistoryHoldsForADayWhileShallowerDepthsKeepRefetchingHourly() async throws {
        var currentDate = date("2026-08-18")
        let cache = HistoricalPriceCache(directoryURL: temporaryCacheURL(), nowProvider: { currentDate })
        defer { try? cache.removeAll() }
        var deepFetchCount = 0
        var shallowFetchCount = 0
        let service = HistoricalPriceService.testingInstance(
            historicalPriceCache: cache,
            nowProvider: { currentDate },
            candleFetcher: { _, _, from, to in
                if to.timeIntervalSince(from) > 10 * 365 * 24 * 60 * 60 {
                    deepFetchCount += 1
                } else {
                    shallowFetchCount += 1
                }
                return candleResponse(
                    dates: weekdayDates(from: from, to: to),
                    metadata: HistoricalCandleMetadata(reportedGranularity: "1d")
                )
            }
        )

        _ = try await service.fetchHistoricalPriceResult(symbol: "AAPL", timeframe: .twentyYear)
        _ = try await service.fetchHistoricalPriceResult(symbol: "AAPL", timeframe: .twoYear)

        currentDate = currentDate.addingTimeInterval(12 * 60 * 60)
        _ = try await service.fetchHistoricalPriceResult(symbol: "AAPL", timeframe: .twentyYear)
        _ = try await service.fetchHistoricalPriceResult(symbol: "AAPL", timeframe: .twoYear)

        #expect(deepFetchCount == 1)
        #expect(shallowFetchCount == 2)

        currentDate = currentDate.addingTimeInterval(13 * 60 * 60)
        _ = try await service.fetchHistoricalPriceResult(symbol: "AAPL", timeframe: .twentyYear)

        #expect(deepFetchCount == 2)
    }

    // MARK: - Helpers

    private func weekdayDates(from: Date, to: Date) -> [Date] {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .current

        var dates: [Date] = []
        var cursor = from
        while cursor <= to {
            let weekday = calendar.component(.weekday, from: cursor)
            if weekday != 1 && weekday != 7 {
                dates.append(cursor)
            }
            guard let next = calendar.date(byAdding: .day, value: 1, to: cursor) else { break }
            cursor = next
        }
        return dates
    }

    private func spacedDates(from: Date, to: Date, everyDays: Int) -> [Date] {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .current

        var dates: [Date] = []
        var cursor = from
        while cursor <= to {
            dates.append(cursor)
            guard let next = calendar.date(byAdding: .day, value: everyDays, to: cursor) else { break }
            cursor = next
        }
        return dates
    }

    private func candleResponse(dates: [Date], metadata: HistoricalCandleMetadata) -> FinnhubCandleResponse {
        let closes = dates.indices.map { 100 + Double($0) * 0.01 }
        return FinnhubCandleResponse(
            s: dates.isEmpty ? "no_data" : "ok",
            t: dates.map { Int($0.timeIntervalSince1970) },
            o: closes,
            h: closes.map { $0 + 1 },
            l: closes.map { max(0.01, $0 - 1) },
            c: closes,
            v: closes.map { _ in 1_000 },
            metadata: metadata
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

    private func temporaryCacheURL() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("cosmo-deep-history-resolution-tests-\(UUID().uuidString)", isDirectory: true)
    }
}
