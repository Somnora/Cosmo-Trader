import Foundation

struct HealthResponse: Codable {
    let ok: Bool
    let service: String?
}

struct BuildInfoRouteChecks: Codable {
    let hasBriefToday: Bool?
    let hasInbox: Bool?
    let hasRewardsStatus: Bool?
    let hasWhoami: Bool?

    enum CodingKeys: String, CodingKey {
        case hasBriefToday = "has_brief_today"
        case hasInbox = "has_inbox"
        case hasRewardsStatus = "has_rewards_status"
        case hasWhoami = "has_whoami"
    }
}

struct BuildInfoResponse: Codable {
    let service: String
    let apiVersion: String
    let gitSha: String?
    let buildTime: String?
    let routeChecks: BuildInfoRouteChecks?

    enum CodingKeys: String, CodingKey {
        case service
        case apiVersion = "api_version"
        case gitSha = "git_sha"
        case buildTime = "build_time"
        case routeChecks = "route_checks"
    }
}

struct PingResponse: Codable {
    let ok: Bool
    let ping: String
}

struct V1HealthzResponse: Codable {
    let ok: Bool
    let service: String
    let projectConfigured: Bool

    enum CodingKeys: String, CodingKey {
        case ok
        case service
        case projectConfigured = "project_configured"
    }
}

struct WhoAmIResponse: Codable {
    let authMode: String
    let uid: String
    let projectConfigured: Bool

    enum CodingKeys: String, CodingKey {
        case authMode = "auth_mode"
        case uid
        case projectConfigured = "project_configured"
    }
}

struct ReferralApplyRequest: Codable {
    let code: String
    let deviceId: String
}

struct ReferralApplyResponse: Codable {
    let ok: Bool
    let referralId: String?
    let message: String?
}

struct ReferralQualifyRequest: Codable {
    let milestone: String

    init(milestone: ReferralMilestone) {
        self.milestone = milestone.rawValue
    }
}

struct ReferralQualifyResponse: Codable {
    let ok: Bool
    let status: String?
}

struct ReferralRedeemResponse: Codable {
    let ok: Bool
    let status: String
    let rewardGranted: Bool
    let creditsBalance: Int
    let premiumUntil: String?
    let idempotent: Bool?

    enum CodingKeys: String, CodingKey {
        case ok
        case status
        case rewardGranted = "reward_granted"
        case creditsBalance = "credits_balance"
        case premiumUntil = "premium_until"
        case idempotent
    }
}

enum PushTokenType: String, Codable, CaseIterable {
    case apns
    case fcm

    static func validated(_ rawValue: String) -> PushTokenType? {
        PushTokenType(rawValue: rawValue)
    }
}

struct PushRegisterRequest: Codable {
    let deviceId: String
    let token: String
    let tokenType: PushTokenType
    let appVersion: String
    let buildNumber: String
    let platform: String
    let locale: String
}

struct PushRegisterResponse: Codable {
    let ok: Bool
}

struct ReferralLeaderboardEntry: Codable {
    let uid: String
    let anonymizedName: String
    let referralRewardCount: Int
}

struct ReferralLeaderboardResponse: Codable {
    let leaders: [ReferralLeaderboardEntry]
}

struct BackendUserProfile: Codable {
    let uid: String
    let createdAt: String?
    let updatedAt: String?
    let zodiacSign: String?
    let riskLevel: Int?
    let notificationsEnabled: Bool?
    let lastSeenAt: String?
    let portfolio: [Stock]?
    let watchlist: [String]?

    enum CodingKeys: String, CodingKey {
        case uid
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case zodiacSign = "zodiac_sign"
        case riskLevel = "risk_level"
        case notificationsEnabled = "notifications_enabled"
        case lastSeenAt = "last_seen_at"
        case portfolio
        case watchlist
    }
}

struct UpdateUserProfileRequest: Codable {
    let zodiacSign: String?
    let riskLevel: Int?
    let notificationsEnabled: Bool?
    let portfolio: [Stock]?
    let watchlist: [String]?

    init(
        zodiacSign: String? = nil,
        riskLevel: Int? = nil,
        notificationsEnabled: Bool? = nil,
        portfolio: [Stock]? = nil,
        watchlist: [String]? = nil
    ) {
        self.zodiacSign = zodiacSign
        self.riskLevel = riskLevel
        self.notificationsEnabled = notificationsEnabled
        self.portfolio = portfolio
        self.watchlist = watchlist
    }

    enum CodingKeys: String, CodingKey {
        case zodiacSign = "zodiac_sign"
        case riskLevel = "risk_level"
        case notificationsEnabled = "notifications_enabled"
        case portfolio
        case watchlist
    }
}

struct DailyBriefResponse: Codable {
    let date: String
    let uid: String
    let createdAt: String?
    let briefText: String
    let moodTag: String?
    let signals: [String]?

    enum CodingKeys: String, CodingKey {
        case date
        case uid
        case createdAt = "created_at"
        case briefText = "brief_text"
        case moodTag = "mood_tag"
        case signals
    }
}

struct RewardsStatus: Codable {
    let creditsBalance: Int
    let premiumUntil: String?

    enum CodingKeys: String, CodingKey {
        case creditsBalance = "credits_balance"
        case premiumUntil = "premium_until"
    }
}

typealias RewardsStatusResponse = RewardsStatus

struct InboxItem: Codable, Identifiable {
    let id: String
    let uid: String
    let createdAt: String?
    let title: String
    let body: String
    let type: String
    let isRead: Bool
    let deepLink: String?
    let metadata: [String: String]?

    enum CodingKeys: String, CodingKey {
        case id
        case uid
        case createdAt = "created_at"
        case title
        case body
        case type
        case isRead = "is_read"
        case deepLink = "deep_link"
        case metadata
    }
}

struct InboxListResponse: Codable {
    let items: [InboxItem]
}

struct OkResponse: Codable {
    let ok: Bool
}

struct ErrorResponse: Codable {
    let detail: String?
}
