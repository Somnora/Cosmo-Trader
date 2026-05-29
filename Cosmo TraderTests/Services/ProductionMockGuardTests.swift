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
