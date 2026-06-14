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
