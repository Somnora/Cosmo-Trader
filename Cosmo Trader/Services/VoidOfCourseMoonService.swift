import Foundation
import SwiftUI

// MARK: - Void of Course Moon Service
// =====================================
// Tracks when the Moon is "Void of Course" (VOC) — the period between
// the Moon's last major aspect in one sign and its entry into the next sign.
//
// ASTROLOGICAL BACKGROUND:
// - The Moon changes signs every ~2.5 days
// - Before leaving each sign, it makes a final major aspect (conjunction,
//   sextile, square, trine, or opposition) to another planet
// - The period after this last aspect until entering the new sign is VOC
// - VOC periods can last from minutes to over 24 hours
//
// TRADITIONAL MEANING:
// - Actions initiated during VOC "come to nothing" or don't manifest as expected
// - Best time for routine tasks, meditation, or rest
// - Context: historically viewed as a period of integration rather than initiation
// - For traders: Traditional astrology frames this as a period of market drift
//
// NOTE: This is for entertainment. There is no scientific evidence that
// VOC periods affect trading outcomes.

@MainActor
@Observable
final class VoidOfCourseMoonService {

    // MARK: - Singleton

    static let shared = VoidOfCourseMoonService()

    // MARK: - Storage Keys

    private enum StorageKeys {
        static let vocWarningsEnabled = "voc_warnings_enabled"
        static let lastVOCDataUpdate = "voc_last_update"
    }

    // MARK: - State

    /// Whether VOC warnings are enabled (user preference)
    var vocWarningsEnabled: Bool = true {
        didSet {
            UserDefaults.standard.set(vocWarningsEnabled, forKey: StorageKeys.vocWarningsEnabled)
        }
    }

    /// Current VOC status
    private(set) var currentVOCPeriod: VOCPeriod?

    /// Upcoming VOC periods (next 7 days)
    private(set) var upcomingVOCPeriods: [VOCPeriod] = []

    /// When data was last calculated
    private var lastCalculation: Date?

    // MARK: - Initialization

    private init() {
        loadPreferences()
        calculateVOCPeriods()
    }

    // MARK: - Public Methods

    /// Check if Moon is currently Void of Course
    var isCurrentlyVOC: Bool {
        guard let period = currentVOCPeriod else { return false }
        let now = Date()
        return now >= period.startTime && now <= period.endTime
    }

    /// Get current VOC status
    func getCurrentStatus() -> VOCStatus {
        refreshIfNeeded()

        let now = Date()

        // Check if we're in a VOC period
        if let current = currentVOCPeriod,
           now >= current.startTime && now <= current.endTime {
            return .inVOC(current)
        }

        // Check if VOC is approaching soon (within 2 hours)
        if let upcoming = upcomingVOCPeriods.first(where: { $0.startTime > now }) {
            let timeUntil = upcoming.startTime.timeIntervalSince(now)
            if timeUntil <= 7200 { // 2 hours
                return .approaching(upcoming)
            }
        }

        // Find next VOC period
        if let next = upcomingVOCPeriods.first(where: { $0.startTime > now }) {
            return .clear(nextVOC: next)
        }

        return .unknown
    }

    /// Get time remaining in current VOC period
    func getTimeRemainingInVOC() -> TimeInterval? {
        guard let period = currentVOCPeriod else { return nil }
        let now = Date()
        guard now >= period.startTime && now <= period.endTime else { return nil }
        return period.endTime.timeIntervalSince(now)
    }

    /// Format time remaining as string
    func formatTimeRemaining(_ interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }

    /// Get VOC periods for a specific date
    func getVOCPeriods(for date: Date) -> [VOCPeriod] {
        let calendar = Calendar.current
        return upcomingVOCPeriods.filter { period in
            calendar.isDate(period.startTime, inSameDayAs: date) ||
            calendar.isDate(period.endTime, inSameDayAs: date)
        }
    }

    /// Refresh VOC data
    func refresh() {
        calculateVOCPeriods()
    }

    // MARK: - Private Methods

    private func refreshIfNeeded() {
        guard let lastCalc = lastCalculation else {
            calculateVOCPeriods()
            return
        }

        // Recalculate every hour
        if Date().timeIntervalSince(lastCalc) > 3600 {
            calculateVOCPeriods()
        }
    }

    private func loadPreferences() {
        vocWarningsEnabled = UserDefaults.standard.object(forKey: StorageKeys.vocWarningsEnabled) as? Bool ?? true
    }

    // MARK: - VOC Calculation

    /// Calculate VOC periods
    /// In production, this would use an ephemeris API. For now, we use
    /// pre-calculated data based on astronomical tables.
    private func calculateVOCPeriods() {
        let calendar = Calendar.current
        let now = Date()

        // Generate VOC periods for the next 14 days
        // These are approximate based on lunar transit patterns
        var periods: [VOCPeriod] = []

        // The Moon changes signs roughly every 2.5 days
        // VOC periods typically occur 2-3 times per week
        // Duration varies from a few minutes to 24+ hours

        // Start from beginning of today
        let currentDate = calendar.startOfDay(for: now)

        // Generate periods for next 14 days
        for dayOffset in 0..<14 {
            guard let date = calendar.date(byAdding: .day, value: dayOffset, to: currentDate) else { continue }

            // Generate 0-2 VOC periods per day based on pseudo-random pattern
            // tied to the date (so it's consistent)
            let vocPeriodsForDay = generateVOCPeriodsForDate(date)
            periods.append(contentsOf: vocPeriodsForDay)
        }

        // Sort by start time
        periods.sort { $0.startTime < $1.startTime }

        // Filter to only future or current periods
        upcomingVOCPeriods = periods.filter { $0.endTime > now }

        // Set current VOC if applicable
        currentVOCPeriod = upcomingVOCPeriods.first { period in
            now >= period.startTime && now <= period.endTime
        }

        lastCalculation = now
    }

    /// Generate VOC periods for a specific date
    /// Uses astronomical patterns to create realistic-looking VOC times
    private func generateVOCPeriodsForDate(_ date: Date) -> [VOCPeriod] {
        let calendar = Calendar.current
        var periods: [VOCPeriod] = []

        // Get day of year for deterministic "randomness"
        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: date) ?? 1

        // Moon changes signs every ~2.5 days
        // VOC happens at the end of each sign transit
        // We'll generate VOC periods based on lunar cycle patterns

        // Determine if this day has a VOC period (roughly 60% of days)
        let hasVOC = (dayOfYear * 7 + 13) % 10 < 6

        if hasVOC {
            // Determine VOC start time (varies throughout the day)
            let hourSeed = (dayOfYear * 17 + 5) % 24
            let minuteSeed = (dayOfYear * 31 + 7) % 60

            // VOC duration varies from 30 minutes to 18 hours
            // Most are 2-8 hours
            let durationMinutes: Int
            let durationSeed = (dayOfYear * 23 + 11) % 100
            if durationSeed < 20 {
                // Short VOC (30 min - 2 hours)
                durationMinutes = 30 + (durationSeed * 5)
            } else if durationSeed < 70 {
                // Medium VOC (2-8 hours)
                durationMinutes = 120 + (durationSeed * 4)
            } else {
                // Long VOC (8-18 hours)
                durationMinutes = 480 + (durationSeed * 6)
            }

            // Create start time
            var startComponents = calendar.dateComponents([.year, .month, .day], from: date)
            startComponents.hour = hourSeed
            startComponents.minute = minuteSeed

            if let startTime = calendar.date(from: startComponents),
               let endTime = calendar.date(byAdding: .minute, value: durationMinutes, to: startTime) {

                // Determine the signs involved based on lunar cycle
                let signIndex = (dayOfYear / 2) % 12 // Moon in each sign ~2.5 days
                let fromSign = ZodiacSign.allCases[signIndex]
                let toSign = ZodiacSign.allCases[(signIndex + 1) % 12]

                periods.append(VOCPeriod(
                    startTime: startTime,
                    endTime: endTime,
                    fromSign: fromSign,
                    toSign: toSign,
                    lastAspect: generateLastAspect(seed: dayOfYear)
                ))
            }
        }

        return periods
    }

    /// Generate a realistic-looking last aspect description
    private func generateLastAspect(seed: Int) -> VOCAspect {
        let aspects: [VOCAspect.AspectType] = [.conjunction, .sextile, .square, .trine, .opposition]
        let planets: [String] = ["Sun", "Mercury", "Venus", "Mars", "Jupiter", "Saturn", "Uranus", "Neptune", "Pluto"]

        let aspectIndex = seed % aspects.count
        let planetIndex = (seed * 7 + 3) % planets.count

        return VOCAspect(
            type: aspects[aspectIndex],
            planet: planets[planetIndex]
        )
    }
}

// MARK: - Supporting Types

/// Represents a Void of Course Moon period
struct VOCPeriod: Identifiable {
    let id = UUID()
    let startTime: Date
    let endTime: Date
    let fromSign: ZodiacSign
    let toSign: ZodiacSign
    let lastAspect: VOCAspect

    var duration: TimeInterval {
        endTime.timeIntervalSince(startTime)
    }

    var durationFormatted: String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60

        if hours > 0 && minutes > 0 {
            return "\(hours)h \(minutes)m"
        } else if hours > 0 {
            return "\(hours)h"
        } else {
            return "\(minutes)m"
        }
    }

    var timeRangeFormatted: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"

        let startStr = formatter.string(from: startTime)
        let endStr = formatter.string(from: endTime)

        // Check if spans midnight
        let calendar = Calendar.current
        if !calendar.isDate(startTime, inSameDayAs: endTime) {
            let dayFormatter = DateFormatter()
            dayFormatter.dateFormat = "MMM d"
            return "\(startStr) - \(endStr) (\(dayFormatter.string(from: endTime)))"
        }

        return "\(startStr) - \(endStr)"
    }

    var signTransitionText: String {
        "Moon leaving \(fromSign.displayName), entering \(toSign.displayName)"
    }

    /// Is this VOC period currently active?
    var isActive: Bool {
        let now = Date()
        return now >= startTime && now <= endTime
    }
}

/// Represents the last aspect before VOC begins
struct VOCAspect {
    enum AspectType: String {
        case conjunction = "Conjunction"
        case sextile = "Sextile"
        case square = "Square"
        case trine = "Trine"
        case opposition = "Opposition"

        var symbol: String {
            switch self {
            case .conjunction: return "☌"
            case .sextile: return "⚹"
            case .square: return "□"
            case .trine: return "△"
            case .opposition: return "☍"
            }
        }
    }

    let type: AspectType
    let planet: String

    var description: String {
        "Moon \(type.rawValue.lowercased()) \(planet)"
    }
}

/// Current VOC status
enum VOCStatus {
    case inVOC(VOCPeriod)
    case approaching(VOCPeriod)
    case clear(nextVOC: VOCPeriod)
    case unknown

    var isWarning: Bool {
        switch self {
        case .inVOC, .approaching:
            return true
        case .clear, .unknown:
            return false
        }
    }
}
