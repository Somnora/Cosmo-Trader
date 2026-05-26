import SwiftUI

// MARK: - Cosmic Ticker Views
// ===========================
// Bloomberg-style scrolling ticker tape with cosmic commentary.
//
// "AAPL +1.2% | TSLA -0.4% | MOON IN SCORPIO | GOOGL +0.8% | VOC ENDS 2PM"
//
// WHY IT WORKS: Bloomberg meets mysticism. Constantly engaging. Premium feel.

// MARK: - Cosmic Ticker Tape (Main Component)

struct CosmicTickerTape: View {
    @State private var service = CosmicTickerService.shared
    @State private var offset: CGFloat = 0
    @State private var contentWidth: CGFloat = 0

    /// Speed of ticker scroll (points per second)
    private let scrollSpeed: CGFloat = 40

    /// Timer for animation
    @State private var animationTimer: Timer?

    var body: some View {
        GeometryReader { geometry in
            let viewWidth = geometry.size.width

            HStack(spacing: 0) {
                // First copy of ticker items
                tickerContent
                    .background(
                        GeometryReader { contentGeo in
                            Color.clear
                                .onAppear {
                                    contentWidth = contentGeo.size.width
                                }
                        }
                    )

                // Second copy for seamless looping
                tickerContent
            }
            .offset(x: offset)
            .onAppear {
                startAnimation(viewWidth: viewWidth)
            }
            .onDisappear {
                animationTimer?.invalidate()
            }
            .onChange(of: service.tickerItems) { _, _ in
                // Reset animation when items change
                offset = 0
                startAnimation(viewWidth: viewWidth)
            }
        }
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

    private func startAnimation(viewWidth: CGFloat) {
        animationTimer?.invalidate()

        guard contentWidth > 0 else { return }

        // Reset to start
        offset = 0

        // Create smooth animation timer
        animationTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { _ in
            Task { @MainActor in
                offset -= scrollSpeed / 60.0

                // Reset when first copy has scrolled off
                if abs(offset) >= contentWidth {
                    offset = 0
                }
            }
        }
    }
}

// MARK: - Compact Ticker (Single Line, No Animation)

struct CosmicTickerCompact: View {
    @State private var service = CosmicTickerService.shared
    @State private var currentIndex: Int = 0
    @State private var fadeIn: Bool = true

    /// Auto-rotate timer
    @State private var rotateTimer: Timer?

    var body: some View {
        Group {
            if let item = service.tickerItems[safe: currentIndex] {
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
                        ForEach(0..<min(5, service.tickerItems.count), id: \.self) { index in
                            Circle()
                                .fill(index == currentIndex % min(5, service.tickerItems.count)
                                    ? CosmicTheme.gold
                                    : CosmicTheme.textMuted.opacity(0.4))
                                .frame(width: 4, height: 4)
                        }
                    }
                }
                .opacity(fadeIn ? 1 : 0)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(CosmicTheme.cardBackground)
        )
        .onAppear {
            startRotation()
        }
        .onDisappear {
            rotateTimer?.invalidate()
        }
    }

    private func startRotation() {
        rotateTimer?.invalidate()

        rotateTimer = Timer.scheduledTimer(withTimeInterval: 4.0, repeats: true) { _ in
            Task { @MainActor in
                // Fade out
                withAnimation(.easeOut(duration: 0.3)) {
                    fadeIn = false
                }

                // Wait and change
                try? await Task.sleep(nanoseconds: 300_000_000)

                currentIndex = (currentIndex + 1) % max(1, service.tickerItems.count)

                // Fade in
                withAnimation(.easeIn(duration: 0.3)) {
                    fadeIn = true
                }
            }
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
    @State private var currentIndex: Int = 0

    var body: some View {
        Group {
            if let item = service.tickerItems[safe: currentIndex] {
                Text(item.text)
                    .font(TerminalFont.caption(9, weight: .medium))
                    .foregroundColor(item.color)
                    .lineLimit(1)
                    .contentTransition(.numericText())
            }
        }
        .onAppear {
            startRotation()
        }
    }

    private func startRotation() {
        Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
            Task { @MainActor in
                withAnimation(.easeInOut(duration: 0.5)) {
                    currentIndex = (currentIndex + 1) % max(1, service.tickerItems.count)
                }
            }
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
