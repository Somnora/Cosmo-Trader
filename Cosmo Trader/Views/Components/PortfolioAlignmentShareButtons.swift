import SwiftUI

/// Share / export actions for the portfolio zodiac alignment card.
/// Owns the share sheet and the PNG/SVG generation so host views only
/// need a single call site.
struct PortfolioAlignmentShareButtons: View {
    let user: UserProfile
    let result: PortfolioCompatibilityResult

    @State private var showShareSheet: Bool = false
    @State private var shareItems: [Any] = []

    var body: some View {
        HStack(spacing: 12) {
            Button(action: sharePNGAlignmentCard) {
                HStack(spacing: 6) {
                    Image(systemName: "square.and.arrow.up")
                    Text("SHARE CARD")
                }
                .font(TerminalFont.data(10, weight: .bold))
                .foregroundColor(CosmicTheme.terminalBlack)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(CosmicTheme.gold)
            }
            .buttonStyle(.plain)

            Button(action: exportSVGAlignmentCard) {
                HStack(spacing: 6) {
                    Image(systemName: "curlybraces")
                    Text("EXPORT SVG")
                }
                .font(TerminalFont.data(10, weight: .bold))
                .foregroundColor(CosmicTheme.textPrimary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(CosmicTheme.cardBackground)
                .overlay(
                    Rectangle()
                        .stroke(CosmicTheme.border, lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
        }
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(items: shareItems)
        }
    }

    @MainActor
    private func sharePNGAlignmentCard() {
        let shareView = PortfolioCompatibilityShareView(user: user, result: result)
        let renderer = ImageRenderer(content: shareView)
        renderer.scale = 2.0

        if let image = renderer.uiImage {
            let shareText = "Check out my zodiac portfolio alignment score on Cosmo Trader! #CosmoTrader"
            shareItems = [shareText, image]
            showShareSheet = true
        }
    }

    private func exportSVGAlignmentCard() {
        let svgString = CosmicSVGExporter.generateAlignmentSVG(user: user, result: result)
        let filename = "CosmoTrader_Alignment_\(user.sunSign.displayName).svg"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(filename)

        do {
            try svgString.write(to: tempURL, atomically: true, encoding: .utf8)
            shareItems = [tempURL]
            showShareSheet = true
        } catch {
            Log.error("[PortfolioAlignmentShareButtons] Failed to write SVG file for sharing: \(error)")
        }
    }
}
