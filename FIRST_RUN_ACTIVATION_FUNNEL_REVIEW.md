# First-Run Activation Funnel Review

## Executive Verdict

PR #32, `End-To-End First-Run Activation Funnel Smoke`, is not merge-ready yet because GitHub Actions has not completed.

I found 0 HIGH code findings, 1 MEDIUM process blocker, and 0 LOW findings. Local verification passed, the PR is now based on `main`, and PR #31 is merged into `main`, so the branch is no longer stacked. If the in-progress GitHub `iOS checks` job completes green, I found no remaining blockers to merge.

## HIGH Findings

None.

## MEDIUM Findings

1. GitHub Actions is still in progress, so the required CI-green condition is not yet satisfied.
   - Path: GitHub Actions `iOS checks`
   - PR: https://github.com/Somnora/Cosmo-Trader/pull/32
   - Run: https://github.com/Somnora/Cosmo-Trader/actions/runs/27485835783/job/81241721321
   - Evidence: `gh pr view 32` reports `status: IN_PROGRESS`, `conclusion: ""`, and `mergeStateStatus: UNSTABLE`.
   - Impact: The PR should not merge until this check completes successfully.

## LOW Findings

None.

## First-Run Funnel Findings

- PR #32 exists, is open, targets `main`, and uses head branch `codex/first-run-activation-funnel-smoke`.
- PR #31 has merged into `main`; local history shows PR #32 rebased directly on `bdc30eb`, the PR #31 merge commit.
- Diff scope is limited to:
  - `Cosmo Trader/Views/Components/StockTechnicalAnalysisView.swift`
  - `Cosmo Trader/Views/Components/TodayMarketHoroscopeView.swift`
  - `Cosmo TraderTests/Services/FirstRunActivationFunnelSmokeTests.swift`
  - `Scripts/production_mock_guard.sh`
- The production app source changes are stable accessibility anchors only:
  - `today.activation...`
  - `stock.technicalAnalysis`
  - `stock.technicalAnalysis.refreshHistory`
- The new smoke tests cover:
  - Today first-run no-data state,
  - Today CTA routing to portfolio add, portfolio import, and Discover search,
  - portfolio import persistence,
  - watchlist persistence,
  - provider-history loading through `HistoricalPriceService.testingInstance`,
  - no sample-data fallback during provider-history load,
  - insufficient-history locked state for Stock Detail correlation and technical context,
  - provider-backed unlock state only when provenance, completeness, and sample gates allow it,
  - first-run copy staying context-only and non-advisory.

## Data, Provenance, And Compliance Findings

- No fake holding, quote, price, movement, history, or generated production candles were introduced.
- Provider-shaped candles are generated only inside the test file for controlled service coverage.
- Missing history is framed through unavailable/provider-backed-history language, not as a user error.
- Source/freshness/completeness label coverage remains anchored through `DataSourceIndicator` guard checks and existing UI surfaces.
- Market Weather 100% basket gate remains intact.
- Portfolio 70% coverage gate remains intact.
- Stock correlation gates remain intact.
- Stock technical-analysis gates remain intact.
- `BuildInfo.generated.swift` has no diff.
- `SubscriptionManager.swift` has no diff.
- No untracked Swift files are required.

## Test, Guard, And Build Results

- `xcodebuild -list -project "Cosmo Trader.xcodeproj"`: passed.
- `bash Scripts/production_mock_guard.sh`: passed.
- `bash Scripts/compliance_copy_guard.sh`: passed with 5 Swift Testing tests.
- Focused selector passed with 76 Swift Testing tests across 8 suites:
  - `FirstRunActivationFunnelSmokeTests`
  - `TodayMarketHoroscopeComposerTests`
  - `PortfolioImportCommitTests`
  - `HistoricalPriceCacheTests`
  - `AstroCorrelationServiceTests`
  - `StockTechnicalAnalysisServiceTests`
  - `ProductionMockGuardTests`
  - `ComplianceCopyGuardTests`
- Clean Debug simulator build passed:
  - `xcodebuild -project "Cosmo Trader.xcodeproj" -scheme "Cosmo Trader" -configuration Debug -destination "generic/platform=iOS Simulator" CODE_SIGNING_ALLOWED=NO clean build`
- No selected-zero test result was accepted. Xcode printed normal XCTest harness `Executed 0 tests` lines, but Swift Testing executed nonzero selected tests.

## Screenshot Index Result

Screenshot index exists at:

`/tmp/cosmo-first-run-activation-funnel-smoke/SCREENSHOT_INDEX.md`

The index accurately states that screenshots were not captured and marks the requested surfaces as `not reachable`. It explains that this PR is test/guard focused and lacks a deterministic UI-test seed/provider path for full visual capture. No screenshots were committed.

## Merge Readiness

PR #32 should not merge until GitHub Actions completes green.

If the current `iOS checks` run completes successfully, this PR can merge from a code, data-provenance, compliance, and local verification standpoint.

## Recommended Next PR

After PR #32 merges, the next high-value follow-up is a deterministic UI-test fixture or visual-smoke seed path for first-run activation states so Today, Portfolio, Discover, Stock Detail locked states, and provider-backed unlock states can be captured visually without production fake data.
