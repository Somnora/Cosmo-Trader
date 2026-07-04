import SwiftUI

// MARK: - Saturn Return Card
// ===========================
// Detailed card for stock detail view

struct SaturnReturnCard: View {
    let stock: Stock
    @State private var saturnService = SaturnReturnService.shared
    @State private var showDetail = false

    var body: some View {
        if let data = saturnService.getSaturnReturn(for: stock) {
            Button(action: { showDetail = true }) {
                VStack(alignment: .leading, spacing: 16) {
                    // Header
                    HStack {
                        HStack(spacing: 8) {
                            Image(systemName: "circle.hexagongrid.fill")
                                .font(.headline)
                                .foregroundColor(data.status.color)

                            Text("Saturn Return")
                                .font(TerminalFont.headline(14))
                                .foregroundColor(CosmicTheme.textPrimary)
                        }

                        Spacer()

                        // Status badge
                        Text(data.status.rawValue)
                            .font(.system(size: 10, weight: .semibold, design: .monospaced))
                            .foregroundColor(data.status == .inSaturnReturn ? .black : data.status.color)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(data.status == .inSaturnReturn ? data.status.color : data.status.color.opacity(0.2))
                            )
                    }

                    // Company age
                    HStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Company Age")
                                .font(.caption)
                                .foregroundColor(CosmicTheme.textMuted)
                            Text(data.formattedAge)
                                .font(TerminalFont.data(14, weight: .semibold))
                                .foregroundColor(CosmicTheme.textPrimary)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Next Saturn Return")
                                .font(.caption)
                                .foregroundColor(CosmicTheme.textMuted)
                            Text(data.formattedNextDate)
                                .font(TerminalFont.data(14, weight: .semibold))
                                .foregroundColor(data.status.color)
                        }
                    }

                    // Progress ring
                    saturnCycleProgress(data: data)

                    // Insight teaser
                    if let insight = saturnService.getHistoricalInsight(for: stock) {
                        Text(insight.insight)
                            .font(.caption)
                            .foregroundColor(CosmicTheme.textSecondary)
                            .lineLimit(3)
                    }

                    // Tap for more
                    HStack {
                        Spacer()
                        Text("Tap for full analysis")
                            .font(.caption2)
                            .foregroundColor(CosmicTheme.gold)
                        Image(systemName: "chevron.right")
                            .font(.caption2)
                            .foregroundColor(CosmicTheme.gold)
                    }
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(CosmicTheme.cardBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(data.status.color.opacity(0.2), lineWidth: 1)
                        )
                )
            }
            .buttonStyle(.plain)
            .sheet(isPresented: $showDetail) {
                SaturnReturnDetailSheet(stock: stock, data: data)
            }
        }
    }

    private func saturnCycleProgress(data: SaturnReturnData) -> some View {
        HStack(spacing: 12) {
            // Progress ring
            ZStack {
                Circle()
                    .stroke(CosmicTheme.textMuted.opacity(0.3), lineWidth: 4)
                    .frame(width: 50, height: 50)

                Circle()
                    .trim(from: 0, to: data.progressToNextReturn)
                    .stroke(
                        data.status.color,
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .frame(width: 50, height: 50)
                    .rotationEffect(.degrees(-90))

                // Saturn symbol in center
                Text("h")
                    .font(.system(size: 20, weight: .light))
                    .foregroundColor(data.status.color)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Cycle Progress")
                    .font(.caption)
                    .foregroundColor(CosmicTheme.textMuted)

                Text("\(Int(data.progressToNextReturn * 100))% through current Saturn cycle")
                    .font(.caption)
                    .foregroundColor(CosmicTheme.textSecondary)

                Text("Saturn Return #\(data.currentSaturnReturnNumber)")
                    .font(.caption2)
                    .foregroundColor(CosmicTheme.textMuted)
            }

            Spacer()
        }
    }
}

// MARK: - Saturn Return Detail Sheet
// ====================================
// Full-screen detail view for Saturn Return analysis

struct SaturnReturnDetailSheet: View {
    let stock: Stock
    let data: SaturnReturnData
    @State private var saturnService = SaturnReturnService.shared
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Hero section
                    heroSection

                    // Status section
                    statusSection

                    // Historical insight
                    historicalSection

                    // What to watch
                    watchSection

                    // Educational section
                    educationalSection
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .background(CosmicTheme.background.ignoresSafeArea())
            .navigationTitle("Saturn Return Analysis")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(CosmicTheme.gold)
                }
            }
            .toolbarBackground(CosmicTheme.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .onAppear {
            AnalyticsService.shared.track(.saturnReturnViewed, params: AnalyticsParameters([
                "symbol": stock.symbol,
                "status": data.status.rawValue
            ]))
        }
    }

    // MARK: - Hero Section

    private var heroSection: some View {
        VStack(spacing: 20) {
            // Saturn visualization
            ZStack {
                // Orbital rings
                ForEach(0..<3, id: \.self) { ring in
                    Circle()
                        .stroke(data.status.color.opacity(0.1 - Double(ring) * 0.03), lineWidth: 1)
                        .frame(width: 120 + CGFloat(ring) * 30, height: 120 + CGFloat(ring) * 30)
                }

                // Saturn ring effect
                Ellipse()
                    .stroke(data.status.color.opacity(0.4), lineWidth: 3)
                    .frame(width: 100, height: 30)

                // Planet
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                data.status.color.opacity(0.6),
                                data.status.color.opacity(0.3),
                                CosmicTheme.cardBackground
                            ],
                            center: .topLeading,
                            startRadius: 10,
                            endRadius: 50
                        )
                    )
                    .frame(width: 60, height: 60)
            }

            // Company info
            VStack(spacing: 8) {
                Text(stock.symbol)
                    .font(.system(size: 28, weight: .bold, design: .monospaced))
                    .foregroundColor(CosmicTheme.textPrimary)

                Text(stock.name)
                    .font(.subheadline)
                    .foregroundColor(CosmicTheme.textSecondary)

                Text("Founded \(formattedFoundingYear)")
                    .font(.caption)
                    .foregroundColor(CosmicTheme.textMuted)
            }
        }
        .padding(.vertical, 20)
    }

    private var formattedFoundingYear: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy"
        return formatter.string(from: data.foundingDate)
    }

    // MARK: - Status Section

    private var statusSection: some View {
        VStack(spacing: 16) {
            // Status badge
            HStack {
                Image(systemName: data.status.icon)
                    .foregroundColor(data.status.color)
                Text(data.status.rawValue.uppercased())
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(data.status.color)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(data.status.color.opacity(0.15))
            )

            // Key metrics
            HStack(spacing: 0) {
                metricBox(title: "Company Age", value: "\(Int(data.companyAgeYears))y", subtitle: data.formattedAge)

                Divider()
                    .frame(height: 50)
                    .background(CosmicTheme.borderDim)

                metricBox(title: "Saturn Return", value: "#\(data.currentSaturnReturnNumber)", subtitle: "Current cycle")

                Divider()
                    .frame(height: 50)
                    .background(CosmicTheme.borderDim)

                metricBox(title: "Next Return", value: formattedMonthsUntil, subtitle: data.formattedNextDate)
            }
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(CosmicTheme.cardBackground)
            )
        }
    }

    private func metricBox(title: String, value: String, subtitle: String) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption2)
                .foregroundColor(CosmicTheme.textMuted)

            Text(value)
                .font(.system(size: 20, weight: .bold, design: .monospaced))
                .foregroundColor(CosmicTheme.textPrimary)

            Text(subtitle)
                .font(.caption2)
                .foregroundColor(CosmicTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var formattedMonthsUntil: String {
        let calendar = Calendar.current
        let months = calendar.dateComponents([.month], from: Date(), to: data.nextSaturnReturnDate).month ?? 0
        if months <= 0 {
            return "Now"
        } else if months < 12 {
            return "\(months)mo"
        } else {
            let years = months / 12
            return "\(years)y"
        }
    }

    // MARK: - Historical Section

    private var historicalSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "Historical Context", icon: "book.fill")

            if let insight = saturnService.getHistoricalInsight(for: stock) {
                VStack(alignment: .leading, spacing: 12) {
                    Text(insight.insight)
                        .font(.subheadline)
                        .foregroundColor(CosmicTheme.textPrimary)
                        .lineSpacing(4)

                    if let event = insight.historicalEvent {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("What Happened")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(CosmicTheme.gold)

                            Text(event)
                                .font(.caption)
                                .foregroundColor(CosmicTheme.textSecondary)
                                .lineSpacing(3)
                        }
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(CosmicTheme.gold.opacity(0.08))
                        )
                    }

                    if let outcome = insight.outcome {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("The Outcome")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(CosmicTheme.positive)

                            Text(outcome)
                                .font(.caption)
                                .foregroundColor(CosmicTheme.textSecondary)
                                .lineSpacing(3)
                        }
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(CosmicTheme.positive.opacity(0.08))
                        )
                    }
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(CosmicTheme.cardBackground)
                )
            }
        }
    }

    // MARK: - Watch Section

    private var watchSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "What to Watch", icon: "eye.fill")

            VStack(spacing: 10) {
                watchItem(
                    icon: "person.2.fill",
                    title: "Leadership Changes",
                    description: "CEO transitions, board reshuffles, or founder returns"
                )

                watchItem(
                    icon: "arrow.triangle.branch",
                    title: "Strategic Pivots",
                    description: "New market launches, product line changes, or M&A activity"
                )

                watchItem(
                    icon: "chart.bar.doc.horizontal",
                    title: "Financial Restructuring",
                    description: "Cost cuts, spinoffs, or capital allocation shifts"
                )

                watchItem(
                    icon: "megaphone.fill",
                    title: "Brand Evolution",
                    description: "Rebranding, mission changes, or culture shifts"
                )
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(CosmicTheme.cardBackground)
            )
        }
    }

    private func watchItem(icon: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(data.status.color)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(CosmicTheme.textPrimary)

                Text(description)
                    .font(.caption2)
                    .foregroundColor(CosmicTheme.textSecondary)
            }

            Spacer()
        }
    }

    // MARK: - Educational Section

    private var educationalSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "About Saturn Returns", icon: "info.circle.fill")

            VStack(alignment: .leading, spacing: 12) {
                Text("In astrology, Saturn takes approximately 29.5 years to orbit the Sun and return to its original position. This 'Saturn Return' represents a period of maturation, testing, and transformation.")
                    .font(.caption)
                    .foregroundColor(CosmicTheme.textSecondary)
                    .lineSpacing(4)

                Text("For companies, this period often correlates with significant transitions — whether that's reinvention and growth, or stagnation and decline. The outcome depends on how the organization responds to the pressures of maturity.")
                    .font(.caption)
                    .foregroundColor(CosmicTheme.textSecondary)
                    .lineSpacing(4)

                // Disclaimer
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.caption)
                        .foregroundColor(.orange)

                    Text("This is for entertainment only. There is no scientific evidence that planetary positions affect corporate performance. Always do your own research.")
                        .font(.caption2)
                        .foregroundColor(CosmicTheme.textMuted)
                        .italic()
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.orange.opacity(0.08))
                )
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(CosmicTheme.cardBackground)
            )
        }
    }

    // MARK: - Helper

    private func sectionHeader(title: String, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(CosmicTheme.gold)

            Text(title)
                .font(TerminalFont.headline(14))
                .foregroundColor(CosmicTheme.textPrimary)
        }
    }
}
#Preview("Saturn Card") {
    SaturnReturnCard(stock: MockStockData.knownStocks.first!)
        .padding()
        .background(CosmicTheme.background)
        .preferredColorScheme(.dark)
}
