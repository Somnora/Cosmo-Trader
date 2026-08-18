import Testing

// Any test that writes AppState-persisted UserDefaults keys — the shared
// `com.cosmotrader.userProfile` profile key, the `firstRunDataSetup*` flags,
// or the `subscription_*` keys cleared by `AppState.deleteAllUserData()` —
// must live under this parent. `AppState(user:)` reads and writes real
// `UserDefaults.standard` storage, so parallel suites racing on that same
// storage can interleave a write from one test into another test's read.
// Swift Testing applies `.serialized` recursively to nested suites, so
// nesting a suite here (via `extension AppStatePersistenceSuites { ... }`
// in that suite's own file) keeps it from running concurrently with every
// other suite nested here. Adding a new persisting test elsewhere silently
// reopens the race this exists to close.
@Suite(.serialized)
enum AppStatePersistenceSuites {}
