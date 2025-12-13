import Foundation
import SwiftUI

// MARK: - Mercury Retrograde Service
// ===================================
// Always-visible countdown for Mercury Retrograde.
//
// "Next Mercury Retrograde: 23 days"
// or
// "MERCURY RETROGRADE ACTIVE — Day 12 of 21"
//
// WHY IT WORKS: Creates urgency. Drives engagement. Cosmic FOMO.

@MainActor
@Observable
final class MercuryRetrogradeService {

    // MARK: - Singleton

    static let shared = MercuryRetrogradeService()

    // MARK: - Dependencies

    private let astroService: AstroAlertService

    // MARK: - State

    /// Current retrograde status
    private(set) var status: RetrogradeStatus = .clear

    /// Days until next retrograde (if not active)
    private(set) var daysUntilNext: Int = 0

    /// Current day of retrograde (if active)
    private(set) var currentDayOfRetrograde: Int = 0

    /// Total days of current retrograde (if active)
    private(set) var totalRetrogradeDays: Int = 0

    /// The active or next Mercury Retrograde event
    private(set) var retrogradeEvent: CosmicEvent?

    /// Countdown refresh timer
    @ObservationIgnored
    private var refreshTimer: Timer?

    // MARK: - Initialization

    private init() {
        self.astroService = AstroAlertService.shared
        refreshStatus()
        startRefreshTimer()
    }

    // MARK: - Public Methods

    /// Refresh the retrograde status
    func refreshStatus() {
        let now = Date()
        let calendar = Calendar.current

        // Check for active Mercury Retrograde
        if let activeRetrograde = astroService.activeEvents.first(where: { $0.type == .mercuryRetrograde }) {
            retrogradeEvent = activeRetrograde

            // Calculate current day of retrograde
            let daysSinceStart = calendar.dateComponents([.day], from: activeRetrograde.startDate, to: now).day ?? 0
            currentDayOfRetrograde = max(1, daysSinceStart + 1)

            // Calculate total days
            let totalDays = calendar.dateComponents([.day], from: activeRetrograde.startDate, to: activeRetrograde.endDate).day ?? 21
            totalRetrogradeDays = totalDays

            // Determine phase
            let progress = Double(currentDayOfRetrograde) / Double(totalRetrogradeDays)
            if progress < 0.2 {
                status = .stormBeginning
            } else if progress > 0.8 {
                status = .stormEnding
            } else {
                status = .active
            }

            daysUntilNext = 0
        } else {
            // Find next Mercury Retrograde
            let upcomingRetrogrades = astroService.allEvents
                .filter { $0.type == .mercuryRetrograde && $0.startDate > now }
                .sorted { $0.startDate < $1.startDate }

            if let nextRetrograde = upcomingRetrogrades.first {
                retrogradeEvent = nextRetrograde

                let daysUntil = calendar.dateComponents([.day], from: now, to: nextRetrograde.startDate).day ?? 0
                daysUntilNext = max(0, daysUntil)

                // Pre-shadow warning (typically 2 weeks before)
                if daysUntilNext <= 14 {
                    status = .preShadow
                } else {
                    status = .clear
                }

                currentDayOfRetrograde = 0
                totalRetrogradeDays = 0
            } else {
                // No retrograde data available
                status = .clear
                retrogradeEvent = nil
                daysUntilNext = 0
            }
        }
    }

    // MARK: - Computed Properties

    /// Is Mercury currently retrograde?
    var isRetrograde: Bool {
        switch status {
        case .active, .stormBeginning, .stormEnding:
            return true
        default:
            return false
        }
    }

    /// Status message for display
    var statusMessage: String {
        switch status {
        case .active:
            return "MERCURY RETROGRADE ACTIVE"
        case .stormBeginning:
            return "RETROGRADE STORM BEGINNING"
        case .stormEnding:
            return "RETROGRADE STORM ENDING"
        case .preShadow:
            return "PRE-SHADOW PERIOD"
        case .clear:
            return "Mercury Direct"
        }
    }

    /// Countdown/progress text
    var countdownText: String {
        switch status {
        case .active, .stormBeginning, .stormEnding:
            return "Day \(currentDayOfRetrograde) of \(totalRetrogradeDays)"
        case .preShadow:
            return "\(daysUntilNext) days until retrograde"
        case .clear:
            if daysUntilNext > 0 {
                return "Next retrograde in \(daysUntilNext) days"
            } else {
                return "No upcoming retrograde data"
            }
        }
    }

    /// Short format for compact displays
    var shortText: String {
        switch status {
        case .active, .stormBeginning, .stormEnding:
            return "Day \(currentDayOfRetrograde)/\(totalRetrogradeDays)"
        case .preShadow, .clear:
            return daysUntilNext > 0 ? "\(daysUntilNext)d" : "—"
        }
    }

    /// Advice based on current status
    var currentAdvice: String {
        switch status {
        case .active:
            return "Triple-check all communications and contracts. Avoid major tech purchases. Back up everything."
        case .stormBeginning:
            return "The retrograde storm is intensifying. Be extra cautious with decisions today."
        case .stormEnding:
            return "Almost through! But don't let your guard down — the final days can be tricky."
        case .preShadow:
            return "Pre-shadow period: Themes of the upcoming retrograde are emerging. Tie up loose ends."
        case .clear:
            return "Mercury is direct. Good time for signing contracts, making deals, and clear communication."
        }
    }

    /// Trading advice
    var tradingAdvice: String {
        switch status {
        case .active, .stormBeginning, .stormEnding:
            return "Review positions carefully. Avoid impulsive trades. Technology glitches may cause delays. Double-check order details before confirming."
        case .preShadow:
            return "Consider closing or adjusting positions before retrograde begins. Prepare for potential volatility."
        case .clear:
            return "Communication flows smoothly. Good period for researching new investments and executing planned trades."
        }
    }

    /// Progress percentage (0-1) for active retrograde
    var progressPercentage: Double {
        guard isRetrograde, totalRetrogradeDays > 0 else { return 0 }
        return min(1.0, Double(currentDayOfRetrograde) / Double(totalRetrogradeDays))
    }

    /// Days remaining in active retrograde
    var daysRemaining: Int {
        guard isRetrograde else { return 0 }
        return max(0, totalRetrogradeDays - currentDayOfRetrograde)
    }

    /// Color for current status
    var statusColor: Color {
        switch status {
        case .active:
            return .orange
        case .stormBeginning, .stormEnding:
            return .red
        case .preShadow:
            return .yellow
        case .clear:
            return .green
        }
    }

    /// Icon for current status
    var statusIcon: String {
        switch status {
        case .active, .stormBeginning, .stormEnding:
            return "arrow.uturn.backward.circle.fill"
        case .preShadow:
            return "exclamationmark.triangle.fill"
        case .clear:
            return "checkmark.circle.fill"
        }
    }

    // MARK: - 2025 Mercury Retrograde Periods

    /// All Mercury Retrograde periods for 2025 (for reference)
    static let retrograde2025Periods: [(start: String, end: String, sign: String)] = [
        ("Mar 14", "Apr 7", "Aries/Pisces"),
        ("Jul 18", "Aug 11", "Leo/Virgo"),
        ("Nov 9", "Nov 29", "Sagittarius")
    ]

    // MARK: - Private Methods

    private func startRefreshTimer() {
        // Refresh every hour
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 3600, repeats: true) { _ in
            Task { @MainActor in
                MercuryRetrogradeService.shared.refreshStatus()
            }
        }
    }
}

// MARK: - Retrograde Status

enum RetrogradeStatus: String, CaseIterable {
    case active = "Active"
    case stormBeginning = "Storm Beginning"
    case stormEnding = "Storm Ending"
    case preShadow = "Pre-Shadow"
    case clear = "Clear"

    var severity: Int {
        switch self {
        case .stormBeginning, .stormEnding: return 3
        case .active: return 2
        case .preShadow: return 1
        case .clear: return 0
        }
    }

    var emoji: String {
        switch self {
        case .active: return "☿️"
        case .stormBeginning: return "⚡️"
        case .stormEnding: return "🌤"
        case .preShadow: return "⚠️"
        case .clear: return "✅"
        }
    }
}

// MARK: - Analytics Events

extension AnalyticsEvent {
    static let mercuryRetrogradeViewed = AnalyticsEvent(rawValue: "mercury_retrograde_viewed")!
}
