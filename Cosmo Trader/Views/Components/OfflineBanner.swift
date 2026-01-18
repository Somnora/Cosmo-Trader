import SwiftUI

// MARK: - OfflineBanner
// =====================
// A banner that automatically appears when the device loses network connectivity.
// Slides in from the top with animation, provides visual feedback about offline state.
//
// Usage: Add at the top of your view hierarchy
// VStack(spacing: 0) {
//     OfflineBanner()
//     // rest of content
// }

struct OfflineBanner: View {

    // MARK: - State

    @State private var networkMonitor = NetworkMonitor.shared
    @State private var showBanner: Bool = false

    // MARK: - Customization

    let compact: Bool

    init(compact: Bool = false) {
        self.compact = compact
    }

    // MARK: - Body

    var body: some View {
        if showBanner {
            bannerContent
                .transition(.move(edge: .top).combined(with: .opacity))
        }
    }

    // MARK: - Banner Content

    @ViewBuilder
    private var bannerContent: some View {
        if compact {
            compactBanner
        } else {
            fullBanner
        }
    }

    private var fullBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "wifi.slash")
                .font(.system(size: 14, weight: .semibold))

            Text("No internet connection")
                .font(.system(size: 13, weight: .medium, design: .monospaced))

            Spacer()

            // Retry indicator
            if networkMonitor.isConnected == false {
                ProgressView()
                    .scaleEffect(0.7)
                    .tint(CosmicTheme.background)
            }
        }
        .foregroundColor(CosmicTheme.background)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.orange)
        .onChange(of: networkMonitor.isConnected) { _, isConnected in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                showBanner = !isConnected
            }
        }
        .onAppear {
            // Check initial state
            showBanner = !networkMonitor.isConnected
        }
    }

    private var compactBanner: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(Color.orange)
                .frame(width: 6, height: 6)

            Text("Offline")
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundColor(CosmicTheme.textSecondary)

            Image(systemName: "wifi.slash")
                .font(.system(size: 10))
                .foregroundColor(.orange)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(
            Capsule()
                .fill(CosmicTheme.cardBackground)
                .overlay(
                    Capsule()
                        .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                )
        )
        .onChange(of: networkMonitor.isConnected) { _, isConnected in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                showBanner = !isConnected
            }
        }
        .onAppear {
            showBanner = !networkMonitor.isConnected
        }
    }
}

// MARK: - Stale Data Indicator
// ============================
// Shows when displaying cached/stale data

struct StaleDataIndicator: View {

    let cachedAt: Date

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "clock")
                .font(.system(size: 10))

            Text("Data from \(ageDescription)")
                .font(.system(size: 11, weight: .regular, design: .monospaced))
        }
        .foregroundColor(CosmicTheme.textMuted)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(
            Capsule()
                .fill(CosmicTheme.cardBackground.opacity(0.5))
        )
    }

    private var ageDescription: String {
        let minutes = Int(Date().timeIntervalSince(cachedAt) / 60)

        if minutes < 1 { return "just now" }
        if minutes == 1 { return "1 min ago" }
        if minutes < 60 { return "\(minutes) mins ago" }

        let hours = minutes / 60
        if hours == 1 { return "1 hour ago" }
        if hours < 24 { return "\(hours) hours ago" }

        let days = hours / 24
        if days == 1 { return "1 day ago" }
        return "\(days) days ago"
    }
}

// MARK: - Connection Status Badge
// ===============================
// Small badge showing current connection status

struct ConnectionStatusBadge: View {

    @State private var networkMonitor = NetworkMonitor.shared

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(networkMonitor.isConnected ? Color.green : Color.orange)
                .frame(width: 6, height: 6)

            if !networkMonitor.isConnected {
                Text("Offline")
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(CosmicTheme.textMuted)
            }
        }
    }
}

// MARK: - Previews

#Preview("Offline Banner - Full") {
    VStack(spacing: 0) {
        // Simulated offline banner
        HStack(spacing: 10) {
            Image(systemName: "wifi.slash")
                .font(.system(size: 14, weight: .semibold))

            Text("No internet connection")
                .font(.system(size: 13, weight: .medium, design: .monospaced))

            Spacer()
        }
        .foregroundColor(CosmicTheme.background)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.orange)

        Spacer()
    }
    .background(CosmicTheme.background)
}

#Preview("Offline Banner - Compact") {
    ZStack {
        CosmicTheme.background.ignoresSafeArea()

        VStack {
            HStack(spacing: 6) {
                Circle()
                    .fill(Color.orange)
                    .frame(width: 6, height: 6)

                Text("Offline")
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundColor(CosmicTheme.textSecondary)

                Image(systemName: "wifi.slash")
                    .font(.system(size: 10))
                    .foregroundColor(.orange)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                Capsule()
                    .fill(CosmicTheme.cardBackground)
                    .overlay(
                        Capsule()
                            .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                    )
            )

            Spacer()
        }
        .padding()
    }
}

#Preview("Stale Data Indicator") {
    ZStack {
        CosmicTheme.background.ignoresSafeArea()
        StaleDataIndicator(cachedAt: Date().addingTimeInterval(-360))
    }
}
