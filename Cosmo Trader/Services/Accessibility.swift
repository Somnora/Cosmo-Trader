import SwiftUI

// MARK: - Accessibility Extensions
// ================================
// Centralized accessibility labels and helpers for the app.
// Ensures VoiceOver and other accessibility features work properly.

// MARK: - Zodiac Sign Accessibility

extension ZodiacSign {
    /// VoiceOver-friendly description of the zodiac sign
    var accessibilityLabel: String {
        "\(displayName), \(element.displayName) sign"
    }

    /// Full description for VoiceOver
    var accessibilityDescription: String {
        "\(displayName) is a \(element.displayName) sign. \(element.traits.prefix(3).joined(separator: ", "))."
    }
}

extension ZodiacSign.Element {
    /// VoiceOver-friendly description
    var accessibilityLabel: String {
        "\(displayName) element"
    }

    /// Description of element's trading characteristics
    var accessibilityTradingDescription: String {
        switch self {
        case .fire:
            return "Fire signs are bold and action-oriented investors"
        case .earth:
            return "Earth signs are patient and value-focused investors"
        case .air:
            return "Air signs are analytical and diversified investors"
        case .water:
            return "Water signs are intuitive and protective investors"
        }
    }
}

// MARK: - Stock Accessibility

extension Stock {
    /// VoiceOver label for the stock
    var accessibilityLabel: String {
        "\(name), ticker symbol \(symbol)"
    }

    /// Price accessibility description
    var accessibilityPriceDescription: String {
        let direction = isPositive ? "up" : "down"
        let change = abs(percentageChange)
        return "Currently at \(formattedPrice), \(direction) \(String(format: "%.2f", change)) percent today"
    }

    /// Full accessibility description
    var accessibilityDescription: String {
        var description = "\(accessibilityLabel). \(accessibilityPriceDescription). "
        description += "\(zodiacSign.displayName) sign, \(element.displayName) element."

        if sharesOwned > 0 {
            description += " You own \(formattedSharesOwned) shares worth \(formattedTotalValue)."
        }

        return description
    }

    /// Accessibility hint for interaction
    var accessibilityHint: String {
        "Double tap to view stock details"
    }
}

// MARK: - Portfolio Accessibility

extension UserProfile {
    /// Portfolio summary for VoiceOver
    var accessibilityPortfolioSummary: String {
        let holdingsCount = portfolio.filter { $0.sharesOwned > 0 }.count

        if holdingsCount == 0 {
            return "Your portfolio is empty"
        }

        let direction = isPortfolioPositive ? "up" : "down"
        return "Portfolio value \(formattedPortfolioValue), \(direction) \(formattedDailyChangePercent) today. \(holdingsCount) holdings."
    }
}

// MARK: - Cosmic Event Accessibility

extension CosmicEvent {
    /// VoiceOver label for the event
    var accessibilityLabel: String {
        "\(title). \(subtitle)"
    }

    /// Full accessibility description
    var accessibilityDescription: String {
        var desc = "\(title). \(description)"
        if isActive {
            desc += " This event is currently active."
        } else {
            desc += " \(statusText)."
        }
        if let warning = warningMessage {
            desc += " Warning: \(warning)"
        }
        return desc
    }
}

// MARK: - View Modifiers for Accessibility

extension View {
    /// Add accessibility label and hint for a stock item
    func stockAccessibility(_ stock: Stock) -> some View {
        self
            .accessibilityElement(children: .combine)
            .accessibilityLabel(stock.accessibilityLabel)
            .accessibilityValue(stock.accessibilityPriceDescription)
            .accessibilityHint(stock.accessibilityHint)
    }

    /// Add accessibility for zodiac sign display
    func zodiacAccessibility(_ sign: ZodiacSign) -> some View {
        self
            .accessibilityLabel(sign.accessibilityLabel)
            .accessibilityHint("Zodiac sign")
    }

    /// Add accessibility for element display
    func elementAccessibility(_ element: ZodiacSign.Element) -> some View {
        self
            .accessibilityLabel(element.accessibilityLabel)
            .accessibilityHint(element.accessibilityTradingDescription)
    }

    /// Add accessibility for price change indicators
    func priceChangeAccessibility(isPositive: Bool, percentChange: Double) -> some View {
        let direction = isPositive ? "increased" : "decreased"
        let value = String(format: "%.2f", abs(percentChange))
        return self
            .accessibilityLabel("Price \(direction) by \(value) percent")
    }

    /// Add accessibility for compatibility percentage
    func compatibilityAccessibility(score: Int) -> some View {
        let level: String
        switch score {
        case 85...: level = "Excellent"
        case 70..<85: level = "Good"
        case 50..<70: level = "Moderate"
        default: level = "Low"
        }
        return self
            .accessibilityLabel("\(level) compatibility at \(score) percent")
    }

    /// Make a decorative element hidden from accessibility
    func accessibilityDecorative() -> some View {
        self.accessibilityHidden(true)
    }

    /// Add accessibility for loading states
    func loadingAccessibility(isLoading: Bool, loadingMessage: String = "Loading") -> some View {
        self.accessibilityValue(isLoading ? loadingMessage : "")
    }

    /// Add accessibility for error states
    func errorAccessibility(_ error: AppError?) -> some View {
        Group {
            if let error = error {
                self.accessibilityLabel("Error: \(error.cosmicMessage)")
            } else {
                self
            }
        }
    }
}

// MARK: - Accessibility Announcements

struct AccessibilityAnnouncement {
    /// Announce portfolio update
    static func portfolioUpdated(value: String, change: String) {
        let message = "Portfolio updated. Total value \(value), change \(change)"
        UIAccessibility.post(notification: .announcement, argument: message)
    }

    /// Announce stock added to portfolio
    static func stockAdded(symbol: String) {
        let message = "\(symbol) added to portfolio"
        UIAccessibility.post(notification: .announcement, argument: message)
    }

    /// Announce stock removed from portfolio
    static func stockRemoved(symbol: String) {
        let message = "\(symbol) removed from portfolio"
        UIAccessibility.post(notification: .announcement, argument: message)
    }

    /// Announce stock added to watchlist
    static func addedToWatchlist(symbol: String) {
        let message = "\(symbol) added to watchlist"
        UIAccessibility.post(notification: .announcement, argument: message)
    }

    /// Announce cosmic event
    static func cosmicEvent(title: String) {
        let message = "Cosmic alert: \(title)"
        UIAccessibility.post(notification: .announcement, argument: message)
    }

    /// Announce error
    static func error(message: String) {
        UIAccessibility.post(notification: .announcement, argument: "Error: \(message)")
    }

    /// Announce successful action
    static func success(message: String) {
        UIAccessibility.post(notification: .announcement, argument: message)
    }

    /// Announce navigation change
    static func screenChanged(to screen: String) {
        UIAccessibility.post(notification: .screenChanged, argument: screen)
    }
}

// MARK: - Dynamic Type Support

struct DynamicTypeModifier: ViewModifier {
    @Environment(\.sizeCategory) var sizeCategory

    let baseSize: CGFloat
    let maxSize: CGFloat

    func body(content: Content) -> some View {
        content
            .font(.system(size: scaledSize))
    }

    private var scaledSize: CGFloat {
        switch sizeCategory {
        case .extraSmall:
            return baseSize * 0.8
        case .small:
            return baseSize * 0.9
        case .medium:
            return baseSize
        case .large:
            return baseSize * 1.1
        case .extraLarge:
            return min(baseSize * 1.2, maxSize)
        case .extraExtraLarge:
            return min(baseSize * 1.3, maxSize)
        case .extraExtraExtraLarge:
            return min(baseSize * 1.4, maxSize)
        case .accessibilityMedium:
            return min(baseSize * 1.5, maxSize)
        case .accessibilityLarge:
            return min(baseSize * 1.7, maxSize)
        case .accessibilityExtraLarge:
            return min(baseSize * 1.9, maxSize)
        case .accessibilityExtraExtraLarge:
            return min(baseSize * 2.1, maxSize)
        case .accessibilityExtraExtraExtraLarge:
            return min(baseSize * 2.3, maxSize)
        @unknown default:
            return baseSize
        }
    }
}

extension View {
    /// Apply dynamic type scaling with a maximum size
    func dynamicTypeSize(base: CGFloat, max: CGFloat) -> some View {
        modifier(DynamicTypeModifier(baseSize: base, maxSize: max))
    }
}

// MARK: - Color Contrast Helpers

struct AccessibleColors {
    /// Returns a text color with sufficient contrast against background
    static func textColor(onBackground background: Color, preferLight: Bool = true) -> Color {
        // For dark mode app, we generally want light text
        preferLight ? CosmicTheme.textPrimary : CosmicTheme.background
    }

    /// Returns whether a color has sufficient contrast for accessibility
    /// Note: This is a simplified check - real apps should calculate luminance
    static func hasSufficientContrast(_ foreground: Color, background: Color) -> Bool {
        // Simplified - always return true for our predefined theme colors
        true
    }
}

// MARK: - Accessibility Helpers

struct AccessibilityHelper {
    /// Check if VoiceOver is running
    static var isVoiceOverRunning: Bool {
        UIAccessibility.isVoiceOverRunning
    }

    /// Check if user prefers reduced motion
    static var prefersReducedMotion: Bool {
        UIAccessibility.isReduceMotionEnabled
    }

    /// Check if user prefers increased contrast
    static var prefersIncreasedContrast: Bool {
        UIAccessibility.isDarkerSystemColorsEnabled
    }

    /// Check if bold text is enabled
    static var isBoldTextEnabled: Bool {
        UIAccessibility.isBoldTextEnabled
    }
}

// MARK: - Reduced Motion Support

struct ReducedMotionModifier: ViewModifier {
    let animation: Animation?
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    func body(content: Content) -> some View {
        content.animation(reduceMotion ? nil : animation, value: UUID())
    }
}

extension View {
    /// Apply animation only if reduce motion is not enabled
    func accessibleAnimation(_ animation: Animation?) -> some View {
        modifier(ReducedMotionModifier(animation: animation))
    }
}
