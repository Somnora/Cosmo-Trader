import SwiftUI

struct ImportReviewView: View {
    let parsedPortfolio: ParsedPortfolio
    var onComplete: () -> Void = {}
    var onCancel: () -> Void = {}

    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    @State private var holdings: [ReviewedImportHolding]
    @State private var livePrices: [String: Double] = [:]
    @State private var quoteProvenanceBySymbol: [String: FinancialDataProvenance] = [:]
    @State private var isFetchingQuotes = false
    @State private var pendingCommitMode: PortfolioImportCommitMode?

    init(
        parsedPortfolio: ParsedPortfolio,
        onComplete: @escaping () -> Void = {},
        onCancel: @escaping () -> Void = {}
    ) {
        self.parsedPortfolio = parsedPortfolio
        self.onComplete = onComplete
        self.onCancel = onCancel
        _holdings = State(initialValue: parsedPortfolio.holdings.map { ReviewedImportHolding(holding: $0) })
    }

    private var reviewedParsedHoldings: [ParsedHolding] {
        holdings.compactMap(\.parsedHolding)
    }

    private var committableHoldings: [ParsedHolding] {
        reviewedParsedHoldings.filter { $0.shares > 0 }
    }

    private var existingHoldingCount: Int {
        appState.currentUser?.portfolio.count ?? 0
    }

    private var quoteBatchProvenance: FinancialDataProvenance {
        let provenances = holdings.compactMap { quoteProvenanceBySymbol[$0.symbol.uppercased()] }

        if let live = provenances.first(where: { if case .live = $0 { return true }; return false }) {
            return live
        }
        if let cached = provenances.first(where: { if case .cached = $0 { return true }; return false }) {
            return cached
        }
        if holdings.isEmpty {
            return .unavailable(reason: "No imported holdings to quote")
        }
        return .unavailable(reason: "Provider quotes unavailable for imported holdings")
    }

    var body: some View {
        ZStack {
            CosmicTheme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 16) {
                        summaryBanner

                        if holdings.isEmpty {
                            emptyState
                        } else {
                            holdingsSection
                            unparsedLinesSection
                        }
                    }
                    .padding(16)
                }

                bottomActions
            }
        }
        .navigationTitle("Review Import")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await fetchLivePrices()
        }
        .sheet(item: $pendingCommitMode) { mode in
            ImportCommitConfirmationSheet(
                mode: mode,
                existingCount: existingHoldingCount,
                importedCount: committableHoldings.count,
                onCancel: { pendingCommitMode = nil },
                onConfirm: {
                    pendingCommitMode = nil
                    commitPortfolio(mode: mode)
                }
            )
            .presentationDetents([.height(260)])
        }
    }

    private var summaryBanner: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "doc.text.magnifyingglass")
                    .font(.title3)
                    .foregroundColor(confidenceColor(parsedPortfolio.overallConfidence))
                    .frame(width: 28, height: 28)

                VStack(alignment: .leading, spacing: 4) {
                    Text(parsedPortfolio.broker.uppercased())
                        .font(TerminalFont.data(12, weight: .semibold))
                        .foregroundColor(CosmicTheme.textPrimary)
                        .tracking(1)

                    Text("\(holdings.count) parsed rows")
                        .font(TerminalFont.data(10))
                        .foregroundColor(CosmicTheme.textMuted)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(Int(parsedPortfolio.overallConfidence * 100))%")
                        .font(TerminalFont.price(18))
                        .foregroundColor(confidenceColor(parsedPortfolio.overallConfidence))

                    Text("CONFIDENCE")
                        .font(TerminalFont.data(8))
                        .foregroundColor(CosmicTheme.textMuted)
                        .tracking(0.8)
                }
            }

            HStack(spacing: 8) {
                DataSourceIndicator(provenance: quoteBatchProvenance, size: .compact)

                if isFetchingQuotes {
                    ProgressView()
                        .scaleEffect(0.7)
                        .tint(CosmicTheme.gold)
                }

                Spacer()
            }
        }
        .padding(14)
        .background(CosmicTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(confidenceColor(parsedPortfolio.overallConfidence).opacity(0.35), lineWidth: 1)
        )
    }

    private var holdingsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("REVIEW HOLDINGS")
                    .font(TerminalFont.data(10, weight: .semibold))
                    .foregroundColor(CosmicTheme.textMuted)
                    .tracking(1)

                Spacer()

                Text("\(committableHoldings.count) ready")
                    .font(TerminalFont.data(10))
                    .foregroundColor(CosmicTheme.textMuted)
            }
            .padding(12)

            Rectangle()
                .fill(CosmicTheme.border)
                .frame(height: 1)

            ForEach($holdings) { $holding in
                ImportReviewHoldingRow(
                    holding: $holding,
                    livePrice: livePrices[holding.symbol.uppercased()],
                    quoteProvenance: quoteProvenanceBySymbol[holding.symbol.uppercased()],
                    onDelete: {
                        holdings.removeAll { $0.id == holding.id }
                    }
                )

                if holding.id != holdings.last?.id {
                    Rectangle()
                        .fill(CosmicTheme.border.opacity(0.55))
                        .frame(height: 1)
                }
            }
        }
        .background(CosmicTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(CosmicTheme.border, lineWidth: 1)
        )
    }

    private var unparsedLinesSection: some View {
        DisclosureGroup {
            VStack(alignment: .leading, spacing: 8) {
                if parsedPortfolio.unparsedLines.isEmpty {
                    Text("No skipped lines reported.")
                        .font(TerminalFont.data(11))
                        .foregroundColor(CosmicTheme.textMuted)
                } else {
                    ForEach(Array(parsedPortfolio.unparsedLines.enumerated()), id: \.offset) { _, line in
                        Text(line)
                            .font(TerminalFont.data(10))
                            .foregroundColor(CosmicTheme.textSecondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 2)
                    }
                }
            }
            .padding(.top, 8)
        } label: {
            HStack {
                Text("SKIPPED / UNPARSED LINES")
                    .font(TerminalFont.data(10, weight: .semibold))
                    .tracking(1)

                Spacer()

                Text("\(parsedPortfolio.unparsedLines.count)")
                    .font(TerminalFont.price(11))
            }
            .foregroundColor(CosmicTheme.textMuted)
        }
        .padding(12)
        .background(CosmicTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(CosmicTheme.border, lineWidth: 1)
        )
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "exclamationmark.magnifyingglass")
                .font(.system(size: 28))
                .foregroundColor(CosmicTheme.gold)

            Text("No holdings parsed")
                .font(TerminalFont.data(14, weight: .semibold))
                .foregroundColor(CosmicTheme.textPrimary)

            Text("Try a positions export from thinkorswim or Schwab with Symbol/Instrument and Quantity columns visible.")
                .font(TerminalFont.data(11))
                .foregroundColor(CosmicTheme.textSecondary)
                .multilineTextAlignment(.center)

            Button("Back to import picker") {
                onCancel()
                dismiss()
            }
            .font(TerminalFont.data(12, weight: .semibold))
            .foregroundColor(CosmicTheme.gold)
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(CosmicTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(CosmicTheme.border, lineWidth: 1)
        )
    }

    private var bottomActions: some View {
        VStack(spacing: 10) {
            Button(action: {
                pendingCommitMode = .append
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "plus.rectangle.on.folder")
                    Text("Append to portfolio")
                }
                .font(TerminalFont.data(13, weight: .semibold))
                .foregroundColor(CosmicTheme.background)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
                .background(committableHoldings.isEmpty ? CosmicTheme.textMuted : CosmicTheme.gold)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .disabled(committableHoldings.isEmpty)

            Button(action: {
                pendingCommitMode = .replace
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                    Text("Replace my portfolio")
                }
                .font(TerminalFont.data(13, weight: .semibold))
                .foregroundColor(CosmicTheme.negative)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(committableHoldings.isEmpty ? CosmicTheme.textMuted : CosmicTheme.negative.opacity(0.65), lineWidth: 1)
                )
            }
            .disabled(committableHoldings.isEmpty)

            Button(action: {
                onCancel()
                dismiss()
            }) {
                Text("Cancel")
                    .font(TerminalFont.data(12, weight: .semibold))
                    .foregroundColor(CosmicTheme.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
            }
        }
        .padding(16)
        .background(CosmicTheme.background)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(CosmicTheme.border)
                .frame(height: 1)
        }
    }

    private func fetchLivePrices() async {
        let symbols = Array(Set(holdings.map { $0.symbol.uppercased() })).filter { !$0.isEmpty }
        guard !symbols.isEmpty else { return }

        isFetchingQuotes = true
        let results = await StockAPIService.shared.getMultipleQuoteResults(symbols: symbols)
        livePrices = results.compactMapValues { $0.quote?.currentPrice }
        quoteProvenanceBySymbol = results.mapValues { result in
            result.quote == nil
                ? .unavailable(reason: result.error?.cosmicMessage ?? "Provider quote unavailable")
                : result.provenance
        }
        isFetchingQuotes = false
    }

    private func commitPortfolio(mode: PortfolioImportCommitMode) {
        PortfolioImportService.commitPortfolio(
            with: committableHoldings,
            in: appState,
            mode: mode,
            livePrices: livePrices
        )
        onComplete()
        dismiss()
    }

    private func confidenceColor(_ confidence: Double) -> Color {
        if confidence >= 0.8 { return CosmicTheme.positive }
        if confidence >= 0.5 { return CosmicTheme.gold }
        return CosmicTheme.negative
    }
}

private struct ImportReviewHoldingRow: View {
    @Binding var holding: ReviewedImportHolding
    let livePrice: Double?
    let quoteProvenance: FinancialDataProvenance?
    let onDelete: () -> Void

    private var shares: Double? {
        Double(holding.sharesText.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    private var csvMarketValueText: String {
        holding.csvMarketValue.map(Self.formatCurrency) ?? "-"
    }

    private var liveMarketValueText: String {
        guard let shares, shares > 0, let livePrice, livePrice > 0 else { return "—" }
        return Self.formatCurrency(shares * livePrice)
    }

    private var resolvedQuoteProvenance: FinancialDataProvenance {
        quoteProvenance ?? .unavailable(reason: "Provider quote not loaded")
    }

    private var matchedStock: Stock? {
        MockStockData.knownStocks.first { $0.symbol.uppercased() == holding.symbol.uppercased() }
    }

    private var confidenceColor: Color {
        if holding.confidence >= 0.8 { return CosmicTheme.positive }
        if holding.confidence >= 0.5 { return CosmicTheme.gold }
        return CosmicTheme.negative
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Circle()
                    .fill(confidenceColor)
                    .frame(width: 7, height: 7)

                TextField("SYMBOL", text: $holding.symbol)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                    .font(TerminalFont.ticker(13))
                    .foregroundColor(CosmicTheme.textPrimary)
                    .frame(width: 74)

                if let sign = matchedStock?.zodiacSign {
                    ZodiacMark(sign: sign, size: .tiny, style: .element)
                        .frame(width: 18)
                } else {
                    Text("?")
                        .font(TerminalFont.data(12, weight: .bold))
                        .foregroundColor(CosmicTheme.textMuted)
                        .frame(width: 18)
                        .accessibilityLabel("unknown sign")
                }

                Spacer()

                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.caption)
                        .foregroundColor(CosmicTheme.negative)
                        .frame(width: 28, height: 28)
                }
                .accessibilityLabel("Remove \(holding.symbol)")
            }

            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("SHARES")
                        .font(TerminalFont.data(8))
                        .foregroundColor(CosmicTheme.textMuted)

                    TextField("0", text: $holding.sharesText)
                        .keyboardType(.numbersAndPunctuation)
                        .font(TerminalFont.price(12))
                        .foregroundColor((shares ?? 0) > 0 ? CosmicTheme.textPrimary : CosmicTheme.negative)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("COST BASIS")
                        .font(TerminalFont.data(8))
                        .foregroundColor(CosmicTheme.textMuted)

                    TextField("Optional", text: $holding.costBasisText)
                        .keyboardType(.numbersAndPunctuation)
                        .font(TerminalFont.price(12))
                        .foregroundColor(holding.isCostBasisValid ? CosmicTheme.textPrimary : CosmicTheme.negative)
                }

                VStack(alignment: .trailing, spacing: 4) {
                    Text("CSV VALUE")
                        .font(TerminalFont.data(8))
                        .foregroundColor(CosmicTheme.textMuted)

                    Text(csvMarketValueText)
                        .font(TerminalFont.price(12))
                        .foregroundColor(CosmicTheme.textSecondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                }
                .frame(maxWidth: .infinity, alignment: .trailing)

                VStack(alignment: .trailing, spacing: 4) {
                    Text("LIVE VALUE")
                        .font(TerminalFont.data(8))
                        .foregroundColor(CosmicTheme.textMuted)

                    Text(liveMarketValueText)
                        .font(TerminalFont.price(12))
                        .foregroundColor(livePrice == nil ? CosmicTheme.textMuted : CosmicTheme.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)

                    Text(resolvedQuoteProvenance.shortLabel.uppercased())
                        .font(TerminalFont.data(7, weight: .bold))
                        .foregroundColor(resolvedQuoteProvenance.color)
                        .tracking(0.5)
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
        .padding(12)
    }

    nonisolated private static func formatCurrency(_ value: Double) -> String {
        let sign = value < 0 ? "-" : ""
        let absValue = abs(value)
        if absValue >= 1_000_000 {
            return String(format: "%@$%.2fM", sign, absValue / 1_000_000)
        }
        if absValue >= 1_000 {
            return String(format: "%@$%.2fK", sign, absValue / 1_000)
        }
        return String(format: "%@$%.2f", sign, absValue)
    }
}

extension PortfolioImportCommitMode: Identifiable {
    var id: String {
        switch self {
        case .replace: return "replace"
        case .append: return "append"
        }
    }
}

private struct ImportCommitConfirmationSheet: View {
    let mode: PortfolioImportCommitMode
    let existingCount: Int
    let importedCount: Int
    let onCancel: () -> Void
    let onConfirm: () -> Void

    private var title: String {
        switch mode {
        case .replace:
            return "Replace portfolio?"
        case .append:
            return "Append holdings?"
        }
    }

    private var message: String {
        switch mode {
        case .replace:
            return "Replace \(existingCount) existing holdings with \(importedCount) imported holdings? This cannot be undone."
        case .append:
            return "Add \(importedCount) imported holdings to \(existingCount) existing holdings? Matching symbols will combine shares and weighted cost basis."
        }
    }

    private var confirmTitle: String {
        switch mode {
        case .replace:
            return "Replace my portfolio"
        case .append:
            return "Append holdings"
        }
    }

    private var confirmColor: Color {
        switch mode {
        case .replace:
            return CosmicTheme.negative
        case .append:
            return CosmicTheme.gold
        }
    }

    var body: some View {
        VStack(spacing: 18) {
            Capsule()
                .fill(CosmicTheme.border)
                .frame(width: 42, height: 4)
                .padding(.top, 10)

            VStack(spacing: 8) {
                Text(title)
                    .font(TerminalFont.data(16, weight: .semibold))
                    .foregroundColor(CosmicTheme.textPrimary)

                Text(message)
                    .font(TerminalFont.data(12))
                    .foregroundColor(CosmicTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(spacing: 10) {
                Button(action: onConfirm) {
                    Text(confirmTitle)
                        .font(TerminalFont.data(13, weight: .semibold))
                        .foregroundColor(CosmicTheme.background)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(confirmColor)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }

                Button(action: onCancel) {
                    Text("Cancel")
                        .font(TerminalFont.data(12, weight: .semibold))
                        .foregroundColor(CosmicTheme.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                }
            }
        }
        .padding(18)
        .background(CosmicTheme.background)
    }
}

private struct ReviewedImportHolding: Identifiable {
    let id = UUID()
    var symbol: String
    var sharesText: String
    var costBasisText: String
    let csvMarketValue: Double?
    let confidence: Double
    let rawSource: String

    nonisolated init(holding: ParsedHolding) {
        symbol = holding.symbol
        sharesText = Self.formatShares(holding.shares)
        costBasisText = Self.formatCostBasis(holding.costBasisPerShare)
        csvMarketValue = holding.marketValue
        confidence = holding.confidence
        rawSource = holding.rawSource
    }

    var isCostBasisValid: Bool {
        parseCostBasis() != nil || costBasisText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var parsedHolding: ParsedHolding? {
        let cleanSymbol = BrokerCSVParsing.cleanSymbol(symbol)
        guard BrokerCSVParsing.isValidSymbol(cleanSymbol),
              let shares = Double(sharesText.trimmingCharacters(in: .whitespacesAndNewlines)),
              shares.isFinite,
              let costBasis = parseCostBasis() else {
            return nil
        }

        return ParsedHolding(
            symbol: cleanSymbol,
            shares: shares,
            marketValue: csvMarketValue,
            costBasisPerShare: costBasis,
            confidence: confidence,
            rawSource: rawSource
        )
    }

    nonisolated private static func formatShares(_ value: Double) -> String {
        if value == value.rounded() {
            return String(format: "%.0f", value)
        }
        return String(format: "%.4f", value)
    }

    nonisolated private static func formatCostBasis(_ value: Double?) -> String {
        guard let value else { return "" }
        return String(format: "%.2f", value)
    }

    private func parseCostBasis() -> Double?? {
        let text = costBasisText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return .some(nil) }
        guard let value = BrokerCSVParsing.parseDouble(text),
              value.isFinite,
              value > 0 else {
            return nil
        }
        return .some(value)
    }
}

#Preview("Import Review") {
    NavigationStack {
        ImportReviewView(
            parsedPortfolio: ParsedPortfolio(
                broker: "Schwab Web Positions",
                holdings: [
                    ParsedHolding(symbol: "AAPL", shares: 10, marketValue: 3108.50, confidence: 1, rawSource: "AAPL,10,..."),
                    ParsedHolding(symbol: "ZZZZ", shares: 3, marketValue: 120, confidence: 0.8, rawSource: "ZZZZ,3,...")
                ],
                unparsedLines: ["Cash & Money Market,100.00"],
                overallConfidence: 0.92
            )
        )
    }
    .environment(AppState(user: .sample))
    .preferredColorScheme(.dark)
}
