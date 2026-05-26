import Foundation
import Testing
@testable import Cosmo_Trader

/// Wire-format contract tests for payloads sent to the Cosmo backend.
///
/// These exist to catch silent JSON-key drift between the iOS request models
/// and the FastAPI route handlers. If a backend field
/// rename slips in without a matching iOS change (or vice versa), one of these
/// tests should fail before it reaches a real device.
@MainActor
struct CosmoAPIContractTests {

    // MARK: - Referral milestones

    @Test("ReferralMilestone exposes exactly the three canonical raw values")
    func referralMilestoneCanonicalSet() {
        let actual = Set(ReferralMilestone.allCases.map(\.rawValue))
        #expect(actual == ["first_profile_open", "first_watchlist_add", "first_swipe_session"])
    }

    @Test("ReferralMilestone qualification storage keys are derived from canonical raw values")
    func referralMilestoneStorageKeysUseCanonicalValues() {
        #expect(ReferralMilestone.firstProfileOpen.qualificationStorageKey == "referral_qualified_first_profile_open")
        #expect(ReferralMilestone.firstWatchlistAdd.qualificationStorageKey == "referral_qualified_first_watchlist_add")
        #expect(ReferralMilestone.firstSwipeSession.qualificationStorageKey == "referral_qualified_first_swipe_session")
    }

    @Test("ReferralMilestone rejects the legacy `added_first_watchlist_stock` string")
    func referralMilestoneRejectsLegacyAlias() {
        // Regression: the old iOS string `added_first_watchlist_stock` produced
        // 400 invalid_milestone responses from backend_v0. The fix renames it
        // to `first_watchlist_add` — and this test stops it coming back.
        #expect(ReferralMilestone.validated("added_first_watchlist_stock") == nil)
        #expect(ReferralMilestone.validated("first_watchlist_add") == .firstWatchlistAdd)
    }

    @Test("ReferralMilestone validation is case-sensitive and trims nothing")
    func referralMilestoneValidationIsStrict() {
        #expect(ReferralMilestone.validated("FIRST_PROFILE_OPEN") == nil)
        #expect(ReferralMilestone.validated(" first_profile_open") == nil)
        #expect(ReferralMilestone.validated("") == nil)
    }

    // MARK: - Referral qualify payload

    @Test("ReferralQualifyRequest encodes a single `milestone` field with the raw value")
    func referralQualifyRequestEncoding() throws {
        let request = ReferralQualifyRequest(milestone: .firstWatchlistAdd)
        let json = try Self.jsonObject(encoding: request)
        #expect(json as? [String: String] == ["milestone": "first_watchlist_add"])
    }

    // MARK: - Referral apply payload

    @Test("ReferralApplyRequest encodes `code` and `deviceId` (camelCase) as backend_v0 expects")
    func referralApplyRequestEncoding() throws {
        let request = ReferralApplyRequest(code: "ABC123", deviceId: "device-42")
        let json = try Self.jsonObject(encoding: request)
        #expect(json as? [String: String] == ["code": "ABC123", "deviceId": "device-42"])
    }

    // MARK: - Push register payload

    @Test("PushRegisterRequest serialises every contract field (deviceId, token, tokenType, appVersion, buildNumber, platform, locale)")
    func pushRegisterRequestEncoding() throws {
        let request = PushRegisterRequest(
            deviceId: "device-42",
            token: "apns-token-abc",
            tokenType: .apns,
            appVersion: "1.2.3",
            buildNumber: "456",
            platform: "ios",
            locale: "en_US"
        )

        let json = try Self.jsonObject(encoding: request)
        let expected: [String: String] = [
            "deviceId": "device-42",
            "token": "apns-token-abc",
            "tokenType": "apns",
            "appVersion": "1.2.3",
            "buildNumber": "456",
            "platform": "ios",
            "locale": "en_US"
        ]
        #expect(json as? [String: String] == expected)
    }

    @Test("PushRegisterRequest tokenType is always `apns` or `fcm` (no `ios` confusion)")
    func pushRegisterRequestTokenTypeIsCanonical() throws {
        // Regression: an earlier client mapped iOS's device token to the
        // `platform` field with value "apns". The backend now requires the
        // canonical `tokenType` field with values "apns" or "fcm" — this test
        // freezes the new contract.
        let request = PushRegisterRequest(
            deviceId: "device-42",
            token: "apns-token-abc",
            tokenType: .apns,
            appVersion: "1.2.3",
            buildNumber: "456",
            platform: "ios",
            locale: "en_US"
        )

        let json = try Self.jsonObject(encoding: request)
        guard let dict = json as? [String: Any] else {
            Issue.record("expected dictionary, got \(type(of: json))")
            return
        }
        #expect(dict["tokenType"] as? String == "apns")
        #expect(dict["platform"] as? String == "ios")
    }

    @Test("PushTokenType rejects non-canonical token type strings")
    func pushTokenTypeValidationIsStrict() {
        #expect(PushTokenType.validated("apns") == .apns)
        #expect(PushTokenType.validated("fcm") == .fcm)
        #expect(PushTokenType.validated("ios") == nil)
        #expect(PushTokenType.validated("APNS") == nil)
    }

    // MARK: - Profile update payload

    @Test("UpdateUserProfileRequest encodes snake_case keys for /v1/me PUT")
    func updateUserProfileRequestEncoding() throws {
        let request = UpdateUserProfileRequest(
            zodiacSign: "aries",
            riskLevel: 42,
            notificationsEnabled: true
        )
        let json = try Self.jsonObject(encoding: request)
        guard let dict = json as? [String: Any] else {
            Issue.record("expected dictionary, got \(type(of: json))")
            return
        }
        #expect(dict["zodiac_sign"] as? String == "aries")
        #expect(dict["risk_level"] as? Int == 42)
        #expect(dict["notifications_enabled"] as? Bool == true)
    }

    // MARK: - Helpers

    private static func jsonObject<T: Encodable>(encoding value: T) throws -> Any {
        let data = try JSONEncoder().encode(value)
        return try JSONSerialization.jsonObject(with: data, options: [])
    }
}
