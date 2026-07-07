import SwiftUI

// MARK: - PortfolioPerformanceViewModel
// =====================================
// Loads the data behind the Portfolio > PERFORMANCE chart: a weighted
// portfolio-value line and an S&P 500 (SPY) benchmark, both drawn from the
// same provider-backed historical price service that powers the rest of the
// app's charts and the correlation coverage panel.
//
// The chart used to render permanently "unavailable" because its host view
// never loaded anything — this view model is the wiring that was missing.
//
// Loading (network) lives here, not in the view, per the app's view-size
// ratchet rule: views render state, view models orchestrate. The value/
// benchmark assembly is split into `nonisolated static` pure functions so
// the weighting and date-alignment can be unit tested without the network.

@Observable
final class PortfolioPerformanceViewModel {

    // MARK: - Rendered state

    private(set) var portfolioData: [PortfolioPoint] = []
    private(set) var benchmarkData: [PortfolioPoint] = []
    private(set) var provenance: FinancialDataProvenance = .unavailable(reason: "Portfolio history not loaded")
    private(set) var isLoading = false

    /// Owned symbols that had no usable provider-backed history for the
    /// selected timeframe and were left out of the line. Surfaced so the
    /// chart can stay honest about partial coverage.
    private(set) var excludedSymbols: [String] = []

    /// A performance line needs at least two portfolio points and a benchmark
    /// to compare against; below that the chart shows its unavailable state.
    var hasProviderBackedHistory: Bool {
        portfolioData.count >= 2 && benchmarkData.count >= 2
    }

    // MARK: - Dependencies

    private let historicalPriceService: HistoricalPriceService
    private let benchmarkSymbol = "SPY"

    /// Guards against a slow load landing after a newer one (timeframe taps
    /// fire loads faster than the network returns).
    private var loadGeneration = 0

    init(historicalPriceService: HistoricalPriceService = .shared) {
        self.historicalPriceService = historicalPriceService
    }

    // MARK: - Loading

    func load(holdings: [Stock], timeframe: ChartTimeframe) async {
        // Automation runs stay network-free, matching fetchLivePrices and
        // DiscoverViewModel — screenshots and UI tests must never depend on a
        // third-party history API.
        guard !AppState.isUITesting, !AppState.isScreenshotMode else {
            clear(reason: "History disabled under automation")
            return
        }

        let owned = holdings.filter { $0.isOwned && $0.sharesOwned > 0 }
        guard !owned.isEmpty else {
            clear(reason: "No owned holdings to chart")
            return
        }

        loadGeneration += 1
        let generation = loadGeneration
        isLoading = true

        // Fetch every holding's history concurrently, plus the benchmark.
        let holdingResults = await withTaskGroup(
            of: (Stock, HistoricalPriceResult?).self
        ) { group -> [(Stock, HistoricalPriceResult?)] in
            for stock in owned {
                group.addTask { [historicalPriceService] in
                    let result = try? await historicalPriceService.fetchHistoricalPriceResult(
                        symbol: stock.symbol,
                        timeframe: timeframe
                    )
                    return (stock, result)
                }
            }
            var collected: [(Stock, HistoricalPriceResult?)] = []
            for await item in group { collected.append(item) }
            return collected
        }

        let benchmarkResult = try? await historicalPriceService.fetchHistoricalPriceResult(
            symbol: benchmarkSymbol,
            timeframe: timeframe
        )

        // A newer load superseded this one while awaiting — drop the result.
        guard generation == loadGeneration else { return }

        var included: [(shares: Double, candles: [OHLCData])] = []
        var excluded: [String] = []
        var provenances: [FinancialDataProvenance] = []

        for (stock, result) in holdingResults {
            if let result, result.data.count >= 2 {
                included.append((shares: stock.sharesOwned, candles: result.data))
                provenances.append(result.provenance)
            } else {
                excluded.append(stock.symbol)
            }
        }

        let portfolioSeries = Self.buildPortfolioSeries(holdings: included)

        var benchmarkSeries: [PortfolioPoint] = []
        if let benchmarkResult,
           benchmarkResult.data.count >= 2,
           let startValue = portfolioSeries.first?.value {
            benchmarkSeries = Self.scaleBenchmark(
                benchmarkResult.data,
                toStartValue: startValue,
                alignedTo: portfolioSeries.map(\.date)
            )
            if !benchmarkSeries.isEmpty {
                provenances.append(benchmarkResult.provenance)
            }
        }

        portfolioData = portfolioSeries
        benchmarkData = benchmarkSeries
        excludedSymbols = excluded.sorted()
        provenance = Self.aggregateProvenance(provenances)
        isLoading = false
    }

    private func clear(reason: String) {
        portfolioData = []
        benchmarkData = []
        excludedSymbols = []
        provenance = .unavailable(reason: reason)
        isLoading = false
    }

    // MARK: - Pure assembly (unit tested)

    /// Weighted portfolio value at each trading date. The series starts at the
    /// latest first-candle date across holdings so every point reflects all
    /// included holdings (a holding whose history starts later never causes a
    /// phantom jump). Each holding's contribution uses its most recent close
    /// on or before the date (forward-fill) so mismatched calendars align.
    nonisolated static func buildPortfolioSeries(
        holdings: [(shares: Double, candles: [OHLCData])]
    ) -> [PortfolioPoint] {
        let series = holdings
            .map { (shares: $0.shares, sorted: $0.candles.sorted { $0.date < $1.date }) }
            .filter { !$0.sorted.isEmpty }

        guard !series.isEmpty,
              let startDate = series.compactMap({ $0.sorted.first?.date }).max() else {
            return []
        }

        var dateSet = Set<Date>()
        for holding in series {
            for candle in holding.sorted where candle.date >= startDate {
                dateSet.insert(candle.date)
            }
        }
        let dates = dateSet.sorted()
        guard dates.count >= 2 else { return [] }

        return dates.map { date in
            let value = series.reduce(0.0) { total, holding in
                total + holding.shares * closeAsOf(date, in: holding.sorted)
            }
            return PortfolioPoint(date: date, value: value)
        }
    }

    /// Rebases the benchmark to the portfolio's starting value so both lines
    /// share one dollar axis: benchmark(date) = startValue × close(date) /
    /// close(firstDate). Sampled on the portfolio's own dates.
    nonisolated static func scaleBenchmark(
        _ candles: [OHLCData],
        toStartValue startValue: Double,
        alignedTo dates: [Date]
    ) -> [PortfolioPoint] {
        let sorted = candles.sorted { $0.date < $1.date }
        guard let baseDate = dates.first, !sorted.isEmpty else { return [] }

        let anchorClose = closeAsOf(baseDate, in: sorted)
        guard anchorClose > 0 else { return [] }

        return dates.map { date in
            let close = closeAsOf(date, in: sorted)
            return PortfolioPoint(date: date, value: startValue * (close / anchorClose))
        }
    }

    /// Most recent close on or before `date`; falls back to the earliest close
    /// so dates before a series begins still resolve to a real number.
    nonisolated static func closeAsOf(_ date: Date, in sorted: [OHLCData]) -> Double {
        var result = sorted.first?.close ?? 0
        for candle in sorted {
            if candle.date <= date {
                result = candle.close
            } else {
                break
            }
        }
        return result
    }

    /// Worst-of across the fetched series: all-live → live (newest), all
    /// provider-backed → cached (oldest, the most conservative age), otherwise
    /// mixed. Mirrors the aggregation used for all-time P/L.
    nonisolated static func aggregateProvenance(
        _ provenances: [FinancialDataProvenance]
    ) -> FinancialDataProvenance {
        guard !provenances.isEmpty else {
            return .unavailable(reason: "No provider-backed history for holdings")
        }

        let provider = provenances.compactMap { provenance -> String? in
            switch provenance {
            case .live(let name, _), .cached(let name, _, _): return name
            case .mixed, .unavailable, .sample: return nil
            }
        }.first ?? "provider"

        let liveDates = provenances.compactMap { provenance -> Date? in
            if case .live(_, let fetchedAt) = provenance { return fetchedAt }
            return nil
        }
        if liveDates.count == provenances.count, let newest = liveDates.max() {
            return .live(provider: provider, fetchedAt: newest)
        }

        if provenances.allSatisfy(\.isProviderBacked) {
            let oldest = provenances.compactMap(\.fetchedAt).min() ?? Date()
            return .cached(provider: provider, fetchedAt: oldest, now: Date())
        }

        return .mixed(reason: "Some holdings lack provider-backed history")
    }
}
