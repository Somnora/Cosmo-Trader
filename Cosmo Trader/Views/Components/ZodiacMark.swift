import SwiftUI

/// ZodiacMark
/// ----------
/// Standardized zodiac mark wrapper for consistent sizing, color, and accessibility.
struct ZodiacMark: View {

    enum Size {
        case tiny
        case small
        case medium
        case large

        var pointSize: CGFloat {
            switch self {
            case .tiny: return 12
            case .small: return 16
            case .medium: return 24
            case .large: return 32
            }
        }
    }

    enum Style {
        case badge
        case element
    }

    let sign: ZodiacSign
    var size: Size = .small
    var style: Style = .badge
    var color: Color? = nil
    var strokeWidth: CGFloat? = nil
    private var customSize: CGFloat? = nil

    init(sign: ZodiacSign, size: Size = .small, style: Style = .badge, color: Color? = nil, strokeWidth: CGFloat? = nil) {
        self.sign = sign
        self.size = size
        self.style = style
        self.color = color
        self.strokeWidth = strokeWidth
        self.customSize = nil
    }

    init(sign: ZodiacSign, size: CGFloat, style: Style = .badge, color: Color? = nil, strokeWidth: CGFloat? = nil) {
        self.sign = sign
        self.size = .small
        self.style = style
        self.color = color
        self.strokeWidth = strokeWidth
        self.customSize = size
    }

    private var resolvedSize: CGFloat {
        customSize ?? size.pointSize
    }

    private var resolvedColor: Color {
        if let color {
            return color
        }
        switch style {
        case .badge:
            return CosmicTheme.gold
        case .element:
            return sign.element.color
        }
    }

    var body: some View {
        ZodiacSymbolView(
            sign: sign,
            size: resolvedSize,
            color: resolvedColor,
            strokeWidth: strokeWidth
        )
        .accessibilityLabel("\(sign.displayName) zodiac sign")
    }
}

