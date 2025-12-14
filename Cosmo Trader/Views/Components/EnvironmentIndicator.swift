//
//  EnvironmentIndicator.swift
//  Cosmo Trader
//
//  Visual indicator showing current app environment.
//  Only visible in development and staging builds.
//
//  USAGE:
//  ------
//  Add to any view with:
//    .environmentIndicator()
//
//  Or use directly:
//    EnvironmentBadge()

import SwiftUI

// MARK: - Environment Badge

/// Compact badge showing current environment
/// Only renders in non-production builds
struct EnvironmentBadge: View {

    private let environment = AppEnvironment.current

    var body: some View {
        if environment != .production {
            badge
        }
    }

    private var badge: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(badgeColor)
                .frame(width: 6, height: 6)

            Text(environment.badgeLabel)
                .font(TerminalFont.data(9, weight: .bold))
                .foregroundColor(badgeColor)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(badgeColor.opacity(0.15))
                .overlay(
                    Capsule()
                        .stroke(badgeColor.opacity(0.3), lineWidth: 0.5)
                )
        )
    }

    private var badgeColor: Color {
        switch environment {
        case .development:
            return CosmicTheme.gold
        case .staging:
            return Color.orange
        case .production:
            return CosmicTheme.positive
        }
    }
}

// MARK: - Environment Overlay

/// Full-screen overlay that shows environment in corner
struct EnvironmentOverlay: View {

    private let environment = AppEnvironment.current

    /// Position of the indicator
    var position: IndicatorPosition = .topTrailing

    var body: some View {
        if environment != .production {
            GeometryReader { geometry in
                badge
                    .position(badgePosition(in: geometry))
            }
        }
    }

    private var badge: some View {
        VStack(alignment: .trailing, spacing: 2) {
            EnvironmentBadge()

            if environment == .development {
                Text("Debug Mode")
                    .font(TerminalFont.data(8))
                    .foregroundColor(CosmicTheme.textMuted)
            }
        }
        .padding(8)
    }

    private func badgePosition(in geometry: GeometryProxy) -> CGPoint {
        let padding: CGFloat = 60

        switch position {
        case .topLeading:
            return CGPoint(x: padding, y: padding)
        case .topTrailing:
            return CGPoint(x: geometry.size.width - padding, y: padding)
        case .bottomLeading:
            return CGPoint(x: padding, y: geometry.size.height - padding)
        case .bottomTrailing:
            return CGPoint(x: geometry.size.width - padding, y: geometry.size.height - padding)
        }
    }

    enum IndicatorPosition {
        case topLeading
        case topTrailing
        case bottomLeading
        case bottomTrailing
    }
}

// MARK: - Ribbon Style

/// Diagonal ribbon indicator in corner
struct EnvironmentRibbon: View {

    private let environment = AppEnvironment.current

    var body: some View {
        if environment != .production {
            ribbon
        }
    }

    private var ribbon: some View {
        GeometryReader { _ in
            ZStack {
                // Ribbon background
                Rectangle()
                    .fill(ribbonColor)
                    .frame(width: 120, height: 24)
                    .rotationEffect(.degrees(45))
                    .offset(x: 30, y: -30)

                // Label
                Text(environment.badgeLabel)
                    .font(TerminalFont.data(10, weight: .bold))
                    .foregroundColor(.black)
                    .rotationEffect(.degrees(45))
                    .offset(x: 30, y: -30)
            }
            .frame(width: 80, height: 80)
            .clipped()
        }
        .frame(width: 80, height: 80)
    }

    private var ribbonColor: Color {
        switch environment {
        case .development:
            return CosmicTheme.gold
        case .staging:
            return Color.orange
        case .production:
            return CosmicTheme.positive
        }
    }
}

// MARK: - View Modifier

/// Adds environment indicator to any view
struct EnvironmentIndicatorModifier: ViewModifier {

    var style: IndicatorStyle = .badge
    var position: EnvironmentOverlay.IndicatorPosition = .topTrailing

    func body(content: Content) -> some View {
        content
            .overlay(alignment: overlayAlignment) {
                switch style {
                case .badge:
                    EnvironmentBadge()
                        .padding(8)
                case .overlay:
                    EnvironmentOverlay(position: position)
                case .ribbon:
                    EnvironmentRibbon()
                }
            }
    }

    private var overlayAlignment: Alignment {
        switch position {
        case .topLeading: return .topLeading
        case .topTrailing: return .topTrailing
        case .bottomLeading: return .bottomLeading
        case .bottomTrailing: return .bottomTrailing
        }
    }

    enum IndicatorStyle {
        case badge
        case overlay
        case ribbon
    }
}

// MARK: - View Extension

extension View {

    /// Adds environment indicator badge
    func environmentIndicator() -> some View {
        modifier(EnvironmentIndicatorModifier())
    }

    /// Adds environment indicator with custom style
    func environmentIndicator(
        style: EnvironmentIndicatorModifier.IndicatorStyle,
        position: EnvironmentOverlay.IndicatorPosition = .topTrailing
    ) -> some View {
        modifier(EnvironmentIndicatorModifier(style: style, position: position))
    }
}

// MARK: - AppEnvironment Badge Extension

extension AppEnvironment {

    /// Short label for badge display
    var badgeLabel: String {
        switch self {
        case .development:
            return "DEV"
        case .staging:
            return "STG"
        case .production:
            return "PROD"
        }
    }

    /// Full label for detailed display
    var fullLabel: String {
        switch self {
        case .development:
            return "Development"
        case .staging:
            return "Staging"
        case .production:
            return "Production"
        }
    }
}

// MARK: - Preview

#Preview("Environment Indicators") {
    ScrollView {
        VStack(spacing: 32) {
            Text("ENVIRONMENT INDICATORS")
                .font(TerminalFont.headline(16))
                .foregroundColor(CosmicTheme.textPrimary)

            // Badge style
            VStack(spacing: 8) {
                Text("Badge Style")
                    .font(TerminalFont.data(12))
                    .foregroundColor(CosmicTheme.textSecondary)

                EnvironmentBadge()
            }

            Divider().background(CosmicTheme.border)

            // Overlay on content
            VStack(spacing: 8) {
                Text("Overlay Style")
                    .font(TerminalFont.data(12))
                    .foregroundColor(CosmicTheme.textSecondary)

                RoundedRectangle(cornerRadius: 8)
                    .fill(CosmicTheme.cardBackground)
                    .frame(height: 150)
                    .overlay(
                        Text("App Content")
                            .foregroundColor(CosmicTheme.textMuted)
                    )
                    .environmentIndicator()
            }

            Divider().background(CosmicTheme.border)

            // Ribbon style
            VStack(spacing: 8) {
                Text("Ribbon Style")
                    .font(TerminalFont.data(12))
                    .foregroundColor(CosmicTheme.textSecondary)

                ZStack(alignment: .topTrailing) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(CosmicTheme.cardBackground)
                        .frame(height: 150)
                        .overlay(
                            Text("App Content")
                                .foregroundColor(CosmicTheme.textMuted)
                        )

                    EnvironmentRibbon()
                }
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            Spacer().frame(height: 50)
        }
        .padding()
    }
    .background(CosmicTheme.background)
}
