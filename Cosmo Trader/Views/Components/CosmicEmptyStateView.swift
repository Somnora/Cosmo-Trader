import SwiftUI
import UIKit

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

// MARK: - Haptic Feedback Utility
// ================================
// Centralized haptic feedback for consistent tactile responses

enum HapticFeedback {

    /// Light impact - for subtle interactions like skip
    static func light() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    /// Medium impact - for primary actions like like, save, star
    static func medium() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    /// Heavy impact - for significant actions
    static func heavy() {
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
    }

    /// Selection changed - for toggles, pickers
    static func selection() {
        UISelectionFeedbackGenerator().selectionChanged()
    }

    /// Success notification - for completed purchases, saves
    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    /// Warning notification - for cautionary feedback
    static func warning() {
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }

    /// Error notification - for errors, failures
    static func error() {
        UINotificationFeedbackGenerator().notificationOccurred(.error)
    }
}

// MARK: - Preset Empty States
// ===========================
// Factory methods for common empty states

extension CosmicEmptyStateView {

    /// Empty portfolio state
    static var emptyPortfolio: CosmicEmptyStateView {
        CosmicEmptyStateView(
            title: "Portfolio Setup",
            message: "Add your holdings to generate a daily financial astrology reading. Start with 3-5 tickers and refine later.",
            icon: "briefcase"
        )
    }

    /// Empty watchlist state
    static var emptyWatchlist: CosmicEmptyStateView {
        CosmicEmptyStateView(
            title: "No Watchlist Items",
            message: "No stocks in your watchlist yet. Star stocks from Discover to track them here.",
            icon: "star"
        )
    }

    /// No more discover cards
    static var noMoreCards: CosmicEmptyStateView {
        CosmicEmptyStateView(
            title: "All Caught Up",
            message: "You've seen all available stocks. Check back tomorrow for new candidates.",
            icon: "rectangle.stack"
        )
    }

    /// Empty search results
    static func emptySearch(query: String) -> CosmicEmptyStateView {
        CosmicEmptyStateView(
            title: "No Results",
            message: "No stocks match \"\(query)\". Try a different symbol or name.",
            icon: "magnifyingglass"
        )
    }

    /// No patterns detected
    static var noPatterns: CosmicEmptyStateView {
        CosmicEmptyStateView(
            title: "No Active Patterns",
            message: "No chart patterns detected today.",
            icon: "waveform.path.ecg"
        )
    }

    /// Empty karmic ledger
    static var emptyLedger: CosmicEmptyStateView {
        CosmicEmptyStateView(
            title: "Clean Slate",
            message: "Your karmic ledger is clean. Portfolio actions will appear here.",
            icon: "book.closed"
        )
    }

    /// Volume leaders unavailable
    static var volumeUnavailable: CosmicEmptyStateView {
        CosmicEmptyStateView(
            title: "Data Unavailable",
            message: "Market data temporarily unavailable. Please try again later.",
            icon: "chart.bar.xaxis"
        )
    }
}

// MARK: - Previews

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

