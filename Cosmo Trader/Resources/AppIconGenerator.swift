import SwiftUI
import UIKit

// MARK: - App Icon Generator
// ===========================
// Utility to programmatically generate the Cosmo Trader app icon.
// Run this in a preview or playground to generate the icon images.
//
// DESIGN SPEC:
// - Black background (#000000)
// - Gold constellation pattern
// - Stylized "CT" or zodiac-inspired glyph
// - OLED-optimized (true black for battery savings)

struct AppIconGenerator: View {

    let size: CGFloat

    var body: some View {
        ZStack {
            // True black background
            Color.black

            // Constellation pattern (simplified for icon)
            ConstellationIconPattern()
                .stroke(
                    LinearGradient(
                        colors: [
                            Color(hex: "FFD700"),
                            Color(hex: "DAA520")
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: size * 0.02, lineCap: .round)
                )
                .padding(size * 0.15)

            // Central glyph - stylized chart/star hybrid
            CentralGlyph()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(hex: "FFD700"),
                            Color(hex: "FFA500")
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: size * 0.5, height: size * 0.5)

            // Star accents at constellation points
            ForEach(0..<5, id: \.self) { index in
                Circle()
                    .fill(Color(hex: "FFD700"))
                    .frame(width: size * 0.04, height: size * 0.04)
                    .position(starPosition(index: index, in: size))
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.225)) // iOS icon corner radius
    }

    private func starPosition(index: Int, in size: CGFloat) -> CGPoint {
        let positions: [CGPoint] = [
            CGPoint(x: 0.2, y: 0.25),
            CGPoint(x: 0.8, y: 0.2),
            CGPoint(x: 0.15, y: 0.7),
            CGPoint(x: 0.85, y: 0.75),
            CGPoint(x: 0.5, y: 0.15)
        ]
        let pos = positions[index]
        return CGPoint(x: pos.x * size, y: pos.y * size)
    }
}

// MARK: - Constellation Pattern

struct ConstellationIconPattern: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height

        // Draw constellation lines connecting stars
        // Pattern inspired by stock chart peaks and troughs

        // Line 1: Top left to center top
        path.move(to: CGPoint(x: w * 0.1, y: h * 0.3))
        path.addLine(to: CGPoint(x: w * 0.5, y: h * 0.1))

        // Line 2: Center top to top right
        path.move(to: CGPoint(x: w * 0.5, y: h * 0.1))
        path.addLine(to: CGPoint(x: w * 0.9, y: h * 0.25))

        // Line 3: Bottom left connection
        path.move(to: CGPoint(x: w * 0.1, y: h * 0.3))
        path.addLine(to: CGPoint(x: w * 0.15, y: h * 0.75))

        // Line 4: Bottom right connection
        path.move(to: CGPoint(x: w * 0.9, y: h * 0.25))
        path.addLine(to: CGPoint(x: w * 0.85, y: h * 0.8))

        // Line 5: Bottom connection
        path.move(to: CGPoint(x: w * 0.15, y: h * 0.75))
        path.addLine(to: CGPoint(x: w * 0.85, y: h * 0.8))

        return path
    }
}

// MARK: - Central Glyph

struct CentralGlyph: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        _ = w / 2  // centerX reserved for future use
        _ = h / 2  // centerY reserved for future use

        // Create a stylized chart/constellation hybrid
        // Looks like an upward trending chart with star points

        // Main upward trend line (thick)
        path.move(to: CGPoint(x: w * 0.15, y: h * 0.7))
        path.addLine(to: CGPoint(x: w * 0.35, y: h * 0.5))
        path.addLine(to: CGPoint(x: w * 0.5, y: h * 0.6))
        path.addLine(to: CGPoint(x: w * 0.65, y: h * 0.3))
        path.addLine(to: CGPoint(x: w * 0.85, y: h * 0.25))

        // Add small star at the peak
        let starCenter = CGPoint(x: w * 0.85, y: h * 0.25)
        let starSize: CGFloat = w * 0.12
        path.addPath(starPath(center: starCenter, size: starSize))

        return path
    }

    private func starPath(center: CGPoint, size: CGFloat) -> Path {
        var path = Path()
        let points = 5
        let innerRadius = size * 0.4
        let outerRadius = size

        for i in 0..<(points * 2) {
            let radius = i.isMultiple(of: 2) ? outerRadius : innerRadius
            let angle = (CGFloat(i) * .pi / CGFloat(points)) - .pi / 2

            let point = CGPoint(
                x: center.x + cos(angle) * radius,
                y: center.y + sin(angle) * radius
            )

            if i == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        path.closeSubpath()

        return path
    }
}

// MARK: - Icon Export Helper

struct AppIconExporter {

    /// Generate app icon images at all required sizes
    /// Call this from a test or playground to export the images
    static func exportAllSizes() -> [String: UIImage] {
        var icons: [String: UIImage] = [:]

        // iOS requires 1024x1024 for App Store
        let sizes: [(String, CGFloat)] = [
            ("AppIcon-1024", 1024),
            ("AppIcon-180", 180),   // iPhone @3x
            ("AppIcon-120", 120),   // iPhone @2x
            ("AppIcon-167", 167),   // iPad Pro @2x
            ("AppIcon-152", 152),   // iPad @2x
            ("AppIcon-76", 76),     // iPad @1x
            ("AppIcon-40", 40),     // Spotlight @1x
            ("AppIcon-80", 80),     // Spotlight @2x
            ("AppIcon-120-spotlight", 120), // Spotlight @3x
            ("AppIcon-60", 60),     // Settings @3x
            ("AppIcon-58", 58),     // Settings @2x
            ("AppIcon-29", 29),     // Settings @1x
        ]

        for (name, size) in sizes {
            let view = AppIconGenerator(size: size)
            if let image = view.snapshot() {
                icons[name] = image
            }
        }

        return icons
    }
}

// MARK: - View Snapshot Extension

extension View {
    func snapshot() -> UIImage? {
        let controller = UIHostingController(rootView: self)
        let view = controller.view

        let targetSize = controller.view.intrinsicContentSize
        view?.bounds = CGRect(origin: .zero, size: targetSize)
        view?.backgroundColor = .clear

        let renderer = UIGraphicsImageRenderer(size: targetSize)
        return renderer.image { _ in
            view?.drawHierarchy(in: controller.view.bounds, afterScreenUpdates: true)
        }
    }
}

// MARK: - Previews

#Preview("App Icon - 1024px") {
    AppIconGenerator(size: 1024)
        .frame(width: 300, height: 300) // Scaled for preview
}

#Preview("App Icon - All Sizes") {
    VStack(spacing: 20) {
        HStack(spacing: 20) {
            AppIconGenerator(size: 120)
                .frame(width: 60, height: 60)

            AppIconGenerator(size: 180)
                .frame(width: 60, height: 60)

            AppIconGenerator(size: 1024)
                .frame(width: 80, height: 80)
        }

        Text("Cosmo Trader")
            .font(.system(size: 14, weight: .medium, design: .monospaced))
            .foregroundColor(.white)
    }
    .padding(40)
    .background(Color.gray.opacity(0.3))
}

#Preview("Icon on Home Screen Mock") {
    ZStack {
        // iOS wallpaper simulation
        LinearGradient(
            colors: [.purple.opacity(0.6), .blue.opacity(0.4)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()

        VStack(spacing: 8) {
            AppIconGenerator(size: 180)
                .frame(width: 60, height: 60)
                .shadow(color: .black.opacity(0.3), radius: 8, y: 4)

            Text("Cosmo Trader")
                .font(.system(size: 11))
                .foregroundColor(.white)
        }
    }
}
