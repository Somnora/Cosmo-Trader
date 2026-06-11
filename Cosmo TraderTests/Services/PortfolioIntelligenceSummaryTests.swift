import Foundation
import Testing
@testable import Cosmo_Trader

struct PortfolioIntelligenceSummaryTests {

    @Test("Portfolio intelligence separates stored value from provider quote coverage")
    func separatesStoredValueFromProviderQuoteCoverage() {
        let fetchedAt = date("2026-05-30")
        let fire = stock(
            symbol: "FIRE",
            currentPrice: 2,
            sharesOwned: 100,
            foundedDate: date(month: 4, day: 1, year: 2000)
        )
        let earth = stock(
            symbol: "EARTH",
            currentPrice: 200,
            sharesOwned: 1,
            foundedDate: date(month: 5, day: 1, year: 2000)
        )

        let summary = PortfolioIntelligenceSummary.make(
            holdings: [fire, earth],
            quoteProvenanceBySymbol: [
                "FIRE": .live(provider: FinancialDataProvenance.finnhubProvider, fetchedAt: fetchedAt)
            ],
            correlationSummaries: []
        )

        #expect(isClose(summary.totalStoredValue, 400))
        #expect(summary.totalStoredValueProvenance.indicatorLabel == "Stored data")
        #expect(isClose(summary.providerQuoteCoverage, 0.5))
        #expect(isClose(summary.providerQuoteValue, 200))

        if case .mixed(let reason) = summary.providerQuoteProvenance {
            #expect(reason.contains("50%"))
        } else {
            Issue.record("Partial provider quote coverage should be mixed provenance")
        }
    }

    @Test("Unknown-founded holdings are excluded from zodiac and element denominators")
    func unknownFoundedHoldingsStayOutOfCosmicDenominators() {
        let verified = stock(
            symbol: "KNOWN",
            currentPrice: 10,
            sharesOwned: 10,
            foundedDate: date(month: 4, day: 1, year: 2000)
        )
        let unknown = stock(
            symbol: "UNKNOWN",
            currentPrice: 1000,
            sharesOwned: 1,
            foundedDate: nil
        )

        let summary = PortfolioIntelligenceSummary.make(
            holdings: [verified, unknown],
            quoteProvenanceBySymbol: [:],
            correlationSummaries: []
        )

        #expect(isClose(summary.totalStoredValue, 1100))
        #expect(isClose(summary.verifiedAstrologyCoverage, 100.0 / 1100.0))
        #expect(summary.unknownFoundedCount == 1)
        #expect(isClose(summary.unknownFoundedValue, 1000))
        #expect(summary.elementDistribution.first?.label == ZodiacSign.Element.fire.displayName)
        #expect(isClose(summary.elementDistribution.first?.percentage ?? 0, 1))
        #expect(summary.zodiacDistribution.first?.label == ZodiacSign.aries.displayName)
        #expect(isClose(summary.zodiacDistribution.first?.percentage ?? 0, 1))
    }

    @Test("Portfolio intelligence cosmic distribution is market-value weighted")
    func cosmicDistributionUsesMarketValueWeighting() {
        let shareHeavy = stock(
            symbol: "SHARE",
            currentPrice: 2,
            sharesOwned: 100,
            foundedDate: date(month: 4, day: 1, year: 2000)
        )
        let valueHeavy = stock(
            symbol: "VALUE",
            currentPrice: 200,
            sharesOwned: 1,
            foundedDate: date(month: 5, day: 1, year: 2000)
        )

        let summary = PortfolioIntelligenceSummary.make(
            holdings: [shareHeavy, valueHeavy],
            quoteProvenanceBySymbol: [:],
            correlationSummaries: []
        )

        let fire = summary.elementDistribution.first { $0.label == ZodiacSign.Element.fire.displayName }
        let earth = summary.elementDistribution.first { $0.label == ZodiacSign.Element.earth.displayName }

        #expect(isClose(fire?.percentage ?? 0, 0.5))
        #expect(isClose(earth?.percentage ?? 0, 0.5))
        #expect(!isClose(fire?.percentage ?? 0, 0.990099, tolerance: 0.0001))
    }

    @Test("Low history coverage does not allow portfolio correlation headline metrics")
    func lowHistoryCoverageDoesNotAllowHeadlineMetrics() {
        let summary = PortfolioIntelligenceSummary.make(
            holdings: [
                stock(symbol: "LIVE", currentPrice: 60, sharesOwned: 10, foundedDate: date(month: 4, day: 1, year: 2000)),
                stock(symbol: "MISS", currentPrice: 40, sharesOwned: 10, foundedDate: date(month: 5, day: 1, year: 2000))
            ],
            quoteProvenanceBySymbol: [:],
            correlationSummaries: [
                portfolioSummary(
                    includedWeight: 0.60,
                    provenance: .mixed(reason: "Only 60% of portfolio value has provider-backed historical prices"),
                    displayMode: .partialCoverage
                )
            ]
        )

        #expect(isClose(summary.historyCoverage, 0.60))
        #expect(summary.allowsPortfolioCorrelationHeadlineMetrics == false)
        #expect(summary.correlationReadinessCopy.contains("70%"))
    }

    @Test("Portfolio intelligence does not expose fake daily P/L")
    func noFakeDailyPL() {
        #expect(PortfolioIntelligenceSummary.shouldShowDailyPL(provenance: .sample(reason: "Stored daily P/L")) == false)
        #expect(PortfolioIntelligenceSummary.shouldShowDailyPL(provenance: .unavailable(reason: "Provider quote unavailable")) == false)
        #expect(PortfolioIntelligenceSummary.shouldShowDailyPL(provenance: .mixed(reason: "Some quotes are stored")) == false)
        #expect(PortfolioIntelligenceSummary.shouldShowDailyPL(provenance: .live(provider: FinancialDataProvenance.finnhubProvider, fetchedAt: date("2026-05-30"))) == true)
        #expect(PortfolioIntelligenceSummary.shouldShowDailyPL(provenance: .cached(provider: FinancialDataProvenance.finnhubProvider, fetchedAt: date("2026-05-30"), age: 60)) == true)
    }

    @Test("Portfolio intelligence generated copy is compliance safe")
    func generatedCopyIsComplianceSafe() {
        let summary = PortfolioIntelligenceSummary.make(
            holdings: [stock(symbol: "AAPL", currentPrice: 100, sharesOwned: 1, foundedDate: date(month: 4, day: 1, year: 1976))],
            quoteProvenanceBySymbol: [:],
            correlationSummaries: []
        )
        let copy = [
            summary.correlationReadinessCopy,
            summary.totalStoredValueProvenance.accessibilityLabel,
            summary.providerQuoteProvenance.accessibilityLabel,
            summary.historyProvenance.accessibilityLabel
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
            #expect(!copy.contains(banned))
        }
    }

    private func portfolioSummary(
        includedWeight: Double,
        provenance: FinancialDataProvenance,
        displayMode: CorrelationDisplayMode
    ) -> PortfolioCosmicCorrelationSummary {
        PortfolioCosmicCorrelationSummary(
            id: "fullMoon",
            eventName: "Full Moon",
            eventType: .fullMoon,
            eventCount: 4,
            sampleSize: 0,
            window: CorrelationWindow(daysBefore: 1, daysAfter: 3),
            averagePortfolioReturn: nil,
            medianPortfolioReturn: nil,
            winRate: nil,
            baselinePortfolioReturn: nil,
            volatilityRatio: nil,
            maxDrawdown: nil,
            affectedHoldings: [],
            unavailableHoldings: ["MISS"],
            includedPortfolioWeight: includedWeight,
            excludedPortfolioWeight: max(0, 1 - includedWeight),
            provenance: provenance,
            confidence: .insufficient,
            displayMode: displayMode,
            disclaimer: "Historical portfolio context only. Correlation does not imply causation and this is not financial advice."
        )
    }

    private func stock(
        symbol: String,
        currentPrice: Double,
        sharesOwned: Double,
        purchasePrice: Double? = nil,
        foundedDate: Date?,
        sector: String = "Technology"
    ) -> Stock {
        Stock(
            symbol: symbol,
            name: "\(symbol) Corp.",
            currentPrice: currentPrice,
            priceChange: 0,
            percentageChange: 0,
            sharesOwned: sharesOwned,
            purchasePrice: purchasePrice,
            foundedDate: foundedDate,
            sector: sector
        )
    }

    private func date(_ value: String) -> Date {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter.date(from: value) ?? Date(timeIntervalSince1970: 0)
    }

    private func date(month: Int, day: Int, year: Int) -> Date {
        Calendar(identifier: .gregorian).date(from: DateComponents(year: year, month: month, day: day))
            ?? Date(timeIntervalSince1970: 0)
    }

    private func isClose(_ actual: Double, _ expected: Double, tolerance: Double = 0.0001) -> Bool {
        abs(actual - expected) <= tolerance
    }
}
