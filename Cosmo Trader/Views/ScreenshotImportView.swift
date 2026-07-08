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
    @State private var parsedPortfolio: ParsedPortfolio?
    @State private var errorMessage = ""
    @State private var showError = false
    @State private var isShowingImportReview = false
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

            Text("Take a screenshot of a supported brokerage positions view. You will review every parsed row before choosing append or replace.")
                .font(TerminalFont.data(12))
                .foregroundColor(CosmicTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            // Tips
            VStack(alignment: .leading, spacing: 8) {
                tipRow(icon: "checkmark.circle", text: "Make sure stock symbols are visible")
                tipRow(icon: "checkmark.circle", text: "Include quantities and market values if possible")
                tipRow(icon: "checkmark.circle", text: "Use a clear, high-resolution screenshot")
                tipRow(icon: "checkmark.circle", text: "Confirm each row before importing")
            }
            .padding(.top, 4)

            // Supported brokers
            HStack(spacing: 8) {
                ForEach(["Schwab mobile"], id: \.self) { name in
                    Text(name)
                        .font(TerminalFont.data(9))
                        .foregroundColor(CosmicTheme.textMuted)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(CosmicTheme.cardBackground)
                        .clipShape(Capsule())
                }
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

                Text("Extracting rows for review...")
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
            let portfolio = try await PortfolioImportService.parseScreenshot(image)
            parsedPortfolio = portfolio
            isShowingImportReview = true
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }

        isProcessing = false
    }
}

// MARK: - Preview

#Preview("Screenshot Import") {
    ScreenshotImportView()
        .environment(AppState())
        .preferredColorScheme(.dark)
}
