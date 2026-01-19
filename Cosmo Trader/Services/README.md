# Services/

This directory contains all business logic services for Cosmo Trader.

## Service Catalog

| Service | Purpose | Singleton |
|---------|---------|-----------|
| `StockAPIService` | Finnhub API integration for real-time quotes | `.shared` |
| `SearchService` | Stock symbol search with debouncing | `.shared` |
| `NotificationService` | Push notification scheduling | `.shared` |
| `SubscriptionManager` | StoreKit 2 subscription handling | `.shared` |
| `NetworkMonitor` | Connectivity monitoring (NWPathMonitor) | `.shared` |
| `ChartPatternService` | Technical analysis pattern detection | `.shared` |
| `HoroscopeGenerator` | Daily horoscope generation | `.shared` |
| `MoonPhaseService` | Lunar phase calculations | `.shared` |
| `VoidOfCourseMoonService` | Void-of-course moon periods | `.shared` |
| `MercuryRetrogradeService` | Mercury retrograde tracking | `.shared` |
| `SignSeasonService` | Zodiac season transitions | `.shared` |
| `SaturnReturnService` | Saturn return cycle analysis | `.shared` |
| `CompatibilityCalculator` | User-stock zodiac matching | Static methods |
| `PortfolioCompatibilityService` | Portfolio-wide analysis | Static methods |
| `VolumeService` | Volume leader tracking | `.shared` |
| `EarningsService` | Earnings calendar data | `.shared` |
| `IPOService` | IPO calendar and details | `.shared` |
| `AnalyticsService` | Event tracking (TelemetryDeck) | `.shared` |
| `KarmicLedgerService` | Investment lesson tracking | `.shared` |
| `CosmicMoodService` | Market sentiment analysis | `.shared` |
| `ErrorHandling` | Error types and retry logic | Types only |

## Architecture Patterns

### Singleton Access

All services follow the singleton pattern for app-wide state:

```swift
let quote = try await StockAPIService.shared.getQuote(symbol: "AAPL")
```

### Thread Safety

Services are `@MainActor` isolated for UI-safe state updates:

```swift
@MainActor
final class StockAPIService: ObservableObject {
    static let shared = StockAPIService()
    @Published var isLoading: Bool = false
}
```

### Async/Await

Network operations use Swift Concurrency:

```swift
func getQuote(symbol: String) async throws -> StockQuote {
    // Async network call
}
```

### Error Handling

All network operations throw `NetworkError`:

```swift
do {
    let quote = try await service.getQuote(symbol: "AAPL")
} catch let error as NetworkError {
    switch error {
    case .rateLimited:
        // Handle rate limit
    case .noConnection:
        // Handle offline
    default:
        // Show error
    }
}
```

## Key Service Details

### StockAPIService

Primary API integration for Finnhub:

- **Rate Limiting**: 60 requests/minute enforcement
- **Caching**: 60-second in-memory cache
- **Offline Support**: Returns stale cache when offline
- **Retry Logic**: Automatic retry with exponential backoff

### SearchService

Debounced symbol search:

- **Debounce**: 300ms delay before API call
- **Cancellation**: Previous searches cancelled on new input
- **Recent Searches**: Persisted to UserDefaults

### SubscriptionManager

StoreKit 2 integration:

- **Products**: Oracle tier subscription
- **Entitlements**: Handles purchase verification
- **Restore**: Supports purchase restoration

### AnalyticsService

Privacy-first analytics via TelemetryDeck:

- **No PII**: No personal data collected
- **Opt-out**: Respects user preferences
- **Events**: Screen views, feature usage, errors

## Adding New Services

1. Create file in `Services/` directory
2. Follow singleton pattern with `.shared`
3. Add `@MainActor` for UI-bound state
4. Use `async throws` for network operations
5. Throw `NetworkError` for failures
6. Add comprehensive DocC documentation
7. Update this README
