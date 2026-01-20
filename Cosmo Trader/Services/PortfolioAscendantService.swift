import Foundation
import SwiftUI

// MARK: - Portfolio Ascendant Service
// ====================================
// Analyzes the dual nature of a portfolio: what it truly is vs. how it appears.
//
// FEATURE: Portfolio Ascendant
// In astrology, your Ascendant is how others perceive you vs. who you really are.
//
// Show two views of portfolio:
// - "Your Portfolio" (sun sign = what you hold)
// - "Your Portfolio's Ascendant" (how it appears to the market)
//
// Example: "Sun: Conservative Earth-heavy. Ascendant: That one NVDA position
//          makes you look like a tech bro."
//
// WHY IT WORKS: Funny. Self-aware. Shareable insight.

@MainActor
@Observable
final class PortfolioAscendantService {

    // MARK: - Singleton

    static let shared = PortfolioAscendantService()

    private init() {}

    // MARK: - Analysis

    /// Generate a full portfolio ascendant reading
    func analyzePortfolio(holdings: [Stock], userSign: ZodiacSign) -> PortfolioAscendantReading {
        guard !holdings.isEmpty else {
            return PortfolioAscendantReading.empty(userSign: userSign)
        }

        // Calculate true nature (Sun)
        let sunAnalysis = analyzeSunNature(holdings: holdings)

        // Calculate perceived nature (Ascendant)
        let ascendantAnalysis = analyzeAscendantNature(holdings: holdings)

        // Generate the contrast/insight
        let contrast = generateContrast(sun: sunAnalysis, ascendant: ascendantAnalysis)

        // Generate shareable quip
        let quip = generateShareableQuip(sun: sunAnalysis, ascendant: ascendantAnalysis)

        return PortfolioAscendantReading(
            userSign: userSign,
            sunAnalysis: sunAnalysis,
            ascendantAnalysis: ascendantAnalysis,
            contrast: contrast,
            shareableQuip: quip,
            holdings: holdings
        )
    }

    // MARK: - Sun Analysis (True Nature)

    /// Analyze the true elemental/sign composition of the portfolio
    private func analyzeSunNature(holdings: [Stock]) -> PortfolioSunAnalysis {
        let totalValue = holdings.reduce(0) { $0 + $1.totalValue }
        guard totalValue > 0 else {
            return PortfolioSunAnalysis(
                dominantElement: .earth,
                elementBreakdown: [:],
                dominantSign: .taurus,
                signBreakdown: [:],
                personality: "Empty",
                description: "Your portfolio is a blank canvas awaiting cosmic guidance."
            )
        }

        // Calculate element breakdown by value
        var elementValues: [ZodiacSign.Element: Double] = [:]
        var signValues: [ZodiacSign: Double] = [:]

        for stock in holdings {
            let element = stock.zodiacSign.element
            let sign = stock.zodiacSign
            elementValues[element, default: 0] += stock.totalValue
            signValues[sign, default: 0] += stock.totalValue
        }

        // Convert to percentages
        let elementBreakdown = elementValues.mapValues { ($0 / totalValue) * 100 }
        let signBreakdown = signValues.mapValues { ($0 / totalValue) * 100 }

        // Find dominant element and sign
        let dominantElement = elementBreakdown.max(by: { $0.value < $1.value })?.key ?? .earth
        let dominantSign = signBreakdown.max(by: { $0.value < $1.value })?.key ?? .taurus

        // Generate personality based on element composition
        let personality = generateSunPersonality(elementBreakdown: elementBreakdown)
        let description = generateSunDescription(
            dominantElement: dominantElement,
            elementBreakdown: elementBreakdown
        )

        return PortfolioSunAnalysis(
            dominantElement: dominantElement,
            elementBreakdown: elementBreakdown,
            dominantSign: dominantSign,
            signBreakdown: signBreakdown,
            personality: personality,
            description: description
        )
    }

    private func generateSunPersonality(elementBreakdown: [ZodiacSign.Element: Double]) -> String {
        let fire = elementBreakdown[.fire] ?? 0
        let earth = elementBreakdown[.earth] ?? 0
        let air = elementBreakdown[.air] ?? 0
        let water = elementBreakdown[.water] ?? 0

        // Determine dominant trait
        if fire > 50 {
            return "Aggressive Growth Seeker"
        } else if earth > 50 {
            return "Conservative Value Hunter"
        } else if air > 50 {
            return "Innovation Chaser"
        } else if water > 50 {
            return "Intuitive Opportunist"
        } else if fire + air > 60 {
            return "High-Risk Visionary"
        } else if earth + water > 60 {
            return "Steady Accumulator"
        } else if fire > 30 && earth > 30 {
            return "Balanced Pragmatist"
        } else if air > 30 && water > 30 {
            return "Adaptive Strategist"
        } else {
            return "Diversified Cosmic Investor"
        }
    }

    private func generateSunDescription(
        dominantElement: ZodiacSign.Element,
        elementBreakdown: [ZodiacSign.Element: Double]
    ) -> String {
        let dominantPercent = elementBreakdown[dominantElement] ?? 0

        switch dominantElement {
        case .fire:
            if dominantPercent > 60 {
                return "Your portfolio burns hot with aggressive growth plays. You're not here for dividends."
            } else {
                return "Fire energy drives your core holdings. You favor bold moves over safe bets."
            }

        case .earth:
            if dominantPercent > 60 {
                return "Rock-solid Earth energy dominates. You're building generational wealth, one dividend at a time."
            } else {
                return "Earth grounds your portfolio. Value and stability are your north stars."
            }

        case .air:
            if dominantPercent > 60 {
                return "Your portfolio lives in the cloud — literally and figuratively. Innovation is oxygen."
            } else {
                return "Air carries your investments toward the future. You bet on ideas, not just earnings."
            }

        case .water:
            if dominantPercent > 60 {
                return "Deep Water energy flows through your holdings. You invest with intuition and emotion."
            } else {
                return "Water guides your choices. You sense market currents others miss."
            }
        }
    }

    // MARK: - Ascendant Analysis (Perceived Nature)

    /// Analyze how the portfolio appears to outsiders based on standout positions
    private func analyzeAscendantNature(holdings: [Stock]) -> PortfolioAscendantAnalysis {
        guard !holdings.isEmpty else {
            return PortfolioAscendantAnalysis(
                perceivedAs: "Ghost Investor",
                standoutStock: nil,
                standoutReason: "No positions to judge",
                socialLabel: "The Invisible One",
                description: "Nobody knows you're even in the market.",
                roast: "Your portfolio is so empty, even the void is jealous."
            )
        }

        let totalValue = holdings.reduce(0) { $0 + $1.totalValue }

        // Find the most notable position (largest, most volatile, or most recognizable)
        let standout = findStandoutPosition(holdings: holdings, totalValue: totalValue)

        // Generate perception based on standout
        let perception = generatePerception(standout: standout, holdings: holdings, totalValue: totalValue)

        return perception
    }

    private func findStandoutPosition(holdings: [Stock], totalValue: Double) -> StandoutPosition? {
        guard let largest = holdings.max(by: { $0.totalValue < $1.totalValue }) else {
            return nil
        }

        let largestPercent = (largest.totalValue / totalValue) * 100

        // Check for meme-worthy stocks
        let memeStocks = ["GME", "AMC", "BBBY", "DOGE", "SHIB"]
        if let meme = holdings.first(where: { memeStocks.contains($0.symbol) }) {
            return StandoutPosition(
                stock: meme,
                reason: .memeStock,
                percentOfPortfolio: (meme.totalValue / totalValue) * 100
            )
        }

        // Check for tech giants that define perception
        let techGiants = ["NVDA", "TSLA", "AAPL", "GOOGL", "META", "AMZN", "MSFT"]
        if let tech = holdings.first(where: { techGiants.contains($0.symbol) }),
           (tech.totalValue / totalValue) * 100 > 15 {
            return StandoutPosition(
                stock: tech,
                reason: .techGiant,
                percentOfPortfolio: (tech.totalValue / totalValue) * 100
            )
        }

        // Check for high volatility (daily change > 3%)
        if let volatile = holdings.first(where: { abs($0.percentageChange) > 3 }) {
            return StandoutPosition(
                stock: volatile,
                reason: .highVolatility,
                percentOfPortfolio: (volatile.totalValue / totalValue) * 100
            )
        }

        // Default to largest position if it's significant
        if largestPercent > 25 {
            return StandoutPosition(
                stock: largest,
                reason: .concentration,
                percentOfPortfolio: largestPercent
            )
        }

        return StandoutPosition(
            stock: largest,
            reason: .largestHolding,
            percentOfPortfolio: largestPercent
        )
    }

    private func generatePerception(
        standout: StandoutPosition?,
        holdings: [Stock],
        totalValue: Double
    ) -> PortfolioAscendantAnalysis {
        guard let standout = standout else {
            return PortfolioAscendantAnalysis(
                perceivedAs: "The Mystery Investor",
                standoutStock: nil,
                standoutReason: "No clear standout",
                socialLabel: "Enigma",
                description: "Your portfolio defies categorization.",
                roast: "Even AI can't figure out your investment thesis."
            )
        }

        let stock = standout.stock
        let percent = standout.percentOfPortfolio

        switch standout.reason {
        case .memeStock:
            return PortfolioAscendantAnalysis(
                perceivedAs: "Diamond Hands Degen",
                standoutStock: stock,
                standoutReason: "That \(stock.symbol) position",
                socialLabel: "Ape",
                description: "One glimpse of \(stock.symbol) and everyone assumes you learned investing from Reddit.",
                roast: "Your portfolio screams 'I was there for the squeeze' even if you weren't."
            )

        case .techGiant:
            let techRoasts: [String: (label: String, desc: String, roast: String)] = [
                "NVDA": (
                    "AI Evangelist",
                    "That NVDA position makes you look like you've been talking about AI since before ChatGPT.",
                    "Everyone thinks you're a tech bro now. Leather jacket optional."
                ),
                "TSLA": (
                    "Elon Disciple",
                    "TSLA ownership broadcasts 'I believe in the mission' energy whether you do or not.",
                    "People assume you have opinions about Mars colonies. Strong ones."
                ),
                "AAPL": (
                    "Ecosystem Loyalist",
                    "AAPL signals you're the person who 'just likes quality products.'",
                    "Your portfolio says 'I own every Apple device and I'm not sorry.'"
                ),
                "META": (
                    "Metaverse Believer",
                    "META ownership says you're either visionary or delusional. No middle ground.",
                    "People think you own a VR headset. Do you? Be honest."
                ),
                "GOOGL": (
                    "Data Pragmatist",
                    "GOOGL makes you look like someone who 'understands moats.'",
                    "You come across as the person who actually reads 10-Ks. Nerd."
                ),
                "AMZN": (
                    "Convenience Capitalist",
                    "AMZN ownership screams 'I profit from my own Prime addiction.'",
                    "Your portfolio is basically a receipt from your own shopping habits."
                ),
                "MSFT": (
                    "Enterprise Enthusiast",
                    "MSFT says 'I appreciate boring excellence.'",
                    "You look like someone who uses Excel for fun. And you might."
                )
            ]

            let roastData = techRoasts[stock.symbol] ?? (
                "Tech Optimist",
                "Your tech holdings broadcast faith in innovation.",
                "Silicon Valley energy, whether you live there or not."
            )

            return PortfolioAscendantAnalysis(
                perceivedAs: roastData.label,
                standoutStock: stock,
                standoutReason: "\(String(format: "%.0f", percent))% in \(stock.symbol)",
                socialLabel: roastData.label,
                description: roastData.desc,
                roast: roastData.roast
            )

        case .highVolatility:
            return PortfolioAscendantAnalysis(
                perceivedAs: "Thrill Seeker",
                standoutStock: stock,
                standoutReason: "\(stock.symbol) moved \(String(format: "%.1f", stock.percentageChange))% today",
                socialLabel: "Adrenaline Junkie",
                description: "That \(stock.symbol) volatility makes your whole portfolio look like a casino bet.",
                roast: "Your blood pressure probably matches your portfolio's beta."
            )

        case .concentration:
            return PortfolioAscendantAnalysis(
                perceivedAs: "True Believer",
                standoutStock: stock,
                standoutReason: "\(String(format: "%.0f", percent))% concentrated in \(stock.symbol)",
                socialLabel: "All-In Artist",
                description: "With \(String(format: "%.0f", percent))% in \(stock.symbol), you look like you've married this stock.",
                roast: "Diversification? Never heard of her. And apparently neither have you."
            )

        case .largestHolding:
            return PortfolioAscendantAnalysis(
                perceivedAs: "The \(stock.zodiacSign.element.displayName) Investor",
                standoutStock: stock,
                standoutReason: "\(stock.symbol) leads your portfolio",
                socialLabel: stock.zodiacSign.element.displayName + " Energy",
                description: "\(stock.symbol) sets the tone. Your portfolio inherits its \(stock.zodiacSign.displayName) energy.",
                roast: "Your largest holding defines you. For better or worse, you're a \(stock.symbol) person now."
            )
        }
    }

    // MARK: - Contrast Generation

    private func generateContrast(
        sun: PortfolioSunAnalysis,
        ascendant: PortfolioAscendantAnalysis
    ) -> PortfolioContrast {
        let sunElement = sun.dominantElement
        let ascendantLabel = ascendant.socialLabel

        // Determine contrast level
        let contrastLevel: ContrastLevel
        let insight: String

        // Check for funny contrasts
        if sunElement == .earth && (ascendantLabel.contains("Tech") || ascendantLabel.contains("AI")) {
            contrastLevel = .dramatic
            insight = "You're a conservative Earth investor wearing a tech bro costume. The market sees NVDA, but your soul craves T-bills."
        } else if sunElement == .fire && ascendantLabel.contains("Conservative") {
            contrastLevel = .dramatic
            insight = "Fire burns in your heart, but your portfolio plays it cool. You're a risk-taker trapped in a boomer's body."
        } else if sunElement == .water && ascendantLabel.contains("Degen") {
            contrastLevel = .dramatic
            insight = "Your intuitive Water nature got seduced by meme energy. The heart wants dividends, the hands hold GME."
        } else if sunElement == .air && ascendantLabel.contains("Value") {
            contrastLevel = .moderate
            insight = "An innovation-minded Air investor with value vibes? You're a walking contradiction, and honestly, it's working."
        } else if sun.personality.contains("Conservative") && ascendant.perceivedAs.contains("Thrill") {
            contrastLevel = .dramatic
            insight = "Secretly conservative, publicly chaotic. One volatile stock is doing all the talking."
        } else if sun.personality.contains("Aggressive") && ascendant.perceivedAs.contains("Steady") {
            contrastLevel = .moderate
            insight = "Aggressive at heart, steady in appearance. Your poker face extends to your portfolio."
        } else {
            contrastLevel = .aligned
            insight = "Your portfolio's true nature and public image are in sync. What you hold is what you project."
        }

        return PortfolioContrast(
            level: contrastLevel,
            insight: insight,
            sunSummary: "\(sun.personality): \(sun.dominantElement.displayName)-heavy",
            ascendantSummary: ascendant.perceivedAs
        )
    }

    // MARK: - Shareable Quip

    private func generateShareableQuip(
        sun: PortfolioSunAnalysis,
        ascendant: PortfolioAscendantAnalysis
    ) -> String {
        if let standout = ascendant.standoutStock {
            return "Sun: \(sun.personality). Ascendant: That one \(standout.symbol) position makes me look like \(ascendant.socialLabel.lowercased())."
        } else {
            return "Sun: \(sun.personality). Ascendant: \(ascendant.perceivedAs). The duality of investing."
        }
    }
}

// MARK: - Supporting Types

struct PortfolioAscendantReading: Identifiable {
    let id = UUID()
    let userSign: ZodiacSign
    let sunAnalysis: PortfolioSunAnalysis
    let ascendantAnalysis: PortfolioAscendantAnalysis
    let contrast: PortfolioContrast
    let shareableQuip: String
    let holdings: [Stock]

    static func empty(userSign: ZodiacSign) -> PortfolioAscendantReading {
        PortfolioAscendantReading(
            userSign: userSign,
            sunAnalysis: PortfolioSunAnalysis(
                dominantElement: .earth,
                elementBreakdown: [:],
                dominantSign: .taurus,
                signBreakdown: [:],
                personality: "The Blank Slate",
                description: "No holdings to analyze yet."
            ),
            ascendantAnalysis: PortfolioAscendantAnalysis(
                perceivedAs: "Ghost",
                standoutStock: nil,
                standoutReason: "Empty portfolio",
                socialLabel: "Invisible",
                description: "The market doesn't know you exist.",
                roast: "You can't have an ascendant without ascending first."
            ),
            contrast: PortfolioContrast(
                level: .aligned,
                insight: "Start investing to discover your portfolio's cosmic identity.",
                sunSummary: "Unknown",
                ascendantSummary: "Unknown"
            ),
            shareableQuip: "My portfolio's ascendant is: nonexistent. Time to change that.",
            holdings: []
        )
    }
}

struct PortfolioSunAnalysis {
    let dominantElement: ZodiacSign.Element
    let elementBreakdown: [ZodiacSign.Element: Double]
    let dominantSign: ZodiacSign
    let signBreakdown: [ZodiacSign: Double]
    let personality: String
    let description: String
}

struct PortfolioAscendantAnalysis {
    let perceivedAs: String
    let standoutStock: Stock?
    let standoutReason: String
    let socialLabel: String
    let description: String
    let roast: String
}

struct PortfolioContrast {
    let level: ContrastLevel
    let insight: String
    let sunSummary: String
    let ascendantSummary: String
}

enum ContrastLevel {
    case aligned    // Sun and Ascendant match
    case moderate   // Some difference
    case dramatic   // Major contrast (the funny ones)

    var displayName: String {
        switch self {
        case .aligned: return "Aligned"
        case .moderate: return "Interesting"
        case .dramatic: return "Dramatic"
        }
    }

    var icon: String {
        switch self {
        case .aligned: return "equal.circle.fill"
        case .moderate: return "arrow.left.arrow.right.circle.fill"
        case .dramatic: return "theatermasks.fill"
        }
    }

    var color: Color {
        switch self {
        case .aligned: return .green
        case .moderate: return .orange
        case .dramatic: return .purple
        }
    }
}

struct StandoutPosition {
    let stock: Stock
    let reason: StandoutReason
    let percentOfPortfolio: Double
}

enum StandoutReason {
    case memeStock
    case techGiant
    case highVolatility
    case concentration
    case largestHolding
}
