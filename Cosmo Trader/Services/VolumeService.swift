import Foundation
import SwiftUI

// MARK: - VolumeService
// =====================
// Tracks volume data and identifies stocks with unusual trading activity.
// Uses Finnhub candles API for real volume data.
// Used for Volume Leaders feature and Cosmic Confluence alerts.

// MARK: - Volume Data Model

struct VolumeData: Identifiable, Codable {
    let id: UUID
    let symbol: String
    let currentVolume: Int
    let averageVolume: Int
    let volumeRatio: Double
    let timestamp: Date

    init(
        id: UUID = UUID(),
        symbol: String,
        currentVolume: Int,
        averageVolume: Int,
        volumeRatio: Double,
        timestamp: Date
    ) {
        self.id = id
        self.symbol = symbol
        self.currentVolume = currentVolume
        self.averageVolume = averageVolume
        self.volumeRatio = volumeRatio
        self.timestamp = timestamp
    }

    /// Check if this cached data is stale (older than 5 minutes)
    var isStale: Bool {
        Date().timeIntervalSince(timestamp) > 300
    }

    var formattedCurrentVolume: String {
        formatVolume(currentVolume)
    }

    var formattedAverageVolume: String {
        formatVolume(averageVolume)
    }

    var formattedVolumeRatio: String {
        String(format: "%.1fx", volumeRatio)
    }

    var isUnusual: Bool {
        volumeRatio >= 1.5
    }

    var volumeSignal: VolumeSignal {
        VolumeSignal.from(ratio: volumeRatio)
    }

    private func formatVolume(_ vol: Int) -> String {
        if vol >= 1_000_000_000 {
            return String(format: "%.1fB", Double(vol) / 1_000_000_000)
        } else if vol >= 1_000_000 {
            return String(format: "%.1fM", Double(vol) / 1_000_000)
        } else if vol >= 1_000 {
            return String(format: "%.1fK", Double(vol) / 1_000)
        }
        return "\(vol)"
    }
}

// MARK: - Volume Signal

enum VolumeSignal: String, CaseIterable {
    case surging = "Surging"
    case elevated = "Elevated"
    case normal = "Normal"
    case quiet = "Quiet"
    case dormant = "Dormant"

    var color: Color {
        switch self {
        case .surging: return CosmicTheme.gold
        case .elevated: return CosmicTheme.positive
        case .normal: return CosmicTheme.textSecondary
        case .quiet: return CosmicTheme.textMuted
        case .dormant: return CosmicTheme.textMuted.opacity(0.5)
        }
    }

    var icon: String {
        switch self {
        case .surging: return "flame.fill"
        case .elevated: return "chart.line.uptrend.xyaxis"
        case .normal: return "minus"
        case .quiet: return "moon.zzz"
        case .dormant: return "powersleep"
        }
    }

    var cosmicInterpretation: String {
        switch self {
        case .surging:
            return "Exceptional energy alignment. The cosmos are focusing attention on this asset. Major moves may be imminent."
        case .elevated:
            return "Strong cosmic interest. Above-average activity suggests growing attention from market participants."
        case .normal:
            return "Steady cosmic flow. Standard trading activity indicates balanced energy."
        case .quiet:
            return "Subdued cosmic presence. Below-average interest may signal a period of consolidation."
        case .dormant:
            return "Minimal cosmic attention. Very low activity - a sleeping giant or fading star?"
        }
    }

    static func from(ratio: Double) -> VolumeSignal {
        switch ratio {
        case 3.0...: return .surging
        case 1.5..<3.0: return .elevated
        case 0.75..<1.5: return .normal
        case 0.5..<0.75: return .quiet
        default: return .dormant
        }
    }
}

// MARK: - Volume Leader

struct VolumeLeader: Identifiable {
    let id = UUID()
    let stock: Stock
    let volumeData: VolumeData
    let cosmicInsights: [CosmicPatternInsight]

    var hasCosmicSignals: Bool {
        !cosmicInsights.isEmpty
    }

    var primarySignal: CosmicPatternInsight? {
        cosmicInsights.first
    }

    var isCosmicConfluence: Bool {
        // True if both unusual volume AND cosmic signals
        volumeData.isUnusual && hasCosmicSignals
    }
}

// MARK: - Volume Service

@MainActor
@Observable
class VolumeService {

    // MARK: - Singleton

    static let shared = VolumeService()

    // MARK: - Properties

    private(set) var volumeLeaders: [VolumeLeader] = []
    private(set) var isLoading: Bool = false
    private(set) var lastUpdate: Date?
    private(set) var lastError: Error?

    // Cache for volume data (keyed by symbol)
    private var volumeCache: [String: VolumeData] = [:]

    // Cache duration (5 minutes - volume doesn't need real-time updates)
    private let cacheDuration: TimeInterval = 300

    // MARK: - Init

    private init() {
        // Load cached data on init
        loadCachedVolumeData()
    }

    // MARK: - Get Volume Leaders

    /// Get today's volume leaders sorted by volume ratio
    func getVolumeLeaders(
        from stocks: [Stock],
        userSign: ZodiacSign,
        limit: Int = 10
    ) async -> [VolumeLeader] {
        isLoading = true
        lastError = nil

        let interpreter = CosmicPatternInterpreter.shared
        var leaders: [VolumeLeader] = []

        for stock in stocks {
            // Get volume data (from cache or API)
            if let volumeData = await getVolumeData(for: stock.symbol) {
                let insights = interpreter.getInsights(for: stock, userSign: userSign)

                leaders.append(VolumeLeader(
                    stock: stock,
                    volumeData: volumeData,
                    cosmicInsights: insights
                ))
            }
        }

        // Sort by volume ratio (highest first)
        leaders.sort { $0.volumeData.volumeRatio > $1.volumeData.volumeRatio }

        // Take top N
        volumeLeaders = Array(leaders.prefix(limit))
        isLoading = false
        lastUpdate = Date()

        // Persist cache
        saveVolumeCache()

        return volumeLeaders
    }

    /// Get only stocks with unusual volume (>1.5x average)
    func getUnusualVolumeStocks(
        from stocks: [Stock],
        userSign: ZodiacSign
    ) async -> [VolumeLeader] {
        let leaders = await getVolumeLeaders(from: stocks, userSign: userSign, limit: stocks.count)
        return leaders.filter { $0.volumeData.isUnusual }
    }

    /// Get stocks with cosmic confluence (unusual volume + cosmic signals)
    func getCosmicConfluenceStocks(
        from stocks: [Stock],
        userSign: ZodiacSign
    ) async -> [VolumeLeader] {
        let leaders = await getVolumeLeaders(from: stocks, userSign: userSign, limit: stocks.count)
        return leaders.filter { $0.isCosmicConfluence }
    }

    // MARK: - Volume Data Fetching

    /// Get volume data for a stock symbol (from cache or API)
    func getVolumeData(for symbol: String) async -> VolumeData? {
        // Check cache first (return if fresh)
        if let cached = volumeCache[symbol], !cached.isStale {
            log("📦 Cache hit for \(symbol) volume")
            return cached
        }

        // Fetch from API
        do {
            let candles = try await StockAPIService.shared.fetchRecentCandles(symbol: symbol)

            guard candles.hasValidVolumeData,
                  let latestVolume = candles.latestVolume,
                  let avgVolume = candles.averageVolume else {
                log("⚠️ No volume data for \(symbol)")
                // Return stale cache if available
                return volumeCache[symbol]
            }

            let volumeRatio = avgVolume > 0 ? Double(latestVolume) / avgVolume : 1.0

            let data = VolumeData(
                symbol: symbol,
                currentVolume: latestVolume,
                averageVolume: Int(avgVolume),
                volumeRatio: volumeRatio,
                timestamp: Date()
            )

            volumeCache[symbol] = data
            log("✅ Fetched volume for \(symbol): \(data.formattedVolumeRatio)")
            return data

        } catch {
            log("❌ Volume fetch error for \(symbol): \(error)")
            lastError = error
            // Return stale cache if available
            return volumeCache[symbol]
        }
    }

    /// Get volume data synchronously from cache only (for non-async contexts)
    func getCachedVolumeData(for symbol: String) -> VolumeData? {
        volumeCache[symbol]
    }

    // MARK: - Cache Management

    private let cacheKey = "com.cosmotrader.volumecache"

    func clearCache() {
        volumeCache.removeAll()
        volumeLeaders.removeAll()
        UserDefaults.standard.removeObject(forKey: cacheKey)
        log("🗑️ Volume cache cleared")
    }

    func refreshCache() async {
        clearCache()
        // Re-fetch would happen when getVolumeLeaders is called next
    }

    private func saveVolumeCache() {
        do {
            let data = try JSONEncoder().encode(Array(volumeCache.values))
            UserDefaults.standard.set(data, forKey: cacheKey)
            log("💾 Saved \(volumeCache.count) volume entries to cache")
        } catch {
            log("⚠️ Failed to save volume cache: \(error)")
        }
    }

    private func loadCachedVolumeData() {
        guard let data = UserDefaults.standard.data(forKey: cacheKey) else {
            log("📦 No cached volume data found")
            return
        }

        do {
            let cached = try JSONDecoder().decode([VolumeData].self, from: data)
            for item in cached {
                volumeCache[item.symbol] = item
            }
            log("📦 Loaded \(cached.count) volume entries from cache")
        } catch {
            log("⚠️ Failed to load volume cache: \(error)")
        }
    }

    // MARK: - Logging

    private func log(_ message: String) {
        #if DEBUG
        print("[VolumeService] \(message)")
        #endif
    }
}
