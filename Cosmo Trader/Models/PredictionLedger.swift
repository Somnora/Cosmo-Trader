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
    /// Schema version new records are written with. v1 recorded the
    /// highest-confidence event from year-long summaries whether or not that
    /// event was occurring; v2 records only claims whose cosmic driver was
    /// actually active on the trading day.
    static let currentSchemaVersion = 2
    /// Earliest schema whose claims may enter accuracy stats. v1 records
    /// measured a different experiment, so they are retained and shown but
    /// never counted — deleting them would be the only irreversible option.
    static let earliestScoreableSchemaVersion = 2

    let id: UUID
    /// Version of the ledger schema this record was written with. Ledger
    /// files written before the active-driver join carry no key for it and
    /// decode as v1.
    let schemaVersion: Int
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
        schemaVersion: Int = PredictionRecord.currentSchemaVersion,
        tradingDay: String,
        recordedAt: Date,
        recordedAfterClose: Bool,
        claims: [PredictionClaim]
    ) {
        self.id = id
        self.schemaVersion = schemaVersion
        self.tradingDay = tradingDay
        self.recordedAt = recordedAt
        self.recordedAfterClose = recordedAfterClose
        self.claims = claims
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case schemaVersion
        case tradingDay
        case recordedAt
        case recordedAfterClose
        case claims
    }

    /// Decoding is hand-written for one reason: a v1 ledger on disk has no
    /// `schemaVersion` key, and synthesized decoding would throw on it.
    /// `PredictionLedgerStore.loadRecords()` swallows a decode failure into
    /// an empty ledger, and the next insert would then overwrite the user's
    /// entire history with a single record. An absent version means v1.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.schemaVersion = try container.decodeIfPresent(Int.self, forKey: .schemaVersion) ?? 1
        self.tradingDay = try container.decode(String.self, forKey: .tradingDay)
        self.recordedAt = try container.decode(Date.self, forKey: .recordedAt)
        self.recordedAfterClose = try container.decode(Bool.self, forKey: .recordedAfterClose)
        self.claims = try container.decode([PredictionClaim].self, forKey: .claims)
    }

    var isNoCall: Bool { claims.isEmpty }

    var isFullyResolved: Bool { claims.allSatisfy { $0.outcome != nil } }

    /// True for records written before claims were joined to an actually
    /// active cosmic driver. Shown in history, excluded from accuracy.
    var predatesActiveDriverJoin: Bool {
        schemaVersion < PredictionRecord.earliestScoreableSchemaVersion
    }
}

// `CorrelationConfidence` is a String-backed enum; ledger records persist it
// by raw value.
extension CorrelationConfidence: Codable {}
