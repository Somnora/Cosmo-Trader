# Today One-Glance Market Horoscope Polish Review

## Executive Verdict

APPROVED. PR #13 is safe to merge.

The branch `codex/today-one-glance-polish` exists, targets `main`, and is at `1dde218` or a direct descendant. GitHub reports the PR is open, mergeable, and its `iOS checks` workflow completed successfully. The diff is appropriately scoped to Today one-glance UX, Today summary/composer model updates, focused tests, and production guard anchors.

No HIGH or MEDIUM blockers were found.

## HIGH Findings

None.

## MEDIUM Findings

None.

## LOW Findings

None blocking.

Observed but not introduced by this PR:

- Clean Debug build still emits existing warnings in unrelated files:
  - `Cosmo Trader/Views/Referral/ReferralView.swift`
  - `Cosmo Trader/Views/Settings/InboxViews.swift`
  - `Cosmo Trader/Views/Tabs/DiscoverView.swift`
- Build also emits an AppIntents metadata warning because no AppIntents dependency is present. This is not caused by PR #13.

## UX Findings

PR #13 adds a real one-glance Today layer:

- `Cosmo Trader/Models/TodayMarketHoroscopeSummary.swift` adds `primaryAction`.
- `Cosmo Trader/Services/TodayMarketHoroscopeComposer.swift` computes `primaryAction` with the expected priority:
  - no portfolio prioritizes portfolio setup;
  - no watchlist prioritizes watchlist/search when market and portfolio are ready;
  - missing market history prioritizes market refresh when other lenses are ready.
- `Cosmo Trader/Views/Components/TodayMarketHoroscopeView.swift` renders the one-glance panel before detailed cards and uses `accessibilityIdentifier("today.oneGlanceRead")`.
- Detailed Market, Portfolio, and Stock sections suppress the same activation prompt when that prompt is already promoted in the one-glance panel, so the first viewport does not repeat the exact same CTA.
- The label guide remains collapsed and readable.
- The existing width system and bottom tab clearance are not changed by this PR.

The first viewport now clearly summarizes:

- Market Weather
- Portfolio context
- Stock/watchlist context
- data quality
- one primary next action

## Data, Provenance, And Compliance Findings

No new fake, mock, generated, sample, or placeholder market, portfolio, stock, quote, or history data was introduced.

The PR does not change the core data gates:

- Market Weather 100 percent SPY / QQQ / DIA / IWM basket gate remains intact.
- Portfolio 70 percent coverage gate remains intact.
- Stock, portfolio, market, cache, and Today provenance safeguards remain intact.

Compliance copy remains safe:

- No buy, sell, hold, take-profit, reduce-exposure, position-size, expected-upside, expected-downside, guaranteed, or predictive trading language was found in the changed Today copy.
- `Scripts/compliance_copy_guard.sh` passed.

`BuildInfo.generated.swift` and `SubscriptionManager.swift` have no diff.

## Test, Guard, And Build Results

GitHub:

- PR #13 exists and targets `main`.
- Branch: `codex/today-one-glance-polish`.
- Commit: `1dde218` or direct descendant.
- Merge state: clean.
- CI: green, `iOS checks` completed successfully.

Local verification:

- `xcodebuild -list -project "Cosmo Trader.xcodeproj"` passed.
- `bash Scripts/production_mock_guard.sh` passed.
- `bash Scripts/compliance_copy_guard.sh` passed.
  - Xcode's XCTest wrapper reported 0 XCTest cases, then Swift Testing ran the selected suite.
  - Swift Testing result: 4 tests in 1 suite passed.
  - This is not a selected-0 failure.
- Focused requested test command passed with nonzero Swift Testing coverage.
  - `TodayMarketHoroscopeComposerTests`
  - `MarketWeatherServiceTests`
  - `PortfolioCosmicCorrelationServiceTests`
  - `ProductionMockGuardTests`
  - `ComplianceCopyGuardTests`
  - Result: 56 tests in 5 suites passed.
- Clean Debug simulator build passed:
  - `xcodebuild -project "Cosmo Trader.xcodeproj" -scheme "Cosmo Trader" -configuration Debug -destination "generic/platform=iOS Simulator" CODE_SIGNING_ALLOWED=NO clean build`

No command selected 0 Swift Testing tests.

Worktree status after verification contains only untracked Markdown review artifacts. No untracked Swift files are required.

## Visual Smoke Result

Visual smoke artifacts exist at:

`/tmp/cosmo-today-one-glance-smoke/`

Screenshot index:

`/tmp/cosmo-today-one-glance-smoke/SCREENSHOT_INDEX.md`

Result:

- Initial `today-first-viewport.png` is correctly classified as a transient cold-launch blank frame and is not counted for judgment.
- Retry screenshot `today-first-viewport-retry.png` is marked `pass`.
- Retry shows the Today Market Horoscope header, Market / Portfolio / Stock snapshot cards, and the one-glance read / primary CTA panel before deeper detail sections.

## Merge Readiness

PR #13 can merge to `main`.

## Recommended Next PR

Provider History Activation For Holdings And Watchlist.

That is the next best step because Today now presents a clearer daily read and primary action, but users still need an obvious way to load provider-backed history for imported holdings and watchlist symbols so Today, Stock Correlation, and Portfolio Correlation can unlock without fake data.
