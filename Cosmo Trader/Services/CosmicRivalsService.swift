import Foundation
import SwiftUI

// MARK: - Cosmic Rivals Service
// ==============================
// Detects and analyzes cosmic rivalries (oppositions) between stocks.
//
// ASTROLOGICAL BACKGROUND:
// In astrology, signs that are 180° apart on the zodiac wheel are in
// "opposition". These pairs represent complementary but often conflicting
// energies. They are like two sides of the same coin.
//
// THE SIX COSMIC RIVAL PAIRS:
// - Aries ↔ Libra: Self vs Partnership
// - Taurus ↔ Scorpio: Security vs Transformation
// - Gemini ↔ Sagittarius: Details vs Big Picture
// - Cancer ↔ Capricorn: Home vs Career
// - Leo ↔ Aquarius: Individual vs Collective
// - Virgo ↔ Pisces: Logic vs Intuition
//
// TRADING INTERPRETATION:
// Having cosmic rivals in your portfolio can mean:
// - Increased volatility (opposing forces pulling in different directions)
// - Natural hedging (one may rise when the other falls)
// - Balance (exposure to both sides of a cosmic dynamic)

@MainActor
@Observable
final class CosmicRivalsService {

    // MARK: - Singleton

    static let shared = CosmicRivalsService()

    // MARK: - Initialization

    private init() {}

    // MARK: - Rival Detection

    /// Find the cosmic rival for a given stock from available stocks
    func findRival(for stock: Stock, in availableStocks: [Stock]) -> Stock? {
        guard let stockSign = stock.zodiacSign else { return nil }
        let rivalSign = stockSign.oppositeSign
        return availableStocks.first { $0.zodiacSign == rivalSign && $0.symbol != stock.symbol }
    }

    /// Find all stocks that are cosmic rivals to the given stock
    func findAllRivals(for stock: Stock, in availableStocks: [Stock]) -> [Stock] {
        guard let stockSign = stock.zodiacSign else { return [] }
        let rivalSign = stockSign.oppositeSign
        return availableStocks.filter { $0.zodiacSign == rivalSign && $0.symbol != stock.symbol }
    }

    /// Detect all cosmic tensions (rival pairs) in a portfolio
    func detectPortfolioTensions(in holdings: [Stock]) -> [CosmicTension] {
        var tensions: [CosmicTension] = []
        var processedPairs: Set<String> = []

        for stock1 in holdings {
            for stock2 in holdings {
                // Skip same stock
                guard stock1.symbol != stock2.symbol else { continue }

                // Check if they're cosmic rivals
                guard let stock1Sign = stock1.zodiacSign,
                      let stock2Sign = stock2.zodiacSign,
                      stock1Sign.isOpposite(to: stock2Sign) else { continue }

                // Create a unique key for this pair (to avoid duplicates)
                let pairKey = [stock1.symbol, stock2.symbol].sorted().joined(separator: "-")
                guard !processedPairs.contains(pairKey) else { continue }
                processedPairs.insert(pairKey)

                // Calculate tension intensity based on holdings
                let tension = CosmicTension(
                    stock1: stock1,
                    stock2: stock2,
                    theme: stock1Sign.oppositionTheme,
                    description: stock1Sign.oppositionDescription
                )
                tensions.append(tension)
            }
        }

        return tensions.sorted { $0.combinedValue > $1.combinedValue }
    }

    /// Check if a portfolio has any cosmic tensions
    func hasCosmicTensions(in holdings: [Stock]) -> Bool {
        !detectPortfolioTensions(in: holdings).isEmpty
    }

    /// Get a summary of portfolio cosmic balance
    func getPortfolioCosmicBalance(holdings: [Stock]) -> CosmicBalance {
        let tensions = detectPortfolioTensions(in: holdings)
        let tensionCount = tensions.count
        let totalHoldings = holdings.count

        // Calculate balance score
        let balanceScore: Int
        let interpretation: String

        if tensionCount == 0 {
            balanceScore = 50 // Neutral - no opposing forces
            interpretation = "Your portfolio has no cosmic tensions. While stable, consider adding opposing energies for natural balance."
        } else if tensionCount == 1 {
            balanceScore = 75
            interpretation = "One cosmic tension detected. This creates dynamic energy that can drive growth through opposing forces."
        } else if tensionCount == 2 {
            balanceScore = 90
            interpretation = "Multiple cosmic tensions create a well-balanced portfolio with natural hedging from opposing energies."
        } else {
            balanceScore = 85
            interpretation = "Highly dynamic portfolio with many opposing forces. This can mean volatility but also resilience."
        }

        return CosmicBalance(
            score: balanceScore,
            tensions: tensions,
            interpretation: interpretation,
            totalHoldings: totalHoldings
        )
    }

    // MARK: - Rival Information

    /// Get detailed rivalry information between two stocks
    func getRivalryInfo(stock1: Stock, stock2: Stock) -> CosmicRivalry? {
        guard let stock1Sign = stock1.zodiacSign,
              let stock2Sign = stock2.zodiacSign,
              stock1Sign.isOpposite(to: stock2Sign) else { return nil }

        return CosmicRivalry(
            stock1: stock1,
            stock2: stock2,
            theme: stock1Sign.oppositionTheme,
            description: stock1Sign.oppositionDescription,
            tradingImplication: getTradingImplication(for: stock1Sign)
        )
    }

    /// Get trading implications for this opposition
    private func getTradingImplication(for sign: ZodiacSign) -> String {
        switch sign {
        case .aries, .libra:
            return "This opposition often shows up as tension between growth stocks (Aries aggression) and partnership-focused companies (Libra collaboration). One may thrive in bull markets while the other excels in consolidation phases."

        case .taurus, .scorpio:
            return "Taurus companies favor stability and steady dividends, while Scorpio companies embrace transformation and disruption. When one sector restructures, the other often provides safe harbor."

        case .gemini, .sagittarius:
            return "Gemini companies excel at rapid information processing and communication, while Sagittarius companies pursue expansive global vision. Tech startups vs. established international players."

        case .cancer, .capricorn:
            return "Cancer companies prioritize customer care and emotional connection, while Capricorn companies focus on institutional strength and market dominance. Consumer sentiment vs. market structure."

        case .leo, .aquarius:
            return "Leo companies build powerful brands around personality and prestige, while Aquarius companies innovate for collective benefit. Luxury goods vs. social innovation."

        case .virgo, .pisces:
            return "Virgo companies optimize through analytics and precision, while Pisces companies succeed through creative vision and emotional resonance. Data-driven vs. intuition-led sectors."
        }
    }
}

// MARK: - Supporting Types

/// Represents a cosmic tension (opposition) between two stocks in a portfolio
struct CosmicTension: Identifiable {
    let id = UUID()
    let stock1: Stock
    let stock2: Stock
    let theme: String
    let description: String

    /// Combined value of both holdings
    var combinedValue: Double {
        stock1.totalValue + stock2.totalValue
    }

    /// The intensity of this tension (based on relative holdings)
    var intensity: TensionIntensity {
        let ratio = min(stock1.totalValue, stock2.totalValue) /
                   max(stock1.totalValue, stock2.totalValue)

        if ratio > 0.75 {
            return .balanced
        } else if ratio > 0.4 {
            return .moderate
        } else {
            return .unbalanced
        }
    }

    enum TensionIntensity: String {
        case balanced = "Balanced"
        case moderate = "Moderate"
        case unbalanced = "Unbalanced"

        var description: String {
            switch self {
            case .balanced:
                return "Equal opposing forces - maximum dynamic balance"
            case .moderate:
                return "Slight imbalance - one force is stronger"
            case .unbalanced:
                return "One force dominates - consider rebalancing"
            }
        }

        var color: Color {
            switch self {
            case .balanced: return CosmicTheme.positive
            case .moderate: return CosmicTheme.gold
            case .unbalanced: return .orange
            }
        }
    }
}

/// Complete rivalry information between two stocks
struct CosmicRivalry: Identifiable {
    let id = UUID()
    let stock1: Stock
    let stock2: Stock
    let theme: String
    let description: String
    let tradingImplication: String

    var oppositionSymbol: String {
        "\(stock1.zodiacSign?.textSymbol ?? "?") ☍ \(stock2.zodiacSign?.textSymbol ?? "?")"
    }
}

/// Overall cosmic balance of a portfolio
struct CosmicBalance: Identifiable {
    let id = UUID()
    let score: Int
    let tensions: [CosmicTension]
    let interpretation: String
    let totalHoldings: Int

    var tensionCount: Int { tensions.count }

    var balanceLevel: BalanceLevel {
        if score >= 85 {
            return .excellent
        } else if score >= 70 {
            return .good
        } else if score >= 50 {
            return .neutral
        } else {
            return .needsWork
        }
    }

    enum BalanceLevel: String {
        case excellent = "Excellent"
        case good = "Good"
        case neutral = "Neutral"
        case needsWork = "Needs Work"

        var color: Color {
            switch self {
            case .excellent: return CosmicTheme.positive
            case .good: return CosmicTheme.accentBlue
            case .neutral: return CosmicTheme.textSecondary
            case .needsWork: return .orange
            }
        }

        var icon: String {
            switch self {
            case .excellent: return "checkmark.seal.fill"
            case .good: return "hand.thumbsup.fill"
            case .neutral: return "minus.circle.fill"
            case .needsWork: return "exclamationmark.triangle.fill"
            }
        }
    }
}
