import Foundation

nonisolated enum FinancialDataProvenance: Equatable, Codable {
    case live(provider: String, fetchedAt: Date)
    case cached(provider: String, fetchedAt: Date, age: TimeInterval)
    case mixed(reason: String)
    case unavailable(reason: String)
    case sample(reason: String)

    static let finnhubProvider = "Finnhub"
    static let defaultCachedStaleInterval: TimeInterval = 60 * 60 * 24

    var fetchedAt: Date? {
        switch self {
        case .live(_, let fetchedAt), .cached(_, let fetchedAt, _):
            return fetchedAt
        case .mixed, .unavailable, .sample:
            return nil
        }
    }

    var provider: String? {
        switch self {
        case .live(let provider, _), .cached(let provider, _, _):
            return provider
        case .mixed, .unavailable, .sample:
            return nil
        }
    }

    var isProviderBacked: Bool {
        switch self {
        case .live, .cached:
            return true
        case .mixed, .unavailable, .sample:
            return false
        }
    }

    var isCached: Bool {
        if case .cached = self { return true }
        return false
    }

    func isCachedStale(staleAfter staleInterval: TimeInterval = Self.defaultCachedStaleInterval) -> Bool {
        guard case .cached(_, _, let age) = self else { return false }
        return age >= staleInterval
    }

    static func cached(provider: String, fetchedAt: Date, now: Date = Date()) -> FinancialDataProvenance {
        .cached(provider: provider, fetchedAt: fetchedAt, age: max(0, now.timeIntervalSince(fetchedAt)))
    }

    private enum CodingKeys: String, CodingKey {
        case kind
        case provider
        case fetchedAt
        case age
        case reason
    }

    private enum Kind: String, Codable {
        case live
        case cached
        case mixed
        case unavailable
        case sample
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let kind = try container.decode(Kind.self, forKey: .kind)

        switch kind {
        case .live:
            self = .live(
                provider: try container.decode(String.self, forKey: .provider),
                fetchedAt: try container.decode(Date.self, forKey: .fetchedAt)
            )
        case .cached:
            self = .cached(
                provider: try container.decode(String.self, forKey: .provider),
                fetchedAt: try container.decode(Date.self, forKey: .fetchedAt),
                age: try container.decode(TimeInterval.self, forKey: .age)
            )
        case .mixed:
            self = .mixed(reason: try container.decode(String.self, forKey: .reason))
        case .unavailable:
            self = .unavailable(reason: try container.decode(String.self, forKey: .reason))
        case .sample:
            self = .sample(reason: try container.decode(String.self, forKey: .reason))
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case .live(let provider, let fetchedAt):
            try container.encode(Kind.live, forKey: .kind)
            try container.encode(provider, forKey: .provider)
            try container.encode(fetchedAt, forKey: .fetchedAt)
        case .cached(let provider, let fetchedAt, let age):
            try container.encode(Kind.cached, forKey: .kind)
            try container.encode(provider, forKey: .provider)
            try container.encode(fetchedAt, forKey: .fetchedAt)
            try container.encode(age, forKey: .age)
        case .mixed(let reason):
            try container.encode(Kind.mixed, forKey: .kind)
            try container.encode(reason, forKey: .reason)
        case .unavailable(let reason):
            try container.encode(Kind.unavailable, forKey: .kind)
            try container.encode(reason, forKey: .reason)
        case .sample(let reason):
            try container.encode(Kind.sample, forKey: .kind)
            try container.encode(reason, forKey: .reason)
        }
    }
}

nonisolated struct ProvenancedValue<Value: Equatable>: Equatable {
    let value: Value?
    let provenance: FinancialDataProvenance
}
