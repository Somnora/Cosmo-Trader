import SwiftUI

// MARK: - HoldingSharesInput
// ==========================
// Validation rules for manually edited holdings. Pure + nonisolated so the
// rules are unit-testable without UI (see HoldingSharesEditorTests).

nonisolated enum HoldingSharesInput {

    /// Upper bound guards against an extra-digit typo creating a holding
    /// that dwarfs every market-value-weighted computation downstream.
    static let maximumShares: Double = 1_000_000_000

    /// Upper bound for a per-share cost basis in dollars.
    static let maximumCostBasisPerShare: Double = 10_000_000

    enum CostBasis: Equatable {
        /// Empty field — the user doesn't know it. P/L stays unavailable
        /// rather than guessed.
        case unknown
        case value(Double)
        case invalid
    }

    /// Parses a user-typed share count. Rejects empty, non-numeric, zero,
    /// negative, and out-of-range values.
    static func parseShares(_ text: String) -> Double? {
        guard let value = parseDecimal(text), value > 0, value <= maximumShares else {
            return nil
        }
        return value
    }

    /// Parses the optional cost-basis field. Zero is allowed (gifted or
    /// award shares have a real zero basis).
    static func costBasis(from text: String) -> CostBasis {
        if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return .unknown
        }
        guard let value = parseDecimal(text), value >= 0, value <= maximumCostBasisPerShare else {
            return .invalid
        }
        return .value(value)
    }

    /// Formats a share count for display and for prefilling the editor
    /// field: whole counts stay whole, fractional counts keep up to four
    /// decimals with trailing zeros trimmed (matches import review).
    static func displayShares(_ value: Double) -> String {
        if value == value.rounded() {
            return String(format: "%.0f", value)
        }
        var text = String(format: "%.4f", value)
        while text.hasSuffix("0") { text.removeLast() }
        if text.hasSuffix(".") { text.removeLast() }
        return text
    }

    /// Decimal-pad input arrives with the user's locale separator: "2,5"
    /// means two and a half on a comma-locale keyboard. A comma is only a
    /// grouping separator when a period is also present ("1,234.5").
    private static func parseDecimal(_ raw: String) -> Double? {
        var text = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        text = text.replacingOccurrences(of: "$", with: "")
        text = text.replacingOccurrences(of: " ", with: "")
        if text.contains(","), text.contains(".") {
            text = text.replacingOccurrences(of: ",", with: "")
        } else if text.contains(",") {
            text = text.replacingOccurrences(of: ",", with: ".")
        }
        guard let value = Double(text), value.isFinite else { return nil }
        return value
    }
}

// MARK: - HoldingSharesEditorView
// ===============================
// Bottom-sheet editor for one holding's share count and optional cost
// basis. Presented from StockDetailView (add + edit) and from a long-press
// on a PortfolioView holdings row (edit). Removal lives here too, behind a
// confirmation dialog, so every surface shares one code path.

struct HoldingSharesEditorView: View {

    let symbol: String
    let name: String
    /// nil when the stock is not in the portfolio yet (add flow).
    let currentShares: Double?
    let currentCostBasis: Double?
    let onSave: (_ shares: Double, _ costBasisPerShare: Double?) -> Void
    /// nil hides the remove option (add flow).
    let onRemove: (() -> Void)?

    @Environment(\.dismiss) private var dismiss
    @State private var sharesText: String
    @State private var costBasisText: String
    @State private var showRemoveConfirmation = false
    @FocusState private var focusedField: Field?

    private enum Field { case shares, costBasis }

    init(
        symbol: String,
        name: String,
        currentShares: Double? = nil,
        currentCostBasis: Double? = nil,
        onSave: @escaping (_ shares: Double, _ costBasisPerShare: Double?) -> Void,
        onRemove: (() -> Void)? = nil
    ) {
        self.symbol = symbol
        self.name = name
        self.currentShares = currentShares
        self.currentCostBasis = currentCostBasis
        self.onSave = onSave
        self.onRemove = onRemove
        _sharesText = State(initialValue: currentShares.map(HoldingSharesInput.displayShares) ?? "1")
        _costBasisText = State(initialValue: currentCostBasis.map { String(format: "%.2f", $0) } ?? "")
    }

    private var isEditing: Bool { currentShares != nil }
    private var parsedShares: Double? { HoldingSharesInput.parseShares(sharesText) }
    private var costBasis: HoldingSharesInput.CostBasis { HoldingSharesInput.costBasis(from: costBasisText) }
    private var canSave: Bool { parsedShares != nil && costBasis != .invalid }

    var body: some View {
        NavigationStack {
            ZStack {
                CosmicTheme.background.ignoresSafeArea()

                VStack(alignment: .leading, spacing: 20) {
                    header
                    fieldsCard
                    footnote

                    Spacer()

                    if onRemove != nil {
                        removeButton
                    }
                }
                .padding(20)
            }
            .navigationTitle(isEditing ? "Edit Shares" : "Add Holding")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(CosmicTheme.textSecondary)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? "Save" : "Add") { commit() }
                        .fontWeight(.semibold)
                        .foregroundColor(canSave ? CosmicTheme.gold : CosmicTheme.textMuted)
                        .disabled(!canSave)
                        .accessibilityIdentifier("holding.sharesEditor.save")
                }

                // The decimal pad has no return key; give the keyboard an
                // explicit dismiss so the Remove button stays reachable.
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { focusedField = nil }
                        .foregroundColor(CosmicTheme.gold)
                }
            }
            .toolbarBackground(CosmicTheme.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .confirmationDialog(
                "Remove \(symbol) from your portfolio?",
                isPresented: $showRemoveConfirmation,
                titleVisibility: .visible
            ) {
                Button("Remove \(symbol)", role: .destructive) {
                    onRemove?()
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Readings weighted by your holdings stop counting \(symbol). You can add it back anytime.")
            }
        }
        .presentationDetents([.medium])
        .onAppear { focusedField = .shares }
    }

    // MARK: - Sections

    private var header: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(symbol)
                    .font(TerminalFont.headline(18))
                    .foregroundColor(CosmicTheme.textPrimary)

                Text(name)
                    .font(TerminalFont.data(12))
                    .foregroundColor(CosmicTheme.textSecondary)
                    .lineLimit(1)
            }

            Spacer()
        }
        .padding(16)
        .background(CosmicTheme.cardBackground)
    }

    private var fieldsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text("SHARES OWNED")
                    .font(TerminalFont.data(10, weight: .semibold))
                    .foregroundColor(CosmicTheme.textMuted)
                    .tracking(1)

                TextField("10 or 2.5", text: $sharesText)
                    .keyboardType(.decimalPad)
                    .font(TerminalFont.price(16))
                    .foregroundColor(parsedShares != nil ? CosmicTheme.textPrimary : CosmicTheme.negative)
                    .focused($focusedField, equals: .shares)
                    .accessibilityIdentifier("holding.sharesEditor.shares")

                if parsedShares == nil {
                    Text("Enter a share count above zero.")
                        .font(TerminalFont.data(10))
                        .foregroundColor(CosmicTheme.negative)
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("COST BASIS / SHARE (OPTIONAL)")
                    .font(TerminalFont.data(10, weight: .semibold))
                    .foregroundColor(CosmicTheme.textMuted)
                    .tracking(1)

                TextField("What you paid per share", text: $costBasisText)
                    .keyboardType(.decimalPad)
                    .font(TerminalFont.price(16))
                    .foregroundColor(costBasis == .invalid ? CosmicTheme.negative : CosmicTheme.textPrimary)
                    .focused($focusedField, equals: .costBasis)
                    .accessibilityIdentifier("holding.sharesEditor.costBasis")

                if costBasis == .invalid {
                    Text("Enter a dollar amount, or leave this empty.")
                        .font(TerminalFont.data(10))
                        .foregroundColor(CosmicTheme.negative)
                }
            }
        }
        .padding(16)
        .background(CosmicTheme.cardBackground)
    }

    private var footnote: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "info.circle")
                .font(.caption)
                .foregroundColor(CosmicTheme.textMuted)

            Text("Fractional shares are fine. Cosmo weights your readings by what you own. If you skip cost basis, P/L shows as unavailable instead of guessing.")
                .font(TerminalFont.data(11))
                .foregroundColor(CosmicTheme.textMuted)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var removeButton: some View {
        Button {
            showRemoveConfirmation = true
        } label: {
            HStack {
                Image(systemName: "trash")
                Text("Remove from Portfolio")
                    .fontWeight(.medium)
            }
            .font(TerminalFont.data(13, weight: .semibold))
            .foregroundColor(CosmicTheme.negative)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(CosmicTheme.negative.opacity(0.5), lineWidth: 1)
            )
        }
        .accessibilityIdentifier("holding.sharesEditor.remove")
    }

    private func commit() {
        guard let shares = parsedShares else { return }
        let basis: Double?
        if case .value(let amount) = costBasis {
            basis = amount
        } else {
            basis = nil
        }
        onSave(shares, basis)
        dismiss()
    }
}

#Preview("Edit") {
    HoldingSharesEditorView(
        symbol: "AAPL",
        name: "Apple Inc.",
        currentShares: 12.5,
        currentCostBasis: 150,
        onSave: { _, _ in },
        onRemove: {}
    )
}

#Preview("Add") {
    HoldingSharesEditorView(
        symbol: "MSFT",
        name: "Microsoft Corporation",
        onSave: { _, _ in }
    )
}
