# Stock Detail Small Screen Layout Review

PR: #28, Fix Stock Detail Price Layout On Small Screens
Branch: `codex/stock-detail-small-screen-price-layout`
Base: `main`
Review date: 2026-06-13

## Executive Verdict

No HIGH or MEDIUM blockers found.

PR #28 is a narrow layout-only repair for the Stock Detail price header on small screens. The diff is limited to `StockDetailView.swift` and `PriceDisplayView.swift`; it does not change chart, correlation, provider-loading, subscription, or provenance logic.

The PR is mergeable from a code review perspective. CI is green. Local `production_mock_guard.sh`, `xcodebuild -list`, and clean Debug simulator build passed. Local `compliance_copy_guard.sh` started the correct nonzero focused Xcode selector but did not complete because the target simulator was busy with an unrelated running SquadSync Xcode job. This appears to be local simulator contention, not a PR regression.

## Findings

### HIGH

None.

### MEDIUM

None.

### LOW

1. Local compliance guard could not be fully re-run because of simulator contention.
   - File paths: `Scripts/compliance_copy_guard.sh`
   - The script invoked the expected selector: `Cosmo TraderTests/ComplianceCopyGuardTests`.
   - It did not select 0 tests. The command stalled before test execution while an unrelated SquadSync Xcode build/test process was active on the same simulator.
   - PR CI status is green, so this is an environment limitation rather than evidence of a PR failure.

2. No fresh post-fix screenshot was captured in this review pass.
   - Existing screenshots remain outside the repo at `/tmp/cosmo-chart-surface-qa/`.
   - Prior visual QA identified the small-screen wrap. The code change directly addresses it with responsive layout and single-line scaling, but local simulator install/test contention prevented a fresh screenshot in this pass.

## Layout Findings

Changed files:

- `Cosmo Trader/Views/StockDetailView.swift`
- `Cosmo Trader/Views/Components/PriceDisplayView.swift`

The layout change is well-scoped:

- Replaces the rigid horizontal price/source/mini-chart row with `ViewThatFits(in: .horizontal)`.
- Keeps a horizontal arrangement when space allows.
- Falls back to a stacked layout on narrow screens.
- Keeps `DataSourceIndicator(provenance: priceProvenance, size: .compact)` next to the price.
- Keeps the 7D mini-chart as an explicit unavailable `N/A` state.
- Adds `lineLimit(1)` and `minimumScaleFactor(0.65)` to the price change row so the percentage/change text cannot wrap into a vertical column.

This should address the iPhone SE-sized issue seen in `/tmp/cosmo-chart-surface-qa/stock-detail-small-screen-route.png`.

## Data, Provenance, And Compliance Findings

No chart, provider, cache, correlation, subscription, or provenance logic changed.

The 7D mini-chart remains honest:

- It still displays `N/A`.
- It still includes the source comment that no provider-backed 7D sparkline exists yet.
- It does not render fake, sample, generated, or live-looking chart data.

`SubscriptionManager.swift` and `BuildInfo.generated.swift` are unchanged.

No screenshots were committed. Existing screenshots remain outside the repo.

## Test, Guard, And Build Results

GitHub PR status:

- PR exists: yes
- Base: `main`
- Head: `codex/stock-detail-small-screen-price-layout`
- Merge state: clean
- CI: green, `iOS checks` succeeded

Local commands:

- `git fetch origin`: passed
- `gh pr view 28 --json ...`: passed, PR open and CI green
- `git checkout codex/stock-detail-small-screen-price-layout`: passed
- `git status --short`: passed, only pre-existing untracked review artifacts before this report
- `git diff --stat origin/main...HEAD`: 2 files changed, 68 insertions, 46 deletions
- `git diff --name-only origin/main...HEAD`: only `StockDetailView.swift` and `PriceDisplayView.swift`
- `xcodebuild -list -project "Cosmo Trader.xcodeproj"`: passed
- `bash Scripts/production_mock_guard.sh`: passed
- `bash Scripts/compliance_copy_guard.sh`: local run blocked by simulator contention after selecting `Cosmo TraderTests/ComplianceCopyGuardTests`; PR CI is green
- clean Debug simulator build: passed

No selected-0 test run was accepted.

Clean build warnings observed are pre-existing and unrelated:

- `ReferralView.swift`: unused `error`
- `InboxViews.swift`: unused result
- `DiscoverView.swift`: deprecated `onChange(of:perform:)`

## Merge Readiness

PR #28 can merge after reviewer acceptance. The only residual issue is local simulator contention preventing a fresh local compliance-test completion and post-fix screenshot during this review pass. CI is green and the diff is narrow enough that this does not appear to block merge.

## Recommended Next PR

Proceed with chart PR stabilization:

1. Merge the small layout fix first.
2. Decide merge order for PR #25 and PR #26.
3. Rebase the second chart PR after the first lands because they conflict in chart/view-model/test/guard files.
4. Add a provider-backed chart fixture smoke path if visual verification of eligible candle mode remains blocked by lack of local provider-backed OHLC data.
