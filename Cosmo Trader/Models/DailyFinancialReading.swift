import Foundation
import SwiftUI

struct DailyFinancialReading {
    let date: Date
    let signalHeadline: String
    let marketCosmicPosture: String
    let portfolioImpact: String
    let watchItems: [DailyReadingWatchItem]
    let bestMove: DailyReadingMove
    let grounding: String
    let framingLevel: SignalFramingLevel
    let portfolioValue: String?
    let portfolioReturn: String?
    let dominantExposure: DailyReadingExposure?
    let lunarPhase: String
    let mercuryStatus: String
    let marketTone: String
    /// Provenance of the `marketTone` value. When this is not provider-backed,
    /// the cockpit UI must render the cell with an explicit non-market tag
    /// (e.g. "Cosmic context only" / "Market data unavailable").
    let marketToneProvenance: FinancialDataProvenance
    let activeEvents: [String]
    let needsPortfolioSetup: Bool
    let financialProvenance: FinancialDataProvenance
}

struct DailyReadingWatchItem: Identifiable {
    enum Source {
        case holding
        case watchlist
    }

    let id: String
    let symbol: String
    let name: String
    let source: Source
    let reason: String
    let changeText: String?
    let isPositive: Bool?
}

struct DailyReadingExposure {
    let label: String
    let detail: String
    let color: Color
}

enum DailyReadingMove: String {
    case watch = "Watch"
    case hold = "Hold"
    case review = "Review"
    case reduceRisk = "Reduce risk"
    case avoidChasing = "Avoid chasing"
    case waitForConfirmation = "Wait for confirmation"

    var systemImage: String {
        switch self {
        case .watch: return "eye"
        case .hold: return "pause.circle"
        case .review: return "list.clipboard"
        case .reduceRisk: return "shield"
        case .avoidChasing: return "hand.raised"
        case .waitForConfirmation: return "checkmark.seal"
        }
    }

    var color: Color {
        switch self {
        case .watch, .hold: return CosmicTheme.nebulaBlue
        case .review, .waitForConfirmation: return CosmicTheme.gold
        case .reduceRisk, .avoidChasing: return .orange
        }
    }
}
