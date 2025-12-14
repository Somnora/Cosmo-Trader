# SDK Integration Notes

## Mixpanel Analytics

**Status**: Optional (uses conditional import)

The `MixpanelProvider` is designed to work with or without the Mixpanel SDK installed:
- When SDK is **not installed**: Analytics calls are no-op (logged locally in DEBUG only)
- When SDK is **installed**: Events are forwarded to Mixpanel servers

### To Enable Mixpanel

1. Add Mixpanel SDK via Swift Package Manager:
   - File > Add Package Dependencies
   - Enter: `https://github.com/mixpanel/mixpanel-swift`
   - Select version: 4.0.0+

2. Configure token in `Secrets.plist`:
   ```xml
   <key>MIXPANEL_TOKEN</key>
   <string>your-mixpanel-token</string>
   ```

3. Rebuild the app - the `#if canImport(Mixpanel)` directives will detect the SDK

### Privacy Notes
- All analytics are anonymized (no PII collected)
- User opt-out is supported via `setOptOut()`
- Super properties automatically strip sensitive keys

---

## Firebase Crashlytics

**Status**: Optional (uses conditional import)

The `CrashReportingService` works with or without Firebase installed:
- When SDK is **not installed**: Crash logs are printed to console only
- When SDK is **installed**: Crashes and non-fatal errors are sent to Firebase

### To Enable Firebase

1. Add Firebase SDK via Swift Package Manager:
   - Add: `https://github.com/firebase/firebase-ios-sdk`
   - Select: FirebaseAnalytics, FirebaseCrashlytics

2. Add `GoogleService-Info.plist` to the project

3. Build and run - `#if canImport(FirebaseCore)` will detect the SDK

---

## StoreKit

**Status**: Native (no external SDK needed)

StoreKit 2 is used for in-app purchases. Configure products in App Store Connect:
- `com.cosmotrader.premium.monthly` - Monthly subscription
- `com.cosmotrader.premium.yearly` - Yearly subscription

---

## Build Schemes

Three schemes are configured for different environments:

| Scheme | Configuration | APP_ENVIRONMENT |
|--------|--------------|-----------------|
| Cosmo Trader Debug | Debug | debug |
| Cosmo Trader Staging | Debug | staging |
| Cosmo Trader Release | Release | production |

The `AppEnvironment` enum reads from the environment variable to determine configuration.
