import Foundation
import Testing
@testable import Cosmo_Trader

@MainActor
struct ProductionMockGuardTests {

    @Test("Stock model no longer synthesizes user-facing financial history or stats")
    func stockModelDoesNotGenerateFinancialFixtures() {
        let stock = Stock.sample

        #expect(stock.priceHistory.isEmpty)
        #expect(stock.chartData(for: .month).isEmpty)
        #expect(stock.keyStats == nil)
    }

    @Test("Chart pattern service returns insufficient data when cache is empty")
    func chartPatternsDoNotUseGeneratedOHLCFallback() {
        let service = ChartPatternService.shared
        service.clearCache()

        let candles = service.getOHLCData(for: Stock.sample, days: 365)
        let patterns = service.detectPatterns(ohlc: candles)

        #expect(candles.isEmpty)
        #expect(patterns.isEmpty)
    }

    @Test("Sample historical provenance cannot produce chart correlation metrics")
    func sampleHistoricalProvenanceCannotProduceChartCorrelationMetrics() {
        let summaries = AstroCorrelationService.shared.stockSummaries(
            symbol: "AAPL",
            prices: [
                OHLCData(date: Date(timeIntervalSince1970: 0), open: 100, high: 101, low: 99, close: 100, volume: 1_000),
                OHLCData(date: Date(timeIntervalSince1970: 86_400), open: 101, high: 102, low: 100, close: 101, volume: 1_000),
                OHLCData(date: Date(timeIntervalSince1970: 172_800), open: 102, high: 103, low: 101, close: 102, volume: 1_000)
            ],
            events: [
                AstroOverlayEvent(
                    id: "sample-full-moon",
                    kind: .fullMoon,
                    title: "Full Moon",
                    subtitle: nil,
                    startDate: Date(timeIntervalSince1970: 0),
                    endDate: nil,
                    markerDate: Date(timeIntervalSince1970: 0),
                    intensity: .high,
                    affectedElements: [],
                    affectedSectors: [],
                    iconSystemName: "moon.circle.fill",
                    source: .calculatedMoonPhase,
                    isEstimated: false
                )
            ],
            filterState: AstroOverlayFilterState(eventWindowDays: 1),
            provenance: .sample(reason: "DEBUG screenshot fixture")
        )

        #expect(summaries.first?.averageReturn == nil)
        #expect(summaries.first?.medianReturn == nil)
        #expect(summaries.first?.winRate == nil)
        #expect(summaries.first?.displayMode == .sampleOnly)
    }

    @Test("Upcoming cosmic events do not use fake price or company metadata")
    func upcomingCosmicEventsDoNotUseFakePriceOrCompanyMetadata() {
        let unknownStock = Stock(
            symbol: "NOH",
            name: "No History Corp.",
            currentPrice: 0,
            priceChange: 0,
            percentageChange: 0,
            foundedDate: nil,
            sector: "Unknown"
        )
        let summary = StockUpcomingCosmicEventsService.shared.summary(
            for: unknownStock,
            startDate: date("2026-06-14")
        )

        #expect(!summary.hasCompanySpecificMetadata)
        #expect(!summary.events.isEmpty)
        #expect(summary.events.allSatisfy { ![.moonInSign, .companyBirthMonth, .companyFoundingAnniversary].contains($0.kind) })
        #expect(summary.events.allSatisfy { !$0.sourceLabel.localizedCaseInsensitiveContains("sample") })
        #expect(summary.events.allSatisfy { !$0.whyText.localizedCaseInsensitiveContains("price") })
    }

    @Test("Candle chart mode cannot render sample or synthetic close-only candles")
    func candleChartModeDoesNotUseSampleOrSyntheticCandles() {
        let validCandles = [
            OHLCData(date: Date(timeIntervalSince1970: 0), open: 100, high: 105, low: 98, close: 103, volume: 1_000),
            OHLCData(date: Date(timeIntervalSince1970: 86_400), open: 103, high: 106, low: 101, close: 102, volume: 1_000)
        ]
        let closeOnlyCandles = [
            OHLCData(date: Date(timeIntervalSince1970: 0), open: 100, high: 100, low: 100, close: 100, volume: 1_000),
            OHLCData(date: Date(timeIntervalSince1970: 86_400), open: 101, high: 101, low: 101, close: 101, volume: 1_000)
        ]

        #expect(!StockChartCandleEligibility.canRenderCandles(
            candles: validCandles,
            provenance: .sample(reason: "DEBUG screenshot fixture"),
            completeness: .complete
        ))
        #expect(!StockChartCandleEligibility.canRenderCandles(
            candles: closeOnlyCandles,
            provenance: .live(provider: "Unit Test Provider", fetchedAt: Date(timeIntervalSince1970: 172_800)),
            completeness: .complete
        ))
        #expect(StockChartCandleEligibility.canRenderCandles(
            candles: validCandles,
            provenance: .cached(provider: "Unit Test Provider", fetchedAt: Date(timeIntervalSince1970: 172_800), age: 60 * 60),
            completeness: .complete
        ))
        #expect(!StockChartCandleEligibility.canRenderCandles(
            candles: validCandles,
            provenance: .cached(
                provider: "Unit Test Provider",
                fetchedAt: Date(timeIntervalSince1970: 172_800),
                age: FinancialDataProvenance.defaultCachedStaleInterval + 60
            ),
            completeness: .complete
        ))
    }

    @Test("Stock detail history activation uses provider service without sample fallback")
    func stockDetailHistoryActivationUsesProviderServiceWithoutSampleFallback() async {
        let viewModel = StockDetailHistoryActivationViewModel { _, _ in
            throw HistoricalPriceError.noHistoricalData
        }

        let didLoad = await viewModel.refresh(symbol: "AAPL", timeframe: .month)

        #expect(!didLoad)
        #expect(viewModel.state.provenance == .unavailable(reason: "Provider-backed historical prices unavailable. Try again later."))
        if case .sample = viewModel.state.provenance {
            Issue.record("Stock Detail history activation must not fall back to sample provenance")
        }
        #expect(viewModel.state.contextRows.allSatisfy { !$0.status.localizedCaseInsensitiveContains("sample data") })
        #expect(viewModel.state.contextRows.allSatisfy { !$0.status.localizedCaseInsensitiveContains("sample fallback") })
    }

    @Test("Today share card does not convert sample or unavailable context into provider-backed claims")
    func todayShareCardDoesNotConvertSampleOrUnavailableContextIntoProviderBackedClaims() {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let summary = TodayMarketHoroscopeSummary(
            date: now,
            cosmicContext: TodayCosmicContext(
                headline: "Cosmic context only",
                detail: "Moon phase context without provider-backed market tone.",
                lunarLabel: "New Moon / Aries",
                mercuryLabel: "Mercury Direct",
                marketToneLabel: "Market data unavailable",
                activeEvents: [],
                provenance: .unavailable(reason: "Provider-backed market tone unavailable")
            ),
            marketContext: TodayMarketContext(
                headline: "Market Weather unavailable",
                detail: "Provider-backed market ETF history unavailable.",
                eventName: nil,
                windowLabel: nil,
                eventCount: 0,
                sampleSize: 0,
                includedSymbols: [],
                excludedSymbols: ["SPY", "QQQ", "DIA", "IWM"],
                staleSymbols: [],
                coverage: 0,
                metrics: [],
                sectorBreadth: nil,
                provenance: .unavailable(reason: "Provider-backed market ETF history unavailable"),
                displayMode: .unavailable,
                activation: nil
            ),
            portfolioContext: TodayPortfolioContext(
                headline: "Sample portfolio context is labeled",
                detail: "Demo context only.",
                eventName: nil,
                windowLabel: nil,
                eventCount: 0,
                sampleSize: 0,
                includedPortfolioWeight: 0,
                excludedPortfolioWeight: 1,
                unavailableHoldings: [],
                metrics: [],
                provenance: .sample(reason: "Demo context only, not portfolio data"),
                displayMode: .sampleOnly,
                activation: nil
            ),
            stockContext: TodayStockContext(
                symbol: "WATCH",
                name: "Watchlist setup",
                headline: "Stock lens needs a ticker",
                detail: "Add a watchlist symbol.",
                eventName: nil,
                windowLabel: nil,
                eventCount: 0,
                sampleSize: 0,
                metrics: [],
                provenance: .unavailable(reason: "No portfolio or watchlist stock available"),
                displayMode: .unavailable,
                source: nil,
                activation: nil
            ),
            firstRunSetup: TodayFirstRunSetupState(isSkipped: false, steps: []),
            dataCoverage: TodayDataCoverage(
                headline: "Waiting on provider-backed history",
                detail: "No provider-backed history is available yet.",
                rows: [],
                explainers: []
            ),
            primaryAction: nil,
            provenance: .mixed(reason: "Today combines unavailable and sample-labeled datasets."),
            disclaimer: "Historical context only. Correlation does not imply causation and this is not financial advice."
        )

        let card = TodayMarketHoroscopeShareCardContent.make(from: summary)

        #expect(card.marketLine.metrics.isEmpty)
        #expect(card.portfolioLine?.metrics.isEmpty == true)
        #expect(card.stockLine?.metrics.isEmpty == true)
        #expect(card.marketLine.provenance.indicatorLabel == "Unavailable")
        #expect(card.portfolioLine?.provenance.indicatorLabel == "Sample data")
        #expect(!card.searchableText.localizedCaseInsensitiveContains("Finnhub live"))
        #expect(!card.searchableText.localizedCaseInsensitiveContains("provider-backed basket history cleared"))
        #expect(!card.searchableText.localizedCaseInsensitiveContains("provider-backed holding history cleared"))
    }

    @Test("Cosmic pattern interpreter does not create notes without provider candles")
    func cosmicPatternInterpreterDoesNotUseGeneratedCandles() {
        ChartPatternService.shared.clearCache()

        let insights = CosmicPatternInterpreter.shared.getInsights(
            for: Stock.sample,
            userSign: .aries
        )

        #expect(insights.isEmpty)
    }

    @Test("IPO service empty state does not load fictional IPOs")
    func ipoServiceDoesNotUseMockFallback() {
        let service = IPOService.testingInstance(loadCache: false)

        #expect(service.getUpcomingIPOs().isEmpty)
        #expect(service.getFeaturedIPOs().isEmpty)
        #expect(service.availableSectors.isEmpty)
        #expect(service.dataProvenance == .unavailable(reason: "IPO calendar unavailable"))
    }

    @Test("Earnings service empty state does not load fake earnings")
    func earningsServiceDoesNotUseMockFallback() {
        let service = EarningsService.testingInstance(loadCache: false)

        #expect(service.getEarningsThisWeek().isEmpty)
        #expect(service.getNextEarnings(for: "AAPL") == nil)
        #expect(service.dataProvenance == .unavailable(reason: "Earnings calendar unavailable"))
    }

    private func date(_ value: String) -> Date {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: value) ?? Date(timeIntervalSince1970: 0)
    }

    @Test("Provider-dependent cosmic mood factors do not simulate market data")
    func cosmicMoodDoesNotSimulateMarketFactors() {
        let service = CosmicMoodService.shared
        let mood = service.getCurrentMood()
        let providerDependentFactors = mood.factors.filter {
            $0.category == .market || $0.category == .volatility || $0.category == .momentum
        }

        #expect(!providerDependentFactors.isEmpty)
        #expect(providerDependentFactors.allSatisfy { $0.value == nil })
        #expect(providerDependentFactors.allSatisfy { $0.description.lowercased().contains("unavailable") })
        #expect(mood.value == nil)
        #expect(mood.displayMode == .cosmicContextOnly)
        #expect(mood.marketDataCoverage == 0)
        #expect(mood.marketToneText == "Cosmic context only")
        #expect(!mood.isMarketBacked)
        #expect(service.getMoodHistory(days: 30).isEmpty)
    }

    @Test("Daily reading does not quote unavailable cosmic mood as a market score")
    func dailyReadingDoesNotQuoteUnavailableMoodScore() {
        let reading = DailyFinancialReadingService.shared.compose(for: .sampleWithHoldings)

        #expect(reading.marketTone == "Cosmic context only")
        #expect(!reading.marketCosmicPosture.contains("/100"))
        #expect(!reading.marketCosmicPosture.localizedCaseInsensitiveContains("Market tone is neutral"))
        #expect(!reading.marketCosmicPosture.localizedCaseInsensitiveContains("Risk appetite is elevated"))
    }

    @Test("Cosmic ticker defaults to cosmic-only items without mock stock prices")
    func cosmicTickerDoesNotDefaultToMockStocks() {
        let items = CosmicTickerService.shared.generateTickerItems()

        #expect(!items.isEmpty)
        #expect(items.allSatisfy {
            if case .stock = $0.type {
                return false
            }
            return true
        })
    }

    @Test("Daily brief does not summarize sample stock movement as news")
    func dailyBriefDoesNotUseSamplePriceMovement() {
        let brief = DailyBriefService.shared.generateBrief(for: .sampleWithHoldings)

        #expect(brief.watchlistHighlights.isEmpty)
        #expect(brief.newsAlerts.isEmpty)
    }

}
