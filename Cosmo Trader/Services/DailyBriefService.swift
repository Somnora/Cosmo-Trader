import Foundation
import SwiftUI

// MARK: - DailyBriefService
// =========================
// Generates personalized "zen trading" daily briefs based on cosmic conditions,
// portfolio performance, and market activity.

// MARK: - Daily Brief

struct DailyBrief {
    let date: Date
    let cosmicHeadline: String
    let cosmicConditions: CosmicConditions
    let watchlistHighlights: [WatchlistHighlight]
    let suggestedAction: SuggestedAction
    let newsAlerts: [NewsAlert]
    let streak: StreakInfo
    let framingLevel: SignalFramingLevel

    /// Framed version of cosmic conditions summary
    var framedConditionsSummary: String {
        SignalFramingService.shared.frameConditions(
            energy: cosmicConditions.overallEnergy,
            mercury: cosmicConditions.mercuryStatus,
            moon: cosmicConditions.moonPhase,
            level: framingLevel
        )
    }

    /// Framed posture note title and description
    var framedSuggestedAction: (title: String, description: String) {
        SignalFramingService.shared.frameSuggestedAction(
            action: suggestedAction,
            level: framingLevel
        )
    }

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter.string(from: date)
    }

    var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        case 17..<21: return "Good evening"
        default: return "Good night"
        }
    }
}

// MARK: - Cosmic Conditions

struct CosmicConditions {
    let overallEnergy: CosmicEnergyLevel
    let moonPhase: MoonPhase
    let mercuryStatus: MercuryStatus
    let dominantElement: ZodiacSign.Element
    let volatilityTolerance: VolatilityTolerance

    var summary: String {
        switch overallEnergy {
        case .high:
            return "Cosmic energy is elevated. Markets may see increased activity."
        case .moderate:
            return "Balanced cosmic conditions. Steady approach recommended."
        case .low:
            return "Low cosmic energy. Focus on preservation over growth."
        case .cautious:
            return "Mixed signals in the cosmos. Exercise extra caution today."
        }
    }
}

// MARK: - Energy Level

enum CosmicEnergyLevel: String, CaseIterable {
    case high = "High"
    case moderate = "Moderate"
    case low = "Low"
    case cautious = "Cautious"

    var sfSymbol: String {
        switch self {
        case .high: return "bolt.fill"
        case .moderate: return "equal"
        case .low: return "moon.fill"
        case .cautious: return "exclamationmark.triangle.fill"
        }
    }

    var color: Color {
        switch self {
        case .high: return CosmicTheme.positive
        case .moderate: return CosmicTheme.gold
        case .low: return CosmicTheme.nebulaBlue
        case .cautious: return .orange
        }
    }

    var description: String {
        switch self {
        case .high: return "High energy day"
        case .moderate: return "Balanced energy"
        case .low: return "Rest and observe"
        case .cautious: return "Proceed carefully"
        }
    }
}

// MARK: - Mercury Status

enum MercuryStatus: String, CaseIterable {
    case direct = "Direct"
    case retrograde = "Retrograde"
    case preShadow = "Pre-Shadow"
    case postShadow = "Post-Shadow"

    var sfSymbol: String {
        switch self {
        case .direct: return "arrow.up.right"
        case .retrograde: return "arrow.uturn.backward"
        case .preShadow: return "arrow.down.right"
        case .postShadow: return "arrow.up.forward"
        }
    }

    var color: Color {
        switch self {
        case .direct: return CosmicTheme.positive
        case .retrograde: return CosmicTheme.negative
        case .preShadow: return .orange
        case .postShadow: return CosmicTheme.gold
        }
    }

    var tradingAdvice: String {
        switch self {
        case .direct:
            return "Communications clear. Good for new initiatives."
        case .retrograde:
            return "Review existing positions. Avoid major new commitments."
        case .preShadow:
            return "Slowdown approaching. Finalize pending decisions."
        case .postShadow:
            return "Clarity returning. Resume normal trading activity."
        }
    }
}

// MARK: - Volatility Tolerance

enum VolatilityTolerance: String, CaseIterable {
    case embrace = "Embrace"
    case neutral = "Neutral"
    case avoid = "Avoid"

    var sfSymbol: String {
        switch self {
        case .embrace: return "waveform.path.ecg"
        case .neutral: return "minus"
        case .avoid: return "hand.raised.fill"
        }
    }

    var color: Color {
        switch self {
        case .embrace: return CosmicTheme.positive
        case .neutral: return CosmicTheme.textSecondary
        case .avoid: return CosmicTheme.negative
        }
    }

    var advice: String {
        switch self {
        case .embrace: return "Volatility may be worth reviewing"
        case .neutral: return "Normal market conditions expected"
        case .avoid: return "Review volatile exposure through your own plan"
        }
    }
}

// MARK: - Watchlist Highlight

struct WatchlistHighlight: Identifiable {
    let id = UUID()
    let stock: Stock
    let reason: HighlightReason
    let priceChange: Double
    let percentChange: Double

    var formattedChange: String {
        let sign = percentChange >= 0 ? "+" : ""
        return String(format: "%@%.2f%%", sign, percentChange)
    }

    var changeColor: Color {
        percentChange >= 0 ? CosmicTheme.positive : CosmicTheme.negative
    }
}

// MARK: - Highlight Reason

enum HighlightReason: String, CaseIterable {
    case biggestMover = "Biggest Mover"
    case earningsToday = "Earnings Today"
    case earningsThisWeek = "Earnings This Week"
    case breakingNews = "Breaking News"
    case cosmicAlignment = "Cosmic Alignment"
    case volumeSpike = "Volume Spike"
    case priceAlert = "Price Alert"

    var sfSymbol: String {
        switch self {
        case .biggestMover: return "chart.line.uptrend.xyaxis"
        case .earningsToday: return "calendar.badge.clock"
        case .earningsThisWeek: return "calendar"
        case .breakingNews: return "newspaper"
        case .cosmicAlignment: return "star.fill"
        case .volumeSpike: return "chart.bar.fill"
        case .priceAlert: return "bell.fill"
        }
    }

    var color: Color {
        switch self {
        case .biggestMover: return CosmicTheme.gold
        case .earningsToday: return .orange
        case .earningsThisWeek: return CosmicTheme.nebulaBlue
        case .breakingNews: return CosmicTheme.negative
        case .cosmicAlignment: return CosmicTheme.accentBlue
        case .volumeSpike: return CosmicTheme.positive
        case .priceAlert: return CosmicTheme.gold
        }
    }
}

// MARK: - Posture Note

enum SuggestedAction: String, CaseIterable {
    case watch = "Watch"
    case review = "Review"
    case rest = "Rest"
    case journal = "Journal"
    case rebalance = "Rebalance"

    var sfSymbol: String {
        switch self {
        case .watch: return "eye"
        case .review: return "list.clipboard"
        case .rest: return "leaf"
        case .journal: return "square.and.pencil"
        case .rebalance: return "scale.3d"
        }
    }

    var color: Color {
        switch self {
        case .watch: return CosmicTheme.nebulaBlue
        case .review: return CosmicTheme.gold
        case .rest: return CosmicTheme.positive
        case .journal: return CosmicTheme.accentBlue
        case .rebalance: return .orange
        }
    }

    var title: String {
        switch self {
        case .watch: return "Watch & Wait"
        case .review: return "Review Portfolio"
        case .rest: return "Rest Day"
        case .journal: return "Journal Insights"
        case .rebalance: return "Review Allocation"
        }
    }

    var description: String {
        switch self {
        case .watch:
            return "Observe market movements without acting. Let patterns emerge."
        case .review:
            return "Examine your positions. Assess alignment with your goals."
        case .rest:
            return "Step back from the markets. Your mind needs recovery."
        case .journal:
            return "Document your observations and emotional state today."
        case .rebalance:
            return "Look at your allocation against your own targets. The reading is context only."
        }
    }
}

// MARK: - News Alert

struct NewsAlert: Identifiable {
    let id = UUID()
    let symbol: String
    let headline: String
    let source: String
    let timestamp: Date
    let severity: Severity
    let cosmicContext: String?

    var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: timestamp, relativeTo: Date())
    }
}

// MARK: - Severity

enum Severity: String, CaseIterable {
    case info = "Info"
    case warning = "Warning"
    case critical = "Critical"

    var sfSymbol: String {
        switch self {
        case .info: return "info.circle"
        case .warning: return "exclamationmark.triangle"
        case .critical: return "exclamationmark.octagon.fill"
        }
    }

    var color: Color {
        switch self {
        case .info: return CosmicTheme.textSecondary
        case .warning: return .orange
        case .critical: return CosmicTheme.negative
        }
    }
}

// MARK: - Streak Info

struct StreakInfo {
    let currentStreak: Int
    let longestStreak: Int
    let lastCheckIn: Date?
    let milestone: Milestone?

    var streakMessage: String {
        if currentStreak == 0 {
            return "Start your streak today"
        } else if currentStreak == 1 {
            return "1 day streak"
        } else {
            return "\(currentStreak) day streak"
        }
    }

    var isActive: Bool {
        guard let lastCheckIn = lastCheckIn else { return false }
        return Calendar.current.isDateInToday(lastCheckIn) ||
               Calendar.current.isDateInYesterday(lastCheckIn)
    }
}

// MARK: - Milestone

enum Milestone: String, CaseIterable {
    case firstWeek = "First Week"
    case twoWeeks = "Two Weeks"
    case oneMonth = "One Month"
    case threeMonths = "Three Months"

    var sfSymbol: String {
        switch self {
        case .firstWeek: return "star"
        case .twoWeeks: return "star.fill"
        case .oneMonth: return "trophy"
        case .threeMonths: return "trophy.fill"
        }
    }

    var color: Color {
        switch self {
        case .firstWeek: return CosmicTheme.gold
        case .twoWeeks: return CosmicTheme.gold
        case .oneMonth: return CosmicTheme.accentBlue
        case .threeMonths: return CosmicTheme.gold
        }
    }

    var requiredDays: Int {
        switch self {
        case .firstWeek: return 7
        case .twoWeeks: return 14
        case .oneMonth: return 30
        case .threeMonths: return 90
        }
    }

    var congratsMessage: String {
        switch self {
        case .firstWeek: return "One week of cosmic awareness"
        case .twoWeeks: return "Two weeks of mindful trading"
        case .oneMonth: return "A full lunar cycle of discipline"
        case .threeMonths: return "Master of cosmic patience"
        }
    }
}

// MARK: - Service

final class DailyBriefService {

    // MARK: - Singleton

    static let shared = DailyBriefService()

    private init() {}

    // MARK: - Storage Keys

    private let currentStreakKey = "dailyBrief_currentStreak"
    private let longestStreakKey = "dailyBrief_longestStreak"
    private let lastCheckInKey = "dailyBrief_lastCheckIn"

    // MARK: - Generate Brief

    /// Generates a daily brief for the user
    /// - Parameters:
    ///   - user: The user profile to generate the brief for
    ///   - framingLevel: Optional framing level override. If nil, uses user's preference.
    /// - Returns: A personalized DailyBrief
    func generateBrief(for user: UserProfile, framingLevel: SignalFramingLevel? = nil) -> DailyBrief {
        let conditions = calculateCosmicConditions()
        let highlights = generateWatchlistHighlights(for: user)
        let action = determineSuggestedAction(conditions: conditions, user: user)
        let alerts = generateNewsAlerts(for: user, framingLevel: framingLevel ?? user.signalFramingLevel)
        let streak = calculateStreak()
        let level = framingLevel ?? user.signalFramingLevel
        let headline = generateHeadline(for: conditions, framingLevel: level)

        return DailyBrief(
            date: Date(),
            cosmicHeadline: headline,
            cosmicConditions: conditions,
            watchlistHighlights: highlights,
            suggestedAction: action,
            newsAlerts: alerts,
            streak: streak,
            framingLevel: level
        )
    }

    // MARK: - Cosmic Conditions

    private func calculateCosmicConditions() -> CosmicConditions {
        let moonPhase = MoonPhase.from(date: Date())
        let mercuryStatus = determineMercuryStatus()
        let dominantElement = determineDominantElement()
        let energy = calculateEnergyLevel(moon: moonPhase, mercury: mercuryStatus)
        let volatility = calculateVolatilityTolerance(moon: moonPhase, mercury: mercuryStatus)

        return CosmicConditions(
            overallEnergy: energy,
            moonPhase: moonPhase,
            mercuryStatus: mercuryStatus,
            dominantElement: dominantElement,
            volatilityTolerance: volatility
        )
    }

    private func determineMercuryStatus() -> MercuryStatus {
        let service = MercuryRetrogradeService.shared
        switch service.status {
        case .active, .stormBeginning, .stormEnding:
            return .retrograde
        case .preShadow:
            return .preShadow
        case .clear:
            return .direct
        }
    }

    private func determineDominantElement() -> ZodiacSign.Element {
        // Based on current moon sign
        let moonSign = MoonPhaseService.shared.currentLunarData?.moonSign ?? .aries
        return moonSign.element
    }

    private func calculateEnergyLevel(moon: MoonPhase, mercury: MercuryStatus) -> CosmicEnergyLevel {
        // Full moon + direct mercury = high energy
        if moon == .fullMoon && mercury == .direct {
            return .high
        }

        // Mercury retrograde = cautious regardless of moon
        if mercury == .retrograde {
            return .cautious
        }

        // Waning phases = lower energy
        if !moon.isWaxing {
            return .low
        }

        // Waxing phases = moderate to high
        if moon == .waxingGibbous || moon == .firstQuarter {
            return .moderate
        }

        return .moderate
    }

    private func calculateVolatilityTolerance(moon: MoonPhase, mercury: MercuryStatus) -> VolatilityTolerance {
        // Full moon often brings volatility
        if moon == .fullMoon {
            return .embrace
        }

        // Mercury retrograde - avoid volatility
        if mercury == .retrograde {
            return .avoid
        }

        // New moon - neutral
        if moon == .newMoon {
            return .neutral
        }

        return .neutral
    }

    // MARK: - Watchlist Highlights

    private func generateWatchlistHighlights(for user: UserProfile) -> [WatchlistHighlight] {
        // Combine portfolio and watchlist stocks
        var allStocks: [Stock] = user.portfolio

        // Add watchlist stocks from MockStockData
        for symbol in user.watchlist {
            if let stock = MockStockData.all.first(where: { $0.symbol == symbol }) {
                if !allStocks.contains(where: { $0.symbol == symbol }) {
                    allStocks.append(stock)
                }
            }
        }

        // Sort by absolute percentage change
        let sorted = allStocks.sorted { abs($0.percentageChange) > abs($1.percentageChange) }

        // Take top 3 movers
        return sorted.prefix(3).map { stock in
            let reason: HighlightReason
            if abs(stock.percentageChange) > 5 {
                reason = .biggestMover
            } else if stock.zodiacSign == user.sunSign {
                reason = .cosmicAlignment
            } else {
                reason = .priceAlert
            }

            return WatchlistHighlight(
                stock: stock,
                reason: reason,
                priceChange: stock.priceChange,
                percentChange: stock.percentageChange
            )
        }
    }

    // MARK: - Posture Note

    private func determineSuggestedAction(conditions: CosmicConditions, user: UserProfile) -> SuggestedAction {
        // Mercury retrograde = review
        if conditions.mercuryStatus == .retrograde {
            return .review
        }

        // Low energy = rest
        if conditions.overallEnergy == .low {
            return .rest
        }

        // Cautious = journal
        if conditions.overallEnergy == .cautious {
            return .journal
        }

        // Full moon with high energy = rebalance opportunity
        if conditions.moonPhase == .fullMoon && conditions.overallEnergy == .high {
            return .rebalance
        }

        // Default to watch
        return .watch
    }

    // MARK: - News Alerts

    private func generateNewsAlerts(for user: UserProfile, framingLevel: SignalFramingLevel) -> [NewsAlert] {
        // Generate alerts for significant movers (>5% change)
        var alerts: [NewsAlert] = []

        for stock in user.portfolio where abs(stock.percentageChange) > 5 {
            let isPositive = stock.percentageChange > 0
            let severity: Severity = abs(stock.percentageChange) > 10 ? .critical : .warning

            let headline = isPositive
                ? "\(stock.symbol) surges \(String(format: "%.1f", stock.percentageChange))%"
                : "\(stock.symbol) drops \(String(format: "%.1f", abs(stock.percentageChange)))%"

            // Use SignalFramingService to frame the cosmic context
            let cosmicContext = SignalFramingService.shared.frameNewsContext(
                symbol: stock.symbol,
                change: stock.percentageChange,
                stockSign: stock.zodiacSign,
                level: framingLevel
            )

            alerts.append(NewsAlert(
                symbol: stock.symbol,
                headline: headline,
                source: "Cosmic Tracker",
                timestamp: Date(),
                severity: severity,
                cosmicContext: cosmicContext
            ))
        }

        return alerts
    }

    // MARK: - Streak Management

    func calculateStreak() -> StreakInfo {
        let currentStreak = UserDefaults.standard.integer(forKey: currentStreakKey)
        let longestStreak = UserDefaults.standard.integer(forKey: longestStreakKey)
        let lastCheckIn = UserDefaults.standard.object(forKey: lastCheckInKey) as? Date

        let milestone = Milestone.allCases.last { currentStreak >= $0.requiredDays }

        return StreakInfo(
            currentStreak: currentStreak,
            longestStreak: longestStreak,
            lastCheckIn: lastCheckIn,
            milestone: milestone
        )
    }

    func recordCheckIn() {
        let calendar = Calendar.current
        let today = Date()
        let lastCheckIn = UserDefaults.standard.object(forKey: lastCheckInKey) as? Date

        var currentStreak = UserDefaults.standard.integer(forKey: currentStreakKey)
        var longestStreak = UserDefaults.standard.integer(forKey: longestStreakKey)

        if let lastDate = lastCheckIn {
            if calendar.isDateInToday(lastDate) {
                // Already checked in today
                return
            } else if calendar.isDateInYesterday(lastDate) {
                // Consecutive day
                currentStreak += 1
            } else {
                // Streak broken
                currentStreak = 1
            }
        } else {
            // First check-in
            currentStreak = 1
        }

        // Update longest streak
        if currentStreak > longestStreak {
            longestStreak = currentStreak
        }

        // Save to UserDefaults
        UserDefaults.standard.set(currentStreak, forKey: currentStreakKey)
        UserDefaults.standard.set(longestStreak, forKey: longestStreakKey)
        UserDefaults.standard.set(today, forKey: lastCheckInKey)
    }

    // MARK: - Headlines

    private func generateHeadline(for conditions: CosmicConditions, framingLevel: SignalFramingLevel) -> String {
        // Use SignalFramingService to get appropriately framed headlines
        let headlines = SignalFramingService.shared.getHeadlines(
            for: conditions.overallEnergy,
            level: framingLevel
        )
        return headlines.randomElement() ?? generateFallbackHeadline(for: conditions, framingLevel: framingLevel)
    }

    /// Fallback headline if service returns empty
    private func generateFallbackHeadline(for conditions: CosmicConditions, framingLevel: SignalFramingLevel) -> String {
        switch framingLevel {
        case .rational, .leanRational:
            // Data-focused fallbacks
            switch conditions.overallEnergy {
            case .high: return "Market conditions read as active."
            case .moderate: return "Balanced market conditions today."
            case .low: return "Low activity expected. Nothing in the reading asks for a move."
            case .cautious: return "Mixed readings suggest extra context."
            }
        case .mystical, .leanMystical:
            // Cosmic-focused fallbacks
            switch conditions.overallEnergy {
            case .high: return "Cosmic momentum reads as active; context only."
            case .moderate: return "Balanced conditions favor measured positioning."
            case .low: return "Low-conviction conditions favor patience."
            case .cautious: return "Mixed cosmic readings call for review."
            }
        case .balanced:
            // Blend of both
            switch conditions.overallEnergy {
            case .high: return "Energy peaks. Markets may see increased activity."
            case .moderate: return "Steady conditions. A measured posture fits the read."
            case .low: return "Low energy day. A quiet read for review."
            case .cautious: return "Uncertain conditions. Treat the reading as context."
            }
        }
    }
}
