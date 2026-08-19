import Foundation
import Testing
@testable import Cosmo_Trader

@MainActor
struct PredictionExtractorTests {

    private let extractor = PredictionExtractor()
    /// Every fixture below cites Full Moon, so the driver join has to report
    /// it as occurring before any claim can exist. The suites that are about
    /// something else (display mode, thresholds, ET boundaries) pass this so
    /// they keep testing that one thing.
    private let activeFullMoon: Set<AstroOverlayEventKind> = [.fullMoon]

    // MARK: - Direction derivation

    @Test("Positive edge with win rate at the bullish threshold reads bullish")
    func positiveEdgeAtBullishThresholdReadsBullish() throws {
        let record = extractor.makeRecord(
            date: easternDate("2026-07-06T09:35:00"),
            activeDriverKinds: activeFullMoon,
            marketWeather: marketWeather(events: [
                weatherEvent(averageReturn: 0.9, baselineReturn: 0.3, winRate: 0.55)
            ]),
            portfolioSummaries: [],
            portfolioHoldings: [],
            stockCandidate: nil
        )

        let claim = try #require(record.claims.first)
        #expect(claim.subject == .market)
        #expect(claim.direction == .bullish)
        #expect(claim.cosmicDriver == "Full Moon")
        #expect(claim.driverKind == AstroOverlayEventKind.fullMoon.rawValue)
        #expect(abs(claim.historicalEdge - 0.6) < 0.0001)
        #expect(claim.historicalWinRate == 0.55)
    }

    @Test("Positive edge below the bullish win-rate threshold reads neutral")
    func positiveEdgeBelowBullishThresholdReadsNeutral() {
        let record = extractor.makeRecord(
            date: easternDate("2026-07-06T09:35:00"),
            activeDriverKinds: activeFullMoon,
            marketWeather: marketWeather(events: [
                weatherEvent(averageReturn: 0.9, baselineReturn: 0.3, winRate: 0.54)
            ]),
            portfolioSummaries: [],
            portfolioHoldings: [],
            stockCandidate: nil
        )

        #expect(record.claims.first?.direction == .neutral)
    }

    @Test("Negative edge with win rate at the bearish threshold reads bearish")
    func negativeEdgeAtBearishThresholdReadsBearish() {
        let record = extractor.makeRecord(
            date: easternDate("2026-07-06T09:35:00"),
            activeDriverKinds: activeFullMoon,
            marketWeather: marketWeather(events: [
                weatherEvent(averageReturn: -0.4, baselineReturn: 0.2, winRate: 0.45)
            ]),
            portfolioSummaries: [],
            portfolioHoldings: [],
            stockCandidate: nil
        )

        #expect(record.claims.first?.direction == .bearish)
    }

    @Test("Negative edge above the bearish win-rate threshold reads neutral")
    func negativeEdgeAboveBearishThresholdReadsNeutral() {
        let record = extractor.makeRecord(
            date: easternDate("2026-07-06T09:35:00"),
            activeDriverKinds: activeFullMoon,
            marketWeather: marketWeather(events: [
                weatherEvent(averageReturn: -0.4, baselineReturn: 0.2, winRate: 0.46)
            ]),
            portfolioSummaries: [],
            portfolioHoldings: [],
            stockCandidate: nil
        )

        #expect(record.claims.first?.direction == .neutral)
    }

    @Test("Zero edge reads neutral even with an extreme win rate")
    func zeroEdgeReadsNeutral() {
        let record = extractor.makeRecord(
            date: easternDate("2026-07-06T09:35:00"),
            activeDriverKinds: activeFullMoon,
            marketWeather: marketWeather(events: [
                weatherEvent(averageReturn: 0.5, baselineReturn: 0.5, winRate: 0.95)
            ]),
            portfolioSummaries: [],
            portfolioHoldings: [],
            stockCandidate: nil
        )

        #expect(record.claims.first?.direction == .neutral)
    }

    // MARK: - Market-backed filter

    @Test(
        "Non-market-backed weather summaries never create claims",
        arguments: [
            CorrelationDisplayMode.sampleOnly,
            .partialCoverage,
            .partialDataset,
            .insufficientDataset,
            .insufficientSample,
            .unavailable
        ]
    )
    func nonMarketBackedWeatherCreatesNoClaim(displayMode: CorrelationDisplayMode) {
        let record = extractor.makeRecord(
            date: easternDate("2026-07-06T09:35:00"),
            activeDriverKinds: activeFullMoon,
            marketWeather: marketWeather(events: [
                weatherEvent(
                    averageReturn: 0.9,
                    baselineReturn: 0.3,
                    winRate: 0.9,
                    displayMode: displayMode
                )
            ]),
            portfolioSummaries: [],
            portfolioHoldings: [],
            stockCandidate: nil
        )

        #expect(record.claims.isEmpty)
        #expect(record.isNoCall)
    }

    @Test("No market-backed inputs produce an explicit no-call record")
    func noInputsProduceNoCallRecord() {
        let record = extractor.makeRecord(
            date: easternDate("2026-07-06T09:35:00"),
            activeDriverKinds: activeFullMoon,
            marketWeather: nil,
            portfolioSummaries: [],
            portfolioHoldings: [],
            stockCandidate: nil
        )

        #expect(record.isNoCall)
        #expect(record.tradingDay == "2026-07-06")
        #expect(!record.recordedAfterClose)
    }

    // MARK: - Event selection

    @Test("Higher confidence event wins regardless of edge size")
    func higherConfidenceEventWins() {
        let record = extractor.makeRecord(
            date: easternDate("2026-07-06T09:35:00"),
            activeDriverKinds: [.fullMoon, .mercuryRetrograde],
            marketWeather: marketWeather(events: [
                weatherEvent(
                    eventName: "Mercury Retrograde",
                    eventType: .mercuryRetrograde,
                    averageReturn: 3.0,
                    baselineReturn: 0.1,
                    winRate: 0.8,
                    confidence: .thin
                ),
                weatherEvent(
                    eventName: "Full Moon",
                    eventType: .fullMoon,
                    averageReturn: 0.6,
                    baselineReturn: 0.2,
                    winRate: 0.6,
                    confidence: .strong
                )
            ]),
            portfolioSummaries: [],
            portfolioHoldings: [],
            stockCandidate: nil
        )

        #expect(record.claims.count == 1)
        #expect(record.claims.first?.cosmicDriver == "Full Moon")
    }

    @Test("Equal confidence ties break on absolute edge")
    func equalConfidenceTieBreaksOnEdge() {
        let record = extractor.makeRecord(
            date: easternDate("2026-07-06T09:35:00"),
            activeDriverKinds: [.fullMoon, .newMoon],
            marketWeather: marketWeather(events: [
                weatherEvent(
                    eventName: "Full Moon",
                    eventType: .fullMoon,
                    averageReturn: 0.5,
                    baselineReturn: 0.2,
                    winRate: 0.6,
                    confidence: .moderate
                ),
                weatherEvent(
                    eventName: "New Moon",
                    eventType: .newMoon,
                    averageReturn: -1.4,
                    baselineReturn: 0.2,
                    winRate: 0.3,
                    confidence: .moderate
                )
            ]),
            portfolioSummaries: [],
            portfolioHoldings: [],
            stockCandidate: nil
        )

        #expect(record.claims.first?.cosmicDriver == "New Moon")
        #expect(record.claims.first?.direction == .bearish)
    }

    // MARK: - Trading day and close boundary (ET)

    @Test("Record made before 4 p.m. ET is not flagged after-close")
    func beforeCloseIsNotFlagged() {
        let record = extractor.makeRecord(
            date: easternDate("2026-07-06T15:59:00"),
            activeDriverKinds: activeFullMoon,
            marketWeather: nil,
            portfolioSummaries: [],
            portfolioHoldings: [],
            stockCandidate: nil
        )

        #expect(!record.recordedAfterClose)
    }

    @Test("Record made at or after 4 p.m. ET is flagged after-close")
    func atOrAfterCloseIsFlagged() {
        let atClose = extractor.makeRecord(
            date: easternDate("2026-07-06T16:00:00"),
            activeDriverKinds: activeFullMoon,
            marketWeather: nil,
            portfolioSummaries: [],
            portfolioHoldings: [],
            stockCandidate: nil
        )
        let afterClose = extractor.makeRecord(
            date: easternDate("2026-07-06T16:01:00"),
            activeDriverKinds: activeFullMoon,
            marketWeather: nil,
            portfolioSummaries: [],
            portfolioHoldings: [],
            stockCandidate: nil
        )

        #expect(atClose.recordedAfterClose)
        #expect(afterClose.recordedAfterClose)
    }

    @Test("Trading day is the ET calendar day, not UTC")
    func tradingDayUsesEasternCalendar() {
        // 11:30 p.m. ET on July 6 is already July 7 in UTC.
        let record = extractor.makeRecord(
            date: easternDate("2026-07-06T23:30:00"),
            activeDriverKinds: activeFullMoon,
            marketWeather: nil,
            portfolioSummaries: [],
            portfolioHoldings: [],
            stockCandidate: nil
        )

        #expect(record.tradingDay == "2026-07-06")
    }

    // MARK: - Portfolio claims

    @Test("Portfolio claim freezes market-value weights at recording time")
    func portfolioClaimFreezesWeights() throws {
        let record = extractor.makeRecord(
            date: easternDate("2026-07-06T09:35:00"),
            activeDriverKinds: activeFullMoon,
            marketWeather: nil,
            portfolioSummaries: [
                portfolioSummary(averageReturn: 1.0, baselineReturn: 0.2, winRate: 0.7)
            ],
            portfolioHoldings: [
                stock(symbol: "AAPL", sharesOwned: 3),   // 300 of 400
                stock(symbol: "MSFT", sharesOwned: 1)    // 100 of 400
            ],
            stockCandidate: nil
        )

        let claim = try #require(record.claims.first)
        #expect(claim.subject == .portfolio)
        #expect(claim.direction == .bullish)
        let weights = try #require(claim.portfolioWeights)
        #expect(abs((weights["AAPL"] ?? 0) - 0.75) < 0.0001)
        #expect(abs((weights["MSFT"] ?? 0) - 0.25) < 0.0001)
    }

    @Test("Market-backed portfolio summary without owned holdings creates no claim")
    func portfolioClaimRequiresOwnedHoldings() {
        let record = extractor.makeRecord(
            date: easternDate("2026-07-06T09:35:00"),
            activeDriverKinds: activeFullMoon,
            marketWeather: nil,
            portfolioSummaries: [
                portfolioSummary(averageReturn: 1.0, baselineReturn: 0.2, winRate: 0.7)
            ],
            portfolioHoldings: [],
            stockCandidate: nil
        )

        #expect(record.isNoCall)
    }

    // MARK: - Stock claims

    @Test("Stock claim targets the candidate symbol")
    func stockClaimTargetsCandidateSymbol() throws {
        let candidate = TodayStockCandidate(
            stock: stock(symbol: "AAPL", sharesOwned: 0),
            summaries: [
                stockSummary(averageReturn: -0.8, baselineReturn: 0.1, winRate: 0.3)
            ],
            provenance: liveProvenance(),
            completeness: .complete,
            source: .watchlist
        )

        let record = extractor.makeRecord(
            date: easternDate("2026-07-06T09:35:00"),
            activeDriverKinds: activeFullMoon,
            marketWeather: nil,
            portfolioSummaries: [],
            portfolioHoldings: [],
            stockCandidate: candidate
        )

        let claim = try #require(record.claims.first)
        #expect(claim.subject == .stock(symbol: "AAPL"))
        #expect(claim.direction == .bearish)
    }

    @Test("All three subjects record together, market first")
    func allThreeSubjectsRecordTogether() {
        let candidate = TodayStockCandidate(
            stock: stock(symbol: "TSLA", sharesOwned: 0),
            summaries: [
                stockSummary(averageReturn: 0.9, baselineReturn: 0.1, winRate: 0.7)
            ],
            provenance: liveProvenance(),
            completeness: .complete,
            source: .portfolio
        )

        let record = extractor.makeRecord(
            date: easternDate("2026-07-06T09:35:00"),
            activeDriverKinds: activeFullMoon,
            marketWeather: marketWeather(events: [
                weatherEvent(averageReturn: 0.9, baselineReturn: 0.3, winRate: 0.6)
            ]),
            portfolioSummaries: [
                portfolioSummary(averageReturn: 1.0, baselineReturn: 0.2, winRate: 0.7)
            ],
            portfolioHoldings: [stock(symbol: "AAPL", sharesOwned: 2)],
            stockCandidate: candidate
        )

        #expect(record.claims.map(\.subject) == [
            .market,
            .portfolio,
            .stock(symbol: "TSLA")
        ])
    }

    // MARK: - Active cosmic driver join

    @Test("Fully market-backed summaries abstain when no driver is active")
    func noActiveDriverProducesNoCallRecord() {
        let record = extractor.makeRecord(
            date: easternDate("2026-07-06T09:35:00"),
            activeDriverKinds: [],
            marketWeather: marketWeather(events: [
                weatherEvent(averageReturn: 0.9, baselineReturn: 0.3, winRate: 0.7)
            ]),
            portfolioSummaries: [
                portfolioSummary(averageReturn: 1.0, baselineReturn: 0.2, winRate: 0.7)
            ],
            portfolioHoldings: [stock(symbol: "AAPL", sharesOwned: 2)],
            stockCandidate: fullMoonStockCandidate()
        )

        // All three builders decline, and the day is still recorded.
        #expect(record.claims.isEmpty)
        #expect(record.isNoCall)
        #expect(record.tradingDay == "2026-07-06")
        #expect(!record.recordedAfterClose)
    }

    @Test("The same summaries claim once their driver is active")
    func activeDriverProducesClaims() {
        let record = extractor.makeRecord(
            date: easternDate("2026-07-06T09:35:00"),
            activeDriverKinds: [.fullMoon],
            marketWeather: marketWeather(events: [
                weatherEvent(averageReturn: 0.9, baselineReturn: 0.3, winRate: 0.7)
            ]),
            portfolioSummaries: [
                portfolioSummary(averageReturn: 1.0, baselineReturn: 0.2, winRate: 0.7)
            ],
            portfolioHoldings: [stock(symbol: "AAPL", sharesOwned: 2)],
            stockCandidate: fullMoonStockCandidate()
        )

        #expect(!record.isNoCall)
        #expect(record.claims.map(\.subject) == [
            .market,
            .portfolio,
            .stock(symbol: "AAPL")
        ])
        #expect(record.claims.allSatisfy { $0.driverKind == AstroOverlayEventKind.fullMoon.rawValue })
    }

    @Test("A driver outside the active set never claims, even unopposed")
    func inactiveSoleDriverNeverClaims() {
        let record = extractor.makeRecord(
            date: easternDate("2026-07-06T09:35:00"),
            activeDriverKinds: [.mercuryRetrograde],
            marketWeather: marketWeather(events: [
                weatherEvent(averageReturn: 0.9, baselineReturn: 0.3, winRate: 0.9)
            ]),
            portfolioSummaries: [],
            portfolioHoldings: [],
            stockCandidate: nil
        )

        #expect(record.isNoCall)
    }

    @Test("Best event is selected among active drivers only")
    func bestEventIsSelectedAmongActiveDriversOnly() throws {
        // Mercury Rx carries the stronger sample, but it is not occurring, so
        // the claim must fall to the active Full Moon rather than cite an
        // event that is not happening.
        let record = extractor.makeRecord(
            date: easternDate("2026-07-06T09:35:00"),
            activeDriverKinds: [.fullMoon],
            marketWeather: marketWeather(events: [
                weatherEvent(
                    eventName: "Mercury Rx",
                    eventType: .mercuryRetrograde,
                    averageReturn: 3.0,
                    baselineReturn: 0.1,
                    winRate: 0.85,
                    confidence: .strong
                ),
                weatherEvent(
                    eventName: "Full Moon",
                    eventType: .fullMoon,
                    averageReturn: 0.6,
                    baselineReturn: 0.2,
                    winRate: 0.6,
                    confidence: .moderate
                ),
                weatherEvent(
                    eventName: "New Moon",
                    eventType: .newMoon,
                    averageReturn: -2.5,
                    baselineReturn: 0.2,
                    winRate: 0.2,
                    confidence: .strong
                )
            ]),
            portfolioSummaries: [],
            portfolioHoldings: [],
            stockCandidate: nil
        )

        let claim = try #require(record.claims.first)
        #expect(record.claims.count == 1)
        #expect(claim.cosmicDriver == "Full Moon")
        #expect(claim.driverKind == AstroOverlayEventKind.fullMoon.rawValue)
        #expect(claim.direction == .bullish)
    }

    @Test("Records carry the current ledger schema version")
    func recordsCarryCurrentSchemaVersion() {
        let record = extractor.makeRecord(
            date: easternDate("2026-07-06T09:35:00"),
            activeDriverKinds: activeFullMoon,
            marketWeather: marketWeather(events: [
                weatherEvent(averageReturn: 0.9, baselineReturn: 0.3, winRate: 0.7)
            ]),
            portfolioSummaries: [],
            portfolioHoldings: [],
            stockCandidate: nil
        )

        #expect(record.schemaVersion == PredictionRecord.currentSchemaVersion)
        #expect(!record.predatesActiveDriverJoin)
    }

    // MARK: - Fixtures

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

    private func fullMoonStockCandidate() -> TodayStockCandidate {
        TodayStockCandidate(
            stock: stock(symbol: "AAPL", sharesOwned: 0),
            summaries: [
                stockSummary(averageReturn: 0.9, baselineReturn: 0.1, winRate: 0.7)
            ],
            provenance: liveProvenance(),
            completeness: .complete,
            source: .watchlist
        )
    }

    private func liveProvenance() -> FinancialDataProvenance {
        .live(provider: "Yahoo Finance", fetchedAt: easternDate("2026-07-06T09:30:00"))
    }

    private func stock(symbol: String, sharesOwned: Double) -> Stock {
        Stock(
            symbol: symbol,
            name: "\(symbol) Inc.",
            currentPrice: 100,
            priceChange: 1,
            percentageChange: 1,
            sharesOwned: sharesOwned,
            purchasePrice: 90,
            foundedMonth: 4,
            foundedDay: 1,
            foundedYear: 1976,
            sector: "Technology"
        )
    }

    private func weatherEvent(
        eventName: String = "Full Moon",
        eventType: AstroOverlayEventKind = .fullMoon,
        averageReturn: Double?,
        baselineReturn: Double?,
        winRate: Double?,
        confidence: CorrelationConfidence = .moderate,
        displayMode: CorrelationDisplayMode = .marketBackedResult
    ) -> MarketWeatherEventSummary {
        MarketWeatherEventSummary(
            id: eventType.rawValue,
            eventName: eventName,
            eventType: eventType,
            eventCount: 6,
            sampleSize: displayMode == .marketBackedResult ? 6 : 0,
            window: CorrelationWindow(daysBefore: 1, daysAfter: 3),
            averageMarketReturn: averageReturn,
            medianMarketReturn: averageReturn,
            winRate: winRate,
            baselineMarketReturn: baselineReturn,
            baselineWinRate: nil,
            volatilityRatio: nil,
            maxDrawdown: nil,
            includedSymbols: ["DIA", "IWM", "QQQ", "SPY"],
            excludedSymbols: [],
            staleSymbols: [],
            provenance: liveProvenance(),
            confidence: confidence,
            displayMode: displayMode,
            disclaimer: "Historical market context only. Correlation does not imply causation and this is not financial advice."
        )
    }

    private func marketWeather(events: [MarketWeatherEventSummary]) -> MarketWeatherSummary {
        MarketWeatherSummary(
            symbols: MarketWeatherService.v1Symbols,
            eventSummaries: events,
            sectorBreadth: nil,
            includedSymbols: ["DIA", "IWM", "QQQ", "SPY"],
            excludedSymbols: [],
            staleSymbols: [],
            partialSymbols: [],
            insufficientSymbols: [],
            coverage: 1,
            provenance: liveProvenance(),
            disclaimer: "Historical market context only. Correlation does not imply causation and this is not financial advice."
        )
    }

    private func portfolioSummary(
        averageReturn: Double?,
        baselineReturn: Double?,
        winRate: Double?,
        confidence: CorrelationConfidence = .moderate,
        displayMode: CorrelationDisplayMode = .marketBackedResult
    ) -> PortfolioCosmicCorrelationSummary {
        PortfolioCosmicCorrelationSummary(
            id: "fullMoon",
            eventName: "Full Moon",
            eventType: .fullMoon,
            eventCount: 6,
            sampleSize: displayMode == .marketBackedResult ? 6 : 0,
            window: CorrelationWindow(daysBefore: 1, daysAfter: 3),
            averagePortfolioReturn: averageReturn,
            medianPortfolioReturn: averageReturn,
            winRate: winRate,
            baselinePortfolioReturn: baselineReturn,
            baselineWinRate: nil,
            volatilityRatio: nil,
            maxDrawdown: nil,
            affectedHoldings: [],
            unavailableHoldings: [],
            includedPortfolioWeight: 1,
            excludedPortfolioWeight: 0,
            provenance: liveProvenance(),
            confidence: confidence,
            displayMode: displayMode,
            disclaimer: "Historical portfolio context only. Correlation does not imply causation and this is not financial advice."
        )
    }

    private func stockSummary(
        symbol: String = "AAPL",
        averageReturn: Double?,
        baselineReturn: Double?,
        winRate: Double?,
        confidence: CorrelationConfidence = .moderate,
        displayMode: CorrelationDisplayMode = .marketBackedResult
    ) -> StockCosmicCorrelationSummary {
        StockCosmicCorrelationSummary(
            id: "\(symbol)-fullMoon",
            symbol: symbol,
            eventName: "Full Moon",
            eventType: .fullMoon,
            eventCount: 6,
            sampleSize: displayMode == .marketBackedResult ? 6 : 0,
            window: CorrelationWindow(daysBefore: 1, daysAfter: 3),
            averageReturn: averageReturn,
            medianReturn: averageReturn,
            winRate: winRate,
            baselineReturn: baselineReturn,
            volatilityRatio: nil,
            maxDrawdown: nil,
            provenance: liveProvenance(),
            confidence: confidence,
            displayMode: displayMode,
            disclaimer: "Historical stock context only. Correlation does not imply causation and this is not financial advice."
        )
    }
}
