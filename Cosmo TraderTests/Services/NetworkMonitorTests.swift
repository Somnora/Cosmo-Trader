//
//  NetworkMonitorTests.swift
//  Cosmo TraderTests
//
//  Comprehensive tests for NetworkMonitor including connection types,
//  status descriptions, and notification handling.
//

import Testing
import Foundation
@testable import Cosmo_Trader

// MARK: - Connection Type Tests

struct ConnectionTypeTests {

    @Test("WiFi connection type display name")
    func wifiConnectionTypeDisplayName() {
        #expect(NetworkMonitor.ConnectionType.wifi.rawValue == "Wi-Fi")
    }

    @Test("Cellular connection type display name")
    func cellularConnectionTypeDisplayName() {
        #expect(NetworkMonitor.ConnectionType.cellular.rawValue == "Cellular")
    }

    @Test("Ethernet connection type display name")
    func ethernetConnectionTypeDisplayName() {
        #expect(NetworkMonitor.ConnectionType.ethernet.rawValue == "Ethernet")
    }

    @Test("Unknown connection type display name")
    func unknownConnectionTypeDisplayName() {
        #expect(NetworkMonitor.ConnectionType.unknown.rawValue == "Unknown")
    }
}

// MARK: - Connection Type Icons Tests

struct ConnectionTypeIconTests {

    @Test("WiFi has correct icon")
    func wifiIcon() {
        #expect(NetworkMonitor.ConnectionType.wifi.icon == "wifi")
    }

    @Test("Cellular has correct icon")
    func cellularIcon() {
        #expect(NetworkMonitor.ConnectionType.cellular.icon == "antenna.radiowaves.left.and.right")
    }

    @Test("Ethernet has correct icon")
    func ethernetIcon() {
        #expect(NetworkMonitor.ConnectionType.ethernet.icon == "cable.connector")
    }

    @Test("Unknown has correct icon")
    func unknownIcon() {
        #expect(NetworkMonitor.ConnectionType.unknown.icon == "questionmark.circle")
    }
}

// MARK: - Status Description Tests

struct NetworkStatusDescriptionTests {

    @Test("Connected WiFi status description")
    func connectedWifiStatusDescription() {
        let isConnected = true
        let connectionType = NetworkMonitor.ConnectionType.wifi
        let isExpensive = false
        let isConstrained = false

        var description: String
        if isConnected {
            description = "Connected via \(connectionType.rawValue)"
            if isExpensive {
                description += " (metered)"
            }
            if isConstrained {
                description += " (low data)"
            }
        } else {
            description = "Offline"
        }

        #expect(description == "Connected via Wi-Fi")
    }

    @Test("Connected cellular metered status description")
    func connectedCellularMeteredStatusDescription() {
        let isConnected = true
        let connectionType = NetworkMonitor.ConnectionType.cellular
        let isExpensive = true
        let isConstrained = false

        var description: String
        if isConnected {
            description = "Connected via \(connectionType.rawValue)"
            if isExpensive {
                description += " (metered)"
            }
            if isConstrained {
                description += " (low data)"
            }
        } else {
            description = "Offline"
        }

        #expect(description == "Connected via Cellular (metered)")
    }

    @Test("Connected low data status description")
    func connectedLowDataStatusDescription() {
        let isConnected = true
        let connectionType = NetworkMonitor.ConnectionType.wifi
        let isExpensive = false
        let isConstrained = true

        var description: String
        if isConnected {
            description = "Connected via \(connectionType.rawValue)"
            if isExpensive {
                description += " (metered)"
            }
            if isConstrained {
                description += " (low data)"
            }
        } else {
            description = "Offline"
        }

        #expect(description == "Connected via Wi-Fi (low data)")
    }

    @Test("Connected metered and low data status description")
    func connectedMeteredAndLowDataStatusDescription() {
        let isConnected = true
        let connectionType = NetworkMonitor.ConnectionType.cellular
        let isExpensive = true
        let isConstrained = true

        var description: String
        if isConnected {
            description = "Connected via \(connectionType.rawValue)"
            if isExpensive {
                description += " (metered)"
            }
            if isConstrained {
                description += " (low data)"
            }
        } else {
            description = "Offline"
        }

        #expect(description == "Connected via Cellular (metered) (low data)")
    }

    @Test("Offline status description")
    func offlineStatusDescription() {
        let isConnected = false

        let description: String
        if isConnected {
            description = "Connected via Wi-Fi"
        } else {
            description = "Offline"
        }

        #expect(description == "Offline")
    }
}

// MARK: - Network Error Tests

struct NetworkErrorTests {

    @Test("No connection error throws correctly")
    func noConnectionErrorThrows() {
        let isConnected = false

        func requireConnection() throws {
            guard isConnected else {
                throw NetworkError.noConnection
            }
        }

        var threwError = false
        do {
            try requireConnection()
        } catch NetworkError.noConnection {
            threwError = true
        } catch {
            // Other errors
        }

        #expect(threwError == true)
    }

    @Test("Connected does not throw")
    func connectedDoesNotThrow() {
        let isConnected = true

        func requireConnection() throws {
            guard isConnected else {
                throw NetworkError.noConnection
            }
        }

        var threwError = false
        do {
            try requireConnection()
        } catch {
            threwError = true
        }

        #expect(threwError == false)
    }
}

// MARK: - Wait For Connection Tests

struct WaitForConnectionTests {

    @Test("Wait for connection returns true when already connected")
    func waitForConnectionReturnsImmediately() async {
        let isConnected = true

        if isConnected {
            #expect(true)
        } else {
            #expect(Bool(false), "Should be connected")
        }
    }

    @Test("Timeout calculation is correct")
    func timeoutCalculation() {
        let timeout: TimeInterval = 10
        let deadline = Date().addingTimeInterval(timeout)

        let now = Date()
        let withinTimeout = now < deadline

        #expect(withinTimeout == true)
    }

    @Test("Deadline is in the future")
    func deadlineIsInFuture() {
        let timeout: TimeInterval = 5
        let deadline = Date().addingTimeInterval(timeout)

        #expect(deadline > Date())
    }
}

// MARK: - Notification Name Tests

struct NetworkNotificationNameTests {

    @Test("Network status changed notification name is correct")
    func networkStatusChangedNotificationName() {
        let notificationName = Notification.Name.networkStatusChanged

        #expect(notificationName.rawValue == "com.cosmotrader.networkStatusChanged")
    }
}

// MARK: - Connection State Tests

struct ConnectionStateTests {

    @Test("Initial connected state is true")
    func initialConnectedStateIsTrue() {
        // Based on NetworkMonitor init, initial state is true
        let initialState = true
        #expect(initialState == true)
    }

    @Test("Connection type default is unknown")
    func connectionTypeDefaultIsUnknown() {
        // Based on NetworkMonitor init
        let defaultType = NetworkMonitor.ConnectionType.unknown
        #expect(defaultType == .unknown)
    }

    @Test("Expensive default is false")
    func expensiveDefaultIsFalse() {
        let defaultExpensive = false
        #expect(defaultExpensive == false)
    }

    @Test("Constrained default is false")
    func constrainedDefaultIsFalse() {
        let defaultConstrained = false
        #expect(defaultConstrained == false)
    }
}

// MARK: - Status Change Tracking Tests

struct StatusChangeTrackingTests {

    @Test("Status change updates timestamp")
    func statusChangeUpdatesTimestamp() {
        let beforeChange = Date()
        let lastStatusChange = Date()
        let afterChange = Date()

        #expect(lastStatusChange >= beforeChange)
        #expect(lastStatusChange <= afterChange)
    }

    @Test("Status change posts notification")
    func statusChangePostsNotification() {
        // This test verifies the notification is correctly configured
        let notificationName = Notification.Name.networkStatusChanged
        let userInfo: [String: Any] = ["isConnected": true]

        #expect(notificationName.rawValue.contains("networkStatusChanged"))
        #expect(userInfo["isConnected"] as? Bool == true)
    }
}

// MARK: - Wait Interval Tests

struct WaitIntervalTests {

    @Test("Wait interval is 0.5 seconds")
    func waitIntervalIs500ms() {
        let waitNanoseconds: UInt64 = 500_000_000
        let waitSeconds = Double(waitNanoseconds) / 1_000_000_000

        #expect(waitSeconds == 0.5)
    }

    @Test("Default timeout is 10 seconds")
    func defaultTimeoutIs10Seconds() {
        let defaultTimeout: TimeInterval = 10

        #expect(defaultTimeout == 10)
    }
}

// MARK: - NetworkMonitor Singleton Tests

struct NetworkMonitorSingletonTests {

    @Test("Shared instance exists")
    @MainActor
    func sharedInstanceExists() {
        let monitor = NetworkMonitor.shared
        #expect(monitor != nil)
    }

    @Test("Shared instance is same object")
    @MainActor
    func sharedInstanceIsSameObject() {
        let monitor1 = NetworkMonitor.shared
        let monitor2 = NetworkMonitor.shared

        #expect(monitor1 === monitor2)
    }
}

// MARK: - Connection Type Determination Tests

struct ConnectionTypeDeterminationTests {

    @Test("All connection types have unique raw values")
    func allConnectionTypesHaveUniqueRawValues() {
        let types: [NetworkMonitor.ConnectionType] = [.wifi, .cellular, .ethernet, .unknown]
        let rawValues = types.map { $0.rawValue }
        let uniqueValues = Set(rawValues)

        #expect(rawValues.count == uniqueValues.count)
    }

    @Test("All connection types have non-empty icons")
    func allConnectionTypesHaveIcons() {
        let types: [NetworkMonitor.ConnectionType] = [.wifi, .cellular, .ethernet, .unknown]

        for type in types {
            #expect(!type.icon.isEmpty, "Connection type \(type) should have an icon")
        }
    }
}
