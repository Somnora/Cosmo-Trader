import SwiftUI

// MARK: - J.P. Morgan Quote View
// ==============================
// "Millionaires don't use astrology, billionaires do."
// A reusable component displaying the famous J.P. Morgan quote.
// Design: Terminal monospace font, slightly dimmed, let it breathe.

struct JPMorganQuoteView: View {

    // MARK: - Properties

    enum Size {
        case full       // Onboarding - centered, larger, more space
        case compact    // Paywall - smaller, tighter spacing
        case minimal    // Launch screen - smallest, subtle
    }

    let size: Size
    var opacity: Double = 1.0

    // MARK: - Body

    var body: some View {
        VStack(alignment: .trailing, spacing: quoteSpacing) {
            // The quote
            Text("\"Millionaires don't use astrology, billionaires do.\"")
                .font(quoteFont)
                .foregroundColor(quoteColor)
                .multilineTextAlignment(.center)
                .lineSpacing(lineSpacing)

            // Attribution
            Text("— J.P. Morgan")
                .font(attributionFont)
                .foregroundColor(attributionColor)
        }
        .frame(maxWidth: maxWidth)
        .opacity(opacity)
    }

    // MARK: - Styling

    private var quoteFont: Font {
        switch size {
        case .full:
            return .system(size: 18, weight: .regular, design: .monospaced)
        case .compact:
            return .system(size: 13, weight: .regular, design: .monospaced)
        case .minimal:
            return .system(size: 11, weight: .regular, design: .monospaced)
        }
    }

    private var attributionFont: Font {
        switch size {
        case .full:
            return .system(size: 14, weight: .light, design: .monospaced)
        case .compact:
            return .system(size: 11, weight: .light, design: .monospaced)
        case .minimal:
            return .system(size: 9, weight: .light, design: .monospaced)
        }
    }

    private var quoteColor: Color {
        switch size {
        case .full:
            return CosmicTheme.textPrimary
        case .compact:
            return CosmicTheme.textSecondary
        case .minimal:
            return Color(hex: "666666")
        }
    }

    private var attributionColor: Color {
        switch size {
        case .full:
            return CosmicTheme.textMuted
        case .compact:
            return CosmicTheme.textMuted.opacity(0.7)
        case .minimal:
            return Color(hex: "444444")
        }
    }

    private var quoteSpacing: CGFloat {
        switch size {
        case .full: return 16
        case .compact: return 10
        case .minimal: return 6
        }
    }

    private var lineSpacing: CGFloat {
        switch size {
        case .full: return 6
        case .compact: return 4
        case .minimal: return 2
        }
    }

    private var maxWidth: CGFloat? {
        switch size {
        case .full: return 300
        case .compact: return 280
        case .minimal: return 260
        }
    }
}

// MARK: - Onboarding Quote Step View

struct OnboardingQuoteStepView: View {

    @State private var quoteOpacity: Double = 0
    @State private var showContinue: Bool = false

    var onContinue: () -> Void

    var body: some View {
        VStack(spacing: 60) {
            Spacer()

            // The quote with fade-in
            JPMorganQuoteView(size: .full, opacity: quoteOpacity)
                .padding(.horizontal, 32)

            Spacer()

            // Continue button (appears after delay)
            if showContinue {
                Button(action: onContinue) {
                    Text("Continue")
                        .font(.system(size: 14, weight: .medium, design: .monospaced))
                        .foregroundColor(CosmicTheme.gold)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .strokeBorder(CosmicTheme.gold.opacity(0.5), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }

            Spacer()
                .frame(height: 80)
        }
        .onAppear {
            // Fade in quote
            withAnimation(.easeIn(duration: 1.0)) {
                quoteOpacity = 1.0
            }

            // Show continue button after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation(.easeIn(duration: 0.5)) {
                    showContinue = true
                }
            }
        }
    }
}

// MARK: - Onboarding Disclaimer Step View

struct OnboardingDisclaimerStepView: View {

    @State private var contentOpacity: Double = 0
    @State private var showButton: Bool = false

    var onAcknowledge: () -> Void

    private let disclaimerText = "Cosmo Trader is for informational and entertainment purposes only and does not constitute financial advice. Always consult a qualified financial advisor before making investment decisions."

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Warning icon
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48, weight: .light))
                .foregroundColor(CosmicTheme.gold)
                .opacity(contentOpacity)

            // Title
            Text("IMPORTANT")
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundColor(CosmicTheme.gold)
                .tracking(4)
                .opacity(contentOpacity)

            // Disclaimer text
            Text(disclaimerText)
                .font(.system(size: 14, weight: .regular, design: .monospaced))
                .foregroundColor(CosmicTheme.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(6)
                .padding(.horizontal, 24)
                .opacity(contentOpacity)

            Spacer()

            // "I Understand" button
            if showButton {
                Button(action: {
                    AnalyticsService.shared.trackOnboardingDisclaimerAccepted()
                    onAcknowledge()
                }) {
                    Text("I Understand")
                        .font(.system(size: 14, weight: .semibold, design: .monospaced))
                        .foregroundColor(CosmicTheme.terminalBlack)
                        .tracking(1)
                        .padding(.horizontal, 40)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(CosmicTheme.gold)
                        )
                }
                .buttonStyle(.plain)
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }

            Spacer()
                .frame(height: 80)
        }
        .onAppear {
            // Fade in content
            withAnimation(.easeIn(duration: 0.8)) {
                contentOpacity = 1.0
            }

            // Show button after reading delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation(.easeIn(duration: 0.4)) {
                    showButton = true
                }
            }
        }
    }
}

// MARK: - Preview

#Preview("Full Size - Onboarding") {
    ZStack {
        Color.black.ignoresSafeArea()
        OnboardingQuoteStepView {
            // Debug action removed for release
        }
    }
}

#Preview("Compact - Paywall") {
    ZStack {
        CosmicTheme.terminalBlack.ignoresSafeArea()
        JPMorganQuoteView(size: .compact)
            .padding()
    }
}

#Preview("Minimal - Launch") {
    ZStack {
        Color.black.ignoresSafeArea()
        JPMorganQuoteView(size: .minimal)
            .padding()
    }
}

#Preview("Disclaimer - Onboarding") {
    ZStack {
        Color.black.ignoresSafeArea()
        OnboardingDisclaimerStepView {
            // Debug action removed for release
        }
    }
}
