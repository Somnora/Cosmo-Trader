import SwiftUI

// MARK: - CosmicErrorView
// =======================
// A cosmic-themed error view component that displays errors
// with witty messages and appropriate actions.
//
// Usage:
// CosmicErrorView(
//     error: .network(.noConnection),
//     onRetry: { await refreshData() },
//     onDismiss: { errorState.dismiss() }
// )

struct CosmicErrorView: View {

    // MARK: - Properties

    let error: AppError
    let onRetry: (() async -> Void)?
    let onDismiss: (() -> Void)?
    let style: Style

    enum Style {
        case fullScreen   // Takes up most of the view
        case card         // Compact card style
        case banner       // Slim banner at top
        case inline       // Minimal inline message
    }

    // MARK: - State

    @State private var isRetrying: Bool = false
    @State private var starPulse: Bool = false

    // MARK: - Init

    init(
        error: AppError,
        style: Style = .fullScreen,
        onRetry: (() async -> Void)? = nil,
        onDismiss: (() -> Void)? = nil
    ) {
        self.error = error
        self.style = style
        self.onRetry = onRetry
        self.onDismiss = onDismiss
    }

    // MARK: - Convenience inits

    /// Network error convenience
    init(
        networkError: NetworkError,
        style: Style = .fullScreen,
        onRetry: (() async -> Void)? = nil,
        onDismiss: (() -> Void)? = nil
    ) {
        self.error = .network(networkError)
        self.style = style
        self.onRetry = onRetry
        self.onDismiss = onDismiss
    }

    /// Data error convenience
    init(
        dataError: DataError,
        style: Style = .fullScreen,
        onRetry: (() async -> Void)? = nil,
        onDismiss: (() -> Void)? = nil
    ) {
        self.error = .data(dataError)
        self.style = style
        self.onRetry = onRetry
        self.onDismiss = onDismiss
    }

    // MARK: - Body

    var body: some View {
        switch style {
        case .fullScreen:
            fullScreenContent
        case .card:
            cardContent
        case .banner:
            bannerContent
        case .inline:
            inlineContent
        }
    }

    // MARK: - Full Screen Style

    private var fullScreenContent: some View {
        VStack(spacing: 32) {
            Spacer()

            // Animated illustration
            errorIllustration
                .frame(height: 160)

            // Message content
            VStack(spacing: 12) {
                Text(errorTitle)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(CosmicTheme.textPrimary)
                    .multilineTextAlignment(.center)

                Text(error.cosmicMessage)
                    .font(.body)
                    .foregroundColor(CosmicTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            .padding(.horizontal, 32)

            // Action buttons
            actionButtons
                .padding(.top, 8)

            Spacer()

            // Subtle footer
            Text(footerText)
                .font(.caption2)
                .foregroundColor(CosmicTheme.textMuted)
                .padding(.bottom, 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(CosmicTheme.background)
        .onAppear {
            startPulseAnimation()
        }
    }

    // MARK: - Card Style

    private var cardContent: some View {
        VStack(spacing: 20) {
            // Icon
            ZStack {
                Circle()
                    .fill(errorColor.opacity(0.15))
                    .frame(width: 70, height: 70)

                Image(systemName: errorIcon)
                    .font(.system(size: 32))
                    .foregroundColor(errorColor)
            }

            // Message
            VStack(spacing: 8) {
                Text(errorTitle)
                    .font(.headline)
                    .foregroundColor(CosmicTheme.textPrimary)
                    .multilineTextAlignment(.center)

                Text(error.cosmicMessage)
                    .font(.subheadline)
                    .foregroundColor(CosmicTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
            }

            // Actions
            compactActionButtons
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(CosmicTheme.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(errorColor.opacity(0.3), lineWidth: 1)
                )
        )
    }

    // MARK: - Banner Style

    private var bannerContent: some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: errorIcon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(errorColor)
                .frame(width: 36, height: 36)
                .background(
                    Circle()
                        .fill(errorColor.opacity(0.15))
                )

            // Text
            VStack(alignment: .leading, spacing: 2) {
                Text(errorTitle)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(CosmicTheme.textPrimary)

                Text(error.cosmicMessage)
                    .font(.caption)
                    .foregroundColor(CosmicTheme.textSecondary)
                    .lineLimit(2)
            }

            Spacer()

            // Retry or dismiss
            if onRetry != nil, isRetryable {
                Button(action: handleRetry) {
                    if isRetrying {
                        ProgressView()
                            .scaleEffect(0.8)
                            .tint(errorColor)
                    } else {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(errorColor)
                    }
                }
                .frame(width: 32, height: 32)
                .disabled(isRetrying)
            }

            if let onDismiss = onDismiss {
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(CosmicTheme.textMuted)
                        .frame(width: 24, height: 24)
                        .background(Circle().fill(CosmicTheme.cardBackground))
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(CosmicTheme.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(errorColor.opacity(0.3), lineWidth: 1)
                )
                .shadow(color: errorColor.opacity(0.1), radius: 8, y: 2)
        )
    }

    // MARK: - Inline Style

    private var inlineContent: some View {
        HStack(spacing: 8) {
            Image(systemName: errorIcon)
                .font(.caption)
                .foregroundColor(errorColor)

            Text(error.cosmicMessage)
                .font(.caption)
                .foregroundColor(CosmicTheme.textSecondary)
                .lineLimit(2)

            Spacer()

            if onRetry != nil, isRetryable {
                Button("Retry", action: handleRetry)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(errorColor)
                    .disabled(isRetrying)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(errorColor.opacity(0.1))
        )
    }

    // MARK: - Error Illustration

    private var errorIllustration: some View {
        ZStack {
            // Background glow rings
            ForEach(0..<3, id: \.self) { ring in
                Circle()
                    .stroke(errorColor.opacity(0.1 - Double(ring) * 0.02), lineWidth: 1.5)
                    .frame(width: 100 + CGFloat(ring) * 35, height: 100 + CGFloat(ring) * 35)
                    .scaleEffect(starPulse ? 1.05 : 1.0)
                    .animation(
                        .easeInOut(duration: 2.0)
                        .repeatForever(autoreverses: true)
                        .delay(Double(ring) * 0.2),
                        value: starPulse
                    )
            }

            // Core glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            errorColor.opacity(0.3),
                            errorColor.opacity(0.1),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 20,
                        endRadius: 60
                    )
                )
                .frame(width: 120, height: 120)

            // Floating stars
            ForEach(0..<8, id: \.self) { i in
                let angle = Double(i) * (360.0 / 8.0) - 90
                let radians = angle * .pi / 180
                let distance: CGFloat = 55

                Image(systemName: "star.fill")
                    .font(.system(size: 8))
                    .foregroundColor(CosmicTheme.gold.opacity(0.4 + Double(i % 3) * 0.2))
                    .offset(
                        x: cos(radians) * distance,
                        y: sin(radians) * distance
                    )
                    .scaleEffect(starPulse ? 0.8 : 1.2)
                    .animation(
                        .easeInOut(duration: 1.5)
                        .repeatForever(autoreverses: true)
                        .delay(Double(i) * 0.1),
                        value: starPulse
                    )
            }

            // Main icon
            Image(systemName: errorIcon)
                .font(.system(size: 48))
                .foregroundColor(errorColor)
                .scaleEffect(starPulse ? 1.02 : 0.98)
                .animation(
                    .easeInOut(duration: 2.0)
                    .repeatForever(autoreverses: true),
                    value: starPulse
                )
        }
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        VStack(spacing: 12) {
            // Primary action (retry if available)
            if onRetry != nil, isRetryable {
                Button(action: handleRetry) {
                    HStack(spacing: 8) {
                        if isRetrying {
                            ProgressView()
                                .scaleEffect(0.8)
                                .tint(CosmicTheme.background)
                        } else {
                            Image(systemName: "arrow.clockwise")
                        }
                        Text(isRetrying ? "Retrying..." : "Try Again")
                    }
                    .font(.headline)
                    .foregroundColor(CosmicTheme.background)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(errorColor)
                    )
                }
                .disabled(isRetrying)
                .padding(.horizontal, 40)
            }

            // Secondary action (dismiss or go back)
            if let onDismiss = onDismiss {
                Button(action: onDismiss) {
                    Text("Go Back")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(CosmicTheme.textSecondary)
                }
            }
        }
    }

    private var compactActionButtons: some View {
        HStack(spacing: 12) {
            if let onDismiss = onDismiss {
                Button(action: onDismiss) {
                    Text("Dismiss")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(CosmicTheme.textSecondary)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .stroke(CosmicTheme.textMuted, lineWidth: 1)
                        )
                }
            }

            if onRetry != nil, isRetryable {
                Button(action: handleRetry) {
                    HStack(spacing: 6) {
                        if isRetrying {
                            ProgressView()
                                .scaleEffect(0.7)
                                .tint(.white)
                        } else {
                            Image(systemName: "arrow.clockwise")
                                .font(.caption)
                        }
                        Text(isRetrying ? "..." : "Retry")
                    }
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Capsule().fill(errorColor))
                }
                .disabled(isRetrying)
            }
        }
    }

    // MARK: - Helpers

    private var errorTitle: String {
        switch error {
        case .network(let err):
            switch err {
            case .noConnection: return "Lost in Space"
            case .timeout: return "Stars Are Slow"
            case .serverError: return "Cosmic Turbulence"
            case .rateLimited: return "Too Many Wishes"
            case .invalidSymbol: return "Unknown Star"
            case .apiKeyMissing: return "Gateway Closed"
            default: return "Cosmic Interference"
            }
        case .data:
            return "Data Anomaly"
        case .validation:
            return "Invalid Input"
        }
    }

    private var errorIcon: String {
        switch error {
        case .network(let err):
            return err.icon
        case .data:
            return "externaldrive.badge.exclamationmark"
        case .validation:
            return "exclamationmark.bubble"
        }
    }

    private var errorColor: Color {
        switch error {
        case .network(let err):
            return err.themeColor
        case .data:
            return .purple
        case .validation:
            return .blue
        }
    }

    private var isRetryable: Bool {
        switch error {
        case .network(let err):
            return err.isRetryable
        case .data:
            return true
        case .validation:
            return false
        }
    }

    private var footerText: String {
        switch error {
        case .network(let err):
            return err.suggestedAction
        case .data:
            return "Your data is safe in the cosmos"
        case .validation:
            return "Please check your input"
        }
    }

    private func handleRetry() {
        guard let onRetry = onRetry else { return }

        isRetrying = true
        Task {
            await onRetry()
            await MainActor.run {
                isRetrying = false
            }
        }
    }

    private func startPulseAnimation() {
        withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
            starPulse = true
        }
    }
}

// MARK: - Empty State View
// ========================
// A cosmic-themed empty state component

struct CosmicEmptyStateView: View {

    let title: String
    let message: String
    let icon: String
    let actionTitle: String?
    let action: (() -> Void)?

    @State private var floatAnimation: Bool = false

    init(
        title: String,
        message: String,
        icon: String = "sparkles",
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.title = title
        self.message = message
        self.icon = icon
        self.actionTitle = actionTitle
        self.action = action
    }

    var body: some View {
        VStack(spacing: 24) {
            // Animated illustration
            ZStack {
                // Background stars
                ForEach(0..<6, id: \.self) { i in
                    let angle = Double(i) * (360.0 / 6.0)
                    let radians = angle * .pi / 180
                    let distance: CGFloat = 50 + CGFloat(i % 2) * 15

                    Image(systemName: "star.fill")
                        .font(.system(size: 6 + CGFloat(i % 3) * 2))
                        .foregroundColor(CosmicTheme.gold.opacity(0.3 + Double(i % 3) * 0.15))
                        .offset(
                            x: cos(radians) * distance,
                            y: sin(radians) * distance
                        )
                        .scaleEffect(floatAnimation ? 0.9 : 1.1)
                        .animation(
                            .easeInOut(duration: 2.0)
                            .repeatForever(autoreverses: true)
                            .delay(Double(i) * 0.15),
                            value: floatAnimation
                        )
                }

                // Main icon
                Image(systemName: icon)
                    .font(.system(size: 56))
                    .foregroundStyle(CosmicTheme.goldGradient)
                    .offset(y: floatAnimation ? -5 : 5)
                    .animation(
                        .easeInOut(duration: 3.0)
                        .repeatForever(autoreverses: true),
                        value: floatAnimation
                    )
            }
            .frame(height: 120)

            // Text content
            VStack(spacing: 8) {
                Text(title)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(CosmicTheme.textPrimary)
                    .multilineTextAlignment(.center)

                Text(message)
                    .font(.subheadline)
                    .foregroundColor(CosmicTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            .padding(.horizontal, 20)

            // Action button
            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(.headline)
                        .foregroundColor(CosmicTheme.background)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 14)
                        .background(
                            Capsule()
                                .fill(CosmicTheme.gold)
                        )
                }
                .padding(.top, 8)
            }
        }
        .padding(32)
        .onAppear {
            floatAnimation = true
        }
    }
}

// MARK: - Offline Indicator
// =========================
// A compact offline mode indicator

struct OfflineIndicator: View {
    @State private var pulse: Bool = false

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(Color.orange)
                .frame(width: 8, height: 8)
                .scaleEffect(pulse ? 1.2 : 1.0)
                .animation(
                    .easeInOut(duration: 1.0)
                    .repeatForever(autoreverses: true),
                    value: pulse
                )

            Text("Offline Mode")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(CosmicTheme.textSecondary)

            Image(systemName: "wifi.slash")
                .font(.caption)
                .foregroundColor(.orange)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(CosmicTheme.cardBackground)
                .overlay(
                    Capsule()
                        .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                )
        )
        .onAppear {
            pulse = true
        }
    }
}

// MARK: - Loading State View
// ==========================

struct CosmicLoadingView: View {
    let message: String

    @State private var rotation: Double = 0

    init(message: String = "Consulting the stars...") {
        self.message = message
    }

    var body: some View {
        VStack(spacing: 24) {
            // Animated loader
            ZStack {
                // Outer ring
                Circle()
                    .stroke(CosmicTheme.gold.opacity(0.2), lineWidth: 3)
                    .frame(width: 60, height: 60)

                // Animated arc
                Circle()
                    .trim(from: 0, to: 0.3)
                    .stroke(
                        CosmicTheme.goldGradient,
                        style: StrokeStyle(lineWidth: 3, lineCap: .round)
                    )
                    .frame(width: 60, height: 60)
                    .rotationEffect(.degrees(rotation))

                // Center star
                Image(systemName: "sparkle")
                    .font(.system(size: 20))
                    .foregroundColor(CosmicTheme.gold)
            }

            Text(message)
                .font(.subheadline)
                .foregroundColor(CosmicTheme.textSecondary)
        }
        .onAppear {
            withAnimation(.linear(duration: 1.0).repeatForever(autoreverses: false)) {
                rotation = 360
            }
        }
    }
}

// MARK: - Previews

#Preview("Error - Full Screen") {
    CosmicErrorView(
        error: .network(.noConnection),
        style: .fullScreen,
        onRetry: { try? await Task.sleep(nanoseconds: 1_000_000_000) },
        onDismiss: {}
    )
}

#Preview("Error - Card") {
    ZStack {
        CosmicTheme.background.ignoresSafeArea()
        CosmicErrorView(
            error: .network(.timeout),
            style: .card,
            onRetry: {},
            onDismiss: {}
        )
        .padding()
    }
}

#Preview("Error - Banner") {
    ZStack {
        CosmicTheme.background.ignoresSafeArea()
        VStack {
            CosmicErrorView(
                error: .network(.rateLimited),
                style: .banner,
                onRetry: {},
                onDismiss: {}
            )
            .padding()
            Spacer()
        }
    }
}

#Preview("Empty State") {
    ZStack {
        CosmicTheme.background.ignoresSafeArea()
        CosmicEmptyStateView(
            title: "Your Watchlist is Empty",
            message: "Swipe right on stocks in Discover to add them to your watchlist.",
            icon: "heart",
            actionTitle: "Start Discovering",
            action: {}
        )
    }
}

#Preview("Loading") {
    ZStack {
        CosmicTheme.background.ignoresSafeArea()
        CosmicLoadingView()
    }
}
