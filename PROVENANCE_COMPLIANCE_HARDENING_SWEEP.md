# Provenance And Compliance Hardening Sweep

Date: 2026-06-14
Branch: main
Commit: 4b26b2d

## Executive Verdict

Main is strong on data provenance and numeric-claim gates. The focused guards, targeted Swift Testing suites, and clean Debug build all passed, and I did not find evidence that sample, unavailable, stale, partial, or insufficient data can produce gated market, portfolio, stock, chart, technical-analysis, or correlation claims.

Main is not fully ready for broad QA stress testing under the stricter "no advice-like copy" standard because legacy VOC Moon and Daily Brief copy still contains explicit trading-action wording. This is a copy/compliance cleanup issue, not a data-gate failure.

Recommended next PR: a small legacy advice-copy compliance cleanup before broad QA.

## HIGH Findings

None.

## MEDIUM Findings

1. Legacy VOC Moon copy contains user-facing advice-like trading phrasing.

   Evidence:
   - `Cosmo Trader/Views/Components/VOCMoonViews.swift:560` says actions during VOC periods include listed examples.
   - `Cosmo Trader/Views/Components/VOCMoonViews.swift:568` lists "Opening new positions".
   - `Cosmo Trader/Views/Components/VOCMoonViews.swift:601` says some traders "avoid initiating new positions".
   - `Cosmo Trader/Views/Components/VOCMoonViews.swift:610` says new positions may not develop as expected.
   - `Cosmo Trader/Views/Components/VOCMoonViews.swift:616` says closing positions during VOC is considered acceptable.

   Risk: This violates the stricter sweep invariant that no buy/sell/hold/reduce/avoid/take-profit/position-size advice appears. It is especially risky because it is user-facing copy, not just internal naming.

   Recommended fix: Reframe VOC Moon copy as historical/entertainment context only, remove action-adjacent entries/exits wording, and add compliance guard anchors for "avoid initiating new positions", "opening new positions", and "closing positions".

2. Legacy Daily Brief copy still uses action-like wording.

   Evidence:
   - `Cosmo Trader/Services/DailyBriefService.swift:141` defines `tradingAdvice`.
   - `Cosmo Trader/Services/DailyBriefService.swift:146` says "Review existing positions. Avoid major new commitments."
   - `Cosmo Trader/Services/DailyBriefService.swift:150` says "Resume normal trading activity."
   - `Cosmo Trader/Services/DailyBriefService.swift:160` has the `avoid` enum case.
   - `Cosmo Trader/Services/DailyBriefService.swift:182` says "Review volatile exposure through your own plan".

   Risk: The copy is less specific than a direct trade recommendation, but it still reads like trading guidance. Current compliance guard coverage does not catch this wording.

   Recommended fix: Rename user-facing "advice" surfaces to "context", replace action-oriented phrases with neutral historical/cosmic framing, and expand compliance guard coverage for these phrases.

## LOW Findings

1. Current compliance guard passes but does not cover all legacy advice-like phrases found in the sweep.

   Evidence:
   - `Scripts/compliance_copy_guard.sh` checks known widget phrases such as "Good for new positions".
   - It does not currently catch the VOC Moon and Daily Brief phrases listed above.

   Recommended fix: Add targeted `require_absent` checks for the legacy phrases after the copy is cleaned up.

2. Shareable Today card is not present on current main.

   The sweep invariant for share-card behavior is not applicable to current main. PR #35 covers that surface separately. Current main still includes older social share surfaces, but not the new Today share card.

3. Stock-level upcoming cosmic events are not present on current main.

   The stock-level upcoming events invariant is not applicable to current main. Existing astro overlay/event generation tests remain in place, and no prediction/expected-return wording was found in the focused guard pass.

## Gate-By-Gate Results

| Gate / invariant | Result | Evidence |
| --- | --- | --- |
| Sample data is labeled as sample/demo context | PASS | `production_mock_guard.sh` passed; `ProductionMockGuardTests` includes sample-only chart/correlation guards. |
| Unavailable data never produces numeric market/portfolio/stock/quote/chart/technical/return claims | PASS | Focused suites passed; Today, Market Weather, portfolio correlation, stock correlation, technical analysis, and chart guards cover unavailable states. |
| Stale-beyond-policy data is labeled stale and withheld where freshness is required | PASS | `StockTechnicalAnalysisService` rejects stale cached data; candle eligibility rejects stale cached OHLC; Market Weather labels stale inputs. |
| Partial/insufficient datasets do not produce numeric claims | PASS | Market Weather, portfolio correlation, stock correlation, technical analysis, and historical cache tests passed. |
| Market Weather requires 100% SPY/QQQ/DIA/IWM basket coverage | PASS | `MarketWeatherService` keeps `requiredCoverageForNumericClaims = 1.0` and v1 basket is SPY, QQQ, DIA, IWM. |
| Portfolio correlation requires 70% usable coverage | PASS | `PortfolioCosmicCorrelationService` keeps `minimumPortfolioCoverageForNumericClaims = 0.7`; focused tests passed. |
| Stock correlation respects sample-size/provenance/completeness gates | PASS | `AstroCorrelationServiceTests` passed and service guards provider-backed provenance and numeric-claim completeness. |
| Technical analysis computes only from provider-backed/cached provider-backed candles | PASS | `StockTechnicalAnalysisService` guards provider-backed provenance, stale cache policy, completeness, and candle counts; tests passed. |
| Candle mode only renders complete fresh provider-backed/cached OHLC | PASS | `StockChartCandleEligibility` requires provider-backed, non-stale, complete, valid OHLC; guard/tests passed. |
| Share card does not convert unavailable/sample context into provider-backed claims | N/A on main | The new Today share card is not merged into current main. PR #35 should continue to be reviewed separately. |
| Upcoming cosmic events do not imply prediction or expected returns | N/A on stock detail main | Stock-level upcoming cosmic events are not merged into current main. Existing astro overlay/event tests passed. |
| No buy/sell/hold/reduce/avoid/take-profit/position-size advice appears | FAIL | VOC Moon and Daily Brief legacy copy findings above. |

## Fake-Data Risks

No active fake-data regression was found in this sweep.

Confirmed guard/test coverage includes:
- no sample chart/correlation metrics in production;
- no sample fallback in Stock Detail history activation;
- no sample inherited current price in import paths;
- no generated/sample candles for candle mode;
- unavailable/sample technical data produces no numeric technical claims;
- Market Weather and portfolio gates remain intact.

## Advice-Copy Risks

Current compliance guard passed, but the stricter sweep found user-facing legacy advice-like copy in:
- `Cosmo Trader/Views/Components/VOCMoonViews.swift`
- `Cosmo Trader/Services/DailyBriefService.swift`

This should be cleaned up before broad QA so downstream visual QA is not validating copy that should be replaced.

## Test / Guard / Build Results

Preflight:
- `git fetch origin`: passed.
- `git checkout main`: passed.
- `git pull --ff-only origin main`: passed, already up to date.
- `git status --short`: only pre-existing untracked review artifacts before this report.
- `xcodebuild -list -project "Cosmo Trader.xcodeproj"`: passed.

Guards:
- `bash Scripts/production_mock_guard.sh`: passed.
- `bash Scripts/compliance_copy_guard.sh`: passed with 5 Swift Testing tests.

Focused tests:
- `TodayMarketHoroscopeComposerTests`
- `MarketWeatherServiceTests`
- `PortfolioCosmicCorrelationServiceTests`
- `PortfolioImportCommitTests`
- `HistoricalPriceCacheTests`
- `AstroCorrelationServiceTests`
- `StockTechnicalAnalysisServiceTests`
- `ProductionMockGuardTests`
- `ComplianceCopyGuardTests`

Result: passed with 104 Swift Testing tests in 9 suites.

Selected-zero status: no selected-zero Swift Testing result was accepted. Xcode emitted its normal wrapper "Executed 0 tests" lines, but the Swift Testing run executed 104 tests.

Clean build:
- `xcodebuild -project "Cosmo Trader.xcodeproj" -scheme "Cosmo Trader" -configuration Debug -destination "generic/platform=iOS Simulator" CODE_SIGNING_ALLOWED=NO clean build`: passed.

Non-blocking build warnings:
- `ReferralView.swift`: unused `error` binding.
- `InboxViews.swift`: unused result from `publishTestInboxItem()`.
- `DiscoverView.swift`: deprecated `onChange(of:perform:)` usage.
- App Intents metadata generation warning.

## Extensive QA Readiness

Data/provenance gates are ready for extensive QA stress testing.

Compliance-copy is not ready under the strict standard in this task. Run a small copy/guard hardening PR first, then proceed to broad QA.

## Recommended Next PR

Title: Legacy Advice Copy Compliance Cleanup Before Broad QA

Scope:
- Reframe VOC Moon "Trading Wisdom" and traditional interpretation copy as historical/entertainment context only.
- Remove or rewrite "avoid initiating new positions", "Opening new positions", "Closing positions", "Review existing positions", "Avoid major new commitments", "Resume normal trading activity", and "Review volatile exposure".
- Rename user-facing `tradingAdvice`/`advice` concepts where practical to `context` without broad refactors.
- Add compliance guard anchors so these phrases cannot return.
- Run production mock guard, compliance guard, focused copy tests, and clean Debug build.
