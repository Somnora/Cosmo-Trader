# Compliance Copy Cleanup Review (Independent Pass)

Review target: `Remove Remaining Trading-Instruction Copy Before Portfolio Correlation`
Reviewer: fresh-eyes independent pass (Codex implemented + self-reviewed; this supersedes the prior self-review verdict on test execution).
Review date: 2026-05-29
Working tree: `fix/provenance-leaks-mood-and-portfolio-pl` on top of inner commit `d81dd8c`; the cleanup is uncommitted in the working tree.

---

## Executive Verdict

**The user-facing copy cleanup is real, present, and complete for the defined contract.** Independently verified by (a) targeted grep of all 17 scanned production files, and (b) a from-scratch Python re-implementation of the scanner's exact rule set + allowlist run natively against the working tree: **0 violations**. The four previously-flagged phrases are gone, the user-facing enum raw values were rewritten to safe context language, and disclaimer copy is correctly preserved.

**However, the compliance guard test that is supposed to protect this is not trustworthy as wired, and Codex's self-review reached the wrong conclusion about why.** Codex reported the focused command "selected 0 tests" and a retry hit a simulator launch failure, and concluded execution was merely "inconclusive." That is not the full picture. With the **correct** selector on a **healthy** simulator, the key test does run — and **deterministically FAILS** — because it reads source files off the host filesystem via `String(contentsOf:)`, which the iOS-simulator test sandbox denies with `NSPOSIXErrorDomain Code=1 "Operation not permitted"`. So the guard offers false assurance two different ways: the wrong selector is a false green (0 tests, `TEST SUCCEEDED`), and the right selector is a hard red that has nothing to do with copy content.

Net: the **copy** is ship-ready for Portfolio-Level Correlation. The **automated guard** needs a test-infrastructure fix before it can be relied on in CI. This is a test-harness defect, not a copy defect.

---

## Findings

### HIGH

#### HIGH-1: `ComplianceCopyGuardTests.productCopyHasNoTradingInstructionPhrases()` cannot pass on the iOS simulator (sandbox EPERM), so the scanner test provides false assurance

Files:
- `Cosmo TraderTests/Services/ComplianceCopyGuardTests.swift:8-29` (the failing test)
- `Cosmo TraderTests/Services/ComplianceCopyGuardTests.swift:74-79` (`repositoryRoot()` via `#filePath`)

Evidence (this review, healthy iPhone 17 Pro / iOS 26.5 simulator, correct selector):
- `-only-testing:'Cosmo TraderTests/ComplianceCopyGuardTests'` → `** TEST FAILED **`.
- The four sub-tests resolve as: `scannerCatchesKnownBadPhrases` ✅, `scannerAllowsExplicitNonAdviceDisclaimers` ✅, `cosmicEventMessagesAreComplianceSafe` ✅, `productCopyHasNoTradingInstructionPhrases` ❌.
- xcresult failure payload (verbatim):
  > "CosmicEvent.swift" couldn't be opened because you don't have permission to view it.
  > `NSFilePath=/Users/.../Cosmo Trader/Cosmo Trader/Models/CosmicEvent.swift`
  > `NSUnderlyingError=… {Error Domain=NSPOSIXErrorDomain Code=1 "Operation not permitted"}`
- The test throws on the **first** scanned path (`CosmicEvent.swift`); it never scans any content. The three passing sub-tests are all pure in-memory (they never touch the filesystem), which is exactly why they pass while this one fails.

Why it matters:
- The only sub-test that actually scans the production source files is the one that cannot run on the simulator. The "compliance scanner" therefore protects nothing on the one destination CI can run. The protection that genuinely works today is `Scripts/production_mock_guard.sh` (a shell script that runs natively on macOS) — but that guard only checks a handful of hardcoded literal strings, not the scanner's full 23-rule set + allowlist.
- This is the mirror image of the false-green selector problem: even after fixing the selector, the test is red-by-construction for a reason unrelated to copy.

Important scope note: **the copy itself is clean.** This finding is about the *test harness*, not the product copy. Verified independently below (§Verification 1-3).

Recommended fix (any one):
1. Re-home the scanner as a **native macOS test target** (host `macosx`, no app sandbox) so `String(contentsOf:)` can read the repo.
2. Convert the file-scan into a build-time / SwiftPM plugin or a standalone `swift` script invoked from `production_mock_guard.sh`, and keep only the in-memory rule/allowlist tests (`scannerCatchesKnownBadPhrases`, `scannerAllowsExplicitNonAdviceDisclaimers`, `cosmicEventMessagesAreComplianceSafe`) in the iOS test target.
3. Bundle the scanned source files into the test bundle as resources and read them via `Bundle(for:).url(forResource:)` instead of host `#filePath` paths.
4. Port the full rule set into `production_mock_guard.sh` so the shell guard is the source of truth and the XCTest layer only validates scanner logic in-memory.

Until one of these lands, do **not** treat a green `ComplianceCopyGuardTests` run as evidence the product copy is clean, and do not wire the current test into CI as a copy gate.

### MEDIUM

#### MEDIUM-1: The documented/used focused test command selects 0 tests (false green)

Evidence (reproduced this review):
- `-only-testing:'Cosmo TraderTests/Services/ComplianceCopyGuardTests'` → `** TEST SUCCEEDED **` with **no** `ComplianceCopyGuardTests` suite executed (no "Test case … passed/failed" lines for it). Silent 0-test pass.

Root cause:
- Xcode `-only-testing` identifiers are `TargetName/SuiteName[/testMethod]`. They do **not** contain the on-disk folder. `Services/` is a directory inside the test target, not part of the test identifier. `Cosmo TraderTests/Services/ComplianceCopyGuardTests` is parsed as target `Cosmo TraderTests`, suite `Services`, test `ComplianceCopyGuardTests` — none of which resolve — so nothing is selected and the run trivially "succeeds."

Correct focused command:
```
xcodebuild -project 'Cosmo Trader.xcodeproj' -scheme 'Cosmo Trader' -configuration Debug \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5' \
  CODE_SIGNING_ALLOWED=NO \
  -only-testing:'Cosmo TraderTests/ComplianceCopyGuardTests' \
  test
```
(Suite name only — no `Services/` path component. Same pattern for `AstroCorrelationServiceTests`, `CosmicMoodServiceTests`, `ProductionMockGuardTests`, `FinancialDataProvenanceTests`.)

Recommendation: any CI step using `-only-testing` should also assert a nonzero executed-test count (xcodebuild does not fail on 0 selected). Note that with the correct selector this particular suite goes red due to HIGH-1 — so fix HIGH-1 first, then the selector.

### LOW

#### LOW-1: `production_mock_guard.sh` is the real file-scan guard but only checks a few literal strings, not the full rule set

`Scripts/production_mock_guard.sh` passes (`production_mock_guard: passed`) and is the only file-scanning guard that runs natively. But it greps for a small set of exact phrases. It is not a substitute for the 23-rule scanner. If the team relies on the shell guard as the durable protection (recommended, per HIGH-1), port the scanner's rule set into it.

#### LOW-2: Widget extension still emits "Bullish"/"Bearish" sentiment literals while the main app softened them

- Main app `MoonPhase.MarketSentiment` raw values were softened to `"Constructive"` / `"Cooling"` (`Cosmo Trader/Models/MoonPhase.swift:296-298`).
- The widget target keeps `"Bullish"`/`"Bearish"` literals (`Cosmo Trader Widget/MoonPhaseWidget.swift:140-152`, `WidgetViews.swift:27-28,229-230,280`, `SharedWidgetData.swift:77-101`, and `Utils/WidgetDataManager.swift:365`).

"Bullish"/"Bearish" are standard market adjectives and are **not** on the banned list, so this is not a contract violation. But it is an inconsistency, and widgets are deferred (`reloadWidgetTimelines()` is a DEBUG no-op), so the surface is dormant. Worth aligning when widgets are enabled.

#### LOW-3: A few residual mildly-imperative phrases remain (already noted by Codex)

`CosmicPatternInterpreter.swift` ("Plant seeds now.", "Proceed with elevated caution.", "Patience required.") and `CosmicEvent.swift` ("Stay nimble.", "Be ready to pivot if the thesis changes."). None are trading instructions; none match the ban list. Optional tightening in a later voice pass.

---

## Verification Detail

### 1. Exact flagged phrases — PASS

Grep across all production Swift (`Cosmo Trader/` + `Cosmo Trader Widget/`, excluding tests) for:
- "Consider reducing position sizes" — 0 hits
- "Avoid starting new high-risk positions" — 0 hits
- "using smaller position sizes" — 0 hits
- "potential contrarian (buy|sell)" — 0 hits

### 2. Equivalent instruction language — PASS (with correct classification)

The sweep across the 17 scanned files surfaced only:
- Allowlisted disclaimers: `CosmicMoodIndex.swift:62,64` ("…not a prediction.", "…not a buy or sell signal."), `MoonPhase.swift:438` ("…not a prediction and not a trading signal."). The scanner's allowlist (`isAllowedSafeDisclaimer`) correctly permits these — and `scannerAllowsExplicitNonAdviceDisclaimers()` passed in-simulator, proving the allowlist works.
- Enum **case identifiers** (`.hold`, `case hold`, `case takeProfit`, `reduceRisk`, `avoidChasing`) — these are Swift identifiers, not string literals; the scanner only inspects string literals. Their user-facing **raw values** were rewritten to safe terms: `DailyReadingMove` → "Watchlist context" / "Steady context" / "Risk review" / "Hype check" / "Confirmation check" (`DailyFinancialReading.swift:49-55`); `MoonPhase.SignalType` → "Fresh Cycle" / "Building Context" / "Review" / "Distribution" / "Reflection" (`MoonPhase.swift:260-267`); `MarketSentiment` → "Constructive" / "Cooling" (`MoonPhase.swift:296-298`).
- One comment (`StockDetailView.swift:480` "…so avoid rendering generated samples…") — the scanner skips `//` comments.

Independent Python re-implementation of the scanner (same 23 rules, same allowlist, same literal-extraction incl. `//`, `/* */`, `"""`, escapes) run natively against the working tree: **TOTAL VIOLATIONS: 0**.

### 3. `isExtremeReading()` — PASS

`Cosmo Trader/Services/CosmicMoodService.swift:411-425` no longer contains "buy signal" / "sell signal". Returns contrarian-context language; gated on `isMarketBacked`; no production consumer renders it.

### 4. Legal disclaimers not over-blocked — PASS

- `Views/Legal/LegalViews.swift` is **not** in `ComplianceCopyScanner.scannedPaths`, so its "recommendation to buy, sell, or hold any security" disclaimer is never scanned and cannot be blocked.
- Within scanned files, the allowlist permits negated-safety phrasings ("not a buy or sell signal", "not a prediction", "not a trade signal", "not guaranteed"). `scannerAllowsExplicitNonAdviceDisclaimers()` ✅ in-simulator.
- Caveat: the `hold` and `avoid` rules have **no** allowlist branch — any scanned-file string literal containing the bare words "hold"/"avoid" would be an unconditional violation. None exist today (verified), but a future legitimate disclaimer using those words inside a scanned file would be wrongly flagged. Minor latent over-block risk; note for whoever ports the rules into the shell guard.

### 5. `ComplianceCopyGuardTests` target membership — CONFIRMED (yes, it is a member)

Definitive, from `Cosmo Trader.xcodeproj/project.pbxproj`:
- The `Cosmo TraderTests` target (`23AC0A30…`) declares `fileSystemSynchronizedGroups = (23AC0A34… /* Cosmo TraderTests */)` with **no** associated `PBXFileSystemSynchronizedBuildFileExceptionSet`.
- The **only** exception set in the project (`23E31334…`) is scoped to *"Cosmo Trader" folder in "Cosmo Trader" target* (the main app) — it excludes config/docs files from the app target, and has nothing to do with the test target.
- Therefore every file under `Cosmo TraderTests/` — including `Services/ComplianceCopyGuardTests.swift` — is auto-membered in the test target. Confirmed empirically: the suite's three in-memory sub-tests executed and passed, which is only possible if the file compiled into the test bundle.

### 6. Correct focused command + nonzero run — see MEDIUM-1 + HIGH-1

- Wrong (folder-style) selector → 0 tests, false `TEST SUCCEEDED` (reproduced).
- Correct selector (`Cosmo TraderTests/ComplianceCopyGuardTests`) → suite executes; 3 pass, 1 fails on sandbox EPERM (HIGH-1).
- The earlier `NSMachErrorDomain Code=-308` Codex hit was transient simulator instability, separate from both the selector bug and the EPERM bug. On a healthy simulator this run completes and the EPERM failure is deterministic.

Separation of the three distinct issues Codex conflated:
- **Test-target membership issue?** No — the file is target-membered (§5).
- **Wrong `-only-testing` selector?** Yes — folder-style selector selects 0 (MEDIUM-1).
- **Simulator/runtime instability?** Was a one-off (`-308`) in Codex's run; not the root cause. The durable root cause is the sandbox EPERM on host-file reads (HIGH-1).

### 7. Regression suites — PASS

Run with correct selectors on iPhone 17 Pro / iOS 26.5: **102 passed, 0 failed**, `** TEST SUCCEEDED **` across:
- `AstroCorrelationServiceTests` — Stock-Level Correlation safe-copy + provenance gating invariants intact.
- `CosmicMoodServiceTests` — prior Cosmic Mood provenance fixes intact.
- `FinancialDataProvenanceTests` — `.mixed` provenance shape intact.
- `ProductionMockGuardTests` — runtime mock-data guards intact.
- `AstroOverlayEventServiceTests` — Phase 1 astro canary intact.

(These suites are all in-memory; none use the host-file-read pattern, which is why they pass on-simulator while `productCopy…` does not.)

### 8. Mock/fake/generated financial data — PASS

- `bash Scripts/production_mock_guard.sh` → `production_mock_guard: passed`.
- No new `Double.random` / `simulate*` / `generateMock*` / `MockOHLC` in financial production paths. The `randomElement()` hits that exist are non-financial copy variety (referral codes, horoscope/epitaph/headline text) and `ReferralService.simulateReferral()` (referral demo, not market data) — consistent with prior accepted state, not reintroduced fabricated financial facts.

---

## Prior Fixes Intact

- Cosmic Mood provenance (nullable score, `.cosmicContextOnly` / `.unavailable` / `.marketBackedScore`, coverage threshold) — `CosmicMoodServiceTests` green.
- Portfolio DAILY P/L + CHG% provenance (`portfolioDailyPLProvenance`, `changeCell`, `aggregateQuoteProvenance`) — preserved; `production_mock_guard.sh` still asserts the relevant strings.
- Stock-Level Correlation provenance/sample-size gating — `AstroCorrelationServiceTests` green.

---

## Readiness For Portfolio-Level Correlation MVP

**Copy/compliance substance: READY.** The trading-instruction copy is gone, verified independently by native scan; legal disclaimers are intact; correlation and provenance invariants still pass.

**Required preflight (test infrastructure, not copy):**
1. Fix HIGH-1 — re-home the file-scanning compliance test so it runs where it can read the repo (native macOS test target, bundled resources, or fold the rule set into `production_mock_guard.sh`). As written it is a guaranteed red on the iOS simulator and a false green under the folder-style selector — either way it does not protect the copy.
2. Use the corrected `-only-testing` selector (no `Services/` component) anywhere this suite is invoked, and have CI assert a nonzero executed count.

These are guard-reliability fixes. They do not block starting Portfolio-Level Correlation, but they should land before the compliance scanner is trusted as a merge gate — otherwise future copy regressions will slip past both the false-green selector and the unrunnable on-simulator test.

---

_Note: this document replaces the earlier self-review's "execution inconclusive" conclusion with a definitive root-cause diagnosis (sandbox EPERM on host-file reads) and a confirmed target-membership result._
