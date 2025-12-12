import Foundation
import SwiftUI

// MARK: - CosmicRoastGenerator
// ============================
// Generates brutal but funny astrological portfolio roasts.
// This is the "screenshot and send to group chat" feature.
//
// The roast tone scales with portfolio performance:
// - Losing money? Get roasted for your choices
// - Making money? Get roasted for your overconfidence
// - Either way, the cosmos has opinions

final class CosmicRoastGenerator {

    // MARK: - Main Generation

    static func generate(for user: UserProfile) -> CosmicRoast {
        let elementBreakdown = calculateElementBreakdown(for: user)
        let worstPerformer = findWorstPerformer(in: user.portfolio)
        let ytdReturn = calculateYTDReturn(for: user)
        let assessment = CosmicAssessmentLevel.from(ytdReturn: ytdReturn)

        let sectorAnalysis = elementBreakdown.map { breakdown -> SectorAnalysis in
            let status: SectorAnalysis.SectorStatus
            switch breakdown.percentage {
            case 0..<5: status = .critical
            case 5..<15: status = .underweight
            case 15..<40: status = .balanced
            default: status = .overweight
            }
            return SectorAnalysis(
                element: breakdown.element,
                percentage: breakdown.percentage,
                status: status,
                value: breakdown.value
            )
        }

        let dominantElement = elementBreakdown.max(by: { $0.percentage < $1.percentage })?.element ?? .fire
        let dominantPercentage = elementBreakdown.max(by: { $0.percentage < $1.percentage })?.percentage ?? 0

        return CosmicRoast(
            generatedDate: Date(),
            reportTitle: "COSMIC AUDIT REPORT",
            auditorName: "The Universe",
            portfolioValue: user.totalPortfolioValue,
            ytdReturn: ytdReturn,
            cosmicAssessment: assessment.rawValue,
            assessmentIcon: assessment.icon,
            sectorBreakdown: sectorAnalysis,
            sectorDiagnosis: generateSectorDiagnosis(
                dominant: dominantElement,
                percentage: dominantPercentage,
                userSign: user.sunSign
            ),
            roastTitle: "THE COSMIC VERDICT",
            roastContent: generateMainRoast(
                user: user,
                dominantElement: dominantElement,
                dominantPercentage: dominantPercentage,
                ytdReturn: ytdReturn
            ),
            weakestLink: worstPerformer.map { stock in
                WeakestLinkCallout(
                    symbol: stock.symbol,
                    name: stock.name,
                    percentageChange: stock.percentageChange,
                    zodiacSign: stock.zodiacSign,
                    roastNote: generateWeakestLinkNote(for: stock)
                )
            },
            recommendation: generateRecommendation(
                dominantElement: dominantElement,
                ytdReturn: ytdReturn,
                userSign: user.sunSign
            ),
            recommendationSubtext: generateRecommendationSubtext(ytdReturn: ytdReturn),
            disclaimer: generateDisclaimer(ytdReturn: ytdReturn)
        )
    }

    // MARK: - Element Breakdown

    private static func calculateElementBreakdown(for user: UserProfile) -> [ElementBreakdown] {
        let totalValue = user.totalPortfolioValue
        guard totalValue > 0 else {
            return ZodiacSign.Element.allCases.map {
                ElementBreakdown(element: $0, percentage: 0, value: 0)
            }
        }

        var elementValues: [ZodiacSign.Element: Double] = [:]
        for stock in user.portfolio where stock.sharesOwned > 0 {
            let element = stock.zodiacSign.element
            elementValues[element, default: 0] += stock.totalValue
        }

        return ZodiacSign.Element.allCases.map { element in
            let value = elementValues[element] ?? 0
            let percentage = (value / totalValue) * 100
            return ElementBreakdown(element: element, percentage: percentage, value: value)
        }
    }

    private struct ElementBreakdown {
        let element: ZodiacSign.Element
        let percentage: Double
        let value: Double
    }

    // MARK: - YTD Calculation (Simulated)

    private static func calculateYTDReturn(for user: UserProfile) -> Double {
        // For demo purposes, calculate based on daily changes
        // In production, this would use actual historical data
        let totalChange = user.totalDailyChange
        let portfolioValue = user.totalPortfolioValue

        guard portfolioValue > 0 else { return 0 }

        // Extrapolate daily to "YTD" for dramatic effect
        let dailyPercent = user.totalDailyChangePercent
        return dailyPercent * 5 // Simulated YTD multiplier
    }

    // MARK: - Worst Performer

    private static func findWorstPerformer(in portfolio: [Stock]) -> Stock? {
        portfolio
            .filter { $0.sharesOwned > 0 }
            .min(by: { $0.percentageChange < $1.percentageChange })
    }

    // MARK: - Sector Diagnosis

    private static func generateSectorDiagnosis(
        dominant: ZodiacSign.Element,
        percentage: Double,
        userSign: ZodiacSign
    ) -> String {
        let signDescriptors: [ZodiacSign: (risk: String, savings: String)] = [
            .aries: ("a caffeinated Aries", "a squirrel"),
            .taurus: ("a stubborn Taurus", "a dragon"),
            .gemini: ("an indecisive Gemini", "their evil twin"),
            .cancer: ("an emotional Cancer", "a hermit crab"),
            .leo: ("a dramatic Leo", "a street performer"),
            .virgo: ("an anxious Virgo", "a spreadsheet"),
            .libra: ("an indecisive Libra", "someone who pays full price"),
            .scorpio: ("a revenge-plotting Scorpio", "a bond villain"),
            .sagittarius: ("a YOLO Sagittarius", "someone with a plan"),
            .capricorn: ("a boring Capricorn", "an overworked accountant"),
            .aquarius: ("a contrarian Aquarius", "someone who read the terms and conditions"),
            .pisces: ("a daydreaming Pisces", "a lottery winner")
        ]

        let descriptors = signDescriptors[userSign] ?? ("a human", "someone")

        if percentage > 60 {
            switch dominant {
            case .fire:
                return "Portfolio has the risk tolerance of \(descriptors.risk) with the savings account of \(descriptors.savings)."
            case .earth:
                return "Portfolio is so stable it's basically a savings bond cosplaying as investments."
            case .air:
                return "Portfolio diversification: analyzed. Actual execution: still pending."
            case .water:
                return "Portfolio allocation based on feelings and the position of Neptune."
            }
        } else if percentage > 40 {
            return "Slight \(dominant.displayName) lean detected. The cosmos notes your preference for \(dominant == .fire ? "setting money on fire" : dominant == .water ? "going with the flow" : dominant == .earth ? "burying treasure" : "overthinking")."
        } else {
            return "Elementally balanced. Either enlightened or just confused about their investment thesis."
        }
    }

    // MARK: - Main Roast Generation

    private static func generateMainRoast(
        user: UserProfile,
        dominantElement: ZodiacSign.Element,
        dominantPercentage: Double,
        ytdReturn: Double
    ) -> String {
        // Empty portfolio
        if user.portfolio.isEmpty || user.totalPortfolioValue == 0 {
            return "Your portfolio is emptier than a Gemini's commitment. The cosmos can't roast what doesn't exist. This is simultaneously your safest and saddest financial decision."
        }

        // Very negative performance
        if ytdReturn < -15 {
            return selectRoast(from: devastatingRoasts(
                element: dominantElement,
                percentage: dominantPercentage,
                userSign: user.sunSign
            ))
        }

        // Negative performance
        if ytdReturn < 0 {
            return selectRoast(from: negativeRoasts(
                element: dominantElement,
                percentage: dominantPercentage,
                userSign: user.sunSign
            ))
        }

        // Positive but modest
        if ytdReturn < 20 {
            return selectRoast(from: modestGainsRoasts(
                element: dominantElement,
                percentage: dominantPercentage,
                userSign: user.sunSign
            ))
        }

        // Very positive - roast the overconfidence
        return selectRoast(from: overconfidenceRoasts(
            element: dominantElement,
            percentage: dominantPercentage,
            userSign: user.sunSign
        ))
    }

    private static func selectRoast(from roasts: [String]) -> String {
        roasts.randomElement() ?? "The stars have no words. That's not a good sign."
    }

    // MARK: - Devastating Roasts (ytd < -15%)

    private static func devastatingRoasts(
        element: ZodiacSign.Element,
        percentage: Double,
        userSign: ZodiacSign
    ) -> [String] {
        [
            "Your portfolio is \(Int(percentage))% \(element.displayName) sector in what appears to be a personal vendetta against compound interest. Mercury isn't in retrograde — your decision-making is.",

            "The stars aligned to warn you. You responded by doubling down. This is the financial equivalent of wearing a 'kick me' sign to a rodeo.",

            "Your \(userSign.displayName) intuition told you to buy. Your \(userSign.displayName) intuition was wrong. The good news? At least you're consistent.",

            "This portfolio has all the cosmic alignment of a drunk astrologer throwing darts. The darts missed the board and hit your savings account.",

            "You've somehow found stocks that make your worst ex look like a sound investment. The universe is impressed by your commitment to chaos.",

            "Your portfolio's \(element.displayName) concentration suggests you read your horoscope and thought 'that sounds like financial advice.' It wasn't."
        ]
    }

    // MARK: - Negative Roasts (ytd between -15% and 0%)

    private static func negativeRoasts(
        element: ZodiacSign.Element,
        percentage: Double,
        userSign: ZodiacSign
    ) -> [String] {
        [
            "Your portfolio is down, but not devastatingly so. It's giving 'trying their best' energy, which is the participation trophy of investing.",

            "The \(element.displayName) sector makes up \(Int(percentage))% of your holdings. The remaining \(100 - Int(percentage))% is disappointment and unrealized potential.",

            "As a \(userSign.displayName), you were destined to make bold choices. Unfortunately, 'bold' and 'profitable' aren't synonyms.",

            "Your portfolio is in the red, which at least matches the color of the flags you ignored. The cosmos tried to warn you through vibes alone.",

            "You've achieved the rare status of 'cosmically inconvenienced.' Not quite cursed, but the stars definitely unfollowed you.",

            "This portfolio has \(userSign.displayName) energy: \(userSign.element == .fire ? "passionate but impulsive" : userSign.element == .water ? "intuitive but emotional" : userSign.element == .earth ? "stubborn but patient" : "analytical but indecisive"). The market does not care about your feelings."
        ]
    }

    // MARK: - Modest Gains Roasts (ytd between 0% and 20%)

    private static func modestGainsRoasts(
        element: ZodiacSign.Element,
        percentage: Double,
        userSign: ZodiacSign
    ) -> [String] {
        [
            "You're in the green. Barely. This is the investing equivalent of passing a class with a C-. Technically a win, spiritually a journey.",

            "Your \(element.displayName)-heavy portfolio is performing... adequately. The cosmos gives you a firm 'acceptable.' Frame that.",

            "Congratulations, you've outperformed keeping cash under your mattress. The bar was low, but you cleared it. Mostly.",

            "As a \(userSign.displayName), you expected the stars to shower you with gains. They sent a drizzle. Take what you can get.",

            "Your portfolio is up, which means you're doing better than \(Int.random(in: 40...60))% of people who also trusted the cosmos. Low bar, but noted.",

            "The \(Int(percentage))% \(element.displayName) allocation is working... for now. Don't let this modest success go to your head. That's a \(userSign.displayName) trait."
        ]
    }

    // MARK: - Overconfidence Roasts (ytd > 20%)

    private static func overconfidenceRoasts(
        element: ZodiacSign.Element,
        percentage: Double,
        userSign: ZodiacSign
    ) -> [String] {
        [
            "Your portfolio is up significantly. The cosmos reminds you that pride comes before Mercury retrograde. Enjoy it while the stars are aligned.",

            "Strong gains detected. You're probably feeling like a genius right now. You're not. You got lucky. The universe wants you humble.",

            "The \(element.displayName) sector carried you to victory. Don't confuse a bull market for brilliance. That's classic \(userSign.displayName) behavior.",

            "You've beaten the market. The stars are suspicious. Either you've cracked the cosmic code or you're about to learn a valuable lesson.",

            "Impressive returns. The cosmos notes you're probably already telling everyone about your 'strategy.' It was luck. Mostly luck.",

            "Your portfolio is up, which means you'll ignore all future advice. Very \(userSign.displayName) of you. The stars will remember this hubris."
        ]
    }

    // MARK: - Weakest Link Notes

    private static func generateWeakestLinkNote(for stock: Stock) -> String {
        let signNotes: [ZodiacSign: [String]] = [
            .aries: ["This Aries stock charged in first and asked questions never.", "Classic Aries energy: all aggression, no strategy."],
            .taurus: ["This Taurus stock is as stubborn about going down as it is about going up.", "Taurus stocks move slowly. This one found a new direction: down."],
            .gemini: ["This Gemini stock can't decide if it's a growth or value trap.", "Two-faced like a true Gemini. Both faces are crying."],
            .cancer: ["This Cancer stock is emotionally manipulating your portfolio.", "Clings to red like a Cancer clings to the past."],
            .leo: ["This Leo stock needed attention. It's getting it. For the wrong reasons.", "Leo stocks demand the spotlight. This one's on fire (not the good kind)."],
            .virgo: ["This Virgo stock analyzed itself into a death spiral.", "Perfectionist Virgo energy — perfectly terrible performance."],
            .libra: ["This Libra stock can't decide between tanking and crashing.", "Seeking balance between disappointing and devastating."],
            .scorpio: ["This Scorpio stock is as emotionally volatile as it sounds.", "Scorpio intensity, but make it losses."],
            .sagittarius: ["This Sagittarius stock adventured right off a cliff.", "YOLO energy with goodbye returns."],
            .capricorn: ["This Capricorn stock's five-year plan didn't account for... this.", "So disciplined it's disciplining your portfolio into the ground."],
            .aquarius: ["This Aquarius stock is unique. Uniquely disappointing.", "Too innovative to make money, apparently."],
            .pisces: ["This Pisces stock is living in a dream. A nightmare, specifically.", "Swimming against the current. The current is winning."]
        ]

        return (signNotes[stock.zodiacSign]?.randomElement()) ?? "The stars decline to comment."
    }

    // MARK: - Recommendations

    private static func generateRecommendation(
        dominantElement: ZodiacSign.Element,
        ytdReturn: Double,
        userSign: ZodiacSign
    ) -> String {
        let deficientElement: ZodiacSign.Element
        switch dominantElement {
        case .fire: deficientElement = .earth
        case .earth: deficientElement = .air
        case .air: deficientElement = .water
        case .water: deficientElement = .fire
        }

        if ytdReturn < -10 {
            return "Suggested Action: Add \(deficientElement.displayName) sector for stability. Consider also: therapy."
        } else if ytdReturn < 0 {
            return "Suggested Action: Balance with \(deficientElement.displayName) energy. Or blame Mercury. Your choice."
        } else if ytdReturn < 15 {
            return "Suggested Action: Maintain course. Maybe add some \(deficientElement.displayName) for cosmic balance."
        } else {
            return "Suggested Action: Touch grass. Your gains have gone to your head. Classic \(userSign.displayName)."
        }
    }

    private static func generateRecommendationSubtext(ytdReturn: Double) -> String {
        if ytdReturn < -10 {
            return "Or don't. Free will is an illusion anyway."
        } else if ytdReturn < 0 {
            return "The universe is testing you. Don't fail."
        } else if ytdReturn < 20 {
            return "Not financial advice. The stars don't have licenses."
        } else {
            return "Pride comes before the fall. Just saying."
        }
    }

    // MARK: - Disclaimers

    private static func generateDisclaimer(ytdReturn: Double) -> String {
        if ytdReturn < -10 {
            return "This roast is for entertainment purposes only. Unlike your portfolio, which is apparently also for entertainment."
        } else if ytdReturn < 0 {
            return "This report is satirical. Your losses, unfortunately, are not."
        } else if ytdReturn < 20 {
            return "Past performance doesn't guarantee future results. Neither does reading your horoscope."
        } else {
            return "This roast is for entertainment. Your overconfidence, however, is concerning."
        }
    }
}
