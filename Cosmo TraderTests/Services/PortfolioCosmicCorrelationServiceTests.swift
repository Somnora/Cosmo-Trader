import Foundation
import Testing
@testable import Cosmo_Trader

struct PortfolioCosmicCorrelationServiceTests {

    @Test("Portfolio correlation is weighted by market value, not share count")
    func portfolioCorrelationUsesMarketValueWeights() {
        let shareHeavy = stock(symbol: "SHARE", currentPrice: 2, sharesOwned: 100)
        let valueHeavy = stock(symbol: "VALUE", currentPrice: 200, sharesOwned: 1)
        let events = fullMoonEvents()

        let summaries = PortfolioCosmicCorrelationService.shared.summaries(
            holdings: [shareHeavy, valueHeavy],
            priceHistoryBySymbol: [
                "SHARE": prices([100, 105, 110, 100, 105, 110, 100, 105, 110]),
                "VALUE": prices([100, 95, 90, 100, 95, 90, 100, 95, 90])
            ],
            provenanceBySymbol: providerProvenance(["SHARE", "VALUE"]),
            events: events,
            filterState: AstroOverlayFilterState(enabledKinds: [.fullMoon], showEstimatedEvents: true, eventWindowDays: 1),
            minimumSampleSize: 3
        )

        let summary = summaries.first { $0.eventType == .fullMoon }
        #expect(isMarketBacked(summary))
        #expect(summary?.sampleSize == 3)
        #expect(isClose(summary?.includedPortfolioWeight ?? 0, 1))
        #expect(isClose(summary?.averagePortfolioReturn ?? 99, 0))
        #expect(!isClose(summary?.averagePortfolioReturn ?? 0, 9.8, tolerance: 0.2))
    }

    @Test("Volatility ratio reads 1.0 when within-window volatility matches baseline volatility")
    func volatilityRatioIsOneWhenWindowVolatilityMatchesBaseline() {
        // Zero real astrological effect: every event window has exactly the
        // same day-to-day return volatility as the rest of the price history.
        // A dimensionally sound ratio must read ~1.0 here at the default
        // (unset) 3-day event window, not the inflated value produced by
        // taking the stdev of window-to-window returns (which scales with
        // window length) over a single-day baseline stdev.
        //
        // The history runs long because the baseline is now measured only over
        // candles the events never touched, and it reports no comparison at
        // all below a floor of clean windows. Three weeks of prices with three
        // events in them is almost entirely event.
        let flat = stock(symbol: "FLAT", currentPrice: 100, sharesOwned: 10)
        let events = [
            pointEvent(kind: .fullMoon, on: "2025-01-06"),
            pointEvent(kind: .fullMoon, on: "2025-01-11"),
            pointEvent(kind: .fullMoon, on: "2025-01-16")
        ]

        let summaries = PortfolioCosmicCorrelationService.shared.summaries(
            holdings: [flat],
            priceHistoryBySymbol: ["FLAT": constantDailyVolatilityPrices(days: 200)],
            provenanceBySymbol: providerProvenance(["FLAT"]),
            events: events,
            filterState: AstroOverlayFilterState(enabledKinds: [.fullMoon], showEstimatedEvents: true),
            minimumSampleSize: 3
        )

        let summary = summaries.first { $0.eventType == .fullMoon }
        #expect(isMarketBacked(summary))
        #expect(summary?.sampleSize == 3)
        // Not exact: the clean stretches carry one more up-day than down-day,
        // which moves the baseline stdev in the fifth decimal. The bug this
        // guards against printed 1.7x and 3.9x.
        #expect(isClose(summary?.volatilityRatio ?? 0, 1, tolerance: 0.01))
    }

    @Test("Portfolio baseline is withheld rather than invented when clean history is thin")
    func portfolioBaselineWithheldWhenCleanHistoryIsThin() {
        // Twenty-one candles with three full moons in them leaves almost no
        // stretch the events did not touch. The honest answer is no baseline,
        // not a number assembled from the leftovers -- and the event metrics
        // still stand on their own.
        let flat = stock(symbol: "FLAT", currentPrice: 100, sharesOwned: 10)
        let events = [
            pointEvent(kind: .fullMoon, on: "2025-01-06"),
            pointEvent(kind: .fullMoon, on: "2025-01-11"),
            pointEvent(kind: .fullMoon, on: "2025-01-16")
        ]

        let summaries = PortfolioCosmicCorrelationService.shared.summaries(
            holdings: [flat],
            priceHistoryBySymbol: ["FLAT": constantDailyVolatilityPrices(days: 21)],
            provenanceBySymbol: providerProvenance(["FLAT"]),
            events: events,
            filterState: AstroOverlayFilterState(enabledKinds: [.fullMoon], showEstimatedEvents: true),
            minimumSampleSize: 3
        )

        let summary = summaries.first { $0.eventType == .fullMoon }
        #expect(isMarketBacked(summary))
        #expect(summary?.sampleSize == 3)
        #expect(summary?.averagePortfolioReturn != nil)
        #expect(summary?.baselinePortfolioReturn == nil)
        #expect(summary?.volatilityRatio == nil)
    }

    @Test("Low total portfolio coverage withholds numeric portfolio claims")
    func lowTotalPortfolioCoverageWithholdsNumericClaims() {
        let verified = stock(symbol: "LIVE", currentPrice: 10, sharesOwned: 10)
        let sample = stock(symbol: "SAMPLE", currentPrice: 90, sharesOwned: 10)

        let summaries = PortfolioCosmicCorrelationService.shared.summaries(
            holdings: [verified, sample],
            priceHistoryBySymbol: [
                "LIVE": prices([100, 105, 110, 100, 105, 110, 100, 105, 110]),
                "SAMPLE": prices([100, 150, 200, 100, 150, 200, 100, 150, 200])
            ],
            provenanceBySymbol: [
                "LIVE": .live(provider: FinancialDataProvenance.finnhubProvider, fetchedAt: date("2025-01-10")),
                "SAMPLE": .sample(reason: "Preview fixture")
            ],
            events: fullMoonEvents(),
            filterState: AstroOverlayFilterState(enabledKinds: [.fullMoon], showEstimatedEvents: true, eventWindowDays: 1),
            minimumSampleSize: 3
        )

        let summary = summaries.first { $0.eventType == .fullMoon }
        #expect(isInsufficientSample(summary))
        #expect(isClose(summary?.includedPortfolioWeight ?? 0, 0.1))
        #expect(isClose(summary?.excludedPortfolioWeight ?? 0, 0.9))
        #expect(summary?.unavailableHoldings == ["SAMPLE"])
        expectNoAggregateMetrics(summary)
        #expect(summary?.disclaimer.contains("50% coverage is required for portfolio context") == true)
        if case .mixed(let reason)? = summary?.provenance {
            #expect(reason.contains("10% of portfolio value") == true)
        } else {
            Issue.record("Low coverage summary should expose mixed provenance")
        }
    }

    @Test("Partial portfolio coverage withholds headline numeric metrics")
    func partialPortfolioCoverageWithholdsHeadlineNumericMetrics() {
        let verified = stock(symbol: "LIVE", currentPrice: 60, sharesOwned: 10)
        let sample = stock(symbol: "SAMPLE", currentPrice: 40, sharesOwned: 10)

        let summaries = PortfolioCosmicCorrelationService.shared.summaries(
            holdings: [verified, sample],
            priceHistoryBySymbol: [
                "LIVE": prices([100, 105, 110, 100, 105, 110, 100, 105, 110]),
                "SAMPLE": prices([100, 150, 200, 100, 150, 200, 100, 150, 200])
            ],
            provenanceBySymbol: [
                "LIVE": .live(provider: FinancialDataProvenance.finnhubProvider, fetchedAt: date("2025-01-10")),
                "SAMPLE": .sample(reason: "Preview fixture")
            ],
            events: fullMoonEvents(),
            filterState: AstroOverlayFilterState(enabledKinds: [.fullMoon], showEstimatedEvents: true, eventWindowDays: 1),
            minimumSampleSize: 3
        )

        let summary = summaries.first { $0.eventType == .fullMoon }
        #expect(isPartialCoverage(summary))
        #expect(isClose(summary?.includedPortfolioWeight ?? 0, 0.6))
        #expect(isClose(summary?.excludedPortfolioWeight ?? 0, 0.4))
        #expect(summary?.unavailableHoldings == ["SAMPLE"])
        expectNoAggregateMetrics(summary)
        #expect(summary?.disclaimer.contains("70% coverage is required for headline portfolio metrics") == true)
        #expect(summary?.disclaimer.contains("Partial context only") == true)
        if case .mixed(let reason)? = summary?.provenance {
            #expect(reason.contains("60% of portfolio value") == true)
        } else {
            Issue.record("Partial coverage summary should expose mixed provenance")
        }
    }

    @Test("Exactly fifty percent coverage is partial context only")
    func exactlyFiftyPercentCoverageIsPartialContextOnly() {
        let verified = stock(symbol: "LIVE", currentPrice: 50, sharesOwned: 10)
        let sample = stock(symbol: "SAMPLE", currentPrice: 50, sharesOwned: 10)

        let summaries = PortfolioCosmicCorrelationService.shared.summaries(
            holdings: [verified, sample],
            priceHistoryBySymbol: [
                "LIVE": prices([100, 105, 110, 100, 105, 110, 100, 105, 110]),
                "SAMPLE": prices([100, 150, 200, 100, 150, 200, 100, 150, 200])
            ],
            provenanceBySymbol: [
                "LIVE": .live(provider: FinancialDataProvenance.finnhubProvider, fetchedAt: date("2025-01-10")),
                "SAMPLE": .sample(reason: "Preview fixture")
            ],
            events: fullMoonEvents(),
            filterState: AstroOverlayFilterState(enabledKinds: [.fullMoon], showEstimatedEvents: true, eventWindowDays: 1),
            minimumSampleSize: 3
        )

        let summary = summaries.first { $0.eventType == .fullMoon }
        #expect(isPartialCoverage(summary))
        #expect(isClose(summary?.includedPortfolioWeight ?? 0, 0.5))
        expectNoAggregateMetrics(summary)
        #expect(summary?.disclaimer.contains("70% coverage is required") == true)
    }

    @Test("Seventy percent provider-backed coverage can return portfolio metrics")
    func seventyPercentProviderBackedCoverageCanReturnPortfolioMetrics() {
        let verified = stock(symbol: "LIVE", currentPrice: 70, sharesOwned: 10)
        let sample = stock(symbol: "SAMPLE", currentPrice: 30, sharesOwned: 10)

        let summaries = PortfolioCosmicCorrelationService.shared.summaries(
            holdings: [verified, sample],
            priceHistoryBySymbol: [
                "LIVE": prices([100, 105, 110, 100, 105, 110, 100, 105, 110]),
                "SAMPLE": prices([100, 150, 200, 100, 150, 200, 100, 150, 200])
            ],
            provenanceBySymbol: [
                "LIVE": .live(provider: FinancialDataProvenance.finnhubProvider, fetchedAt: date("2025-01-10")),
                "SAMPLE": .sample(reason: "Preview fixture")
            ],
            events: fullMoonEvents(),
            filterState: AstroOverlayFilterState(enabledKinds: [.fullMoon], showEstimatedEvents: true, eventWindowDays: 1),
            minimumSampleSize: 3
        )

        let summary = summaries.first { $0.eventType == .fullMoon }
        #expect(isMarketBacked(summary))
        #expect(isClose(summary?.includedPortfolioWeight ?? 0, 0.7))
        #expect(isClose(summary?.excludedPortfolioWeight ?? 0, 0.3))
        #expect(summary?.unavailableHoldings == ["SAMPLE"])
        #expect(isClose(summary?.averagePortfolioReturn ?? 0, 10))
    }

    @Test("All non-provider-backed holdings do not expose numeric portfolio claims")
    func allNonProviderBackedHoldingsWithholdMetrics() {
        let sample = stock(symbol: "SAMPLE", currentPrice: 50, sharesOwned: 2)

        let summaries = PortfolioCosmicCorrelationService.shared.summaries(
            holdings: [sample],
            priceHistoryBySymbol: ["SAMPLE": prices([100, 110, 120, 130])],
            provenanceBySymbol: ["SAMPLE": .sample(reason: "Preview fixture")],
            events: fullMoonEvents(),
            filterState: AstroOverlayFilterState(enabledKinds: [.fullMoon], showEstimatedEvents: true, eventWindowDays: 1),
            minimumSampleSize: 3
        )

        let summary = summaries.first { $0.eventType == .fullMoon }
        #expect(isSampleOnly(summary))
        #expect(summary?.confidence == .unavailable)
        #expect(summary?.averagePortfolioReturn == nil)
        #expect(summary?.winRate == nil)
        #expect(summary?.includedPortfolioWeight == 0)
        #expect(summary?.excludedPortfolioWeight == 1)
    }

    @Test("Mixed provenance holdings do not count toward portfolio coverage")
    func mixedProvenanceHoldingsDoNotCountTowardCoverage() {
        let mixed = stock(symbol: "MIXED", currentPrice: 100, sharesOwned: 1)

        let summaries = PortfolioCosmicCorrelationService.shared.summaries(
            holdings: [mixed],
            priceHistoryBySymbol: ["MIXED": prices([100, 105, 110, 100, 105, 110, 100, 105, 110])],
            provenanceBySymbol: ["MIXED": .mixed(reason: "Mixed freshness is unsafe for numeric correlation claims")],
            events: fullMoonEvents(),
            filterState: AstroOverlayFilterState(enabledKinds: [.fullMoon], showEstimatedEvents: true, eventWindowDays: 1),
            minimumSampleSize: 3
        )

        let summary = summaries.first { $0.eventType == .fullMoon }
        #expect(isUnavailable(summary))
        #expect(summary?.averagePortfolioReturn == nil)
        #expect(summary?.winRate == nil)
        #expect(summary?.includedPortfolioWeight == 0)
        #expect(summary?.excludedPortfolioWeight == 1)
    }

    @Test("Partial historical datasets do not count toward portfolio numeric coverage")
    func partialHistoricalDatasetsDoNotCountTowardPortfolioNumericCoverage() {
        let complete = stock(symbol: "COMP", currentPrice: 60, sharesOwned: 10)
        let partial = stock(symbol: "PART", currentPrice: 40, sharesOwned: 10)

        let summaries = PortfolioCosmicCorrelationService.shared.summaries(
            holdings: [complete, partial],
            priceHistoryBySymbol: [
                "COMP": prices([100, 105, 110, 100, 105, 110, 100, 105, 110]),
                "PART": prices([100, 150, 200, 100, 150, 200, 100, 150, 200])
            ],
            provenanceBySymbol: providerProvenance(["COMP", "PART"]),
            completenessBySymbol: [
                "COMP": .complete,
                "PART": .partial(reason: "Provider returned a limited portion of the requested range")
            ],
            events: fullMoonEvents(),
            filterState: AstroOverlayFilterState(enabledKinds: [.fullMoon], showEstimatedEvents: true, eventWindowDays: 1),
            minimumSampleSize: 3
        )

        let summary = summaries.first { $0.eventType == .fullMoon }
        #expect(isPartialCoverage(summary))
        #expect(isClose(summary?.includedPortfolioWeight ?? 0, 0.6))
        #expect(summary?.unavailableHoldings == ["PART"])
        expectNoAggregateMetrics(summary)
        #expect(summary?.disclaimer.contains("70% coverage is required") == true)
    }

    @Test("Insufficient historical datasets do not count toward portfolio coverage")
    func insufficientHistoricalDatasetsDoNotCountTowardPortfolioCoverage() {
        let insufficient = stock(symbol: "THIN", currentPrice: 100, sharesOwned: 1)

        let summaries = PortfolioCosmicCorrelationService.shared.summaries(
            holdings: [insufficient],
            priceHistoryBySymbol: ["THIN": prices([100, 105, 110])],
            provenanceBySymbol: providerProvenance(["THIN"]),
            completenessBySymbol: [
                "THIN": .insufficient(reason: "Provider returned fewer than two historical candles")
            ],
            events: fullMoonEvents(),
            filterState: AstroOverlayFilterState(enabledKinds: [.fullMoon], showEstimatedEvents: true, eventWindowDays: 1),
            minimumSampleSize: 3
        )

        let summary = summaries.first { $0.eventType == .fullMoon }
        #expect(isUnavailable(summary))
        #expect(summary?.includedPortfolioWeight == 0)
        #expect(summary?.excludedPortfolioWeight == 1)
        expectNoAggregateMetrics(summary)
    }

    @Test("Minimum sample size gates portfolio correlation metrics")
    func minimumSampleSizeGatesPortfolioMetrics() {
        let holding = stock(symbol: "AAPL", currentPrice: 100, sharesOwned: 1)
        let events = [
            pointEvent(kind: .newMoon, on: "2025-01-02"),
            pointEvent(kind: .newMoon, on: "2025-01-05")
        ]

        let summaries = PortfolioCosmicCorrelationService.shared.summaries(
            holdings: [holding],
            priceHistoryBySymbol: ["AAPL": prices([100, 105, 110, 100, 105, 110])],
            provenanceBySymbol: providerProvenance(["AAPL"]),
            events: events,
            filterState: AstroOverlayFilterState(enabledKinds: [.newMoon], showEstimatedEvents: true, eventWindowDays: 1),
            minimumSampleSize: 3
        )

        let summary = summaries.first { $0.eventType == .newMoon }
        #expect(isInsufficientSample(summary))
        #expect(summary?.sampleSize == 2)
        #expect(summary?.averagePortfolioReturn == nil)
        #expect(summary?.disclaimer.contains("No return claim") == true)
    }

    @Test("Portfolio correlation V1 only reports full moon, new moon, and Mercury retrograde")
    func portfolioCorrelationReportsOnlyLockedV1Events() {
        let holding = stock(symbol: "AAPL", currentPrice: 100, sharesOwned: 1)
        let events = fullMoonEvents()
            + [pointEvent(kind: .firstQuarter, on: "2025-01-03")]
            + [rangeEvent(start: "2025-01-01", end: "2025-01-03")]

        let summaries = PortfolioCosmicCorrelationService.shared.summaries(
            holdings: [holding],
            priceHistoryBySymbol: ["AAPL": prices([100, 105, 110, 100, 105, 110, 100, 105, 110])],
            provenanceBySymbol: providerProvenance(["AAPL"]),
            events: events,
            filterState: AstroOverlayFilterState(enabledKinds: [.fullMoon, .newMoon, .mercuryRetrograde, .firstQuarter], showEstimatedEvents: true, eventWindowDays: 1),
            minimumSampleSize: 3
        )

        #expect(summaries.map(\.eventType) == [.fullMoon, .newMoon, .mercuryRetrograde])
        #expect(summaries.first { $0.eventType == .firstQuarter } == nil)
    }

    @Test("Portfolio correlation copy remains compliance safe")
    func portfolioCorrelationCopyIsComplianceSafe() {
        let holding = stock(symbol: "AAPL", currentPrice: 100, sharesOwned: 1)
        let summaries = PortfolioCosmicCorrelationService.shared.summaries(
            holdings: [holding],
            priceHistoryBySymbol: ["AAPL": prices([100, 105, 110, 100, 105, 110, 100, 105, 110])],
            provenanceBySymbol: providerProvenance(["AAPL"]),
            events: fullMoonEvents(),
            filterState: AstroOverlayFilterState(enabledKinds: [.fullMoon], showEstimatedEvents: true, eventWindowDays: 1),
            minimumSampleSize: 3
        )

        let bannedFragments = [
            "buy signal",
            "sell signal",
            "take profits",
            "reduce exposure",
            "position size",
            "avoid",
            "guaranteed"
        ]
        let copy = summaries.map(\.disclaimer).joined(separator: " ").lowercased()

        for fragment in bannedFragments {
            #expect(!copy.contains(fragment), "Unsafe copy fragment found: \(fragment)")
        }
    }

    @Test("Portfolio intelligence distinguishes stored values from provider quote coverage")
    func portfolioIntelligenceDistinguishesStoredAndProviderQuoteCoverage() {
        let live = stock(symbol: "LIVE", currentPrice: 100, sharesOwned: 1)
        let stored = stock(symbol: "STOR", currentPrice: 100, sharesOwned: 1)

        let summary = PortfolioIntelligenceSummary.make(
            holdings: [live, stored],
            quoteProvenanceBySymbol: [
                "LIVE": .live(provider: FinancialDataProvenance.finnhubProvider, fetchedAt: date("2025-01-10"))
            ],
            historicalIncludedWeight: 0.70,
            historicalProvenance: .live(provider: FinancialDataProvenance.finnhubProvider, fetchedAt: date("2025-01-10")),
            unavailableHistorySymbols: ["STOR"]
        )

        #expect(isClose(summary.totalStoredValue, 200))
        #expect(isClose(summary.providerQuoteCoverage, 0.5))
        #expect(summary.formattedQuoteCoverage == "50%")
        if case .mixed(let reason) = summary.valueProvenance {
            #expect(reason.contains("provider-backed quotes"))
            #expect(reason.contains("stored setup values"))
        } else {
            Issue.record("Mixed quote provenance should distinguish stored and provider-backed values")
        }
    }

    @Test("Portfolio intelligence excludes unknown-founded holdings from zodiac denominator")
    func portfolioIntelligenceExcludesUnknownFoundedHoldingsFromZodiacDenominator() {
        let known = stock(symbol: "KNOWN", currentPrice: 100, sharesOwned: 1)
        let unknown = Stock(
            symbol: "UNK",
            name: "Unknown Corp.",
            currentPrice: 300,
            priceChange: 0,
            percentageChange: 0,
            sharesOwned: 1,
            purchasePrice: 300,
            foundedDate: nil,
            sector: "Mystery"
        )

        let summary = PortfolioIntelligenceSummary.make(
            holdings: [known, unknown],
            quoteProvenanceBySymbol: [:],
            historicalIncludedWeight: 0,
            historicalProvenance: .unavailable(reason: "Provider-backed history unavailable"),
            unavailableHistorySymbols: ["KNOWN", "UNK"]
        )

        #expect(isClose(summary.verifiedAstrologyCoverage, 0.25))
        #expect(summary.unknownFoundedSymbols == ["UNK"])
        #expect(summary.elementBreakdown.first?.label == ZodiacSign.aries.element.displayName)
        #expect(isClose(summary.elementBreakdown.first?.percentage ?? 0, 1))
        #expect(summary.astrologyCoverageText.contains("Unknown-founded holdings stay out"))
    }

    @Test("Portfolio intelligence concentration is market-value weighted")
    func portfolioIntelligenceConcentrationUsesMarketValueWeights() {
        let shareHeavy = stock(symbol: "SHARE", currentPrice: 2, sharesOwned: 100)
        let valueHeavy = stock(symbol: "VALUE", currentPrice: 400, sharesOwned: 1)
        let small = stock(symbol: "SMALL", currentPrice: 50, sharesOwned: 1)

        let summary = PortfolioIntelligenceSummary.make(
            holdings: [shareHeavy, valueHeavy, small],
            quoteProvenanceBySymbol: providerProvenance(["SHARE", "VALUE", "SMALL"]),
            historicalIncludedWeight: 1,
            historicalProvenance: .live(provider: FinancialDataProvenance.finnhubProvider, fetchedAt: date("2025-01-10")),
            unavailableHistorySymbols: []
        )

        #expect(summary.topHoldings.first?.label == "VALUE")
        #expect(isClose(summary.largestHoldingWeight, 400.0 / 650.0))
        #expect(isClose(summary.topThreeConcentration, 1))
        #expect(!isClose(summary.largestHoldingWeight, 1.0 / 102.0, tolerance: 0.01))
    }

    @Test("Portfolio intelligence history coverage preserves seventy percent unlock policy")
    func portfolioIntelligenceHistoryCoveragePreservesSeventyPercentUnlockPolicy() {
        let live = stock(symbol: "LIVE", currentPrice: 60, sharesOwned: 10)
        let missing = stock(symbol: "MISS", currentPrice: 40, sharesOwned: 10)

        let summary = PortfolioIntelligenceSummary.make(
            holdings: [live, missing],
            quoteProvenanceBySymbol: providerProvenance(["LIVE", "MISS"]),
            historicalIncludedWeight: 0.60,
            historicalProvenance: .mixed(reason: "Only 60% of portfolio value has provider-backed historical prices"),
            unavailableHistorySymbols: ["MISS"]
        )

        #expect(isClose(summary.historyCoverage, 0.60))
        #expect(!summary.isPortfolioCorrelationUnlocked)
        #expect(summary.historyUnlockText.contains("70% history coverage is required"))
        #expect(summary.historyUnlockText.contains("headline portfolio correlation metrics"))
    }

    @MainActor
    @Test("Portfolio history status uses provider datasets without sample candles")
    func portfolioHistoryStatusUsesProviderDatasetsWithoutSampleCandles() {
        let live = stock(symbol: "LIVE", currentPrice: 70, sharesOwned: 10)
        let missing = stock(symbol: "MISS", currentPrice: 30, sharesOwned: 10)
        let snapshot = CorrelationHistoricalDatasetSnapshot(
            datasetsBySymbol: [
                "LIVE": completeDataset(symbol: "LIVE")
            ],
            unavailableProvenanceBySymbol: [
                "MISS": .unavailable(reason: "Provider-backed historical prices unavailable")
            ]
        )

        let statuses = PortfolioCorrelationViewModel.makeHistoryStatuses(
            holdings: [live, missing],
            snapshot: snapshot
        )

        let liveStatus = statuses.first { $0.symbol == "LIVE" }
        let missingStatus = statuses.first { $0.symbol == "MISS" }
        #expect(liveStatus?.state == .live)
        #expect(liveStatus?.isUsableForPortfolioCorrelation == true)
        #expect(isClose(liveStatus?.portfolioWeight ?? 0, 0.70))
        #expect(missingStatus?.state == .unavailable)
        #expect(missingStatus?.isUsableForPortfolioCorrelation == false)
        #expect(statuses.allSatisfy { status in
            if case .sample = status.provenance { return false }
            return true
        })
    }

    @MainActor
    @Test("Partial and insufficient history statuses do not count as usable portfolio history")
    func partialAndInsufficientHistoryStatusesDoNotCountAsUsablePortfolioHistory() {
        let partial = stock(symbol: "PART", currentPrice: 60, sharesOwned: 10)
        let insufficient = stock(symbol: "THIN", currentPrice: 40, sharesOwned: 10)
        let snapshot = CorrelationHistoricalDatasetSnapshot(
            datasetsBySymbol: [
                "PART": partialDataset(symbol: "PART"),
                "THIN": insufficientDataset(symbol: "THIN")
            ],
            unavailableProvenanceBySymbol: [:]
        )

        let statuses = PortfolioCorrelationViewModel.makeHistoryStatuses(
            holdings: [partial, insufficient],
            snapshot: snapshot
        )

        #expect(statuses.first { $0.symbol == "PART" }?.state == .partial)
        #expect(statuses.first { $0.symbol == "PART" }?.provenance.indicatorLabel == "Partial history")
        #expect(statuses.first { $0.symbol == "PART" }?.isUsableForPortfolioCorrelation == false)
        let thinStatus = statuses.first { $0.symbol == "THIN" }
        #expect(thinStatus?.state == .insufficient)
        #expect(thinStatus?.label == "Insufficient")
        #expect(thinStatus?.provenance.isProviderBacked == false)
        #expect(thinStatus?.isUsableForPortfolioCorrelation == false)
    }

    @MainActor
    @Test("Stale history status remains provider-backed but labeled stale")
    func staleHistoryStatusRemainsProviderBackedButLabeledStale() {
        let holding = stock(symbol: "AAPL", currentPrice: 100, sharesOwned: 1)
        let staleProvenance: FinancialDataProvenance = .cached(
            provider: FinancialDataProvenance.finnhubProvider,
            fetchedAt: date("2025-01-01"),
            age: FinancialDataProvenance.defaultCachedStaleInterval + 1
        )
        let snapshot = CorrelationHistoricalDatasetSnapshot(
            datasetsBySymbol: [
                "AAPL": completeDataset(symbol: "AAPL").withProvenance(staleProvenance)
            ],
            unavailableProvenanceBySymbol: [:]
        )

        let statuses = PortfolioCorrelationViewModel.makeHistoryStatuses(
            holdings: [holding],
            snapshot: snapshot
        )

        let status = statuses.first
        #expect(status?.state == .cachedStale)
        #expect(status?.provenance.isProviderBacked == true)
        #expect(status?.provenance.indicatorLabel.contains("stale") == true)
        #expect(status?.isUsableForPortfolioCorrelation == true)
    }

    @MainActor
    @Test("Portfolio history reload requests provider-backed history and updates coverage")
    func portfolioHistoryReloadRequestsProviderBackedHistoryAndUpdatesCoverage() async throws {
        let cacheURL = temporaryCacheURL()
        let cache = HistoricalPriceCache(directoryURL: cacheURL)
        defer { try? cache.removeAll() }
        var requestedSymbols: [String] = []
        let service = HistoricalPriceService.testingInstance(
            historicalPriceCache: cache,
            candleFetcher: { symbol, _, from, to in
                requestedSymbols.append(symbol)
                return candleResponse(from: from, to: to, closes: [100, 103, 106])
            }
        )
        let store = CorrelationDatasetStore(historicalPriceService: service)
        let viewModel = PortfolioCorrelationViewModel(datasetStore: store)

        await viewModel.reload(holdings: [stock(symbol: "AAPL", currentPrice: 100, sharesOwned: 2)])

        #expect(requestedSymbols == ["AAPL"])
        #expect(viewModel.historySymbolStatuses.first?.state == .live)
        #expect(viewModel.providerBackedHistoryWeight == 1)
        #expect(viewModel.unavailableHoldings.isEmpty)
        #expect(viewModel.historicalPriceProvenance.isProviderBacked)
        #expect(viewModel.historySymbolStatuses.allSatisfy { status in
            if case .sample = status.provenance { return false }
            return true
        })
    }

    @MainActor
    @Test("Stock detail history activation distinguishes unavailable stale and insufficient states")
    func stockDetailHistoryActivationDistinguishesUnavailableStaleAndInsufficientStates() {
        let viewModel = HistoricalAstroChartViewModel()
        #expect(viewModel.shouldShowHistoryActivation)
        #expect(viewModel.historyActivationTitle == "Load provider history")

        viewModel.ohlcData = prices([100, 101, 102])
        viewModel.historicalDatasetCompleteness = .complete
        viewModel.historicalPriceProvenance = .cached(
            provider: FinancialDataProvenance.finnhubProvider,
            fetchedAt: date("2025-01-01"),
            age: FinancialDataProvenance.defaultCachedStaleInterval + 1
        )
        #expect(viewModel.shouldShowHistoryActivation)
        #expect(viewModel.historyActivationTitle == "Refresh stale history")
        #expect(viewModel.historyActivationDetail.contains("provider/cache path"))

        viewModel.historicalPriceProvenance = .live(provider: FinancialDataProvenance.finnhubProvider, fetchedAt: date("2025-01-10"))
        viewModel.historicalDatasetCompleteness = .insufficient(reason: "Provider returned too little history")
        #expect(viewModel.shouldShowHistoryActivation)
        #expect(viewModel.historyActivationTitle == "Refresh history range")
    }

    @Test("Portfolio intelligence copy is context-only and avoids trading instructions")
    func portfolioIntelligenceCopyIsComplianceSafe() {
        let holding = stock(symbol: "AAPL", currentPrice: 100, sharesOwned: 1)
        let summary = PortfolioIntelligenceSummary.make(
            holdings: [holding],
            quoteProvenanceBySymbol: [:],
            historicalIncludedWeight: 0,
            historicalProvenance: .unavailable(reason: "Provider-backed history unavailable"),
            unavailableHistorySymbols: ["AAPL"]
        )

        let copy = [
            summary.historyUnlockText,
            summary.astrologyCoverageText
        ].joined(separator: " ").lowercased()
        let bannedFragments = [
            "buy",
            "sell",
            "take profits",
            "reduce exposure",
            "position size",
            "avoid",
            "guaranteed",
            "expected upside",
            "expected downside"
        ]

        for fragment in bannedFragments {
            #expect(!copy.contains(fragment), "Unsafe portfolio intelligence copy fragment found: \(fragment)")
        }
    }

    @Test("Portfolio history coverage diagnostics classify usable stale partial insufficient and unavailable holdings")
    func portfolioHistoryCoverageDiagnosticsClassifyHoldingHistoryStates() {
        let holdings = [
            stock(symbol: "USABLE", currentPrice: 400, sharesOwned: 1),
            stock(symbol: "STALE", currentPrice: 300, sharesOwned: 1),
            stock(symbol: "PART", currentPrice: 150, sharesOwned: 1),
            stock(symbol: "INSUF", currentPrice: 100, sharesOwned: 1),
            stock(symbol: "MISS", currentPrice: 50, sharesOwned: 1)
        ]
        let snapshot = CorrelationHistoricalDatasetSnapshot(
            datasetsBySymbol: [
                "USABLE": historicalDataset(symbol: "USABLE", completeness: .complete),
                "STALE": historicalDataset(
                    symbol: "STALE",
                    provenance: .cached(
                        provider: FinancialDataProvenance.finnhubProvider,
                        fetchedAt: date("2025-01-01"),
                        age: FinancialDataProvenance.defaultCachedStaleInterval + 60
                    ),
                    completeness: .complete
                ),
                "PART": historicalDataset(
                    symbol: "PART",
                    completeness: .partial(reason: "Provider returned a limited portion of the requested range")
                ),
                "INSUF": historicalDataset(
                    symbol: "INSUF",
                    completeness: .insufficient(reason: "Provider returned fewer than two historical candles"),
                    candles: [pricePoint(close: 100, dayOffset: 0)]
                )
            ],
            unavailableProvenanceBySymbol: [
                "MISS": .unavailable(reason: "Provider-backed historical prices unavailable")
            ]
        )

        let diagnostics = PortfolioHistoryCoverageDiagnostics.make(
            holdings: holdings,
            datasetSnapshot: snapshot
        )

        #expect(diagnostics.totalHoldings == 5)
        #expect(diagnostics.usableHoldingsCount == 1)
        #expect(diagnostics.staleHoldingsCount == 1)
        #expect(diagnostics.partialHoldingsCount == 1)
        #expect(diagnostics.insufficientHoldingsCount == 1)
        #expect(diagnostics.unavailableHoldingsCount == 1)
        #expect(isClose(diagnostics.usablePortfolioWeight, 0.40))
        #expect(diagnostics.needsHistorySymbols == ["INSUF", "MISS", "PART", "STALE"])
        #expect(diagnostics.unlockText.contains("70%"))
        #expect(diagnostics.unlockText.contains("headline portfolio correlation metrics"))
    }

    @Test("Portfolio history coverage diagnostics do not create fake history for unavailable symbols")
    func portfolioHistoryCoverageDiagnosticsDoNotCreateFakeHistoryForUnavailableSymbols() {
        let holding = stock(symbol: "NOHIST", currentPrice: 100, sharesOwned: 1)
        let snapshot = CorrelationHistoricalDatasetSnapshot(
            datasetsBySymbol: [:],
            unavailableProvenanceBySymbol: [
                "NOHIST": .unavailable(reason: "Provider-backed historical prices unavailable")
            ]
        )

        let diagnostics = PortfolioHistoryCoverageDiagnostics.make(
            holdings: [holding],
            datasetSnapshot: snapshot
        )
        let row = diagnostics.rows.first

        #expect(row?.status == .unavailable)
        #expect(row?.completeness == nil)
        #expect(diagnostics.usablePortfolioWeight == 0)
        if case .unavailable(let reason)? = row?.provenance {
            #expect(reason.contains("Provider-backed historical prices unavailable"))
        } else {
            Issue.record("Unavailable symbols must stay unavailable instead of receiving generated history")
        }
    }

    @Test("Portfolio history coverage diagnostics copy is compliance safe")
    func portfolioHistoryCoverageDiagnosticsCopyIsComplianceSafe() {
        let diagnostics = PortfolioHistoryCoverageDiagnostics(
            rows: [
                PortfolioHistoryCoverageRow(
                    symbol: "AAPL",
                    marketValue: 100,
                    portfolioWeight: 1,
                    status: .insufficient,
                    provenance: .unavailable(reason: "Insufficient historical dataset. Provider returned fewer than two historical candles"),
                    completeness: .insufficient(reason: "Provider returned fewer than two historical candles")
                )
            ],
            totalPortfolioValue: 100
        )
        let copy = [
            diagnostics.unlockText,
            PortfolioHistoryCoverageStatus.usable.detail,
            PortfolioHistoryCoverageStatus.stale.detail,
            PortfolioHistoryCoverageStatus.partial.detail,
            PortfolioHistoryCoverageStatus.insufficient.detail,
            PortfolioHistoryCoverageStatus.unavailable.detail
        ].joined(separator: " ").lowercased()
        let bannedFragments = [
            "buy",
            "sell",
            "take profits",
            "reduce exposure",
            "position size",
            "avoid",
            "guaranteed",
            "expected upside",
            "expected downside",
            "prediction"
        ]

        for fragment in bannedFragments {
            #expect(!copy.contains(fragment), "Unsafe history coverage copy fragment found: \(fragment)")
        }
    }

    private func isMarketBacked(_ summary: PortfolioCosmicCorrelationSummary?) -> Bool {
        guard let summary else { return false }
        if case .marketBackedResult = summary.displayMode { return true }
        return false
    }

    private func isPartialCoverage(_ summary: PortfolioCosmicCorrelationSummary?) -> Bool {
        guard let summary else { return false }
        if case .partialCoverage = summary.displayMode { return true }
        return false
    }

    private func isInsufficientSample(_ summary: PortfolioCosmicCorrelationSummary?) -> Bool {
        guard let summary else { return false }
        if case .insufficientSample = summary.displayMode { return true }
        return false
    }

    private func isUnavailable(_ summary: PortfolioCosmicCorrelationSummary?) -> Bool {
        guard let summary else { return false }
        if case .unavailable = summary.displayMode { return true }
        return false
    }

    private func isSampleOnly(_ summary: PortfolioCosmicCorrelationSummary?) -> Bool {
        guard let summary else { return false }
        if case .sampleOnly = summary.displayMode { return true }
        return false
    }

    private func expectNoAggregateMetrics(_ summary: PortfolioCosmicCorrelationSummary?) {
        #expect(summary?.averagePortfolioReturn == nil)
        #expect(summary?.medianPortfolioReturn == nil)
        #expect(summary?.winRate == nil)
        #expect(summary?.baselinePortfolioReturn == nil)
        #expect(summary?.volatilityRatio == nil)
        #expect(summary?.maxDrawdown == nil)
    }

    private func stock(
        symbol: String,
        currentPrice: Double,
        sharesOwned: Double
    ) -> Stock {
        Stock(
            symbol: symbol,
            name: "\(symbol) Corp.",
            currentPrice: currentPrice,
            priceChange: 0,
            percentageChange: 0,
            sharesOwned: sharesOwned,
            purchasePrice: currentPrice,
            foundedDate: date("2000-04-01"),
            sector: "Technology"
        )
    }

    private func fullMoonEvents() -> [AstroOverlayEvent] {
        [
            pointEvent(kind: .fullMoon, on: "2025-01-02"),
            pointEvent(kind: .fullMoon, on: "2025-01-05"),
            pointEvent(kind: .fullMoon, on: "2025-01-08")
        ]
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
            intensity: .high,
            affectedElements: [],
            affectedSectors: [],
            iconSystemName: kind.iconSystemName,
            source: .calculatedMoonPhase,
            isEstimated: false
        )
    }

    private func rangeEvent(start: String, end: String) -> AstroOverlayEvent {
        AstroOverlayEvent(
            id: "mercury-\(start)",
            kind: .mercuryRetrograde,
            title: "Mercury Retrograde",
            subtitle: nil,
            startDate: date(start),
            endDate: date(end),
            markerDate: date(start),
            intensity: .high,
            affectedElements: [],
            affectedSectors: [],
            iconSystemName: AstroOverlayEventKind.mercuryRetrograde.iconSystemName,
            source: .curatedDataset,
            isEstimated: true
        )
    }

    private func prices(_ closes: [Double]) -> [OHLCData] {
        closes.enumerated().map { index, close in
            OHLCData(
                date: Calendar.current.date(byAdding: .day, value: index, to: date("2025-01-01")) ?? date("2025-01-01"),
                open: close,
                high: close + 1,
                low: max(0.01, close - 1),
                close: close,
                volume: 1_000
            )
        }
    }

    /// A synthetic series whose daily-return magnitude never changes: every
    /// day is +/-`dailyReturnPercent`, alternating. Any window sampled from
    /// it has the same day-to-day volatility as the full series, isolating
    /// the volatility-ratio formula from any real astrological effect.
    private func constantDailyVolatilityPrices(days: Int, dailyReturnPercent: Double = 5) -> [OHLCData] {
        var closes: [Double] = [100]
        for day in 1..<days {
            let multiplier = day.isMultiple(of: 2) ? (1 - dailyReturnPercent / 100) : (1 + dailyReturnPercent / 100)
            closes.append(closes[day - 1] * multiplier)
        }
        return prices(closes)
    }

    private func historicalDataset(
        symbol: String,
        provenance: FinancialDataProvenance? = nil,
        completeness: HistoricalDatasetCompleteness,
        candles: [HistoricalPricePoint]? = nil
    ) -> HistoricalPriceDataset {
        HistoricalPriceDataset(
            symbol: symbol.uppercased(),
            candles: candles ?? [
                pricePoint(close: 100, dayOffset: 0),
                pricePoint(close: 101, dayOffset: 1),
                pricePoint(close: 102, dayOffset: 2)
            ],
            provider: FinancialDataProvenance.finnhubProvider,
            fetchedAt: date("2025-01-10"),
            requestedRange: DateInterval(start: date("2025-01-01"), end: date("2025-01-10")),
            actualRange: DateInterval(start: date("2025-01-01"), end: date("2025-01-10")),
            provenance: provenance ?? .live(provider: FinancialDataProvenance.finnhubProvider, fetchedAt: date("2025-01-10")),
            completeness: completeness
        )
    }

    private func pricePoint(close: Double, dayOffset: Int) -> HistoricalPricePoint {
        HistoricalPricePoint(
            date: Calendar.current.date(byAdding: .day, value: dayOffset, to: date("2025-01-01")) ?? date("2025-01-01"),
            open: close,
            high: close + 1,
            low: max(0.01, close - 1),
            close: close,
            volume: 1_000
        )
    }

    private func providerProvenance(_ symbols: [String]) -> [String: FinancialDataProvenance] {
        symbols.reduce(into: [:]) { partialResult, symbol in
            partialResult[symbol] = .live(provider: FinancialDataProvenance.finnhubProvider, fetchedAt: date("2025-01-10"))
        }
    }

    private func completeDataset(symbol: String) -> HistoricalPriceDataset {
        HistoricalPriceDataset.providerBacked(
            symbol: symbol,
            candles: prices([100, 101, 102, 103, 104, 105, 106, 107, 108, 109]),
            provider: FinancialDataProvenance.finnhubProvider,
            fetchedAt: date("2025-01-10"),
            requestedRange: DateInterval(start: date("2025-01-01"), end: date("2025-01-10")),
            provenance: .live(provider: FinancialDataProvenance.finnhubProvider, fetchedAt: date("2025-01-10"))
        )
    }

    private func partialDataset(symbol: String) -> HistoricalPriceDataset {
        HistoricalPriceDataset.providerBacked(
            symbol: symbol,
            candles: prices([100, 101, 102]),
            provider: FinancialDataProvenance.finnhubProvider,
            fetchedAt: date("2025-01-10"),
            requestedRange: DateInterval(start: date("2025-01-01"), end: date("2025-01-20")),
            provenance: .live(provider: FinancialDataProvenance.finnhubProvider, fetchedAt: date("2025-01-10"))
        )
    }

    private func insufficientDataset(symbol: String) -> HistoricalPriceDataset {
        HistoricalPriceDataset.providerBacked(
            symbol: symbol,
            candles: prices([100]),
            provider: FinancialDataProvenance.finnhubProvider,
            fetchedAt: date("2025-01-10"),
            requestedRange: DateInterval(start: date("2025-01-01"), end: date("2025-01-10")),
            provenance: .live(provider: FinancialDataProvenance.finnhubProvider, fetchedAt: date("2025-01-10"))
        )
    }

    private func candleResponse(from: Date, to: Date, closes: [Double]) -> FinnhubCandleResponse {
        let duration = max(1, to.timeIntervalSince(from))
        let timestamps = closes.indices.map { index in
            let fraction = closes.count == 1 ? 0 : Double(index) / Double(closes.count - 1)
            return Int(from.addingTimeInterval(duration * fraction).timeIntervalSince1970)
        }
        return FinnhubCandleResponse(
            s: "ok",
            t: timestamps,
            o: closes,
            h: closes.map { $0 + 1 },
            l: closes.map { max(0.01, $0 - 1) },
            c: closes,
            v: closes.map { _ in 1_000 }
        )
    }

    private func temporaryCacheURL() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("cosmo-portfolio-history-activation-tests-\(UUID().uuidString)", isDirectory: true)
    }

    private func date(_ value: String) -> Date {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: value) ?? Date(timeIntervalSince1970: 0)
    }

    private func isClose(_ actual: Double, _ expected: Double, tolerance: Double = 0.0001) -> Bool {
        abs(actual - expected) <= tolerance
    }
}
