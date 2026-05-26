import SwiftUI
import PhotosUI

// MARK: - ScreenshotImportView
// ============================
// Terminal-style view for importing portfolio holdings from brokerage screenshots.
// Uses Vision framework OCR to extract stock symbols, quantities, and prices.

struct ScreenshotImportView: View {

    // MARK: - Environment

    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState

    // MARK: - State

    @State private var selectedImage: UIImage?
    @State private var selectedItem: PhotosPickerItem?
    @State private var isProcessing = false
    @State private var extractedPortfolio: OCRExtractedPortfolio?
    @State private var editableHoldings: [OCRExtractedHolding] = []
    @State private var errorMessage = ""
    @State private var showError = false
    @State private var showSuccess = false
    @State private var replaceExisting = false
    @State private var scanLineOffset: CGFloat = 0

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                CosmicTheme.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        if isProcessing {
                            processingView
                        } else if let portfolio = extractedPortfolio {
                            resultsView(portfolio)
                        } else {
                            instructionsView
                            photoPickerSection
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Screenshot Import")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(CosmicTheme.textSecondary)
                }

                if extractedPortfolio != nil && !editableHoldings.isEmpty {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Import") {
                            confirmImport()
                        }
                        .foregroundColor(CosmicTheme.gold)
                        .fontWeight(.semibold)
                    }
                }
            }
            .onChange(of: selectedItem) { _, newValue in
                Task {
                    await loadImage(from: newValue)
                }
            }
            .alert("Import Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .alert("Portfolio Imported!", isPresented: $showSuccess) {
                Button("Done") {
                    dismiss()
                }
            } message: {
                Text("Successfully imported \(editableHoldings.count) holdings to your portfolio.")
            }
        }
    }

    // MARK: - Instructions View

    private var instructionsView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "camera.viewfinder")
                    .font(.caption)
                    .foregroundColor(CosmicTheme.gold)

                Text("SCREENSHOT IMPORT")
                    .font(TerminalFont.data(11, weight: .semibold))
                    .foregroundColor(CosmicTheme.textPrimary)
                    .tracking(1)
            }

            Text("Take a screenshot of your brokerage app's portfolio view, then import it here. Our OCR will extract your holdings automatically.")
                .font(TerminalFont.data(12))
                .foregroundColor(CosmicTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            // Tips
            VStack(alignment: .leading, spacing: 8) {
                tipRow(icon: "checkmark.circle", text: "Make sure stock symbols are visible")
                tipRow(icon: "checkmark.circle", text: "Include quantities and prices if possible")
                tipRow(icon: "checkmark.circle", text: "Use a clear, high-resolution screenshot")
            }
            .padding(.top, 4)

            // Supported brokers
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
                Text("+4 more")
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

    private func tipRow(icon: String, text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundColor(CosmicTheme.positive)

            Text(text)
                .font(TerminalFont.data(11))
                .foregroundColor(CosmicTheme.textSecondary)
        }
    }

    // MARK: - Photo Picker Section

    private var photoPickerSection: some View {
        VStack(spacing: 12) {
            PhotosPicker(
                selection: $selectedItem,
                matching: .images,
                photoLibrary: .shared()
            ) {
                HStack(spacing: 10) {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.title3)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("SELECT SCREENSHOT")
                            .font(TerminalFont.data(12, weight: .semibold))
                            .tracking(1)

                        Text("Choose from your photo library")
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
        }
    }

    // MARK: - Processing View

    private var processingView: some View {
        VStack(spacing: 24) {
            // Image preview with scanning animation
            if let image = selectedImage {
                ZStack {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxHeight: 300)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(CosmicTheme.border, lineWidth: 1)
                        )

                    // Scanning line animation
                    GeometryReader { geometry in
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        CosmicTheme.gold.opacity(0),
                                        CosmicTheme.gold.opacity(0.8),
                                        CosmicTheme.gold.opacity(0)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(height: 4)
                            .offset(y: scanLineOffset * geometry.size.height)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .onAppear {
                    withAnimation(
                        .linear(duration: 2.0)
                        .repeatForever(autoreverses: false)
                    ) {
                        scanLineOffset = 1.0
                    }
                }
            }

            // Processing status
            VStack(spacing: 12) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: CosmicTheme.gold))
                    .scaleEffect(1.2)

                Text("ANALYZING SCREENSHOT")
                    .font(TerminalFont.data(12, weight: .semibold))
                    .foregroundColor(CosmicTheme.gold)
                    .tracking(1)

                Text("Extracting stock symbols and values...")
                    .font(TerminalFont.data(11))
                    .foregroundColor(CosmicTheme.textMuted)
            }
            .padding(.vertical, 20)
        }
        .padding(16)
        .background(CosmicTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(CosmicTheme.border, lineWidth: 1)
        )
    }

    // MARK: - Results View

    private func resultsView(_ portfolio: OCRExtractedPortfolio) -> some View {
        VStack(spacing: 16) {
            // Summary card
            summaryCard(portfolio)

            // Warnings
            if !portfolio.warnings.isEmpty {
                warningsCard(portfolio.warnings)
            }

            // Holdings list (editable)
            if !editableHoldings.isEmpty {
                holdingsList
            } else {
                noHoldingsView
            }

            // Options
            if !editableHoldings.isEmpty {
                optionsSection
            }
        }
    }

    private func summaryCard(_ portfolio: OCRExtractedPortfolio) -> some View {
        VStack(spacing: 12) {
            // Header
            HStack(spacing: 8) {
                Image(systemName: portfolio.holdings.isEmpty ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(portfolio.holdings.isEmpty ? .orange : CosmicTheme.positive)

                VStack(alignment: .leading, spacing: 2) {
                    Text(portfolio.holdings.isEmpty ? "SCAN COMPLETE" : "HOLDINGS DETECTED")
                        .font(TerminalFont.data(11, weight: .semibold))
                        .foregroundColor(portfolio.holdings.isEmpty ? .orange : CosmicTheme.positive)
                        .tracking(1)

                    if let broker = portfolio.detectedBroker {
                        HStack(spacing: 4) {
                            Image(systemName: broker.icon)
                                .font(.caption2)
                            Text("Detected: \(broker.rawValue)")
                                .font(TerminalFont.data(10))
                        }
                        .foregroundColor(CosmicTheme.textMuted)
                    }
                }

                Spacer()

                // Confidence badge
                if !portfolio.holdings.isEmpty {
                    Text("\(Int(portfolio.confidence * 100))%")
                        .font(TerminalFont.data(12, weight: .semibold))
                        .foregroundColor(portfolio.confidence >= 0.7 ? CosmicTheme.positive : .orange)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            (portfolio.confidence >= 0.7 ? CosmicTheme.positive : Color.orange)
                                .opacity(0.2)
                        )
                        .clipShape(Capsule())
                }
            }

            if !portfolio.holdings.isEmpty {
                Rectangle()
                    .fill(CosmicTheme.border)
                    .frame(height: 1)

                // Stats
                HStack(spacing: 20) {
                    statItem(
                        value: "\(portfolio.holdings.count)",
                        label: "DETECTED",
                        icon: "text.viewfinder"
                    )

                    statItem(
                        value: "\(portfolio.recognizedCount)",
                        label: "RECOGNIZED",
                        icon: "checkmark.circle"
                    )

                    statItem(
                        value: "\(editableHoldings.count)",
                        label: "TO IMPORT",
                        icon: "square.and.arrow.down"
                    )
                }
            }
        }
        .padding(16)
        .background(CosmicTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(
                    (portfolio.holdings.isEmpty ? Color.orange : CosmicTheme.positive).opacity(0.3),
                    lineWidth: 1
                )
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

    private func warningsCard(_ warnings: [String]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundColor(.orange)

                Text("NOTES (\(warnings.count))")
                    .font(TerminalFont.data(10, weight: .semibold))
                    .foregroundColor(.orange)
                    .tracking(1)
            }

            ForEach(warnings, id: \.self) { warning in
                HStack(alignment: .top, spacing: 8) {
                    Text("•")
                        .font(TerminalFont.data(11))
                        .foregroundColor(.orange.opacity(0.7))

                    Text(warning)
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

    private var holdingsList: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text("HOLDINGS TO IMPORT")
                    .font(TerminalFont.data(10, weight: .semibold))
                    .foregroundColor(CosmicTheme.textMuted)
                    .tracking(1)

                Spacer()

                Text("Tap to edit • Swipe to remove")
                    .font(TerminalFont.data(9))
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
                Text("PRICE")
                    .frame(width: 70, alignment: .trailing)
                Text("CONF")
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
            ForEach(editableHoldings) { holding in
                holdingRow(holding)
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            removeHolding(holding)
                        } label: {
                            Label("Remove", systemImage: "trash")
                        }
                    }

                if holding.id != editableHoldings.last?.id {
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

    private func holdingRow(_ holding: OCRExtractedHolding) -> some View {
        HStack(spacing: 0) {
            // Symbol with zodiac if recognized
            HStack(spacing: 6) {
                Text(holding.symbol)
                    .font(TerminalFont.data(12, weight: .semibold))
                    .foregroundColor(holding.isRecognized ? CosmicTheme.textPrimary : .orange)

                if let stock = holding.matchedStock {
                    ZodiacMark(sign: stock.zodiacSign, size: .tiny, style: .element)
                }
            }
            .frame(width: 70, alignment: .leading)

            // Quantity
            Text(holding.formattedQuantity)
                .font(TerminalFont.data(12))
                .foregroundColor(CosmicTheme.textSecondary)
                .frame(width: 60, alignment: .trailing)

            // Price
            Text(holding.formattedPrice)
                .font(TerminalFont.data(12))
                .foregroundColor(CosmicTheme.textSecondary)
                .frame(width: 70, alignment: .trailing)

            // Confidence
            HStack(spacing: 4) {
                Circle()
                    .fill(confidenceColor(holding.confidence))
                    .frame(width: 6, height: 6)

                Text(holding.confidenceLevel)
                    .font(TerminalFont.data(10))
                    .foregroundColor(confidenceColor(holding.confidence))
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }

    private func confidenceColor(_ confidence: Double) -> Color {
        switch confidence {
        case 0.75...: return CosmicTheme.positive
        case 0.5..<0.75: return .orange
        default: return CosmicTheme.negative
        }
    }

    private var noHoldingsView: some View {
        VStack(spacing: 12) {
            Image(systemName: "text.magnifyingglass")
                .font(.largeTitle)
                .foregroundColor(CosmicTheme.textMuted)

            Text("No Holdings Detected")
                .font(TerminalFont.data(14, weight: .semibold))
                .foregroundColor(CosmicTheme.textPrimary)

            Text("Try a different screenshot with visible stock symbols")
                .font(TerminalFont.data(12))
                .foregroundColor(CosmicTheme.textMuted)
                .multilineTextAlignment(.center)

            Button(action: resetAndTryAgain) {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.caption)

                    Text("Try Another Screenshot")
                        .font(TerminalFont.data(11))
                }
                .foregroundColor(CosmicTheme.gold)
            }
            .padding(.top, 8)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(CosmicTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(CosmicTheme.border, lineWidth: 1)
        )
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

            // Try another button
            Button(action: resetAndTryAgain) {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.caption)

                    Text("Choose Different Screenshot")
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

    private func loadImage(from item: PhotosPickerItem?) async {
        guard let item = item else { return }

        do {
            if let data = try await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                selectedImage = image
                await processImage(image)
            }
        } catch {
            errorMessage = "Failed to load image: \(error.localizedDescription)"
            showError = true
        }
    }

    private func processImage(_ image: UIImage) async {
        isProcessing = true
        scanLineOffset = 0

        do {
            let portfolio = try await VisionOCRService.shared.extractPortfolio(from: image)
            extractedPortfolio = portfolio
            editableHoldings = portfolio.holdings
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }

        isProcessing = false
    }

    private func removeHolding(_ holding: OCRExtractedHolding) {
        withAnimation {
            editableHoldings.removeAll { $0.id == holding.id }
        }
    }

    private func resetAndTryAgain() {
        withAnimation {
            selectedImage = nil
            selectedItem = nil
            extractedPortfolio = nil
            editableHoldings = []
            scanLineOffset = 0
        }
    }

    private func confirmImport() {
        // Convert OCR holdings to ImportedHoldings
        let importedHoldings = VisionOCRService.shared.convertToImportedHoldings(editableHoldings)

        // Apply import using existing service
        PortfolioImportService.applyImport(
            holdings: importedHoldings,
            to: appState,
            replaceExisting: replaceExisting
        )

        showSuccess = true
    }
}

// MARK: - Preview

#Preview("Screenshot Import") {
    ScreenshotImportView()
        .environment(AppState())
        .preferredColorScheme(.dark)
}
