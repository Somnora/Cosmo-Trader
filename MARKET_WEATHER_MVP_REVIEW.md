# Market Weather MVP Review

## Executive Verdict

PASS with no HIGH or MEDIUM findings.

The branch `codex/market-weather-mvp` exists on GitHub at `c85e151` and is based on current `main` at `27c8125`, which includes the Today regression guard cleanup. The Market Weather implementation is present as the rebased equivalent of the original `fc36455` work. It adds a provider-backed whole-market lens for SPY, QQQ, DIA, and IWM, integrates it into Today, adds a low-risk Cosmos context section, preserves stock and portfolio correlation safeguards, and does not change `SubscriptionManager` or `BuildInfo.generated.swift`.

This branch can merge to `main` from a code and verification standpoint. The only review-process gap is that no GitHub PR object currently exists for the branch.

## Findings

### HIGH

None.

### MEDIUM

None.

### LOW

1. No GitHub PR object exists for the branch yet.
   - Evidence: `gh pr list --repo Somnora/Cosmo-Trader --head codex/market-weather-mvp --json number,title,headRefName,baseRefName,state,url` returned `[]`.
   - Impact: the branch is pushed and reviewable, but GitHub PR metadata and PR-scoped checks are not attached yet.
   - Recommendation: open a PR before merge if Claude review and CI signoff are expected to attach to a GitHub pull request.

## Branch And GitHub State

- Current branch: `codex/market-weather-mvp`
- Remote branch: `origin/codex/market-weather-mvp`
- Branch HEAD: `c85e151 Build market weather MVP`
- Current `main`: `27c8125 Harden Today guard coverage tests`
- `origin/main`: `27c8125 Harden Today guard coverage tests`
- Branch base check: `origin/main` is an ancestor of `origin/codex/market-weather-mvp`.
- Today regression guard cleanup is merged into `main`.
- Changed files relative to `origin/main`:
  - `Cosmo Trader/Models/TodayMarketHoroscopeSummary.swift`
  - `Cosmo Trader/Services/MarketWeatherService.swift`
  - `Cosmo Trader/Services/TodayMarketHoroscopeComposer.swift`
  - `Cosmo Trader/ViewModels/TodayMarketHoroscopeViewModel.swift`
  - `Cosmo Trader/Views/Components/TodayMarketHoroscopeView.swift`
  - `Cosmo Trader/Views/Tabs/CosmosView.swift`
  - `Cosmo TraderTests/Services/MarketWeatherServiceTests.swift`
  - `Cosmo TraderTests/Services/TodayMarketHoroscopeComposerTests.swift`
  - `Scripts/production_mock_guard.sh`
- `SubscriptionManager` was not changed.
- `BuildInfo.generated.swift` was not changed.
- No untracked Swift files are required for build or test success.
- Existing untracked review artifact before this report: `TODAY_REGRESSION_GUARDS_REVIEW.md`.

## Market Data And Provenance Behavior

Market Weather uses provider-backed or cached provider-backed historical datasets through the existing correlation dataset path. `MarketWeatherService.loadSummary` requests datasets from `CorrelationDatasetStore` for `Self.v1Symbols.map(\.symbol)` in `Cosmo Trader/Services/MarketWeatherService.swift:82`.

The V1 market scope is exactly:

- `SPY`
- `QQQ`
- `DIA`
- `IWM`

Evidence: `MarketWeatherService.v1Symbols` is defined with only those symbols in `Cosmo Trader/Services/MarketWeatherService.swift:49`.

The V1 event scope is exactly:

- Full Moon
- New Moon
- Mercury Retrograde

Evidence: `supportedEventKinds` contains `.fullMoon`, `.newMoon`, and `.mercuryRetrograde` in `Cosmo Trader/Services/MarketWeatherService.swift:56`, and generated events are filtered through that set in `Cosmo Trader/Services/MarketWeatherService.swift:97`.

Numeric market claims are gated on:

- Provider-backed or cached provider-backed provenance.
- Cached data not being stale.
- Dataset completeness.
- Minimum event sample size.
- Full V1 basket coverage for numeric claims.
- Full per-event symbol contribution coverage.
- No sample, unavailable, partial, or insufficient data.

Evidence:

- `requiredCoverageForNumericClaims = 1.0` in `Cosmo Trader/Services/MarketWeatherService.swift:66`.
- Coverage is computed against the four-symbol V1 basket in `Cosmo Trader/Services/MarketWeatherService.swift:143`.
- Coverage below the numeric threshold returns `.partialCoverage` with nil metrics in `Cosmo Trader/Services/MarketWeatherService.swift:223`.
- Sample data is explicitly excluded in `Cosmo Trader/Services/MarketWeatherService.swift:355`.
- Non-provider-backed data is excluded in `Cosmo Trader/Services/MarketWeatherService.swift:359`.
- Stale cached data is excluded in `Cosmo Trader/Services/MarketWeatherService.swift:363`.
- Partial and insufficient datasets are excluded in `Cosmo Trader/Services/MarketWeatherService.swift:367`.
- Numeric `.marketBackedResult` is only returned after the gates pass in `Cosmo Trader/Services/MarketWeatherService.swift:277`.
- `MockStockData` and `Double.random` are absent from `MarketWeatherService`, and the production guard enforces that in `Scripts/production_mock_guard.sh:170`.

## Today Integration Status

Today has a Market Weather card.

Evidence:

- `TodayMarketHoroscopeSummary` now includes `marketContext` in `Cosmo Trader/Models/TodayMarketHoroscopeSummary.swift:6`.
- `TodayMarketContext` models market display modes, event details, symbol coverage, metrics, provenance, and disclaimer state in `Cosmo Trader/Models/TodayMarketHoroscopeSummary.swift:24`.
- `TodayMarketHoroscopeViewModel` loads market weather through `MarketWeatherService` and passes it to the composer in `Cosmo Trader/ViewModels/TodayMarketHoroscopeViewModel.swift:68`.
- `TodayMarketHoroscopeComposer` maps Market Weather into Today and only populates metrics when display mode is market-backed in `Cosmo Trader/Services/TodayMarketHoroscopeComposer.swift:78`.
- `TodayMarketHoroscopeView` renders the `MARKET WEATHER` section in `Cosmo Trader/Views/Components/TodayMarketHoroscopeView.swift:177`.
- The Today Market Weather section displays `DataSourceIndicator` in `Cosmo Trader/Views/Components/TodayMarketHoroscopeView.swift:198`.
- Market Weather metrics render only when `context.metrics` is non-empty in `Cosmo Trader/Views/Components/TodayMarketHoroscopeView.swift:210`.

Today still preserves the existing portfolio coverage policy. The composer keeps the `0.70` numeric portfolio threshold and withholds portfolio headline metrics below that threshold.

## Cosmos Integration Status

Cosmos includes a low-risk market context section.

Evidence:

- `CosmosView` stores `marketWeatherSummary` in `Cosmo Trader/Views/Tabs/CosmosView.swift:32`.
- The Cosmos market section renders `MARKET WEATHER` in `Cosmo Trader/Views/Tabs/CosmosView.swift:403`.
- The section displays a `DataSourceIndicator` in `Cosmo Trader/Views/Tabs/CosmosView.swift:410`.
- The section shows coverage, event, and sample context in `Cosmo Trader/Views/Tabs/CosmosView.swift:424`.
- Cosmos renders metrics only when `canShowMarketWeatherMetrics` allows it in `Cosmo Trader/Views/Tabs/CosmosView.swift:430`.
- `canShowMarketWeatherMetrics` requires full coverage, market-backed result mode, provider-backed provenance, and non-stale data in `Cosmo Trader/Views/Tabs/CosmosView.swift:1129`.

## Safe Copy And Compliance Behavior

Market Weather copy is framed as historical context, market lens, and non-advice.

Evidence:

- Market Weather service disclaimer: `Historical market context only. Correlation does not imply causation and this is not financial advice.` in `Cosmo Trader/Services/MarketWeatherService.swift:169`.
- Today market detail copy distinguishes market-backed context from stale, partial, insufficient, unavailable, and sample states in `Cosmo Trader/Services/TodayMarketHoroscopeComposer.swift:424`.
- Cosmos market context copy uses historical/context language and avoids trading instructions in `Cosmo Trader/Views/Tabs/CosmosView.swift:1138`.
- `bash Scripts/compliance_copy_guard.sh` passed.

No advice-like copy was introduced. The compliance guard and focused tests did not detect buy, sell, hold, avoid, take-profit, reduce-exposure, position-size, smaller-position, delay-decision, high-risk-position, guaranteed, expected-upside, or expected-downside language in the scanned user-facing surfaces.

## Guard And Test Results

Commands run from `/Users/jamesmcshane/Desktop/Cosmo_Trader/Cosmo Trader`:

```bash
xcodebuild -list -project "Cosmo Trader.xcodeproj"
```

Result: passed. Xcode listed the `Cosmo Trader` project, targets, configurations, and schemes.

```bash
bash Scripts/production_mock_guard.sh
```

Result: passed.

```bash
bash Scripts/compliance_copy_guard.sh
```

Result: passed. The focused Swift Testing suite executed 4 `ComplianceCopyGuardTests` tests. Xcode printed its legacy XCTest preamble with `0 tests`, but Swift Testing then executed the selected nonzero test set.

```bash
xcodebuild test \
  -project "Cosmo Trader.xcodeproj" \
  -scheme "Cosmo Trader" \
  -destination "platform=iOS Simulator,name=iPhone 17 Pro" \
  -parallel-testing-enabled NO \
  -maximum-concurrent-test-simulator-destinations 1 \
  -only-testing:"Cosmo TraderTests/MarketWeatherServiceTests" \
  -only-testing:"Cosmo TraderTests/TodayMarketHoroscopeComposerTests" \
  -only-testing:"Cosmo TraderTests/AstroCorrelationServiceTests" \
  -only-testing:"Cosmo TraderTests/PortfolioCosmicCorrelationServiceTests" \
  -only-testing:"Cosmo TraderTests/HistoricalPriceCacheTests" \
  -only-testing:"Cosmo TraderTests/FinancialDataProvenanceTests" \
  -only-testing:"Cosmo TraderTests/ProductionMockGuardTests" \
  -only-testing:"Cosmo TraderTests/ComplianceCopyGuardTests"
```

Result: passed. Swift Testing executed 72 tests across 8 suites. No focused command selected 0 Swift Testing tests.

```bash
xcodebuild \
  -project "Cosmo Trader.xcodeproj" \
  -scheme "Cosmo Trader" \
  -configuration Debug \
  -destination "generic/platform=iOS Simulator" \
  CODE_SIGNING_ALLOWED=NO \
  clean build
```

Result: passed.

Build notes: the build emitted pre-existing warnings in unrelated files:

- `Cosmo Trader/Views/Referral/ReferralView.swift:372` unused `error`.
- `Cosmo Trader/Views/Settings/InboxViews.swift:134` unused result from `publishTestInboxItem()`.
- `Cosmo Trader/Views/Tabs/DiscoverView.swift:129` deprecated `onChange(of:perform:)`.
- App Intents metadata extraction warned that no AppIntents dependency was found.

These warnings are not introduced by this branch.

## Specific Verification Checklist

- Branch exists on GitHub and is based on current main: verified.
- Market Weather implementation exists at rebased commit `c85e151`: verified.
- Today regression guard PR is merged into main: verified at `27c8125`.
- Provider-backed or cached provider-backed historical datasets only: verified.
- V1 market scope exactly SPY, QQQ, DIA, IWM: verified.
- Event-window summaries for Full Moon, New Moon, Mercury Retrograde: verified.
- Numeric market claims gated on provenance, freshness, completeness, sample size, and safe display modes: verified.
- Today has a Market Weather card: verified.
- Cosmos has a low-risk market context section: verified.
- Source, freshness, and coverage are visible: verified.
- No fake/generated market data introduced: verified by source inspection and production mock guard.
- No advice-like copy introduced: verified by source inspection and compliance guard.
- Stock correlation safeguards still pass: verified in focused tests.
- Portfolio correlation safeguards still pass: verified in focused tests.
- Today safeguards still pass: verified in focused tests and production guard.
- Cache/completeness safeguards still pass: verified in focused tests.
- Compliance and production mock guards pass: verified.
- Clean Debug build passes: verified.
- No command selected 0 Swift Testing tests: verified.
- No untracked Swift files are required: verified.
- `SubscriptionManager` and `BuildInfo.generated.swift` were not changed: verified.

## Merge Readiness

This PR can merge to `main` after a GitHub PR is opened, if the team wants the normal PR record and PR-scoped CI checks. There are no code, provenance, compliance, mock-data, or build blockers in this review.

## Recommended Next PR

After Market Weather merges, the next PR should be:

**Add Market Weather CI Selectors And Provider Observability**

Goal: add Market Weather focused tests to CI and add lightweight diagnostics for ETF historical dataset fetch failures, stale cache usage, and unavailable market coverage. This would make the new market lens easier to monitor before the Today surface starts carrying more of the product narrative.
