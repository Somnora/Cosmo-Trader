import SwiftUI
import UniformTypeIdentifiers

// MARK: - ImportPortfolioView
// ============================
// Terminal-style view for importing portfolio holdings from broker
// positions files. CSV import accepts any positions export with Symbol
// and Quantity columns (specialized parsers cover thinkorswim and Schwab
// web formats); screenshot import currently parses Schwab mobile
// positions screens. Every parse routes through ImportReviewView for
// row-by-row review before anything is committed.

struct ImportPortfolioView: View {

    // MARK: - Environment

    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState

    // MARK: - State

    @State private var isShowingFilePicker = false
    @State private var isShowingError = false
    @State private var errorMessage = ""
    @State private var isImporting = false
    @State private var isShowingScreenshotImport = false
    @State private var parsedPortfolio: ParsedPortfolio?
    @State private var isShowingImportReview = false
    @State private var expandedGuideID: String?

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                CosmicTheme.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        instructionsSection
                        importButtons
                        brokerGuides
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
            .sheet(isPresented: $isShowingScreenshotImport) {
                ScreenshotImportView()
            }
            .navigationDestination(isPresented: $isShowingImportReview) {
                if let parsedPortfolio {
                    ImportReviewView(
                        parsedPortfolio: parsedPortfolio,
                        onComplete: {
                            dismiss()
                        },
                        onCancel: {
                            self.parsedPortfolio = nil
                            isShowingImportReview = false
                        }
                    )
                }
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

            Text("Import holdings to make Today operational. Any positions CSV with Symbol and Quantity columns will import; you review every row before it commits.")
                .font(TerminalFont.data(12))
                .foregroundColor(CosmicTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            // Formats with dedicated parsers or verified generic support
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    ForEach(["Schwab", "thinkorswim", "Fidelity", "E*TRADE"], id: \.self) { name in
                        Text(name)
                            .font(TerminalFont.data(9))
                            .foregroundColor(CosmicTheme.textMuted)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(CosmicTheme.cardBackground)
                            .clipShape(Capsule())
                    }
                }
                Text("+ any positions CSV with Symbol and Quantity columns")
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

    // MARK: - Import Buttons

    private var importButtons: some View {
        VStack(spacing: 12) {
            // Positions CSV (primary: works for most brokers)
            Button(action: {
                isShowingFilePicker = true
            }) {
                HStack(spacing: 10) {
                    Image(systemName: "doc.badge.plus")
                        .font(.title3)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("IMPORT POSITIONS CSV")
                            .font(TerminalFont.data(12, weight: .semibold))
                            .tracking(1)

                        Text("Most brokers. Review rows, then append or replace")
                            .font(TerminalFont.data(10))
                            .opacity(0.7)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer()

                    if isImporting {
                        ProgressView()
                            .tint(CosmicTheme.gold)
                    } else {
                        Image(systemName: "chevron.right")
                            .font(.caption)
                    }
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
            .disabled(isImporting)
            .accessibilityIdentifier("importPortfolio.csvImport")

            // Screenshot import (Schwab mobile positions screens only)
            Button(action: {
                isShowingScreenshotImport = true
            }) {
                HStack(spacing: 10) {
                    Image(systemName: "camera.viewfinder")
                        .font(.title3)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("SCREENSHOT IMPORT")
                            .font(TerminalFont.data(12, weight: .semibold))
                            .tracking(1)

                        Text("Schwab mobile positions screens")
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
            .accessibilityIdentifier("importPortfolio.screenshotImport")

            #if DEBUG
            // Debug-only sample import. Production import paths must use real user files.
            Button(action: {
                loadSampleData()
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .font(.caption2)

                    Text("Try with DEBUG sample data")
                        .font(TerminalFont.data(11))
                }
                .foregroundColor(CosmicTheme.textMuted)
            }
            #endif
        }
    }

    // MARK: - Broker Export Guides

    private var brokerGuides: some View {
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

            ForEach(BrokerExportGuide.all) { guide in
                brokerRow(guide)

                if guide.id != BrokerExportGuide.all.last?.id {
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

    private func brokerRow(_ guide: BrokerExportGuide) -> some View {
        let isExpanded = expandedGuideID == guide.id

        return VStack(alignment: .leading, spacing: 0) {
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    expandedGuideID = isExpanded ? nil : guide.id
                }
            }) {
                HStack {
                    Image(systemName: guide.icon)
                        .font(.system(size: 14))
                        .foregroundColor(guide.iconColor)
                        .frame(width: 24, height: 24)

                    Text(guide.name)
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
                    ForEach(guide.steps.indices, id: \.self) { index in
                        HStack(alignment: .top, spacing: 8) {
                            Text("\(index + 1).")
                                .font(TerminalFont.data(11, weight: .semibold))
                                .foregroundColor(CosmicTheme.gold)
                                .frame(width: 16)

                            Text(guide.steps[index])
                                .font(TerminalFont.data(11))
                                .foregroundColor(CosmicTheme.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }

                    HStack(spacing: 6) {
                        Image(systemName: "arrow.right.circle")
                            .font(.caption2)
                            .foregroundColor(CosmicTheme.textMuted)

                        Text(guide.pathHint)
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

        Task {
            do {
                let parsed = try await PortfolioImportService.parseCSVFile(url)
                await MainActor.run {
                    parsedPortfolio = parsed
                    isShowingImportReview = true
                    isImporting = false
                }
            } catch let error as PortfolioImportError {
                await MainActor.run {
                    errorMessage = error.errorDescription ?? "Unknown error"
                    isShowingError = true
                    isImporting = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isShowingError = true
                    isImporting = false
                }
            }
        }
    }

    #if DEBUG
    private func loadSampleData() {
        Task {
            do {
                let sampleCSV = PortfolioImportService.generateSampleCSV()
                let parsed = try await PortfolioImportService.parseCSV(sampleCSV)
                await MainActor.run {
                    parsedPortfolio = parsed
                    isShowingImportReview = true
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isShowingError = true
                }
            }
        }
    }
    #endif
}

// MARK: - Broker Export Guide

// Static how-to content only. Which files actually parse is decided by the
// registered BrokerCSVParser implementations; keep these guides in step with
// them so the screen never teaches an export the engine rejects.
private struct BrokerExportGuide: Identifiable {
    let id: String
    let name: String
    let icon: String
    let iconColor: Color
    let steps: [String]
    let pathHint: String

    static let all: [BrokerExportGuide] = [
        BrokerExportGuide(
            id: "schwab",
            name: "Charles Schwab",
            icon: "s.circle.fill",
            iconColor: .cyan,
            steps: [
                "Log in to Schwab.com",
                "Go to Accounts, then Positions",
                "Select Export in the top right",
                "Choose CSV download"
            ],
            pathHint: "Accounts, Positions, Export"
        ),
        BrokerExportGuide(
            id: "thinkorswim",
            name: "thinkorswim",
            icon: "t.circle.fill",
            iconColor: .green,
            steps: [
                "Open thinkorswim desktop",
                "Go to the Monitor tab, Activity and Positions",
                "Open the Position Statement section menu",
                "Choose Export to File"
            ],
            pathHint: "Monitor, Position Statement, Export to File"
        ),
        BrokerExportGuide(
            id: "fidelity",
            name: "Fidelity",
            icon: "building.columns.fill",
            iconColor: .blue,
            steps: [
                "Log in to Fidelity.com",
                "Go to Accounts, then Positions",
                "Select the Download icon above the positions table",
                "The positions CSV downloads directly"
            ],
            pathHint: "Accounts, Positions, Download"
        ),
        BrokerExportGuide(
            id: "etrade",
            name: "E*TRADE",
            icon: "e.circle.fill",
            iconColor: .purple,
            steps: [
                "Log in to E*TRADE",
                "Go to Portfolios, then Positions",
                "Select the Download link",
                "Choose the spreadsheet (CSV) option"
            ],
            pathHint: "Portfolios, Positions, Download"
        ),
        BrokerExportGuide(
            id: "robinhood",
            name: "Robinhood",
            icon: "leaf.fill",
            iconColor: .green,
            steps: [
                "Robinhood does not currently offer a positions CSV export; its reports are transaction history, which is not a positions file",
                "Use ADD HOLDING on the Portfolio tab to enter positions manually"
            ],
            pathHint: "No positions export available"
        ),
        BrokerExportGuide(
            id: "other",
            name: "Other brokers",
            icon: "doc.text.fill",
            iconColor: CosmicTheme.textMuted,
            steps: [
                "Export your positions (not transaction history) as CSV",
                "Make sure the file includes Symbol and Quantity or Shares columns",
                "Market Value and Cost Basis columns improve the review screen when present"
            ],
            pathHint: "Any positions CSV with Symbol and Quantity columns"
        )
    ]
}

// MARK: - Preview

#Preview("Import Portfolio") {
    ImportPortfolioView()
        .environment(AppState())
        .preferredColorScheme(.dark)
}
