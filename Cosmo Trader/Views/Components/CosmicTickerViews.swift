import SwiftUI

// MARK: - Cosmic Ticker Views
// ===========================
// Bloomberg-style scrolling ticker tape with cosmic commentary.
//
// "AAPL +1.2% | TSLA -0.4% | MOON IN SCORPIO | GOOGL +0.8% | VOC ENDS 2PM"
//
// WHY IT WORKS: Bloomberg meets mysticism. Constantly engaging. Premium feel.
//
// Animation model: no Timer instances. The tape scroll is a single
// repeat-forever linear animation that runs on the render server (zero
// per-frame SwiftUI updates); the rotating variants derive their current
// item from a periodic TimelineView, which pauses automatically when the
// view is off screen. Each visible ticker view owns the service refresh
// lifecycle, so the 30s data refresh only runs while a ticker is on screen.

// MARK: - Cosmic Ticker Tape (Main Component)

struct CosmicTickerTape: View {
    @State private var service = CosmicTickerService.shared
    @State private var contentWidth: CGFloat = 0
    @State private var isScrolling = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Speed of ticker scroll (points per second)
    private let scrollSpeed: CGFloat = 40

    var body: some View {
        HStack(spacing: 0) {
            // First copy of ticker items
            tickerContent
                .background(
                    GeometryReader { contentGeo in
                        Color.clear
                            .onAppear {
                                contentWidth = contentGeo.size.width
                            }
                            .onChange(of: contentGeo.size.width) { _, newWidth in
                                contentWidth = newWidth
                            }
                    }
                )

            // Second copy for seamless looping
            tickerContent
        }
        .offset(x: isScrolling ? -contentWidth : 0)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .frame(height: 32)
        .background(CosmicTheme.background.opacity(0.95))
        .overlay(
            // Fade edges
            HStack(spacing: 0) {
                LinearGradient(
                    colors: [CosmicTheme.background, .clear],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(width: 20)

                Spacer()

                LinearGradient(
                    colors: [.clear, CosmicTheme.background],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(width: 20)
            }
        )
        .clipped()
        .onAppear {
            service.refreshTicker()
            service.startRefreshTimer()
            restartScrolling()
        }
        .onDisappear {
            service.stopRefreshTimer()
        }
        .onChange(of: contentWidth) { _, _ in
            restartScrolling()
        }
        .onChange(of: service.tickerItems) { _, _ in
            restartScrolling()
        }
    }

    private var tickerContent: some View {
        HStack(spacing: 0) {
            ForEach(service.tickerItems) { item in
                tickerItemView(item)
            }
        }
    }

    private func tickerItemView(_ item: TickerItem) -> some View {
        HStack(spacing: 8) {
            Text(item.text)
                .font(TerminalFont.body(12, weight: .medium))
                .foregroundColor(item.color)

            // Separator
            Text("|")
                .font(TerminalFont.body(12))
                .foregroundColor(CosmicTheme.textMuted.opacity(0.5))
        }
        .padding(.horizontal, 12)
    }

    /// Hand the scroll to the render server: snap back to the start without
    /// animating, then attach one repeating linear animation. The two-step
    /// dance runs across two main-actor turns so SwiftUI doesn't coalesce
    /// the reset and the restart into a no-op.
    private func restartScrolling() {
        guard !reduceMotion, contentWidth > 0 else {
            isScrolling = false
            return
        }

        var reset = Transaction()
        reset.disablesAnimations = true
        withTransaction(reset) {
            isScrolling = false
        }

        let duration = contentWidth / scrollSpeed
        Task { @MainActor in
            withAnimation(.linear(duration: duration).repeatForever(autoreverses: false)) {
                isScrolling = true
            }
        }
    }
}

// MARK: - Rotation Index

/// Index of the item to show at a given instant for a rotating ticker.
/// Derived purely from the clock so rotating views need no timer state.
private func tickerRotationIndex(at date: Date, every interval: TimeInterval, count: Int) -> Int {
    guard count > 0 else { return 0 }
    let ticks = Int(date.timeIntervalSinceReferenceDate / interval)
    return ((ticks % count) + count) % count
}

// MARK: - Compact Ticker (Single Line, Rotating)

struct CosmicTickerCompact: View {
    @State private var service = CosmicTickerService.shared

    var body: some View {
        TimelineView(.periodic(from: .now, by: 4)) { context in
            let items = service.tickerItems
            let currentIndex = tickerRotationIndex(at: context.date, every: 4, count: items.count)

            ZStack {
                if let item = items[safe: currentIndex] {
                    HStack(spacing: 8) {
                        // Ticker icon
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.caption2)
                            .foregroundColor(CosmicTheme.gold)

                        Text(item.text)
                            .font(TerminalFont.caption(11, weight: .medium))
                            .foregroundColor(item.color)
                            .lineLimit(1)

                        Spacer()

                        // Indicator dots
                        HStack(spacing: 3) {
                            ForEach(0..<min(5, items.count), id: \.self) { index in
                                Circle()
                                    .fill(index == currentIndex % min(5, items.count)
                                        ? CosmicTheme.gold
                                        : CosmicTheme.textMuted.opacity(0.4))
                                    .frame(width: 4, height: 4)
                            }
                        }
                    }
                    .id(currentIndex)
                    .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.3), value: currentIndex)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(CosmicTheme.cardBackground)
        )
        .onAppear {
            service.refreshTicker()
            service.startRefreshTimer()
        }
        .onDisappear {
            service.stopRefreshTimer()
        }
    }
}

// MARK: - Ticker Banner (Full Width with Border)

struct CosmicTickerBanner: View {
    var body: some View {
        VStack(spacing: 0) {
            // Top border
            Rectangle()
                .fill(CosmicTheme.gold.opacity(0.3))
                .frame(height: 1)

            CosmicTickerTape()

            // Bottom border
            Rectangle()
                .fill(CosmicTheme.gold.opacity(0.3))
                .frame(height: 1)
        }
    }
}

// MARK: - Ticker Card (For Portfolio View)

struct CosmicTickerCard: View {
    @State private var service = CosmicTickerService.shared
    @State private var isExpanded: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            Button(action: { withAnimation(.spring(response: 0.3)) { isExpanded.toggle() } }) {
                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: "waveform")
                            .font(.caption)
                            .foregroundColor(CosmicTheme.gold)

                        Text("COSMIC WIRE")
                            .font(TerminalFont.caption(10, weight: .bold))
                            .foregroundColor(CosmicTheme.gold)
                    }

                    Spacer()

                    HStack(spacing: 4) {
                        // Live indicator
                        Circle()
                            .fill(.green)
                            .frame(width: 6, height: 6)

                        Text("LIVE")
                            .font(TerminalFont.caption(8, weight: .bold))
                            .foregroundColor(.green)
                    }

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption2)
                        .foregroundColor(CosmicTheme.textMuted)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }
            .buttonStyle(.plain)

            // Ticker content
            if isExpanded {
                Divider()
                    .background(CosmicTheme.textMuted.opacity(0.4))

                CosmicTickerTape()
                    .transition(.opacity.combined(with: .move(edge: .top)))
            } else {
                CosmicTickerCompact()
                    .padding(.horizontal, 4)
                    .padding(.bottom, 8)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(CosmicTheme.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(CosmicTheme.gold.opacity(0.2), lineWidth: 0.5)
                )
        )
        .onAppear {
            AnalyticsService.shared.track(.cosmicTickerViewed)
        }
    }
}

// MARK: - Minimal Ticker Strip (For Navigation Bar)

struct CosmicTickerStrip: View {
    @State private var service = CosmicTickerService.shared

    var body: some View {
        TimelineView(.periodic(from: .now, by: 3)) { context in
            let items = service.tickerItems
            let currentIndex = tickerRotationIndex(at: context.date, every: 3, count: items.count)

            Group {
                if let item = items[safe: currentIndex] {
                    Text(item.text)
                        .font(TerminalFont.caption(9, weight: .medium))
                        .foregroundColor(item.color)
                        .lineLimit(1)
                        .contentTransition(.numericText())
                }
            }
            .animation(.easeInOut(duration: 0.5), value: currentIndex)
        }
        .onAppear {
            service.refreshTicker()
            service.startRefreshTimer()
        }
        .onDisappear {
            service.stopRefreshTimer()
        }
    }
}

// MARK: - Previews

#Preview("Ticker Tape") {
    VStack {
        CosmicTickerTape()
    }
    .background(CosmicTheme.background)
    .preferredColorScheme(.dark)
}

#Preview("Ticker Banner") {
    VStack {
        Spacer()
        CosmicTickerBanner()
        Spacer()
    }
    .background(CosmicTheme.background)
    .preferredColorScheme(.dark)
}

#Preview("Ticker Card") {
    VStack {
        CosmicTickerCard()
    }
    .padding()
    .background(CosmicTheme.background)
    .preferredColorScheme(.dark)
}

#Preview("Compact Ticker") {
    VStack {
        CosmicTickerCompact()
    }
    .padding()
    .background(CosmicTheme.background)
    .preferredColorScheme(.dark)
}
