import Foundation

/// File-backed store for the prediction ledger (specs/prediction-ledger-mvp.md).
///
/// Stateless like `HistoricalPriceCache`: every operation loads the single
/// ledger JSON file, mutates, and writes back atomically. Volume is at most
/// one record per trading day, so the whole ledger stays trivially small.
/// All production call sites are main-actor view models; the store itself
/// keeps no shared mutable state.
///
/// Integrity rules enforced here:
/// 1. At most one record per ET trading day. A no-call record (empty claims)
///    may be upgraded once by the first market-backed record of the same day
///    (e.g. the morning load was offline); a record with claims is permanent.
/// 2. Claims are immutable once stored — only a claim's `outcome` may be set,
///    exactly once.
nonisolated final class PredictionLedgerStore {
    static let shared = PredictionLedgerStore()

    private let fileManager: FileManager
    private let directoryURL: URL

    init(
        directoryURL: URL? = nil,
        fileManager: FileManager = .default
    ) {
        self.fileManager = fileManager
        self.directoryURL = directoryURL ?? Self.defaultDirectoryURL(fileManager: fileManager)
    }

    // MARK: - Reads

    /// All records, newest trading day first.
    func allRecords() -> [PredictionRecord] {
        loadRecords().sorted { $0.tradingDay > $1.tradingDay }
    }

    func record(forTradingDay tradingDay: String) -> PredictionRecord? {
        loadRecords().first { $0.tradingDay == tradingDay }
    }

    /// Records for trading days strictly before `tradingDay` that still have
    /// unresolved claims. ("yyyy-MM-dd" keys compare correctly as strings.)
    func pendingRecords(before tradingDay: String) -> [PredictionRecord] {
        loadRecords()
            .filter { $0.tradingDay < tradingDay && !$0.isFullyResolved }
            .sorted { $0.tradingDay < $1.tradingDay }
    }

    // MARK: - Writes

    /// Inserts `record` unless its trading day is already taken.
    /// The one exception: an existing no-call record is replaced by the first
    /// record that carries claims — a record with claims is never altered.
    /// Returns whether the record was stored.
    @discardableResult
    func insert(_ record: PredictionRecord) -> Bool {
        var records = loadRecords()

        if let existingIndex = records.firstIndex(where: { $0.tradingDay == record.tradingDay }) {
            guard records[existingIndex].isNoCall, !record.isNoCall else {
                return false
            }
            records[existingIndex] = record
        } else {
            records.append(record)
        }

        saveRecords(records)
        return true
    }

    /// Sets the outcome on a single claim, exactly once. Never touches any
    /// other claim field. Returns whether the outcome was applied.
    @discardableResult
    func applyOutcome(
        _ outcome: PredictionOutcome,
        claimID: UUID,
        tradingDay: String
    ) -> Bool {
        var records = loadRecords()
        guard let recordIndex = records.firstIndex(where: { $0.tradingDay == tradingDay }),
              let claimIndex = records[recordIndex].claims.firstIndex(where: { $0.id == claimID }),
              records[recordIndex].claims[claimIndex].outcome == nil else {
            return false
        }

        records[recordIndex].claims[claimIndex].outcome = outcome
        saveRecords(records)
        return true
    }

    func removeAll() throws {
        guard fileManager.fileExists(atPath: fileURL.path) else { return }
        try fileManager.removeItem(at: fileURL)
    }

    // MARK: - Persistence

    private var fileURL: URL {
        directoryURL.appendingPathComponent("prediction-ledger.json")
    }

    private func loadRecords() -> [PredictionRecord] {
        guard fileManager.fileExists(atPath: fileURL.path),
              let data = try? Data(contentsOf: fileURL),
              let decoded = try? decoder.decode([PredictionRecord].self, from: data) else {
            // A corrupt or missing ledger recovers empty rather than crashing;
            // predictions only ever accumulate going forward.
            return []
        }
        return decoded
    }

    private func saveRecords(_ records: [PredictionRecord]) {
        guard let data = try? encoder.encode(records) else { return }
        try? fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        try? data.write(to: fileURL, options: [.atomic])
    }

    private static func defaultDirectoryURL(fileManager: FileManager) -> URL {
        let baseURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? fileManager.temporaryDirectory
        return baseURL
            .appendingPathComponent("Cosmo Trader", isDirectory: true)
            .appendingPathComponent("PredictionLedger", isDirectory: true)
    }

    private var encoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.sortedKeys]
        return encoder
    }

    private var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
