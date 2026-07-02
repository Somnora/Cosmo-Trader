# Line And Candle Chart Mode Review

## Executive Verdict

PR #25 is not ready to merge.

The implementation is well scoped to chart mode selection, astro overlay preservation, tests, and production guard anchors. Line mode remains the default, source/freshness labels remain visible, no fake chart data was introduced, and the clean Debug build passed.

However, there is one HIGH trust blocker: candle mode currently allows stale cached complete OHLC candles beyond the app's default stale policy. The user requirement explicitly says stale-beyond-policy data cannot render candle mode. The new tests also encode the wrong behavior by asserting that 48-hour cached candles are eligible.

## HIGH Findings

### 1. Stale cached OHLC data can still render candle mode

Files:

- `Cosmo Trader/Views/Components/StockChartView.swift:41`
- `Cosmo Trader/Models/FinancialDataProvenance.swift:11`
- `Cosmo Trader/Models/FinancialDataProvenance.swift:45`
- `Cosmo TraderTests/Services/AstroOverlayEventServiceTests.swift:357`
- `Cosmo TraderTests/Services/ProductionMockGuardTests.swift:86`

`StockChartCandleEligibility.canRenderCandles` only checks that provenance is provider-backed and completeness is `.complete`:

- `provenance.isProviderBacked` returns true for both `.live` and `.cached`.
- `FinancialDataProvenance.defaultCachedStaleInterval` is 24 hours.
- `FinancialDataProvenance.isCachedStale(...)` exists but is not used by the candle-mode gate.

The tests explicitly allow 48-hour cached complete candles:

- `AstroOverlayEventServiceTests.candleModeRequiresCompleteProviderBackedOHLC`
- `ProductionMockGuardTests.candleModeRequiresNonSampleCompleteOHLC`

Impact:

This violates the PR requirement that stale-beyond-policy cached data cannot render candle mode. It is a trust/provenance bug because candle charts visually imply complete OHLC precision. Stale line charts may still be acceptable with a clear cached/stale label, but candle mode should not be available when the dataset is stale beyond policy.

Recommended fix:

- Update `StockChartCandleEligibility.canRenderCandles` to reject stale cached provenance, for example by using `!provenance.isCachedStale()`.
- Add a test that fresh cached complete OHLC can render if that is the intended policy.
- Add a test that 48-hour cached complete OHLC cannot render candle mode under the default 24-hour stale policy.
- Keep line mode available with the existing source/freshness label if stale chart display remains allowed elsewhere.

## MEDIUM Findings

None.

## LOW Findings

### 1. Chart visual QA could not reach the actual chart surfaces

Requested visual screenshots were partially attempted outside the repo at:

- `/tmp/cosmo-line-candle-chart-qa/SCREENSHOT_INDEX.md`
- `/tmp/cosmo-line-candle-chart-qa/app-launch.png`
- `/tmp/cosmo-line-candle-chart-qa/app-launch-after-wait.png`

The simulator launched and reached Today, but no reliable stock-detail route with provider-backed complete OHLC history was available in this read-only review environment. Chart-specific screenshots were marked `not reachable` instead of overclaimed.

This is not a merge blocker by itself, but the visual pass should be repeated after the stale gate is fixed using a seeded provider-backed OHLC fixture or a known stock-detail route with complete non-stale history.

## Chart Behavior Findings

- PR #25 exists and targets `main`.
- Branch under review: `codex/line-candle-chart-mode`.
- Head commit observed locally: `42b7c41 Add line and candle chart mode toggle`.
- GitHub merge state is `CLEAN`.
- GitHub Actions `iOS checks` completed successfully.
- Diff is limited to chart mode toggle, astro overlay preservation, tests, and production guard anchors.
- `StockDetailView` initializes `selectedChartDisplayMode` as `.line`, so line mode remains default.
- `StockChartCandleEligibility.validCandles` rejects invalid OHLC shapes, non-finite values, non-positive OHLC values, and close-only flat candles where high equals low.
- Candle mode is gated on provider-backed provenance and `.complete` historical dataset completeness.
- Sample, unavailable, partial, insufficient, unsafe mixed, and close-only synthetic candles are blocked by the current implementation and tests.
- Stale-beyond-policy cached data is not blocked, which is the HIGH finding above.

## Astro Overlay Preservation Findings

Static review shows the astro overlay structure is preserved in `HistoricalAstroChartView`:

- Full Moon and New Moon point markers remain layered over the price chart.
- Mercury Retrograde range bands remain rendered with `RectangleMark`.
- Selected event vertical line remains rendered.
- Event strip remains below the chart.
- Scrub/crosshair selection remains in the chart overlay.
- Source/freshness/completeness labels remain visible through `DataSourceIndicator`.

Focused tests also cover marker helper behavior and overlay independence from chart display mode.

## Data, Provenance, And Compliance Findings

- No fake/generated chart data was introduced in the PR diff.
- No new advice-like copy was found.
- `SubscriptionManager.swift` has no diff.
- `BuildInfo.generated.swift` has no diff.
- No untracked Swift files are required for build/test success.
- Production mock guard passed locally.
- Compliance guard selected the intended suite but failed locally because the simulator test runner died before establishing a test connection. This was an infrastructure failure, not selected-zero. GitHub Actions is green.

## Test, Guard, And Build Results

Commands run:

- `git fetch origin`: passed.
- `gh pr view 25 --json ...`: passed, PR open, base `main`, head `codex/line-candle-chart-mode`, CI green.
- `git checkout codex/line-candle-chart-mode`: passed.
- `git status --short`: only untracked review artifacts, no untracked Swift files.
- `git diff --stat origin/main...HEAD`: 8 files changed, scoped to chart mode, overlay view/model, tests, and guard script.
- `xcodebuild -list -project "Cosmo Trader.xcodeproj"`: passed.
- `bash Scripts/production_mock_guard.sh`: passed.
- `bash Scripts/compliance_copy_guard.sh`: local simulator infrastructure failure before test connection, not selected-zero.
- Focused `HistoricalAstroChartViewModelHelperTests`: 10 Swift Testing tests passed.
- Focused `AstroCorrelationServiceTests`: 17 Swift Testing tests passed.
- Focused `ProductionMockGuardTests`: 11 Swift Testing tests passed.
- Clean Debug simulator build: passed.

No command selected zero Swift Testing tests. Some Xcode legacy XCTest summaries printed `Executed 0 tests`, but the Swift Testing runner reported nonzero test counts for the focused suites above.

## Visual QA Findings

Screenshot folder:

- `/tmp/cosmo-line-candle-chart-qa/`

Captured:

- `app-launch.png`: initial app splash/loading frame.
- `app-launch-after-wait.png`: Today screen after launch.

Requested chart-specific states were marked `not reachable` in `SCREENSHOT_INDEX.md` because the review environment did not have a reliable route to a stock chart with complete non-stale provider-backed OHLC candles.

## Merge Recommendation

Do not merge PR #25 yet.

The stale cached candle gate should be fixed first, and the tests should be updated so stale-beyond-policy cached OHLC cannot render candle mode.

## Recommended Next PR

Small blocker repair:

`Fix Candle Mode Stale Cache Gate`

Scope:

- Reject stale cached provenance in `StockChartCandleEligibility.canRenderCandles`.
- Update chart/guard tests to assert 48-hour cached data is not candle-eligible under the default 24-hour policy.
- Preserve line mode and all astro overlays.
- Rerun focused chart/correlation/compliance tests, production mock guard, and clean Debug build.
- Repeat visual QA with a provider-backed complete non-stale OHLC fixture if available.
