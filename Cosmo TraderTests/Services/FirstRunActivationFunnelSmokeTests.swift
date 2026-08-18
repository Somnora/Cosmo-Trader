import Foundation
import Testing
@testable import Cosmo_Trader

extension AppStatePersistenceSuites {
    @MainActor
    struct FirstRunActivationFunnelSmokeTests {
        private let composer = TodayMarketHoroscopeComposer()

        @Test("Today first-run funnel routes to setup without numeric or fake claims")
        func todayFirstRunFunnelRoutesToSetupWithoutNumericOrFakeClaims() {
            let summary = composer.compose(
                date: date("2026-06-01"),
                user: user(portfolio: [], watchlist: []),
                mood: moodUnavailable(),
                lunarData: lunarData(),
                mercuryStatus: "Mercury Direct",
                activeEventTitles: [],
                portfolioSummaries: [],
                stockCandidate: nil,
                marketWeather: nil
            )

            #expect(summary.primaryAction?.primaryActionTitle == "ADD HOLDING")
            #expect(summary.primaryAction?.secondaryActionTitle == "IMPORT PORTFOLIO")
            #expect(summary.primaryAction?.tertiaryActionTitle == "ADD WATCHLIST SYMBOLS")
            #expect(summary.marketContext.metrics.isEmpty)
            #expect(summary.portfolioContext.metrics.isEmpty)
            #expect(summary.stockContext?.metrics.isEmpty == true)
            #expect(summary.dataCoverage.rows.contains { $0.provenance.indicatorLabel == "Unavailable" })
            #expect(summary.dataCoverage.detail.contains("provider-backed history clears"))

            let appState = AppState(user: user(portfolio: [], watchlist: []))

            appState.requestNavigation(.portfolioAddHolding)
            #expect(appState.selectedTab == .portfolio)
            #expect(appState.pendingNavigationIntent == .portfolioAddHolding)

            appState.requestNavigation(.portfolioImport)
            #expect(appState.selectedTab == .portfolio)
            #expect(appState.pendingNavigationIntent == .portfolioImport)

            appState.requestNavigation(.discoverSearch)
            #expect(appState.selectedTab == .discover)
            #expect(appState.pendingNavigationIntent == .discoverSearch)
        }

        @Test("Portfolio import and watchlist setup persist real user data")
        func portfolioImportAndWatchlistSetupPersistRealUserData() throws {
            let appState = AppState(user: user(portfolio: [], watchlist: []))
            let parsedHoldings = [
                ParsedHolding(
                    symbol: "AAPL",
                    shares: 4,
                    marketValue: 720,
                    costBasisPerShare: 150,
                    confidence: 0.99,
                    rawSource: "AAPL 4 720"
                ),
                ParsedHolding(
                    symbol: "ZZZZ",
                    shares: 2,
                    marketValue: nil,
                    costBasisPerShare: 25,
                    confidence: 0.90,
                    rawSource: "ZZZZ 2"
                )
            ]

            PortfolioImportService.commitPortfolio(
                with: parsedHoldings,
                in: appState,
                mode: .replace
            )
            appState.addToWatchlist("MSFT")

            let savedUser = try #require(appState.currentUser)
            let decoded = try JSONDecoder().decode(
                UserProfile.self,
                from: JSONEncoder().encode(savedUser)
            )

            let aapl = try #require(decoded.portfolio.first { $0.symbol == "AAPL" })
            let unknown = try #require(decoded.portfolio.first { $0.symbol == "ZZZZ" })

            #expect(aapl.sharesOwned == 4)
            #expect(aapl.currentPrice == 180)
            #expect(aapl.purchasePrice == 150)
            #expect(unknown.currentPrice == 0)
            #expect(unknown.foundedDate == nil)
            #expect(unknown.foundedZodiacSign == nil)
            #expect(decoded.watchlist.contains("MSFT"))
        }

        @Test("Provider history load requests real provider candles and does not create sample data")
        func providerHistoryLoadRequestsProviderCandlesWithoutSampleFallback() async throws {
            let now = date("2026-06-01")
            let cache = HistoricalPriceCache(directoryURL: temporaryCacheURL(), nowProvider: { now })
            defer { try? cache.removeAll() }

            var requestedSymbols: [String] = []
            let service = HistoricalPriceService.testingInstance(
                historicalPriceCache: cache,
                nowProvider: { now },
                candleFetcher: { symbol, _, from, _ in
                    requestedSymbols.append(symbol)
                    return candleResponse(start: from, count: 230)
                }
            )

            let result = try await service.fetchHistoricalPriceResult(symbol: "AAPL", timeframe: .year)

            #expect(requestedSymbols == ["AAPL"])
            #expect(result.source == .provider)
            #expect(result.provenance.isProviderBacked)
            #expect(result.provenance.indicatorLabel.localizedCaseInsensitiveContains("live"))
            #expect(result.completeness.allowsNumericCorrelationClaims)
            #expect(result.data.count == 230)
        }

        @Test("Stock Detail context stays locked on insufficient history")
        func stockDetailContextStaysLockedOnInsufficientHistory() {
            let dataset = insufficientDataset(symbol: "AAPL")
            let events = [pointEvent(kind: .fullMoon, on: "2026-05-15")]

            let correlation = AstroCorrelationService.shared.stockSummaries(
                symbol: dataset.symbol,
                prices: dataset.ohlcData,
                events: events,
                filterState: AstroOverlayFilterState(eventWindowDays: 1),
                provenance: dataset.provenance,
                completeness: dataset.completeness
            )
            let technical = StockTechnicalAnalysisService.shared.summary(for: dataset)

            #expect(correlation.first?.displayMode == .insufficientDataset)
            #expect(correlation.first?.averageReturn == nil)
            #expect(correlation.first?.winRate == nil)
            #expect(technical.hasNumericClaims == false)
            #expect(technical.displayMode == .insufficient(reason: "Provider returned fewer than two historical candles"))
            #expect(technical.provenance.indicatorLabel == "Unavailable")
        }

        @Test("Stock Detail context unlocks only after provider-backed gates pass")
        func stockDetailContextUnlocksOnlyAfterProviderBackedGatesPass() {
            let fetchedAt = date("2026-06-01")
            let candles = candles(start: date("2026-01-01"), count: 230)
            let dataset = HistoricalPriceDataset.providerBacked(
                symbol: "AAPL",
                candles: candles,
                provider: FinancialDataProvenance.finnhubProvider,
                fetchedAt: fetchedAt,
                requestedRange: DateInterval(start: candles.first!.date, end: candles.last!.date),
                provenance: .live(provider: FinancialDataProvenance.finnhubProvider, fetchedAt: fetchedAt)
            )
            let events = [
                pointEvent(kind: .fullMoon, on: "2026-02-15"),
                pointEvent(kind: .fullMoon, on: "2026-03-15"),
                pointEvent(kind: .fullMoon, on: "2026-04-15")
            ]

            let correlation = AstroCorrelationService.shared.stockSummaries(
                symbol: dataset.symbol,
                prices: dataset.ohlcData,
                events: events,
                filterState: AstroOverlayFilterState(eventWindowDays: 1),
                provenance: dataset.provenance,
                completeness: dataset.completeness
            )
            let technical = StockTechnicalAnalysisService.shared.summary(for: dataset)

            #expect(dataset.provenance.isProviderBacked)
            #expect(dataset.completeness.allowsNumericCorrelationClaims)
            #expect(correlation.first?.displayMode == .marketBackedResult)
            #expect(correlation.first?.averageReturn != nil)
            #expect(correlation.first?.winRate != nil)
            #expect(technical.hasNumericClaims)
            #expect(technical.metrics?.movingAverage20 != nil)
            #expect(technical.metrics?.movingAverage50 != nil)
            #expect(technical.metrics?.movingAverage200 != nil)
            #expect(technical.metrics?.rsi14 != nil)
        }

        @Test("First-run funnel copy stays context-only and non-advisory")
        func firstRunFunnelCopyStaysContextOnlyAndNonAdvisory() {
            let summary = composer.compose(
                date: date("2026-06-01"),
                user: user(portfolio: [], watchlist: []),
                mood: moodUnavailable(),
                lunarData: lunarData(),
                mercuryStatus: "Mercury Direct",
                activeEventTitles: [],
                portfolioSummaries: [],
                stockCandidate: nil,
                marketWeather: nil
            )
            let technical = StockTechnicalAnalysisService.shared.unavailableSummary(
                symbol: "AAPL",
                reason: "Provider-backed historical candles not loaded"
            )

            let copy = [
                summary.marketContext.headline,
                summary.marketContext.detail,
                summary.marketContext.activation?.title ?? "",
                summary.marketContext.activation?.detail ?? "",
                summary.portfolioContext.headline,
                summary.portfolioContext.detail,
                summary.portfolioContext.activation?.title ?? "",
                summary.portfolioContext.activation?.detail ?? "",
                summary.stockContext?.headline ?? "",
                summary.stockContext?.detail ?? "",
                summary.stockContext?.activation?.title ?? "",
                summary.stockContext?.activation?.detail ?? "",
                summary.dataCoverage.headline,
                summary.dataCoverage.detail,
                summary.disclaimer,
                technical.headline,
                technical.explanation
            ].joined(separator: "\n").lowercased()

            #expect(copy.contains("provider-backed"))
            #expect(copy.contains("historical"))
            #expect(copy.contains("not financial advice"))

            for forbidden in forbiddenTradingInstructionFragments {
                #expect(!copy.contains(forbidden))
            }
        }

        private var forbiddenTradingInstructionFragments: [String] {
            [
                "buy signal",
                "sell signal",
                "take profits",
                "reduce exposure",
                "reduce position",
                "position size",
                "smaller position",
                "delay major decisions",
                "high-risk positions",
                "expected upside",
                "expected downside"
            ]
        }

        private func user(
            portfolio: [Stock]? = nil,
            watchlist: [String] = ["TSLA"]
        ) -> UserProfile {
            UserProfile(
                displayName: "Funnel Tester",
                email: "funnel.tester@example.com",
                birthDate: date("1990-04-12"),
                portfolio: portfolio ?? [stock(symbol: "AAPL", sharesOwned: 2)],
                watchlist: watchlist
            )
        }

        private func stock(symbol: String, sharesOwned: Double) -> Stock {
            var stock = MockStockData.knownStocks.first { $0.symbol == symbol } ?? Stock(
                symbol: symbol,
                name: "\(symbol) Inc.",
                currentPrice: 100,
                priceChange: 0,
                percentageChange: 0,
                sharesOwned: sharesOwned,
                purchasePrice: 90,
                purchaseDate: date("2026-01-01"),
                foundedDate: nil,
                sector: "Unknown"
            )
            stock.sharesOwned = sharesOwned
            stock.purchasePrice = 90
            return stock
        }

        private func moodUnavailable() -> CosmicMoodData {
            CosmicMoodData(
                date: date("2026-06-01"),
                value: nil,
                factors: [],
                label: "Market data unavailable",
                provenance: .unavailable(reason: "Provider-backed market factors unavailable"),
                marketDataCoverage: 0,
                unavailableFactorWeight: 1,
                displayMode: .unavailable
            )
        }

        private func lunarData() -> LunarData {
            LunarData(
                date: date("2026-06-01"),
                phase: .waxingGibbous,
                illumination: 0.72,
                age: 10,
                moonSign: .aries,
                isWaxing: true
            )
        }

        private func insufficientDataset(symbol: String) -> HistoricalPriceDataset {
            let fetchedAt = date("2026-06-01")
            return HistoricalPriceDataset.providerBacked(
                symbol: symbol,
                candles: [candle(on: fetchedAt, close: 100)],
                provider: FinancialDataProvenance.finnhubProvider,
                fetchedAt: fetchedAt,
                requestedRange: DateInterval(start: date("2026-05-01"), end: fetchedAt),
                provenance: .live(provider: FinancialDataProvenance.finnhubProvider, fetchedAt: fetchedAt)
            )
        }

        private func pointEvent(kind: AstroOverlayEventKind, on value: String) -> AstroOverlayEvent {
            let eventDate = date(value)
            return AstroOverlayEvent(
                id: "\(kind.rawValue)-\(value)",
                kind: kind,
                title: kind.displayName,
                subtitle: nil,
                startDate: eventDate,
                endDate: nil,
                markerDate: eventDate,
                intensity: .medium,
                affectedElements: [],
                affectedSectors: [],
                iconSystemName: kind.iconSystemName,
                source: .calculatedMoonPhase,
                isEstimated: false
            )
        }

        private func candleResponse(start: Date, count: Int) -> FinnhubCandleResponse {
            let generated = candles(start: start, count: count)
            return FinnhubCandleResponse(
                s: "ok",
                t: generated.map { Int($0.date.timeIntervalSince1970) },
                o: generated.map(\.open),
                h: generated.map(\.high),
                l: generated.map(\.low),
                c: generated.map(\.close),
                v: generated.map(\.volume)
            )
        }

        private func candles(start: Date, count: Int) -> [OHLCData] {
            (0..<count).map { index in
                let close = 100 + Double(index) * 0.35 + sin(Double(index) / 6)
                let date = Calendar(identifier: .gregorian).date(byAdding: .day, value: index, to: start) ?? start
                return candle(on: date, close: close)
            }
        }

        private func candle(on date: Date, close: Double) -> OHLCData {
            OHLCData(
                date: date,
                open: close - 0.4,
                high: close + 1.2,
                low: max(0.01, close - 1.1),
                close: close,
                volume: 1_000_000
            )
        }

        private func temporaryCacheURL() -> URL {
            FileManager.default.temporaryDirectory
                .appendingPathComponent("cosmo-first-run-funnel-\(UUID().uuidString)", isDirectory: true)
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
}
