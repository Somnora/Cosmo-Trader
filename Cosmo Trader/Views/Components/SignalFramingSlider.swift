import SwiftUI

// MARK: - SignalFramingSlider
// ===========================
// A slider component that lets users control how signals are framed.
// From pure technical/data language to full cosmic/mystical language.
//
// DESIGN: OLED terminal aesthetic with gold accent, sharp corners,
// snap points at predefined levels, haptic feedback.

struct SignalFramingSlider: View {

    // MARK: - Properties

    @Binding var level: SignalFramingLevel

    /// Whether to show "RATIONAL" and "MYSTICAL" labels
    var showLabels: Bool = true

    /// Compact mode for inline use (smaller height)
    var compact: Bool = false

    /// Show discrete segments instead of continuous slider
    var discreteMode: Bool = false

    // MARK: - State

    @State private var dragOffset: CGFloat = 0
    @State private var isDragging = false

    // MARK: - Body

    var body: some View {
        VStack(spacing: compact ? 8 : 12) {
            if discreteMode {
                discreteSegments
            } else {
                continuousSlider
            }

            // Current level indicator
            HStack(spacing: 6) {
                Image(systemName: level.sfSymbol)
                    .font(compact ? .caption : .caption)
                    .foregroundColor(level.color)

                Text(level.displayName.uppercased())
                    .font(TerminalFont.data(compact ? 9 : 10, weight: .semibold))
                    .foregroundColor(level.color)
                    .tracking(0.5)
            }
            .animation(.easeInOut(duration: 0.2), value: level)
        }
    }

    // MARK: - Continuous Slider

    private var continuousSlider: some View {
        VStack(spacing: 8) {
            // Labels
            if showLabels {
                HStack {
                    Text("RATIONAL")
                        .font(TerminalFont.data(9))
                        .foregroundColor(level.rawValue <= 0.25 ? CosmicTheme.positive : CosmicTheme.textMuted)
                        .tracking(0.5)

                    Spacer()

                    Text("MYSTICAL")
                        .font(TerminalFont.data(9))
                        .foregroundColor(level.rawValue >= 0.75 ? CosmicTheme.gold : CosmicTheme.textMuted)
                        .tracking(0.5)
                }
            }

            // Slider track
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background track
                    Rectangle()
                        .fill(CosmicTheme.cardBackground)
                        .frame(height: compact ? 6 : 8)

                    // Gradient fill to current position
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [CosmicTheme.positive, CosmicTheme.gold, CosmicTheme.accentBlue],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * level.rawValue, height: compact ? 6 : 8)

                    // Snap point indicators
                    HStack(spacing: 0) {
                        ForEach(SignalFramingLevel.allCases, id: \.self) { snapLevel in
                            Rectangle()
                                .fill(snapLevel == level ? CosmicTheme.gold : CosmicTheme.border)
                                .frame(width: 1, height: compact ? 10 : 12)
                                .offset(y: compact ? -2 : -2)

                            if snapLevel != .mystical {
                                Spacer()
                            }
                        }
                    }

                    // Thumb
                    Circle()
                        .fill(CosmicTheme.gold)
                        .frame(width: compact ? 16 : 20, height: compact ? 16 : 20)
                        .overlay(
                            Circle()
                                .stroke(CosmicTheme.background, lineWidth: 2)
                        )
                        .shadow(color: CosmicTheme.gold.opacity(0.3), radius: isDragging ? 8 : 4)
                        .offset(x: (geometry.size.width * level.rawValue) - (compact ? 8 : 10))
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    isDragging = true
                                    let newValue = min(1.0, max(0.0, value.location.x / geometry.size.width))
                                    let newLevel = SignalFramingLevel.nearest(to: newValue)

                                    if newLevel != level {
                                        // Haptic feedback on snap
                                        let generator = UIImpactFeedbackGenerator(style: .light)
                                        generator.impactOccurred()
                                        level = newLevel
                                    }
                                }
                                .onEnded { _ in
                                    isDragging = false
                                }
                        )
                }
            }
            .frame(height: compact ? 20 : 24)
        }
    }

    // MARK: - Discrete Segments

    private var discreteSegments: some View {
        VStack(spacing: 8) {
            // Labels
            if showLabels {
                HStack {
                    Text("RATIONAL")
                        .font(TerminalFont.data(9))
                        .foregroundColor(level.rawValue <= 0.25 ? CosmicTheme.positive : CosmicTheme.textMuted)
                        .tracking(0.5)

                    Spacer()

                    Text("MYSTICAL")
                        .font(TerminalFont.data(9))
                        .foregroundColor(level.rawValue >= 0.75 ? CosmicTheme.gold : CosmicTheme.textMuted)
                        .tracking(0.5)
                }
            }

            // Segments
            HStack(spacing: 2) {
                ForEach(SignalFramingLevel.allCases, id: \.self) { segmentLevel in
                    Button(action: {
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
                        withAnimation(.easeInOut(duration: 0.2)) {
                            level = segmentLevel
                        }
                    }) {
                        VStack(spacing: 4) {
                            Rectangle()
                                .fill(segmentLevel == level ? segmentLevel.color : CosmicTheme.cardBackground)
                                .frame(height: compact ? 6 : 8)
                                .overlay(
                                    Rectangle()
                                        .stroke(segmentLevel == level ? segmentLevel.color : CosmicTheme.border, lineWidth: 1)
                                )

                            if !compact {
                                Image(systemName: segmentLevel.sfSymbol)
                                    .font(.caption2)
                                    .foregroundColor(segmentLevel == level ? segmentLevel.color : CosmicTheme.textMuted)
                            }
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
}

// MARK: - Compact Framing Indicator

/// A small indicator showing current framing level (for headers)
struct SignalFramingIndicator: View {

    let level: SignalFramingLevel

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: level.sfSymbol)
                .font(.caption2)
                .foregroundColor(level.color)

            Text(level.shortName)
                .font(TerminalFont.data(8))
                .foregroundColor(level.color)
                .tracking(0.5)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(level.color.opacity(0.15))
    }
}

// MARK: - Preview

#Preview("Signal Framing Slider") {
    struct PreviewWrapper: View {
        @State private var level: SignalFramingLevel = .balanced

        var body: some View {
            ZStack {
                CosmicTheme.background.ignoresSafeArea()

                VStack(spacing: 32) {
                    // Full slider
                    VStack(alignment: .leading, spacing: 8) {
                        Text("SIGNAL FRAMING")
                            .font(TerminalFont.data(10))
                            .foregroundColor(CosmicTheme.textMuted)
                            .tracking(1)

                        SignalFramingSlider(level: $level)
                    }
                    .padding()
                    .background(CosmicTheme.cardBackground)

                    // Compact slider
                    VStack(alignment: .leading, spacing: 8) {
                        Text("COMPACT MODE")
                            .font(TerminalFont.data(10))
                            .foregroundColor(CosmicTheme.textMuted)
                            .tracking(1)

                        SignalFramingSlider(level: $level, compact: true)
                    }
                    .padding()
                    .background(CosmicTheme.cardBackground)

                    // Discrete mode
                    VStack(alignment: .leading, spacing: 8) {
                        Text("DISCRETE MODE")
                            .font(TerminalFont.data(10))
                            .foregroundColor(CosmicTheme.textMuted)
                            .tracking(1)

                        SignalFramingSlider(level: $level, discreteMode: true)
                    }
                    .padding()
                    .background(CosmicTheme.cardBackground)

                    // Indicator
                    HStack {
                        Text("Indicator:")
                            .font(TerminalFont.data(11))
                            .foregroundColor(CosmicTheme.textSecondary)

                        SignalFramingIndicator(level: level)
                    }

                    // Description
                    Text(level.description)
                        .font(TerminalFont.data(11))
                        .foregroundColor(CosmicTheme.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding()
                }
                .padding()
            }
        }
    }

    return PreviewWrapper()
        .preferredColorScheme(.dark)
}
