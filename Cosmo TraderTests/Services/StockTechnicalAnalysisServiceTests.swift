import Foundation
import Testing
@testable import Cosmo_Trader

struct StockTechnicalAnalysisServiceTests {

    @Test("Moving averages require enough provider-backed candles")
    func movingAveragesRequireEnoughProviderBackedCandles() {
        let service = StockTechnicalAnalysisService()

        let shortSummary = service.summary(
            symbol: "AAPL",
            dataset: providerDataset(closes: Array(1...49).map(Double.init))
        )
        #expect(shortSummary.movingAverage20 != nil)
        #expect(shortSummary.movingAverage50 == nil)

        let fullSummary = service.summary(
            symbol: "AAPL",
            dataset: providerDataset(closes: Array(1...50).map(Double.init))
        )
        #expect(fullSummary.movingAverage20 == average(Array(31...50).map(Double.init)))
        #expect(fullSummary.movingAverage50 == average(Array(1...50).map(Double.init)))
        #expect(fullSummary.displayMode == .providerBacked)
    }

    @Test("RSI requires enough real candles")
    func rsiRequiresEnoughRealCandles() {
        let service = StockTechnicalAnalysisService()

        let tooShort = service.summary(
            symbol: "AAPL",
            dataset: providerDataset(closes: Array(1...14).map(Double.init))
        )
        #expect(tooShort.rsi14 == nil)
        #expect(tooShort.momentumContext.contains("15 provider-backed candles"))

        let enough = service.summary(
            symbol: "AAPL",
            dataset: providerDataset(closes: Array(1...15).map(Double.init))
        )
        #expect(enough.rsi14 == 100)
    }

    @Test("Sample unavailable partial and insufficient datasets produce no numeric technical claims")
    func unsafeDatasetsProduceNoNumericTechnicalClaims() {
        let service = StockTechnicalAnalysisService()
        let closes = Array(1...80).map(Double.init)

        let sample = service.summary(
            symbol: "AAPL",
            dataset: dataset(
                closes: closes,
                provenance: .sample(reason: "Preview fixture"),
                completeness: .complete
            )
        )
        assertNoNumericMetrics(sample)
        #expect(sample.displayMode == .sampleOnly)

        let unavailable = service.summary(
            symbol: "AAPL",
            dataset: dataset(
                closes: closes,
                provenance: .unavailable(reason: "Provider unavailable"),
                completeness: .complete
            )
        )
        assertNoNumericMetrics(unavailable)
        #expect(unavailable.displayMode == .unavailable)

        let partial = service.summary(
            symbol: "AAPL",
            dataset: dataset(
                closes: closes,
                provenance: .live(provider: FinancialDataProvenance.finnhubProvider, fetchedAt: date("2026-01-01")),
                completeness: .partial(reason: "Provider returned a limited portion of the requested range")
            )
        )
        assertNoNumericMetrics(partial)
        #expect(partial.displayMode == .partialDataset)

        let insufficient = service.summary(
            symbol: "AAPL",
            dataset: dataset(
                closes: closes,
                provenance: .live(provider: FinancialDataProvenance.finnhubProvider, fetchedAt: date("2026-01-01")),
                completeness: .insufficient(reason: "Provider returned too few candles")
            )
        )
        assertNoNumericMetrics(insufficient)
        #expect(insufficient.displayMode == .insufficientDataset)
    }

    @Test("Stale provider-backed data is labeled while preserving numeric context")
    func staleProviderBackedDataIsLabeled() {
        let fetchedAt = date("2026-01-01")
        let stale = serviceSummary(
            closes: Array(1...80).map(Double.init),
            provenance: .cached(
                provider: FinancialDataProvenance.finnhubProvider,
                fetchedAt: fetchedAt,
                age: HistoricalPriceDataset.defaultStaleInterval + 120
            )
        )

        #expect(stale.displayMode == .staleProviderBacked)
        #expect(stale.provenance.indicatorLabel == "Finnhub stale")
        #expect(stale.freshnessLabel == "Finnhub stale cached history")
        #expect(stale.movingAverage20 != nil)
        #expect(stale.rsi14 != nil)
    }

    @Test("Generated technical copy avoids trading-instruction phrases")
    func generatedTechnicalCopyAvoidsTradingInstructionPhrases() {
        let summary = serviceSummary(closes: Array(1...80).map(Double.init))
        let displayedCopy = [
            summary.trendContext,
            summary.momentumContext,
            summary.volumeContext,
            summary.volatilityContext,
            summary.rangeContext,
            summary.explanation,
            StockTechnicalSummary.disclaimer,
            StockTechnicalSummary.unavailableTitle
        ].joined(separator: "\n").lowercased()

        for banned in bannedTradingInstructionPhrases {
            #expect(!displayedCopy.contains(banned), "Unsafe phrase found: \(banned)")
        }
    }

    @Test("Stock Detail unavailable state copy is explicit and non numeric")
    func stockDetailUnavailableStateCopyIsExplicitAndNonNumeric() {
        let summary = StockTechnicalSummary.unavailable(symbol: "AAPL")

        #expect(summary.displayMode == .unavailable)
        #expect(!summary.canShowNumericMetrics)
        #expect(StockTechnicalSummary.unavailableTitle == "Technical context unavailable")
        #expect(summary.unavailableDetail.contains("Provider-backed historical candles are unavailable"))
        assertNoNumericMetrics(summary)
    }

    private var bannedTradingInstructionPhrases: [String] {
        [
            "buy",
            "sell",
            "hold",
            "take profit",
            "reduce exposure",
            "reduce position",
            "position size",
            "expected upside",
            "expected downside",
            "trade signal",
            "prediction"
        ]
    }

    private func serviceSummary(
        closes: [Double],
        provenance: FinancialDataProvenance? = nil
    ) -> StockTechnicalSummary {
        let resolvedProvenance = provenance ?? .live(
            provider: FinancialDataProvenance.finnhubProvider,
            fetchedAt: date("2026-01-01")
        )
        return StockTechnicalAnalysisService().summary(
            symbol: "AAPL",
            dataset: dataset(closes: closes, provenance: resolvedProvenance, completeness: .complete)
        )
    }

    private func assertNoNumericMetrics(_ summary: StockTechnicalSummary) {
        #expect(!summary.canShowNumericMetrics)
        #expect(summary.latestClose == nil)
        #expect(summary.movingAverage20 == nil)
        #expect(summary.movingAverage50 == nil)
        #expect(summary.rsi14 == nil)
        #expect(summary.latestVolume == nil)
        #expect(summary.averageVolume20 == nil)
        #expect(summary.volumeRatio20 == nil)
        #expect(summary.averageAbsoluteMove20 == nil)
        #expect(summary.recentRangeLow == nil)
        #expect(summary.recentRangeHigh == nil)
        #expect(summary.supportCandidate == nil)
        #expect(summary.resistanceCandidate == nil)
    }

    private func providerDataset(closes: [Double]) -> HistoricalPriceDataset {
        dataset(
            closes: closes,
            provenance: .live(provider: FinancialDataProvenance.finnhubProvider, fetchedAt: date("2026-01-01")),
            completeness: .complete
        )
    }

    private func dataset(
        closes: [Double],
        provenance: FinancialDataProvenance,
        completeness: HistoricalDatasetCompleteness
    ) -> HistoricalPriceDataset {
        let candles = prices(closes)
        let requestedRange = DateInterval(
            start: candles.first?.date ?? date("2026-01-01"),
            end: candles.last?.date ?? date("2026-01-01")
        )
        return HistoricalPriceDataset(
            symbol: "AAPL",
            candles: candles.map(HistoricalPricePoint.init(candle:)),
            provider: provenance.provider ?? "Test",
            fetchedAt: provenance.fetchedAt ?? date("2026-01-01"),
            requestedRange: requestedRange,
            actualRange: requestedRange,
            provenance: provenance,
            completeness: completeness
        )
    }

    private func prices(_ closes: [Double]) -> [OHLCData] {
        closes.enumerated().map { index, close in
            let open = max(0.01, close - 0.25)
            return OHLCData(
                date: Calendar.current.date(byAdding: .day, value: index, to: date("2026-01-01")) ?? date("2026-01-01"),
                open: open,
                high: close + 1,
                low: max(0.01, close - 1),
                close: close,
                volume: 1_000 + index
            )
        }
    }

    private func average(_ values: [Double]) -> Double {
        values.reduce(0, +) / Double(values.count)
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
