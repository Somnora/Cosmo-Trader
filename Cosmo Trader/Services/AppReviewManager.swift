import StoreKit
import SwiftUI

// MARK: - AppReviewManager
// =========================
// Manages App Store review prompt timing using Apple's SKStoreReviewController.
//
// Strategy:
// - Prompt after the user has generated 3+ readings AND opened the app on 3+ days.
// - Never prompt more than once per 120-day window (Apple throttles anyway,
//   but this prevents the ask-every-session antipattern).
// - Reset the counter after a prompt so returning users get asked again
//   after continued engagement.

@Observable
final class AppReviewManager {

    static let shared = AppReviewManager()

    // MARK: - UserDefaults Keys

    private enum Keys {
        static let readingCount = "appReview.readingCount"
        static let uniqueDaysOpened = "appReview.uniqueDaysOpened"
        static let lastPromptDate = "appReview.lastPromptDate"
        static let lastRecordedDay = "appReview.lastRecordedDay"
    }

    // MARK: - Thresholds

    /// Minimum readings before eligible for a prompt
    private let minimumReadings = 3

    /// Minimum unique days the app was opened
    private let minimumDays = 3

    /// Minimum days between prompts (Apple throttles further, but respect the user)
    private let daysBetweenPrompts = 120

    // MARK: - Tracking

    /// Call when the user regenerates or views a horoscope reading
    func recordReadingGenerated() {
        let current = UserDefaults.standard.integer(forKey: Keys.readingCount)
        UserDefaults.standard.set(current + 1, forKey: Keys.readingCount)
    }

    /// Call once per app session (e.g., on Cosmos tab appear)
    func recordAppOpened() {
        let today = calendarDayString()
        let lastDay = UserDefaults.standard.string(forKey: Keys.lastRecordedDay)

        guard today != lastDay else { return }

        UserDefaults.standard.set(today, forKey: Keys.lastRecordedDay)
        let current = UserDefaults.standard.integer(forKey: Keys.uniqueDaysOpened)
        UserDefaults.standard.set(current + 1, forKey: Keys.uniqueDaysOpened)
    }

    /// Check eligibility and request review if appropriate.
    /// Call this after a positive moment (reading regenerated, watchlist built).
    func requestReviewIfAppropriate() {
        let readings = UserDefaults.standard.integer(forKey: Keys.readingCount)
        let days = UserDefaults.standard.integer(forKey: Keys.uniqueDaysOpened)

        guard (readings >= minimumReadings || days >= 5),
              !hasPromptedRecently()
        else { return }

        // Mark that we prompted
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: Keys.lastPromptDate)

        // Reset reading counter so they need to re-engage before next prompt
        UserDefaults.standard.set(0, forKey: Keys.readingCount)

        // Request review through the current window scene
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            guard let scene = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .first(where: { $0.activationState == .foregroundActive })
            else { return }

            SKStoreReviewController.requestReview(in: scene)
        }
    }

    // MARK: - Private

    private func hasPromptedRecently() -> Bool {
        let lastPrompt = UserDefaults.standard.double(forKey: Keys.lastPromptDate)
        guard lastPrompt > 0 else { return false }

        let lastDate = Date(timeIntervalSince1970: lastPrompt)
        let daysSince = Calendar.current.dateComponents([.day], from: lastDate, to: Date()).day ?? 0
        return daysSince < daysBetweenPrompts
    }

    private func calendarDayString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
}
