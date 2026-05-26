# SDK Integration Notes

## Third-party analytics — v1 status: **NOT SHIPPED**

This release intentionally ships **no third-party behavioural-analytics or
crash-reporting SDK**. `AnalyticsService` is a local-only event recorder
(in-memory queue + DEBUG console logging). Nothing leaves the device.

This is reflected in:

- `Cosmo Trader/PrivacyInfo.xcprivacy` — `NSPrivacyTracking = false`, no
  tracking domains, no collected data types.
- `Cosmo Trader/Views/Legal/LegalViews.swift` — the in-app privacy policy
  documents only Finnhub, Firebase Authentication, and Apple App Store.

If a future release adds tracking analytics, all of the following must
be updated in the same change:

1. `PrivacyInfo.xcprivacy` — flip `NSPrivacyTracking` and add the new
   `NSPrivacyTrackingDomains` / `NSPrivacyCollectedDataTypes`.
2. `LegalViews.PrivacyPolicyView` — disclose the new processor in both
   "DATA WE COLLECT" and "THIRD-PARTY SERVICES".
3. App Store Connect privacy questionnaire.
4. ATT prompt copy and gating, if the SDK falls under tracking.
5. `AnalyticsService.setOptOut(_:)` — ensure the opt-out actually halts
   transmission, not just the local buffer.

### Re-enabling Mixpanel (future, optional)

Historical instructions left for reference. The previous `MixpanelProvider`
shim has been deleted; reintroducing it requires reverting that deletion
in addition to the steps below.

1. Add Mixpanel SDK via Swift Package Manager:
   - File > Add Package Dependencies
   - Enter: `https://github.com/mixpanel/mixpanel-swift`
2. Configure token in `Secrets.plist`.
3. Make sure all five privacy/disclosure touchpoints above are updated in
   the same PR.

### Re-enabling Firebase Crashlytics (future, optional)

The previous `CrashReportingService` shim has been deleted. To reintroduce:

1. Add `FirebaseCrashlytics` to the Swift Package selection (already linked:
   `FirebaseAuth`, `FirebaseCore`).
2. Re-add a thin recorder service.
3. Disclose in `PrivacyPolicyView` and `PrivacyInfo.xcprivacy`.

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
