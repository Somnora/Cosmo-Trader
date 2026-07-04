# Prediction Ledger MVP — spec

**Goal:** Every day the Today tab makes cosmic claims about the market. Record
those claims as immutable, falsifiable predictions; score them against actual
closes; show the user a running **Cosmic Accuracy Score**. This is the
accountability loop the app is missing — it turns one-shot horoscope content
into a daily "was the cosmos right?" game, and it extends the existing
data-honesty culture to the astrology itself.

Entertainment framing throughout. Nothing here is, or may read as, investment
advice. All copy goes through `compliance_copy_guard.sh`.

---

## 1. Product behavior

### The daily loop

1. **Morning (any Today load before market close):** the app composes the
   Today horoscope as it does now. If the composition contains at least one
   *market-backed* cosmic signal, the ledger silently records today's
   **prediction record** — direction calls derived from the same historical
   stats the horoscope already displays. If nothing is market-backed, it
   records an explicit **no-call** ("the cosmos abstained today") — honesty
   about silence is content too.
2. **After close (next launch/foreground):** pending records are resolved
   against actual daily candles. Each claim becomes hit / miss / flat /
   unresolved.
3. **Scorecard:** a card on Today shows today's call and the running accuracy;
   tapping it opens the full scorecard — history, streak, per-cosmic-driver
   hit rates (Mercury retrograde vs. full moon vs. new moon), and the honest
   baseline line: *"Coin flip: 50%."*

### What gets predicted (max 3 claims per day)

| Claim | Subject | Derived from |
|---|---|---|
| Market | SPY | Best `MarketWeatherEventSummary` among active events |
| Portfolio | User's owned holdings (weighted) | Best `PortfolioCosmicCorrelationSummary` |
| Stock | Today's featured stock | Best `StockCosmicCorrelationSummary` on the `TodayStockCandidate` |

A claim is only recorded when its source summary is **market-backed**
(`displayMode == .marketBackedResult` / equivalent). Sample-only, partial,
insufficient, and unavailable summaries never create scored predictions —
same rule the UI already follows for showing numbers.

### Direction derivation (pure function)

Inputs per summary: `averageMarketReturn` (or per-scope equivalent),
`baselineMarketReturn`, `winRate`, `confidence`, `eventName`, `eventType`.

- edge = averageReturn − baselineReturn
- **bullish** if edge > 0 and winRate ≥ 0.55
- **bearish** if edge < 0 and winRate ≤ 0.45
- **neutral** otherwise (recorded and scored — neutral hits when the day is flat)

When several active events qualify, pick highest `CorrelationConfidence`,
tie-break on |edge|. The chosen event is the claim's **cosmic driver**.

### Scoring

- Actual outcome = the subject's return for the prediction's trading day,
  from **daily candles via `HistoricalPriceService`** (never quotes — candles
  are canonical, retroactively fetchable, and provenance-labeled).
  - Market: SPY close-over-previous-close return.
  - Stock: same for the symbol.
  - Portfolio: market-value-weighted return across owned holdings that have a
    candle for that date; if covered weight < 70% (reuse the composer's
    `numericPortfolioCoverageThreshold`), the claim resolves **unresolved**
    with an unavailability reason, not a guess.
- **Flat deadband:** |return| < 0.10% counts as flat.
- Result: `hit` (sign matches, or neutral+flat), `miss`, `flat` (directional
  call on a flat day — excluded from hit rate, shown as "push"), `unresolved`
  (no provider data — carries `FinancialDataProvenance.unavailable`).

### Integrity rules (non-negotiable)

1. **One record per ET calendar day.** First market-backed snapshot wins.
2. **Immutable once recorded.** Claims are never revised after recording;
   resolution only fills in outcomes.
3. **No after-the-fact predictions.** A record created after 4:00 p.m. ET on
   its trading day is stored but flagged `recordedAfterClose` and excluded
   from accuracy stats (rendered greyed in history). Records on non-trading
   days (no SPY candle exists for that date once resolution runs) resolve as
   `marketClosed` and are excluded from stats.
4. **Provenance everywhere.** Every outcome stores the provenance of the
   candle(s) used; the scorecard aggregates render a `DataSourceIndicator`
   like every other numeric surface.

### Copy / legal

- Card and scorecard carry the standard entertainment disclaimer (reuse the
  existing disclaimer strings where possible so the copy guard stays quiet).
- Language is always retrospective-observational: "the cosmos called it,"
  "Mercury went 3-for-7," never "buy/sell/should have."
- The scorecard explicitly teaches the null hypothesis: baseline 50% line,
  sample-size caveat under ~20 resolved predictions ("Early days — too few
  readings to mean anything"), reusing `CorrelationConfidence` semantics.

---

## 2. Data model

`Cosmo Trader/Models/PredictionLedger.swift` — all `Codable`, `Equatable`,
stable string raw values (these become backend API contracts in the
server-snapshot phase, so treat the coding keys as frozen once shipped).

```swift
enum PredictionDirection: String, Codable { case bullish, bearish, neutral }

enum PredictionSubject: Codable, Equatable {
    case market                      // SPY
    case portfolio                   // weighted owned holdings
    case stock(symbol: String)
}

struct PredictionClaim: Codable, Equatable, Identifiable {
    let id: UUID
    let subject: PredictionSubject
    let direction: PredictionDirection
    let cosmicDriver: String         // eventName, e.g. "Mercury Retrograde"
    let driverKind: String           // AstroOverlayEventKind rawValue
    let historicalWinRate: Double
    let historicalEdge: Double       // avg − baseline, percent
    let confidence: CorrelationConfidence
    var outcome: PredictionOutcome?  // nil until resolved
}

enum PredictionResult: String, Codable {
    case hit, miss, flat, unresolved, marketClosed
}

struct PredictionOutcome: Codable, Equatable {
    let result: PredictionResult
    let actualReturnPercent: Double? // nil when unresolved/marketClosed
    let resolvedAt: Date
    let provenance: FinancialDataProvenance   // already Codable
    let detail: String?              // e.g. unavailability reason
}

struct PredictionRecord: Codable, Equatable, Identifiable {
    let id: UUID
    let tradingDay: String           // "2026-07-06", ET calendar day — the key
    let recordedAt: Date
    let recordedAfterClose: Bool
    let claims: [PredictionClaim]    // empty ⇒ explicit no-call day
    var isFullyResolved: Bool { claims.allSatisfy { $0.outcome != nil } }
}

struct PredictionScorecard: Equatable {  // computed, not stored
    let resolvedCount: Int
    let hitRate: Double?             // nil under minimum sample
    let currentStreak: Int           // signed: + hits, − misses
    let perDriverKind: [String: DriverStats]  // kind → (hits, total)
    let provenance: FinancialDataProvenance   // aggregate of outcomes used
}
```

## 3. New components

All service work lives behind a view model per AGENTS.md; every new view is a
new file (Today's existing views are ratcheted — do not grow them).

### `Services/PredictionLedgerStore.swift`
File-backed JSON store modeled on `HistoricalPriceCache` (Application
Support, injectable `FileManager` + directory URL for tests). API:

```swift
@MainActor final class PredictionLedgerStore {
    func record(for tradingDay: String) -> PredictionRecord?
    func insertIfAbsent(_ record: PredictionRecord) -> Bool   // integrity rule 1
    func applyOutcome(_ outcome: PredictionOutcome, claimID: UUID, on tradingDay: String)
    func allRecords() -> [PredictionRecord]                   // newest first
    func pendingRecords(asOf now: Date) -> [PredictionRecord] // past days, unresolved
}
```

Single JSON file (`prediction-ledger.json`), loaded once, saved atomically on
mutation. Volume is ~1 record/day — no need for anything heavier.

### `Services/PredictionExtractor.swift`
**Pure, stateless, fully unit-testable.** Takes the raw inputs the view model
already holds (NOT the display-string summary):

```swift
struct PredictionExtractor {
    func makeRecord(
        date: Date,                  // injectable clock, ET conversions inside
        marketWeather: MarketWeatherSummary?,
        portfolioSummaries: [PortfolioCosmicCorrelationSummary],
        stockCandidate: TodayStockCandidate?
    ) -> PredictionRecord
}
```

Owns direction derivation, the market-backed filter, event selection,
after-close flagging, and ET trading-day computation
(`TimeZone(identifier: "America/New_York")`).

### `Services/PredictionScoringService.swift`
Resolves pending records. Dependencies injected, defaulting to shared
(`HistoricalPriceService`, store, `now: Date = Date()` clock — same pattern as
`WatchlistCorrelationService`).

- For each pending record older than today (ET): fetch daily candles for SPY
  + claim symbols via `HistoricalPriceService` (short timeframe; served from
  `HistoricalPriceCache` when warm).
- No SPY candle for that date but candles exist for later dates ⇒ the whole
  record resolves `marketClosed`.
- Candle fetch fails ⇒ leave pending (retry next launch); after 7 calendar
  days, resolve `unresolved` with the provider-unavailable reason.
- Portfolio return: weight by `marketValue` captured **at recording time**
  (store weights on the claim — do not re-read the live portfolio, which may
  have changed; add `weights: [String: Double]?` to the portfolio claim).

### `ViewModels/PredictionLedgerViewModel.swift`
`@MainActor @Observable`. Owns: today's record, the computed
`PredictionScorecard`, loading state. Intents: `recordIfNeeded(...)` (called
by `TodayMarketHoroscopeViewModel` after its `compose` inputs are loaded —
one extractor call + `insertIfAbsent`), `resolvePending()` (called on Today
load, off the critical paint path — fire after `summary` is set).

### Views (new files, ratchet-safe)
- `Views/Components/TodayPredictionCard.swift` — today's call ("♂ Mars square
  Saturn — cosmos leans **bearish** on SPY"), yesterday's result if just
  resolved, running accuracy chip, `DataSourceIndicator`. No-call days render
  the abstain state. Slots into `DailyBriefBackendView`'s `LazyVStack`
  directly under `TodayMarketHoroscopeView`.
- `Views/Today/CosmicScorecardView.swift` — pushed from the card: hit-rate
  header vs. the 50% baseline, streak, per-driver table ("Full Moon 4/6 ·
  Mercury Rx 2/5"), reverse-chron history list (greyed after-close /
  market-closed rows), disclaimer footer.

## 4. Required supporting changes

- **`FinancialDataProvenance`** is already `Codable` with explicit coding
  keys (`Models/FinancialDataProvenance.swift:3`) — no change needed; the
  outcome struct can embed it directly.
- **`TodayMarketHoroscopeViewModel`**: after loading
  `marketWeather`/`portfolioSummaries`/`stockCandidate`, hand them to
  `PredictionLedgerViewModel.recordIfNeeded` (injected dependency, defaulted).
  ~6 lines; keeps the composer untouched.
- **Guard scripts:** add a pin to `production_mock_guard.sh` asserting the
  extractor filters on market-backed display modes (grep for the guard
  clause), so nobody quietly starts scoring sample data. New copy strings
  must pass `compliance_copy_guard.sh`.
- **Optional (phase C polish):** `NotificationService` schedules a local
  notification at ~4:45 p.m. ET on days with a directional call ("Market
  closed — see if the cosmos called it"). Behind a settings toggle, default
  off. Not MVP-blocking.

## 5. Phasing

| Phase | Ships | Why separate |
|---|---|---|
| **A — silent recorder** | Models, store, extractor, VM hook. No UI. | Ledger starts accumulating real history immediately; integrity rules soak before anything is displayed. |
| **B — scorer** | Scoring service + resolve-on-launch + unit suite. | Pure logic, heaviest test surface. |
| **C — surfaces** | Prediction card, scorecard view, disclaimer copy, (optional) close notification, share-card variant reusing `CosmicReportCard`. | UI lands on top of already-verified data. |
| **D — later** | Move record/score server-side with the backend snapshot refactor; ledger syncs via profile like portfolio/watchlist. | Models are Codable with frozen keys precisely so this is a transport change, not a redesign. |

A and B can be one PR each; C is 1–2 PRs. Each phase passes the full guard
gate before merge.

## 6. Test plan (Swift Testing, `Cosmo TraderTests/`)

**PredictionExtractorTests** — the core suite:
- market-backed weather summary → correct direction for bullish/bearish/
  neutral threshold edges (winRate 0.55/0.45 boundaries, zero edge)
- sample-only / partial / insufficient / unavailable summaries → no claim
- no market-backed anything → no-call record (empty claims, still recorded)
- multiple active events → highest confidence wins, |edge| tie-break
- recorded at 3:59 p.m. vs 4:01 p.m. ET → `recordedAfterClose` flips
  (injectable clock; pin ET, not device timezone)
- portfolio claim captures weights at recording time

**PredictionScoringTests:**
- sign match / mismatch / deadband flat (±0.09% vs ±0.11%) for each direction
- neutral + flat ⇒ hit; neutral + move ⇒ miss
- missing SPY candle with later candles present ⇒ `marketClosed`
- provider failure ⇒ stays pending; >7 days ⇒ `unresolved` with provenance
- portfolio coverage below 70% weight ⇒ `unresolved`
- weights from record used, not current portfolio (mutate portfolio between
  record and resolve in the fixture)

**PredictionLedgerStoreTests:**
- round-trip persistence; `insertIfAbsent` rejects a second record for the
  same trading day; `applyOutcome` cannot alter claim fields; corrupt file on
  disk ⇒ store recovers empty without crashing

**Scorecard math:** hit rate excludes flat/unresolved/marketClosed/
after-close; streak sign; per-driver rollup; nil hit rate under minimum
sample.

## 7. Explicitly out of scope (MVP)

- Real-money anything, intraday predictions, options.
- Cosmic Bets / credits staking (separate feature; consumes this ledger).
- Server-side recording/scoring and cross-device sync (phase D).
- Backfilling history before the feature ships — the ledger only ever
  contains predictions actually made. No retroactive "we would have said."
