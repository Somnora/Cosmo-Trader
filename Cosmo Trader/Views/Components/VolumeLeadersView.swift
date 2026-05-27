import SwiftUI

// MARK: - VolumeLeadersView
// =========================
// Displays today's most actively traded stocks with cosmic interpretation.
// Features cosmic confluence alerts when unusual volume meets cosmic signals.

struct VolumeLeadersView: View {

    // MARK: - Properties

    let leaders: [VolumeLeader]
    let isLoading: Bool
    var onStockTap: ((Stock) -> Void)?

    @State private var showOnlyConfluence: Bool = false

    // MARK: - Filtered Leaders

    private var filteredLeaders: [VolumeLeader] {
        if showOnlyConfluence {
            return leaders.filter { $0.isCosmicConfluence }
        }
        return leaders
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            headerSection

            // Filter toggle
            filterToggle

            // Content
            if isLoading {
                loadingView
            } else if filteredLeaders.isEmpty {
                emptyView
            } else {
                leadersList
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        HStack(spacing: 10) {
            Image(systemName: "chart.bar.fill")
                .font(.caption)
                .foregroundColor(CosmicTheme.gold)

            Text("VOLUME LEADERS")
                .font(TerminalFont.data(12, weight: .semibold))
                .foregroundColor(CosmicTheme.textPrimary)
                .tracking(1)

            Spacer()

            if !isLoading && !leaders.isEmpty {
                let confluenceCount = leaders.filter { $0.isCosmicConfluence }.count
                if confluenceCount > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "sparkles")
                            .font(.caption2)
                        Text("\(confluenceCount) CONFLUENCE")
                            .font(TerminalFont.data(9, weight: .semibold))
                    }
                    .foregroundColor(CosmicTheme.gold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(CosmicTheme.gold.opacity(0.15))
                    )
                }
            }
        }
    }

    // MARK: - Filter Toggle

    private var filterToggle: some View {
        HStack(spacing: 12) {
            filterButton(title: "All Leaders", isSelected: !showOnlyConfluence) {
                showOnlyConfluence = false
            }

            filterButton(title: "Cosmic Confluence", isSelected: showOnlyConfluence) {
                showOnlyConfluence = true
            }

            Spacer()
        }
    }

    private func filterButton(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: {
            HapticFeedback.selection()
            withAnimation(.easeInOut(duration: 0.2)) {
                action()
            }
        }) {
            Text(title)
                .font(TerminalFont.data(11, weight: isSelected ? .semibold : .regular))
                .foregroundColor(isSelected ? CosmicTheme.gold : CosmicTheme.textMuted)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(isSelected ? CosmicTheme.gold.opacity(0.15) : Color.clear)
                )
                .overlay(
                    Capsule()
                        .stroke(isSelected ? CosmicTheme.gold.opacity(0.3) : CosmicTheme.border, lineWidth: 0.5)
                )
        }
    }

    // MARK: - Leaders List

    private var leadersList: some View {
        VStack(spacing: 0) {
            ForEach(Array(filteredLeaders.enumerated()), id: \.element.id) { index, leader in
                VolumeLeaderRow(
                    leader: leader,
                    rank: index + 1,
                    onTap: { onStockTap?(leader.stock) }
                )

                if index < filteredLeaders.count - 1 {
                    Divider()
                        .background(CosmicTheme.border)
                }
            }
        }
        .background(CosmicTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(CosmicTheme.border, lineWidth: 0.5)
        )
    }

    // MARK: - Loading View

    private var loadingView: some View {
        HStack(spacing: 10) {
            ProgressView()
                .tint(CosmicTheme.gold)

            Text("Analyzing volume patterns...")
                .font(TerminalFont.data(12))
                .foregroundColor(CosmicTheme.textMuted)
                .italic()
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
    }

    // MARK: - Empty View

    private var emptyView: some View {
        VStack(spacing: 8) {
            Image(systemName: showOnlyConfluence ? "sparkles" : "chart.bar")
                .font(.title2)
                .foregroundColor(CosmicTheme.textMuted)

            if showOnlyConfluence {
                Text("No cosmic confluence detected")
                    .font(TerminalFont.data(12))
                    .foregroundColor(CosmicTheme.textMuted)

                Text("Check back when volume and cosmic context align")
                    .font(TerminalFont.data(11))
                    .foregroundColor(CosmicTheme.textMuted)
                    .italic()
            } else {
                Text("No volume data available")
                    .font(TerminalFont.data(12))
                    .foregroundColor(CosmicTheme.textMuted)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
    }
}

// MARK: - Volume Leader Row

struct VolumeLeaderRow: View {

    let leader: VolumeLeader
    let rank: Int
    var onTap: (() -> Void)?

    @State private var isPressed: Bool = false

    var body: some View {
        Button(action: {
            HapticFeedback.light()
            onTap?()
        }) {
            HStack(spacing: 12) {
                // Rank
                rankBadge

                // Stock info
                stockInfo

                Spacer()

                // Volume data
                volumeInfo

                // Cosmic indicator
                if leader.isCosmicConfluence {
                    confluenceIndicator
                }

                // Chevron
                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundColor(CosmicTheme.textMuted)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(isPressed ? CosmicTheme.secondaryBackground : Color.clear)
        }
        .buttonStyle(PlainButtonStyle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }

    // MARK: - Rank Badge

    private var rankBadge: some View {
        ZStack {
            Circle()
                .fill(rankColor.opacity(0.15))
                .frame(width: 28, height: 28)

            Text("\(rank)")
                .font(TerminalFont.data(12, weight: .bold))
                .foregroundColor(rankColor)
        }
    }

    private var rankColor: Color {
        switch rank {
        case 1: return CosmicTheme.gold
        case 2: return Color.gray.opacity(0.8)
        case 3: return Color.orange.opacity(0.7)
        default: return CosmicTheme.textMuted
        }
    }

    // MARK: - Stock Info

    private var stockInfo: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(leader.stock.symbol)
                .font(TerminalFont.data(13, weight: .semibold))
                .foregroundColor(CosmicTheme.textPrimary)

            HStack(spacing: 4) {
                if let sign = leader.stock.zodiacSign {
                    ZodiacSymbolView(sign: sign, size: 10, color: elementColor)
                } else {
                    Text("?")
                        .font(TerminalFont.data(10, weight: .bold))
                        .foregroundColor(CosmicTheme.textMuted)
                        .accessibilityLabel("unknown sign")
                }

                Text(leader.stock.zodiacSign?.displayName ?? "Unknown")
                    .font(TerminalFont.data(10))
                    .foregroundColor(CosmicTheme.textMuted)
            }
        }
        .frame(width: 80, alignment: .leading)
    }

    private var elementColor: Color {
        leader.stock.foundedElement?.color ?? CosmicTheme.textMuted
    }

    // MARK: - Volume Info

    private var volumeInfo: some View {
        VStack(alignment: .trailing, spacing: 2) {
            // Volume ratio
            HStack(spacing: 4) {
                Image(systemName: leader.volumeData.volumeSignal.icon)
                    .font(.caption2)

                Text(leader.volumeData.formattedVolumeRatio)
                    .font(TerminalFont.price(14))
            }
            .foregroundColor(leader.volumeData.volumeSignal.color)

            // Current volume
            Text(leader.volumeData.formattedCurrentVolume)
                .font(TerminalFont.data(10))
                .foregroundColor(CosmicTheme.textMuted)
        }
    }

    // MARK: - Confluence Indicator

    private var confluenceIndicator: some View {
        HStack(spacing: 2) {
            Image(systemName: "sparkles")
                .font(.caption2)

            if let signal = leader.primarySignal {
                Circle()
                    .fill(signal.cosmicAlignment.color)
                    .frame(width: 6, height: 6)
            }
        }
        .foregroundColor(CosmicTheme.gold)
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(CosmicTheme.gold.opacity(0.1))
        )
    }
}

// MARK: - Volume Leaders Section

struct VolumeLeadersSection: View {

    @Environment(AppState.self) private var appState

    @State private var leaders: [VolumeLeader] = []
    @State private var isLoading: Bool = true
    @State private var selectedStock: Stock?

    var body: some View {
        VolumeLeadersView(
            leaders: leaders,
            isLoading: isLoading,
            onStockTap: { stock in
                selectedStock = stock
            }
        )
        .task {
            await loadLeaders()
        }
        .sheet(item: $selectedStock) { stock in
            NavigationStack {
                StockDetailView(stock: stock)
            }
        }
    }

    private func loadLeaders() async {
        isLoading = true

        let userSign = appState.currentUser?.sunSign ?? .aries
        let volumeService = VolumeService.shared

        leaders = await volumeService.getVolumeLeaders(
            from: MockStockData.knownStocks,
            userSign: userSign,
            limit: 10
        )

        isLoading = false
    }
}

// MARK: - Compact Volume Badge

struct VolumeBadge: View {

    let volumeData: VolumeData

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: volumeData.volumeSignal.icon)
                .font(.caption2)

            Text(volumeData.formattedVolumeRatio)
                .font(TerminalFont.data(10, weight: .medium))
        }
        .foregroundColor(volumeData.volumeSignal.color)
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(volumeData.volumeSignal.color.opacity(0.1))
        )
    }
}

// MARK: - Cosmic Confluence Alert

struct CosmicConfluenceAlert: View {

    let leader: VolumeLeader

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.caption)
                    .foregroundColor(CosmicTheme.gold)

                Text("COSMIC CONFLUENCE")
                    .font(TerminalFont.data(11, weight: .bold))
                    .foregroundColor(CosmicTheme.gold)
                    .tracking(1)

                Spacer()

                Text(leader.stock.symbol)
                    .font(TerminalFont.data(12, weight: .semibold))
                    .foregroundColor(CosmicTheme.textPrimary)
            }

            // Alert body
            HStack(spacing: 16) {
                // Volume indicator
                VStack(alignment: .center, spacing: 4) {
                    Image(systemName: leader.volumeData.volumeSignal.icon)
                        .font(.title2)
                        .foregroundColor(leader.volumeData.volumeSignal.color)

                    Text(leader.volumeData.formattedVolumeRatio)
                        .font(TerminalFont.price(16))
                        .foregroundColor(leader.volumeData.volumeSignal.color)

                    Text("Volume")
                        .font(TerminalFont.data(9))
                        .foregroundColor(CosmicTheme.textMuted)
                }
                .frame(width: 60)

                // Plus sign
                Text("+")
                    .font(TerminalFont.price(20))
                    .foregroundColor(CosmicTheme.gold)

                // Cosmic signal
                if let signal = leader.primarySignal {
                    VStack(alignment: .center, spacing: 4) {
                        Image(systemName: signal.cosmicAlignment.icon)
                            .font(.title2)
                            .foregroundColor(signal.cosmicAlignment.color)

                        Text(signal.cosmicAlignment.rawValue)
                            .font(TerminalFont.data(10, weight: .medium))
                            .foregroundColor(signal.cosmicAlignment.color)
                            .lineLimit(1)

                        Text("Cosmic")
                            .font(TerminalFont.data(9))
                            .foregroundColor(CosmicTheme.textMuted)
                    }
                    .frame(width: 80)
                }

                Spacer()

                // Action hint
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Tap to")
                        .font(TerminalFont.data(9))
                        .foregroundColor(CosmicTheme.textMuted)

                    Text("Explore")
                        .font(TerminalFont.data(11, weight: .semibold))
                        .foregroundColor(CosmicTheme.gold)

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(CosmicTheme.gold)
                }
            }

            // Interpretation
            if let signal = leader.primarySignal {
                Text(signal.headline)
                    .font(TerminalFont.data(11))
                    .foregroundColor(CosmicTheme.textSecondary)
                    .lineLimit(2)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(CosmicTheme.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    LinearGradient(
                        colors: [CosmicTheme.gold.opacity(0.5), CosmicTheme.accentBlue.opacity(0.3)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
    }
}

// MARK: - Preview

#Preview("Volume Leaders View") {
    ZStack {
        CosmicTheme.background.ignoresSafeArea()

        ScrollView {
            VolumeLeadersSection()
                .padding()
        }
    }
    .environment(AppState.preview)
    .preferredColorScheme(.dark)
}

#Preview("Cosmic Confluence Alert") {
    ZStack {
        CosmicTheme.background.ignoresSafeArea()

            CosmicConfluenceAlert(
                leader: VolumeLeader(
                    stock: MockStockData.knownStocks.first!,
                    volumeData: VolumeData(
                    symbol: "AAPL",
                    currentVolume: 150_000_000,
                    averageVolume: 50_000_000,
                    volumeRatio: 3.0,
                    timestamp: Date()
                ),
                cosmicInsights: []
            )
        )
        .padding()
    }
    .preferredColorScheme(.dark)
}
