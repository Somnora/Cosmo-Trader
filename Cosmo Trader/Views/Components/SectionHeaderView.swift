import SwiftUI

/// SectionHeaderView
/// -----------------
/// Terminal-style section header with extending lines.
/// Uppercase, letterspaced text with thin horizontal lines.
///
/// Format: "──── PORTFOLIO HOLDINGS ────"
///
/// Design:
/// - Uppercase, letterspaced, small text
/// - Thin lines extending to edges
/// - Sharp corners, no decorations
/// - Multiple variants for different contexts

// MARK: - Section Header View

struct SectionHeaderView: View {

    /// Section title text
    let title: String

    /// Optional subtitle (right-aligned)
    var subtitle: String? = nil

    /// Text color
    var textColor: Color = CosmicTheme.textMuted

    /// Line color
    var lineColor: Color = CosmicTheme.border

    /// Font size
    var fontSize: CGFloat = 10

    /// Line dash pattern (nil for solid)
    var dashPattern: [CGFloat]? = nil

    var body: some View {
        HStack(spacing: 12) {
            // Left line
            lineSeparator

            // Title
            Text(title.uppercased())
                .font(TerminalFont.data(fontSize, weight: .medium))
                .foregroundColor(textColor)
                .tracking(1.5)
                .lineLimit(1)

            // Right line or subtitle
            if let subtitle = subtitle {
                Spacer(minLength: 8)

                Text(subtitle.uppercased())
                    .font(TerminalFont.data(fontSize - 1))
                    .foregroundColor(textColor.opacity(0.7))
                    .tracking(1)

                lineSeparator
                    .frame(maxWidth: 40)
            } else {
                lineSeparator
            }
        }
        .padding(.vertical, 8)
    }

    private var lineSeparator: some View {
        GeometryReader { geometry in
            Path { path in
                path.move(to: CGPoint(x: 0, y: geometry.size.height / 2))
                path.addLine(to: CGPoint(x: geometry.size.width, y: geometry.size.height / 2))
            }
            .stroke(
                lineColor,
                style: StrokeStyle(
                    lineWidth: 0.5,
                    dash: dashPattern ?? []
                )
            )
        }
        .frame(height: 1)
    }
}

// MARK: - Compact Section Header

/// Minimal section header with just text and optional count
struct CompactSectionHeader: View {

    let title: String
    var count: Int? = nil
    var textColor: Color = CosmicTheme.textMuted

    var body: some View {
        HStack(spacing: 8) {
            Text(title.uppercased())
                .font(TerminalFont.data(9, weight: .medium))
                .foregroundColor(textColor)
                .tracking(1.2)

            if let count = count {
                Text("(\(count))")
                    .font(TerminalFont.data(9))
                    .foregroundColor(textColor.opacity(0.6))
            }

            Spacer()
        }
        .padding(.vertical, 6)
    }
}

// MARK: - Terminal Section Header

/// Bold terminal-style header with optional action button
struct TerminalSectionHeader: View {

    let title: String
    var subtitle: String? = nil
    var action: (() -> Void)? = nil
    var actionLabel: String = "View All"

    var body: some View {
        HStack(spacing: 0) {
            // Left line segment
            Rectangle()
                .fill(CosmicTheme.border)
                .frame(width: 16, height: 0.5)

            // Title section
            HStack(spacing: 8) {
                Text(title.uppercased())
                    .font(TerminalFont.data(11, weight: .semibold))
                    .foregroundColor(CosmicTheme.textSecondary)
                    .tracking(1.5)

                if let subtitle = subtitle {
                    Text("·")
                        .foregroundColor(CosmicTheme.border)

                    Text(subtitle)
                        .font(TerminalFont.data(10))
                        .foregroundColor(CosmicTheme.textMuted)
                }
            }
            .padding(.horizontal, 12)

            // Center line
            Rectangle()
                .fill(CosmicTheme.border)
                .frame(height: 0.5)

            // Action button (optional)
            if let action = action {
                Button(action: action) {
                    Text(actionLabel.uppercased())
                        .font(TerminalFont.data(9, weight: .medium))
                        .foregroundColor(CosmicTheme.gold)
                        .tracking(0.5)
                }
                .padding(.horizontal, 12)

                Rectangle()
                    .fill(CosmicTheme.border)
                    .frame(width: 16, height: 0.5)
            }
        }
        .padding(.vertical, 10)
    }
}

// MARK: - Dashed Section Divider

/// Just a dashed line divider with optional centered label
struct DashedSectionDivider: View {

    var label: String? = nil
    var lineColor: Color = CosmicTheme.border

    var body: some View {
        HStack(spacing: 12) {
            dashedLine

            if let label = label {
                Text(label.uppercased())
                    .font(TerminalFont.data(8))
                    .foregroundColor(CosmicTheme.textMuted)
                    .tracking(1)

                dashedLine
            }
        }
        .frame(height: 1)
    }

    private var dashedLine: some View {
        GeometryReader { geometry in
            Path { path in
                path.move(to: CGPoint(x: 0, y: 0.5))
                path.addLine(to: CGPoint(x: geometry.size.width, y: 0.5))
            }
            .stroke(lineColor, style: StrokeStyle(lineWidth: 0.5, dash: [4, 4]))
        }
    }
}

// MARK: - Gold Accent Section Header

/// Section header with gold accent for premium sections
struct GoldSectionHeader: View {

    let title: String
    var icon: String? = nil

    var body: some View {
        HStack(spacing: 8) {
            // Gold accent bar
            Rectangle()
                .fill(CosmicTheme.gold)
                .frame(width: 3, height: 14)

            // Icon (optional)
            if let icon = icon {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(CosmicTheme.gold)
            }

            // Title
            Text(title.uppercased())
                .font(TerminalFont.data(11, weight: .semibold))
                .foregroundColor(CosmicTheme.textPrimary)
                .tracking(1.2)

            Spacer()

            // Decorative line
            Rectangle()
                .fill(CosmicTheme.border)
                .frame(height: 0.5)
                .frame(maxWidth: 60)
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Preview

#Preview("Section Headers") {
    ScrollView {
        VStack(spacing: 24) {
            Text("SECTION HEADERS")
                .font(TerminalFont.headline(16))
                .foregroundColor(CosmicTheme.textPrimary)

            // Standard
            VStack(spacing: 0) {
                SectionHeaderView(title: "Portfolio Holdings")

                Text("Content goes here...")
                    .font(TerminalFont.data(12))
                    .foregroundColor(CosmicTheme.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
            }
            .terminalCard()

            // With subtitle
            VStack(spacing: 0) {
                SectionHeaderView(title: "Recent Activity", subtitle: "Last 7 Days")

                Text("Activity content...")
                    .font(TerminalFont.data(12))
                    .foregroundColor(CosmicTheme.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
            }
            .terminalCard()

            // Dashed
            VStack(spacing: 0) {
                SectionHeaderView(
                    title: "Cosmic Events",
                    dashPattern: [4, 4]
                )

                Text("Events content...")
                    .font(TerminalFont.data(12))
                    .foregroundColor(CosmicTheme.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
            }
            .terminalCard()

            // Terminal style
            TerminalSectionHeader(
                title: "Holdings",
                subtitle: "8 Positions"
            )

            // With action
            TerminalSectionHeader(
                title: "Watchlist",
                action: { print("View all tapped") },
                actionLabel: "Edit"
            )

            // Compact
            CompactSectionHeader(title: "Market Overview", count: 12)
                .padding(.horizontal)

            // Gold accent
            GoldSectionHeader(title: "Premium Insights", icon: "star.fill")
                .padding(.horizontal)

            // Dashed divider
            VStack(spacing: 16) {
                Text("Section A")
                    .foregroundColor(CosmicTheme.textSecondary)

                DashedSectionDivider(label: "or")

                Text("Section B")
                    .foregroundColor(CosmicTheme.textSecondary)
            }
            .padding()
            .terminalCard()
        }
        .padding()
    }
    .background(CosmicTheme.background)
}
