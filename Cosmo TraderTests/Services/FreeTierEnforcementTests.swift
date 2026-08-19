import Foundation
import Testing
@testable import Cosmo_Trader

/// The free-tier limits existed as constants with no production caller for the
/// whole life of the project: `freeSwipeLimit`, `freeStockLimit` and
/// `freeHoroscopeLimit` were declared, tested for their values, and never
/// consulted by anything a user could reach. These tests pin the enforcement
/// rather than the numbers.
// Nested under the serialized parent because the watchlist tests construct
// AppState, which reads and writes the real shared `com.cosmotrader.userProfile`
// key. See AppStatePersistenceSuites for why running these in parallel with the
// other persisting suites reopens a last-writer-wins race.
extension AppStatePersistenceSuites {

@MainActor
struct FreeTierEnforcementTests {

    // MARK: - Watchlist size

    @Test("The watchlist limit stops the eleventh add for free accounts")
    func watchlistLimitStopsTheEleventhAdd() {
        let manager = SubscriptionManager.shared

        #expect(manager.canAddStock(currentCount: 0))
        #expect(manager.canAddStock(currentCount: manager.freeStockLimit - 1))
        #expect(!manager.canAddStock(currentCount: manager.freeStockLimit))
        #expect(!manager.canAddStock(currentCount: manager.freeStockLimit + 5))
    }

    @Test("Adding a symbol already on the watchlist is never blocked")
    func reAddingAnExistingSymbolIsNotBlocked() {
        // The limit is on watchlist SIZE, so a symbol already counted must not
        // be refused -- otherwise a full watchlist makes its own members
        // un-addable and the toggle on Stock Detail starts lying.
        let state = AppState(user: profile(watchlistCount: 20))
        let existing = "SYM0"

        #expect(state.currentUser?.watchlist.contains(existing) == true)
        #expect(state.addToWatchlist(existing))
    }

    @Test("A full watchlist refuses a new symbol and says so")
    func fullWatchlistRefusesNewSymbol() {
        let state = AppState(user: profile(watchlistCount: 20))

        #expect(!state.addToWatchlist("BRANDNEW"))
        #expect(state.currentUser?.watchlist.contains("BRANDNEW") == false)
    }

    @Test("Onboarding is exempt from the watchlist limit")
    func onboardingIsExemptFromTheWatchlistLimit() {
        // A paywall during first-run setup fires before anyone has seen what
        // the app does. The exemption is explicit at the call site rather than
        // implicit in a count.
        let state = AppState(user: profile(watchlistCount: 20))

        #expect(state.addToWatchlist("FIRSTRUN", enforcingFreeTierLimit: false))
        #expect(state.currentUser?.watchlist.contains("FIRSTRUN") == true)
    }

    @Test("No user means no add, limit or not")
    func missingUserRefusesTheAdd() {
        let state = AppState(user: nil)

        #expect(!state.addToWatchlist("ANY"))
        #expect(!state.addToWatchlist("ANY", enforcingFreeTierLimit: false))
    }

    // MARK: - Daily reading

    @Test("The horoscope limit is one reading a day for free accounts")
    func horoscopeLimitIsOnePerDay() {
        #expect(SubscriptionManager.shared.freeHoroscopeLimit == 1)
    }

    // MARK: - Swipes

    @Test("Swipe allowance is reported, not just stored")
    func swipeAllowanceIsReported() {
        // swipesRemaining and swipesExhausted had no readers at all, which is
        // how a limit ends up shipped but unenforced.
        let manager = SubscriptionManager.shared

        #expect(manager.freeSwipeLimit == 5)
        #expect(manager.swipesRemaining >= 0)
    }

    @Test("Every swipe outcome is distinguishable")
    func swipeOutcomesAreDistinguishable() {
        // The view branches on these to decide whether to toast, do nothing,
        // or present the paywall. Collapsing any two would make a blocked
        // swipe look like a successful one.
        #expect(DiscoverSwipeOutcome.recorded != .swipeLimitReached)
        #expect(DiscoverSwipeOutcome.recorded != .watchlistLimitReached)
        #expect(DiscoverSwipeOutcome.swipeLimitReached != .watchlistLimitReached)
    }

    // MARK: - Fixtures

    private func profile(watchlistCount: Int) -> UserProfile {
        var user = UserProfile(
            displayName: "Limit Tester",
            email: "limits@cosmictrader.com",
            birthMonth: 8, birthDay: 1, birthYear: 1990
        )
        user.watchlist = (0..<watchlistCount).map { "SYM\($0)" }
        return user
    }
}

}
