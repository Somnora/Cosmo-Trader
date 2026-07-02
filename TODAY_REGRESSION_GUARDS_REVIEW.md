# Today Regression Guards Review

## Executive Verdict

Verdict: PASS.

The updated `codex/today-regression-guards-cleanup` branch is the correct branch under review. PR #1 is open against `main`, merge-clean, and its title and body clearly identify the cleanup scope: Today-specific production guard anchors, focused Today coverage tests, and deletion of the legacy `DailyBriefView` surface.

No HIGH or MEDIUM findings remain. The PR can merge to `main`.

Market-Level Correlation MVP can be pushed and reviewed next after this PR lands or after that branch is rebased onto the merged cleanup. Market Weather was not merged into this PR.

## HIGH Findings

None.

## MEDIUM Findings

None.

## LOW Findings

None blocking.

The clean Debug build still emits pre-existing warnings outside this PR:

- `Cosmo Trader/Views/Referral/ReferralView.swift:372`: unused `error`.
- `Cosmo Trader/Views/Settings/InboxViews.swift:134`: unused result from `publishTestInboxItem()`.
- `Cosmo Trader/Views/Tabs/DiscoverView.swift:129`: deprecated `onChange(of:perform:)`.
- AppIntents metadata extraction warning: no AppIntents framework dependency found.

These are outside the PR diff and are not introduced by this cleanup.

## Branch And PR State

- PR: `https://github.com/Somnora/Cosmo-Trader/pull/1`
- Title: `Harden Today Regression Guards And Clean Up Legacy Daily Brief Surface`
- Head branch: `codex/today-regression-guards-cleanup`
- Base branch: `main`
- PR state: open
- Merge state: clean
- Current local branch: `codex/today-regression-guards-cleanup`
- Local head: `27c8125 Harden Today guard coverage tests`
- Prior cleanup commit still included: `f0459b9 Harden Today regression guards`
- `origin/main`: `a45136e Run iOS CI on macOS 26`
- `origin/main` is an ancestor of the PR branch.

PR diff from `origin/main..HEAD` is limited to:

- Deleted `Cosmo Trader/Views/Tabs/DailyBriefView.swift`
- Modified `Cosmo TraderTests/Services/TodayMarketHoroscopeComposerTests.swift`
- Modified `Scripts/production_mock_guard.sh`

No `SubscriptionManager` changes, no `BuildInfo.generated.swift` diff, and no Market Weather files are present in this PR.

## Guard Behavior

`Scripts/production_mock_guard.sh` now directly anchors the Today regression surface:

- `Scripts/production_mock_guard.sh:103` requires legacy `Cosmo Trader/Views/Tabs/DailyBriefView.swift` to stay absent.
- `Scripts/production_mock_guard.sh:104` through `Scripts/production_mock_guard.sh:111` require `TodayMarketHoroscopeSummary`, portfolio context, stock context, data coverage, and Today display modes including setup, partial, insufficient, and sample states.
- `Scripts/production_mock_guard.sh:112` through `Scripts/production_mock_guard.sh:115` require Today tab integration through `DailyBriefBackendView`, `TodayMarketHoroscopeView`, and load/reload calls.
- `Scripts/production_mock_guard.sh:116` through `Scripts/production_mock_guard.sh:119` require `TodayMarketHoroscopeViewModel`, portfolio summary loading, stock candidate loading, and `CorrelationDatasetStore.shared`.
- `Scripts/production_mock_guard.sh:120` through `Scripts/production_mock_guard.sh:124` require `TodayMarketHoroscopeComposer` and its portfolio, stock, and data coverage composition paths.
- `Scripts/production_mock_guard.sh:125` through `Scripts/production_mock_guard.sh:132` require the SwiftUI Today surface, stable accessibility identifier, Today section headers, `DataSourceIndicator` usage, and data coverage display.
- `Scripts/production_mock_guard.sh:133` through `Scripts/production_mock_guard.sh:137` require metric rendering to be gated, the 70 percent portfolio threshold to remain anchored, and portfolio and stock metrics to require `.marketBacked`.
- `Scripts/production_mock_guard.sh:138` through `Scripts/production_mock_guard.sh:142` anchor non-advice and unavailable-state copy.
- `Scripts/production_mock_guard.sh:143` through `Scripts/production_mock_guard.sh:148` require focused Today tests for no portfolio, below 50 percent coverage, 50 to 70 percent partial context, exactly 70 percent coverage, stale and partial datasets, and safe copy.
- `Scripts/production_mock_guard.sh:149` through `Scripts/production_mock_guard.sh:150` block `Double.random` and `generateMock` in the Today composer.

The guard does not over-block legal disclaimers. `Scripts/compliance_copy_guard.sh` passed, and `Cosmo TraderTests/Services/ComplianceCopyGuardTests.swift` includes a narrow allowlist test for copy such as `This is not a buy or sell recommendation.`

## Today Test Coverage

`Cosmo TraderTests/Services/TodayMarketHoroscopeComposerTests.swift` now directly covers the requested Today composer scenarios:

- `Cosmo TraderTests/Services/TodayMarketHoroscopeComposerTests.swift:54` tests no portfolio.
- `Cosmo TraderTests/Services/TodayMarketHoroscopeComposerTests.swift:78` tests below 50 percent portfolio coverage.
- `Cosmo TraderTests/Services/TodayMarketHoroscopeComposerTests.swift:109` tests 50 to 70 percent partial context.
- `Cosmo TraderTests/Services/TodayMarketHoroscopeComposerTests.swift:140` tests exactly 70 percent gated metric rendering.
- `Cosmo TraderTests/Services/TodayMarketHoroscopeComposerTests.swift:194` tests stale cache, partial dataset, insufficient dataset, and unavailable dataset coverage.
- `Cosmo TraderTests/Services/TodayMarketHoroscopeComposerTests.swift:171` tests sample and unavailable stock context cannot produce numeric metrics.
- `Cosmo TraderTests/Services/TodayMarketHoroscopeComposerTests.swift:232` tests safe copy and cosmic-only fallback language.

These tests directly cover the previous MEDIUM gaps.

## Daily Brief Surface

The legacy `Cosmo Trader/Views/Tabs/DailyBriefView.swift` deletion is safe.

Evidence:

- The PR deletes `Cosmo Trader/Views/Tabs/DailyBriefView.swift`.
- `Cosmo Trader/Views/ContentView.swift:39` routes the Today tab to `DailyBriefBackendView()`.
- `Cosmo Trader/Views/Settings/DailyBriefBackendView.swift:18` owns `TodayMarketHoroscopeViewModel`.
- `Cosmo Trader/Views/Settings/DailyBriefBackendView.swift:23` renders `TodayMarketHoroscopeView(viewModel:)`.
- Repository search for `DailyBriefView` now finds only the production guard requirement that the legacy file remain absent.

Today behavior was not changed beyond guard/test-safe cleanup and removal of the unused legacy surface. The PR does not touch `TodayMarketHoroscopeComposer.swift`, `TodayMarketHoroscopeViewModel.swift`, `TodayMarketHoroscopeView.swift`, `DailyBriefBackendView.swift`, or `ContentView.swift`.

## Regression Safeguards

Stock correlation safeguards still pass:

- `Cosmo TraderTests/AstroCorrelationServiceTests` ran in the focused regression command.
- Provider-backed sufficiency, unavailable provenance, sample provenance, partial dataset, and insufficient dataset gates passed.

Portfolio correlation safeguards still pass:

- `Cosmo TraderTests/PortfolioCosmicCorrelationServiceTests` ran in the focused regression command.
- Below-threshold coverage, partial coverage, exactly 50 percent, exactly 70 percent, mixed provenance, partial datasets, insufficient datasets, sample-size gating, V1 event scope, and safe copy passed.

Cache/completeness safeguards still pass:

- `Cosmo TraderTests/HistoricalPriceCacheTests` and `Cosmo TraderTests/FinancialDataProvenanceTests` ran in the focused regression command.
- Fresh cache, stale cache, partial quality, unavailable symbols, and mixed provenance behavior passed.

Compliance and production mock safeguards still pass:

- `bash Scripts/production_mock_guard.sh`: passed.
- `bash Scripts/compliance_copy_guard.sh`: passed.
- `Cosmo TraderTests/ProductionMockGuardTests`: passed.
- `Cosmo TraderTests/ComplianceCopyGuardTests`: passed.

No fake/mock/generated financial data or advice-like copy was reintroduced.

## Test, Guard, And Build Results

Commands run:

- `xcodebuild -list -project "Cosmo Trader.xcodeproj"`: passed.
- `bash Scripts/production_mock_guard.sh`: passed.
- `bash Scripts/compliance_copy_guard.sh`: passed, including 4 Swift Testing tests.
- Focused regression tests:
  - Command included `TodayMarketHoroscopeComposerTests`, `ProductionMockGuardTests`, `ComplianceCopyGuardTests`, `AstroCorrelationServiceTests`, `PortfolioCosmicCorrelationServiceTests`, `HistoricalPriceCacheTests`, and `FinancialDataProvenanceTests`.
  - Result: passed, 61 Swift Testing tests in 7 suites.
- Clean Debug simulator build:
  - `xcodebuild -project "Cosmo Trader.xcodeproj" -scheme "Cosmo Trader" -configuration Debug -destination "generic/platform=iOS Simulator" CODE_SIGNING_ALLOWED=NO clean build`
  - Result: passed.

No command selected 0 tests as a passing result. Xcode still prints an initial legacy XCTest wrapper line with `Executed 0 tests`, but Swift Testing then executed the selected suites: 4 tests in the compliance guard and 61 tests in the broader focused regression command.

## Worktree And BuildInfo

- No untracked Swift files are present.
- `BuildInfo.generated.swift` has no diff.
- Current untracked non-source file after this review: `TODAY_REGRESSION_GUARDS_REVIEW.md`.

## Market Weather Separation

Market Weather was not merged into this PR.

Evidence:

- `git diff --name-status origin/main..HEAD` lists only `DailyBriefView.swift`, `TodayMarketHoroscopeComposerTests.swift`, and `production_mock_guard.sh`.
- Local branch `codex/market-weather-mvp` exists at `fc36455 Build market weather MVP`.
- `git ls-remote --heads origin codex/market-weather-mvp` returned no remote branch.

## Merge Recommendation

This PR can merge to `main`.

It resolves the previous branch-identification issue by making `codex/today-regression-guards-cleanup` the explicit PR branch, expands Today production guard anchors, adds direct Today composer coverage for no portfolio, below 50 percent, 50 to 70 percent, and exactly 70 percent cases, preserves source/freshness and non-advice safeguards, and leaves Market Weather out of scope.

## Next Step

After this PR lands, Market-Level Correlation MVP can be pushed and reviewed next as a separate PR. Rebase the local `codex/market-weather-mvp` branch onto updated `main` first so Claude reviews only the market-level changes.
