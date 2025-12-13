import SwiftUI

// MARK: - Cosmic Obituary Views
// ==============================
// UI components for displaying cosmic obituaries of delisted/bankrupt stocks.
// Dark humor meets market education.

// MARK: - Obituary Card (for Profile)

struct CosmicObituaryCard: View {
    @State private var service = CosmicObituaryService.shared
    @State private var showGraveyard: Bool = false

    var body: some View {
        Button(action: { showGraveyard = true }) {
            HStack(spacing: 14) {
                // Tombstone icon
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 48, height: 48)

                    Text("⚰️")
                        .font(.title2)
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text("Cosmic Graveyard")
                            .font(TerminalFont.body(14, weight: .semibold))
                            .foregroundColor(CosmicTheme.textPrimary)

                        if service.hasUnviewedObituaries {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 8, height: 8)
                        }
                    }

                    Text("Where fallen stocks rest eternally")
                        .font(TerminalFont.caption(11))
                        .foregroundColor(CosmicTheme.textMuted)
                }

                Spacer()

                // Count badge
                Text("\(service.allObituaries.count)")
                    .font(TerminalFont.body(14, weight: .bold))
                    .foregroundColor(CosmicTheme.textSecondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(CosmicTheme.cardBackground)
                    )

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(CosmicTheme.textMuted)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(CosmicTheme.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 0.5)
                    )
            )
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showGraveyard) {
            CosmicGraveyardSheet()
        }
    }
}

// MARK: - Cosmic Graveyard Sheet

struct CosmicGraveyardSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var service = CosmicObituaryService.shared
    @State private var selectedObituary: CosmicObituary?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    graveyardHeader

                    // Obituaries
                    LazyVStack(spacing: 16) {
                        ForEach(service.allObituaries) { obituary in
                            ObituaryRow(obituary: obituary)
                                .onTapGesture {
                                    selectedObituary = obituary
                                    service.markAsViewed(obituary)
                                    AnalyticsService.shared.track(.cosmicObituaryViewed)
                                }
                        }
                    }
                    .padding(.horizontal, 16)
                }
                .padding(.bottom, 40)
            }
            .background(
                LinearGradient(
                    colors: [
                        Color(red: 0.05, green: 0.05, blue: 0.08),
                        Color(red: 0.08, green: 0.06, blue: 0.12),
                        CosmicTheme.background
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            )
            .navigationTitle("Cosmic Graveyard")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(CosmicTheme.gold)
                }
            }
            .toolbarBackground(Color(red: 0.05, green: 0.05, blue: 0.08), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .sheet(item: $selectedObituary) { obituary in
                ObituaryDetailSheet(obituary: obituary)
            }
        }
    }

    private var graveyardHeader: some View {
        VStack(spacing: 16) {
            // Gate visual
            Text("🪦")
                .font(.system(size: 48))

            Text("Here lie the fallen")
                .font(TerminalFont.headline(20))
                .foregroundColor(CosmicTheme.textPrimary)

            Text("Stocks that burned bright, then burned out.\nMay their lessons compound eternally.")
                .font(TerminalFont.caption(12))
                .foregroundColor(CosmicTheme.textMuted)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
        }
        .padding(.vertical, 24)
    }
}

// MARK: - Obituary Row

struct ObituaryRow: View {
    let obituary: CosmicObituary

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                // Symbol and sign
                HStack(spacing: 8) {
                    Text(obituary.zodiacSign.symbol)
                        .font(.title3)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(obituary.symbol)
                            .font(TerminalFont.body(14, weight: .bold))
                            .foregroundColor(CosmicTheme.textPrimary)

                        Text(obituary.formattedLifespan)
                            .font(TerminalFont.caption(10))
                            .foregroundColor(CosmicTheme.textMuted)
                    }
                }

                Spacer()

                // Cause of death badge
                HStack(spacing: 4) {
                    Image(systemName: obituary.causeOfDeath.icon)
                        .font(.caption2)

                    Text(obituary.causeOfDeath.rawValue)
                        .font(TerminalFont.caption(9, weight: .medium))
                }
                .foregroundColor(obituary.causeOfDeath.color)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(obituary.causeOfDeath.color.opacity(0.15))
                )
            }

            // Name
            Text(obituary.name)
                .font(TerminalFont.caption(11))
                .foregroundColor(CosmicTheme.textSecondary)

            // Epitaph
            Text("\"\(obituary.epitaph)\"")
                .font(TerminalFont.caption(12))
                .italic()
                .foregroundColor(CosmicTheme.textPrimary)
                .lineLimit(2)

            // Price info (if available)
            if let loss = obituary.percentageLoss {
                HStack {
                    if let peak = obituary.peakPrice {
                        Text("Peak: $\(String(format: "%.2f", peak))")
                            .font(TerminalFont.caption(10))
                            .foregroundColor(CosmicTheme.textMuted)
                    }

                    Spacer()

                    Text("-\(String(format: "%.1f", loss))%")
                        .font(TerminalFont.caption(10, weight: .bold))
                        .foregroundColor(CosmicTheme.negative)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.3))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 0.5)
                )
        )
    }
}

// MARK: - Obituary Detail Sheet

struct ObituaryDetailSheet: View {
    let obituary: CosmicObituary
    @Environment(\.dismiss) private var dismiss
    @State private var showShareSheet: Bool = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Tombstone header
                    tombstoneHeader

                    // Epitaph
                    epitaphSection

                    // Eulogy
                    eulogySection

                    // Cosmic lesson
                    lessonSection

                    // Stats (if available)
                    if obituary.peakPrice != nil || obituary.finalPrice != nil {
                        statsSection
                    }

                    // Share button
                    shareButton
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
            .background(
                LinearGradient(
                    colors: [
                        Color(red: 0.05, green: 0.05, blue: 0.08),
                        CosmicTheme.background
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            )
            .navigationTitle("In Memoriam")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(CosmicTheme.gold)
                }
            }
            .toolbarBackground(Color(red: 0.05, green: 0.05, blue: 0.08), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .sheet(isPresented: $showShareSheet) {
                ShareSheet(text: obituary.shareableText)
            }
        }
    }

    private var tombstoneHeader: some View {
        VStack(spacing: 16) {
            // Tombstone shape
            ZStack {
                // Tombstone background
                TombstoneShape()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 200, height: 240)

                VStack(spacing: 12) {
                    // Cross or symbol
                    Text("✝")
                        .font(.title)
                        .foregroundColor(CosmicTheme.textMuted)

                    // Symbol
                    Text(obituary.symbol)
                        .font(.system(size: 28, weight: .bold, design: .monospaced))
                        .foregroundColor(CosmicTheme.textPrimary)

                    // Zodiac
                    HStack(spacing: 4) {
                        Text(obituary.zodiacSign.symbol)
                        Text(obituary.zodiacSign.displayName)
                            .font(TerminalFont.caption(12))
                    }
                    .foregroundColor(obituary.zodiacSign.element.color)

                    // Years
                    Text(obituary.formattedLifespan)
                        .font(TerminalFont.body(16, weight: .semibold))
                        .foregroundColor(CosmicTheme.textSecondary)

                    // R.I.P.
                    Text("R.I.P.")
                        .font(TerminalFont.caption(10))
                        .foregroundColor(CosmicTheme.textMuted)
                }
            }

            // Name
            Text(obituary.name)
                .font(TerminalFont.body(16))
                .foregroundColor(CosmicTheme.textSecondary)

            // Cause of death
            HStack(spacing: 6) {
                Image(systemName: obituary.causeOfDeath.icon)
                Text("Cause: \(obituary.causeOfDeath.rawValue)")
            }
            .font(TerminalFont.caption(11))
            .foregroundColor(obituary.causeOfDeath.color)
        }
        .padding(.top, 20)
    }

    private var epitaphSection: some View {
        VStack(spacing: 12) {
            Text("EPITAPH")
                .font(TerminalFont.caption(10, weight: .bold))
                .foregroundColor(CosmicTheme.textMuted)
                .tracking(2)

            Text("\"\(obituary.epitaph)\"")
                .font(TerminalFont.body(18))
                .italic()
                .foregroundColor(CosmicTheme.textPrimary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.3))
        )
    }

    private var eulogySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "text.quote")
                    .foregroundColor(CosmicTheme.gold)
                Text("Eulogy")
                    .font(TerminalFont.body(14, weight: .semibold))
                    .foregroundColor(CosmicTheme.gold)
            }

            Text(obituary.eulogy)
                .font(TerminalFont.body(14))
                .foregroundColor(CosmicTheme.textSecondary)
                .lineSpacing(6)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(CosmicTheme.cardBackground)
        )
    }

    private var lessonSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.yellow)
                Text("Cosmic Lesson")
                    .font(TerminalFont.body(14, weight: .semibold))
                    .foregroundColor(.yellow)
            }

            Text(obituary.cosmicLesson)
                .font(TerminalFont.body(14))
                .foregroundColor(CosmicTheme.textPrimary)
                .lineSpacing(4)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.yellow.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
                )
        )
    }

    private var statsSection: some View {
        VStack(spacing: 12) {
            Text("FINAL NUMBERS")
                .font(TerminalFont.caption(10, weight: .bold))
                .foregroundColor(CosmicTheme.textMuted)
                .tracking(2)

            HStack(spacing: 24) {
                if let peak = obituary.peakPrice {
                    statItem(label: "Peak", value: "$\(String(format: "%.2f", peak))", color: .green)
                }

                if let final = obituary.finalPrice {
                    statItem(label: "Final", value: "$\(String(format: "%.2f", final))", color: .red)
                }

                if let loss = obituary.percentageLoss {
                    statItem(label: "Loss", value: "-\(String(format: "%.1f", loss))%", color: .red)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.3))
        )
    }

    private func statItem(label: String, value: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(label)
                .font(TerminalFont.caption(10))
                .foregroundColor(CosmicTheme.textMuted)

            Text(value)
                .font(TerminalFont.body(14, weight: .bold))
                .foregroundColor(color)
        }
    }

    private var shareButton: some View {
        Button(action: {
            showShareSheet = true
            AnalyticsService.shared.track(.cosmicObituaryShared)
        }) {
            HStack {
                Image(systemName: "square.and.arrow.up")
                Text("Share This Obituary")
            }
            .font(TerminalFont.body(14, weight: .semibold))
            .foregroundColor(CosmicTheme.textPrimary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(CosmicTheme.textMuted, lineWidth: 1)
            )
        }
    }
}

// MARK: - Tombstone Shape

struct TombstoneShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        let cornerRadius: CGFloat = rect.width * 0.15

        // Start at bottom left
        path.move(to: CGPoint(x: 0, y: rect.height))

        // Left side up
        path.addLine(to: CGPoint(x: 0, y: cornerRadius))

        // Top left curve
        path.addArc(
            center: CGPoint(x: cornerRadius, y: cornerRadius),
            radius: cornerRadius,
            startAngle: .degrees(180),
            endAngle: .degrees(270),
            clockwise: false
        )

        // Top
        path.addLine(to: CGPoint(x: rect.width - cornerRadius, y: 0))

        // Top right curve
        path.addArc(
            center: CGPoint(x: rect.width - cornerRadius, y: cornerRadius),
            radius: cornerRadius,
            startAngle: .degrees(270),
            endAngle: .degrees(0),
            clockwise: false
        )

        // Right side down
        path.addLine(to: CGPoint(x: rect.width, y: rect.height))

        // Bottom
        path.addLine(to: CGPoint(x: 0, y: rect.height))

        return path
    }
}

// MARK: - Previews

#Preview("Obituary Card") {
    VStack {
        CosmicObituaryCard()
    }
    .padding()
    .background(CosmicTheme.background)
    .preferredColorScheme(.dark)
}

#Preview("Graveyard Sheet") {
    CosmicGraveyardSheet()
        .preferredColorScheme(.dark)
}

#Preview("Obituary Detail") {
    ObituaryDetailSheet(obituary: CosmicObituaryService.shared.famousObituaries.first!)
        .preferredColorScheme(.dark)
}
