# Import Hardening Review

PR: Portfolio Import And Edit Hardening For First-Run Activation  
PR #6: https://github.com/Somnora/Cosmo-Trader/pull/6  
Branch: `codex/portfolio-import-edit-hardening`  
Reviewed head: `6dbe97d6f085bbbe3da3d9125b55af86655a2fb9`

## Executive Verdict

APPROVED TO MERGE.

I found no HIGH or MEDIUM blockers. PR #6 now routes both CSV import and screenshot import through the hardened review and commit flow. Replace and append are explicit, duplicate append uses weighted cost basis, imported holdings persist through the existing `AppState.saveUserToStorage()` path, known stocks do not inherit sample prices when provider/imported price is unavailable, and unknown tickers preserve nil astrology metadata.

GitHub CI is green, local guards pass, focused import/parser/correlation/Today tests pass with nonzero Swift Testing counts, and a clean Debug simulator build succeeds.

## Findings

### HIGH

None.

### MEDIUM

None.

### LOW

1. Full relaunch persistence is indirectly verified, not directly exercised.
   - Evidence: `PortfolioImportService.commitPortfolio` updates `appState.currentUser` and calls `appState.saveUserToStorage()` at `Cosmo Trader/Services/PortfolioImportService.swift:570-587`.
   - Tests assert `lastSaveTimestamp` after replace/screenshot append at `Cosmo TraderTests/Services/PortfolioImportCommitTests.swift:7-31` and `Cosmo TraderTests/Services/PortfolioImportCommitTests.swift:122-154`.
   - Gap: there is not yet a test that commits, creates a fresh `AppState`, and verifies the holdings reload from `UserDefaults`.
   - Risk: low. The production persistence path is used, but a future test should cover the actual relaunch load.

2. Some legacy import UI state/helper code appears to remain as cleanup debt.
   - Evidence: the production routes no longer call `PortfolioImportService.applyImport`, and the guard blocks that regression at `Scripts/production_mock_guard.sh:220-231`.
   - `ScreenshotImportView` now routes through `ImportReviewView` at `Cosmo Trader/Views/ScreenshotImportView.swift:69-80` and `Cosmo Trader/Views/ScreenshotImportView.swift:645-658`.
   - Gap: old state/helper surfaces in import views should be pruned in a later cleanup PR if still unreachable.
   - Risk: low. I did not find a production direct-commit bypass.

## Import Persistence Findings

CSV import:
- CSV files are parsed by `PortfolioImportService.parseCSVFile` and then routed into `ImportReviewView`, not committed immediately: `Cosmo Trader/Views/ImportPortfolioView.swift:80-91` and `Cosmo Trader/Views/ImportPortfolioView.swift:722-747`.
- `parseCSVFile` reads UTF-8 with ASCII fallback, then calls `parseCSV`: `Cosmo Trader/Services/PortfolioImportService.swift:239-273`.

Screenshot import:
- Screenshot OCR parsing is centralized in `PortfolioImportService.parseScreenshot`: `Cosmo Trader/Services/PortfolioImportService.swift:224-237`.
- `ScreenshotImportView` sends screenshot results to `ImportReviewView`: `Cosmo Trader/Views/ScreenshotImportView.swift:69-80` and `Cosmo Trader/Views/ScreenshotImportView.swift:645-658`.
- The view copy explicitly tells users they will review every parsed row before choosing append or replace: `Cosmo Trader/Views/ScreenshotImportView.swift:101-111`.

Commit and persistence:
- `ImportReviewView` commits only reviewed holdings via `PortfolioImportService.commitPortfolio`: `Cosmo Trader/Views/Settings/ImportReviewView.swift:339-348`.
- `commitPortfolio` supports `.replace` and `.append`, updates `appState.currentUser`, and calls `saveUserToStorage()`: `Cosmo Trader/Services/PortfolioImportService.swift:570-587`.

## Append/Replace UX Findings

Replace is explicit:
- Review UI exposes `Replace my portfolio`: `Cosmo Trader/Views/Settings/ImportReviewView.swift:286-302`.
- Confirmation copy says replacing existing holdings cannot be undone: `Cosmo Trader/Views/Settings/ImportReviewView.swift:522-536`.

Append is explicit:
- Review UI exposes `Append to portfolio`: `Cosmo Trader/Views/Settings/ImportReviewView.swift:268-285`.
- Confirmation copy says matching symbols combine shares and weighted cost basis: `Cosmo Trader/Views/Settings/ImportReviewView.swift:522-528`.

Duplicate merge behavior:
- Append mode merges `user.portfolio + importedStocks`: `Cosmo Trader/Services/PortfolioImportService.swift:579-584`.
- Duplicate symbols are merged in `mergeDuplicateStocks`, with weighted average cost basis computed before combined shares are stored: `Cosmo Trader/Services/PortfolioImportService.swift:635-675`.
- Test coverage confirms duplicate append produces 4 AAPL shares and weighted cost basis 175: `Cosmo TraderTests/Services/PortfolioImportCommitTests.swift:34-65`.

Review/edit support:
- Review rows support editing symbol, shares, and cost basis: `Cosmo Trader/Views/Settings/ImportReviewView.swift:397-446`.
- Skipped/unparsed lines are visible in a disclosure group, so recognized parse misses are not silently hidden: `Cosmo Trader/Views/Settings/ImportReviewView.swift:196-215`.

## No-Sample-Price Findings

Known stocks:
- Known-stock metadata is copied from `MockStockData.knownStocks`, but `currentPrice` is overwritten with `importedOrProviderPrice`, which is `livePrice`, imported market-value-per-share, or 0: `Cosmo Trader/Services/PortfolioImportService.swift:597-618`.
- This prevents known sample currentPrice from leaking into imported holdings.
- Test coverage confirms AAPL with no quote or market value imports at `currentPrice == 0`: `Cosmo TraderTests/Services/PortfolioImportCommitTests.swift:67-91`.

Unknown tickers:
- Unknown symbols construct a new `Stock` with `foundedDate: nil` and no fabricated sign/element: `Cosmo Trader/Services/PortfolioImportService.swift:621-632`.
- Test coverage confirms unknown `ZZZZ` has nil `foundedDate`, `zodiacSign`, and `foundedElement`: `Cosmo TraderTests/Services/PortfolioImportCommitTests.swift:93-120`.
- Screenshot parser coverage confirms unknown screenshot ticker replace preserves nil astrology metadata: `Cosmo TraderTests/Services/PortfolioImportCommitTests.swift:157-184`.

Provider provenance:
- `ImportReviewView` fetches live quote results separately and stores field provenance for visible quote labels: `Cosmo Trader/Views/Settings/ImportReviewView.swift:324-337`.
- If quotes are unavailable, the live value is muted and provenance reports unavailable: `Cosmo Trader/Views/Settings/ImportReviewView.swift:462-477`.

## Test, Guard, And Build Results

GitHub CI:
- PR #6 `iOS checks`: SUCCESS.
- Merge state: CLEAN.

Local checks:
- `xcodebuild -list -project "Cosmo Trader.xcodeproj"`: passed.
- `bash Scripts/production_mock_guard.sh`: passed.
- `DESTINATION='platform=iOS Simulator,name=QA-Den-17Pro' bash Scripts/compliance_copy_guard.sh`: passed with 4 Swift Testing tests.
- Focused service/parser/canary tests: passed with 48 Swift Testing tests across 6 suites:
  - `PortfolioImportCommitTests`: 6 tests.
  - `SchwabMobileParserTests`: 7 tests.
  - `SchwabWebPositionsParserTests`: 4 tests.
  - `ThinkOrSwimPositionStatementParserTests`: 6 tests.
  - `PortfolioCosmicCorrelationServiceTests`: 12 tests.
  - `TodayMarketHoroscopeComposerTests`: 13 tests.
- Clean Debug simulator build: passed.

No selected-0 result was accepted as passing. Xcode's XCTest wrapper reported 0 XCTest tests for Swift Testing suites, but Swift Testing itself reported nonzero passing test counts.

Build warnings observed:
- Pre-existing warnings remain in unrelated files:
  - `Cosmo Trader/Views/Referral/ReferralView.swift:372`
  - `Cosmo Trader/Views/Settings/InboxViews.swift:134`
  - `Cosmo Trader/Views/Tabs/DiscoverView.swift:136`
- These are not introduced by PR #6 and do not block merge.

Worktree:
- No tracked source diffs after verification.
- `BuildInfo.generated.swift` and `SubscriptionManager.swift` have no diff.
- Existing untracked review artifacts remain uncommitted:
  - `DATA_ACTIVATION_TODAY_REVIEW.md`
  - `MARKET_WEATHER_MVP_REVIEW.md`
  - `TODAY_REGRESSION_GUARDS_REVIEW.md`
  - `IMPORT_HARDENING_REVIEW.md`

## Merge Readiness

PR #6 can merge.

It satisfies the requested invariants:
- CSV import uses review and commit flow.
- Screenshot import uses review and commit flow.
- Replace and append are explicit and confirmed.
- Duplicate append uses weighted cost basis.
- Commit path persists via `AppState.saveUserToStorage()`.
- Known stocks without provider/imported quote do not inherit sample currentPrice.
- Unknown tickers preserve nil astrology metadata.
- Import review supports symbol, quantity, and cost basis edits.
- No fake holdings or fake/sample provider prices were introduced.
- Portfolio unavailable/provider-history states remain honest because imported prices are treated as local/imported value or unavailable, not provider-backed historical data.
- Production mock guard now anchors import hardening.
- Compliance guard passes.

## Recommended Next PR

After merge, the next highest-value PR should be a narrow import usability smoke and persistence proof:

1. Add an end-to-end relaunch persistence test using the real storage/load path.
2. Run a visual smoke of manual add, CSV import, screenshot import, review edit, append, replace, relaunch.
3. Remove any unreachable legacy import helper state once the visual smoke confirms the hardened path owns all production entry points.
4. Add one or two real anonymized CSV/screenshot fixtures outside production code if James can provide them.
