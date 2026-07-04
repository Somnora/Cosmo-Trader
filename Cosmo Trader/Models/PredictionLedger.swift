import Foundation

// MARK: - Prediction Ledger models
//
// The prediction ledger records the Today horoscope's market-backed cosmic
// claims as immutable, falsifiable predictions so they can later be scored
// against actual market closes (specs/prediction-ledger-mvp.md).
//
// Coding keys are frozen: these records persist on disk and are intended to
// become backend API contracts. Do not rename cases or fields once shipped.

nonisolated enum PredictionDirection: String, Codable, Equatable {
    case bullish
    case bearish
    case neutral
}

nonisolated enum PredictionSubject: Codable, Equatable, Hashable {
    /// The market proxy basket headline (scored against SPY).
    case market
    /// The user's owned holdings, weighted by market value at recording time.
    case portfolio
    /// A single featured symbol.
    case stock(symbol: String)

    private enum CodingKeys: String, CodingKey {
        case kind
        case symbol
    }

    private enum Kind: String, Codable {
        case market
        case portfolio
        case stock
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        switch try container.decode(Kind.self, forKey: .kind) {
        case .market:
            self = .market
        case .portfolio:
            self = .portfolio
        case .stock:
            self = .stock(symbol: try container.decode(String.self, forKey: .symbol))
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .market:
            try container.encode(Kind.market, forKey: .kind)
        case .portfolio:
            try container.encode(Kind.portfolio, forKey: .kind)
        case .stock(let symbol):
            try container.encode(Kind.stock, forKey: .kind)
            try container.encode(symbol, forKey: .symbol)
        }
    }
}

nonisolated enum PredictionResult: String, Codable, Equatable {
    /// Direction matched the actual move (or a neutral call on a flat day).
    case hit
    /// Direction contradicted the actual move.
    case miss
    /// A directional call on a flat day — a push, excluded from hit rate.
    case flat
    /// Provider data never became available; excluded from hit rate.
    case unresolved
    /// No trading occurred on the recorded day; excluded from hit rate.
    case marketClosed
}

nonisolated struct PredictionOutcome: Codable, Equatable {
    let result: PredictionResult
    /// Actual percent return of the subject for the trading day.
    /// Nil when `result` is `.unresolved` or `.marketClosed`.
    let actualReturnPercent: Double?
    let resolvedAt: Date
    /// Provenance of the candle data used to resolve the claim.
    let provenance: FinancialDataProvenance
    /// Human-readable context, e.g. an unavailability reason.
    let detail: String?

    init(
        result: PredictionResult,
        actualReturnPercent: Double?,
        resolvedAt: Date,
        provenance: FinancialDataProvenance,
        detail: String? = nil
    ) {
        self.result = result
        self.actualReturnPercent = actualReturnPercent
        self.resolvedAt = resolvedAt
        self.provenance = provenance
        self.detail = detail
    }
}

nonisolated struct PredictionClaim: Codable, Equatable, Identifiable {
    let id: UUID
    let subject: PredictionSubject
    let direction: PredictionDirection
    /// Event display name, e.g. "Full Moon".
    let cosmicDriver: String
    /// `AstroOverlayEventKind` raw value. Stored as a plain string so ledger
    /// history survives event-kind removals in future app versions.
    let driverKind: String
    /// Historical share of positive event windows, 0...1.
    let historicalWinRate: Double
    /// Historical average return minus baseline return, in percent points.
    let historicalEdge: Double
    let confidence: CorrelationConfidence
    /// Symbol → portfolio weight captured at recording time. Portfolio claims
    /// only; scoring must use these weights, never the live portfolio.
    let portfolioWeights: [String: Double]?
    /// Nil until the trading day resolves. The only mutable field on a claim.
    var outcome: PredictionOutcome?

    init(
        id: UUID = UUID(),
        subject: PredictionSubject,
        direction: PredictionDirection,
        cosmicDriver: String,
        driverKind: String,
        historicalWinRate: Double,
        historicalEdge: Double,
        confidence: CorrelationConfidence,
        portfolioWeights: [String: Double]? = nil,
        outcome: PredictionOutcome? = nil
    ) {
        self.id = id
        self.subject = subject
        self.direction = direction
        self.cosmicDriver = cosmicDriver
        self.driverKind = driverKind
        self.historicalWinRate = historicalWinRate
        self.historicalEdge = historicalEdge
        self.confidence = confidence
        self.portfolioWeights = portfolioWeights
        self.outcome = outcome
    }
}

nonisolated struct PredictionRecord: Codable, Equatable, Identifiable {
    let id: UUID
    /// ET calendar day the prediction applies to, "yyyy-MM-dd". Ledger key:
    /// at most one record exists per trading day.
    let tradingDay: String
    let recordedAt: Date
    /// True when recorded at or after 4:00 p.m. ET on `tradingDay`. Such
    /// records are kept for display but excluded from accuracy stats — the
    /// ledger never predicts the past.
    let recordedAfterClose: Bool
    /// Empty means an explicit no-call day: nothing market-backed was active,
    /// so the cosmos abstained.
    var claims: [PredictionClaim]

    init(
        id: UUID = UUID(),
        tradingDay: String,
        recordedAt: Date,
        recordedAfterClose: Bool,
        claims: [PredictionClaim]
    ) {
        self.id = id
        self.tradingDay = tradingDay
        self.recordedAt = recordedAt
        self.recordedAfterClose = recordedAfterClose
        self.claims = claims
    }

    var isNoCall: Bool { claims.isEmpty }

    var isFullyResolved: Bool { claims.allSatisfy { $0.outcome != nil } }
}

// `CorrelationConfidence` is a String-backed enum; ledger records persist it
// by raw value.
extension CorrelationConfidence: Codable {}
