import SwiftUI

// MARK: - Cosmic Animations
// =========================
// Reusable animation components and modifiers for premium micro-interactions.
// Includes loading states, success animations, transitions, and button styles.

// MARK: - Bouncy Button Style
// ===========================
// A button style that provides a satisfying press animation

struct BouncyButtonStyle: ButtonStyle {
    let scale: CGFloat
    let dampingFraction: CGFloat

    init(scale: CGFloat = 0.92, dampingFraction: CGFloat = 0.5) {
        self.scale = scale
        self.dampingFraction = dampingFraction
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: dampingFraction), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == BouncyButtonStyle {
    static var bouncy: BouncyButtonStyle { BouncyButtonStyle() }
    static func bouncy(scale: CGFloat = 0.92, dampingFraction: CGFloat = 0.5) -> BouncyButtonStyle {
        BouncyButtonStyle(scale: scale, dampingFraction: dampingFraction)
    }
}

// MARK: - Mini Loading Spinner
// =============================
// A compact spinning loader for inline use

struct MiniLoadingSpinner: View {
    let size: CGFloat
    let color: Color

    @State private var rotation: Double = 0

    init(size: CGFloat = 24, color: Color = CosmicTheme.gold) {
        self.size = size
        self.color = color
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.3), lineWidth: 2)
                .frame(width: size, height: size)

            Circle()
                .trim(from: 0, to: 0.3)
                .stroke(color, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                .frame(width: size, height: size)
                .rotationEffect(.degrees(rotation))
        }
        .onAppear {
            withAnimation(.linear(duration: 0.8).repeatForever(autoreverses: false)) {
                rotation = 360
            }
        }
    }
}

// MARK: - Skeleton Loading View
// =============================
// Shimmer effect for placeholder content

struct SkeletonView: View {
    let cornerRadius: CGFloat

    @State private var shimmerOffset: CGFloat = -200

    init(cornerRadius: CGFloat = 8) {
        self.cornerRadius = cornerRadius
    }

    var body: some View {
        GeometryReader { geometry in
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(CosmicTheme.cardBackground)
                .overlay(
                    LinearGradient(
                        colors: [
                            .clear,
                            CosmicTheme.textMuted.opacity(0.3),
                            .clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .offset(x: shimmerOffset)
                )
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                .onAppear {
                    withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                        shimmerOffset = geometry.size.width + 200
                    }
                }
        }
    }
}

// MARK: - Success Checkmark
// =========================
// Animated checkmark for successful actions

struct SuccessCheckmark: View {
    @State private var trimEnd: CGFloat = 0
    @State private var circleScale: CGFloat = 0.5
    @State private var opacity: Double = 0

    let size: CGFloat
    let color: Color

    init(size: CGFloat = 60, color: Color = CosmicTheme.positive) {
        self.size = size
        self.color = color
    }

    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .fill(color.opacity(0.2))
                .frame(width: size, height: size)
                .scaleEffect(circleScale)

            // Circle stroke
            Circle()
                .stroke(color, lineWidth: 3)
                .frame(width: size, height: size)
                .scaleEffect(circleScale)

            // Checkmark path
            CheckmarkShape()
                .trim(from: 0, to: trimEnd)
                .stroke(color, style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
                .frame(width: size * 0.4, height: size * 0.4)
        }
        .opacity(opacity)
        .onAppear {
            // Circle appears first
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                circleScale = 1.0
                opacity = 1.0
            }
            // Then checkmark draws
            withAnimation(.easeOut(duration: 0.3).delay(0.2)) {
                trimEnd = 1.0
            }
        }
    }
}

// Custom checkmark shape for proper animation
struct CheckmarkShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height

        path.move(to: CGPoint(x: width * 0.1, y: height * 0.5))
        path.addLine(to: CGPoint(x: width * 0.4, y: height * 0.8))
        path.addLine(to: CGPoint(x: width * 0.9, y: height * 0.2))

        return path
    }
}

// MARK: - Confetti Celebration
// ============================
// Celebratory particle effect

struct ConfettiView: View {
    @State private var particles: [ConfettiParticle] = []

    let colors: [Color]
    let particleCount: Int

    init(colors: [Color] = [.yellow, .orange, .purple, .blue, .green, .pink], particleCount: Int = 50) {
        self.colors = colors
        self.particleCount = particleCount
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(particles) { particle in
                    Circle()
                        .fill(particle.color)
                        .frame(width: particle.size, height: particle.size)
                        .position(particle.position)
                        .opacity(particle.opacity)
                        .rotationEffect(.degrees(particle.rotation))
                }
            }
            .onAppear {
                startConfetti(in: geometry.size)
            }
        }
        .allowsHitTesting(false)
    }

    private func startConfetti(in size: CGSize) {
        particles = (0..<particleCount).map { _ in
            ConfettiParticle(
                color: colors.randomElement() ?? .yellow,
                size: CGFloat.random(in: 4...10),
                position: CGPoint(x: CGFloat.random(in: 0...size.width), y: -20),
                velocity: CGPoint(x: CGFloat.random(in: -100...100), y: CGFloat.random(in: 300...600)),
                rotation: Double.random(in: 0...360)
            )
        }

        withAnimation(.linear(duration: 2.5)) {
            for i in particles.indices {
                particles[i].position.y += particles[i].velocity.y
                particles[i].position.x += particles[i].velocity.x
                particles[i].rotation += Double.random(in: 180...360)
                particles[i].opacity = 0
            }
        }
    }
}

struct ConfettiParticle: Identifiable {
    let id = UUID()
    var color: Color
    var size: CGFloat
    var position: CGPoint
    var velocity: CGPoint
    var rotation: Double
    var opacity: Double = 1.0
}

// MARK: - Slide In Modifier
// =========================
// Staggered slide-in animation for list items

struct SlideInModifier: ViewModifier {
    let index: Int
    let direction: SlideDirection
    @State private var appeared = false

    enum SlideDirection {
        case leading, trailing, bottom
    }

    init(index: Int, direction: SlideDirection = .trailing) {
        self.index = index
        self.direction = direction
    }

    func body(content: Content) -> some View {
        content
            .offset(x: offsetX, y: offsetY)
            .opacity(appeared ? 1 : 0)
            .onAppear {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7).delay(Double(index) * 0.05)) {
                    appeared = true
                }
            }
    }

    private var offsetX: CGFloat {
        guard !appeared else { return 0 }
        switch direction {
        case .leading: return -50
        case .trailing: return 50
        case .bottom: return 0
        }
    }

    private var offsetY: CGFloat {
        guard !appeared else { return 0 }
        switch direction {
        case .bottom: return 30
        default: return 0
        }
    }
}

extension View {
    func slideIn(index: Int, from direction: SlideInModifier.SlideDirection = .trailing) -> some View {
        modifier(SlideInModifier(index: index, direction: direction))
    }
}

// MARK: - Animated Number
// =======================
// Smooth number transitions

struct AnimatedNumber: View, Animatable {
    var value: Double
    let format: String
    let font: Font
    let color: Color

    var animatableData: Double {
        get { value }
        set { value = newValue }
    }

    init(value: Double, format: String = "%.2f", font: Font = .body, color: Color = CosmicTheme.textPrimary) {
        self.value = value
        self.format = format
        self.font = font
        self.color = color
    }

    var body: some View {
        Text(String(format: format, value))
            .font(font)
            .foregroundColor(color)
            .contentTransition(.numericText())
    }
}

// MARK: - Animated Currency
// =========================
// Animated dollar value display

struct AnimatedCurrency: View {
    let value: Double
    let showSign: Bool

    @State private var displayValue: Double = 0

    init(value: Double, showSign: Bool = false) {
        self.value = value
        self.showSign = showSign
    }

    var body: some View {
        Text(formattedValue)
            .contentTransition(.numericText())
            .onChange(of: value) { oldValue, newValue in
                withAnimation(.easeOut(duration: 0.5)) {
                    displayValue = newValue
                }
            }
            .onAppear {
                displayValue = value
            }
    }

    private var formattedValue: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 2

        if showSign && displayValue > 0 {
            return "+\(formatter.string(from: NSNumber(value: displayValue)) ?? "$0.00")"
        }
        return formatter.string(from: NSNumber(value: displayValue)) ?? "$0.00"
    }
}

// MARK: - Animated Percentage
// ===========================
// Percentage with color and direction indicator

struct AnimatedPercentage: View {
    let value: Double
    let showArrow: Bool

    init(value: Double, showArrow: Bool = true) {
        self.value = value
        self.showArrow = showArrow
    }

    var color: Color {
        value >= 0 ? CosmicTheme.positive : CosmicTheme.negative
    }

    var body: some View {
        HStack(spacing: 4) {
            if showArrow {
                Image(systemName: value >= 0 ? "arrow.up" : "arrow.down")
                    .font(.caption2)
            }

            Text(String(format: "%.2f%%", abs(value)))
                .contentTransition(.numericText())
        }
        .foregroundColor(color)
    }
}

// MARK: - Swipe Indicator Overlay
// ===============================
// Visual feedback during card swipe

struct SwipeIndicatorOverlay: View {
    let offset: CGFloat
    let threshold: CGFloat

    init(offset: CGFloat, threshold: CGFloat = 100) {
        self.offset = offset
        self.threshold = threshold
    }

    var likeOpacity: Double {
        min(1.0, max(0, Double(offset / threshold)))
    }

    var skipOpacity: Double {
        min(1.0, max(0, Double(-offset / threshold)))
    }

    var body: some View {
        ZStack {
            // Like indicator (right swipe)
            HStack {
                Spacer()
                likeIndicator
                    .padding(.trailing, 40)
            }
            .opacity(likeOpacity)

            // Skip indicator (left swipe)
            HStack {
                skipIndicator
                    .padding(.leading, 40)
                Spacer()
            }
            .opacity(skipOpacity)
        }
    }

    private var likeIndicator: some View {
        VStack(spacing: 8) {
            Image(systemName: "heart.fill")
                .font(.system(size: 50, weight: .bold))
                .foregroundColor(CosmicTheme.positive)
                .scaleEffect(1 + likeOpacity * 0.2)

            Text("WATCHLIST")
                .font(TerminalFont.data(12, weight: .bold))
                .foregroundColor(CosmicTheme.positive)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(CosmicTheme.positive.opacity(0.2))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(CosmicTheme.positive, lineWidth: 3)
                )
        )
        .rotationEffect(.degrees(-15))
    }

    private var skipIndicator: some View {
        VStack(spacing: 8) {
            Image(systemName: "xmark")
                .font(.system(size: 50, weight: .bold))
                .foregroundColor(CosmicTheme.negative)
                .scaleEffect(1 + skipOpacity * 0.2)

            Text("SKIP")
                .font(TerminalFont.data(12, weight: .bold))
                .foregroundColor(CosmicTheme.negative)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(CosmicTheme.negative.opacity(0.2))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(CosmicTheme.negative, lineWidth: 3)
                )
        )
        .rotationEffect(.degrees(15))
    }
}

// MARK: - Pulse Animation Modifier
// ================================
// Subtle pulsing effect for attention

struct PulseModifier: ViewModifier {
    @State private var isPulsing = false
    let minScale: CGFloat
    let maxScale: CGFloat
    let duration: Double

    init(minScale: CGFloat = 0.95, maxScale: CGFloat = 1.05, duration: Double = 1.0) {
        self.minScale = minScale
        self.maxScale = maxScale
        self.duration = duration
    }

    func body(content: Content) -> some View {
        content
            .scaleEffect(isPulsing ? maxScale : minScale)
            .onAppear {
                withAnimation(.easeInOut(duration: duration).repeatForever(autoreverses: true)) {
                    isPulsing = true
                }
            }
    }
}

extension View {
    func pulse(minScale: CGFloat = 0.95, maxScale: CGFloat = 1.05, duration: Double = 1.0) -> some View {
        modifier(PulseModifier(minScale: minScale, maxScale: maxScale, duration: duration))
    }
}

// MARK: - Shake Animation Modifier
// ================================
// Error shake animation

struct ShakeModifier: ViewModifier {
    let shakes: Int
    var animatableData: CGFloat

    init(shakes: Int, animatableData: CGFloat) {
        self.shakes = shakes
        self.animatableData = animatableData
    }

    func body(content: Content) -> some View {
        content
            .offset(x: sin(animatableData * .pi * CGFloat(shakes)) * 10)
    }
}

extension View {
    func shake(trigger: Bool) -> some View {
        modifier(ShakeModifier(shakes: 4, animatableData: trigger ? 1 : 0))
            .animation(.linear(duration: 0.4), value: trigger)
    }
}

// MARK: - Glow Effect Modifier
// ============================
// Soft glow around elements

struct GlowModifier: ViewModifier {
    let color: Color
    let radius: CGFloat
    @State private var isGlowing = false

    init(color: Color = CosmicTheme.gold, radius: CGFloat = 10) {
        self.color = color
        self.radius = radius
    }

    func body(content: Content) -> some View {
        content
            .shadow(color: color.opacity(isGlowing ? 0.6 : 0.3), radius: isGlowing ? radius : radius * 0.5)
            .onAppear {
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                    isGlowing = true
                }
            }
    }
}

extension View {
    func cosmicGlow(color: Color = CosmicTheme.gold, radius: CGFloat = 10) -> some View {
        modifier(GlowModifier(color: color, radius: radius))
    }
}

// MARK: - Card Flip View
// ======================
// 3D flip transition between two views

struct CardFlipView<Front: View, Back: View>: View {
    @Binding var isFlipped: Bool
    let front: Front
    let back: Back

    init(isFlipped: Binding<Bool>, @ViewBuilder front: () -> Front, @ViewBuilder back: () -> Back) {
        self._isFlipped = isFlipped
        self.front = front()
        self.back = back()
    }

    var body: some View {
        ZStack {
            front
                .rotation3DEffect(.degrees(isFlipped ? 180 : 0), axis: (x: 0, y: 1, z: 0))
                .opacity(isFlipped ? 0 : 1)

            back
                .rotation3DEffect(.degrees(isFlipped ? 0 : -180), axis: (x: 0, y: 1, z: 0))
                .opacity(isFlipped ? 1 : 0)
        }
        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: isFlipped)
    }
}

// MARK: - Success Toast View
// ==========================
// Animated success notification

struct SuccessToast: View {
    let message: String
    let icon: String

    @State private var appeared = false

    init(message: String, icon: String = "checkmark.circle.fill") {
        self.message = message
        self.icon = icon
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(CosmicTheme.positive)

            Text(message)
                .font(TerminalFont.data(14, weight: .medium))
                .foregroundColor(CosmicTheme.textPrimary)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(
            Capsule()
                .fill(CosmicTheme.cardBackground)
                .shadow(color: Color.black.opacity(0.3), radius: 10, y: 5)
        )
        .overlay(
            Capsule()
                .stroke(CosmicTheme.positive.opacity(0.5), lineWidth: 1)
        )
        .scaleEffect(appeared ? 1 : 0.8)
        .opacity(appeared ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                appeared = true
            }
        }
    }
}

// MARK: - Skeleton List Item
// ==========================
// Placeholder for loading list items

struct SkeletonListItem: View {
    let index: Int

    var body: some View {
        HStack(spacing: 12) {
            // Avatar placeholder
            SkeletonView(cornerRadius: 12)
                .frame(width: 48, height: 48)

            VStack(alignment: .leading, spacing: 8) {
                // Title
                SkeletonView()
                    .frame(height: 16)
                    .frame(maxWidth: 120)

                // Subtitle
                SkeletonView()
                    .frame(height: 12)
                    .frame(maxWidth: 80)
            }

            Spacer()

            // Value placeholder
            VStack(alignment: .trailing, spacing: 6) {
                SkeletonView()
                    .frame(width: 70, height: 16)

                SkeletonView()
                    .frame(width: 50, height: 12)
            }
        }
        .padding(.vertical, 8)
        .slideIn(index: index)
    }
}

// MARK: - Previews

#Preview("Mini Loading Spinner") {
    ZStack {
        CosmicTheme.background.ignoresSafeArea()
        MiniLoadingSpinner()
    }
}

#Preview("Success Checkmark") {
    ZStack {
        CosmicTheme.background.ignoresSafeArea()
        SuccessCheckmark()
    }
}

#Preview("Confetti") {
    ZStack {
        CosmicTheme.background.ignoresSafeArea()
        ConfettiView()
    }
}

#Preview("Skeleton Loading") {
    ZStack {
        CosmicTheme.background.ignoresSafeArea()
        VStack(spacing: 16) {
            ForEach(0..<5, id: \.self) { index in
                SkeletonListItem(index: index)
            }
        }
        .padding()
    }
}

#Preview("Bouncy Button") {
    ZStack {
        CosmicTheme.background.ignoresSafeArea()
        Button("Press Me") {}
            .font(.headline)
            .foregroundColor(.white)
            .padding()
            .background(CosmicTheme.gold)
            .cornerRadius(12)
            .buttonStyle(.bouncy)
    }
}

#Preview("Swipe Indicator") {
    ZStack {
        CosmicTheme.background.ignoresSafeArea()
        SwipeIndicatorOverlay(offset: 80)
    }
}
