import Foundation
import Network
import SwiftUI

// MARK: - NetworkMonitor
// ======================
// Monitors network connectivity status using NWPathMonitor.
// Provides real-time updates for offline detection and graceful degradation.
//
// Usage:
// - Check NetworkMonitor.shared.isConnected before network requests
// - Use connectionType to adapt behavior for cellular vs wifi
// - Observe changes to show/hide offline indicators

@MainActor
@Observable
final class NetworkMonitor {

    // MARK: - Singleton

    static let shared = NetworkMonitor()

    // MARK: - Properties

    /// Whether the device currently has network connectivity
    private(set) var isConnected: Bool = true

    /// The type of current connection
    private(set) var connectionType: ConnectionType = .unknown

    /// Whether we're on an expensive connection (cellular)
    private(set) var isExpensive: Bool = false

    /// Whether the connection is constrained (low data mode)
    private(set) var isConstrained: Bool = false

    /// Timestamp of last connectivity change
    private(set) var lastStatusChange: Date = Date()

    // MARK: - Connection Type

    enum ConnectionType: String {
        case wifi = "Wi-Fi"
        case cellular = "Cellular"
        case ethernet = "Ethernet"
        case unknown = "Unknown"

        var icon: String {
            switch self {
            case .wifi: return "wifi"
            case .cellular: return "antenna.radiowaves.left.and.right"
            case .ethernet: return "cable.connector"
            case .unknown: return "questionmark.circle"
            }
        }
    }

    // MARK: - Private

    private let monitor: NWPathMonitor
    private let queue = DispatchQueue(label: "com.cosmotrader.networkmonitor", qos: .utility)

    // MARK: - Initialization

    private init() {
        monitor = NWPathMonitor()
        startMonitoring()
    }

    deinit {
        monitor.cancel()
    }

    // MARK: - Monitoring

    private func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            guard let self = self else { return }
            Task { @MainActor [weak self] in
                self?.updateStatus(from: path)
            }
        }
        monitor.start(queue: queue)
    }

    private func updateStatus(from path: NWPath) {
        let wasConnected = isConnected
        isConnected = path.status == .satisfied
        connectionType = getConnectionType(from: path)
        isExpensive = path.isExpensive
        isConstrained = path.isConstrained

        // Track when status actually changed
        if wasConnected != isConnected {
            lastStatusChange = Date()

            #if DEBUG
            print("[NetworkMonitor] Connection changed: \(isConnected ? "Online" : "Offline") via \(connectionType.rawValue)")
            #endif

            // Post notification for views that don't observe directly
            NotificationCenter.default.post(
                name: .networkStatusChanged,
                object: nil,
                userInfo: ["isConnected": isConnected]
            )
        }
    }

    private func getConnectionType(from path: NWPath) -> ConnectionType {
        if path.usesInterfaceType(.wifi) {
            return .wifi
        } else if path.usesInterfaceType(.cellular) {
            return .cellular
        } else if path.usesInterfaceType(.wiredEthernet) {
            return .ethernet
        }
        return .unknown
    }

    // MARK: - Public Methods

    /// Check connectivity with optional throwing for offline state
    func requireConnection() throws {
        guard isConnected else {
            throw NetworkError.noConnection
        }
    }

    /// Wait for connection with timeout
    func waitForConnection(timeout: TimeInterval = 10) async -> Bool {
        if isConnected { return true }

        let deadline = Date().addingTimeInterval(timeout)

        while Date() < deadline {
            if isConnected { return true }
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        }

        return isConnected
    }

    /// Human-readable status description
    var statusDescription: String {
        if isConnected {
            var description = "Connected via \(connectionType.rawValue)"
            if isExpensive {
                description += " (metered)"
            }
            if isConstrained {
                description += " (low data)"
            }
            return description
        } else {
            return "Offline"
        }
    }
}

// MARK: - Notification Extension

extension Notification.Name {
    static let networkStatusChanged = Notification.Name("com.cosmotrader.networkStatusChanged")
}
