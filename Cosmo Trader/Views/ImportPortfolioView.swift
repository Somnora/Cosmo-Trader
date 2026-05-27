import SwiftUI
import UniformTypeIdentifiers

// MARK: - ImportPortfolioView
// ============================
// Terminal-style view for importing portfolio holdings from CSV files.
// Supports multiple broker export formats with step-by-step guidance.

struct ImportPortfolioView: View {

    // MARK: - Environment

    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState

    // MARK: - State

    @State private var importResult: PortfolioImportResult?
    @State private var isShowingFilePicker = false
    @State private var isShowingError = false
    @State private var errorMessage = ""
    @State private var isImporting = false
    @State private var replaceExisting = false
    @State private var showSuccess = false
    @State private var expandedFormat: CSVFormat?
    @State private var isShowingScreenshotImport = false

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                CosmicTheme.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        if let result = importResult {
                            // Preview imported data
                            importPreview(result)
                        } else {
                            // Import instructions
                            instructionsSection
                            brokerInstructions
                            importButton
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Import Portfolio")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(CosmicTheme.textSecondary)
                }

                if importResult != nil {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Import") {
                            confirmImport()
                        }
                        .foregroundColor(CosmicTheme.gold)
                        .fontWeight(.semibold)
                    }
                }
            }
            .fileImporter(
                isPresented: $isShowingFilePicker,
                allowedContentTypes: [.commaSeparatedText, .plainText],
                allowsMultipleSelection: false
            ) { result in
                handleFileSelection(result)
            }
            .alert("Import Error", isPresented: $isShowingError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .alert("Portfolio Imported!", isPresented: $showSuccess) {
                Button("Done") {
                    dismiss()
                }
            } message: {
                if let result = importResult {
                    Text("Successfully imported \(result.holdings.count) holdings to your portfolio.")
                }
            }
            .sheet(isPresented: $isShowingScreenshotImport) {
                ScreenshotImportView()
            }
        }
    }

    // MARK: - Instructions Section

    private var instructionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "square.and.arrow.down")
                    .font(.caption)
                    .foregroundColor(CosmicTheme.gold)

                Text("IMPORT YOUR HOLDINGS")
                    .font(TerminalFont.data(11, weight: .semibold))
                    .foregroundColor(CosmicTheme.textPrimary)
                    .tracking(1)
            }

            Text("Import holdings to make Today operational. Screenshot import is fastest; CSV is available when you want a cleaner position file.")
                .font(TerminalFont.data(12))
                .foregroundColor(CosmicTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            // Supported formats
            HStack(spacing: 8) {
                ForEach(["Robinhood", "Fidelity", "Schwab"], id: \.self) { name in
                    Text(name)
                        .font(TerminalFont.data(9))
                        .foregroundColor(CosmicTheme.textMuted)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(CosmicTheme.cardBackground)
                        .clipShape(Capsule())
                }
                Text("+3 more")
                    .font(TerminalFont.data(9))
                    .foregroundColor(CosmicTheme.gold)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(CosmicTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(CosmicTheme.border, lineWidth: 1)
        )
    }

    // MARK: - Broker Instructions

    private var brokerInstructions: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("EXPORT INSTRUCTIONS BY BROKER")
                    .font(TerminalFont.data(10, weight: .semibold))
                    .foregroundColor(CosmicTheme.textMuted)
                    .tracking(1)

                Spacer()
            }
            .padding(12)

            Rectangle()
                .fill(CosmicTheme.border)
                .frame(height: 1)

            ForEach(CSVFormat.allCases.filter { $0 != .generic }, id: \.self) { format in
                brokerRow(format)

                if format != .tdAmeritrade {
                    Rectangle()
                        .fill(CosmicTheme.border.opacity(0.5))
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

    private func brokerRow(_ format: CSVFormat) -> some View {
        let isExpanded = expandedFormat == format

        return VStack(alignment: .leading, spacing: 0) {
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    expandedFormat = isExpanded ? nil : format
                }
            }) {
                HStack {
                    // Broker icon
                    brokerIcon(for: format)
                        .frame(width: 24, height: 24)

                    Text(format.rawValue)
                        .font(TerminalFont.data(12, weight: .medium))
                        .foregroundColor(CosmicTheme.textPrimary)

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(CosmicTheme.textMuted)
                }
                .padding(12)
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())

            if isExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    // Steps
                    ForEach(exportSteps(for: format).indices, id: \.self) { index in
                        HStack(alignment: .top, spacing: 8) {
                            Text("\(index + 1).")
                                .font(TerminalFont.data(11, weight: .semibold))
                                .foregroundColor(CosmicTheme.gold)
                                .frame(width: 16)

                            Text(exportSteps(for: format)[index])
                                .font(TerminalFont.data(11))
                                .foregroundColor(CosmicTheme.textSecondary)
                        }
                    }

                    // Path hint
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.right.circle")
                            .font(.caption2)
                            .foregroundColor(CosmicTheme.textMuted)

                        Text(format.exportInstructions)
                            .font(TerminalFont.data(10))
                            .foregroundColor(CosmicTheme.textMuted)
                            .italic()
                    }
                    .padding(.top, 4)
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 12)
                .background(CosmicTheme.background.opacity(0.5))
            }
        }
    }

    private func brokerIcon(for format: CSVFormat) -> some View {
        let (icon, color): (String, Color) = switch format {
        case .robinhood: ("leaf.fill", .green)
        case .fidelity: ("building.columns.fill", .blue)
        case .schwab: ("s.circle.fill", .cyan)
        case .etrade: ("e.circle.fill", .purple)
        case .tdAmeritrade: ("t.circle.fill", .green)
        case .generic: ("doc.text.fill", CosmicTheme.textMuted)
        }

        return Image(systemName: icon)
            .font(.system(size: 14))
            .foregroundColor(color)
    }

    private func exportSteps(for format: CSVFormat) -> [String] {
        switch format {
        case .robinhood:
            return [
                "Open Robinhood app or web",
                "Go to Account → Statements & History",
                "Select 'Export' or 'Download'",
                "Choose CSV format"
            ]
        case .fidelity:
            return [
                "Log in to Fidelity.com",
                "Go to Accounts → Positions",
                "Click 'Download' button",
                "Select CSV format"
            ]
        case .schwab:
            return [
                "Log in to Schwab.com",
                "Navigate to Accounts → Positions",
                "Click 'Export' in the top right",
                "Choose CSV download"
            ]
        case .etrade:
            return [
                "Log in to E*TRADE",
                "Go to Accounts → Positions",
                "Click 'Download' icon",
                "Select CSV format"
            ]
        case .tdAmeritrade:
            return [
                "Log in to TD Ameritrade",
                "Go to My Account → Positions",
                "Click 'Export' button",
                "Download as CSV"
            ]
        case .generic:
            return ["Export your positions as CSV from your broker"]
        }
    }

    // MARK: - Import Button

    private var importButton: some View {
        VStack(spacing: 12) {
            // Screenshot Import (Primary - Recommended)
            Button(action: {
                isShowingScreenshotImport = true
            }) {
                HStack(spacing: 10) {
                    Image(systemName: "camera.viewfinder")
                        .font(.title3)

                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Text("SCREENSHOT IMPORT")
                                .font(TerminalFont.data(12, weight: .semibold))
                                .tracking(1)

                            Text("Recommended")
                                .font(TerminalFont.data(8, weight: .semibold))
                                .foregroundColor(CosmicTheme.background)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(CosmicTheme.gold)
                                .clipShape(Capsule())
                        }

                        Text("Fast setup from a broker holdings screen")
                            .font(TerminalFont.data(10))
                            .opacity(0.7)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption)
                }
                .foregroundColor(CosmicTheme.gold)
                .padding(16)
                .background(CosmicTheme.gold.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(CosmicTheme.gold.opacity(0.3), lineWidth: 1)
                )
            }
            .buttonStyle(PlainButtonStyle())

            // CSV File Import (Secondary)
            Button(action: {
                isShowingFilePicker = true
            }) {
                HStack(spacing: 10) {
                    Image(systemName: "doc.badge.plus")
                        .font(.title3)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("CSV FILE IMPORT")
                            .font(TerminalFont.data(12, weight: .semibold))
                            .tracking(1)

                        Text("Cleaner import from exported positions")
                            .font(TerminalFont.data(10))
                            .opacity(0.7)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption)
                }
                .foregroundColor(CosmicTheme.textSecondary)
                .padding(16)
                .background(CosmicTheme.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(CosmicTheme.border, lineWidth: 1)
                )
            }
            .buttonStyle(PlainButtonStyle())

            // Sample import option
            Button(action: {
                loadSampleData()
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .font(.caption2)

                    Text("Try with sample data")
                        .font(TerminalFont.data(11))
                }
                .foregroundColor(CosmicTheme.textMuted)
            }
        }
    }

    // MARK: - Import Preview

    private func importPreview(_ result: PortfolioImportResult) -> some View {
        VStack(spacing: 16) {
            // Summary card
            summaryCard(result)

            // Warnings
            if !result.warnings.isEmpty {
                warningsCard(result.warnings)
            }

            // Holdings list
            holdingsList(result.holdings)

            // Options
            optionsSection
        }
    }

    private func summaryCard(_ result: PortfolioImportResult) -> some View {
        VStack(spacing: 12) {
            // Success header
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(CosmicTheme.positive)

                VStack(alignment: .leading, spacing: 2) {
                    Text("FILE PARSED SUCCESSFULLY")
                        .font(TerminalFont.data(11, weight: .semibold))
                        .foregroundColor(CosmicTheme.positive)
                        .tracking(1)

                    Text("Detected format: \(result.format.rawValue)")
                        .font(TerminalFont.data(10))
                        .foregroundColor(CosmicTheme.textMuted)
                }

                Spacer()
            }

            Rectangle()
                .fill(CosmicTheme.border)
                .frame(height: 1)

            // Stats
            HStack(spacing: 20) {
                statItem(
                    value: "\(result.holdings.count)",
                    label: "STOCKS",
                    icon: "chart.bar.fill"
                )

                statItem(
                    value: String(format: "%.0f", result.totalShares),
                    label: "SHARES",
                    icon: "square.stack.3d.up.fill"
                )

                statItem(
                    value: formatValue(result.totalValue),
                    label: "EST. VALUE",
                    icon: "dollarsign.circle.fill"
                )
            }

            // Skipped rows note
            if result.skippedRows > 0 {
                HStack(spacing: 6) {
                    Image(systemName: "info.circle")
                        .font(.caption2)
                        .foregroundColor(CosmicTheme.textMuted)

                    Text("\(result.skippedRows) rows skipped (headers, empty rows, or invalid data)")
                        .font(TerminalFont.data(10))
                        .foregroundColor(CosmicTheme.textMuted)
                }
            }
        }
        .padding(16)
        .background(CosmicTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(CosmicTheme.positive.opacity(0.3), lineWidth: 1)
        )
    }

    private func statItem(value: String, label: String, icon: String) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption2)
                    .foregroundColor(CosmicTheme.gold)

                Text(value)
                    .font(TerminalFont.price(18))
                    .foregroundColor(CosmicTheme.textPrimary)
            }

            Text(label)
                .font(TerminalFont.data(9))
                .foregroundColor(CosmicTheme.textMuted)
                .tracking(0.5)
        }
        .frame(maxWidth: .infinity)
    }

    private func warningsCard(_ warnings: [ImportWarning]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundColor(.orange)

                Text("WARNINGS (\(warnings.count))")
                    .font(TerminalFont.data(10, weight: .semibold))
                    .foregroundColor(.orange)
                    .tracking(1)
            }

            ForEach(warnings) { warning in
                HStack(alignment: .top, spacing: 8) {
                    Text("•")
                        .font(TerminalFont.data(11))
                        .foregroundColor(.orange.opacity(0.7))

                    Text(warning.message)
                        .font(TerminalFont.data(11))
                        .foregroundColor(CosmicTheme.textSecondary)
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.orange.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
        )
    }

    private func holdingsList(_ holdings: [ImportedHolding]) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text("HOLDINGS TO IMPORT")
                    .font(TerminalFont.data(10, weight: .semibold))
                    .foregroundColor(CosmicTheme.textMuted)
                    .tracking(1)

                Spacer()

                Text("\(holdings.filter { $0.isRecognized }.count)/\(holdings.count) recognized")
                    .font(TerminalFont.data(10))
                    .foregroundColor(CosmicTheme.textMuted)
            }
            .padding(12)

            Rectangle()
                .fill(CosmicTheme.border)
                .frame(height: 1)

            // Table header
            HStack(spacing: 0) {
                Text("SYMBOL")
                    .frame(width: 70, alignment: .leading)
                Text("QTY")
                    .frame(width: 60, alignment: .trailing)
                Text("AVG COST")
                    .frame(width: 80, alignment: .trailing)
                Text("STATUS")
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .font(TerminalFont.data(9))
            .foregroundColor(CosmicTheme.textMuted)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(CosmicTheme.background)

            Rectangle()
                .fill(CosmicTheme.border)
                .frame(height: 1)

            // Rows
            ForEach(holdings) { holding in
                holdingRow(holding)

                if holding.id != holdings.last?.id {
                    Rectangle()
                        .fill(CosmicTheme.border.opacity(0.5))
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

    private func holdingRow(_ holding: ImportedHolding) -> some View {
        HStack(spacing: 0) {
            // Symbol with zodiac if recognized
            HStack(spacing: 6) {
                Text(holding.symbol)
                    .font(TerminalFont.data(12, weight: .semibold))
                    .foregroundColor(CosmicTheme.textPrimary)

                if let sign = holding.matchedStock?.zodiacSign {
                    ZodiacMark(sign: sign, size: .tiny, style: .element)
                } else if holding.matchedStock != nil {
                    Text("?")
                        .font(TerminalFont.data(10, weight: .bold))
                        .foregroundColor(CosmicTheme.textMuted)
                        .accessibilityLabel("unknown sign")
                }
            }
            .frame(width: 70, alignment: .leading)

            // Quantity
            Text(holding.formattedQuantity)
                .font(TerminalFont.data(12))
                .foregroundColor(CosmicTheme.textSecondary)
                .frame(width: 60, alignment: .trailing)

            // Average cost
            Text(holding.formattedAverageCost ?? "-")
                .font(TerminalFont.data(12))
                .foregroundColor(CosmicTheme.textSecondary)
                .frame(width: 80, alignment: .trailing)

            // Status
            HStack(spacing: 4) {
                if holding.isRecognized {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption2)
                        .foregroundColor(CosmicTheme.positive)
                    Text("Ready")
                        .font(TerminalFont.data(10))
                        .foregroundColor(CosmicTheme.positive)
                } else {
                    Image(systemName: "questionmark.circle")
                        .font(.caption2)
                        .foregroundColor(.orange)
                    Text("Unknown")
                        .font(TerminalFont.data(10))
                        .foregroundColor(.orange)
                }
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }

    // MARK: - Options Section

    private var optionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("IMPORT OPTIONS")
                .font(TerminalFont.data(10, weight: .semibold))
                .foregroundColor(CosmicTheme.textMuted)
                .tracking(1)

            Toggle(isOn: $replaceExisting) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Replace existing portfolio")
                        .font(TerminalFont.data(12))
                        .foregroundColor(CosmicTheme.textPrimary)

                    Text("Clear current holdings before importing")
                        .font(TerminalFont.data(10))
                        .foregroundColor(CosmicTheme.textMuted)
                }
            }
            .toggleStyle(SwitchToggleStyle(tint: CosmicTheme.gold))

            // Clear preview button
            Button(action: {
                withAnimation {
                    importResult = nil
                }
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.caption)

                    Text("Choose Different File")
                        .font(TerminalFont.data(11))
                }
                .foregroundColor(CosmicTheme.textMuted)
            }
        }
        .padding(12)
        .background(CosmicTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(CosmicTheme.border, lineWidth: 1)
        )
    }

    // MARK: - Actions

    private func handleFileSelection(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            importCSVFile(url)

        case .failure(let error):
            errorMessage = error.localizedDescription
            isShowingError = true
        }
    }

    private func importCSVFile(_ url: URL) {
        isImporting = true

        do {
            let result = try PortfolioImportService.importFromCSV(fileURL: url)
            withAnimation {
                importResult = result
            }
        } catch let error as PortfolioImportError {
            errorMessage = error.errorDescription ?? "Unknown error"
            isShowingError = true
        } catch {
            errorMessage = error.localizedDescription
            isShowingError = true
        }

        isImporting = false
    }

    private func loadSampleData() {
        do {
            let sampleCSV = PortfolioImportService.generateSampleCSV()
            let result = try PortfolioImportService.importFromCSVString(sampleCSV)
            withAnimation {
                importResult = result
            }
        } catch {
            errorMessage = error.localizedDescription
            isShowingError = true
        }
    }

    private func confirmImport() {
        guard let result = importResult else { return }

        PortfolioImportService.applyImport(
            holdings: result.holdings,
            to: appState,
            replaceExisting: replaceExisting
        )

        showSuccess = true
    }

    // MARK: - Helpers

    private func formatValue(_ value: Double) -> String {
        if value >= 1_000_000 {
            return String(format: "$%.1fM", value / 1_000_000)
        } else if value >= 1_000 {
            return String(format: "$%.1fK", value / 1_000)
        } else {
            return String(format: "$%.0f", value)
        }
    }
}

// MARK: - Preview

#Preview("Import Portfolio") {
    ImportPortfolioView()
        .environment(AppState())
        .preferredColorScheme(.dark)
}
