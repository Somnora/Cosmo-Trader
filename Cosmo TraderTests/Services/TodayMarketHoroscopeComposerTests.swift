import Foundation
import Testing
@testable import Cosmo_Trader

@MainActor
struct TodayMarketHoroscopeComposerTests {
    private let composer = TodayMarketHoroscopeComposer()

    @Test("Market-backed Today summary exposes source-labeled portfolio and stock metrics")
    func marketBackedSummaryExposesMetrics() {
        let fetchedAt = date("2026-05-30")
        let provenance: FinancialDataProvenance = .live(provider: FinancialDataProvenance.finnhubProvider, fetchedAt: fetchedAt)

        let summary = composer.compose(
            date: fetchedAt,
            user: user(),
            mood: mood(value: 68, provenance: provenance),
            lunarData: lunarData(),
            mercuryStatus: "Mercury Direct",
            activeEventTitles: ["Full Moon"],
            portfolioSummaries: [
                portfolioSummary(
                    provenance: provenance,
                    displayMode: .marketBackedResult,
                    includedWeight: 0.82,
                    averageReturn: 1.4,
                    winRate: 0.67
                )
            ],
            stockCandidate: TodayStockCandidate(
                stock: stock(symbol: "AAPL", sharesOwned: 2),
                summaries: [
                    stockSummary(
                        provenance: provenance,
                        displayMode: .marketBackedResult,
                        averageReturn: 2.1,
                        winRate: 0.75
                    )
                ],
                provenance: provenance,
                completeness: .complete
            ),
            marketWeather: marketWeatherSummary(
                provenance: provenance,
                displayMode: .marketBackedResult,
                coverage: 1,
                averageReturn: 0.8,
                winRate: 0.58
            )
        )

        #expect(summary.marketContext.displayMode == .marketBacked)
        #expect(summary.marketContext.metrics.map(\.label).contains("AVG MKT"))
        #expect(summary.portfolioContext.displayMode == .marketBacked)
        #expect(summary.portfolioContext.metrics.map(\.label).contains("AVG PORT"))
        #expect(summary.portfolioContext.metrics.map(\.label).contains("WIN"))
        #expect(summary.stockContext?.displayMode == .marketBacked)
        #expect(summary.stockContext?.metrics.map(\.label).contains("AVG") == true)
        #expect(summary.provenance.isProviderBacked)
        #expect(summary.disclaimer.contains("not financial advice"))
    }

    @Test("No portfolio stays setup-only with no numeric portfolio metrics")
    func noPortfolioStaysSetupOnlyWithNoNumericPortfolioMetrics() {
        let fetchedAt = date("2026-05-30")

        let summary = composer.compose(
            date: fetchedAt,
            user: user(portfolio: [], watchlist: []),
            mood: mood(value: nil, provenance: .unavailable(reason: "Provider-backed market factors unavailable")),
            lunarData: lunarData(),
            mercuryStatus: "Mercury Direct",
            activeEventTitles: [],
            portfolioSummaries: [],
            stockCandidate: nil
        )

        #expect(summary.portfolioContext.displayMode == .setupRequired)
        #expect(summary.portfolioContext.metrics.isEmpty)
        #expect(summary.portfolioContext.includedPortfolioWeight == 0)
        #expect(summary.portfolioContext.excludedPortfolioWeight == 0)
        #expect(summary.portfolioContext.provenance.indicatorLabel == "Unavailable")
        #expect(summary.portfolioContext.activation?.primaryActionTitle == "ADD HOLDING")
        #expect(summary.portfolioContext.activation?.secondaryActionTitle == "IMPORT PORTFOLIO")
        #expect(summary.portfolioContext.activation?.tertiaryActionTitle == "ADD WATCHLIST SYMBOLS")
        #expect(summary.portfolioContext.activation?.detail.contains("add a holding manually") == true)
        #expect(summary.portfolioContext.activation?.actionItems.contains("Add holding manually") == true)
        #expect(summary.portfolioContext.activation?.actionItems.contains("Import portfolio") == true)
        #expect(summary.portfolioContext.activation?.actionItems.contains("Add watchlist symbols") == true)
        #expect(summary.primaryAction?.primaryActionTitle == "ADD HOLDING")
        #expect(summary.primaryAction?.secondaryActionTitle == "IMPORT PORTFOLIO")
        #expect(summary.primaryAction?.tertiaryActionTitle == "ADD WATCHLIST SYMBOLS")
        #expect(summary.stockContext?.displayMode == .unavailable)
        #expect(summary.stockContext?.activation?.primaryActionTitle == "ADD WATCHLIST SYMBOLS")
        #expect(summary.stockContext?.activation?.secondaryActionTitle == "OPEN DISCOVER / SEARCH")
        #expect(summary.dataCoverage.rows.contains { $0.label == "WATCH history" && $0.provenance.indicatorLabel == "Unavailable" })
    }

    @Test("Below fifty percent portfolio coverage blocks Today portfolio context metrics")
    func belowFiftyPercentPortfolioCoverageBlocksTodayPortfolioContextMetrics() {
        let fetchedAt = date("2026-05-30")
        let provenance: FinancialDataProvenance = .mixed(reason: "Only 49% of portfolio value has provider-backed historical prices")

        let summary = composer.compose(
            date: fetchedAt,
            user: user(),
            mood: mood(value: nil, provenance: .unavailable(reason: "Provider-backed market factors unavailable")),
            lunarData: lunarData(),
            mercuryStatus: "Mercury Direct",
            activeEventTitles: [],
            portfolioSummaries: [
                portfolioSummary(
                    provenance: provenance,
                    displayMode: .insufficientSample,
                    includedWeight: 0.49,
                    averageReturn: 8.8,
                    winRate: 0.88
                )
            ],
            stockCandidate: nil
        )

        #expect(summary.portfolioContext.displayMode == .insufficientCoverage)
        #expect(summary.portfolioContext.metrics.isEmpty)
        #expect(!summary.portfolioContext.metrics.map(\.label).contains("AVG PORT"))
        #expect(summary.portfolioContext.detail.contains("At least 50% coverage"))
        #expect(summary.portfolioContext.includedPortfolioWeight == 0.49)
        #expect(summary.portfolioContext.activation?.primaryActionTitle == "REFRESH HOLDING HISTORY")
        #expect(summary.portfolioContext.activation?.secondaryActionTitle == "ADD HOLDING")
        #expect(summary.portfolioContext.activation?.actionItems.contains("Refresh provider-backed holding history") == true)
        #expect(summary.portfolioContext.activation?.actionItems.contains("Never create sample candles") == true)
    }

    @Test("Partial portfolio coverage stays context-only below seventy percent")
    func partialPortfolioCoverageWithholdsHeadlineMetrics() {
        let fetchedAt = date("2026-05-30")
        let provenance: FinancialDataProvenance = .mixed(reason: "Only 60% of portfolio value has provider-backed historical prices")

        let summary = composer.compose(
            date: fetchedAt,
            user: user(),
            mood: mood(value: nil, provenance: .unavailable(reason: "Provider-backed market factors unavailable")),
            lunarData: lunarData(),
            mercuryStatus: "Mercury Direct",
            activeEventTitles: [],
            portfolioSummaries: [
                portfolioSummary(
                    provenance: provenance,
                    displayMode: .partialCoverage,
                    includedWeight: 0.60,
                    averageReturn: 9.9,
                    winRate: 0.99
                )
            ],
            stockCandidate: nil
        )

        #expect(summary.portfolioContext.displayMode == .partialContext)
        #expect(summary.portfolioContext.metrics.isEmpty)
        #expect(!summary.portfolioContext.metrics.map(\.label).contains("AVG PORT"))
        #expect(summary.portfolioContext.detail.contains("70%"))
        #expect(summary.portfolioContext.includedPortfolioWeight == 0.60)
        #expect(summary.portfolioContext.activation?.primaryActionTitle == "REFRESH HOLDING HISTORY")
    }

    @Test("Exactly seventy percent portfolio coverage can render Today portfolio metrics")
    func exactlySeventyPercentPortfolioCoverageCanRenderTodayPortfolioMetrics() {
        let fetchedAt = date("2026-05-30")
        let provenance: FinancialDataProvenance = .live(provider: FinancialDataProvenance.finnhubProvider, fetchedAt: fetchedAt)

        let summary = composer.compose(
            date: fetchedAt,
            user: user(),
            mood: mood(value: 62, provenance: provenance),
            lunarData: lunarData(),
            mercuryStatus: "Mercury Direct",
            activeEventTitles: ["Full Moon"],
            portfolioSummaries: [
                portfolioSummary(
                    provenance: provenance,
                    displayMode: .marketBackedResult,
                    includedWeight: 0.70,
                    averageReturn: 1.2,
                    winRate: 0.64
                )
            ],
            stockCandidate: nil
        )

        #expect(summary.portfolioContext.displayMode == .marketBacked)
        #expect(summary.portfolioContext.metrics.map(\.label).contains("AVG PORT"))
        #expect(summary.portfolioContext.metrics.map(\.label).contains("WIN"))
        #expect(summary.portfolioContext.includedPortfolioWeight == 0.70)
        #expect(summary.portfolioContext.detail.contains("Provider-backed history covers 70%"))
    }

    @Test("Sample and unavailable stock context cannot produce numeric metrics")
    func unsafeStockContextWithholdsMetrics() {
        let unsafeSummary = stockSummary(
            provenance: .sample(reason: "Preview fixture"),
            displayMode: .sampleOnly,
            averageReturn: 12.5,
            winRate: 1
        )

        let context = composer.makeStockContext(
            candidate: TodayStockCandidate(
                stock: stock(symbol: "TSLA", sharesOwned: 0),
                summaries: [unsafeSummary],
                provenance: .sample(reason: "Preview fixture"),
                completeness: .complete
            )
        )

        #expect(context.displayMode == .sampleOnly)
        #expect(context.metrics.isEmpty)
        #expect(context.detail.contains("No historical correlation claim is shown"))
        #expect(context.activation?.detail.contains("Sample data is demo context only") == true)
    }

    @Test("No market data state offers provider-backed market history refresh without metrics")
    func noMarketDataStateOffersProviderBackedRefreshWithoutMetrics() {
        let summary = composer.compose(
            user: user(),
            mood: mood(value: nil, provenance: .unavailable(reason: "Provider-backed market factors unavailable")),
            lunarData: lunarData(),
            mercuryStatus: "Mercury Direct",
            activeEventTitles: [],
            portfolioSummaries: [],
            stockCandidate: nil,
            marketWeather: nil
        )

        #expect(summary.marketContext.displayMode == .unavailable)
        #expect(summary.marketContext.metrics.isEmpty)
        #expect(summary.marketContext.activation?.primaryActionTitle == "FETCH MARKET HISTORY")
        #expect(summary.marketContext.activation?.detail.contains("provider/cache path") == true)
        #expect(summary.marketContext.activation?.actionItems.contains("Fetch SPY / QQQ / DIA / IWM history") == true)
        #expect(summary.marketContext.activation?.actionItems.contains("Show loading and provider/cache errors here") == true)
        #expect(summary.marketContext.activation?.actionItems.contains("Do not create sample market data") == true)
        #expect(!summary.marketContext.activation!.detail.localizedCaseInsensitiveContains("sample"))
    }

    @Test("Holdings without history offer provider-backed history refresh")
    func holdingsWithoutHistoryOfferProviderBackedHistoryRefresh() {
        let summary = composer.compose(
            user: user(),
            mood: mood(value: nil, provenance: .unavailable(reason: "Provider-backed market factors unavailable")),
            lunarData: lunarData(),
            mercuryStatus: "Mercury Direct",
            activeEventTitles: [],
            portfolioSummaries: [],
            stockCandidate: nil,
            marketWeather: nil
        )

        #expect(summary.portfolioContext.displayMode == .unavailable)
        #expect(summary.portfolioContext.metrics.isEmpty)
        #expect(summary.portfolioContext.activation?.title == "Load holding history")
        #expect(summary.portfolioContext.activation?.primaryActionTitle == "REFRESH HOLDING HISTORY")
        #expect(summary.portfolioContext.activation?.actionItems.contains("Refresh provider-backed holding history") == true)
        #expect(summary.portfolioContext.activation?.actionItems.contains("Show symbols that still need data") == true)
        #expect(summary.portfolioContext.activation?.actionItems.contains("Never create sample candles") == true)
        #expect(summary.portfolioContext.unavailableHoldings.contains("AAPL"))
    }

    @Test("One-glance primary CTA prioritizes market history after portfolio and stock are ready")
    func oneGlancePrimaryCTAPrioritizesMarketHistoryWhenOtherLensesAreReady() {
        let fetchedAt = date("2026-05-30")
        let provenance: FinancialDataProvenance = .live(provider: FinancialDataProvenance.finnhubProvider, fetchedAt: fetchedAt)

        let summary = composer.compose(
            date: fetchedAt,
            user: user(),
            mood: mood(value: 62, provenance: provenance),
            lunarData: lunarData(),
            mercuryStatus: "Mercury Direct",
            activeEventTitles: ["Full Moon"],
            portfolioSummaries: [
                portfolioSummary(
                    provenance: provenance,
                    displayMode: .marketBackedResult,
                    includedWeight: 0.82,
                    averageReturn: 1.1,
                    winRate: 0.6
                )
            ],
            stockCandidate: TodayStockCandidate(
                stock: stock(symbol: "AAPL", sharesOwned: 0),
                summaries: [
                    stockSummary(
                        provenance: provenance,
                        displayMode: .marketBackedResult,
                        averageReturn: 0.9,
                        winRate: 0.55
                    )
                ],
                provenance: provenance,
                completeness: .complete
            ),
            marketWeather: nil
        )

        #expect(summary.marketContext.displayMode == .unavailable)
        #expect(summary.portfolioContext.displayMode == .marketBacked)
        #expect(summary.stockContext?.displayMode == .marketBacked)
        #expect(summary.primaryAction?.primaryActionTitle == "FETCH MARKET HISTORY")
        #expect(summary.primaryAction?.actionItems.contains("Do not create sample market data") == true)
    }

    @Test("Market refresh activation never turns unsafe market weather into metrics")
    func marketRefreshActivationDoesNotCreateFakeMetrics() {
        let summary = composer.compose(
            user: user(),
            mood: mood(value: nil, provenance: .unavailable(reason: "Provider-backed market factors unavailable")),
            lunarData: lunarData(),
            mercuryStatus: "Mercury Direct",
            activeEventTitles: [],
            portfolioSummaries: [],
            stockCandidate: nil,
            marketWeather: marketWeatherSummary(
                provenance: .unavailable(reason: "Provider-backed market ETF history unavailable"),
                displayMode: .unavailable,
                coverage: 0,
                averageReturn: 4.2,
                winRate: 0.99
            )
        )

        #expect(summary.marketContext.displayMode == .unavailable)
        #expect(summary.marketContext.metrics.isEmpty)
        #expect(!summary.marketContext.metrics.map(\.label).contains("AVG MKT"))
        #expect(summary.marketContext.activation?.primaryActionTitle == "FETCH MARKET HISTORY")
        #expect(summary.marketContext.activation?.actionItems.contains("Do not create sample market data") == true)
    }

    @Test("Data label guide explains unavailable sample stored cached partial and insufficient")
    func dataLabelGuideExplainsSourceStates() {
        let summary = composer.compose(
            user: user(portfolio: [], watchlist: []),
            mood: mood(value: nil, provenance: .unavailable(reason: "Provider-backed market factors unavailable")),
            lunarData: lunarData(),
            mercuryStatus: "Mercury Direct",
            activeEventTitles: [],
            portfolioSummaries: [],
            stockCandidate: nil
        )

        let labels = summary.dataCoverage.explainers.map(\.label)
        #expect(labels.contains("Unavailable"))
        #expect(labels.contains("Sample data"))
        #expect(labels.contains("Stored data"))
        #expect(labels.contains("Cached/stale"))
        #expect(labels.contains("Partial"))
        #expect(labels.contains("Insufficient"))
        #expect(summary.dataCoverage.explainers.contains { $0.label == "Unavailable" && $0.detail == "Provider has not returned enough data yet." })
        #expect(summary.dataCoverage.explainers.contains { $0.label == "Sample data" && $0.detail == "Demo context only, not market data." })
        #expect(summary.dataCoverage.explainers.contains { $0.label == "Stored data" && $0.detail == "Saved locally from your setup." })
        #expect(summary.dataCoverage.explainers.contains { $0.label == "Cached/stale" && $0.detail == "Provider-backed data saved earlier." })
        #expect(summary.dataCoverage.explainers.contains { $0.label == "Partial" && $0.detail == "Some required data is missing." })
        #expect(summary.dataCoverage.explainers.contains { $0.label == "Insufficient" && $0.detail == "Not enough history for a reliable context view." })
    }

    @Test("Today activation routing opens the nearest add import or search tab")
    func todayActivationRoutingSelectsSpecificDestinations() {
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

    @Test("No watchlist stock state offers watchlist and portfolio setup actions")
    func noWatchlistStockStateOffersSetupActions() {
        let summary = composer.compose(
            user: user(portfolio: [], watchlist: []),
            mood: mood(value: nil, provenance: .unavailable(reason: "Provider-backed market factors unavailable")),
            lunarData: lunarData(),
            mercuryStatus: "Mercury Direct",
            activeEventTitles: [],
            portfolioSummaries: [],
            stockCandidate: nil
        )

        #expect(summary.stockContext?.symbol == "WATCH")
        #expect(summary.stockContext?.metrics.isEmpty == true)
        #expect(summary.stockContext?.activation?.primaryActionTitle == "ADD WATCHLIST SYMBOLS")
        #expect(summary.stockContext?.activation?.secondaryActionTitle == "OPEN DISCOVER / SEARCH")
        #expect(summary.stockContext?.activation?.actionItems.contains("Add symbol") == true)
        #expect(summary.stockContext?.activation?.actionItems.contains("Open Discover/Search") == true)
        #expect(summary.stockContext?.activation?.actionItems.contains("Provider-backed stock history unlocks this lens") == true)
        #expect(summary.stockContext?.detail.contains("provider-backed history") == true)
    }

    @Test("One-glance primary CTA can focus the watchlist when market and portfolio are ready")
    func oneGlancePrimaryCTACanFocusWatchlistWhenOtherLensesAreReady() {
        let fetchedAt = date("2026-05-30")
        let provenance: FinancialDataProvenance = .live(provider: FinancialDataProvenance.finnhubProvider, fetchedAt: fetchedAt)

        let summary = composer.compose(
            date: fetchedAt,
            user: user(watchlist: []),
            mood: mood(value: 62, provenance: provenance),
            lunarData: lunarData(),
            mercuryStatus: "Mercury Direct",
            activeEventTitles: ["Full Moon"],
            portfolioSummaries: [
                portfolioSummary(
                    provenance: provenance,
                    displayMode: .marketBackedResult,
                    includedWeight: 0.82,
                    averageReturn: 1.1,
                    winRate: 0.6
                )
            ],
            stockCandidate: nil,
            marketWeather: marketWeatherSummary(
                provenance: provenance,
                displayMode: .marketBackedResult,
                coverage: 1,
                averageReturn: 0.8,
                winRate: 0.58
            )
        )

        #expect(summary.marketContext.displayMode == .marketBacked)
        #expect(summary.portfolioContext.displayMode == .marketBacked)
        #expect(summary.stockContext?.displayMode == .unavailable)
        #expect(summary.primaryAction?.primaryActionTitle == "ADD WATCHLIST SYMBOLS")
        #expect(summary.primaryAction?.secondaryActionTitle == "OPEN DISCOVER / SEARCH")
    }

    @Test("Today data coverage distinguishes stale, partial, and unavailable datasets")
    func dataCoverageCarriesDatasetQuality() {
        let fetchedAt = date("2026-05-28")
        let stale: FinancialDataProvenance = .cached(
            provider: FinancialDataProvenance.finnhubProvider,
            fetchedAt: fetchedAt,
            age: FinancialDataProvenance.defaultCachedStaleInterval * 2
        )

        let summary = composer.compose(
            date: date("2026-05-30"),
            user: user(),
            mood: mood(value: 55, provenance: stale),
            lunarData: lunarData(),
            mercuryStatus: "Mercury Direct",
            activeEventTitles: [],
            portfolioSummaries: [
                portfolioSummary(
                    provenance: .mixed(reason: "Partial historical dataset. Provider returned a limited portion of the requested range"),
                    displayMode: .partialCoverage,
                    includedWeight: 0.55,
                    averageReturn: nil,
                    winRate: nil
                )
            ],
            stockCandidate: TodayStockCandidate(
                stock: stock(symbol: "MSFT", sharesOwned: 0),
                summaries: [],
                provenance: .unavailable(reason: "Provider-backed historical prices unavailable"),
                completeness: .insufficient(reason: "Provider-backed historical prices unavailable")
            )
        )

        #expect(summary.dataCoverage.rows.contains { $0.provenance.isCachedStale() })
        #expect(summary.dataCoverage.rows.contains { $0.provenance.indicatorLabel == "Partial history" })
        #expect(summary.dataCoverage.rows.contains { $0.provenance.indicatorLabel == "Unavailable" })
    }

    @Test("Today and Mercury copy avoid trading-instruction phrases")
    func todayCopyAvoidsTradingInstructionPhrases() {
        let summary = composer.compose(
            user: user(),
            mood: mood(value: nil, provenance: .unavailable(reason: "Provider-backed market factors unavailable")),
            lunarData: lunarData(),
            mercuryStatus: "Mercury Direct",
            activeEventTitles: ["New Moon"],
            portfolioSummaries: [],
            stockCandidate: nil
        )

        let productCopy = [
            summary.cosmicContext.headline,
            summary.cosmicContext.detail,
            summary.marketContext.headline,
            summary.marketContext.detail,
            summary.portfolioContext.headline,
            summary.portfolioContext.detail,
            summary.stockContext?.headline ?? "",
            summary.stockContext?.detail ?? "",
            summary.marketContext.activation?.title ?? "",
            summary.marketContext.activation?.detail ?? "",
            summary.marketContext.activation?.actionItems.joined(separator: "\n") ?? "",
            summary.portfolioContext.activation?.title ?? "",
            summary.portfolioContext.activation?.detail ?? "",
            summary.portfolioContext.activation?.primaryActionTitle ?? "",
            summary.portfolioContext.activation?.secondaryActionTitle ?? "",
            summary.portfolioContext.activation?.tertiaryActionTitle ?? "",
            summary.portfolioContext.activation?.actionItems.joined(separator: "\n") ?? "",
            summary.stockContext?.activation?.title ?? "",
            summary.stockContext?.activation?.detail ?? "",
            summary.stockContext?.activation?.primaryActionTitle ?? "",
            summary.stockContext?.activation?.secondaryActionTitle ?? "",
            summary.stockContext?.activation?.tertiaryActionTitle ?? "",
            summary.stockContext?.activation?.actionItems.joined(separator: "\n") ?? "",
            summary.dataCoverage.headline,
            summary.dataCoverage.detail,
            summary.dataCoverage.explainers.map(\.detail).joined(separator: "\n"),
            summary.disclaimer,
            MercuryRetrogradeService.shared.currentAdvice,
            MercuryRetrogradeService.shared.tradingAdvice
        ].joined(separator: "\n").lowercased()

        for banned in [
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
        ] {
            #expect(!productCopy.contains(banned))
        }
    }

    @Test("Share card renders unavailable Today state honestly")
    func shareCardRendersUnavailableTodayStateHonestly() {
        let summary = composer.compose(
            date: date("2026-05-30"),
            user: user(portfolio: [], watchlist: []),
            mood: mood(value: nil, provenance: .unavailable(reason: "Provider-backed market factors unavailable")),
            lunarData: lunarData(),
            mercuryStatus: "Mercury Direct",
            activeEventTitles: [],
            portfolioSummaries: [],
            stockCandidate: nil,
            marketWeather: nil
        )

        let card = TodayMarketHoroscopeShareCardContent.make(from: summary)

        #expect(card.marketLine.value == "Market Weather unavailable")
        #expect(card.marketLine.metrics.isEmpty)
        #expect(card.portfolioLine?.value == "Portfolio setup needed")
        #expect(card.stockLine?.value == "Watchlist setup needed")
        #expect(card.provenanceLabel == "Unavailable")
        #expect(card.searchableText.localizedCaseInsensitiveContains("not available yet"))
        #expect(card.footer == "Historical context only. No forecast. Not financial advice.")
    }

    @Test("Share card numeric claims only come from gated Today metrics")
    func shareCardNumericClaimsRespectTodayGates() {
        let fetchedAt = date("2026-05-30")
        let live: FinancialDataProvenance = .live(provider: FinancialDataProvenance.finnhubProvider, fetchedAt: fetchedAt)
        let readySummary = composer.compose(
            date: fetchedAt,
            user: user(),
            mood: mood(value: 68, provenance: live),
            lunarData: lunarData(),
            mercuryStatus: "Mercury Direct",
            activeEventTitles: ["Full Moon"],
            portfolioSummaries: [
                portfolioSummary(
                    provenance: live,
                    displayMode: .marketBackedResult,
                    includedWeight: 0.82,
                    averageReturn: 1.4,
                    winRate: 0.67
                )
            ],
            stockCandidate: TodayStockCandidate(
                stock: stock(symbol: "AAPL", sharesOwned: 0),
                summaries: [
                    stockSummary(
                        provenance: live,
                        displayMode: .marketBackedResult,
                        averageReturn: 2.1,
                        winRate: 0.75
                    )
                ],
                provenance: live,
                completeness: .complete
            ),
            marketWeather: marketWeatherSummary(
                provenance: live,
                displayMode: .marketBackedResult,
                coverage: 1,
                averageReturn: 0.8,
                winRate: 0.58
            )
        )

        let readyCard = TodayMarketHoroscopeShareCardContent.make(from: readySummary)
        #expect(readyCard.marketLine.metrics.map(\.value).contains("+0.8%"))
        #expect(readyCard.portfolioLine?.metrics.map(\.value).contains("+1.4%") == true)
        #expect(readyCard.stockLine?.metrics.map(\.value).contains("+2.1%") == true)

        let unavailableSummary = composer.compose(
            date: fetchedAt,
            user: user(),
            mood: mood(value: nil, provenance: .unavailable(reason: "Provider-backed market factors unavailable")),
            lunarData: lunarData(),
            mercuryStatus: "Mercury Direct",
            activeEventTitles: [],
            portfolioSummaries: [
                portfolioSummary(
                    provenance: .mixed(reason: "Only 40% of portfolio value has provider-backed historical prices"),
                    displayMode: .insufficientSample,
                    includedWeight: 0.40,
                    averageReturn: 8.8,
                    winRate: 0.88
                )
            ],
            stockCandidate: TodayStockCandidate(
                stock: stock(symbol: "TSLA", sharesOwned: 0),
                summaries: [
                    stockSummary(
                        provenance: .sample(reason: "Preview fixture"),
                        displayMode: .sampleOnly,
                        averageReturn: 12.5,
                        winRate: 1
                    )
                ],
                provenance: .sample(reason: "Preview fixture"),
                completeness: .complete
            ),
            marketWeather: marketWeatherSummary(
                provenance: .unavailable(reason: "Provider-backed market ETF history unavailable"),
                displayMode: .unavailable,
                coverage: 0,
                averageReturn: 9.9,
                winRate: 0.99
            )
        )

        let unavailableCard = TodayMarketHoroscopeShareCardContent.make(from: unavailableSummary)
        let allUnavailableMetricsHidden = unavailableCard.lines.allSatisfy { $0.metrics.isEmpty }
        #expect(allUnavailableMetricsHidden)
        #expect(!unavailableCard.searchableText.contains("+9.9%"))
        #expect(!unavailableCard.searchableText.contains("+8.8%"))
        #expect(!unavailableCard.searchableText.contains("+12.5%"))
        #expect(!unavailableCard.searchableText.contains("99%"))
        #expect(!unavailableCard.searchableText.contains("100%"))
    }

    @Test("Share card can render without portfolio or watchlist")
    func shareCardCanRenderWithoutPortfolioOrWatchlist() {
        let summary = composer.compose(
            date: date("2026-05-30"),
            user: user(portfolio: [], watchlist: []),
            mood: mood(value: nil, provenance: .unavailable(reason: "Provider-backed market factors unavailable")),
            lunarData: lunarData(),
            mercuryStatus: "Mercury Direct",
            activeEventTitles: [],
            portfolioSummaries: [],
            stockCandidate: nil,
            marketWeather: nil
        )

        let card = TodayMarketHoroscopeShareCardContent.make(from: summary)

        #expect(card.portfolioLine?.detail == "Add or import holdings to unlock portfolio context.")
        #expect(card.stockLine?.title == "WATCHLIST LENS")
        #expect(card.stockLine?.detail == "Add a watchlist symbol or holding to unlock the stock lens.")
        #expect(card.shareText.contains("PORTFOLIO LENS: Portfolio setup needed"))
        #expect(card.shareText.contains("WATCHLIST LENS: Watchlist setup needed"))
    }

    @Test("Share card can render with watchlist stock context")
    func shareCardCanRenderWithWatchlistStockContext() {
        let fetchedAt = date("2026-05-30")
        let live: FinancialDataProvenance = .live(provider: FinancialDataProvenance.finnhubProvider, fetchedAt: fetchedAt)
        let summary = composer.compose(
            date: fetchedAt,
            user: user(),
            mood: mood(value: 62, provenance: live),
            lunarData: lunarData(),
            mercuryStatus: "Mercury Direct",
            activeEventTitles: ["Full Moon"],
            portfolioSummaries: [],
            stockCandidate: TodayStockCandidate(
                stock: stock(symbol: "AAPL", sharesOwned: 0),
                summaries: [
                    stockSummary(
                        provenance: live,
                        displayMode: .marketBackedResult,
                        averageReturn: 2.1,
                        winRate: 0.75
                    )
                ],
                provenance: live,
                completeness: .complete
            ),
            marketWeather: nil
        )

        let card = TodayMarketHoroscopeShareCardContent.make(from: summary)

        #expect(card.stockLine?.title == "AAPL LENS")
        #expect(card.stockLine?.value == "AAPL context ready")
        #expect(card.stockLine?.metrics.map(\.label).contains("AVG") == true)
        #expect(card.stockLine?.provenance.isProviderBacked == true)
    }

    @Test("Share card copy stays compliance safe")
    func shareCardCopyStaysComplianceSafe() {
        let summary = composer.compose(
            user: user(portfolio: [], watchlist: []),
            mood: mood(value: nil, provenance: .unavailable(reason: "Provider-backed market factors unavailable")),
            lunarData: lunarData(),
            mercuryStatus: "Mercury Direct",
            activeEventTitles: ["New Moon"],
            portfolioSummaries: [],
            stockCandidate: nil,
            marketWeather: nil
        )
        let card = TodayMarketHoroscopeShareCardContent.make(from: summary)
        let copy = card.searchableText.lowercased()

        for banned in [
            "buy signal",
            "sell signal",
            "take profits",
            "reduce exposure",
            "position size",
            "expected upside",
            "expected downside",
            "guaranteed outcome"
        ] {
            #expect(!copy.contains(banned))
        }
    }

    private func user(
        portfolio: [Stock]? = nil,
        watchlist: [String] = ["TSLA"]
    ) -> UserProfile {
        UserProfile(
            displayName: "Test",
            email: "test@example.com",
            birthDate: date("1990-04-12"),
            portfolio: portfolio ?? [
                stock(symbol: "AAPL", sharesOwned: 2),
                stock(symbol: "MSFT", sharesOwned: 1)
            ],
            watchlist: watchlist
        )
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

    private func mood(value: Int?, provenance: FinancialDataProvenance) -> CosmicMoodData {
        CosmicMoodData(
            date: date("2026-05-30"),
            value: value,
            factors: [],
            label: value == nil ? "Market data unavailable" : nil,
            provenance: provenance,
            marketDataCoverage: value == nil ? 0 : 1,
            unavailableFactorWeight: value == nil ? 1 : 0,
            displayMode: value == nil ? .unavailable : .marketBackedScore
        )
    }

    private func lunarData() -> LunarData {
        LunarData(
            date: date("2026-05-30"),
            phase: .waxingGibbous,
            illumination: 0.82,
            age: 11,
            moonSign: .aries,
            isWaxing: true
        )
    }

    private func portfolioSummary(
        provenance: FinancialDataProvenance,
        displayMode: CorrelationDisplayMode,
        includedWeight: Double,
        averageReturn: Double?,
        winRate: Double?
    ) -> PortfolioCosmicCorrelationSummary {
        PortfolioCosmicCorrelationSummary(
            id: "fullMoon",
            eventName: "Full Moon",
            eventType: .fullMoon,
            eventCount: 6,
            sampleSize: displayMode == .marketBackedResult ? 4 : 0,
            window: CorrelationWindow(daysBefore: 1, daysAfter: 3),
            averagePortfolioReturn: averageReturn,
            medianPortfolioReturn: averageReturn,
            winRate: winRate,
            baselinePortfolioReturn: averageReturn.map { $0 / 2 },
            volatilityRatio: displayMode == .marketBackedResult ? 1.1 : nil,
            maxDrawdown: displayMode == .marketBackedResult ? 2.3 : nil,
            affectedHoldings: [],
            unavailableHoldings: includedWeight < 1 ? ["MSFT"] : [],
            includedPortfolioWeight: includedWeight,
            excludedPortfolioWeight: max(0, 1 - includedWeight),
            provenance: provenance,
            confidence: displayMode == .marketBackedResult ? .thin : .insufficient,
            displayMode: displayMode,
            disclaimer: "Historical portfolio context only. Correlation does not imply causation and this is not financial advice."
        )
    }

    private func stockSummary(
        provenance: FinancialDataProvenance,
        displayMode: CorrelationDisplayMode,
        averageReturn: Double?,
        winRate: Double?
    ) -> StockCosmicCorrelationSummary {
        StockCosmicCorrelationSummary(
            id: "AAPL-fullMoon",
            symbol: "AAPL",
            eventName: "Full Moon",
            eventType: .fullMoon,
            eventCount: 6,
            sampleSize: displayMode == .marketBackedResult ? 4 : 0,
            window: CorrelationWindow(daysBefore: 1, daysAfter: 3),
            averageReturn: averageReturn,
            medianReturn: averageReturn,
            winRate: winRate,
            baselineReturn: averageReturn.map { $0 / 2 },
            volatilityRatio: displayMode == .marketBackedResult ? 1.2 : nil,
            maxDrawdown: displayMode == .marketBackedResult ? 2.1 : nil,
            provenance: provenance,
            confidence: displayMode == .marketBackedResult ? .thin : .unavailable,
            displayMode: displayMode,
            disclaimer: displayMode == .sampleOnly
                ? "Sample chart data is labeled for preview only. No historical correlation claim is shown."
                : "Historical price data unavailable. Correlation context will appear when provider-backed history is available."
        )
    }

    private func marketWeatherSummary(
        provenance: FinancialDataProvenance,
        displayMode: CorrelationDisplayMode,
        coverage: Double,
        averageReturn: Double?,
        winRate: Double?
    ) -> MarketWeatherSummary {
        MarketWeatherSummary(
            symbols: MarketWeatherService.v1Symbols,
            eventSummaries: [
                MarketWeatherEventSummary(
                    id: "fullMoon",
                    eventName: "Full Moon",
                    eventType: .fullMoon,
                    eventCount: 6,
                    sampleSize: displayMode == .marketBackedResult ? 4 : 0,
                    window: CorrelationWindow(daysBefore: 1, daysAfter: 3),
                    averageMarketReturn: averageReturn,
                    medianMarketReturn: averageReturn,
                    winRate: winRate,
                    baselineMarketReturn: averageReturn.map { $0 / 2 },
                    volatilityRatio: displayMode == .marketBackedResult ? 1.05 : nil,
                    maxDrawdown: displayMode == .marketBackedResult ? 1.7 : nil,
                    includedSymbols: coverage >= 1 ? ["DIA", "IWM", "QQQ", "SPY"] : ["DIA", "QQQ", "SPY"],
                    excludedSymbols: coverage >= 1 ? [] : ["IWM"],
                    staleSymbols: [],
                    provenance: provenance,
                    confidence: displayMode == .marketBackedResult ? .thin : .insufficient,
                    displayMode: displayMode,
                    disclaimer: "Historical market context only. Correlation does not imply causation and this is not financial advice."
                )
            ],
            sectorBreadth: nil,
            includedSymbols: coverage >= 1 ? ["DIA", "IWM", "QQQ", "SPY"] : ["DIA", "QQQ", "SPY"],
            excludedSymbols: coverage >= 1 ? [] : ["IWM"],
            staleSymbols: [],
            partialSymbols: [],
            insufficientSymbols: [],
            coverage: coverage,
            provenance: provenance,
            disclaimer: "Historical market context only. Correlation does not imply causation and this is not financial advice."
        )
    }

    private func date(_ value: String) -> Date {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter.date(from: value) ?? Date(timeIntervalSince1970: 0)
    }
}
