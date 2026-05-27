import Foundation
import SwiftUI

// MARK: - PortfolioCompatibilityService
// =====================================
// Calculates portfolio-wide cosmic compatibility weighted by share count.
// 1 share = 1 data point. More shares = more influence on overall score.
//
// This creates a comprehensive view of portfolio "cosmic health" that
// accounts for position sizing, not just presence of holdings.

// MARK: - Portfolio Compatibility Result

/// Complete result of portfolio-wide compatibility analysis
struct PortfolioCompatibilityResult {
    /// Overall weighted compatibility score (0-100)
    let overallScore: Double

    /// Element breakdown as percentages of verified-date holdings.
    let elementBreakdown: [ZodiacSign.Element: Double]

    /// Sign breakdown by share count, excluding unknown-founded holdings.
    let signBreakdown: [ZodiacSign: Double]

    /// The dominant zodiac sign in portfolio (by shares)
    let dominantSign: ZodiacSign

    /// The dominant element (by shares)
    let dominantElement: ZodiacSign.Element

    /// Total shares analyzed, excluding unknown-founded holdings.
    let totalShares: Double

    /// Cosmic insight about portfolio health
    let cosmicInsight: String

    /// Rating based on overall score
    var rating: CompatibilityRating {
        CompatibilityRating.from(score: Int(overallScore))
    }

    /// Formatted overall score
    var formattedScore: String {
        String(format: "%.0f%%", overallScore)
    }

    /// Whether the portfolio has balanced elements
    var isElementBalanced: Bool {
        let values = elementBreakdown.values
        guard let maxValue = values.max(), let minValue = values.min() else { return true }
        return (maxValue - minValue) < 30 // Less than 30% spread
    }

    /// Missing elements (0% allocation)
    var missingElements: [ZodiacSign.Element] {
        ZodiacSign.Element.allCases.filter { elementBreakdown[$0, default: 0] == 0 }
    }

    /// Elements with heavy allocation (>40%)
    var heavyElements: [ZodiacSign.Element] {
        elementBreakdown.filter { $0.value > 40 }.map { $0.key }
    }
}

// MARK: - Rebalancing Suggestion

/// A suggestion for improving portfolio cosmic alignment
struct RebalancingSuggestion: Identifiable {
    let id = UUID()
    let type: SuggestionType
    let icon: String
    let message: String
    let priority: Priority

    enum SuggestionType {
        case addElement
        case reduceElement
        case addSign
        case diversify
        case cosmicBoost
    }

    enum Priority: Int, Comparable {
        case high = 3
        case medium = 2
        case low = 1

        static func < (lhs: Priority, rhs: Priority) -> Bool {
            lhs.rawValue < rhs.rawValue
        }
    }
}

// MARK: - Portfolio Compatibility Service

enum PortfolioCompatibilityService {

    // MARK: - Main Calculation

    /// Calculate weighted portfolio compatibility
    /// - Parameters:
    ///   - portfolio: Array of stocks in portfolio
    ///   - userSign: User's zodiac sign
    /// - Returns: Complete compatibility result
    static func calculateWeightedCompatibility(
        portfolio: [Stock],
        userSign: ZodiacSign
    ) -> PortfolioCompatibilityResult {

        // Filter to only owned stocks
        let holdings = portfolio.filter { $0.sharesOwned > 0 }

        // Handle empty portfolio
        guard !holdings.isEmpty else {
            return emptyPortfolioResult(userSign: userSign)
        }

        var totalShares: Double = 0
        var weightedCompatibilitySum: Double = 0
        var elementCounts: [ZodiacSign.Element: Double] = [:]
        var signCounts: [ZodiacSign: Double] = [:]

        for stock in holdings {
            guard let stockSign = stock.foundedZodiacSign else { continue }

            let shares = stock.sharesOwned
            totalShares += shares

            // Weight compatibility by shares
            let compatibility = CompatibilityCalculator.calculate(
                userSign: userSign,
                stockSign: stockSign
            )
            weightedCompatibilitySum += Double(compatibility.score) * shares

            // Track element exposure by shares
            let element = stockSign.element
            elementCounts[element, default: 0] += shares

            // Track sign exposure by shares
            signCounts[stockSign, default: 0] += shares
        }

        guard totalShares > 0 else {
            return emptyPortfolioResult(
                userSign: userSign,
                cosmicInsight: "Add holdings with verified founding dates to generate a portfolio-specific market astrology read."
            )
        }

        // Calculate overall weighted score
        let overallScore = weightedCompatibilitySum / totalShares

        // Convert counts to percentages. Unknown-founded holdings are excluded
        // from totalShares, so the denominator is only verified company dates.
        let elementBreakdown = elementCounts.mapValues { ($0 / totalShares) * 100 }
        let signBreakdown = signCounts.mapValues { ($0 / totalShares) * 100 }

        // Find dominant sign and element
        let dominantSign = signCounts.max(by: { $0.value < $1.value })?.key ?? .aries
        let dominantElement = elementCounts.max(by: { $0.value < $1.value })?.key ?? .fire

        // Generate cosmic insight
        let insight = generatePortfolioInsight(
            score: overallScore,
            userSign: userSign,
            dominantSign: dominantSign,
            dominantElement: dominantElement,
            elementBreakdown: elementBreakdown
        )

        return PortfolioCompatibilityResult(
            overallScore: overallScore,
            elementBreakdown: elementBreakdown,
            signBreakdown: signBreakdown,
            dominantSign: dominantSign,
            dominantElement: dominantElement,
            totalShares: totalShares,
            cosmicInsight: insight
        )
    }

    // MARK: - Rebalancing Suggestions

    /// Generate rebalancing suggestions based on portfolio analysis
    static func generateRebalancingSuggestions(
        result: PortfolioCompatibilityResult,
        userSign: ZodiacSign
    ) -> [RebalancingSuggestion] {

        var suggestions: [RebalancingSuggestion] = []

        // Check for missing elements
        for element in result.missingElements {
            suggestions.append(RebalancingSuggestion(
                type: .addElement,
                icon: element.sfSymbol,
                message: "Add \(element.displayName) sign stocks (you have 0%)",
                priority: .high
            ))
        }

        // Check for heavy elements
        for element in result.heavyElements {
            let percentage = result.elementBreakdown[element, default: 0]
            suggestions.append(RebalancingSuggestion(
                type: .reduceElement,
                icon: "scale.3d",
                message: "Consider reducing \(element.displayName) exposure (currently \(String(format: "%.0f%%", percentage)))",
                priority: .medium
            ))
        }

        // Check for compatible signs to add
        let compatibleSigns = userSign.compatibleSigns
        let missingSoulmates = compatibleSigns.filter { sign in
            result.signBreakdown[sign, default: 0] == 0
        }
        if let missingSign = missingSoulmates.first {
            suggestions.append(RebalancingSuggestion(
                type: .addSign,
                icon: "plus.circle",
                message: "Add \(missingSign.displayName) exposure if it improves portfolio balance",
                priority: .medium
            ))
        }

        // Check if portfolio is too concentrated
        if let maxElementPercentage = result.elementBreakdown.values.max(),
           maxElementPercentage > 60 {
            suggestions.append(RebalancingSuggestion(
                type: .diversify,
                icon: "square.grid.2x2",
                message: "Diversify across elements to reduce concentration risk",
                priority: .high
            ))
        }

        // Add cosmic boost suggestion if score is low
        if result.overallScore < 50 {
            suggestions.append(RebalancingSuggestion(
                type: .cosmicBoost,
                icon: "arrow.up.right.circle",
                message: "Review same-element exposure (\(userSign.element.displayName)) for alignment",
                priority: .high
            ))
        }

        // Sort by priority (high first)
        return suggestions.sorted { $0.priority > $1.priority }
    }

    // MARK: - Empty Portfolio Result

    private static func emptyPortfolioResult(
        userSign: ZodiacSign,
        cosmicInsight: String = "Add holdings to generate a portfolio-specific market astrology read."
    ) -> PortfolioCompatibilityResult {
        PortfolioCompatibilityResult(
            overallScore: 0,
            elementBreakdown: [:],
            signBreakdown: [:],
            dominantSign: userSign, // Default to user's sign
            dominantElement: userSign.element,
            totalShares: 0,
            cosmicInsight: cosmicInsight
        )
    }

    // MARK: - Insight Generation

    private static func generatePortfolioInsight(
        score: Double,
        userSign: ZodiacSign,
        dominantSign: ZodiacSign,
        dominantElement: ZodiacSign.Element,
        elementBreakdown: [ZodiacSign.Element: Double]
    ) -> String {

        let rating = CompatibilityRating.from(score: Int(score))

        // Check for missing elements
        let missingElements = ZodiacSign.Element.allCases.filter {
            elementBreakdown[$0, default: 0] == 0
        }

        // Check for imbalance
        let maxElement = elementBreakdown.max(by: { $0.value < $1.value })
        let isImbalanced = (maxElement?.value ?? 0) > 50

        switch rating {
        case .cosmicSoulmates:
            return "Strong alignment across portfolio factors. \(dominantElement.displayName) exposure dominates, which may amplify your \(userSign.displayName)-style risk posture."

        case .highCompatibility:
            if isImbalanced {
                return "Strong alignment, but \(dominantElement.displayName) energy is concentrated at \(String(format: "%.0f%%", maxElement?.value ?? 0)). Consider elemental diversification."
            }
            return "Your \(userSign.displayName) profile aligns well with current holdings. Structure is helping the reading."

        case .neutral:
            if !missingElements.isEmpty {
                let missing = missingElements.map { $0.displayName }.joined(separator: ", ")
                return "Balanced, but missing \(missing) exposure. Decide whether that gap is intentional diversification or an overlooked sleeve."
            }
            return "Your portfolio is elementally balanced. No single exposure is driving the reading."

        case .challenging:
            return "Your \(userSign.displayName) profile conflicts with \(dominantSign.displayName)-heavy exposure. Treat this as a risk-control prompt."

        case .cosmicClash:
            return "Your portfolio runs against your \(userSign.displayName) profile. Keep position sizing and conviction under review."
        }
    }

    // MARK: - Element Balance Analysis

    /// Analyze element balance and return a description
    static func analyzeElementBalance(
        breakdown: [ZodiacSign.Element: Double]
    ) -> String {
        let count = breakdown.filter { $0.value > 0 }.count

        switch count {
        case 4:
            return "Fully balanced across all elements"
        case 3:
            let missing = ZodiacSign.Element.allCases.first { breakdown[$0, default: 0] == 0 }
            return "Missing \(missing?.displayName ?? "one element") exposure"
        case 2:
            return "Concentrated in two elements - moderate risk"
        case 1:
            let dominant = breakdown.max(by: { $0.value < $1.value })?.key
            return "Heavily concentrated in \(dominant?.displayName ?? "one element")"
        default:
            return "Build your portfolio to see element balance"
        }
    }
}
