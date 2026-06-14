import Foundation

nonisolated final class HistoricalPriceCache {
    static let shared = HistoricalPriceCache()

    private let fileManager: FileManager
    private let directoryURL: URL
    private let nowProvider: () -> Date

    init(
        directoryURL: URL? = nil,
        fileManager: FileManager = .default,
        nowProvider: @escaping () -> Date = Date.init
    ) {
        self.fileManager = fileManager
        self.directoryURL = directoryURL ?? Self.defaultDirectoryURL(fileManager: fileManager)
        self.nowProvider = nowProvider
    }

    func dataset(
        symbol: String,
        timeframe: ChartTimeframe,
        resolution: String,
        now: Date? = nil
    ) -> HistoricalPriceDataset? {
        let url = cacheFileURL(symbol: symbol, timeframe: timeframe, resolution: resolution)
        guard fileManager.fileExists(atPath: url.path),
              let data = try? Data(contentsOf: url),
              let decoded = try? decoder.decode(HistoricalPriceDataset.self, from: data),
              decoded.provenance.isProviderBacked,
              !decoded.candles.isEmpty else {
            return nil
        }

        let currentDate = now ?? nowProvider()
        return decoded.withProvenance(
            .cached(provider: decoded.provider, fetchedAt: decoded.fetchedAt, now: currentDate)
        )
    }

    func store(
        dataset: HistoricalPriceDataset,
        timeframe: ChartTimeframe,
        resolution: String
    ) throws {
        guard dataset.provenance.isProviderBacked,
              !dataset.candles.isEmpty else {
            return
        }

        try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        let url = cacheFileURL(symbol: dataset.symbol, timeframe: timeframe, resolution: resolution)
        let data = try encoder.encode(dataset)
        try data.write(to: url, options: [.atomic])
    }

    func removeAll() throws {
        guard fileManager.fileExists(atPath: directoryURL.path) else { return }
        try fileManager.removeItem(at: directoryURL)
    }

    private func cacheFileURL(symbol: String, timeframe: ChartTimeframe, resolution: String) -> URL {
        let key = [
            sanitized(symbol.uppercased()),
            sanitized(timeframe.rawValue),
            sanitized(resolution)
        ].joined(separator: "_")
        return directoryURL.appendingPathComponent("\(key).json")
    }

    private func sanitized(_ value: String) -> String {
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "._-"))
        let scalars = value.unicodeScalars.map { scalar in
            allowed.contains(scalar) ? Character(scalar) : "_"
        }
        return String(scalars)
    }

    private static func defaultDirectoryURL(fileManager: FileManager) -> URL {
        let baseURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? fileManager.temporaryDirectory

        #if DEBUG
        if let fixtureURL = ProviderBackedChartFixtureSeeder.isolatedCacheDirectoryURL(
            fileManager: fileManager,
            arguments: Set(CommandLine.arguments)
        ) {
            return fixtureURL
        }
        #endif

        return baseURL
            .appendingPathComponent("Cosmo Trader", isDirectory: true)
            .appendingPathComponent("HistoricalPriceCache", isDirectory: true)
    }

    private var encoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.sortedKeys]
        return encoder
    }

    private var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}

#if DEBUG
nonisolated enum ProviderBackedChartFixtureSeeder {
    static let launchFlag = "--provider-chart-fixture"
    static let staleFlag = "--provider-chart-fixture-stale"
    static let symbolPrefix = "--provider-chart-fixture-symbol="
    static let providerName = "UI Test Fixture Provider"
    static let cacheDirectoryName = "HistoricalPriceCacheUITestFixtures"

    static func shouldSeed(arguments: Set<String>) -> Bool {
        arguments.contains("--uitesting") && arguments.contains(launchFlag)
    }

    static func isolatedCacheDirectoryURL(
        fileManager: FileManager,
        arguments: Set<String>
    ) -> URL? {
        guard shouldSeed(arguments: arguments) else { return nil }
        let baseURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? fileManager.temporaryDirectory
        return baseURL
            .appendingPathComponent("Cosmo Trader", isDirectory: true)
            .appendingPathComponent(cacheDirectoryName, isDirectory: true)
    }

    @discardableResult
    static func seedIfRequested(
        arguments: Set<String>,
        cache: HistoricalPriceCache = .shared,
        now: Date = Date()
    ) throws -> [String: Int] {
        guard shouldSeed(arguments: arguments) else { return [:] }

        try cache.removeAll()

        let stale = arguments.contains(staleFlag)
        var seededCounts: [String: Int] = [:]

        for symbol in symbols(from: arguments) {
            for timeframe in ChartTimeframe.allCases {
                let fixture = dataset(symbol: symbol, timeframe: timeframe, now: now, stale: stale)
                let request = requestParameters(for: timeframe, now: now)
                try cache.store(
                    dataset: fixture,
                    timeframe: timeframe,
                    resolution: request.resolution
                )
                seededCounts["\(symbol)-\(timeframe.rawValue)"] = fixture.candles.count
            }
        }

        return seededCounts
    }

    static func dataset(
        symbol: String,
        timeframe: ChartTimeframe,
        now: Date,
        stale: Bool = false
    ) -> HistoricalPriceDataset {
        let request = requestParameters(for: timeframe, now: now)
        let candles = fixtureCandles(symbol: symbol, timeframe: timeframe, now: now)
        let fetchedAt = stale
            ? now.addingTimeInterval(-(FinancialDataProvenance.defaultCachedStaleInterval + 3_600))
            : now.addingTimeInterval(-3_600)

        return HistoricalPriceDataset.providerBacked(
            symbol: symbol,
            candles: candles,
            provider: providerName,
            fetchedAt: fetchedAt,
            requestedRange: DateInterval(start: request.from, end: request.to),
            provenance: .cached(
                provider: providerName,
                fetchedAt: fetchedAt,
                age: now.timeIntervalSince(fetchedAt)
            )
        )
    }

    static func symbols(from arguments: Set<String>) -> [String] {
        var symbols = Set(["AAPL"])

        for argument in arguments where argument.hasPrefix(symbolPrefix) {
            let symbol = argument.replacingOccurrences(of: symbolPrefix, with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .uppercased()
            if !symbol.isEmpty {
                symbols.insert(symbol)
            }
        }

        if let stockDetailSymbol = arguments.first(where: { $0.hasPrefix("--stock-detail=") })?
            .replacingOccurrences(of: "--stock-detail=", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .uppercased(),
           !stockDetailSymbol.isEmpty {
            symbols.insert(stockDetailSymbol)
        }

        return symbols.sorted()
    }

    static func requestParameters(
        for timeframe: ChartTimeframe,
        now: Date
    ) -> (resolution: String, from: Date, to: Date) {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .current

        switch timeframe {
        case .day:
            return ("5", calendar.date(byAdding: .day, value: -1, to: now) ?? now, now)
        case .week:
            return ("60", calendar.date(byAdding: .day, value: -7, to: now) ?? now, now)
        case .month:
            return ("D", calendar.date(byAdding: .day, value: -30, to: now) ?? now, now)
        case .threeMonth:
            return ("D", calendar.date(byAdding: .day, value: -90, to: now) ?? now, now)
        case .sixMonth:
            return ("D", calendar.date(byAdding: .day, value: -180, to: now) ?? now, now)
        case .year:
            return ("D", calendar.date(byAdding: .day, value: -365, to: now) ?? now, now)
        case .all:
            return ("W", calendar.date(byAdding: .year, value: -5, to: now) ?? now, now)
        }
    }

    private static func fixtureCandles(
        symbol: String,
        timeframe: ChartTimeframe,
        now: Date
    ) -> [OHLCData] {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .current

        let count = candleCount(for: timeframe)
        let symbolOffset = Double(symbol.unicodeScalars.reduce(0) { $0 + Int($1.value) } % 17)
        let base = 120.0 + symbolOffset

        return (0..<count).compactMap { index in
            guard let date = calendar.date(byAdding: .day, value: -(count - 1 - index), to: now) else {
                return nil
            }

            let wave = sin(Double(index) / 6.0) * 1.6
            let drift = Double(index) * 0.18
            let close = base + drift + wave
            let open = close - 0.55 + cos(Double(index) / 5.0) * 0.35
            let high = max(open, close) + 1.15
            let low = max(0.01, min(open, close) - 1.05)

            return OHLCData(
                date: date,
                open: open,
                high: high,
                low: low,
                close: close,
                volume: 1_200_000 + index * 7_500
            )
        }
    }

    private static func candleCount(for timeframe: ChartTimeframe) -> Int {
        switch timeframe {
        case .day:
            return 30
        case .week:
            return 45
        case .month:
            return 64
        case .threeMonth:
            return 96
        case .sixMonth:
            return 184
        case .year:
            return 252
        case .all:
            return 260
        }
    }
}
#endif
