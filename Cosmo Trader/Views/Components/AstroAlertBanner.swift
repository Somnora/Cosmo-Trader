import SwiftUI

// MARK: - AstroAlertBanner
// ========================
// A dismissible banner component for important cosmic events.
//
// Shows warnings like "Mercury Retrograde Active" with witty advice.
// Can appear at the top of views when significant events are occurring.
//
// Design: Attention-grabbing but not intrusive, cosmic styling

struct AstroAlertBanner: View {

    // MARK: - Properties

    let event: CosmicEvent
    let onDismiss: () -> Void

    @State private var isExpanded: Bool = false
    @State private var pulseAnimation: Bool = false

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // Main banner content
            Button(action: { withAnimation(.spring(response: 0.3)) { isExpanded.toggle() } }) {
                HStack(spacing: 12) {
                    // Event icon with glow
                    ZStack {
                        Circle()
                            .fill(event.themeColor.opacity(0.3))
                            .frame(width: 40, height: 40)
                            .scaleEffect(pulseAnimation ? event.intensity.pulseScale : 1.0)

                        Image(systemName: event.icon)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(event.themeColor)
                    }

                    // Text content
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Text(event.title)
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .foregroundColor(CosmicTheme.textPrimary)

                            // Intensity indicator
                            if event.intensity == .intense {
                                Text("INTENSE")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(
                                        Capsule()
                                            .fill(Color.red)
                                    )
                            }
                        }

                        Text(event.warningMessage ?? event.subtitle)
                            .font(.caption)
                            .foregroundColor(CosmicTheme.textSecondary)
                            .lineLimit(isExpanded ? nil : 1)
                    }

                    Spacer()

                    // Expand/collapse indicator
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(CosmicTheme.textMuted)

                    // Dismiss button
                    Button(action: onDismiss) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(CosmicTheme.textMuted)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .buttonStyle(.plain)

            // Expanded content
            if isExpanded {
                expandedContent
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(CosmicTheme.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(event.themeColor.opacity(0.4), lineWidth: 1)
                )
                .shadow(color: event.themeColor.opacity(0.2), radius: event.intensity.glowRadius, x: 0, y: 2)
        )
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                pulseAnimation = true
            }
        }
    }

    // MARK: - Expanded Content

    private var expandedContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            Divider()
                .background(CosmicTheme.textMuted.opacity(0.3))

            // Advice section
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: "lightbulb.fill")
                        .font(.caption)
                        .foregroundColor(CosmicTheme.gold)
                    Text("Cosmic Advice")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(CosmicTheme.gold)
                }

                Text(event.advice)
                    .font(.caption)
                    .foregroundColor(CosmicTheme.textSecondary)
                    .lineSpacing(4)
            }

            // Affected areas
            HStack(spacing: 16) {
                // Elements
                if !event.affectedElements.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Affected Elements")
                            .font(.caption2)
                            .foregroundColor(CosmicTheme.textMuted)

                        HStack(spacing: 6) {
                            ForEach(event.affectedElements, id: \.self) { element in
                                Text(element.emoji)
                                    .font(.caption)
                            }
                        }
                    }
                }

                // Sectors
                if !event.affectedSectors.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Affected Sectors")
                            .font(.caption2)
                            .foregroundColor(CosmicTheme.textMuted)

                        Text(event.affectedSectors.prefix(3).map { $0.rawValue }.joined(separator: ", "))
                            .font(.caption)
                            .foregroundColor(CosmicTheme.textSecondary)
                    }
                }
            }

            // Duration
            HStack {
                Image(systemName: "calendar")
                    .font(.caption)
                    .foregroundColor(CosmicTheme.textMuted)

                Text(event.dateRangeFormatted)
                    .font(.caption)
                    .foregroundColor(CosmicTheme.textSecondary)

                Text("·")
                    .foregroundColor(CosmicTheme.textMuted)

                Text(event.statusText)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(event.themeColor)
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 14)
    }
}

// MARK: - Compact Alert Banner

/// A smaller, single-line alert banner for less intrusive warnings
struct CompactAstroAlert: View {
    let event: CosmicEvent
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 8) {
                Image(systemName: event.icon)
                    .font(.caption)
                    .foregroundColor(event.themeColor)

                Text(event.title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(CosmicTheme.textPrimary)

                if let warning = event.warningMessage {
                    Text("·")
                        .foregroundColor(CosmicTheme.textMuted)
                    Text(warning)
                        .font(.caption)
                        .foregroundColor(CosmicTheme.textSecondary)
                        .lineLimit(1)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundColor(CosmicTheme.textMuted)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(event.themeColor.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(event.themeColor.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Cosmic Event Card

/// A larger card for displaying cosmic events in lists
struct CosmicEventCard: View {
    let event: CosmicEvent
    let isExpanded: Bool
    let onTap: () -> Void

    @State private var glowAnimation: Bool = false

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack(spacing: 12) {
                    // Icon
                    ZStack {
                        Circle()
                            .fill(event.themeColor.opacity(0.2))
                            .frame(width: 50, height: 50)
                            .shadow(color: event.themeColor.opacity(glowAnimation ? 0.5 : 0.2), radius: event.intensity.glowRadius)

                        Image(systemName: event.icon)
                            .font(.system(size: 22))
                            .foregroundColor(event.themeColor)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(event.title)
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(CosmicTheme.textPrimary)

                            if event.isActive {
                                Text("ACTIVE")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(
                                        Capsule()
                                            .fill(event.themeColor)
                                    )
                            }
                        }

                        Text(event.subtitle)
                            .font(.subheadline)
                            .foregroundColor(event.themeColor)
                    }

                    Spacer()

                    // Status
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(event.statusText)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(event.isActive ? event.themeColor : CosmicTheme.textSecondary)

                        // Intensity dots
                        HStack(spacing: 3) {
                            ForEach(0..<3, id: \.self) { i in
                                Circle()
                                    .fill(i < intensityLevel ? event.themeColor : CosmicTheme.textMuted.opacity(0.3))
                                    .frame(width: 6, height: 6)
                            }
                        }
                    }
                }

                // Expanded details
                if isExpanded {
                    VStack(alignment: .leading, spacing: 12) {
                        Divider()
                            .background(CosmicTheme.textMuted.opacity(0.3))

                        Text(event.description)
                            .font(.subheadline)
                            .foregroundColor(CosmicTheme.textSecondary)
                            .lineSpacing(4)

                        // Warning message if present
                        if let warning = event.warningMessage {
                            HStack(spacing: 8) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.orange)
                                Text(warning)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.orange)
                            }
                            .padding(10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.orange.opacity(0.1))
                            )
                        }

                        // Advice
                        VStack(alignment: .leading, spacing: 6) {
                            HStack(spacing: 6) {
                                Image(systemName: "sparkles")
                                    .font(.caption)
                                    .foregroundColor(CosmicTheme.gold)
                                Text("Trading Advice")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(CosmicTheme.gold)
                            }

                            Text(event.advice)
                                .font(.caption)
                                .foregroundColor(CosmicTheme.textPrimary)
                                .lineSpacing(4)
                        }
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(CosmicTheme.gold.opacity(0.1))
                        )

                        // Tags
                        HStack(spacing: 8) {
                            // Date range
                            Label(event.dateRangeFormatted, systemImage: "calendar")
                                .font(.caption2)
                                .foregroundColor(CosmicTheme.textMuted)

                            Spacer()

                            // Elements
                            ForEach(event.affectedElements, id: \.self) { element in
                                Text(element.emoji)
                                    .font(.caption)
                            }
                        }
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(CosmicTheme.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                event.isActive ? event.themeColor.opacity(0.4) : CosmicTheme.textMuted.opacity(0.2),
                                lineWidth: event.isActive ? 2 : 1
                            )
                    )
                    .shadow(
                        color: event.isActive ? event.themeColor.opacity(0.2) : Color.clear,
                        radius: event.intensity.glowRadius
                    )
            )
        }
        .buttonStyle(.plain)
        .onAppear {
            if event.isActive {
                withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                    glowAnimation = true
                }
            }
        }
    }

    private var intensityLevel: Int {
        switch event.intensity {
        case .mild: return 1
        case .moderate: return 2
        case .intense: return 3
        }
    }
}

// MARK: - Upcoming Event Row

/// Compact row for upcoming events in a list
struct UpcomingEventRow: View {
    let event: CosmicEvent

    var body: some View {
        HStack(spacing: 12) {
            // Date badge
            VStack(spacing: 2) {
                Text(dayOfMonth)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(CosmicTheme.textPrimary)

                Text(monthAbbrev)
                    .font(.caption2)
                    .foregroundColor(CosmicTheme.textMuted)
            }
            .frame(width: 40)

            // Event icon
            Image(systemName: event.icon)
                .font(.system(size: 16))
                .foregroundColor(event.themeColor)
                .frame(width: 30)

            // Event info
            VStack(alignment: .leading, spacing: 2) {
                Text(event.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(CosmicTheme.textPrimary)

                Text(event.subtitle)
                    .font(.caption)
                    .foregroundColor(event.themeColor)
            }

            Spacer()

            // Intensity indicator
            HStack(spacing: 2) {
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .fill(i < intensityLevel ? event.themeColor : CosmicTheme.textMuted.opacity(0.3))
                        .frame(width: 5, height: 5)
                }
            }
        }
        .padding(.vertical, 8)
    }

    private var dayOfMonth: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: event.startDate)
    }

    private var monthAbbrev: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        return formatter.string(from: event.startDate)
    }

    private var intensityLevel: Int {
        switch event.intensity {
        case .mild: return 1
        case .moderate: return 2
        case .intense: return 3
        }
    }
}

// MARK: - Preview

#Preview("Alert Banner - Mercury Retrograde") {
    VStack {
        AstroAlertBanner(
            event: MockCosmicEvents.all[0],
            onDismiss: {}
        )
        .padding()
    }
    .background(CosmicTheme.background)
}

#Preview("Compact Alert") {
    VStack {
        CompactAstroAlert(
            event: MockCosmicEvents.all[0],
            onTap: {}
        )
        .padding()
    }
    .background(CosmicTheme.background)
}

#Preview("Event Card - Expanded") {
    ScrollView {
        VStack(spacing: 16) {
            CosmicEventCard(
                event: MockCosmicEvents.all[0],
                isExpanded: true,
                onTap: {}
            )

            CosmicEventCard(
                event: MockCosmicEvents.all[1],
                isExpanded: false,
                onTap: {}
            )
        }
        .padding()
    }
    .background(CosmicTheme.background)
}
