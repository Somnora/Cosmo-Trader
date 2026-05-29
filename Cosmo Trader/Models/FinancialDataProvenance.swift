import Foundation

enum FinancialDataProvenance: Equatable {
    case live(provider: String, fetchedAt: Date)
    case cached(provider: String, fetchedAt: Date, age: TimeInterval)
    case mixed(reason: String)
    case unavailable(reason: String)
    case sample(reason: String)

    static let finnhubProvider = "Finnhub"

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

    static func cached(provider: String, fetchedAt: Date, now: Date = Date()) -> FinancialDataProvenance {
        .cached(provider: provider, fetchedAt: fetchedAt, age: max(0, now.timeIntervalSince(fetchedAt)))
    }
}

struct ProvenancedValue<Value: Equatable>: Equatable {
    let value: Value?
    let provenance: FinancialDataProvenance
}
