import SwiftUI

// MARK: - CosmicReportCard
// ========================
// A shareable "report card" view for social media.
// Shows the user's cosmic trading identity in a terminal-style layout.
//
// DESIGN:
// - Terminal aesthetic with monospace fonts
// - Element breakdown as progress bars
// - Witty "cosmic diagnosis" roast
// - QR code placeholder and date stamp
//
// USAGE:
// 1. Display this view in a sheet
// 2. Use CosmicReportCardRenderer to convert to UIImage
// 3. Share via UIActivityViewController

struct CosmicReportCard: View {

    // MARK: - Properties

    let user: UserProfile

    /// Generated cosmic diagnosis based on portfolio
    private var diagnosis: CosmicDiagnosis {
        CosmicDiagnosisGenerator.generate(for: user)
    }

    /// Element breakdown from portfolio
    private var elementBreakdown: [ElementBreakdown] {
        calculateElementBreakdown()
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // Top: Terminal header
            terminalHeader

            // Divider line
            terminalDivider

            // User identity section
            userIdentitySection

            // Divider
            terminalDivider

            // Middle: Element breakdown bars
            elementBreakdownSection

            // Divider
            terminalDivider

            // Bottom: Cosmic diagnosis roast
            diagnosisSection

            // Footer: QR code and date
            footerSection
        }
        .background(CosmicTheme.background)
        .frame(width: 390) // Fixed width for consistent sharing
    }

    // MARK: - Terminal Header

    private var terminalHeader: some View {
        VStack(spacing: 8) {
            // Top decoration
            HStack(spacing: 4) {
                ForEach(0..<3, id: \.self) { _ in
                    Circle()
                        .fill(CosmicTheme.textMuted.opacity(0.5))
                        .frame(width: 8, height: 8)
                }
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.top, 8)

            // Main title
            HStack {
                Image(systemName: "sparkles")
                    .font(.system(size: 14))
                    .foregroundColor(CosmicTheme.gold)

                Text("COSMO TRADER TERMINAL")
                    .font(TerminalFont.ticker(18))
                    .foregroundColor(CosmicTheme.textPrimary)

                Image(systemName: "sparkles")
                    .font(.system(size: 14))
                    .foregroundColor(CosmicTheme.gold)
            }
            .padding(.vertical, 12)

            // Subtitle
            Text("COSMIC PORTFOLIO ANALYSIS")
                .font(TerminalFont.data(11))
                .foregroundColor(CosmicTheme.textMuted)
                .padding(.bottom, 8)
        }
        .frame(maxWidth: .infinity)
        .background(CosmicTheme.cardBackground)
    }

    // MARK: - User Identity Section

    private var userIdentitySection: some View {
        HStack(spacing: 20) {
            // Zodiac badge
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(user.element.color.opacity(0.2))
                        .frame(width: 70, height: 70)

                    Circle()
                        .stroke(user.element.color.opacity(0.5), lineWidth: 2)
                        .frame(width: 70, height: 70)

                    ZodiacSymbolView(sign: user.sunSign, size: 36, color: user.element.color)
                }

                Text(user.sunSign.displayName.uppercased())
                    .font(TerminalFont.ticker(12))
                    .foregroundColor(user.element.color)
            }

            // User info
            VStack(alignment: .leading, spacing: 6) {
                Text(user.displayName.uppercased())
                    .font(TerminalFont.ticker(16))
                    .foregroundColor(CosmicTheme.textPrimary)

                HStack(spacing: 8) {
                    ElementSymbolView(element: user.element, size: 14, color: user.element.color)

                    Text("\(user.element.displayName) Sign")
                        .font(TerminalFont.data(12))
                        .foregroundColor(user.element.color)
                }

                Text("Portfolio: \(user.formattedPortfolioValue)")
                    .font(TerminalFont.price(14))
                    .foregroundColor(CosmicTheme.textSecondary)

                HStack(spacing: 4) {
                    Text(user.isPortfolioPositive ? "+" : "")
                    Text(user.formattedDailyChangePercent)
                }
                .font(TerminalFont.data(12))
                .foregroundColor(user.isPortfolioPositive ? CosmicTheme.positive : CosmicTheme.negative)
            }

            Spacer()
        }
        .padding(20)
        .background(CosmicTheme.secondaryBackground)
    }

    // MARK: - Element Breakdown Section

    private var elementBreakdownSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section header
            HStack {
                Text("ELEMENTAL COMPOSITION")
                    .font(TerminalFont.data(11, weight: .semibold))
                    .foregroundColor(CosmicTheme.gold)

                Spacer()

                Text("\(user.portfolio.count) HOLDINGS")
                    .font(TerminalFont.data(10))
                    .foregroundColor(CosmicTheme.textMuted)
            }

            // Element progress bars
            VStack(spacing: 12) {
                ForEach(elementBreakdown) { breakdown in
                    ElementProgressBar(breakdown: breakdown)
                }
            }
        }
        .padding(20)
        .background(CosmicTheme.cardBackground)
    }

    // MARK: - Diagnosis Section

    private var diagnosisSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 14))
                    .foregroundColor(CosmicTheme.gold)

                Text("COSMIC DIAGNOSIS")
                    .font(TerminalFont.data(11, weight: .semibold))
                    .foregroundColor(CosmicTheme.gold)
            }

            // The roast
            Text(diagnosis.roast)
                .font(TerminalFont.body(14))
                .foregroundColor(CosmicTheme.textPrimary)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)

            // Trading style badge
            HStack(spacing: 6) {
                Image(systemName: diagnosis.traderTypeIcon)
                    .font(.system(size: 12))

                Text(diagnosis.traderType.uppercased())
                    .font(TerminalFont.data(10, weight: .bold))
            }
            .foregroundColor(diagnosis.accentColor)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(diagnosis.accentColor.opacity(0.15))
            )
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(CosmicTheme.secondaryBackground)
    }

    // MARK: - Footer Section

    private var footerSection: some View {
        HStack(spacing: 16) {
            // QR Code placeholder
            VStack(spacing: 4) {
                ZStack {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white)
                        .frame(width: 60, height: 60)

                    // Placeholder QR pattern
                    QRCodePlaceholder()
                        .frame(width: 52, height: 52)
                }

                Text("SCAN TO TRADE")
                    .font(TerminalFont.data(8))
                    .foregroundColor(CosmicTheme.textMuted)
            }

            VStack(alignment: .leading, spacing: 4) {
                // App branding
                Text("COSMO TRADER")
                    .font(TerminalFont.ticker(12))
                    .foregroundColor(CosmicTheme.gold)

                Text("Trade with the stars")
                    .font(TerminalFont.data(10))
                    .foregroundColor(CosmicTheme.textMuted)

                Spacer()

                // Date stamp
                Text("Generated: \(formattedDate)")
                    .font(TerminalFont.timestamp(9))
                    .foregroundColor(CosmicTheme.textMuted)
            }

            Spacer()

            // Zodiac wheel decoration
            ZodiacWheelDecoration(userSign: user.sunSign)
                .frame(width: 60, height: 60)
        }
        .padding(16)
        .background(CosmicTheme.cardBackground)
    }

    // MARK: - Helpers

    private var terminalDivider: some View {
        Rectangle()
            .fill(CosmicTheme.border)
            .frame(height: 1)
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM dd, yyyy HH:mm"
        return formatter.string(from: Date())
    }

    /// Calculate element breakdown from portfolio
    private func calculateElementBreakdown() -> [ElementBreakdown] {
        let verifiedHoldings = user.portfolio.filter { $0.sharesOwned > 0 && $0.foundedElement != nil }
        let totalValue = verifiedHoldings.reduce(0) { $0 + $1.totalValue }
        guard totalValue > 0 else {
            return ZodiacSign.Element.allCases.map {
                ElementBreakdown(element: $0, percentage: 0, value: 0)
            }
        }

        var elementValues: [ZodiacSign.Element: Double] = [:]
        for stock in verifiedHoldings {
            guard let element = stock.foundedElement else { continue }
            elementValues[element, default: 0] += stock.totalValue
        }

        return ZodiacSign.Element.allCases.map { element in
            let value = elementValues[element] ?? 0
            let percentage = (value / totalValue) * 100
            return ElementBreakdown(element: element, percentage: percentage, value: value)
        }.sorted { $0.percentage > $1.percentage }
    }
}

// MARK: - Element Progress Bar

struct ElementProgressBar: View {

    let breakdown: ElementBreakdown

    private var elementColor: Color {
        switch breakdown.element {
        case .fire:  return CosmicTheme.fireElement
        case .earth: return CosmicTheme.earthElement
        case .air:   return CosmicTheme.airElement
        case .water: return CosmicTheme.waterElement
        }
    }

    var body: some View {
        VStack(spacing: 6) {
            // Label row
            HStack {
                HStack(spacing: 6) {
                    ElementSymbolView(element: breakdown.element, size: 14, color: elementColor)

                    Text(breakdown.element.displayName.uppercased())
                        .font(TerminalFont.data(11, weight: .semibold))
                        .foregroundColor(elementColor)
                }

                Spacer()

                Text(breakdown.formattedPercentage)
                    .font(TerminalFont.price(13))
                    .foregroundColor(breakdown.percentage > 0 ? CosmicTheme.textPrimary : CosmicTheme.textMuted)
            }

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background track
                    RoundedRectangle(cornerRadius: 2)
                        .fill(CosmicTheme.border)
                        .frame(height: 8)

                    // Filled portion
                    RoundedRectangle(cornerRadius: 2)
                        .fill(elementColor)
                        .frame(width: max(0, geometry.size.width * CGFloat(breakdown.percentage / 100)), height: 8)
                }
            }
            .frame(height: 8)
        }
    }
}

// MARK: - Cosmic Diagnosis

struct CosmicDiagnosis {
    let roast: String
    let traderType: String
    let traderTypeIcon: String
    let accentColor: Color
}

// MARK: - Cosmic Diagnosis Generator

struct CosmicDiagnosisGenerator {

    static func generate(for user: UserProfile) -> CosmicDiagnosis {
        let breakdown = calculateBreakdown(for: user)
        let dominant = breakdown.max(by: { $0.percentage < $1.percentage })
        let dominantPercentage = dominant?.percentage ?? 0
        let dominantElement = dominant?.element ?? .fire

        // Generate roast based on portfolio composition
        let roast = generateRoast(
            element: dominantElement,
            percentage: dominantPercentage,
            holdingsCount: user.portfolio.count,
            isPositive: user.isPortfolioPositive
        )

        let (traderType, icon) = getTraderType(element: dominantElement, percentage: dominantPercentage)

        let accentColor: Color = {
            switch dominantElement {
            case .fire:  return CosmicTheme.fireElement
            case .earth: return CosmicTheme.earthElement
            case .air:   return CosmicTheme.airElement
            case .water: return CosmicTheme.waterElement
            }
        }()

        return CosmicDiagnosis(
            roast: roast,
            traderType: traderType,
            traderTypeIcon: icon,
            accentColor: accentColor
        )
    }

    private static func calculateBreakdown(for user: UserProfile) -> [ElementBreakdown] {
        let verifiedHoldings = user.portfolio.filter { $0.sharesOwned > 0 && $0.foundedElement != nil }
        let totalValue = verifiedHoldings.reduce(0) { $0 + $1.totalValue }
        guard totalValue > 0 else {
            return ZodiacSign.Element.allCases.map {
                ElementBreakdown(element: $0, percentage: 0, value: 0)
            }
        }

        var elementValues: [ZodiacSign.Element: Double] = [:]
        for stock in verifiedHoldings {
            guard let element = stock.foundedElement else { continue }
            elementValues[element, default: 0] += stock.totalValue
        }

        return ZodiacSign.Element.allCases.map { element in
            let value = elementValues[element] ?? 0
            let percentage = (value / totalValue) * 100
            return ElementBreakdown(element: element, percentage: percentage, value: value)
        }
    }

    private static func generateRoast(
        element: ZodiacSign.Element,
        percentage: Double,
        holdingsCount: Int,
        isPositive: Bool
    ) -> String {
        // Empty portfolio
        if holdingsCount == 0 {
            return "Your portfolio is as empty as the void between stars. The cosmos awaits your first move."
        }

        // Heavily concentrated (>70%)
        if percentage > 70 {
            switch element {
            case .fire:
                return "Your portfolio is \(Int(percentage))% Fire. You don't invest, you gamble with cosmic confidence. The universe admires your audacity (your accountant does not)."
            case .earth:
                return "Your portfolio is \(Int(percentage))% Earth. You're so stable you probably alphabetize your socks. Exciting? No. Reliable? Absolutely."
            case .air:
                return "Your portfolio is \(Int(percentage))% Air. You've researched every stock so thoroughly you forgot to actually feel anything. Analysis paralysis is your love language."
            case .water:
                return "Your portfolio is \(Int(percentage))% Water. You invest based on vibes and mercury retrograde alerts. Your gut feeling has a gut feeling."
            }
        }

        // Moderately concentrated (50-70%)
        if percentage > 50 {
            switch element {
            case .fire:
                return "Fire leads your portfolio at \(Int(percentage))%. You chase growth like a moth to flame. Sometimes you get burned, but at least you're warm."
            case .earth:
                return "Earth grounds your portfolio at \(Int(percentage))%. You build wealth like you build friendships: slowly, deliberately, and with a lot of spreadsheets."
            case .air:
                return "Air dominates at \(Int(percentage))%. You've got more tabs open than positions, and each one is a different financial blog."
            case .water:
                return "Water flows through \(Int(percentage))% of your holdings. Your investment thesis: 'I had a dream about this stock.'"
            }
        }

        // Balanced portfolio
        let balanceRoasts = [
            "Your portfolio is elementally balanced. You're either enlightened or indecisive. The stars aren't sure which.",
            "Perfect cosmic balance achieved. You're diversified across all elements, which means you're hedging against your own judgment.",
            "The elements are in harmony. You've somehow managed to be equally wrong about everything. Impressive.",
            "Balanced across fire, earth, air, and water. You're the Switzerland of cosmic traders: neutral, efficient, and slightly boring."
        ]

        // Add performance-based twist
        if isPositive {
            return balanceRoasts.randomElement()! + " At least you're in the green."
        } else {
            return balanceRoasts.randomElement()! + " The red numbers add character."
        }
    }

    private static func getTraderType(element: ZodiacSign.Element, percentage: Double) -> (String, String) {
        if percentage > 70 {
            switch element {
            case .fire:  return ("Cosmic Gambler", "flame.fill")
            case .earth: return ("Galactic Boomer", "mountain.2.fill")
            case .air:   return ("Overthinking Oracle", "wind")
            case .water: return ("Vibes-Based Investor", "drop.fill")
            }
        } else if percentage > 50 {
            switch element {
            case .fire:  return ("Growth Chaser", "arrow.up.right")
            case .earth: return ("Steady Builder", "building.2.fill")
            case .air:   return ("Data Devotee", "chart.bar.fill")
            case .water: return ("Intuitive Trader", "waveform.path.ecg")
            }
        } else {
            return ("Cosmic Balancer", "scale.3d")
        }
    }
}

// MARK: - QR Code Placeholder

struct QRCodePlaceholder: View {
    var body: some View {
        Canvas { context, size in
            let cellSize = size.width / 7
            let pattern: [[Bool]] = [
                [true, true, true, false, true, true, true],
                [true, false, true, false, true, false, true],
                [true, true, true, false, true, true, true],
                [false, false, false, false, false, false, false],
                [true, true, true, false, true, false, true],
                [true, false, true, false, false, true, false],
                [true, true, true, false, true, true, true]
            ]

            for (row, rowData) in pattern.enumerated() {
                for (col, filled) in rowData.enumerated() {
                    if filled {
                        let rect = CGRect(
                            x: CGFloat(col) * cellSize,
                            y: CGFloat(row) * cellSize,
                            width: cellSize,
                            height: cellSize
                        )
                        context.fill(Path(rect), with: .color(.black))
                    }
                }
            }
        }
    }
}

// MARK: - Zodiac Wheel Decoration

struct ZodiacWheelDecoration: View {
    let userSign: ZodiacSign

    private var userSignIndex: Int {
        ZodiacSign.allCases.firstIndex(of: userSign) ?? 0
    }

    var body: some View {
        Canvas { context, size in
            drawWheel(context: context, size: size)
        }
    }

    private func drawWheel(context: GraphicsContext, size: CGSize) {
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let radius = min(size.width, size.height) / 2 - 4

        // Draw outer circle
        drawOuterCircle(context: context, center: center, radius: radius)

        // Draw 12 segments
        drawSegments(context: context, center: center, radius: radius)

        // Draw center dot
        drawCenterDot(context: context, center: center)
    }

    private func drawOuterCircle(context: GraphicsContext, center: CGPoint, radius: CGFloat) {
        let rect = CGRect(
            x: center.x - radius,
            y: center.y - radius,
            width: radius * 2,
            height: radius * 2
        )
        let outerPath = Path(ellipseIn: rect)
        let color = CosmicTheme.gold.opacity(0.5)
        context.stroke(outerPath, with: .color(color), lineWidth: 1)
    }

    private func drawSegments(context: GraphicsContext, center: CGPoint, radius: CGFloat) {
        for i in 0..<12 {
            drawSegment(context: context, center: center, radius: radius, index: i)
        }
    }

    private func drawSegment(context: GraphicsContext, center: CGPoint, radius: CGFloat, index: Int) {
        let angle = Double(index) * (2 * .pi / 12) - .pi / 2
        let innerRadius = radius * 0.6
        let outerRadius = radius * 0.95

        let startX = center.x + cos(angle) * innerRadius
        let startY = center.y + sin(angle) * innerRadius
        let endX = center.x + cos(angle) * outerRadius
        let endY = center.y + sin(angle) * outerRadius

        var path = Path()
        path.move(to: CGPoint(x: startX, y: startY))
        path.addLine(to: CGPoint(x: endX, y: endY))

        let isUserSign = index == userSignIndex
        let strokeColor: Color = isUserSign ? CosmicTheme.gold : CosmicTheme.textMuted.opacity(0.4)
        let strokeWidth: CGFloat = isUserSign ? 2 : 0.5
        context.stroke(path, with: .color(strokeColor), lineWidth: strokeWidth)
    }

    private func drawCenterDot(context: GraphicsContext, center: CGPoint) {
        let rect = CGRect(x: center.x - 3, y: center.y - 3, width: 6, height: 6)
        let centerDot = Path(ellipseIn: rect)
        context.fill(centerDot, with: .color(CosmicTheme.gold))
    }
}

// MARK: - Image Renderer

@MainActor
struct CosmicReportCardRenderer {

    /// Render the report card to a UIImage for sharing
    /// - Parameters:
    ///   - user: The user profile to generate the card for
    ///   - scale: The scale factor for the image (default 2.0 for retina)
    /// - Returns: A UIImage of the rendered report card
    static func render(user: UserProfile, scale: CGFloat = 2.0) -> UIImage? {
        let reportCard = CosmicReportCard(user: user)

        let renderer = ImageRenderer(content: reportCard)
        renderer.scale = scale

        return renderer.uiImage
    }

    /// Render and prepare for sharing via UIActivityViewController
    /// - Parameters:
    ///   - user: The user profile to generate the card for
    ///   - completion: Callback with the UIActivityViewController or nil if rendering failed
    static func prepareForSharing(user: UserProfile, completion: @escaping (UIActivityViewController?) -> Void) {
        guard let image = render(user: user) else {
            completion(nil)
            return
        }

        let shareText = "Check out my cosmic trading identity! I'm a \(user.sunSign.displayName) with a \(user.element.displayName)-heavy portfolio. #CosmoTrader"

        let activityVC = UIActivityViewController(
            activityItems: [shareText, image],
            applicationActivities: nil
        )

        completion(activityVC)
    }
}

// MARK: - Share Button View

struct ShareReportCardButton: View {

    let user: UserProfile
    @State private var isGenerating = false
    @State private var showShareSheet = false
    @State private var shareImage: UIImage?

    var body: some View {
        Button(action: generateAndShare) {
            HStack(spacing: 8) {
                if isGenerating {
                    ProgressView()
                        .scaleEffect(0.8)
                        .tint(CosmicTheme.background)
                } else {
                    Image(systemName: "square.and.arrow.up")
                        .font(.headline)
                }

                Text("Share Cosmic Identity")
                    .font(TerminalFont.data(14, weight: .semibold))
            }
            .foregroundColor(CosmicTheme.background)
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            .background(CosmicTheme.goldGradient)
            .cornerRadius(8)
        }
        .disabled(isGenerating)
        .sheet(isPresented: $showShareSheet) {
            if let image = shareImage {
                ShareSheet(items: [
                    "Check out my cosmic trading identity! #CosmoTrader",
                    image
                ])
            }
        }
    }

    @MainActor
    private func generateAndShare() {
        isGenerating = true

        // Small delay to show loading state
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            shareImage = CosmicReportCardRenderer.render(user: user)
            isGenerating = false

            if shareImage != nil {
                showShareSheet = true
            }
        }
    }
}

// MARK: - Share Sheet
// ShareSheet is defined in ProfileView.swift to avoid duplication

// MARK: - Preview

#Preview("Cosmic Report Card") {
    ScrollView {
        CosmicReportCard(user: .sampleWithHoldings)
    }
    .background(Color.black)
}

#Preview("Report Card - Fire Heavy") {
    // Create a fire-heavy portfolio
    var fireUser = UserProfile(
        displayName: "Phoenix Trader",
        email: "phoenix@cosmo.com",
        birthMonth: 4,
        birthDay: 5,
        birthYear: 1995
    )

    // Add mostly fire stocks
    if var apple = MockStockData.knownStocks.first(where: { $0.symbol == "AAPL" }) {
        apple.sharesOwned = 50
        fireUser.addStock(apple)
    }
    if var ford = MockStockData.knownStocks.first(where: { $0.symbol == "F" }) {
        ford.sharesOwned = 100
        fireUser.addStock(ford)
    }

    return ScrollView {
        CosmicReportCard(user: fireUser)
    }
    .background(Color.black)
}

#Preview("Share Button") {
    VStack {
        ShareReportCardButton(user: .sampleWithHoldings)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(CosmicTheme.background)
}
