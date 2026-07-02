# Chart Visual QA And Snapshot Coverage Review

## Executive Verdict

PR #22 is safe to merge.

The PR is limited to chart/astro overlay test coverage and `production_mock_guard.sh` anchors. No production app source, screenshots, `SubscriptionManager.swift`, or `BuildInfo.generated.swift` changed. GitHub Actions is green, local guards pass, focused Swift Testing suites ran with nonzero counts, and the clean Debug simulator build succeeded.

## HIGH Findings

None.

## MEDIUM Findings

None.

## LOW Findings

1. Visual smoke coverage is still limited by launch hooks.
   - Evidence: `/tmp/cosmo-chart-visual-qa/SCREENSHOT_INDEX.md`
   - The available Stock Detail astro overlay screenshot route passed, but unavailable chart, provider-backed chart fixture, selected marker/crosshair, and small-screen layout states were marked `not reachable`.
   - Risk: future visual regressions in those states still depend on unit tests and string guards rather than deterministic screenshots.
   - Recommendation: add a future UI-test or preview harness that can launch each chart state deterministically.

2. Clean build still emits unrelated pre-existing warnings.
   - Evidence: local clean Debug build output.
   - Warnings were in production files outside the PR diff, including `ReferralView.swift`, `InboxViews.swift`, and `DiscoverView.swift`.
   - Risk: low. The PR did not touch those files and the build succeeded.
   - Recommendation: handle in a separate warning cleanup PR if the team wants a warning-free baseline.

## Diff Scope

Diff against `origin/main` is limited to:

- `Cosmo TraderTests/Services/AstroCorrelationServiceTests.swift`
- `Cosmo TraderTests/Services/AstroOverlayEventServiceTests.swift`
- `Cosmo TraderTests/Services/ComplianceCopyGuardTests.swift`
- `Cosmo TraderTests/Services/ProductionMockGuardTests.swift`
- `Scripts/production_mock_guard.sh`

Confirmed absent from the PR diff:

- Production app source changes
- Screenshot/image files
- `Cosmo Trader/Services/SubscriptionManager.swift`
- `Cosmo Trader/BuildInfo.generated.swift`
- Fake/generated chart data
- Provenance gate changes

## Guard Behavior

`production_mock_guard.sh` now anchors chart and astro overlay protections for:

- Stock chart provider loading path
- Chart provenance/source labels
- Unavailable chart copy
- Historical dataset completeness
- Astro marker rendering
- Scrub/crosshair selection helpers
- Chart-specific guard tests

The added tests cover:

- Empty historical datasets
- Insufficient candles
- Stale cached candles
- Partial provider-backed candles
- Sample provenance blocking chart correlation metrics
- Astro overlay marker kinds and icon metadata
- Chart/astro overlay copy compliance

## Test / Guard / Build Results

GitHub PR state:

- PR #22 exists and targets `main`.
- Head branch: `codex/chart-visual-qa-snapshot-coverage`
- Merge state: `CLEAN`
- CI: `iOS checks` completed with `SUCCESS`

Local verification:

- `xcodebuild -list -project "Cosmo Trader.xcodeproj"`: passed
- `bash Scripts/production_mock_guard.sh`: passed
- `bash Scripts/compliance_copy_guard.sh`: passed with 5 Swift Testing tests
- Focused chart/correlation tests: passed with 51 Swift Testing tests across 5 suites
- Clean Debug simulator build: passed

Focused test selector used:

```bash
xcodebuild test \
  -project "Cosmo Trader.xcodeproj" \
  -scheme "Cosmo Trader" \
  -destination "platform=iOS Simulator,name=iPhone 17 Pro" \
  -parallel-testing-enabled NO \
  -maximum-concurrent-test-simulator-destinations 1 \
  -only-testing:"Cosmo TraderTests/AstroCorrelationServiceTests" \
  -only-testing:"Cosmo TraderTests/AstroOverlayEventServiceTests" \
  -only-testing:"Cosmo TraderTests/HistoricalAstroChartViewModelHelperTests" \
  -only-testing:"Cosmo TraderTests/ProductionMockGuardTests" \
  -only-testing:"Cosmo TraderTests/ComplianceCopyGuardTests"
```

Swift Testing executed 51 tests. The XCTest wrapper printed `Executed 0 tests`, but Swift Testing selected and ran the requested suites, so this was not a selected-0 failure.

Infrastructure note:

- An initial parallel Xcode run caused a generated `DerivedData/SourcePackages` checkout error.
- Generated Xcode DerivedData was removed, then checks were rerun sequentially and passed.

## Visual Smoke Findings

Screenshot index:

`/tmp/cosmo-chart-visual-qa/SCREENSHOT_INDEX.md`

Passing screenshots:

- `01-stock-detail-astro-overlay.png`
- `02-stock-detail-astro-overlay-repeat.png`

Not reachable with current deterministic launch hooks:

- Stock Detail unavailable chart
- Provider-backed chart fixture state
- Selected marker/crosshair state
- Small-screen layout

No screenshots were committed.

## Merge Readiness

PR #22 can merge.

There are no HIGH or MEDIUM blockers. The remaining LOW items are coverage-depth and cleanup follow-ups, not trust, provenance, fake-data, or compliance blockers.

## Recommended Next PR

Provider-Backed Stock Technical Analysis MVP.

That PR should build on this chart guard baseline by adding provider-backed moving averages, RSI, volume trend, volatility context, recent range, and defensible support/resistance candidates on Stock Detail, with source/freshness/completeness labels and no trading-instruction copy.
