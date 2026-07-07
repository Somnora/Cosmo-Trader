import Foundation

// MARK: - CloudProfileMerge
// =========================
// Merge rule for the launch-time cloud profile pull (AppState.
// fetchProfileFromCloud). The device is the source of truth: every local
// save already pushes to the cloud, so the pull exists only to restore
// onto an empty device. Cloud data therefore fills gaps and never
// replaces — an empty or stale cloud copy must not delete holdings or
// watchlist entries the user built locally.

enum CloudProfileMerge {

    struct Result: Equatable {
        let portfolio: [Stock]
        let watchlist: [String]
    }

    static func merge(
        localPortfolio: [Stock],
        localWatchlist: [String],
        cloudPortfolio: [Stock]?,
        cloudWatchlist: [String]?
    ) -> Result {
        let portfolio: [Stock]
        if localPortfolio.isEmpty, let cloudPortfolio, !cloudPortfolio.isEmpty {
            portfolio = cloudPortfolio
        } else {
            portfolio = localPortfolio
        }

        let watchlist: [String]
        if localWatchlist.isEmpty, let cloudWatchlist, !cloudWatchlist.isEmpty {
            watchlist = cloudWatchlist
        } else {
            watchlist = localWatchlist
        }

        return Result(portfolio: portfolio, watchlist: watchlist)
    }
}
