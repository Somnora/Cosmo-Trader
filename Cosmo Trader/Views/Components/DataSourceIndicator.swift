import SwiftUI

struct DataSourceIndicator: View {
    var source: DataSourceState?
    var provenance: FinancialDataProvenance?
    var size: DataSourceIndicatorSize = .regular

    @State private var monitor = DataSourceMonitor.shared

    private var resolvedLabel: String {
        provenance?.indicatorLabel ?? (source ?? monitor.currentSource).label
    }

    private var resolvedAccessibilityLabel: String {
        provenance?.accessibilityLabel ?? (source ?? monitor.currentSource).accessibilityLabel
    }

    private var resolvedColor: Color {
        provenance?.color ?? (source ?? monitor.currentSource).color
    }

    var body: some View {
        HStack(spacing: size.spacing) {
            Circle()
                .fill(resolvedColor)
                .frame(width: size.dotSize, height: size.dotSize)

            Text(resolvedLabel)
                .font(TerminalFont.data(size.fontSize, weight: .semibold))
                .foregroundColor(resolvedColor)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .padding(.horizontal, size.horizontalPadding)
        .padding(.vertical, size.verticalPadding)
        .background(
            Capsule()
                .fill(resolvedColor.opacity(0.12))
                .overlay(
                    Capsule()
                        .stroke(resolvedColor.opacity(0.28), lineWidth: 0.5)
                )
        )
        .accessibilityLabel(resolvedAccessibilityLabel)
        .onAppear {
            monitor.refreshConfiguration()
        }
    }
}

enum DataSourceIndicatorSize {
    case compact
    case regular

    var dotSize: CGFloat {
        switch self {
        case .compact: return 5
        case .regular: return 6
        }
    }

    var fontSize: CGFloat {
        switch self {
        case .compact: return 8
        case .regular: return 9
        }
    }

    var spacing: CGFloat {
        switch self {
        case .compact: return 4
        case .regular: return 5
        }
    }

    var horizontalPadding: CGFloat {
        switch self {
        case .compact: return 7
        case .regular: return 8
        }
    }

    var verticalPadding: CGFloat {
        switch self {
        case .compact: return 3
        case .regular: return 4
        }
    }
}

private extension DataSourceState {
    var label: String {
        switch self {
        case .live:
            return "Live data"
        case .cached:
            return "Cached data"
        case .sample:
            return "Sample data"
        case .offline:
            return "Offline"
        }
    }

    var accessibilityLabel: String {
        switch self {
        case .live:
            return "Live market data"
        case .cached(let lastUpdated):
            return "Cached market data from \(Self.ageDescription(since: lastUpdated))"
        case .sample:
            return "Sample market data"
        case .offline:
            return "Offline market data"
        }
    }

    var color: Color {
        switch self {
        case .live:
            return CosmicTheme.positive
        case .cached:
            return CosmicTheme.gold
        case .sample:
            return CosmicTheme.textMuted
        case .offline:
            return CosmicTheme.negative
        }
    }

    private static func ageDescription(since date: Date) -> String {
        let seconds = max(0, Int(Date().timeIntervalSince(date)))
        if seconds < 60 { return "less than one minute ago" }

        let minutes = seconds / 60
        if minutes == 1 { return "one minute ago" }
        if minutes < 60 { return "\(minutes) minutes ago" }

        let hours = minutes / 60
        if hours == 1 { return "one hour ago" }
        return "\(hours) hours ago"
    }
}

extension FinancialDataProvenance {
    var indicatorLabel: String {
        switch self {
        case .live(let provider, _):
            return "\(provider) live"
        case .cached(let provider, _, _):
            return isCachedStale() ? "\(provider) stale" : "\(provider) cached"
        case .mixed(let reason):
            if reason.localizedCaseInsensitiveContains("partial historical dataset") {
                return "Partial history"
            }
            if reason.localizedCaseInsensitiveContains("insufficient historical dataset") {
                return "Insufficient history"
            }
            return "Mixed data"
        case .unavailable:
            return "Unavailable"
        case .sample(let reason):
            if reason.localizedCaseInsensitiveContains("stored") {
                return "Stored data"
            }
            return "Sample data"
        }
    }

    var shortLabel: String {
        switch self {
        case .live:
            return "Live"
        case .cached:
            return isCachedStale() ? "Stale" : "Cached"
        case .mixed(let reason):
            if reason.localizedCaseInsensitiveContains("partial historical dataset") {
                return "Partial"
            }
            if reason.localizedCaseInsensitiveContains("insufficient historical dataset") {
                return "Insufficient"
            }
            return "Mixed"
        case .unavailable:
            return "N/A"
        case .sample(let reason):
            if reason.localizedCaseInsensitiveContains("stored") {
                return "Stored"
            }
            return "Sample"
        }
    }

    var accessibilityLabel: String {
        switch self {
        case .live(let provider, let fetchedAt):
            return "Live \(provider) data from \(Self.ageDescription(since: fetchedAt))"
        case .cached(let provider, let fetchedAt, _):
            let prefix = isCachedStale() ? "Stale cached" : "Cached"
            return "\(prefix) \(provider) data from \(Self.ageDescription(since: fetchedAt))"
        case .mixed(let reason):
            return "Mixed financial data. \(reason)"
        case .unavailable(let reason):
            return "Financial data unavailable. \(reason)"
        case .sample(let reason):
            return "Explicit sample or stored financial data. \(reason)"
        }
    }

    var color: Color {
        switch self {
        case .live:
            return CosmicTheme.positive
        case .cached:
            return isCachedStale() ? CosmicTheme.negative : CosmicTheme.gold
        case .mixed(let reason):
            if reason.localizedCaseInsensitiveContains("partial historical dataset")
                || reason.localizedCaseInsensitiveContains("insufficient historical dataset") {
                return CosmicTheme.textMuted
            }
            return CosmicTheme.gold
        case .unavailable:
            return CosmicTheme.textMuted
        case .sample:
            return CosmicTheme.textMuted
        }
    }

    var detailText: String {
        switch self {
        case .live(let provider, let fetchedAt):
            return "\(provider) live • \(Self.compactAgeDescription(since: fetchedAt))"
        case .cached(let provider, let fetchedAt, _):
            let label = isCachedStale() ? "stale cache" : "cached"
            return "\(provider) \(label) • \(Self.compactAgeDescription(since: fetchedAt))"
        case .mixed(let reason):
            return reason
        case .unavailable(let reason):
            return reason
        case .sample(let reason):
            return reason
        }
    }

    private static func ageDescription(since date: Date) -> String {
        let seconds = max(0, Int(Date().timeIntervalSince(date)))
        if seconds < 60 { return "less than one minute ago" }

        let minutes = seconds / 60
        if minutes == 1 { return "one minute ago" }
        if minutes < 60 { return "\(minutes) minutes ago" }

        let hours = minutes / 60
        if hours == 1 { return "one hour ago" }
        if hours < 24 { return "\(hours) hours ago" }

        let days = hours / 24
        if days == 1 { return "one day ago" }
        return "\(days) days ago"
    }

    private static func compactAgeDescription(since date: Date) -> String {
        let seconds = max(0, Int(Date().timeIntervalSince(date)))
        if seconds < 60 { return "just now" }
        let minutes = seconds / 60
        if minutes < 60 { return "\(minutes)m ago" }
        let hours = minutes / 60
        if hours < 24 { return "\(hours)h ago" }
        return "\(hours / 24)d ago"
    }
}
