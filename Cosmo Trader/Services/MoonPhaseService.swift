import Foundation
import SwiftUI
import UserNotifications

// MARK: - Moon Phase Service
// ===========================
// Calculates actual moon phases using astronomical formulas.
// Based on the synodic month (time between new moons) of approximately 29.53 days.

@Observable
final class MoonPhaseService {

    // MARK: - Singleton

    static let shared = MoonPhaseService()

    // MARK: - Constants

    /// Average length of a synodic month (new moon to new moon)
    private let synodicMonth: Double = 29.530588853

    /// Reference new moon date (known new moon: January 6, 2000 at 18:14 UTC)
    private let referenceNewMoon: Date = {
        var components = DateComponents()
        components.year = 2000
        components.month = 1
        components.day = 6
        components.hour = 18
        components.minute = 14
        components.timeZone = TimeZone(identifier: "UTC")
        return Calendar.current.date(from: components)!
    }()

    /// Sidereal month (moon's orbit through zodiac signs)
    private let siderealMonth: Double = 27.321661

    /// Reference point for moon sign calculation (moon in Aries: Jan 1, 2000)
    private let referenceMoonInAries: Date = {
        var components = DateComponents()
        components.year = 2000
        components.month = 1
        components.day = 1
        components.hour = 0
        components.timeZone = TimeZone(identifier: "UTC")
        return Calendar.current.date(from: components)!
    }()

    // MARK: - State

    /// Current lunar data (cached)
    private(set) var currentLunarData: LunarData?

    /// Last calculation time
    private var lastCalculation: Date?

    /// Notification settings
    var notifyOnFullMoon: Bool = true {
        didSet { UserDefaults.standard.set(notifyOnFullMoon, forKey: "notifyOnFullMoon") }
    }

    var notifyOnNewMoon: Bool = true {
        didSet { UserDefaults.standard.set(notifyOnNewMoon, forKey: "notifyOnNewMoon") }
    }

    var notifyOnMoonInUserSign: Bool = false {
        didSet { UserDefaults.standard.set(notifyOnMoonInUserSign, forKey: "notifyOnMoonInUserSign") }
    }

    /// User's sun sign for moon-in-sign notifications
    var userSunSign: ZodiacSign? {
        didSet {
            if let sign = userSunSign {
                UserDefaults.standard.set(sign.rawValue, forKey: "userSunSignForMoon")
            }
        }
    }

    // MARK: - Init

    private init() {
        // Load notification preferences
        notifyOnFullMoon = UserDefaults.standard.object(forKey: "notifyOnFullMoon") as? Bool ?? true
        notifyOnNewMoon = UserDefaults.standard.object(forKey: "notifyOnNewMoon") as? Bool ?? true
        notifyOnMoonInUserSign = UserDefaults.standard.object(forKey: "notifyOnMoonInUserSign") as? Bool ?? false

        // Load user sun sign
        if let signRaw = UserDefaults.standard.string(forKey: "userSunSignForMoon"),
           let sign = ZodiacSign(rawValue: signRaw) {
            userSunSign = sign
        }

        // Calculate initial data
        currentLunarData = calculateLunarData(for: Date())
    }

    // MARK: - Public Methods

    /// Get current lunar data, recalculating if needed
    func getCurrentLunarData() -> LunarData {
        let now = Date()

        // Recalculate if more than 1 hour has passed
        if let lastCalc = lastCalculation,
           now.timeIntervalSince(lastCalc) < 3600,
           let cached = currentLunarData {
            return cached
        }

        let data = calculateLunarData(for: now)
        currentLunarData = data
        lastCalculation = now
        return data
    }

    /// Get lunar data for a specific date
    func getLunarData(for date: Date) -> LunarData {
        calculateLunarData(for: date)
    }

    /// Get the next occurrence of a specific phase
    func getNextPhase(_ targetPhase: MoonPhase, from date: Date = Date()) -> Date {
        let currentAge = getMoonAge(for: date)
        let targetAge = getPhaseAge(targetPhase)

        var daysUntil: Double
        if targetAge > currentAge {
            daysUntil = targetAge - currentAge
        } else {
            daysUntil = synodicMonth - currentAge + targetAge
        }

        return Calendar.current.date(byAdding: .second, value: Int(daysUntil * 86400), to: date) ?? date
    }

    /// Get upcoming significant phases (new and full moons)
    func getUpcomingSignificantPhases(count: Int = 4) -> [MoonPhaseCalendarEntry] {
        var entries: [MoonPhaseCalendarEntry] = []
        var currentDate = Date()

        while entries.count < count {
            let nextNew = getNextPhase(.newMoon, from: currentDate)
            let nextFull = getNextPhase(.fullMoon, from: currentDate)

            if nextNew < nextFull {
                entries.append(MoonPhaseCalendarEntry(
                    date: nextNew,
                    phase: .newMoon,
                    illumination: 0
                ))
                currentDate = Calendar.current.date(byAdding: .day, value: 1, to: nextNew) ?? nextNew
            } else {
                entries.append(MoonPhaseCalendarEntry(
                    date: nextFull,
                    phase: .fullMoon,
                    illumination: 1.0
                ))
                currentDate = Calendar.current.date(byAdding: .day, value: 1, to: nextFull) ?? nextFull
            }
        }

        return entries
    }

    /// Get moon phase calendar for a month
    func getMonthlyCalendar(for month: Date) -> [MoonPhaseCalendarEntry] {
        let calendar = Calendar.current
        let range = calendar.range(of: .day, in: .month, for: month)!
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: month))!

        return range.compactMap { day -> MoonPhaseCalendarEntry? in
            guard let date = calendar.date(byAdding: .day, value: day - 1, to: startOfMonth) else {
                return nil
            }
            let lunarData = calculateLunarData(for: date)
            return MoonPhaseCalendarEntry(
                date: date,
                phase: lunarData.phase,
                illumination: lunarData.illumination
            )
        }
    }

    // MARK: - Notifications

    /// Schedule moon phase notifications
    func scheduleNotifications() {
        // Remove existing notifications
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [
            "fullMoonAlert", "newMoonAlert", "fullMoonEve", "newMoonEve", "moonInSignAlert"
        ])

        guard notifyOnFullMoon || notifyOnNewMoon || notifyOnMoonInUserSign else { return }

        // Request permission
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, _ in
            guard granted else { return }

            Task { @MainActor in
                if self.notifyOnFullMoon {
                    self.scheduleFullMoonNotifications()
                }
                if self.notifyOnNewMoon {
                    self.scheduleNewMoonNotifications()
                }
                if self.notifyOnMoonInUserSign, let sign = self.userSunSign {
                    self.scheduleMoonInSignNotification(for: sign)
                }
            }
        }
    }

    /// Get next date when moon enters a specific sign
    func getNextMoonInSign(_ targetSign: ZodiacSign, from date: Date = Date()) -> Date {
        let signDuration = siderealMonth / 12  // ~2.28 days per sign
        let currentData = getLunarData(for: date)
        let currentSignIndex = ZodiacSign.allCases.firstIndex(of: currentData.moonSign)!
        let targetSignIndex = ZodiacSign.allCases.firstIndex(of: targetSign)!

        // Calculate days until target sign
        var signsToWait = targetSignIndex - currentSignIndex
        if signsToWait <= 0 {
            signsToWait += 12
        }

        let daysUntil = Double(signsToWait) * signDuration
        return Calendar.current.date(byAdding: .second, value: Int(daysUntil * 86400), to: date) ?? date
    }

    private func scheduleMoonInSignNotification(for sign: ZodiacSign) {
        let nextEntry = getNextMoonInSign(sign)

        scheduleNotification(
            identifier: "moonInSignAlert",
            title: "Moon in \(sign.displayName)",
            body: "The moon enters your sign today. Your \(sign.element.displayName) sector is activated. A personally significant lunar day.",
            date: nextEntry
        )
    }

    private func scheduleFullMoonNotifications() {
        let nextFull = getNextPhase(.fullMoon)

        // Day before notification
        if let dayBefore = Calendar.current.date(byAdding: .day, value: -1, to: nextFull) {
            scheduleNotification(
                identifier: "fullMoonEve",
                title: "🌕 Full Moon Tomorrow",
                body: "Expect heightened market volatility. The market's emotions may run high.",
                date: dayBefore
            )
        }

        // Day of notification
        scheduleNotification(
            identifier: "fullMoonAlert",
            title: "🌕 Full Moon Today",
            body: "Peak lunar energy. Some traders watch for increased price swings around full moons.",
            date: nextFull
        )
    }

    private func scheduleNewMoonNotifications() {
        let nextNew = getNextPhase(.newMoon)

        // Day of notification
        scheduleNotification(
            identifier: "newMoonAlert",
            title: "🌑 New Moon Today",
            body: "Fresh lunar cycle beginning. Some traders view this as a good time to research new positions.",
            date: nextNew
        )

        // Day before notification
        if let dayBefore = Calendar.current.date(byAdding: .day, value: -1, to: nextNew) {
            scheduleNotification(
                identifier: "newMoonEve",
                title: "🌑 New Moon Tomorrow",
                body: "New cycle begins tomorrow. Consider what positions you'd like to initiate.",
                date: dayBefore
            )
        }
    }

    private func scheduleNotification(identifier: String, title: String, body: String, date: Date) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let components = Calendar.current.dateComponents([.year, .month, .day, .hour], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Private Calculations

    /// Calculate complete lunar data for a given date
    private func calculateLunarData(for date: Date) -> LunarData {
        let age = getMoonAge(for: date)
        let phase = getPhase(from: age)
        let illumination = getIllumination(from: age)
        let moonSign = getMoonSign(for: date)
        let isWaxing = age < (synodicMonth / 2)

        return LunarData(
            date: date,
            phase: phase,
            illumination: illumination,
            age: age,
            moonSign: moonSign,
            isWaxing: isWaxing
        )
    }

    /// Calculate moon age (days since last new moon)
    private func getMoonAge(for date: Date) -> Double {
        let daysSinceReference = date.timeIntervalSince(referenceNewMoon) / 86400
        let age = daysSinceReference.truncatingRemainder(dividingBy: synodicMonth)
        return age < 0 ? age + synodicMonth : age
    }

    /// Determine phase from moon age
    private func getPhase(from age: Double) -> MoonPhase {
        let phaseLength = synodicMonth / 8

        switch age {
        case 0..<phaseLength:
            return .newMoon
        case phaseLength..<(phaseLength * 2):
            return .waxingCrescent
        case (phaseLength * 2)..<(phaseLength * 3):
            return .firstQuarter
        case (phaseLength * 3)..<(phaseLength * 4):
            return .waxingGibbous
        case (phaseLength * 4)..<(phaseLength * 5):
            return .fullMoon
        case (phaseLength * 5)..<(phaseLength * 6):
            return .waningGibbous
        case (phaseLength * 6)..<(phaseLength * 7):
            return .lastQuarter
        default:
            return .waningCrescent
        }
    }

    /// Calculate illumination percentage (0-1)
    private func getIllumination(from age: Double) -> Double {
        // Use cosine function for smooth illumination curve
        let phaseAngle = (age / synodicMonth) * 2 * .pi
        let illumination = (1 - cos(phaseAngle)) / 2
        return illumination
    }

    /// Get the target age for a specific phase
    private func getPhaseAge(_ phase: MoonPhase) -> Double {
        let phaseLength = synodicMonth / 8

        switch phase {
        case .newMoon:        return 0
        case .waxingCrescent: return phaseLength
        case .firstQuarter:   return phaseLength * 2
        case .waxingGibbous:  return phaseLength * 3
        case .fullMoon:       return phaseLength * 4
        case .waningGibbous:  return phaseLength * 5
        case .lastQuarter:    return phaseLength * 6
        case .waningCrescent: return phaseLength * 7
        }
    }

    /// Calculate the current zodiac sign the moon is in
    private func getMoonSign(for date: Date) -> ZodiacSign {
        // Moon moves through all 12 signs in ~27.3 days
        let daysSinceReference = date.timeIntervalSince(referenceMoonInAries) / 86400
        let signDuration = siderealMonth / 12  // ~2.28 days per sign

        let signIndex = Int(daysSinceReference / signDuration).truncatingRemainder(dividingBy: 12)
        let normalizedIndex = signIndex < 0 ? signIndex + 12 : signIndex

        return ZodiacSign.allCases[normalizedIndex]
    }
}

// MARK: - Int Truncating Remainder

extension Int {
    func truncatingRemainder(dividingBy divisor: Int) -> Int {
        return self % divisor
    }
}

// MARK: - Moon Phase Service Extensions

extension MoonPhaseService {

    /// Get a trading recommendation summary
    func getTradingRecommendation() -> String {
        let data = getCurrentLunarData()
        let signal = data.phase.tradingSignal

        return """
        \(signal.headline): \(signal.summary)

        Moon in \(data.moonSign.displayName) (\(data.moonSign.element.displayName) sign)
        \(data.moonSignInsight)
        """
    }

    /// Check if today is a significant lunar day
    func isSignificantLunarDay() -> (isSignificant: Bool, reason: String?) {
        let data = getCurrentLunarData()

        if data.phase == .fullMoon {
            return (true, "Full moon — peak volatility expected")
        } else if data.phase == .newMoon {
            return (true, "New moon — fresh cycle beginning")
        } else if data.daysUntilFullMoon == 1 {
            return (true, "Full moon tomorrow — prepare for volatility")
        } else if data.daysUntilNewMoon == 1 {
            return (true, "New moon tomorrow — cycle ending")
        }

        return (false, nil)
    }

    /// Get element stocks are activated today
    func getActivatedElement() -> ZodiacSign.Element {
        return getCurrentLunarData().moonSign.element
    }

    /// Get stocks that align with current lunar energy
    func getAlignedStockDescription() -> String {
        return getCurrentLunarData().alignedStockTypes
    }
}
