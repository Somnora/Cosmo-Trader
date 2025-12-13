import Foundation
import SwiftUI

// MARK: - Daily Ritual Service
// ============================
// Manages the 30-second morning ritual experience.
//
// FEATURE: The Daily Ritual
// A morning routine before market open:
// 1. Moon phase + today's cosmic weather (5 sec)
// 2. Portfolio overnight change (5 sec)
// 3. One-line horoscope (5 sec)
// 4. "Intention for today" — user picks: Hold / Buy / Sell / Observe
//
// Tracks streak: "14-day ritual streak"
//
// WHY IT WORKS: Daily habit formation. Engagement metric gold.

@MainActor
@Observable
final class DailyRitualService {

    // MARK: - Singleton

    static let shared = DailyRitualService()

    // MARK: - Storage Keys

    private enum StorageKeys {
        static let lastRitualDate = "dailyRitual_lastDate"
        static let currentStreak = "dailyRitual_streak"
        static let longestStreak = "dailyRitual_longestStreak"
        static let totalRituals = "dailyRitual_totalCount"
        static let intentionHistory = "dailyRitual_intentions"
    }

    // MARK: - State

    /// The date of the last completed ritual
    private(set) var lastRitualDate: Date?

    /// Current streak count
    private(set) var currentStreak: Int = 0

    /// Longest streak ever
    private(set) var longestStreak: Int = 0

    /// Total rituals completed
    private(set) var totalRituals: Int = 0

    /// Today's intention (if set)
    private(set) var todaysIntention: DailyIntention?

    /// History of intentions (last 30 days)
    private(set) var intentionHistory: [IntentionRecord] = []

    // MARK: - Computed Properties

    /// Has the user completed today's ritual?
    var hasCompletedTodaysRitual: Bool {
        guard let lastDate = lastRitualDate else { return false }
        return Calendar.current.isDateInToday(lastDate)
    }

    /// Is it a good time for the ritual? (Morning, before market open)
    var isRitualTime: Bool {
        let hour = Calendar.current.component(.hour, from: Date())
        // Good time: 5 AM - 9:30 AM (before market open)
        return hour >= 5 && hour < 10
    }

    /// Time until market open (for display)
    var timeUntilMarketOpen: String? {
        let calendar = Calendar.current
        let now = Date()
        let hour = calendar.component(.hour, from: now)

        // Market opens at 9:30 AM ET
        if hour < 9 || (hour == 9 && calendar.component(.minute, from: now) < 30) {
            var marketOpen = calendar.dateComponents([.year, .month, .day], from: now)
            marketOpen.hour = 9
            marketOpen.minute = 30

            if let openTime = calendar.date(from: marketOpen) {
                let interval = openTime.timeIntervalSince(now)
                if interval > 0 {
                    let hours = Int(interval) / 3600
                    let minutes = (Int(interval) % 3600) / 60
                    if hours > 0 {
                        return "\(hours)h \(minutes)m until market open"
                    } else {
                        return "\(minutes)m until market open"
                    }
                }
            }
        }

        return nil
    }

    /// Streak message for display
    var streakMessage: String {
        if currentStreak == 0 {
            return "Start your streak today"
        } else if currentStreak == 1 {
            return "1-day streak! Keep it going"
        } else if currentStreak < 7 {
            return "\(currentStreak)-day streak"
        } else if currentStreak < 14 {
            return "\(currentStreak)-day streak! Cosmic discipline"
        } else if currentStreak < 30 {
            return "\(currentStreak)-day streak! You're aligned"
        } else {
            return "\(currentStreak)-day streak! Cosmic master"
        }
    }

    /// Intention distribution (for stats)
    var intentionDistribution: [DailyIntention: Int] {
        var distribution: [DailyIntention: Int] = [:]
        for record in intentionHistory {
            distribution[record.intention, default: 0] += 1
        }
        return distribution
    }

    /// Most common intention
    var dominantIntention: DailyIntention? {
        intentionDistribution.max(by: { $0.value < $1.value })?.key
    }

    // MARK: - Initialization

    private init() {
        loadState()
        checkStreakContinuity()
    }

    // MARK: - Public Methods

    /// Complete today's ritual with an intention
    func completeRitual(intention: DailyIntention) {
        let today = Date()

        // Update streak
        if let lastDate = lastRitualDate {
            let calendar = Calendar.current
            if calendar.isDateInYesterday(lastDate) {
                // Continuing streak
                currentStreak += 1
            } else if !calendar.isDateInToday(lastDate) {
                // Streak broken, start over
                currentStreak = 1
            }
            // If already completed today, don't increment
        } else {
            // First ritual ever
            currentStreak = 1
        }

        // Update longest streak
        if currentStreak > longestStreak {
            longestStreak = currentStreak
        }

        // Update totals
        totalRituals += 1
        lastRitualDate = today
        todaysIntention = intention

        // Record intention
        let record = IntentionRecord(
            date: today,
            intention: intention
        )
        intentionHistory.append(record)

        // Keep only last 30 days
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: today) ?? today
        intentionHistory = intentionHistory.filter { $0.date >= thirtyDaysAgo }

        // Save state
        saveState()

        // Track analytics
        AnalyticsService.shared.track(.dailyRitualCompleted)
    }

    /// Reset today's intention (allow redo)
    func resetTodaysIntention() {
        todaysIntention = nil
        // Remove today's record from history
        intentionHistory.removeAll { Calendar.current.isDateInToday($0.date) }
        saveState()
    }

    /// Get intention for a specific date
    func intention(for date: Date) -> DailyIntention? {
        intentionHistory.first { Calendar.current.isDate($0.date, inSameDayAs: date) }?.intention
    }

    // MARK: - Ritual Content Generation

    /// Generate cosmic weather summary for today
    func getCosmicWeather() -> RitualCosmicWeather {
        let moonData = MoonPhaseService.shared.getCurrentLunarData()
        let astroService = AstroAlertService.shared
        let moodService = CosmicMoodService.shared

        var alerts: [String] = []

        if astroService.isMercuryRetrograde {
            alerts.append("Mercury Retrograde active")
        }

        if VoidOfCourseMoonService.shared.isCurrentlyVOC {
            alerts.append("Moon is Void of Course")
        }

        let activeEvents = astroService.activeAlertEvents
        for event in activeEvents.prefix(2) {
            alerts.append(event.subtitle)
        }

        let moodData = moodService.getCurrentMood()
        return RitualCosmicWeather(
            moonPhase: moonData.phase,
            moonSign: moonData.moonSign,
            cosmicMood: moodData,
            alerts: alerts,
            overallEnergy: determineOverallEnergy(mood: moodData, alerts: alerts)
        )
    }

    /// Generate one-line horoscope for today
    func getDailyHoroscope(for sign: ZodiacSign) -> String {
        let calendar = Calendar.current
        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: Date()) ?? 1

        // Deterministic but varied based on date and sign
        let horoscopes = sign.dailyHoroscopes
        let index = (dayOfYear + sign.hashValue) % horoscopes.count

        return horoscopes[index]
    }

    /// Get portfolio overnight summary
    func getOvernightSummary(holdings: [Stock]) -> OvernightSummary {
        guard !holdings.isEmpty else {
            return OvernightSummary(
                totalChange: 0,
                percentChange: 0,
                topMover: nil,
                topMoverChange: 0,
                sentiment: .neutral
            )
        }

        let totalValue = holdings.reduce(0) { $0 + $1.totalValue }
        let totalChange = holdings.reduce(0) { $0 + ($1.priceChange * $1.sharesOwned) }
        let percentChange = totalValue > 0 ? (totalChange / (totalValue - totalChange)) * 100 : 0

        // Find top mover
        let topMover = holdings.max(by: { abs($0.percentageChange) < abs($1.percentageChange) })

        let sentiment: MarketSentiment
        if percentChange > 1 {
            sentiment = .bullish
        } else if percentChange < -1 {
            sentiment = .bearish
        } else {
            sentiment = .neutral
        }

        return OvernightSummary(
            totalChange: totalChange,
            percentChange: percentChange,
            topMover: topMover,
            topMoverChange: topMover?.percentageChange ?? 0,
            sentiment: sentiment
        )
    }

    // MARK: - Private Methods

    private func determineOverallEnergy(mood: CosmicMoodData?, alerts: [String]) -> EnergyLevel {
        let alertCount = alerts.count
        let moodScore = mood?.value ?? 50

        if alertCount >= 2 || moodScore < 30 {
            return .challenging
        } else if alertCount == 1 || moodScore < 50 {
            return .cautious
        } else if moodScore > 70 {
            return .favorable
        } else {
            return .neutral
        }
    }

    private func checkStreakContinuity() {
        guard let lastDate = lastRitualDate else { return }

        let calendar = Calendar.current

        // If last ritual was not today or yesterday, streak is broken
        if !calendar.isDateInToday(lastDate) && !calendar.isDateInYesterday(lastDate) {
            currentStreak = 0
            saveState()
        }
    }

    // MARK: - Persistence

    private func saveState() {
        let defaults = UserDefaults.standard

        if let lastDate = lastRitualDate {
            defaults.set(lastDate, forKey: StorageKeys.lastRitualDate)
        }
        defaults.set(currentStreak, forKey: StorageKeys.currentStreak)
        defaults.set(longestStreak, forKey: StorageKeys.longestStreak)
        defaults.set(totalRituals, forKey: StorageKeys.totalRituals)

        // Encode intention history
        if let data = try? JSONEncoder().encode(intentionHistory) {
            defaults.set(data, forKey: StorageKeys.intentionHistory)
        }
    }

    private func loadState() {
        let defaults = UserDefaults.standard

        lastRitualDate = defaults.object(forKey: StorageKeys.lastRitualDate) as? Date
        currentStreak = defaults.integer(forKey: StorageKeys.currentStreak)
        longestStreak = defaults.integer(forKey: StorageKeys.longestStreak)
        totalRituals = defaults.integer(forKey: StorageKeys.totalRituals)

        // Decode intention history
        if let data = defaults.data(forKey: StorageKeys.intentionHistory),
           let decoded = try? JSONDecoder().decode([IntentionRecord].self, from: data) {
            intentionHistory = decoded
        }

        // Set today's intention if already completed
        if hasCompletedTodaysRitual {
            todaysIntention = intentionHistory.first { Calendar.current.isDateInToday($0.date) }?.intention
        }
    }
}

// MARK: - Supporting Types

/// Daily intention options
enum DailyIntention: String, CaseIterable, Codable {
    case hold = "Hold"
    case buy = "Buy"
    case sell = "Sell"
    case observe = "Observe"

    var icon: String {
        switch self {
        case .hold: return "hand.raised.fill"
        case .buy: return "arrow.down.circle.fill"
        case .sell: return "arrow.up.circle.fill"
        case .observe: return "eye.fill"
        }
    }

    var color: Color {
        switch self {
        case .hold: return .blue
        case .buy: return .green
        case .sell: return .orange
        case .observe: return .purple
        }
    }

    var description: String {
        switch self {
        case .hold: return "Maintain current positions"
        case .buy: return "Look for opportunities to add"
        case .sell: return "Consider taking profits"
        case .observe: return "Watch and learn today"
        }
    }

    var affirmation: String {
        switch self {
        case .hold: return "Patience is a cosmic virtue. Your positions need time to align."
        case .buy: return "The stars favor acquisition. Trust your research."
        case .sell: return "Knowing when to release is wisdom. Take what the market offers."
        case .observe: return "Not every day requires action. Wisdom comes from watching."
        }
    }
}

/// Record of a daily intention
struct IntentionRecord: Codable, Identifiable {
    var id: Date { date }
    let date: Date
    let intention: DailyIntention
}

/// Cosmic weather summary for Daily Ritual
struct RitualCosmicWeather {
    let moonPhase: MoonPhase
    let moonSign: ZodiacSign
    let cosmicMood: CosmicMoodData?
    let alerts: [String]
    let overallEnergy: EnergyLevel
}

/// Energy level for the day
enum EnergyLevel {
    case favorable
    case neutral
    case cautious
    case challenging

    var displayName: String {
        switch self {
        case .favorable: return "Favorable"
        case .neutral: return "Neutral"
        case .cautious: return "Cautious"
        case .challenging: return "Challenging"
        }
    }

    var color: Color {
        switch self {
        case .favorable: return .green
        case .neutral: return .blue
        case .cautious: return .orange
        case .challenging: return .red
        }
    }

    var icon: String {
        switch self {
        case .favorable: return "sun.max.fill"
        case .neutral: return "cloud.sun.fill"
        case .cautious: return "cloud.fill"
        case .challenging: return "cloud.bolt.fill"
        }
    }
}

/// Overnight portfolio summary
struct OvernightSummary {
    let totalChange: Double
    let percentChange: Double
    let topMover: Stock?
    let topMoverChange: Double
    let sentiment: MarketSentiment

    var formattedChange: String {
        let sign = totalChange >= 0 ? "+" : ""
        return "\(sign)$\(String(format: "%.2f", totalChange))"
    }

    var formattedPercent: String {
        let sign = percentChange >= 0 ? "+" : ""
        return "\(sign)\(String(format: "%.2f", percentChange))%"
    }
}

/// Market sentiment
enum MarketSentiment {
    case bullish
    case neutral
    case bearish

    var emoji: String {
        switch self {
        case .bullish: return "📈"
        case .neutral: return "➡️"
        case .bearish: return "📉"
        }
    }

    var color: Color {
        switch self {
        case .bullish: return .green
        case .neutral: return .gray
        case .bearish: return .red
        }
    }
}

// MARK: - ZodiacSign Daily Horoscopes

extension ZodiacSign {
    /// Pool of daily horoscopes for each sign
    var dailyHoroscopes: [String] {
        switch self {
        case .aries:
            return [
                "Bold moves favor the prepared today. Trust your instincts on timing.",
                "Your competitive edge sharpens. First-mover advantage awaits.",
                "Patience challenges you today, but restraint brings rewards.",
                "Leadership energy peaks. Others follow your market conviction.",
                "Action over analysis today. Your gut knows the play."
            ]
        case .taurus:
            return [
                "Steady hands profit today. Resist the urge to overtrade.",
                "Value reveals itself to patient eyes. Quality over quantity.",
                "Your stubborn nature protects you from FOMO. Trust it.",
                "Material gains favor the methodical. Stick to your system.",
                "Comfort in stability, but don't ignore emerging opportunities."
            ]
        case .gemini:
            return [
                "Information is currency today. Your research pays dividends.",
                "Dual opportunities present themselves. You can pursue both.",
                "Communication brings unexpected market insights. Listen closely.",
                "Your adaptability is your edge today. Pivot if needed.",
                "Curiosity leads to discovery. Explore outside your usual sectors."
            ]
        case .cancer:
            return [
                "Trust your emotional read on market sentiment today.",
                "Protective instincts serve you well. Guard your gains.",
                "Home and security investments shine. Think long-term.",
                "Intuition whispers louder than charts today. Listen.",
                "Nurture your portfolio like family. Patience yields growth."
            ]
        case .leo:
            return [
                "Confidence attracts opportunity today. Take the stage.",
                "Your bold picks gain attention. Lead with conviction.",
                "Generosity with knowledge returns tenfold. Share insights.",
                "The spotlight finds your portfolio. Ensure it deserves attention.",
                "Pride in your choices is warranted, but stay humble to signals."
            ]
        case .virgo:
            return [
                "Details matter more than usual today. Read the fine print.",
                "Your analytical edge cuts through market noise perfectly.",
                "Health and practical sectors align with cosmic energy.",
                "Perfectionism helps in research, hurts in execution. Balance.",
                "Service-oriented investments gain favor. Think utility."
            ]
        case .libra:
            return [
                "Balance your portfolio like you balance life. Harmony profits.",
                "Partnerships and collaborations bring market insights today.",
                "Beauty and luxury sectors catch cosmic tailwinds.",
                "Indecision is your only enemy today. Choose and commit.",
                "Fairness in trades attracts karmic returns. Play clean."
            ]
        case .scorpio:
            return [
                "Your penetrating insight sees through market illusions today.",
                "Transformation in your strategy brings renewal. Embrace change.",
                "Secrets and hidden value reveal themselves to your gaze.",
                "Intensity serves you, but don't death-grip losing positions.",
                "Power moves favor the patient. Strike when certain."
            ]
        case .sagittarius:
            return [
                "Adventure calls in foreign markets or unfamiliar sectors.",
                "Optimism is warranted today, but ground it in research.",
                "The bigger picture crystallizes. Zoom out for perspective.",
                "Freedom to trade your way is your greatest asset.",
                "Truth in financial statements rewards your seeking nature."
            ]
        case .capricorn:
            return [
                "Discipline is your superpower today. Structure wins.",
                "Long-term vision clears. What serves your decade goal?",
                "Authority and established players favor your portfolio.",
                "Ambition meets opportunity. Climb strategically.",
                "Traditional methods outperform experiments today."
            ]
        case .aquarius:
            return [
                "Innovation and disruption sectors align with your energy.",
                "Community wisdom brings unexpected alpha. Engage others.",
                "Your unconventional approach finds validation today.",
                "Technology and future-forward plays catch cosmic winds.",
                "Detachment from emotion gives you analytical clarity."
            ]
        case .pisces:
            return [
                "Dreams and intuition guide better than algorithms today.",
                "Creative and entertainment sectors flow with your energy.",
                "Compassion in trading means knowing when to cut losses.",
                "Imagination reveals opportunities invisible to pure logic.",
                "Spiritual alignment with your portfolio brings peace."
            ]
        }
    }
}

// MARK: - Analytics Events

extension AnalyticsEvent {
    static let dailyRitualStarted = AnalyticsEvent(rawValue: "daily_ritual_started")!
    static let dailyRitualCompleted = AnalyticsEvent(rawValue: "daily_ritual_completed")!
    static let dailyRitualStepViewed = AnalyticsEvent(rawValue: "daily_ritual_step_viewed")!
}
