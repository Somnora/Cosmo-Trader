# Data Activation Today Review

## Executive Verdict

PR #4, `Data Activation And First-Run Value For Today`, exists, targets `main`, and is now materially within scope. The latest head is `9f826b230c2f53b30229da0638ea88a3c957a72c` on `codex/data-activation-today`.

Verdict: safe to merge after normal reviewer approval. I found no HIGH or MEDIUM blockers.

The earlier concern that the PR only changed Discover sample display is resolved. The actual diff now includes Today activation model/composer updates, Today SwiftUI activation prompts, route wiring, data label explainers, tests, and production guard anchors, in addition to Discover sample-display polish.

## Findings

### HIGH

None.

### MEDIUM

None.

### LOW

1. Portfolio CTAs route to existing tabs rather than deep-linking into separate manual add/import flows.
   - Files: `Cosmo Trader/Views/Settings/DailyBriefBackendView.swift`, `Cosmo Trader/Services/TodayMarketHoroscopeComposer.swift`
   - Evidence: Today lists both "Add holding manually" and "Import portfolio", and the primary action routes to the Portfolio tab. This satisfies the low-risk navigation requirement, but future UX should deep-link directly to manual add and import when those routes are stable.
   - Risk: minor activation friction, not a trust or data integrity issue.

2. Clean build still emits pre-existing warnings unrelated to PR #4.
   - Files: `Cosmo Trader/Views/Referral/ReferralView.swift`, `Cosmo Trader/Views/Settings/InboxViews.swift`, `Cosmo Trader/Views/Tabs/DiscoverView.swift`
   - Evidence: unused `error`, unused `publishTestInboxItem()` result, and deprecated `onChange(of:perform:)`.
   - Risk: housekeeping only. Build succeeded.

## UX Activation Findings

Market Weather activation is present and clear.
- `Cosmo Trader/Services/TodayMarketHoroscopeComposer.swift:58` returns a Market Weather unavailable state when SPY, QQQ, DIA, and IWM history is missing.
- `Cosmo Trader/Services/TodayMarketHoroscopeComposer.swift:529` defines activation prompts for partial, stale, insufficient, unavailable, and sample-only market states.
- `Cosmo Trader/Services/TodayMarketHoroscopeComposer.swift:570` adds "Fetch provider-backed market history" with "Fetch SPY / QQQ / DIA / IWM history" and "Do not create sample market data."
- `Cosmo Trader/Views/Components/TodayMarketHoroscopeView.swift:297` shows a loading row while provider/cache history is refreshing.
- `Cosmo Trader/Views/Settings/DailyBriefBackendView.swift:25` wires the market refresh action to `todayViewModel.reload(user:)`.

Portfolio activation is present.
- `Cosmo Trader/Services/TodayMarketHoroscopeComposer.swift:104` detects no owned holdings and returns setup-required context with no metrics.
- `Cosmo Trader/Services/TodayMarketHoroscopeComposer.swift:600` lists "Add holding manually", "Import portfolio", and "Add watchlist symbols."
- `Cosmo Trader/Views/Settings/DailyBriefBackendView.swift:30` routes the portfolio setup action to the Portfolio tab.

Watchlist/stock activation is present.
- `Cosmo Trader/Services/TodayMarketHoroscopeComposer.swift:639` defines stock activation prompts.
- `Cosmo Trader/Services/TodayMarketHoroscopeComposer.swift:647` shows "Add a stock to watch" when no candidate exists.
- `Cosmo Trader/Services/TodayMarketHoroscopeComposer.swift:659` lists "Add symbol", "Open Discover/Search", and "Provider-backed stock history unlocks this lens."
- `Cosmo Trader/Views/Settings/DailyBriefBackendView.swift:33` routes the watchlist setup action to Discover.

Data label explainer is present and understandable.
- `Cosmo Trader/Services/TodayMarketHoroscopeComposer.swift:681` defines labels for Unavailable, Sample data, Stored data, Cached/stale, Partial, and Insufficient.
- `Cosmo Trader/Views/Components/TodayMarketHoroscopeView.swift:658` renders the visible "LABEL GUIDE."

Blank black screen classification: guarded as a transient loading state.
- `Cosmo Trader/Views/Components/TodayMarketHoroscopeView.swift:48` renders a loading shell with "Loading today's provider-backed context."
- This should prevent a truly blank Today surface during load. I did not reproduce a real blank-screen bug in static review or build verification.

Today/Cosmos width system is preserved.
- `Cosmo Trader/Views/Settings/DailyBriefBackendView.swift:48` still uses `AppLayout.screenHorizontalPadding`.
- This PR does not modify `ProfileView`, `CosmosView`, or `AppLayout`.

## Data, Provenance, And Compliance Findings

Market refresh uses real provider/cache loading only.
- `Cosmo Trader/Views/Settings/DailyBriefBackendView.swift:25` calls `todayViewModel.reload(user:)`.
- The view model loads Market Weather through `MarketWeatherService.loadSummary`, which uses `CorrelationDatasetStore.datasets`.
- `Cosmo Trader/Services/MarketWeatherService.swift:77` requests datasets from the dataset store for the V1 market basket.

The 100% Market Weather basket gate remains intact.
- `Cosmo Trader/Services/MarketWeatherService.swift:49` limits V1 scope to SPY, QQQ, DIA, and IWM.
- `Cosmo Trader/Services/MarketWeatherService.swift:65` keeps `requiredCoverageForAnyContext = 0.5`.
- `Cosmo Trader/Services/MarketWeatherService.swift:66` keeps `requiredCoverageForNumericClaims = 1.0`.
- `Cosmo Trader/Services/MarketWeatherService.swift:223` withholds numeric market metrics below full basket coverage.

No market fake/sample data creation was introduced.
- `Cosmo Trader/Services/TodayMarketHoroscopeComposer.swift:80` only emits market metrics when `displayMode == .marketBacked`.
- `Cosmo Trader/Services/TodayMarketHoroscopeComposer.swift:576` explicitly tells the activation state not to create sample market data.
- `Scripts/production_mock_guard.sh:177` and `Scripts/production_mock_guard.sh:178` reject `Double.random` and `generateMock` in the Today composer.

Portfolio 70% coverage gate remains intact.
- `Cosmo Trader/Services/TodayMarketHoroscopeComposer.swift:6` keeps `numericPortfolioCoverageThreshold = 0.70`.
- `Scripts/production_mock_guard.sh:152` anchors this threshold.
- `Cosmo TraderTests/Services/TodayMarketHoroscopeComposerTests.swift:157` verifies exactly 70% can render, while lower coverage tests verify no metrics.

Discover sample movement no longer looks like live provider performance.
- `Cosmo Trader/ViewModels/DiscoverViewModel.swift:60` documents the sample discovery universe and requires visible sample labeling until provider enrichment exists.
- `Cosmo Trader/Views/Components/StockCardView.swift:268` drives price movement from `priceMoveDisplay`.
- `Cosmo TraderTests/Services/DiscoverSampleDisplayTests.swift:6` verifies sample moves show "Sample quote", neutral tone, no percent label, and not provider performance.
- `Cosmo TraderTests/Services/DiscoverSampleDisplayTests.swift:19` verifies unavailable quotes show "Quote unavailable", neutral tone, and no percent label.

No advice-like copy was introduced.
- The Today disclaimer remains historical and non-advice: `Cosmo Trader/Services/TodayMarketHoroscopeComposer.swift:54`.
- Compliance guard passed with 4 Swift Testing tests.

BuildInfo and SubscriptionManager were not changed.
- `git diff --name-only origin/main...HEAD -- "Cosmo Trader/BuildInfo.generated.swift" "Cosmo Trader/Services/SubscriptionManager.swift"` returned no files.

No untracked Swift files are required.
- Current untracked files are review artifacts only: `MARKET_WEATHER_MVP_REVIEW.md` and `TODAY_REGRESSION_GUARDS_REVIEW.md`.

## Test, Guard, And Build Results

GitHub PR state:
- PR: `https://github.com/Somnora/Cosmo-Trader/pull/4`
- Base: `main`
- Head: `codex/data-activation-today`
- Head SHA: `9f826b230c2f53b30229da0638ea88a3c957a72c`
- Merge state: `CLEAN`
- GitHub Actions: `iOS checks` completed with `SUCCESS`

Diff scope:
- `Cosmo Trader/Models/TodayMarketHoroscopeSummary.swift`
- `Cosmo Trader/Services/TodayMarketHoroscopeComposer.swift`
- `Cosmo Trader/ViewModels/DiscoverViewModel.swift`
- `Cosmo Trader/Views/Components/StockCardView.swift`
- `Cosmo Trader/Views/Components/TodayMarketHoroscopeView.swift`
- `Cosmo Trader/Views/Settings/DailyBriefBackendView.swift`
- `Cosmo TraderTests/Services/DiscoverSampleDisplayTests.swift`
- `Cosmo TraderTests/Services/TodayMarketHoroscopeComposerTests.swift`
- `Scripts/production_mock_guard.sh`

Local verification:
- `xcodebuild -list -project "Cosmo Trader.xcodeproj"`: passed.
- `bash Scripts/production_mock_guard.sh`: passed.
- `bash Scripts/compliance_copy_guard.sh`: passed, with 4 Swift Testing tests.
- Focused command for `TodayMarketHoroscopeComposerTests`, `DiscoverSampleDisplayTests`, and `MarketWeatherServiceTests`: passed, with 26 Swift Testing tests in 3 suites.
- Clean Debug simulator build: passed.

Selected-zero status:
- No command selected 0 Swift Testing tests.
- Xcode's XCTest wrapper prints "Executed 0 tests" for Swift Testing suites, but the Swift Testing runner immediately executed 4 compliance tests and 26 focused tests successfully.

Build warnings:
- Pre-existing warnings remain in `ReferralView.swift`, `InboxViews.swift`, and `DiscoverView.swift`.
- No BuildInfo noise was introduced.

## Merge Readiness

PR #4 can merge. The implementation now covers the missing Today activation scope, preserves the market and portfolio gates, avoids fake data, keeps compliance copy safe, and passes local and GitHub verification.

## Recommended Next PR

After merge, the next PR should be a visual smoke and small UX polish pass for the activation states on device. Specifically verify button affordance, label guide density, and whether Portfolio/Discover routing is sufficient or should become deep links into manual add, import, and search flows.
