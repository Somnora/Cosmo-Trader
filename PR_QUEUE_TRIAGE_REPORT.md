# PR Queue Triage Report

## Executive Verdict

The open PR queue is too large for a useful broad QA pass right now. There are 21 open PRs: 13 are clean with green CI, 8 are dirty/conflicting or stacked against a non-main branch. Several older PRs are clearly superseded by newer branches with the same scope. The safest next move is to review/merge the clean, current PRs in dependency order, close or ignore superseded duplicates after confirmation, then rebase the chart stack and dirty legacy branches.

Local main verification completed on 2026-06-14:
- `git fetch origin`: passed.
- `git checkout main && git pull --ff-only origin main`: passed, main already up to date.
- `bash Scripts/production_mock_guard.sh`: passed.
- `bash Scripts/compliance_copy_guard.sh`: passed with 5 Swift Testing tests.
- `xcodebuild -list -project "Cosmo Trader.xcodeproj"`: passed.

## Current PR Table

| PR | Title | Base | Head | Merge State | CI | Status | Dependencies / Prerequisites | Likely Conflicts |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| #35 | Shareable Daily Market Horoscope Card | main | codex/shareable-today-market-horoscope-card | CLEAN | SUCCESS | Current, ready for independent review | Today summary/provenance gates already on main | Low; Today share UI/tests only |
| #34 | Portfolio History Coverage Diagnostics | main | codex/portfolio-history-coverage-diagnostics | CLEAN | SUCCESS | Current, ready for independent review | Portfolio Intelligence should be on main | Medium if provider-history PRs modify Portfolio history sections |
| #33 | Combined Technical And Cosmic Stock Context Cards | main | codex/combined-technical-cosmic-stock-context | CLEAN | SUCCESS | Current, ready for independent review if technical analysis and stock history activation are already on main | Requires Provider-Backed Stock Technical Analysis and Stock Detail Provider History Activation | Medium; Stock Detail / technical / correlation surfaces |
| #32 | End-To-End First-Run Activation Funnel Smoke | main | codex/first-run-activation-funnel-smoke | CLEAN | SUCCESS | Current unless already superseded by a previously merged smoke PR; verify before merge | Depends on first-run setup, portfolio import, Stock Detail technical/history gates | Medium; test/guard overlap with onboarding and history activation |
| #29 | Provider-Backed Chart Fixture Smoke | main | codex/provider-backed-chart-fixture-smoke | DIRTY | SUCCESS | Current concept, needs rebase before review | Should follow chart mode / overlay stabilization | High; chart test fixture and chart surface files |
| #27 | Stock-Level Upcoming Cosmic Events | main | codex/stock-upcoming-cosmic-events | CLEAN | SUCCESS | Current, ready for independent review | AstroOverlayEventService infrastructure on main | Low/medium; Stock Detail additions may conflict with #33 |
| #26 | Historical Chart Interaction And Astro Overlay Polish | main | codex/historical-chart-overlay-polish | CLEAN | SUCCESS | Current chart PR, ready for targeted review but should be sequenced with other chart PRs | Should preserve line/candle mode and stale cache policy if those are merged first | High; chart surface / overlay files |
| #24 | Provider History Activation For Holdings And Watchlist | main | codex/provider-history-activation-holdings-watchlist | CLEAN | SUCCESS | Current, ready for independent review | Builds on portfolio/watchlist/history loading surfaces | Medium/high; overlaps Portfolio and Today activation |
| #23 | Stock Detail Provider History Activation | codex/provider-backed-stock-technical-analysis-mvp | codex/stock-detail-history-activation-mvp | CLEAN | SUCCESS | Superseded/stacked; base is not main | Old stacked branch for stock detail history activation | High; likely obsolete after main-based stock history PRs |
| #21 | Stock Detail Provider History Activation | main | codex/stock-detail-provider-history-activation | DIRTY | SUCCESS | Superseded or stale; needs confirmation/rebase if not obsolete | Same scope as stock detail history activation already handled in later work | High; dirty against main |
| #20 | Stock Correlation Explainability Upgrade | main | codex/stock-correlation-explainability-upgrade | CLEAN | SUCCESS | Current, ready for independent review | Existing stock correlation gates on main | Medium; Stock Detail correlation UI may conflict with #33/#27 |
| #19 | Historical Chart Interaction And Astro Overlay Polish | main | codex/historical-chart-astro-overlay-polish | DIRTY | SUCCESS | Superseded by #26 | Older chart overlay branch | High; duplicate of #26 and dirty |
| #18 | Shareable Daily Market Horoscope Card | main | codex/shareable-daily-market-horoscope-card | CLEAN | SUCCESS | Superseded by #35 | Older share-card branch | Medium; duplicate of #35 |
| #17 | First-Run Data Setup Onboarding | main | codex/first-run-data-setup-onboarding | CLEAN | SUCCESS | Needs verification: may be current if not merged, or stale if equivalent work already landed | First-run setup / Today CTA routes | Medium; overlaps #32 and #24 |
| #16 | Watchlist First-Run Activation And Daily Context | main | codex/watchlist-first-run-daily-context | CLEAN | SUCCESS | Current newer watchlist PR, ready for review if not superseded by #24/#17 | Discover/watchlist persistence and Today watchlist context | Medium; overlaps #24 and #17 |
| #15 | Provider-Backed Stock Technical Analysis MVP | main | codex/provider-backed-stock-technical-analysis-mvp | DIRTY | SUCCESS | Superseded by merged PR #31 or stale; do not review until confirmed | Technical analysis MVP likely already landed | High; dirty against main |
| #14 | Portfolio Intelligence Dashboard MVP | main | codex/portfolio-intelligence-dashboard | DIRTY | SUCCESS | Superseded by merged Portfolio Intelligence work or stale | Portfolio dashboard likely already landed | High; dirty against main |
| #10 | Watchlist First-Run Activation And Daily Context | main | codex/watchlist-first-run-activation | DIRTY | SUCCESS | Superseded by #16 | Older watchlist branch | High; dirty duplicate |
| #9 | Provider-Backed Stock Technical Analysis MVP | main | codex/provider-backed-stock-technical-analysis | DIRTY | SUCCESS | Superseded by #31/#15 lineage | Older technical analysis branch | High; dirty duplicate |
| #8 | Provider History Activation For Holdings And Watchlist | main | codex/provider-history-activation | DIRTY | SUCCESS | Superseded by #24 | Older provider-history branch | High; dirty duplicate |
| #7 | Portfolio Import First-Run Smoke And Setup Polish | main | codex/portfolio-import-first-run-smoke | CLEAN | SUCCESS | Likely stale; verify whether PR #6/import hardening and first-run smoke already covered it | Portfolio import setup polish | Medium; could conflict with newer import/setup changes |

## Superseded / Duplicate PRs

These should not be reviewed until confirmed against main; most should likely be closed after owner approval:

- #18 is superseded by #35 for Shareable Daily Market Horoscope Card.
- #19 is superseded by #26 for Historical Chart Interaction And Astro Overlay Polish.
- #23 is stacked on `codex/provider-backed-stock-technical-analysis-mvp`, not main, and appears superseded by later main-based Stock Detail history activation work.
- #21 appears stale/dirty for Stock Detail Provider History Activation.
- #15 and #9 are superseded by the merged Provider-Backed Stock Technical Analysis work, or at minimum dirty legacy branches.
- #14 is likely superseded by merged Portfolio Intelligence Dashboard work.
- #10 is superseded by #16 for Watchlist First-Run Activation.
- #8 is superseded by #24 for Provider History Activation For Holdings And Watchlist.
- #7 is likely stale after Portfolio Import hardening and first-run setup work, but should be diff-checked before closing.

## Clean / Green PRs Ready For Review

These are clean against `main` and have successful GitHub Actions:

- #35 Shareable Daily Market Horoscope Card
- #34 Portfolio History Coverage Diagnostics
- #33 Combined Technical And Cosmic Stock Context Cards
- #32 End-To-End First-Run Activation Funnel Smoke
- #27 Stock-Level Upcoming Cosmic Events
- #26 Historical Chart Interaction And Astro Overlay Polish
- #24 Provider History Activation For Holdings And Watchlist
- #20 Stock Correlation Explainability Upgrade
- #17 First-Run Data Setup Onboarding, if not already superseded by merged work
- #16 Watchlist First-Run Activation And Daily Context, if not superseded by #24/#17
- #7 Portfolio Import First-Run Smoke And Setup Polish, only after confirming it is not stale

## Dirty / Conflicting PRs

These need rebase or closure before review:

- #29 Provider-Backed Chart Fixture Smoke
- #21 Stock Detail Provider History Activation
- #19 Historical Chart Interaction And Astro Overlay Polish
- #15 Provider-Backed Stock Technical Analysis MVP
- #14 Portfolio Intelligence Dashboard MVP
- #10 Watchlist First-Run Activation And Daily Context
- #9 Provider-Backed Stock Technical Analysis MVP
- #8 Provider History Activation For Holdings And Watchlist

## Recommended Merge Order

1. Review #35 Shareable Daily Market Horoscope Card. It is isolated, clean, green, and low conflict.
2. Review #24 Provider History Activation For Holdings And Watchlist. It unlocks several user flows and should land before downstream diagnostics/polish.
3. Review #34 Portfolio History Coverage Diagnostics after #24, because it may depend on the final history activation UX.
4. Review #27 Stock-Level Upcoming Cosmic Events. It is Stock Detail additive and non-predictive.
5. Review #20 Stock Correlation Explainability Upgrade before #33, because #33 combines technical and cosmic context and benefits from stable correlation explanations.
6. Review #33 Combined Technical And Cosmic Stock Context Cards after #20 and after confirming technical/history prerequisites are in main.
7. Review #26 Historical Chart Interaction And Astro Overlay Polish as the first chart-surface PR in the active chart stack.
8. Rebase/review #29 Provider-Backed Chart Fixture Smoke after #26, so fixture QA validates the latest chart surface.
9. Verify whether #32, #17, #16, and #7 are still needed or are covered by merged activation/onboarding/import work; review only the current one(s), close stale duplicates after approval.

## Recommended Next Action For Each PR

- #35: Send to independent review now.
- #34: Send to independent review after #24, or review now with expected minor recheck after #24.
- #33: Send to independent review after #20, or explicitly verify prerequisites first.
- #32: Confirm whether this was intended to be merged already; if not, review as current smoke coverage.
- #29: Rebase after chart PR order is settled.
- #27: Send to independent review now.
- #26: Send to chart-focused independent review; do not merge until chart stack order is confirmed.
- #24: Send to independent review now.
- #23: Mark as superseded/stacked; do not review as-is.
- #21: Mark as stale/dirty unless it contains unique changes not in main.
- #20: Send to independent review now.
- #19: Superseded by #26; close after approval.
- #18: Superseded by #35; close after approval.
- #17: Diff-check against main to decide whether current or stale.
- #16: Compare against #10 and #24; likely the current watchlist PR if watchlist-specific work is still needed.
- #15: Likely superseded by merged technical analysis work; close after approval.
- #14: Likely superseded by merged Portfolio Intelligence work; close after approval.
- #10: Superseded by #16; close after approval.
- #9: Superseded by #15/#31 lineage; close after approval.
- #8: Superseded by #24; close after approval.
- #7: Diff-check against current import/onboarding state before deciding.

## Broad QA Readiness

Do not run the extensive end-to-end QA stress test yet. First reduce the open PR queue, close confirmed superseded branches, and stabilize chart PR ordering. After #24/#34/#35 and chart ordering are settled, broad QA will be much less noisy and more actionable.
