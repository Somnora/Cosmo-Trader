import Foundation
import Testing
@testable import Cosmo_Trader

/// Privacy-contract tests for `AnalyticsService`.
///
/// These exist to prevent the regression where raw search queries or
/// localized error descriptions leaked into analytics payloads. Even with
/// the v1 stance of "no tracking SDK linked", the call-site shape matters:
/// if a tracking SDK is added later, these tests guarantee the worst-case
/// payload still contains no free-text user input.
@MainActor
struct AnalyticsPrivacyTests {

    // MARK: - Search analytics

    @Test("trackSearchPerformed payload contains no raw query and no `search_query` key")
    func searchPerformedHasNoRawQuery() {
        let service = AnalyticsService.shared
        // Make sure no prior opt-out from another test blocks the buffer.
        service.setOptOut(false)
        service.clearEventBuffer()

        // Use a value that would obviously stand out if it leaked.
        let sensitiveQuery = "tesla earnings password reset"

        service.trackSearchPerformed(
            queryLength: sensitiveQuery.count,
            resultCount: 7,
            searchSource: "discover"
        )

        guard let latest = service.bufferedEvents.last else {
            Issue.record("expected one buffered event")
            return
        }
        let params = latest.params?.dictionary ?? [:]

        // No raw query in any form.
        #expect(params["search_query"] == nil)
        #expect(params["selected_query"] == nil)
        #expect(params["query"] == nil)
        for value in params.values {
            #expect((value as? String)?.contains("tesla") != true,
                    "no payload value should contain the raw query substring")
        }

        // Privacy-safe fields are present and correct.
        #expect(params["query_length"] as? Int == sensitiveQuery.count)
        #expect(params["result_count"] as? Int == 7)
        #expect(params["had_results"] as? Bool == true)
        #expect(params["search_source"] as? String == "discover")
    }

    @Test("trackSearchResultSelected payload contains no raw query and the canonical safe fields")
    func searchResultSelectedHasNoRawQuery() {
        let service = AnalyticsService.shared
        service.setOptOut(false)
        service.clearEventBuffer()

        service.trackSearchResultSelected(
            queryLength: 6,
            position: 2,
            selectedSymbol: "AAPL",
            assetType: "stock",
            searchSource: "global"
        )

        guard let latest = service.bufferedEvents.last else {
            Issue.record("expected one buffered event")
            return
        }
        let params = latest.params?.dictionary ?? [:]

        #expect(params["search_query"] == nil)
        #expect(params["selected_query"] == nil)
        #expect(params["query"] == nil)

        #expect(params["query_length"] as? Int == 6)
        #expect(params["result_position"] as? Int == 2)
        #expect(params["selected_symbol"] as? String == "AAPL")
        #expect(params["asset_type"] as? String == "stock")
        #expect(params["search_source"] as? String == "global")
    }

    @Test("trackSearchPerformed clamps negative inputs to 0")
    func searchPerformedClampsNegatives() {
        let service = AnalyticsService.shared
        service.setOptOut(false)
        service.clearEventBuffer()

        service.trackSearchPerformed(queryLength: -5, resultCount: -3, searchSource: "discover")

        guard let latest = service.bufferedEvents.last else {
            Issue.record("expected one buffered event")
            return
        }
        let params = latest.params?.dictionary ?? [:]
        #expect(params["query_length"] as? Int == 0)
        #expect(params["result_count"] as? Int == 0)
        #expect(params["had_results"] as? Bool == false)
    }

    // MARK: - Error analytics

    @Test("AnalyticsParameters.error rejects free-text fields and exposes only structured ones")
    func errorParametersAreStructuredOnly() {
        let params = AnalyticsParameters.error(
            domain: "com.cosmotrader.NetworkError",
            code: 1001,
            screen: "Portfolio",
            feature: "refresh",
            networkStatus: "offline",
            isRetriable: true
        )

        let dict = params.dictionary

        // Privacy-safe structured fields are present.
        #expect(dict["error_domain"] as? String == "com.cosmotrader.NetworkError")
        #expect(dict["error_code"] as? Int == 1001)
        #expect(dict["screen"] as? String == "Portfolio")
        #expect(dict["feature"] as? String == "refresh")
        #expect(dict["network_status"] as? String == "offline")
        #expect(dict["is_retriable"] as? Bool == true)

        // Free-text fields are explicitly absent.
        #expect(dict["error_message"] == nil)
        #expect(dict["message"] == nil)
        #expect(dict["localized_description"] == nil)
        #expect(dict["description"] == nil)
    }

    @Test("trackError(domain:code:) emits no localized description even when given a real Error")
    func trackErrorBuffersNoLocalizedDescription() {
        let service = AnalyticsService.shared
        service.setOptOut(false)
        service.clearEventBuffer()

        // Simulate the kind of error a caller might have:
        let sensitive = NSError(
            domain: "com.cosmotrader.NetworkError",
            code: 1001,
            userInfo: [NSLocalizedDescriptionKey: "Could not reach https://internal.example.com/secret?token=abc"]
        )

        // The new API does not accept Error at all — callers must translate
        // to (domain, code, ...). This test proves that *if* a caller does
        // the translation, no fragment of localizedDescription reaches the
        // buffered event.
        service.trackError(
            domain: sensitive.domain,
            code: sensitive.code,
            screen: "Portfolio",
            feature: "refresh",
            networkStatus: "offline",
            isRetriable: true
        )

        guard let latest = service.bufferedEvents.last else {
            Issue.record("expected one buffered event")
            return
        }
        let params = latest.params?.dictionary ?? [:]

        for value in params.values {
            #expect((value as? String)?.contains("internal.example.com") != true,
                    "no payload value may contain the URL fragment from localizedDescription")
            #expect((value as? String)?.contains("secret?token") != true,
                    "no payload value may contain query-string fragments")
            #expect((value as? String)?.contains("Could not reach") != true,
                    "no payload value may contain the localized error sentence")
        }
        #expect(params["error_domain"] as? String == "com.cosmotrader.NetworkError")
        #expect(params["error_code"] as? Int == 1001)
    }

    // MARK: - Opt-out enforcement

    @Test("setOptOut(true) clears the in-memory buffer and stops further events")
    func optOutClearsAndStopsBuffer() {
        let service = AnalyticsService.shared
        service.setOptOut(false)
        service.clearEventBuffer()

        service.trackSearchPerformed(queryLength: 4, resultCount: 1, searchSource: "discover")
        #expect(service.bufferedEvents.count >= 1)

        service.setOptOut(true)
        #expect(service.bufferedEvents.isEmpty, "buffer must be cleared on opt-out")

        // Further events must not enqueue.
        service.trackSearchPerformed(queryLength: 4, resultCount: 1, searchSource: "discover")
        #expect(service.bufferedEvents.isEmpty, "no events should enqueue while opted out")

        // Restore opt-in state for any later tests.
        service.setOptOut(false)
    }
}
