import SwiftUI

// MARK: - Karmic Ledger Views
// ============================
// UI components for the Karmic Ledger feature.
// Reframes losses as "cosmic lessons" with dark humor.

// MARK: - Karmic Ledger Card (for Profile/Portfolio)

struct KarmicLedgerCard: View {
    @State private var karmicService = KarmicLedgerService.shared
    @State private var showingLedger = false

    var body: some View {
        Button(action: { showingLedger = true }) {
            HStack(spacing: 12) {
                // Icon
                ZStack {
                    Circle()
                        .fill(Color.purple.opacity(0.2))
                        .frame(width: 44, height: 44)

                    Image(systemName: "book.closed.fill")
                        .font(.title3)
                        .foregroundColor(.purple)
                }

                // Content
                VStack(alignment: .leading, spacing: 4) {
                    Text("Karmic Ledger")
                        .font(TerminalFont.body(14))
                        .foregroundColor(CosmicTheme.textPrimary)

                    if karmicService.lessonsLearned > 0 {
                        Text("\(karmicService.lessonsLearned) lessons · \(karmicService.formattedTotalTuition) tuition")
                            .font(TerminalFont.caption(12))
                            .foregroundColor(CosmicTheme.textSecondary)
                    } else {
                        Text("No cosmic lessons yet")
                            .font(TerminalFont.caption(12))
                            .foregroundColor(CosmicTheme.textMuted)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(CosmicTheme.textMuted)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(CosmicTheme.cardBackground)
            )
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showingLedger) {
            KarmicLedgerSheet()
        }
    }
}

// MARK: - Karmic Ledger Sheet

struct KarmicLedgerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var karmicService = KarmicLedgerService.shared
    @State private var showingWisdom = false
    @State private var showingAddEntry = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Header stats
                    tuitionHeader

                    if karmicService.entries.isEmpty {
                        emptyState
                    } else {
                        // Wisdom button
                        wisdomButton

                        // Recent lessons
                        lessonsSection
                    }

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 16)
                .padding(.top, 20)
            }
            .background(CosmicTheme.background.ignoresSafeArea())
            .navigationTitle("Karmic Ledger")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") { dismiss() }
                        .foregroundColor(CosmicTheme.gold)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { showingAddEntry = true }) {
                        Image(systemName: "plus")
                            .foregroundColor(CosmicTheme.gold)
                    }
                }
            }
            .toolbarBackground(CosmicTheme.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
        .sheet(isPresented: $showingWisdom) {
            KarmicWisdomSheet()
        }
        .sheet(isPresented: $showingAddEntry) {
            AddKarmicEntrySheet()
        }
        .onAppear {
            AnalyticsService.shared.track(.karmicLedgerViewed)
        }
    }

    // MARK: - Tuition Header

    private var tuitionHeader: some View {
        VStack(spacing: 16) {
            // Book icon
            ZStack {
                Circle()
                    .fill(Color.purple.opacity(0.15))
                    .frame(width: 80, height: 80)

                Image(systemName: "book.closed.fill")
                    .font(.system(size: 36))
                    .foregroundColor(.purple)
            }

            // Title
            VStack(spacing: 4) {
                Text("Tuition Paid to the Universe")
                    .font(TerminalFont.caption(12))
                    .foregroundColor(CosmicTheme.textSecondary)

                Text(karmicService.formattedTotalTuition)
                    .font(.system(size: 36, weight: .bold, design: .monospaced))
                    .foregroundColor(CosmicTheme.negative)
            }

            // Stats row
            HStack(spacing: 24) {
                StatBadge(
                    value: "\(karmicService.lessonsLearned)",
                    label: "Lessons"
                )

                if let biggest = karmicService.biggestLesson {
                    StatBadge(
                        value: biggest.formattedLoss,
                        label: "Biggest"
                    )
                }

                if let troublesome = karmicService.troublesomeElement {
                    StatBadge(
                        value: troublesome.element.emoji,
                        label: "Trouble"
                    )
                }
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(CosmicTheme.cardBackground)
        )
    }

    // MARK: - Wisdom Button

    private var wisdomButton: some View {
        Button(action: { showingWisdom = true }) {
            HStack(spacing: 12) {
                Image(systemName: "sparkles")
                    .font(.body)
                    .foregroundColor(CosmicTheme.gold)

                Text("View Cosmic Wisdom")
                    .font(TerminalFont.body(14))
                    .foregroundColor(CosmicTheme.gold)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(CosmicTheme.gold.opacity(0.6))
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(CosmicTheme.gold.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(CosmicTheme.gold.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Lessons Section

    private var lessonsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("LESSONS LEARNED")
                .font(TerminalFont.caption(12))
                .foregroundColor(CosmicTheme.textMuted)
                .padding(.leading, 4)

            ForEach(karmicService.entries.sorted(by: { $0.saleDate > $1.saleDate })) { entry in
                KarmicEntryRow(entry: entry)
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 48))
                .foregroundColor(CosmicTheme.positive)

            Text("Your Karmic Ledger is Clean")
                .font(TerminalFont.body(14))
                .foregroundColor(CosmicTheme.textPrimary)

            Text("No cosmic lessons recorded yet.\nMay your portfolio remain in the green.")
                .font(TerminalFont.caption(12))
                .foregroundColor(CosmicTheme.textSecondary)
                .multilineTextAlignment(.center)

            Button(action: { showingAddEntry = true }) {
                Text("Record a Past Lesson")
                    .font(TerminalFont.caption(12))
                    .foregroundColor(CosmicTheme.gold)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .stroke(CosmicTheme.gold.opacity(0.5), lineWidth: 1)
                    )
            }
            .padding(.top, 8)
        }
        .padding(40)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(CosmicTheme.cardBackground)
        )
    }
}

// MARK: - Stat Badge

private struct StatBadge: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(TerminalFont.body(14))
                .fontWeight(.semibold)
                .foregroundColor(CosmicTheme.textPrimary)

            Text(label)
                .font(TerminalFont.caption(10))
                .foregroundColor(CosmicTheme.textMuted)
        }
    }
}

// MARK: - Karmic Entry Row

struct KarmicEntryRow: View {
    let entry: KarmicEntry
    @State private var showingDetail = false

    var body: some View {
        Button(action: { showingDetail = true }) {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack {
                    // Stock info
                    HStack(spacing: 8) {
                        Text(entry.stockSign.symbol)
                            .font(.title3)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(entry.stockSymbol)
                                .font(TerminalFont.body(14))
                                .fontWeight(.semibold)
                                .foregroundColor(CosmicTheme.textPrimary)

                            Text(entry.shortDate)
                                .font(TerminalFont.caption(10))
                                .foregroundColor(CosmicTheme.textMuted)
                        }
                    }

                    Spacer()

                    // Loss amount
                    Text("-\(entry.formattedLoss)")
                        .font(TerminalFont.body(14))
                        .fontWeight(.medium)
                        .foregroundColor(CosmicTheme.negative)
                }

                // Lesson
                Text("\"\(entry.lesson)\"")
                    .font(TerminalFont.caption(12))
                    .foregroundColor(CosmicTheme.textSecondary)
                    .italic()
                    .lineLimit(3)

                // Cosmic conditions
                HStack(spacing: 8) {
                    ConditionPill(text: entry.moonPhase.rawValue, icon: entry.moonPhase.icon)
                    ConditionPill(text: entry.moonSign.displayName, icon: "moon.fill")

                    if entry.isMercuryRetrograde {
                        ConditionPill(text: "Rx", icon: "arrow.triangle.2.circlepath", isWarning: true)
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(CosmicTheme.cardBackground)
            )
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showingDetail) {
            KarmicEntryDetailSheet(entry: entry)
        }
    }
}

// MARK: - Condition Pill

private struct ConditionPill: View {
    let text: String
    let icon: String
    var isWarning: Bool = false

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)

            Text(text)
                .font(TerminalFont.caption(10))
        }
        .foregroundColor(isWarning ? .orange : CosmicTheme.textMuted)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill((isWarning ? Color.orange : CosmicTheme.textMuted).opacity(0.15))
        )
    }
}

// MARK: - Karmic Entry Detail Sheet

struct KarmicEntryDetailSheet: View {
    let entry: KarmicEntry
    @Environment(\.dismiss) private var dismiss
    @State private var karmicService = KarmicLedgerService.shared
    @State private var showingDeleteConfirm = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Stock header
                    VStack(spacing: 12) {
                        Text(entry.stockSign.symbol)
                            .font(.system(size: 56))

                        Text(entry.stockSymbol)
                            .font(.system(size: 24, weight: .bold, design: .monospaced))
                            .foregroundColor(CosmicTheme.textPrimary)

                        Text(entry.stockName)
                            .font(TerminalFont.caption(12))
                            .foregroundColor(CosmicTheme.textSecondary)
                    }
                    .padding(.top, 20)

                    // Loss amount
                    VStack(spacing: 4) {
                        Text("COSMIC TUITION")
                            .font(TerminalFont.caption(10))
                            .foregroundColor(CosmicTheme.textMuted)

                        Text("-\(entry.formattedLoss)")
                            .font(.system(size: 32, weight: .bold, design: .monospaced))
                            .foregroundColor(CosmicTheme.negative)
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(CosmicTheme.negative.opacity(0.1))
                    )

                    // Lesson
                    VStack(alignment: .leading, spacing: 8) {
                        Text("THE LESSON")
                            .font(TerminalFont.caption(10))
                            .foregroundColor(CosmicTheme.textMuted)

                        Text(entry.lesson)
                            .font(TerminalFont.body(14))
                            .foregroundColor(CosmicTheme.textPrimary)
                            .italic()
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(CosmicTheme.cardBackground)
                    )

                    // Cosmic conditions
                    VStack(alignment: .leading, spacing: 12) {
                        Text("COSMIC CONDITIONS AT TIME OF SALE")
                            .font(TerminalFont.caption(10))
                            .foregroundColor(CosmicTheme.textMuted)

                        VStack(spacing: 0) {
                            DetailRow(label: "Date", value: entry.formattedDate)
                            Divider().background(CosmicTheme.textMuted.opacity(0.2))
                            DetailRow(label: "Moon Phase", value: entry.moonPhase.rawValue)
                            Divider().background(CosmicTheme.textMuted.opacity(0.2))
                            DetailRow(label: "Moon Sign", value: entry.moonSign.displayName)
                            Divider().background(CosmicTheme.textMuted.opacity(0.2))
                            DetailRow(label: "Stock Sign", value: "\(entry.stockSign.symbol) \(entry.stockSign.displayName)")
                            Divider().background(CosmicTheme.textMuted.opacity(0.2))
                            DetailRow(label: "Mercury Retrograde", value: entry.isMercuryRetrograde ? "Yes" : "No")
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(CosmicTheme.cardBackground)
                        )
                    }

                    // Delete button
                    Button(action: { showingDeleteConfirm = true }) {
                        Text("Delete Lesson")
                            .font(TerminalFont.caption(12))
                            .foregroundColor(CosmicTheme.negative)
                    }
                    .padding(.top, 20)

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 16)
            }
            .background(CosmicTheme.background.ignoresSafeArea())
            .navigationTitle("Lesson Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(CosmicTheme.gold)
                }
            }
            .toolbarBackground(CosmicTheme.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .alert("Delete Lesson?", isPresented: $showingDeleteConfirm) {
                Button("Delete", role: .destructive) {
                    karmicService.deleteEntry(entry)
                    dismiss()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This will remove the lesson from your Karmic Ledger.")
            }
        }
    }
}

// MARK: - Detail Row

private struct DetailRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(TerminalFont.caption(12))
                .foregroundColor(CosmicTheme.textSecondary)

            Spacer()

            Text(value)
                .font(TerminalFont.caption(12))
                .foregroundColor(CosmicTheme.textPrimary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

// MARK: - Karmic Wisdom Sheet

struct KarmicWisdomSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var karmicService = KarmicLedgerService.shared

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    let wisdom = karmicService.getKarmicWisdom()

                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 48))
                            .foregroundColor(CosmicTheme.gold)

                        Text("Cosmic Wisdom")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(CosmicTheme.textPrimary)
                    }
                    .padding(.top, 20)

                    // Overall wisdom
                    Text(wisdom.overallWisdom)
                        .font(TerminalFont.body(14))
                        .foregroundColor(CosmicTheme.textSecondary)
                        .multilineTextAlignment(.center)
                        .italic()
                        .padding(.horizontal, 20)

                    // Element breakdown
                    if !wisdom.elementBreakdown.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("LOSSES BY ELEMENT")
                                .font(TerminalFont.caption(10))
                                .foregroundColor(CosmicTheme.textMuted)

                            // Sort elements by loss amount (descending) with safe optional handling
                            let sortedElements = wisdom.elementBreakdown.keys.sorted { element1, element2 in
                                let amount1 = wisdom.elementBreakdown[element1] ?? 0
                                let amount2 = wisdom.elementBreakdown[element2] ?? 0
                                return amount1 > amount2
                            }

                            ForEach(sortedElements, id: \.self) { element in
                                ElementLossRow(
                                    element: element,
                                    amount: wisdom.elementBreakdown[element] ?? 0,
                                    total: wisdom.totalTuition
                                )
                            }
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(CosmicTheme.cardBackground)
                        )
                    }

                    // Patterns
                    if !wisdom.patterns.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("PATTERNS DETECTED")
                                .font(TerminalFont.caption(10))
                                .foregroundColor(CosmicTheme.textMuted)

                            ForEach(wisdom.patterns, id: \.self) { pattern in
                                HStack(alignment: .top, spacing: 12) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .font(.caption)
                                        .foregroundColor(.orange)

                                    Text(pattern)
                                        .font(TerminalFont.caption(12))
                                        .foregroundColor(CosmicTheme.textSecondary)
                                }
                                .padding(12)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.orange.opacity(0.1))
                                )
                            }
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(CosmicTheme.cardBackground)
                        )
                    }

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 16)
            }
            .background(CosmicTheme.background.ignoresSafeArea())
            .navigationTitle("Wisdom")
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
        .onAppear {
            AnalyticsService.shared.track(.karmicWisdomViewed)
        }
    }
}

// MARK: - Element Loss Row

private struct ElementLossRow: View {
    let element: ZodiacSign.Element
    let amount: Double
    let total: Double

    private var percentage: Double {
        guard total > 0 else { return 0 }
        return amount / total
    }

    private var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: amount)) ?? "$0.00"
    }

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                HStack(spacing: 8) {
                    Text(element.emoji)
                    Text(element.displayName)
                        .font(TerminalFont.body(14))
                        .foregroundColor(CosmicTheme.textPrimary)
                }

                Spacer()

                Text(formattedAmount)
                    .font(TerminalFont.body(14))
                    .foregroundColor(CosmicTheme.negative)
            }

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(CosmicTheme.textMuted.opacity(0.2))
                        .frame(height: 6)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(element.color)
                        .frame(width: geometry.size.width * percentage, height: 6)
                }
            }
            .frame(height: 6)
        }
    }
}

// MARK: - Add Karmic Entry Sheet

struct AddKarmicEntrySheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var karmicService = KarmicLedgerService.shared

    @State private var symbol = ""
    @State private var name = ""
    @State private var selectedSign: ZodiacSign = .aries
    @State private var lossAmount = ""
    @State private var saleDate = Date()

    var body: some View {
        NavigationStack {
            Form {
                Section("Stock Information") {
                    TextField("Symbol (e.g., RIVN)", text: $symbol)
                        .textInputAutocapitalization(.characters)
                        .onChange(of: symbol) { _, newValue in
                            if newValue.count > 10 {
                                symbol = String(newValue.prefix(10))
                            }
                            symbol = newValue.uppercased()
                        }

                    TextField("Company Name", text: $name)
                        .onChange(of: name) { _, newValue in
                            if newValue.count > 100 {
                                name = String(newValue.prefix(100))
                            }
                        }

                    Picker("Zodiac Sign", selection: $selectedSign) {
                        ForEach(ZodiacSign.allCases, id: \.self) { sign in
                            Text("\(sign.symbol) \(sign.displayName)").tag(sign)
                        }
                    }
                }

                Section("Loss Details") {
                    TextField("Loss Amount ($)", text: $lossAmount)
                        .keyboardType(.decimalPad)
                        .onChange(of: lossAmount) { _, newValue in
                            // Only allow valid decimal input
                            let filtered = newValue.filter { $0.isNumber || $0 == "." }
                            if filtered != newValue || newValue.filter({ $0 == "." }).count > 1 {
                                lossAmount = String(filtered.prefix(while: { $0.isNumber || $0 == "." }))
                            }
                            if filtered.count > 15 {
                                lossAmount = String(filtered.prefix(15))
                            }
                        }

                    DatePicker("Sale Date", selection: $saleDate, displayedComponents: .date)
                }
            }
            .scrollContentBackground(.hidden)
            .background(CosmicTheme.background.ignoresSafeArea())
            .navigationTitle("Record Lesson")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(CosmicTheme.textSecondary)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        saveEntry()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(CosmicTheme.gold)
                    .disabled(!isValid)
                }
            }
            .toolbarBackground(CosmicTheme.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
    }

    private var isValid: Bool {
        !symbol.isEmpty && !lossAmount.isEmpty && (Double(lossAmount) ?? 0) > 0
    }

    private func saveEntry() {
        guard let amount = Double(lossAmount), amount > 0 else { return }

        karmicService.recordManualLoss(
            symbol: symbol.uppercased(),
            name: name.isEmpty ? symbol.uppercased() : name,
            sign: selectedSign,
            lossAmount: amount,
            saleDate: saleDate
        )

        dismiss()
    }
}

// MARK: - Karmic Ledger Banner (for Portfolio)

struct KarmicLedgerBanner: View {
    @State private var karmicService = KarmicLedgerService.shared
    @State private var showingLedger = false

    var body: some View {
        if karmicService.lessonsLearned > 0 {
            Button(action: { showingLedger = true }) {
                HStack(spacing: 12) {
                    Image(systemName: "book.closed.fill")
                        .font(.title3)
                        .foregroundColor(.purple)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Karmic Ledger")
                            .font(TerminalFont.caption(12))
                            .foregroundColor(CosmicTheme.textPrimary)

                        Text("Tuition: \(karmicService.formattedTotalTuition)")
                            .font(TerminalFont.caption(10))
                            .foregroundColor(CosmicTheme.textSecondary)
                    }

                    Spacer()

                    Text("\(karmicService.lessonsLearned) lessons")
                        .font(TerminalFont.caption(10))
                        .foregroundColor(CosmicTheme.textMuted)

                    Image(systemName: "chevron.right")
                        .font(.caption2)
                        .foregroundColor(CosmicTheme.textMuted)
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.purple.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.purple.opacity(0.3), lineWidth: 1)
                        )
                )
            }
            .buttonStyle(.plain)
            .sheet(isPresented: $showingLedger) {
                KarmicLedgerSheet()
            }
        }
    }
}

// MARK: - Previews

#Preview("Karmic Ledger Card") {
    VStack {
        KarmicLedgerCard()
    }
    .padding()
    .background(CosmicTheme.background)
    .preferredColorScheme(.dark)
}

#Preview("Karmic Ledger Sheet") {
    KarmicLedgerSheet()
        .preferredColorScheme(.dark)
}
