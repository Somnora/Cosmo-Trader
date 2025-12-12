import Foundation
import SwiftUI

// MARK: - CosmicRoast Model
// =========================
// The data structure for "The Cosmic Roast" — a brutal but funny
// astrological portfolio critique formatted like an official audit report.
//
// This is designed for viral sharing on Instagram Stories.

struct CosmicRoast: Identifiable {
    let id = UUID()
    let generatedDate: Date

    // MARK: - Header
    let reportTitle: String
    let auditorName: String

    // MARK: - Performance Summary
    let portfolioValue: Double
    let ytdReturn: Double
    let cosmicAssessment: String
    let assessmentIcon: String

    // MARK: - Sector Analysis
    let sectorBreakdown: [SectorAnalysis]
    let sectorDiagnosis: String

    // MARK: - The Main Roast
    let roastTitle: String
    let roastContent: String

    // MARK: - Worst Performer
    let weakestLink: WeakestLinkCallout?

    // MARK: - Recommendation
    let recommendation: String
    let recommendationSubtext: String

    // MARK: - Footer
    let disclaimer: String

    // MARK: - Computed

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy HH:mm"
        return formatter.string(from: generatedDate)
    }

    var formattedPortfolioValue: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: portfolioValue)) ?? "$0.00"
    }

    var formattedYTDReturn: String {
        let sign = ytdReturn >= 0 ? "+" : ""
        return String(format: "%@%.1f%%", sign, ytdReturn)
    }

    var isPositive: Bool {
        ytdReturn >= 0
    }
}

// MARK: - Supporting Types

struct SectorAnalysis: Identifiable {
    let id = UUID()
    let element: ZodiacSign.Element
    let percentage: Double
    let status: SectorStatus
    let value: Double

    enum SectorStatus: String {
        case overweight = "OVERWEIGHT"
        case balanced = "BALANCED"
        case underweight = "UNDERWEIGHT"
        case critical = "CRITICAL DEFICIENCY"

        var color: Color {
            switch self {
            case .overweight: return CosmicTheme.negative
            case .balanced: return CosmicTheme.positive
            case .underweight: return CosmicTheme.gold
            case .critical: return CosmicTheme.negative
            }
        }
    }

    var formattedPercentage: String {
        String(format: "%.0f%%", percentage)
    }

    var sectorName: String {
        "\(element.displayName) Sector"
    }
}

struct WeakestLinkCallout: Identifiable {
    let id = UUID()
    let symbol: String
    let name: String
    let percentageChange: Double
    let zodiacSign: ZodiacSign
    let roastNote: String

    var formattedChange: String {
        String(format: "%.1f%%", percentageChange)
    }
}

// MARK: - Assessment Levels

enum CosmicAssessmentLevel: String, CaseIterable {
    case disastrous = "UNDERPERFORMING THE VOID"
    case struggling = "COSMICALLY CHALLENGED"
    case neutral = "EXISTING (BARELY)"
    case decent = "ACCEPTABLE TO THE STARS"
    case good = "BLESSED BY MERCURY"
    case excellent = "GALAXY-BRAINED"
    case overconfident = "DANGEROUSLY CONFIDENT"

    var icon: String {
        switch self {
        case .disastrous: return "flame.fill"
        case .struggling: return "cloud.rain.fill"
        case .neutral: return "minus.circle"
        case .decent: return "checkmark.circle"
        case .good: return "star.fill"
        case .excellent: return "sparkles"
        case .overconfident: return "exclamationmark.triangle.fill"
        }
    }

    static func from(ytdReturn: Double) -> CosmicAssessmentLevel {
        switch ytdReturn {
        case ..<(-20): return .disastrous
        case -20..<(-5): return .struggling
        case -5..<5: return .neutral
        case 5..<15: return .decent
        case 15..<30: return .good
        case 30..<50: return .excellent
        default: return .overconfident
        }
    }
}
