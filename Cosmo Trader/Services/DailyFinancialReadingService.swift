import Foundation
import SwiftUI

@MainActor
final class DailyFinancialReadingService {
    static let shared = DailyFinancialReadingService()

    private init() {}

    func compose(for user: UserProfile?, backendBrief: DailyBriefResponse? = nil) -> DailyFinancialReading {
        guard let user else {
            return emptyReading(
                headline: "Portfolio setup needed for a real reading",
                impact: "Add your holdings to generate a daily financial astrology reading. Start with 3-5 tickers or import a broker screenshot, then Today can map exposure, concentration, and names to watch.",
                framingLevel: .balanced
            )
        }

        let holdings = user.portfolio.filter(\.isOwned)
        guard !holdings.isEmpty else {
            return emptyReading(
                headline: "No portfolio reading yet",
                impact: "Your market and lunar tape is live, but portfolio impact needs positions. Add 3-5 tickers so Cosmo can connect today's posture to what you actually own.",
                framingLevel: user.signalFramingLevel
            )
        }

        let lunarData = MoonPhaseService.shared.getCurrentLunarData()
        let mercury = MercuryRetrogradeService.shared
        mercury.refreshStatus()

        let mood = CosmicMoodService.shared.getCurrentMood()
        let events = AstroAlertService.shared.activeEvents
        let dominantElement = dominantElementExposure(in: holdings)
        let dominantSector = dominantSectorExposure(in: holdings)
        let alignedElementCount = holdings.filter { $0.foundedElement == lunarData.activatedElement }.count
        let affectedHoldings = holdings.filter { stock in
            AstroAlertService.shared.isStockAffected(stock) || isMercurySensitive(stock, mercury: mercury)
        }

        let watchItems = buildWatchItems(
            user: user,
            holdings: holdings,
            lunarElement: lunarData.activatedElement,
            affectedHoldings: affectedHoldings
        )
        let bestMove = determineBestMove(
            user: user,
            holdings: holdings,
            mood: mood,
            mercury: mercury,
            affectedHoldings: affectedHoldings
        )

        return DailyFinancialReading(
            date: Date(),
            signalHeadline: signalHeadline(
                user: user,
                holdings: holdings,
                dominantElement: dominantElement?.element,
                dominantSector: dominantSector?.sector,
                mood: mood,
                mercury: mercury,
                bestMove: bestMove
            ),
            marketCosmicPosture: postureText(
                framingLevel: user.signalFramingLevel,
                mood: mood,
                lunarData: lunarData,
                mercury: mercury,
                activeEvents: events,
                backendBrief: backendBrief
            ),
            portfolioImpact: portfolioImpactText(
                user: user,
                holdings: holdings,
                dominantElement: dominantElement,
                dominantSector: dominantSector,
                lunarElement: lunarData.activatedElement,
                alignedElementCount: alignedElementCount,
                affectedHoldings: affectedHoldings
            ),
            watchItems: watchItems,
            bestMove: bestMove,
            grounding: groundingText(user: user, activeEvents: events, backendBrief: backendBrief),
            framingLevel: user.signalFramingLevel,
            portfolioValue: user.formattedPortfolioValue,
            portfolioReturn: "\(user.formattedDailyChange) (\(user.formattedDailyChangePercent))",
            dominantExposure: dominantElement.map {
                DailyReadingExposure(
                    label: "\($0.element.displayName) exposure",
                    detail: String(format: "%.0f%% of portfolio value", $0.weight * 100),
                    color: terminalElementColor($0.element)
                )
            },
            lunarPhase: "\(lunarData.phase.rawValue) / \(lunarData.moonSign.displayName)",
            mercuryStatus: mercury.statusMessage,
            marketTone: "\(mood.moodLevel.sentimentName) \(mood.formattedValue)",
            activeEvents: events.prefix(3).map { $0.title },
            needsPortfolioSetup: false
        )
    }

    private func emptyReading(headline: String, impact: String, framingLevel: SignalFramingLevel) -> DailyFinancialReading {
        let lunarData = MoonPhaseService.shared.getCurrentLunarData()
        let mercury = MercuryRetrogradeService.shared
        mercury.refreshStatus()
        let mood = CosmicMoodService.shared.getCurrentMood()
        let events = AstroAlertService.shared.activeEvents

        return DailyFinancialReading(
            date: Date(),
            signalHeadline: headline,
            marketCosmicPosture: postureText(
                framingLevel: framingLevel,
                mood: mood,
                lunarData: lunarData,
                mercury: mercury,
                activeEvents: events,
                backendBrief: nil
            ),
            portfolioImpact: impact,
            watchItems: [],
            bestMove: .review,
            grounding: "Based on current market tone, lunar phase, active events, and available profile settings. Portfolio confidence stays low until holdings are added.",
            framingLevel: framingLevel,
            portfolioValue: nil,
            portfolioReturn: nil,
            dominantExposure: nil,
            lunarPhase: "\(lunarData.phase.rawValue) / \(lunarData.moonSign.displayName)",
            mercuryStatus: mercury.statusMessage,
            marketTone: "\(mood.moodLevel.sentimentName) \(mood.formattedValue)",
            activeEvents: events.prefix(3).map { $0.title },
            needsPortfolioSetup: true
        )
    }

    private func signalHeadline(
        user: UserProfile,
        holdings: [Stock],
        dominantElement: ZodiacSign.Element?,
        dominantSector: String?,
        mood: CosmicMoodData,
        mercury: MercuryRetrogradeService,
        bestMove: DailyReadingMove
    ) -> String {
        if mercury.isRetrograde {
            return "Review tape for \(dominantSector ?? "core") exposure"
        }

        if abs(user.totalDailyChangePercent) >= 2 {
            let direction = user.totalDailyChangePercent >= 0 ? "Momentum" : "Drawdown"
            return "\(direction) day for \(dominantSector ?? "portfolio") exposure"
        }

        if mood.value <= 40 {
            return "Low-conviction tape; worth reviewing"
        }

        if mood.value >= 75 {
            return "Risk appetite is elevated; keep the reading in perspective"
        }

        if let dominantElement {
            return "\(dominantElement.displayName) exposure is loud; discipline matters"
        }

        return "\(bestMove.rawValue) posture for a mixed market"
    }

    private func postureText(
        framingLevel: SignalFramingLevel,
        mood: CosmicMoodData,
        lunarData: LunarData,
        mercury: MercuryRetrogradeService,
        activeEvents: [CosmicEvent],
        backendBrief: DailyBriefResponse?
    ) -> String {
        let eventClause = activeEvents.isEmpty
            ? "no major active event override"
            : "\(activeEvents.prefix(2).map(\.title).joined(separator: ", ")) active"

        switch framingLevel {
        case .rational:
            return "Market tone is \(mood.moodLevel.sentimentName.lowercased()) at \(mood.value)/100, with \(eventClause). Treat this as context, not advice."
        case .leanRational:
            return "Market tone is \(mood.moodLevel.sentimentName.lowercased()) at \(mood.value)/100 while the lunar cycle points to \(lunarData.phase.rawValue.lowercased()) conditions. \(mercury.statusMessage) keeps execution discipline in focus."
        case .balanced:
            return "The tape is \(mood.moodLevel.sentimentName.lowercased()) and the \(lunarData.phase.rawValue.lowercased()) moon in \(lunarData.moonSign.displayName) puts \(lunarData.activatedElement.displayName.lowercased()) names in focus. \(mercury.statusMessage) argues for quiet positioning and no theatrics."
        case .leanMystical, .mystical:
            return "The \(lunarData.phase.rawValue.lowercased()) moon in \(lunarData.moonSign.displayName) activates \(lunarData.activatedElement.displayName.lowercased()) exposure while the market mood reads \(mood.moodLevel.sentimentName.lowercased()). \(mercury.tradingAdvice)"
        }
    }

    private func portfolioImpactText(
        user: UserProfile,
        holdings: [Stock],
        dominantElement: (element: ZodiacSign.Element, weight: Double)?,
        dominantSector: (sector: String, weight: Double)?,
        lunarElement: ZodiacSign.Element,
        alignedElementCount: Int,
        affectedHoldings: [Stock]
    ) -> String {
        let valueText = "\(user.formattedPortfolioValue), \(user.formattedDailyChange) today (\(user.formattedDailyChangePercent))"
        let elementText = dominantElement.map {
            "\($0.element.displayName.lowercased()) exposure at \(String(format: "%.0f", $0.weight * 100))%"
        } ?? "no clear element concentration"
        let sectorText = dominantSector.map {
            "\($0.sector.lowercased()) at \(String(format: "%.0f", $0.weight * 100))%"
        } ?? "mixed sector exposure"

        if !affectedHoldings.isEmpty {
            let symbols = affectedHoldings.prefix(3).map(\.symbol).joined(separator: ", ")
            return "Your portfolio reads \(valueText). The main concentration is \(elementText), with \(sectorText). Today's active conditions put \(symbols) most exposed."
        }

        if alignedElementCount > 0 {
            return "Your portfolio reads \(valueText). The main concentration is \(elementText), with \(sectorText). The moon activates \(lunarElement.displayName.lowercased()) exposure, matching \(alignedElementCount) holding\(alignedElementCount == 1 ? "" : "s")."
        }

        return "Your portfolio reads \(valueText). The main concentration is \(elementText), with \(sectorText). No single holding dominates the reading, so posture matters more than certainty."
    }

    private func buildWatchItems(
        user: UserProfile,
        holdings: [Stock],
        lunarElement: ZodiacSign.Element,
        affectedHoldings: [Stock]
    ) -> [DailyReadingWatchItem] {
        var selected: [Stock] = []

        selected.append(contentsOf: affectedHoldings)
        selected.append(contentsOf: holdings.sorted { abs($0.percentageChange) > abs($1.percentageChange) })
        selected.append(contentsOf: holdings.sorted { $0.totalValue > $1.totalValue })

        let uniqueHoldings = uniqueStocks(selected).prefix(3).map { stock in
            DailyReadingWatchItem(
                id: "holding-\(stock.symbol)",
                symbol: stock.symbol,
                name: stock.name,
                source: .holding,
                reason: watchReason(for: stock, lunarElement: lunarElement, affected: affectedHoldings.contains(stock)),
                changeText: stock.formattedPercentageChange,
                isPositive: stock.isPositive
            )
        }

        var items = Array(uniqueHoldings)
        if items.count < 4 {
            let watchlistStocks = user.watchlist.compactMap { symbol in
                MockStockData.knownStocks.first { $0.symbol == symbol }
            }
            for stock in watchlistStocks where !items.contains(where: { $0.symbol == stock.symbol }) {
                items.append(
                    DailyReadingWatchItem(
                        id: "watchlist-\(stock.symbol)",
                        symbol: stock.symbol,
                        name: stock.name,
                        source: .watchlist,
                        reason: "\(stock.sector) candidate on your watchlist; compare against today's \(lunarElement.displayName.lowercased()) activation.",
                        changeText: stock.formattedPercentageChange,
                        isPositive: stock.isPositive
                    )
                )
                if items.count == 4 { break }
            }
        }

        return items
    }

    private func watchReason(for stock: Stock, lunarElement: ZodiacSign.Element, affected: Bool) -> String {
        if affected {
            return "Active event exposure plus \(stock.sector.lowercased()) beta makes this the first read."
        }

        if abs(stock.percentageChange) >= 5 {
            return "Large move today; confirm volume before trusting the tape."
        }

        if stock.foundedElement == lunarElement {
            return "\(lunarElement.displayName) signature matches today's lunar activation."
        }

        if stock.totalValue > 0 {
            return "Large position weight; small moves matter here."
        }

        return "Watch for confirmation before changing posture."
    }

    private func determineBestMove(
        user: UserProfile,
        holdings: [Stock],
        mood: CosmicMoodData,
        mercury: MercuryRetrogradeService,
        affectedHoldings: [Stock]
    ) -> DailyReadingMove {
        if mercury.isRetrograde || mercury.status == .preShadow {
            return .review
        }

        if user.totalDailyChangePercent <= -2 || affectedHoldings.count >= 3 {
            return .reduceRisk
        }

        if mood.value >= 75 && user.totalDailyChangePercent > 1 {
            return .avoidChasing
        }

        if mood.value <= 40 {
            return .waitForConfirmation
        }

        if holdings.contains(where: { abs($0.percentageChange) >= 5 }) {
            return .watch
        }

        return .hold
    }

    private func groundingText(user: UserProfile, activeEvents: [CosmicEvent], backendBrief: DailyBriefResponse?) -> String {
        var basis = ["portfolio balance", "daily P/L", "lunar phase", "Mercury status", "current market mood"]
        if !activeEvents.isEmpty {
            basis.append("active events")
        }
        if backendBrief != nil {
            basis.append("saved Daily Brief")
        }
        basis.append("\(user.signalFramingLevel.displayName.lowercased()) framing")
        return "Based on \(basis.joined(separator: ", ")). This is posture guidance, not certainty."
    }

    private func dominantElementExposure(in holdings: [Stock]) -> (element: ZodiacSign.Element, weight: Double)? {
        let verifiedHoldings = holdings.filter { $0.foundedElement != nil }
        let totalValue = verifiedHoldings.reduce(0) { $0 + max($1.totalValue, 0) }
        guard totalValue > 0 else { return nil }

        var exposures: [ZodiacSign.Element: Double] = [:]
        for stock in verifiedHoldings {
            guard let element = stock.foundedElement else { continue }
            exposures[element, default: 0] += max(stock.totalValue, 0) / totalValue
        }

        return exposures.max { $0.value < $1.value }.map { ($0.key, $0.value) }
    }

    private func dominantSectorExposure(in holdings: [Stock]) -> (sector: String, weight: Double)? {
        let totalValue = holdings.reduce(0) { $0 + max($1.totalValue, 0) }
        guard totalValue > 0 else { return nil }

        let exposures = Dictionary(grouping: holdings, by: \.sector).mapValues { stocks in
            stocks.reduce(0) { $0 + max($1.totalValue, 0) } / totalValue
        }

        return exposures.max { $0.value < $1.value }.map { ($0.key, $0.value) }
    }

    private func uniqueStocks(_ stocks: [Stock]) -> [Stock] {
        var seen: Set<String> = []
        return stocks.filter { stock in
            guard !seen.contains(stock.symbol) else { return false }
            seen.insert(stock.symbol)
            return true
        }
    }

    private func isMercurySensitive(_ stock: Stock, mercury: MercuryRetrogradeService) -> Bool {
        guard mercury.isRetrograde || mercury.status == .preShadow else { return false }
        let sector = stock.sector.lowercased()
        return sector.contains("technology")
            || sector.contains("communication")
            || sector.contains("fintech")
            || stock.foundedElement == .air
    }

    private func terminalElementColor(_ element: ZodiacSign.Element) -> Color {
        switch element {
        case .fire: return CosmicTheme.fireElement
        case .earth: return CosmicTheme.earthElement
        case .air: return CosmicTheme.airElement
        case .water: return CosmicTheme.waterElement
        }
    }
}
