import SwiftUI

// MARK: - FreeTierPaywall
// =======================
// One place to present the paywall when a free-tier allowance runs out.
//
// The three limits (swipes, watchlist size, daily readings) live on separate
// screens, and a limit that stops an action without explaining itself reads as
// a bug rather than as a limit. This modifier keeps the presentation and the
// analytics source in one place so a fourth limit cannot arrive with its own
// slightly different handling.

extension View {

    /// Presents the paywall when `isPresented` flips, tagging the analytics
    /// event with which allowance ran out.
    func freeTierPaywall(isPresented: Binding<Bool>, source: String) -> some View {
        sheet(isPresented: isPresented) {
            PaywallView()
                .onAppear {
                    AnalyticsService.shared.trackPaywallViewed(source: source)
                }
        }
    }
}

/// The analytics source names for each allowance, so the funnel can tell which
/// limit actually converts.
enum FreeTierPaywallSource {
    static let dailySwipes = "free_tier_daily_swipes"
    static let watchlistSize = "free_tier_watchlist_limit"
    static let dailyReading = "free_tier_daily_reading"
}
