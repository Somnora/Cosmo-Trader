import Foundation
import Testing
@testable import Cosmo_Trader

struct StockTechnicalAnalysisServiceTests {
    private let service = StockTechnicalAnalysisService.shared

    @Test("RSI requires enough real candles")
    func rsiRequiresEnoughRealCandles() {
        let shortSummary = service.summary(for: providerDataset(count: 14))
        let enoughSummary = service.summary(for: providerDataset(count: 20))

        #expect(shortSummary.metrics == nil)
        #expect(enoughSummary.metrics?.rsi14 != nil)
    }

    @Test("Moving averages require enough real candles")
    func movingAveragesRequireEnoughRealCandles() {
        let shortSummary = service.summary(for: providerDataset(count: 19))
        let summary = service.summary(for: providerDataset(count: 60))

        #expect(shortSummary.metrics == nil)
        #expect(summary.metrics?.movingAverage20 != nil)
        #expect(summary.metrics?.movingAverage50 != nil)
        #expect(summary.metrics?.movingAverage200 == nil)
    }

    @Test("200D moving average is withheld when fewer than 200 usable candles exist")
    func movingAverage200RequiresTwoHundredCandles() {
        let underSummary = service.summary(for: providerDataset(count: 199))
        let enoughSummary = service.summary(for: providerDataset(count: 220))

        #expect(underSummary.metrics?.movingAverage200 == nil)
        #expect(enoughSummary.metrics?.movingAverage200 != nil)
    }

    @Test("Sample unavailable mixed partial and insufficient data produce no numeric technical claims")
    func unsafeDatasetsProduceNoNumericTechnicalClaims() {
        let summaries = [
            service.summary(for: sampleDataset(count: 220)),
            service.summary(for: unavailableDataset(count: 220)),
            service.summary(for: mixedDataset(count: 220)),
            service.summary(for: partialDataset(count: 30)),
            service.summary(for: providerDataset(count: 1))
        ]

        #expect(summaries.allSatisfy { !$0.hasNumericClaims })
    }

    @Test("Stale data is labeled stale and withholds metrics")
    func staleDataIsLabeledStale() {
        let summary = service.summary(for: providerDataset(
            count: 220,
            provenance: .cached(
                provider: FinancialDataProvenance.finnhubProvider,
                fetchedAt: date(dayOffset: -3),
                age: FinancialDataProvenance.defaultCachedStaleInterval + 60
            )
        ))

        #expect(summary.metrics == nil)
        #expect(summary.provenance.isCachedStale())
        #expect(summary.displayMode == .staleCached)
        #expect(summary.headline == "Stale cached history")
    }

    @Test("Support and resistance candidates are withheld when candles are insufficient")
    func supportResistanceRequiresEnoughCandles() {
        let underSummary = service.summary(for: providerDataset(count: 59))
        let enoughSummary = service.summary(for: providerDataset(count: 60))

        #expect(underSummary.metrics?.supportResistance == nil)
        #expect(enoughSummary.metrics?.supportResistance != nil)
    }

    @Test("Generated technical copy contains no banned trading instruction phrases")
    func generatedCopyIsComplianceSafe() {
        let summaries = [
            service.summary(for: providerDataset(count: 220)),
            service.summary(for: sampleDataset(count: 220)),
            service.summary(for: partialDataset(count: 30)),
            service.summary(for: providerDataset(
                count: 220,
                provenance: .cached(
                    provider: FinancialDataProvenance.finnhubProvider,
                    fetchedAt: date(dayOffset: -3),
                    age: FinancialDataProvenance.defaultCachedStaleInterval + 60
                )
            ))
        ]

        let copy = summaries.flatMap { summary in
            [
                summary.headline,
                summary.explanation,
                summary.provenance.indicatorLabel,
                summary.provenance.shortLabel
            ]
        }

        let violations = copy.flatMap(copyViolations)
        if !violations.isEmpty {
            Issue.record("Technical copy violations: \(violations.joined(separator: ", "))")
        }
        #expect(violations.isEmpty)
    }

    @Test("Stock Detail unavailable state renders cleanly")
    func stockDetailUnavailableStateRendersCleanly() {
        let summary = service.unavailableSummary(
            symbol: "AAPL",
            reason: "Provider-backed historical candles unavailable"
        )
        let view = StockTechnicalAnalysisView(
            summary: summary,
            isLoading: false,
            refreshAction: nil
        )

        #expect(summary.metrics == nil)
        #expect(summary.headline == "Technical lens unavailable")
        #expect(summary.explanation.contains("Provider-backed complete candles"))
        #expect(String(describing: type(of: view)) == "StockTechnicalAnalysisView")
    }

    private func providerDataset(
        count: Int,
        provenance: FinancialDataProvenance? = nil
    ) -> HistoricalPriceDataset {
        let candles = candles(count: count)
        let start = candles.first?.date ?? date(dayOffset: 0)
        let end = candles.last?.date ?? start
        let fetchedAt = date(dayOffset: 1)
        return HistoricalPriceDataset.providerBacked(
            symbol: "AAPL",
            candles: candles,
            provider: FinancialDataProvenance.finnhubProvider,
            fetchedAt: fetchedAt,
            requestedRange: DateInterval(start: start, end: end),
            provenance: provenance ?? .live(provider: FinancialDataProvenance.finnhubProvider, fetchedAt: fetchedAt)
        )
    }

    private func partialDataset(count: Int) -> HistoricalPriceDataset {
        let candles = candles(count: count)
        let fetchedAt = date(dayOffset: 1)
        return HistoricalPriceDataset.providerBacked(
            symbol: "AAPL",
            candles: candles,
            provider: FinancialDataProvenance.finnhubProvider,
            fetchedAt: fetchedAt,
            requestedRange: DateInterval(start: date(dayOffset: -180), end: fetchedAt),
            provenance: .live(provider: FinancialDataProvenance.finnhubProvider, fetchedAt: fetchedAt)
        )
    }

    private func sampleDataset(count: Int) -> HistoricalPriceDataset {
        directDataset(
            count: count,
            provenance: .sample(reason: "Preview only"),
            completeness: .complete
        )
    }

    private func unavailableDataset(count: Int) -> HistoricalPriceDataset {
        directDataset(
            count: count,
            provenance: .unavailable(reason: "Provider unavailable"),
            completeness: .complete
        )
    }

    private func mixedDataset(count: Int) -> HistoricalPriceDataset {
        directDataset(
            count: count,
            provenance: .mixed(reason: "Mixed technical dataset"),
            completeness: .complete
        )
    }

    private func directDataset(
        count: Int,
        provenance: FinancialDataProvenance,
        completeness: HistoricalDatasetCompleteness
    ) -> HistoricalPriceDataset {
        let candles = candles(count: count)
        let start = candles.first?.date ?? date(dayOffset: 0)
        let end = candles.last?.date ?? start
        return HistoricalPriceDataset(
            symbol: "AAPL",
            candles: candles.map(HistoricalPricePoint.init(candle:)),
            provider: "Unit Test",
            fetchedAt: end,
            requestedRange: DateInterval(start: start, end: end),
            actualRange: DateInterval(start: start, end: end),
            provenance: provenance,
            completeness: completeness
        )
    }

    private func candles(count: Int) -> [OHLCData] {
        guard count > 0 else { return [] }

        return (0..<count).map { index in
            let close = 100 + Double(index) * 0.35
            let open = close - 0.15
            let high = close + 1.25
            let low = max(0.01, open - 1.15)
            return OHLCData(
                date: date(dayOffset: index),
                open: open,
                high: high,
                low: low,
                close: close,
                volume: 1_000_000 + index * 1_000
            )
        }
    }

    private func date(dayOffset: Int) -> Date {
        Calendar(identifier: .gregorian).date(
            byAdding: .day,
            value: dayOffset,
            to: Date(timeIntervalSince1970: 1_700_000_000)
        ) ?? Date(timeIntervalSince1970: 1_700_000_000)
    }

    private func copyViolations(in copy: String) -> [String] {
        let lowered = copy.lowercased()
        let banned = [
            "buy",
            "sell",
            "hold",
            "avoid",
            "take profits",
            "reduce exposure",
            "position size",
            "expected upside",
            "expected downside",
            "prediction",
            "trade signal",
            "trading signal"
        ]

        return banned.filter { phrase in
            if phrase == "prediction", lowered.contains("not a prediction") {
                return false
            }
            if phrase == "buy", lowered.contains("not a buy or sell") {
                return false
            }
            if phrase == "sell", lowered.contains("not a buy or sell") {
                return false
            }
            return lowered.range(of: "\\b\(NSRegularExpression.escapedPattern(for: phrase))\\b", options: .regularExpression) != nil
        }
    }
}
