import Foundation
import SwiftUI

// MARK: - Sign Stack Service
// ==========================
// Generates shareable "Sign Stack" trading cards showing:
// - User's sun sign
// - Top 3 holdings with their signs
// - Sector/element allocation breakdown
// - A one-liner about their investing style
//
// WHY IT WORKS: Perfect for Twitter/Instagram. Social proof. Viral potential.

@MainActor
@Observable
final class SignStackService {

    // MARK: - Singleton

    static let shared = SignStackService()

    // MARK: - Initialization

    private init() {}

    // MARK: - Sign Stack Generation

    /// Generate a Sign Stack card data for a user
    func generateSignStack(for user: UserProfile) -> SignStackData {
        let holdings = user.portfolio.filter { $0.sharesOwned > 0 }
        let topHoldings = Array(holdings.sorted { $0.totalValue > $1.totalValue }.prefix(3))

        let elementBreakdown = calculateElementBreakdown(holdings: holdings, totalValue: user.totalPortfolioValue)
        let investingStyle = generateInvestingStyle(userSign: user.sunSign, elementBreakdown: elementBreakdown)
        let cosmicTitle = generateCosmicTitle(userSign: user.sunSign, elementBreakdown: elementBreakdown)

        return SignStackData(
            userSign: user.sunSign,
            displayName: user.displayName,
            topHoldings: topHoldings.map { SignStackHolding(stock: $0) },
            elementBreakdown: elementBreakdown,
            investingStyle: investingStyle,
            cosmicTitle: cosmicTitle,
            totalValue: user.totalPortfolioValue,
            holdingsCount: holdings.count,
            generatedDate: Date()
        )
    }

    // MARK: - Element Breakdown

    private func calculateElementBreakdown(holdings: [Stock], totalValue: Double) -> [SignStackElement] {
        guard totalValue > 0 else {
            return ZodiacSign.Element.allCases.map {
                SignStackElement(element: $0, percentage: 0, value: 0)
            }
        }

        var elementValues: [ZodiacSign.Element: Double] = [:]
        for stock in holdings {
            let element = stock.zodiacSign.element
            elementValues[element, default: 0] += stock.totalValue
        }

        return ZodiacSign.Element.allCases.map { element in
            let value = elementValues[element] ?? 0
            let percentage = (value / totalValue) * 100
            return SignStackElement(element: element, percentage: percentage, value: value)
        }.sorted { $0.percentage > $1.percentage }
    }

    // MARK: - Investing Style Generation

    private func generateInvestingStyle(userSign: ZodiacSign, elementBreakdown: [SignStackElement]) -> String {
        let dominantElement = elementBreakdown.first { $0.percentage > 0 }?.element

        // Sign-specific style with element modifier
        let signStyle = getSignInvestingStyle(userSign)
        let elementModifier = getElementModifier(dominantElement, userElement: userSign.element)

        return "\(signStyle) \(elementModifier)"
    }

    private func getSignInvestingStyle(_ sign: ZodiacSign) -> String {
        switch sign {
        case .aries:
            return "First in, first out."
        case .taurus:
            return "Buy and hold forever."
        case .gemini:
            return "Diversified to the max."
        case .cancer:
            return "Protecting capital at all costs."
        case .leo:
            return "Only blue chips and headlines."
        case .virgo:
            return "Spreadsheets for everything."
        case .libra:
            return "Perfectly balanced portfolio."
        case .scorpio:
            return "Deep research, big conviction."
        case .sagittarius:
            return "Global exposure, no borders."
        case .capricorn:
            return "Long-term compounding machine."
        case .aquarius:
            return "Contrarian by nature."
        case .pisces:
            return "Intuition over analysis."
        }
    }

    private func getElementModifier(_ dominantElement: ZodiacSign.Element?, userElement: ZodiacSign.Element) -> String {
        guard let dominant = dominantElement else { return "" }

        if dominant == userElement {
            return "True to your element."
        }

        switch dominant {
        case .fire:
            return "Chasing growth."
        case .earth:
            return "Grounded in value."
        case .air:
            return "Thinking ahead."
        case .water:
            return "Following the flow."
        }
    }

    // MARK: - Cosmic Title Generation

    private func generateCosmicTitle(userSign: ZodiacSign, elementBreakdown: [SignStackElement]) -> String {
        let dominantElement = elementBreakdown.first { $0.percentage > 30 }?.element ?? userSign.element
        let balance = elementBreakdown.filter { $0.percentage > 15 }.count

        if balance >= 3 {
            return "The Cosmic Balancer"
        }

        switch (userSign.element, dominantElement) {
        case (.fire, .fire):
            return "The Fire Starter"
        case (.fire, .earth):
            return "The Grounded Risk-Taker"
        case (.fire, .air):
            return "The Visionary Trader"
        case (.fire, .water):
            return "The Intuitive Maverick"

        case (.earth, .fire):
            return "The Calculated Risk-Taker"
        case (.earth, .earth):
            return "The Value Investor"
        case (.earth, .air):
            return "The Strategic Builder"
        case (.earth, .water):
            return "The Patient Accumulator"

        case (.air, .fire):
            return "The Trend Spotter"
        case (.air, .earth):
            return "The Analytical Builder"
        case (.air, .air):
            return "The Market Philosopher"
        case (.air, .water):
            return "The Intuitive Analyst"

        case (.water, .fire):
            return "The Bold Intuitive"
        case (.water, .earth):
            return "The Steady Hand"
        case (.water, .air):
            return "The Thoughtful Dreamer"
        case (.water, .water):
            return "The Deep Diver"
        }
    }

    // MARK: - Share Text Generation

    func generateShareText(for stack: SignStackData) -> String {
        var text = "My Sign Stack \(stack.userSign.textSymbol)\n\n"
        text += "\"\(stack.cosmicTitle)\"\n"
        text += "\(stack.investingStyle)\n\n"

        if !stack.topHoldings.isEmpty {
            text += "Top Holdings:\n"
            for holding in stack.topHoldings {
                text += "\(holding.symbol) \(holding.sign.textSymbol)\n"
            }
            text += "\n"
        }

        text += "Element Mix: "
        let significantElements = stack.elementBreakdown.filter { $0.percentage > 10 }
        text += significantElements.map { "\($0.element.displayName) \(Int($0.percentage))%" }.joined(separator: " ")
        text += "\n\n"

        text += "#CosmoTrader #SignStack #\(stack.userSign.displayName)"

        return text
    }
}

// MARK: - Sign Stack Data

struct SignStackData: Identifiable {
    let id = UUID()
    let userSign: ZodiacSign
    let displayName: String
    let topHoldings: [SignStackHolding]
    let elementBreakdown: [SignStackElement]
    let investingStyle: String
    let cosmicTitle: String
    let totalValue: Double
    let holdingsCount: Int
    let generatedDate: Date

    var formattedValue: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: totalValue)) ?? "$0"
    }

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: generatedDate)
    }
}

struct SignStackHolding: Identifiable {
    let id = UUID()
    let symbol: String
    let name: String
    let sign: ZodiacSign
    let percentageChange: Double
    let value: Double

    init(stock: Stock) {
        self.symbol = stock.symbol
        self.name = stock.name
        self.sign = stock.zodiacSign
        self.percentageChange = stock.percentageChange
        self.value = stock.totalValue
    }

    var formattedChange: String {
        let sign = percentageChange >= 0 ? "+" : ""
        return "\(sign)\(String(format: "%.1f", percentageChange))%"
    }

    var isPositive: Bool {
        percentageChange >= 0
    }
}

struct SignStackElement: Identifiable {
    let id = UUID()
    let element: ZodiacSign.Element
    let percentage: Double
    let value: Double

    var formattedPercentage: String {
        "\(Int(percentage))%"
    }
}
