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
