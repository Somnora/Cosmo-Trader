# Cosmo Trader — Agent & Contributor Guide

Cosmo Trader is a SwiftUI iOS app that correlates stock movement with
astrological events ("Co-Star inside a Bloomberg terminal"). All displayed
market data must be honestly source-labeled — that constraint is enforced by
guard scripts, not convention.

## Before opening a PR

Run the local gate; CI runs the same scripts:

```bash
bash Scripts/production_mock_guard.sh   # data-honesty pins (fast, static)
bash Scripts/compliance_copy_guard.sh   # copy scan + focused Xcode tests
bash Scripts/view_size_ratchet.sh       # architecture ratchet (see below)
```

## Architecture rules

### Views render, view models load

SwiftUI views must not contain data fetching, service orchestration, or
business logic. That belongs in a `@MainActor @Observable` view model in
`Cosmo Trader/ViewModels/`, with dependencies injected through the
initializer and defaulted to the shared instances:

```swift
init(stock: Stock, stockAPIService: StockAPIService? = nil, ...) {
    self.stockAPIService = stockAPIService ?? .shared
    ...
}
```

The reference example is `StockDetailViewModel` + `StockDetailView`: the
view model owns the loading state and orchestration; the view holds a
`@State private var viewModel`, renders view-model state (thin forwarding
computed properties are fine), and forwards user intents.

**The rule is incremental, enforced by `Scripts/view_size_ratchet.sh`:**
the largest views may shrink but not grow. If your change trips the
ratchet, extract the logic you are adding (plus ideally some it touches)
into the screen's view model and lower the baseline to the new count. Do
not raise a baseline except for pure view code that cannot live elsewhere,
and say so explicitly in the PR description.

### Services

- New code should not add `Foo.shared` singletons reflexively; if a service
  exists only to serve one screen, make it a view-model dependency instead.
- `StockAPIService` is an actor: it owns quote caching, request coalescing,
  and Finnhub's 60/min budget. Do not call Finnhub around it.
- Historical candles come from Yahoo Finance via `HistoricalPriceService`;
  its provenance label is bound to the fetcher — never hardcode a provider
  name on a dataset.
- UI that updates on a schedule uses `TimelineView` (or a render-server
  `repeatForever` animation for continuous motion), never `Timer`.

### Data honesty

Every numeric market claim carries `FinancialDataProvenance` and renders a
`DataSourceIndicator`. Sample/demo data must be labeled as such. The guard
scripts pin these behaviors; if a guard line blocks a legitimate refactor,
update the pin to point at the new location of the same behavior — never
delete the behavior to satisfy the guard.

## Testing

- Unit tests live in `Cosmo TraderTests/` (Swift Testing). Run the focused
  compliance suite via `compliance_copy_guard.sh`; run the full bundle with
  `-only-testing:"Cosmo TraderTests"` before merging risky changes.
- Known pre-existing failures on main are tracked in the PR that introduced
  the fix or in the repo issues — do not silently re-baseline them.
