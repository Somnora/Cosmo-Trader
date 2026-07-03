import Foundation
import UserNotifications
import SwiftUI

// MARK: - Notification Service
// =============================
// Handles local notification logic for Cosmo Trader.
// Requests permission thoughtfully, schedules strategic notifications,
// and respects user preferences at all times.

@MainActor
@Observable
final class NotificationService {

    // MARK: - Singleton

    static let shared = NotificationService()

    // MARK: - Storage Keys

    private enum StorageKeys {
        static let hasRequestedPermission = "notifications_hasRequested"
        static let permissionStatus = "notifications_status"
        static let dailyHoroscopeEnabled = "notifications_dailyHoroscope"
        static let dailyHoroscopeTime = "notifications_dailyHoroscopeTime"
        static let moonPhaseEnabled = "notifications_moonPhase"
        static let mercuryRetrogradeEnabled = "notifications_mercuryRetrograde"
        static let portfolioAlertsEnabled = "notifications_portfolioAlerts"
        static let ipoAlertsEnabled = "notifications_ipoAlerts"
        static let cosmicRoastReminderEnabled = "notifications_cosmicRoast"
        static let weeklySummaryEnabled = "notifications_weeklySummary"
        static let signSeasonEnabled = "notifications_signSeason"
    }

    // MARK: - Permission State

    /// Whether we've already asked for permission (don't ask again if denied)
    private(set) var hasRequestedPermission: Bool = false

    /// Current authorization status
    private(set) var authorizationStatus: UNAuthorizationStatus = .notDetermined

    /// Whether notifications are currently authorized
    var isAuthorized: Bool {
        authorizationStatus == .authorized
    }

    /// Whether we can show the permission prompt (haven't asked yet)
    var canRequestPermission: Bool {
        !hasRequestedPermission && authorizationStatus == .notDetermined
    }

    // MARK: - Notification Preferences

    /// Daily horoscope notification (default: ON)
    var dailyHoroscopeEnabled: Bool = true {
        didSet {
            savePreferences()
            scheduleAllNotifications()
        }
    }

    /// Preferred time for daily horoscope (default: 7:30 AM)
    var dailyHoroscopeTime: Date = defaultHoroscopeTime() {
        didSet {
            savePreferences()
            scheduleAllNotifications()
        }
    }

    /// Moon phase alerts (default: ON)
    var moonPhaseEnabled: Bool = true {
        didSet {
            savePreferences()
            scheduleAllNotifications()
        }
    }

    /// Mercury retrograde alerts (default: ON)
    var mercuryRetrogradeEnabled: Bool = true {
        didSet {
            savePreferences()
            scheduleAllNotifications()
        }
    }

    /// Portfolio movement alerts (default: ON)
    var portfolioAlertsEnabled: Bool = true {
        didSet {
            savePreferences()
            scheduleAllNotifications()
        }
    }

    /// Weekly summary (default: ON)
    var weeklySummaryEnabled: Bool = true {
        didSet {
            savePreferences()
            scheduleAllNotifications()
        }
    }

    /// IPO alerts for compatible signs (default: OFF)
    var ipoAlertsEnabled: Bool = false {
        didSet {
            savePreferences()
            scheduleAllNotifications()
        }
    }

    /// Cosmic roast reminder (default: OFF)
    var cosmicRoastReminderEnabled: Bool = false {
        didSet {
            savePreferences()
            scheduleAllNotifications()
        }
    }

    /// Sign season alerts - when sun enters new zodiac sign (default: ON)
    var signSeasonEnabled: Bool = true {
        didSet {
            savePreferences()
            scheduleAllNotifications()
        }
    }

    // MARK: - Notification Identifiers

    private enum NotificationID {
        static let dailyHoroscope = "cosmo.daily.horoscope"
        static let moonPhasePrefix = "cosmo.moon."
        static let mercuryRetrogradePrefix = "cosmo.mercury."
        static let portfolioBigMove = "cosmo.portfolio.bigmove"
        static let weeklySummary = "cosmo.weekly.summary"
        static let ipoAlertPrefix = "cosmo.ipo."
        static let cosmicRoast = "cosmo.roast.reminder"
        static let signSeasonPrefix = "cosmo.season."
    }

    // MARK: - Initialization

    private init() {
        loadPreferences()
        Task {
            await refreshAuthorizationStatus()
        }
    }

    // MARK: - Default Time

    private static func defaultHoroscopeTime() -> Date {
        var components = DateComponents()
        components.hour = 7
        components.minute = 30
        return Calendar.current.date(from: components) ?? Date()
    }

    // MARK: - Permission Request

    /// Request notification permission (call after onboarding)
    /// Returns true if permission was granted
    @discardableResult
    func requestPermission() async -> Bool {
        guard canRequestPermission else {
            return isAuthorized
        }

        let center = UNUserNotificationCenter.current()

        do {
            let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound])

            hasRequestedPermission = true
            UserDefaults.standard.set(true, forKey: StorageKeys.hasRequestedPermission)

            await refreshAuthorizationStatus()

            if granted {
                scheduleAllNotifications()
                AnalyticsService.shared.track(.notificationPermissionGranted)
            } else {
                AnalyticsService.shared.track(.notificationPermissionDenied)
            }

            return granted
        } catch {
            #if DEBUG
            print("Failed to request notification permission: \(error)")
            #endif
            hasRequestedPermission = true
            UserDefaults.standard.set(true, forKey: StorageKeys.hasRequestedPermission)
            return false
        }
    }

    /// Refresh the current authorization status
    func refreshAuthorizationStatus() async {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        authorizationStatus = settings.authorizationStatus
    }

    /// Open system settings for the app
    func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }

    // MARK: - Schedule All Notifications

    /// Reschedule all notifications based on current preferences
    func scheduleAllNotifications() {
        guard isAuthorized else { return }

        Task {
            // Cancel all existing notifications first
            await cancelAllNotifications()

            // Schedule each type based on preferences
            if dailyHoroscopeEnabled {
                await scheduleDailyHoroscope()
            }

            if moonPhaseEnabled {
                await scheduleMoonPhaseAlerts()
            }

            if mercuryRetrogradeEnabled {
                await scheduleMercuryRetrogradeAlerts()
            }

            if weeklySummaryEnabled {
                await scheduleWeeklySummary()
            }

            if cosmicRoastReminderEnabled {
                await scheduleCosmicRoastReminder()
            }

            if signSeasonEnabled {
                await scheduleSignSeasonAlerts()
            }

            // IPO alerts are scheduled dynamically when new IPOs are added
            // Portfolio alerts are triggered by price changes (handled elsewhere)
        }
    }

    /// Cancel all scheduled notifications
    func cancelAllNotifications() async {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
    }

    // MARK: - Daily Horoscope

    private func scheduleDailyHoroscope() async {
        let content = UNMutableNotificationContent()
        content.title = "Your Cosmic Reading"
        content.body = randomHoroscopeMessage()
        content.sound = .default
        content.badge = 1
        content.userInfo = ["type": "daily_horoscope"]

        // Extract hour and minute from preferred time
        let components = Calendar.current.dateComponents([.hour, .minute], from: dailyHoroscopeTime)
        var triggerComponents = DateComponents()
        triggerComponents.hour = components.hour
        triggerComponents.minute = components.minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerComponents, repeats: true)

        let request = UNNotificationRequest(
            identifier: NotificationID.dailyHoroscope,
            content: content,
            trigger: trigger
        )

        do {
            try await UNUserNotificationCenter.current().add(request)
        } catch {
            #if DEBUG
            print("Failed to schedule daily horoscope: \(error)")
            #endif
        }
    }

    private func randomHoroscopeMessage() -> String {
        let messages = [
            "Your portfolio reading is ready.",
            "Today's reading is ready.",
            "A new market-astrology note is available.",
            "Today's lens is in.",
            "Your portfolio reading has refreshed."
        ]
        return messages.randomElement() ?? messages[0]
    }

    // MARK: - Moon Phase Alerts

    private func scheduleMoonPhaseAlerts() async {
        let moonService = MoonPhaseService.shared
        let calendar = Calendar.current
        let now = Date()

        // Schedule for the next 30 days
        for dayOffset in 0..<30 {
            guard let date = calendar.date(byAdding: .day, value: dayOffset, to: now) else { continue }

            let lunarData = moonService.getLunarData(for: date)
            let phase = lunarData.phase

            // Full moon - alert day before
            if phase == .fullMoon {
                if let dayBefore = calendar.date(byAdding: .day, value: -1, to: date) {
                    await scheduleNotification(
                        id: "\(NotificationID.moonPhasePrefix)full.\(dayOffset)",
                        title: "Full Moon Tomorrow",
                        body: "Full Moon overnight - a calendar marker, not a market call.",
                        date: dayBefore,
                        hour: 18,
                        minute: 0,
                        userInfo: ["type": "moon_phase", "phase": "full"]
                    )
                }
            }

            // New moon - alert on the day
            if phase == .newMoon {
                await scheduleNotification(
                    id: "\(NotificationID.moonPhasePrefix)new.\(dayOffset)",
                    title: "New Moon Today",
                    body: "New Moon today - a quiet marker in the lunar calendar.",
                    date: date,
                    hour: 8,
                    minute: 0,
                    userInfo: ["type": "moon_phase", "phase": "new"]
                )
            }
        }
    }

    // MARK: - Mercury Retrograde Alerts

    private func scheduleMercuryRetrogradeAlerts() async {
        // Mercury retrograde periods for 2025 (approximate dates)
        // These would ideally come from an astronomical API
        let retrogradePeriods: [(start: DateComponents, end: DateComponents)] = [
            (DateComponents(year: 2025, month: 3, day: 14), DateComponents(year: 2025, month: 4, day: 7)),
            (DateComponents(year: 2025, month: 7, day: 18), DateComponents(year: 2025, month: 8, day: 11)),
            (DateComponents(year: 2025, month: 11, day: 9), DateComponents(year: 2025, month: 11, day: 29))
        ]

        let calendar = Calendar.current
        let now = Date()

        for (index, period) in retrogradePeriods.enumerated() {
            // Start date notification
            if let startDate = calendar.date(from: period.start),
               startDate > now {
                await scheduleNotification(
                    id: "\(NotificationID.mercuryRetrogradePrefix)start.\(index)",
                    title: "Mercury Retrograde Begins",
                    body: "Double-check everything. Communication mishaps likely.",
                    date: startDate,
                    hour: 9,
                    minute: 0
                )
            }

            // End date notification
            if let endDate = calendar.date(from: period.end),
               endDate > now {
                await scheduleNotification(
                    id: "\(NotificationID.mercuryRetrogradePrefix)end.\(index)",
                    title: "Mercury Direct",
                    body: "Communication clarity returns. Safe to sign contracts.",
                    date: endDate,
                    hour: 9,
                    minute: 0
                )
            }
        }
    }

    // MARK: - Weekly Summary

    private func scheduleWeeklySummary() async {
        let content = UNMutableNotificationContent()
        content.title = "Your Weekly Portfolio Read"
        content.body = "Your portfolio summary is ready. Tap to review this week's market astrology reading."
        content.sound = .default
        content.userInfo = ["type": "weekly_summary"]

        // Sunday at 6:00 PM
        var components = DateComponents()
        components.weekday = 1 // Sunday
        components.hour = 18
        components.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)

        let request = UNNotificationRequest(
            identifier: NotificationID.weeklySummary,
            content: content,
            trigger: trigger
        )

        do {
            try await UNUserNotificationCenter.current().add(request)
        } catch {
            #if DEBUG
            print("Failed to schedule weekly summary: \(error)")
            #endif
        }
    }

    // MARK: - Cosmic Roast Reminder

    private func scheduleCosmicRoastReminder() async {
        let content = UNMutableNotificationContent()
        content.title = "Time for Your Roast"
        content.body = "Ready for the cosmos to humble you? Your weekly roast awaits."
        content.sound = .default
        content.userInfo = ["type": "cosmic_roast"]

        // Wednesday at 12:00 PM (midweek pick-me-up)
        var components = DateComponents()
        components.weekday = 4 // Wednesday
        components.hour = 12
        components.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)

        let request = UNNotificationRequest(
            identifier: NotificationID.cosmicRoast,
            content: content,
            trigger: trigger
        )

        do {
            try await UNUserNotificationCenter.current().add(request)
        } catch {
            #if DEBUG
            print("Failed to schedule cosmic roast reminder: \(error)")
            #endif
        }
    }

    // MARK: - Sign Season Alerts

    /// Schedule notifications for zodiac sign transitions (~21st of each month)
    private func scheduleSignSeasonAlerts() async {
        let calendar = Calendar.current
        let now = Date()

        // Schedule alerts for the next 3 zodiac sign transitions
        for offset in 0..<3 {
            // Get current sign and find when next sign starts
            var checkDate = now
            for _ in 0...offset {
                let currentSign = ZodiacSign.from(date: checkDate)
                let nextSign = getNextSign(after: currentSign)

                // Calculate the start date of the next sign
                var year = calendar.component(.year, from: checkDate)
                let startDate = nextSign.startDate

                // If the next sign starts in a month before the current month, it's next year
                let currentMonth = calendar.component(.month, from: checkDate)
                let currentDay = calendar.component(.day, from: checkDate)

                if startDate.month < currentMonth || (startDate.month == currentMonth && startDate.day <= currentDay) {
                    year += 1
                }

                var components = DateComponents()
                components.year = year
                components.month = startDate.month
                components.day = startDate.day
                components.hour = 8  // 8 AM on sign transition day
                components.minute = 0

                if let nextSeasonDate = calendar.date(from: components), nextSeasonDate > now {
                    checkDate = nextSeasonDate

                    // Schedule the notification
                    let content = UNMutableNotificationContent()
                    content.title = "\(nextSign.displayName) Season Begins"
                    content.body = "Sun enters \(nextSign.displayName). Your \(nextSign.element.displayName) Sector is in focus."
                    content.sound = .default
                    content.userInfo = ["type": "signSeason", "sign": nextSign.rawValue]

                    let triggerComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: nextSeasonDate)
                    let trigger = UNCalendarNotificationTrigger(dateMatching: triggerComponents, repeats: false)

                    let request = UNNotificationRequest(
                        identifier: "\(NotificationID.signSeasonPrefix)\(nextSign.rawValue)",
                        content: content,
                        trigger: trigger
                    )

                    do {
                        try await UNUserNotificationCenter.current().add(request)
                    } catch {
                        #if DEBUG
                        print("Failed to schedule sign season alert for \(nextSign.displayName): \(error)")
                        #endif
                    }
                }
            }
        }
    }

    /// Get the next zodiac sign in sequence
    private func getNextSign(after sign: ZodiacSign) -> ZodiacSign {
        let allSigns = ZodiacSign.allCases
        guard let currentIndex = allSigns.firstIndex(of: sign) else { return .aries }
        let nextIndex = (currentIndex + 1) % allSigns.count
        return allSigns[nextIndex]
    }

    // MARK: - Cosmic Confluence Alerts

    /// Send a cosmic confluence alert when technical and cosmic signals align
    /// This is the key notification type that makes the app unique
    func sendCosmicConfluenceAlert(
        symbol: String,
        pattern: String,
        cosmicEvent: String,
        compatibility: Int,
        userSign: ZodiacSign
    ) async {
        guard isAuthorized && portfolioAlertsEnabled else { return }

        let content = UNMutableNotificationContent()
        content.title = "\(symbol): chart + chart-of-the-sky note"
        content.body = "A \(pattern) overlaps with \(cosmicEvent). Lens only - not a signal."
        content.sound = .default
        content.badge = 1
        content.userInfo = [
            "symbol": symbol,
            "type": "confluence",
            "pattern": pattern,
            "cosmicEvent": cosmicEvent,
            "compatibility": compatibility
        ]

        // Deliver in 1 second (near-immediate)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)

        let request = UNNotificationRequest(
            identifier: "confluence-\(symbol)-\(Date().timeIntervalSince1970)",
            content: content,
            trigger: trigger
        )

        do {
            try await UNUserNotificationCenter.current().add(request)
            AnalyticsService.shared.track(.confluenceAlertSent)
        } catch {
            #if DEBUG
            print("Failed to send confluence alert: \(error)")
            #endif
        }
    }

    /// Send a Mercury retrograde warning notification
    func sendMercuryRetrogradeWarning(daysUntil: Int, affectedStocksCount: Int) async {
        guard isAuthorized && mercuryRetrogradeEnabled else { return }

        let content = UNMutableNotificationContent()

        if daysUntil == 0 {
            content.title = "Mercury Retrograde Begins Today"
            content.body = "Mercury retrograde begins today. A traditional calendar marker - not a market forecast."
        } else if daysUntil == 1 {
            content.title = "Mercury Retrograde Tomorrow"
            content.body = "Mercury retrograde begins tomorrow. A traditional calendar marker - not a market forecast."
        } else {
            content.title = "Mercury Retrograde Approaching"
            content.body = "Mercury retrograde begins in \(daysUntil) days. A traditional calendar marker - not a market forecast."
        }

        content.sound = .default
        content.userInfo = ["type": "mercury_retrograde", "daysUntil": daysUntil]

        let request = UNNotificationRequest(
            identifier: "mercury-warning-\(Date().timeIntervalSince1970)",
            content: content,
            trigger: nil // Deliver immediately
        )

        do {
            try await UNUserNotificationCenter.current().add(request)
        } catch {
            #if DEBUG
            print("Failed to send Mercury retrograde warning: \(error)")
            #endif
        }
    }

    /// Send a portfolio milestone notification
    func sendPortfolioMilestone(milestone: String, message: String) async {
        guard isAuthorized && portfolioAlertsEnabled else { return }

        let content = UNMutableNotificationContent()
        content.title = "Portfolio milestone"
        content.body = "\(milestone) — \(message)"
        content.sound = .default
        content.userInfo = ["type": "portfolio_milestone", "milestone": milestone]

        let request = UNNotificationRequest(
            identifier: "milestone-\(Date().timeIntervalSince1970)",
            content: content,
            trigger: nil
        )

        do {
            try await UNUserNotificationCenter.current().add(request)
            AnalyticsService.shared.track(.portfolioMilestoneReached)
        } catch {
            #if DEBUG
            print("Failed to send portfolio milestone: \(error)")
            #endif
        }
    }

    // MARK: - Dynamic Notifications

    /// Schedule an IPO alert for a compatible zodiac sign
    func scheduleIPOAlert(ticker: String, companyName: String, ipoDate: Date, zodiacSign: ZodiacSign) async {
        guard isAuthorized && ipoAlertsEnabled else { return }

        let content = UNMutableNotificationContent()
        content.title = "Compatible IPO Alert"
        content.body = "A fellow \(zodiacSign.displayName) enters the market: \(companyName) (\(ticker))"
        content.sound = .default
        content.userInfo = ["ticker": ticker, "type": "ipo"]

        // Alert day before IPO
        let calendar = Calendar.current
        guard let alertDate = calendar.date(byAdding: .day, value: -1, to: ipoDate) else { return }

        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: alertDate)
        var triggerComponents = components
        triggerComponents.hour = 10
        triggerComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerComponents, repeats: false)

        let request = UNNotificationRequest(
            identifier: "\(NotificationID.ipoAlertPrefix)\(ticker)",
            content: content,
            trigger: trigger
        )

        do {
            try await UNUserNotificationCenter.current().add(request)
        } catch {
            #if DEBUG
            print("Failed to schedule IPO alert: \(error)")
            #endif
        }
    }

    /// Trigger a portfolio big move notification immediately
    func sendPortfolioBigMoveAlert(changePercent: Double) async {
        guard isAuthorized && portfolioAlertsEnabled else { return }
        guard abs(changePercent) >= 5.0 else { return } // Only for >5% moves

        let direction = changePercent > 0 ? "up" : "down"

        let content = UNMutableNotificationContent()
        content.title = "Portfolio Alert"
        content.body = "Your portfolio moved \(String(format: "%.1f", abs(changePercent)))% \(direction) today. Review the reading."
        content.sound = .default
        content.userInfo = ["type": "portfolio_move", "change": changePercent]

        let request = UNNotificationRequest(
            identifier: "\(NotificationID.portfolioBigMove).\(Date().timeIntervalSince1970)",
            content: content,
            trigger: nil // Deliver immediately
        )

        do {
            try await UNUserNotificationCenter.current().add(request)
        } catch {
            #if DEBUG
            print("Failed to send portfolio alert: \(error)")
            #endif
        }
    }

    // MARK: - Test Notification

    /// Send a test notification immediately
    func sendTestNotification() async {
        guard isAuthorized else { return }

        let content = UNMutableNotificationContent()
        content.title = "Notifications Enabled"
        content.body = "Your alerts are working. Signal updates can reach you now."
        content.sound = .default

        // Deliver in 2 seconds
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 2, repeats: false)

        let request = UNNotificationRequest(
            identifier: "cosmo.test.\(Date().timeIntervalSince1970)",
            content: content,
            trigger: trigger
        )

        do {
            try await UNUserNotificationCenter.current().add(request)
            AnalyticsService.shared.track(.testNotificationSent)
        } catch {
            #if DEBUG
            print("Failed to send test notification: \(error)")
            #endif
        }
    }

    // MARK: - Helper Methods

    private func scheduleNotification(id: String, title: String, body: String, date: Date, hour: Int, minute: Int, userInfo: [String: Any]? = nil) async {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        if let userInfo = userInfo {
            content.userInfo = userInfo
        }

        var components = Calendar.current.dateComponents([.year, .month, .day], from: date)
        components.hour = hour
        components.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        let request = UNNotificationRequest(
            identifier: id,
            content: content,
            trigger: trigger
        )

        do {
            try await UNUserNotificationCenter.current().add(request)
        } catch {
            #if DEBUG
            print("Failed to schedule notification \(id): \(error)")
            #endif
        }
    }

    // MARK: - Persistence

    private func savePreferences() {
        let defaults = UserDefaults.standard
        defaults.set(dailyHoroscopeEnabled, forKey: StorageKeys.dailyHoroscopeEnabled)
        defaults.set(dailyHoroscopeTime.timeIntervalSince1970, forKey: StorageKeys.dailyHoroscopeTime)
        defaults.set(moonPhaseEnabled, forKey: StorageKeys.moonPhaseEnabled)
        defaults.set(mercuryRetrogradeEnabled, forKey: StorageKeys.mercuryRetrogradeEnabled)
        defaults.set(portfolioAlertsEnabled, forKey: StorageKeys.portfolioAlertsEnabled)
        defaults.set(weeklySummaryEnabled, forKey: StorageKeys.weeklySummaryEnabled)
        defaults.set(ipoAlertsEnabled, forKey: StorageKeys.ipoAlertsEnabled)
        defaults.set(cosmicRoastReminderEnabled, forKey: StorageKeys.cosmicRoastReminderEnabled)
        defaults.set(signSeasonEnabled, forKey: StorageKeys.signSeasonEnabled)
    }

    private func loadPreferences() {
        let defaults = UserDefaults.standard

        hasRequestedPermission = defaults.bool(forKey: StorageKeys.hasRequestedPermission)

        // Load with defaults
        dailyHoroscopeEnabled = defaults.object(forKey: StorageKeys.dailyHoroscopeEnabled) as? Bool ?? true
        moonPhaseEnabled = defaults.object(forKey: StorageKeys.moonPhaseEnabled) as? Bool ?? true
        mercuryRetrogradeEnabled = defaults.object(forKey: StorageKeys.mercuryRetrogradeEnabled) as? Bool ?? true
        portfolioAlertsEnabled = defaults.object(forKey: StorageKeys.portfolioAlertsEnabled) as? Bool ?? true
        weeklySummaryEnabled = defaults.object(forKey: StorageKeys.weeklySummaryEnabled) as? Bool ?? true
        ipoAlertsEnabled = defaults.object(forKey: StorageKeys.ipoAlertsEnabled) as? Bool ?? false
        cosmicRoastReminderEnabled = defaults.object(forKey: StorageKeys.cosmicRoastReminderEnabled) as? Bool ?? false
        signSeasonEnabled = defaults.object(forKey: StorageKeys.signSeasonEnabled) as? Bool ?? true

        // Load horoscope time
        if let timestamp = defaults.object(forKey: StorageKeys.dailyHoroscopeTime) as? TimeInterval {
            dailyHoroscopeTime = Date(timeIntervalSince1970: timestamp)
        }
    }
}

// MARK: - Notification Permission View
// =====================================
// Shown after onboarding to request notification permission

struct NotificationPermissionView: View {
    @State private var notificationService = NotificationService.shared
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Cosmic illustration
            ZStack {
                Circle()
                    .fill(CosmicTheme.gold.opacity(0.1))
                    .frame(width: 160, height: 160)

                Circle()
                    .fill(CosmicTheme.gold.opacity(0.2))
                    .frame(width: 120, height: 120)

                Image(systemName: "bell.badge.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(CosmicTheme.goldGradient)
            }

            // Header
            VStack(spacing: 12) {
                Text("Cosmic Alerts")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(CosmicTheme.textPrimary)

                Text("Get cosmic insights delivered to your device")
                    .font(.subheadline)
                    .foregroundColor(CosmicTheme.textSecondary)
                    .multilineTextAlignment(.center)
            }

            // Benefits list
            VStack(alignment: .leading, spacing: 16) {
                benefitRow(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "Daily Readings",
                    description: "Your morning portfolio reading"
                )

                benefitRow(
                    icon: "moon.stars.fill",
                    title: "Moon Phase Alerts",
                    description: "Local lunar calendar markers"
                )

                benefitRow(
                    icon: "arrow.triangle.2.circlepath",
                    title: "Mercury Retrograde",
                    description: "Know when to double-check everything"
                )

                benefitRow(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "Portfolio Alerts",
                    description: "Big moves & weekly summaries"
                )
            }
            .padding(.horizontal, 24)

            Spacer()

            // Action buttons
            VStack(spacing: 12) {
                Button(action: enableNotifications) {
                    Text("Enable Cosmic Alerts")
                        .font(.headline)
                        .foregroundColor(CosmicTheme.terminalBlack)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(CosmicTheme.goldGradient)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                Button(action: { dismiss() }) {
                    Text("Not Now")
                        .font(.subheadline)
                        .foregroundColor(CosmicTheme.textMuted)
                }
                .padding(.vertical, 8)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(CosmicTheme.background.ignoresSafeArea())
    }

    private func benefitRow(icon: String, title: String, description: String) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(CosmicTheme.gold)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(CosmicTheme.textPrimary)

                Text(description)
                    .font(.caption)
                    .foregroundColor(CosmicTheme.textSecondary)
            }
        }
    }

    private func enableNotifications() {
        Task {
            await notificationService.requestPermission()
            dismiss()
        }
    }
}

// MARK: - Preview

#Preview("Permission Request") {
    NotificationPermissionView()
        .preferredColorScheme(.dark)
}
