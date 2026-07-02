# Market Weather Sector Breadth Review

## Executive Verdict

PR #12, `Market Weather 2.0 With Sector Breadth Context`, is safe to merge after normal review approval. I found 0 HIGH and 0 MEDIUM blockers.

The PR exists, targets `main`, has a clean merge state, and GitHub Actions passed. The implementation keeps the V1 `SPY` / `QQQ` / `DIA` / `IWM` Market Weather basket gate intact, adds sector breadth as a separate optional layer, and withholds sector numeric claims unless all sector coverage, provenance, freshness, completeness, and sample-size gates pass.

## HIGH Findings

None.

## MEDIUM Findings

None.

## LOW Findings

1. Static UX review only for density and readability.
   - Files: `Cosmo Trader/Views/Components/TodayMarketHoroscopeView.swift`, `Cosmo Trader/Views/Tabs/CosmosView.swift`
   - The Today sector row is concise and the Cosmos panel is reasonably separated from core Market Weather in code, but I did not capture fresh screenshots in this review. A post-merge visual QA pass should confirm the sector panel is not too dense on device.
   - Severity: LOW, non-blocking.

## Data And Provenance Behavior

Verified PR metadata:

- PR: `https://github.com/Somnora/Cosmo-Trader/pull/12`
- Base: `main`
- Head: `codex/market-weather-sector-breadth-context`
- Head SHA: `df0ce1e265c264717001a453bb2940e503a41b3d`
- GitHub Actions: `iOS checks` passed
- Merge state: clean

Core market basket behavior remains scoped to V1 symbols only:

- `Cosmo Trader/Services/MarketWeatherService.swift:81-86` defines the V1 basket as `SPY`, `QQQ`, `DIA`, `IWM`.
- `Cosmo Trader/Services/MarketWeatherService.swift:177-191` computes core market coverage only from `Self.v1Symbols`.
- `Cosmo Trader/Services/MarketWeatherService.swift:111-114` keeps `requiredCoverageForNumericClaims = 1.0` and `requiredEventSymbolCoverage = 1.0`.
- `Cosmo Trader/Services/MarketWeatherService.swift:425-436` withholds headline market metrics unless V1 basket coverage is 100%.

Sector breadth is separate from the core market basket:

- `Cosmo Trader/Services/MarketWeatherService.swift:88-100` defines sector symbols as exactly `XLK`, `XLF`, `XLE`, `XLV`, `XLY`, `XLP`, `XLI`, `XLU`, `XLB`, `XLRE`, `XLC`.
- `Cosmo Trader/Services/MarketWeatherService.swift:211-224` attaches `sectorBreadth` as a separate optional summary on `MarketWeatherSummary`.
- `Cosmo Trader/Services/MarketWeatherService.swift:236-378` computes sector breadth independently from `Self.sectorSymbols`.

Sector numeric claims are gated correctly:

- `Cosmo Trader/Services/MarketWeatherService.swift:292-307` returns `.partialCoverage` with nil metrics when sector coverage is below 100%.
- `Cosmo Trader/Services/MarketWeatherService.swift:334-350` returns `.insufficientSample` with nil metrics when observations are below the minimum sample size.
- `Cosmo Trader/Services/MarketWeatherService.swift:633-651` excludes sample, stale, partial, and insufficient datasets from eligible inputs.
- `Cosmo Trader/Services/MarketWeatherService.swift:754-791` centralizes unavailable sector summaries with nil `averageSectorReturn`, `medianSectorReturn`, and `advancingSectorRate`.
- `Cosmo Trader/Services/TodayMarketHoroscopeComposer.swift:102-113` only maps Today sector metrics when display mode is `.marketBackedResult`, provenance is provider-backed, and cache is not stale.
- `Cosmo Trader/Views/Tabs/CosmosView.swift:1229-1235` only renders Cosmos sector metrics when coverage is 100%, display mode is `.marketBackedResult`, provenance is provider-backed, and cache is not stale.

No fake/generated sector data was introduced. The diff only reads historical datasets through the existing `CorrelationDatasetStore` path and excludes `.sample` provenance from numeric metrics.

## Today And Cosmos UX Findings

Today:

- `Cosmo Trader/Views/Components/TodayMarketHoroscopeView.swift:300-301` places sector breadth after the core market basket rows.
- `Cosmo Trader/Views/Components/TodayMarketHoroscopeView.swift:571-613` renders a compact `SECTOR BREADTH` block with coverage, `DataSourceIndicator`, short detail copy, optional metrics, stale sectors, and unavailable sectors.
- This is appropriately concise for Today.

Cosmos:

- `Cosmo Trader/Views/Tabs/CosmosView.swift:455-456` adds the sector panel under the existing Market Weather section.
- `Cosmo Trader/Views/Tabs/CosmosView.swift:464-533` shows deeper sector context, source/freshness, coverage, event/sample labels, safe metrics only when gated, and unavailable/stale sector lists.
- This is readable from code and correctly separated from the core basket.

Copy safety:

- Sector copy uses `historical`, `context`, `not a prediction`, and `not financial advice`.
- I found no buy/sell/hold, reduce exposure, position-size, expected upside/downside, or prediction-style trading instruction copy in the sector additions.

## Test, Guard, And Build Results

Commands run:

- `gh pr view 12 --json number,title,headRefName,baseRefName,state,isDraft,url,mergeStateStatus,statusCheckRollup,reviews,headRefOid,baseRefOid`
  - Passed. PR exists, targets `main`, CI passed, merge state clean.
- `git diff --stat origin/main...HEAD`
  - Passed. Diff is limited to 8 expected files.
- `git diff --name-only origin/main...HEAD | rg 'BuildInfo\\.generated\\.swift|SubscriptionManager\\.swift' || true`
  - Passed. No output. Neither file is changed.
- `xcodebuild -list -project "Cosmo Trader.xcodeproj"`
  - Passed.
- `bash Scripts/production_mock_guard.sh`
  - Passed.
- `bash Scripts/compliance_copy_guard.sh`
  - Initially blocked because the requested `iPhone 17 Pro` simulator did not exist locally.
  - Created local simulator `526C2FBE-E3CD-4BAD-AFC2-A5C0A36EBCF9` using installed iOS 26.5 runtime.
  - Rerun passed with 4 Swift Testing tests.
- Focused regression command:
  - `MarketWeatherServiceTests`
  - `TodayMarketHoroscopeComposerTests`
  - `PortfolioCosmicCorrelationServiceTests`
  - `AstroCorrelationServiceTests`
  - `HistoricalPriceCacheTests`
  - `ProductionMockGuardTests`
  - `ComplianceCopyGuardTests`
  - Passed with 75 Swift Testing tests across 7 suites.
- Clean Debug simulator build:
  - `xcodebuild -project "Cosmo Trader.xcodeproj" -scheme "Cosmo Trader" -configuration Debug -destination "generic/platform=iOS Simulator" CODE_SIGNING_ALLOWED=NO clean build`
  - Passed.

No selected-0 test run was accepted as passing. Xcode's XCTest wrapper reported 0 tests for Swift Testing runs, but Swift Testing reported nonzero passing counts.

Existing unrelated warnings observed during build:

- `Cosmo Trader/Views/Referral/ReferralView.swift:372`: unused `error` binding.
- `Cosmo Trader/Views/Settings/InboxViews.swift:134`: unused result from `publishTestInboxItem()`.
- `Cosmo Trader/Views/Tabs/DiscoverView.swift:136`: deprecated `onChange(of:perform:)`.
- AppIntents metadata extraction warning because no AppIntents dependency is present.

## Merge Recommendation

PR #12 can merge after the team is comfortable with the usual draft-to-ready process. I found no blocking data, provenance, compliance, or test issues.

## Recommended Next PR

After merge, run a visual QA pass for Today and Cosmos sector breadth:

- Capture Today first viewport with sector breadth present.
- Capture Cosmos Market Weather with sector breadth expanded.
- Verify the sector block remains readable on smaller devices.
- Confirm stale, unavailable, and partial sector states are visually distinct from market-backed metrics.

