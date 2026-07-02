import Combine
import Foundation
import Observation

enum DataSourceState: Equatable {
    case live
    case cached(lastUpdated: Date)
    case sample
    case offline
}

@MainActor
@Observable
final class DataSourceMonitor {
    static let shared = DataSourceMonitor()

    private var isOnline: Bool
    private var hasValidFinnhubKey: Bool
    private var mostRecentSuccessfulStockResponse: Date?

    @ObservationIgnored private let networkMonitor: NetworkMonitor
    @ObservationIgnored private let hasValidFinnhubKeyProvider: () -> Bool
    @ObservationIgnored private let nowProvider: () -> Date
    @ObservationIgnored private let liveWindow: TimeInterval
    @ObservationIgnored private var cancellables: Set<AnyCancellable> = []

    var currentSource: DataSourceState {
        Self.resolveSource(
            isOnline: isOnline,
            hasValidFinnhubKey: hasValidFinnhubKey,
            mostRecentSuccessfulResponseAt: mostRecentSuccessfulStockResponse,
            now: nowProvider(),
            liveWindow: liveWindow
        )
    }

    convenience init() {
        self.init(
            networkMonitor: .shared,
            stockAPIService: .shared,
            hasValidFinnhubKeyProvider: { APIConfig.hasValidFinnhubKey }
        )
    }

    init(
        networkMonitor: NetworkMonitor,
        stockAPIService: StockAPIService,
        hasValidFinnhubKeyProvider: @escaping () -> Bool,
        nowProvider: @escaping () -> Date = Date.init,
        liveWindow: TimeInterval = 60
    ) {
        self.networkMonitor = networkMonitor
        self.hasValidFinnhubKeyProvider = hasValidFinnhubKeyProvider
        self.nowProvider = nowProvider
        self.liveWindow = liveWindow
        self.isOnline = networkMonitor.isOnline
        self.hasValidFinnhubKey = hasValidFinnhubKeyProvider()
        self.mostRecentSuccessfulStockResponse = stockAPIService.lastUpdateTime

        stockAPIService.lastUpdateTimePublisher
            .receive(on: RunLoop.main)
            .sink { [weak self] timestamp in
                Task { @MainActor [weak self] in
                    self?.mostRecentSuccessfulStockResponse = timestamp
                    self?.refreshConfiguration()
                }
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: .networkStatusChanged)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.refreshConfiguration()
                }
            }
            .store(in: &cancellables)
    }

    func refreshConfiguration() {
        isOnline = networkMonitor.isOnline
        hasValidFinnhubKey = hasValidFinnhubKeyProvider()
    }

    static func resolveSource(
        isOnline: Bool,
        hasValidFinnhubKey: Bool,
        mostRecentSuccessfulResponseAt lastUpdated: Date?,
        now: Date = Date(),
        liveWindow: TimeInterval = 60
    ) -> DataSourceState {
        guard isOnline else { return .offline }
        guard hasValidFinnhubKey else { return .sample }
        guard let lastUpdated else { return .sample }

        if now.timeIntervalSince(lastUpdated) <= liveWindow {
            return .live
        }

        return .cached(lastUpdated: lastUpdated)
    }
}
