import Foundation

/// Canonical referral qualification milestones.
///
/// Must stay in sync with the backend `ALLOWED_REFERRAL_MILESTONES`.
/// Adding a new case requires adding the matching raw value on the backend
/// (and vice versa) in the same change.
enum ReferralMilestone: String, CaseIterable, Codable {
    case firstProfileOpen = "first_profile_open"
    case firstWatchlistAdd = "first_watchlist_add"
    case firstSwipeSession = "first_swipe_session"

    var qualificationStorageKey: String {
        "referral_qualified_\(rawValue)"
    }

    static func validated(_ rawValue: String) -> ReferralMilestone? {
        ReferralMilestone(rawValue: rawValue)
    }
}
