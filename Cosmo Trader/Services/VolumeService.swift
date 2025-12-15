import Foundation
import SwiftUI

// MARK: - VolumeService
// =====================
// Tracks volume data and identifies stocks with unusual trading activity.
// Used for Volume Leaders feature and Cosmic Confluence alerts.

// MARK: - Volume Data Model

struct VolumeData: Identifiable {
    let id = UUID()
    let symbol: String
    let currentVolume: Int
    let averageVolume: Int
    let volumeRatio: Double
    let timestamp: Date

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

    // Cache for volume data
    private var volumeCache: [String: VolumeData] = [:]

    // MARK: - Init

    private init() {}

    // MARK: - Get Volume Leaders

    /// Get today's volume leaders sorted by volume ratio
    func getVolumeLeaders(
        from stocks: [Stock],
        userSign: ZodiacSign,
        limit: Int = 10
    ) async -> [VolumeLeader] {
        isLoading = true

        // Simulate API call delay
        try? await Task.sleep(nanoseconds: 300_000_000)

        let interpreter = CosmicPatternInterpreter.shared
        var leaders: [VolumeLeader] = []

        for stock in stocks {
            let volumeData = getVolumeData(for: stock)
            let insights = interpreter.getInsights(for: stock, userSign: userSign)

            leaders.append(VolumeLeader(
                stock: stock,
                volumeData: volumeData,
                cosmicInsights: insights
            ))
        }

        // Sort by volume ratio (highest first)
        leaders.sort { $0.volumeData.volumeRatio > $1.volumeData.volumeRatio }

        // Take top N
        volumeLeaders = Array(leaders.prefix(limit))
        isLoading = false
        lastUpdate = Date()

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

    // MARK: - Volume Data Generation

    /// Get volume data for a stock (mock data for now)
    func getVolumeData(for stock: Stock) -> VolumeData {
        // Check cache
        if let cached = volumeCache[stock.symbol] {
            return cached
        }

        // Generate consistent mock data based on stock symbol
        let seed = abs(stock.symbol.hashValue)
        var generator = SeededRandomGenerator(seed: UInt64(seed))

        // Base average volume varies by stock "size"
        let baseAvgVolume: Int
        switch stock.sector {
        case "Technology":
            baseAvgVolume = Int.random(in: 20_000_000...100_000_000, using: &generator)
        case "Finance":
            baseAvgVolume = Int.random(in: 5_000_000...30_000_000, using: &generator)
        case "Healthcare":
            baseAvgVolume = Int.random(in: 3_000_000...25_000_000, using: &generator)
        default:
            baseAvgVolume = Int.random(in: 2_000_000...20_000_000, using: &generator)
        }

        // Current volume varies from average
        // Weighted to occasionally produce unusual volume
        let volumeMultiplier: Double
        let random = Double.random(in: 0...1, using: &generator)
        if random > 0.85 {
            // 15% chance of surging volume
            volumeMultiplier = Double.random(in: 3.0...8.0, using: &generator)
        } else if random > 0.65 {
            // 20% chance of elevated volume
            volumeMultiplier = Double.random(in: 1.5...3.0, using: &generator)
        } else if random > 0.25 {
            // 40% chance of normal volume
            volumeMultiplier = Double.random(in: 0.75...1.5, using: &generator)
        } else {
            // 25% chance of quiet volume
            volumeMultiplier = Double.random(in: 0.3...0.75, using: &generator)
        }

        let currentVolume = Int(Double(baseAvgVolume) * volumeMultiplier)

        let data = VolumeData(
            symbol: stock.symbol,
            currentVolume: currentVolume,
            averageVolume: baseAvgVolume,
            volumeRatio: volumeMultiplier,
            timestamp: Date()
        )

        volumeCache[stock.symbol] = data
        return data
    }

    // MARK: - Cache Management

    func clearCache() {
        volumeCache.removeAll()
        volumeLeaders.removeAll()
    }

    func refreshCache() async {
        clearCache()
        // Re-fetch would happen when getVolumeLeaders is called next
    }
}

// Note: SeededRandomGenerator is defined in Stock.swift
