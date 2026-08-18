import SwiftUI

// MARK: - StockFramingOverrideSheet
// =================================
// Per-stock reading-framing override sheet, extracted verbatim from
// StockDetailView (view-size ratchet: views render state and forward
// intents). Persistence stays in AppState.

struct StockFramingOverrideSheet: View {

    let stock: Stock
    let companyZodiacSign: ZodiacSign?
    let elementColor: Color

    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    private var user: UserProfile? { appState.currentUser }

    private var hasFramingOverride: Bool {
        user?.stockFramingOverrides[stock.symbol] != nil
    }

    var body: some View {
        NavigationStack {
            ZStack {
                CosmicTheme.background.ignoresSafeArea()

                VStack(spacing: 24) {
                    // Stock info header
                    HStack(spacing: 12) {
                        if let companyZodiacSign {
                            ZodiacSymbolView(sign: companyZodiacSign, size: 40, color: elementColor)
                        } else {
                            Image(systemName: "questionmark.circle")
                                .font(.title2)
                                .foregroundColor(CosmicTheme.textMuted)
                                .frame(width: 40, height: 40)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text(stock.symbol)
                                .font(TerminalFont.headline(18))
                                .foregroundColor(CosmicTheme.textPrimary)

                            Text("Reading Framing Override")
                                .font(TerminalFont.data(12))
                                .foregroundColor(CosmicTheme.textSecondary)
                        }

                        Spacer()
                    }
                    .padding(20)
                    .background(CosmicTheme.cardBackground)

                    // Option to use global or custom
                    VStack(alignment: .leading, spacing: 16) {
                        Text("FRAMING PREFERENCE")
                            .font(TerminalFont.data(10, weight: .semibold))
                            .foregroundColor(CosmicTheme.textMuted)
                            .tracking(1)

                        // Use global toggle
                        Button(action: { removeFramingOverride() }) {
                            HStack {
                                Image(systemName: hasFramingOverride ? "circle" : "checkmark.circle.fill")
                                    .foregroundColor(hasFramingOverride ? CosmicTheme.textMuted : CosmicTheme.gold)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Use Global Setting")
                                        .font(TerminalFont.data(14, weight: .semibold))
                                        .foregroundColor(CosmicTheme.textPrimary)

                                    if let globalLevel = user?.signalFramingLevel {
                                        Text("Currently: \(globalLevel.displayName)")
                                            .font(TerminalFont.data(11))
                                            .foregroundColor(CosmicTheme.textSecondary)
                                    }
                                }

                                Spacer()
                            }
                            .padding(16)
                            .background(CosmicTheme.cardBackground)
                        }
                        .buttonStyle(.plain)

                        // Custom framing slider
                        VStack(alignment: .leading, spacing: 16) {
                            Button(action: { enableCustomFraming() }) {
                                HStack {
                                    Image(systemName: hasFramingOverride ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(hasFramingOverride ? CosmicTheme.gold : CosmicTheme.textMuted)

                                    Text("Custom for \(stock.symbol)")
                                        .font(TerminalFont.data(14, weight: .semibold))
                                        .foregroundColor(CosmicTheme.textPrimary)

                                    Spacer()
                                }
                            }
                            .buttonStyle(.plain)

                            if hasFramingOverride {
                                SignalFramingSlider(level: stockFramingBinding)
                                    .padding(.horizontal, 4)
                            }
                        }
                        .padding(16)
                        .background(CosmicTheme.cardBackground)
                    }
                    .padding(.horizontal, 20)

                    Spacer()

                    // Info text
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "info.circle")
                            .font(.caption)
                            .foregroundColor(CosmicTheme.textMuted)

                        Text("Custom framing lets you view this stock's readings differently from your global setting. Useful if you prefer more rational analysis for some stocks and cosmic framing for others.")
                            .font(TerminalFont.data(11))
                            .foregroundColor(CosmicTheme.textMuted)
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Reading Framing")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(CosmicTheme.gold)
                }
            }
            .toolbarBackground(CosmicTheme.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
        .presentationDetents([.medium])
    }

    /// Binding for the stock-specific framing level (persisted via AppState)
    private var stockFramingBinding: Binding<SignalFramingLevel> {
        Binding(
            get: { appState.framingLevel(for: stock.symbol) },
            set: { appState.setStockFramingOverride(symbol: stock.symbol, level: $0) }
        )
    }

    private func removeFramingOverride() {
        appState.setStockFramingOverride(symbol: stock.symbol, level: nil)
    }

    private func enableCustomFraming() {
        // Initialize with global setting
        let globalLevel = user?.signalFramingLevel ?? .leanRational
        appState.setStockFramingOverride(symbol: stock.symbol, level: globalLevel)
    }
}
