import Foundation
import SwiftUI
import Testing
@testable import Cosmo_Trader

@MainActor
struct HistoricalChartOverlayPolishTests {

    @Test("Provider history chart controls expose daily history windows")
    func providerHistoryChartControlsExposeRequestedWindows() {
        #expect(ChartTimeframe.providerHistoryCases == [
            .month,
            .threeMonth,
            .sixMonth,
            .year,
            .twoYear
        ])
        #expect(ChartTimeframe.providerHistoryCases.map(\.rawValue) == ["1M", "3M", "6M", "1Y", "2Y"])
    }

    @Test("Two-year timeframe requests provider daily candles")
    func twoYearTimeframeRequestsProviderDailyCandles() {
        let now = date("2026-06-12")
        let service = HistoricalPriceService.testingInstance(
            historicalPriceCache: HistoricalPriceCache(directoryURL: temporaryDirectory()),
            nowProvider: { now },
            candleFetcher: { _, _, _, _ in
                FinnhubCandleResponse(s: "no_data", t: [], o: [], h: [], l: [], c: [], v: [])
            }
        )

        let request = service.requestParameters(for: .twoYear)

        #expect(request.resolution == "D")
        #expect(Calendar(identifier: .gregorian).dateComponents([.day], from: request.from, to: request.to).day ?? 0 >= 720)
    }

    @Test("Chart rendering requires provider-backed complete history")
    func chartRenderingRequiresProviderBackedCompleteHistory() {
        let candles = providerCandles(count: 60)
        let fetchedAt = date("2026-06-12")

        #expect(HistoricalAstroChartViewModel.allowsChartRendering(
            prices: candles,
            provenance: .live(provider: FinancialDataProvenance.finnhubProvider, fetchedAt: fetchedAt),
            completeness: .complete
        ))

        #expect(!HistoricalAstroChartViewModel.allowsChartRendering(
            prices: candles,
            provenance: .sample(reason: "Preview fixture"),
            completeness: .complete
        ))

        #expect(!HistoricalAstroChartViewModel.allowsChartRendering(
            prices: candles,
            provenance: .unavailable(reason: "Provider-backed history unavailable"),
            completeness: .complete
        ))

        #expect(!HistoricalAstroChartViewModel.allowsChartRendering(
            prices: candles,
            provenance: .mixed(reason: "Partial historical dataset"),
            completeness: .partial(reason: "Provider returned a limited portion of the requested range")
        ))

        #expect(!HistoricalAstroChartViewModel.allowsChartRendering(
            prices: Array(candles.prefix(1)),
            provenance: .live(provider: FinancialDataProvenance.finnhubProvider, fetchedAt: fetchedAt),
            completeness: .insufficient(reason: "Provider returned fewer than two historical candles")
        ))
    }

    @Test("Partial and insufficient datasets surface unavailable chart copy")
    func partialAndInsufficientDatasetsSurfaceUnavailableCopy() {
        let viewModel = HistoricalAstroChartViewModel()

        viewModel.historicalPriceProvenance = .mixed(reason: "Partial historical dataset")
        viewModel.historicalDatasetCompleteness = .partial(reason: "Provider returned a limited portion of the requested range")
        viewModel.ohlcData = providerCandles(count: 60)

        #expect(!viewModel.canRenderHistoricalChart)
        #expect(viewModel.chartUnavailableMessage.contains("Partial historical dataset"))
        #expect(viewModel.chartUnavailableMessage.contains("complete provider-backed history"))

        viewModel.historicalPriceProvenance = .unavailable(reason: "Insufficient historical dataset")
        viewModel.historicalDatasetCompleteness = .insufficient(reason: "Provider returned fewer than two historical candles")
        viewModel.ohlcData = []

        #expect(!viewModel.canRenderHistoricalChart)
        #expect(viewModel.chartUnavailableMessage.contains("Insufficient historical dataset"))
        #expect(viewModel.chartUnavailableMessage.contains("provider-backed history"))
    }

    @Test("Historical chart copy remains non-advisory")
    func historicalChartCopyRemainsNonAdvisory() {
        let viewModel = HistoricalAstroChartViewModel()
        let copy = [
            viewModel.chartUnavailableMessage,
            "Provider-backed historical price action aligned with cosmic event windows.",
            "Historical overlay only. Correlation view, not financial advice.",
            "Chart overlays will appear when complete provider-backed history is available."
        ].joined(separator: "\n").lowercased()

        for banned in [
            "buy signal",
            "sell signal",
            "take profits",
            "reduce exposure",
            "reduce position",
            "position size",
            "expected upside",
            "expected downside",
            "trade signal",
            "trading signal"
        ] {
            #expect(!copy.contains(banned), "Unexpected trading-instruction copy: \(banned)")
        }
    }

    @Test("Chart views can instantiate unavailable states without sample data")
    func chartViewsInstantiateUnavailableStatesWithoutSampleData() {
        let stock = Stock(
            symbol: "TEST",
            name: "Test Co",
            currentPrice: 100,
            priceChange: 0,
            percentageChange: 0,
            volatility: 0,
            volume: 0,
            avgVolume: 0,
            sharesOwned: 0,
            purchasePrice: 0,
            purchaseDate: nil,
            foundedDate: nil,
            sector: "Technology"
        )

        let timeframe = Binding.constant(ChartTimeframe.month)
        _ = StockChartView(stock: stock, selectedTimeframe: timeframe)
        _ = HistoricalAstroChartView(stock: stock, selectedTimeframe: timeframe)
    }

    private func providerCandles(count: Int) -> [OHLCData] {
        let start = date("2026-01-01")
        return (0..<count).map { index in
            let candleDate = Calendar(identifier: .gregorian).date(byAdding: .day, value: index, to: start) ?? start
            let close = 100 + Double(index) * 0.5
            return OHLCData(
                date: candleDate,
                open: close - 0.5,
                high: close + 1,
                low: close - 1,
                close: close,
                volume: 1_000_000 + index
            )
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

    private func temporaryDirectory() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("cosmo-chart-overlay-polish-\(UUID().uuidString)", isDirectory: true)
    }
}
