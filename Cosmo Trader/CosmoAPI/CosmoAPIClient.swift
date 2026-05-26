import Foundation

enum DailyBriefRequestError: Error {
    case unauthorized(statusCode: Int, sanitizedURL: String, message: String?)
    case server(statusCode: Int, sanitizedURL: String, message: String?)
}

final class CosmoAPIClient {
    private let config: CosmoBackendConfig
    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    init(config: CosmoBackendConfig = .load()) {
        self.config = config
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 15
        configuration.timeoutIntervalForResource = 15
        self.session = URLSession(configuration: configuration)
        self.decoder = JSONDecoder()
        self.encoder = JSONEncoder()
    }

    func health() async throws -> HealthResponse {
        try await send(path: "/health", method: "GET", body: Optional<EmptyBody>.none, requiresAuth: false)
    }

    func buildInfo() async throws -> BuildInfoResponse {
        try await send(path: "/__build_info", method: "GET", body: Optional<EmptyBody>.none, requiresAuth: false)
    }

    func ping() async throws -> PingResponse {
        try await send(path: "/v1/ping", method: "GET", body: Optional<EmptyBody>.none, requiresAuth: true)
    }

    func healthz() async throws -> V1HealthzResponse {
        try await send(path: "/v1/healthz", method: "GET", body: Optional<EmptyBody>.none, requiresAuth: true)
    }

    func whoami() async throws -> WhoAmIResponse {
        try await send(path: "/v1/whoami", method: "GET", body: Optional<EmptyBody>.none, requiresAuth: true)
    }

    func fetchMe() async throws -> BackendUserProfile {
        try await send(path: "/v1/me", method: "GET", body: Optional<EmptyBody>.none, requiresAuth: true)
    }

    func updateMe(request: UpdateUserProfileRequest) async throws -> BackendUserProfile {
        try await send(path: "/v1/me", method: "PUT", body: request, requiresAuth: true)
    }

    func fetchDailyBriefToday() async throws -> DailyBriefResponse {
        let url = config.baseURL
            .appendingPathComponent("v1")
            .appendingPathComponent("brief")
            .appendingPathComponent("today")

        #if DEBUG
        if url.path != "/v1/brief/today" {
            print("[DailyBrief] Warning: unexpected request path \(url.path)")
        }
        #endif

        let (statusCode, data, sanitizedURL) = try await sendRaw(
            url: url,
            method: "GET",
            body: Optional<EmptyBody>.none,
            requiresAuth: true
        )

        #if DEBUG
        print("[DailyBrief] GET \(sanitizedURL) -> \(statusCode)")
        #endif

        switch statusCode {
        case 200...299:
            return try decode(DailyBriefResponse.self, from: data)
        case 401:
            let message = decodeErrorMessage(from: data)
            throw DailyBriefRequestError.unauthorized(statusCode: statusCode, sanitizedURL: sanitizedURL, message: message)
        default:
            let message = decodeErrorMessage(from: data)
            throw DailyBriefRequestError.server(statusCode: statusCode, sanitizedURL: sanitizedURL, message: message)
        }
    }

    func referralLeaderboard(limit: Int? = nil) async throws -> ReferralLeaderboardResponse {
        var path = "/v1/referrals/leaderboard"
        if let limit {
            path += "?limit=\(limit)"
        }
        return try await send(path: path, method: "GET", body: Optional<EmptyBody>.none, requiresAuth: true)
    }

    func applyReferral(_ request: ReferralApplyRequest) async throws -> ReferralApplyResponse {
        try await send(path: "/v1/referrals/apply", method: "POST", body: request, requiresAuth: true)
    }

    func qualifyReferral(milestone: ReferralMilestone) async throws -> ReferralQualifyResponse {
        try await send(
            path: "/v1/referrals/qualify",
            method: "POST",
            body: ReferralQualifyRequest(milestone: milestone),
            requiresAuth: true
        )
    }

    func redeemReferralRewards() async throws -> ReferralRedeemResponse {
        try await send(
            path: "/v1/referrals/redeem",
            method: "POST",
            body: Optional<EmptyBody>.none,
            requiresAuth: true
        )
    }

    func registerPushToken(_ request: PushRegisterRequest) async throws -> PushRegisterResponse {
        try await send(path: "/v1/push/register", method: "POST", body: request, requiresAuth: true)
    }

    func rewardsStatus() async throws -> RewardsStatus {
        try await send(
            path: "/v1/rewards/status",
            method: "GET",
            body: Optional<EmptyBody>.none,
            requiresAuth: true
        )
    }

    func fetchRewardsStatus() async throws -> RewardsStatus {
        try await rewardsStatus()
    }

    func fetchInbox() async throws -> [InboxItem] {
        let response: InboxListResponse = try await send(
            path: "/v1/inbox",
            method: "GET",
            body: Optional<EmptyBody>.none,
            requiresAuth: true
        )
        return response.items
    }

    func markInboxRead(id: String) async throws {
        let encodedID = id.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? id
        let _: OkResponse = try await send(
            path: "/v1/inbox/\(encodedID)/read",
            method: "POST",
            body: Optional<EmptyBody>.none,
            requiresAuth: true
        )
    }

    func markInboxItemRead(id: String) async throws {
        try await markInboxRead(id: id)
    }

#if DEBUG
    func publishTestInboxItem() async throws -> InboxItem {
        try await send(
            path: "/v1/inbox/publish_test",
            method: "POST",
            body: Optional<EmptyBody>.none,
            requiresAuth: true
        )
    }
#endif

    func raw(path: String, method: String = "GET", requiresAuth: Bool = false) async throws -> (statusCode: Int, data: Data) {
        try await sendRaw(path: path, method: method, body: Optional<EmptyBody>.none, requiresAuth: requiresAuth)
    }
}

private extension CosmoAPIClient {
    struct EmptyBody: Encodable {}

    func send<T: Decodable, Body: Encodable>(
        path: String,
        method: String,
        body: Body?,
        requiresAuth: Bool
    ) async throws -> T {
        let (statusCode, data) = try await sendRaw(path: path, method: method, body: body, requiresAuth: requiresAuth)
        switch statusCode {
        case 200...299:
            return try decode(T.self, from: data)
        case 401:
            let message = decodeErrorMessage(from: data)
            throw CosmoAPIError.unauthorized(message: message)
        default:
            let message = decodeErrorMessage(from: data)
            throw CosmoAPIError.server(statusCode: statusCode, message: message)
        }
    }

    func sendRaw<Body: Encodable>(
        path: String,
        method: String,
        body: Body?,
        requiresAuth: Bool
    ) async throws -> (statusCode: Int, data: Data) {
        let request = try await buildRequest(path: path, method: method, body: body, requiresAuth: requiresAuth)
        do {
            let (data, response) = try await session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw CosmoAPIError.emptyResponse
            }
            return (httpResponse.statusCode, data)
        } catch let error as CosmoAPIError {
            throw error
        } catch {
            throw CosmoAPIError.transport(error)
        }
    }

    func sendRaw<Body: Encodable>(
        url: URL,
        method: String,
        body: Body?,
        requiresAuth: Bool
    ) async throws -> (statusCode: Int, data: Data, sanitizedURL: String) {
        let request = try await buildRequest(url: url, method: method, body: body, requiresAuth: requiresAuth)
        let sanitizedURL = sanitizedURLString(from: request.url)
        do {
            let (data, response) = try await session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw CosmoAPIError.emptyResponse
            }
            return (httpResponse.statusCode, data, sanitizedURL)
        } catch let error as CosmoAPIError {
            throw error
        } catch {
            throw CosmoAPIError.transport(error)
        }
    }

    func buildRequest<Body: Encodable>(
        path: String,
        method: String,
        body: Body?,
        requiresAuth: Bool
    ) async throws -> URLRequest {
        guard let url = URL(string: path, relativeTo: config.baseURL) else {
            throw CosmoAPIError.invalidURL
        }

        return try await buildRequest(url: url, method: method, body: body, requiresAuth: requiresAuth)
    }

    func buildRequest<Body: Encodable>(
        url: URL,
        method: String,
        body: Body?,
        requiresAuth: Bool
    ) async throws -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        if requiresAuth {
            if let token = await fetchIDToken() {
                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            } else if let apiKey = debugAPIKeyIfAvailable() {
                request.setValue(apiKey, forHTTPHeaderField: "X-Cosmo-Key")
            } else {
                throw CosmoAPIError.unauthorized(message: "Authentication unavailable.")
            }
        }

        if let body {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try encoder.encode(AnyEncodable(body))
        }

        return request
    }

    func sanitizedURLString(from url: URL?) -> String {
        guard let url else { return "unknown-url" }
        let host = url.host ?? "unknown-host"
        let hostWithPort = url.port.map { "\(host):\($0)" } ?? host
        let path = url.path.isEmpty ? "/" : url.path
        return "\(hostWithPort)\(path)"
    }

    func fetchIDToken() async -> String? {
        await AuthManager.shared.getIDTokenIfAvailable(forceRefresh: false)
    }

    func debugAPIKeyIfAvailable() -> String? {
        #if DEBUG
        guard let apiKey = config.apiKey, !apiKey.isEmpty else {
            return nil
        }
        return apiKey
        #else
        return nil
        #endif
    }

    func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw CosmoAPIError.decoding(error)
        }
    }

    func decodeErrorMessage(from data: Data) -> String? {
        guard !data.isEmpty else { return nil }
        return (try? decoder.decode(ErrorResponse.self, from: data))?.detail
    }
}

private struct AnyEncodable: Encodable {
    private let encodeClosure: (Encoder) throws -> Void

    init<T: Encodable>(_ value: T) {
        self.encodeClosure = value.encode
    }

    func encode(to encoder: Encoder) throws {
        try encodeClosure(encoder)
    }
}
