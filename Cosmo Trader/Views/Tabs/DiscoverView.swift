import SwiftUI

// MARK: - DiscoverView
// =====================
// A swipeable stock discovery surface with portfolio-aware context.
//
// LAYOUT PHILOSOPHY (visual redesign pass):
// - The stock card is the hero. Every other element is supporting.
// - Vertical rhythm is intentional, not uniform: small gap above the
//   chip row, large gap around the card, calm gap before the actions.
// - On compact screens (iPhone SE / older), the layout collapses to a
//   different composition — not just smaller fonts. The context caption
//   is hidden, filters reduce to a single button, and the card grows.

struct DiscoverView: View {

    // MARK: - Environment

    @Environment(AppState.self) private var appState

    // MARK: - State

    @State private var viewModel: DiscoverViewModel?

    /// Current drag offset for top card
    @State private var dragOffset: CGSize = .zero

    /// Rotation angle based on drag
    @State private var dragRotation: Double = 0

    /// Active card id for swipe/drag state
    @State private var activeSwipeCardID: UUID? = nil

    /// Swipe threshold
    private let swipeThreshold: CGFloat = 100

    /// Terminal audio service
    @State private var audioService = TerminalAudioService.shared

    /// Toast message for watchlist feedback
    @State private var watchlistToast: String?

    /// One-time profile hint toast
    @State private var showProfileHint: Bool = false

    /// Search sheet opened from Today activation CTAs.
    @State private var showSearch: Bool = false

    private let profileHintKey = "hasShownDiscoverProfileHint"

    /// Whether the view is ready for interaction
    private var isReady: Bool {
        viewModel != nil
    }

    /// Compact-class screens (SE, mini, older devices). Computed from the
    /// outer GeometryReader so the layout is reactive to actual available
    /// space rather than a hard-coded device check.
    private func isCompactLayout(totalHeight: CGFloat) -> Bool {
        totalHeight < 640
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Group {
                if let viewModel = viewModel {
                    discoverContent(viewModel: viewModel)
                } else {
                    ProgressView()
                        .tint(CosmicTheme.gold)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .background(CosmicTheme.background.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 8) {
                        Text("DISCOVER")
                            .font(TerminalFont.data(13, weight: .semibold))
                            .tracking(1.8)
                            .foregroundColor(CosmicTheme.textPrimary)

                        DataSourceIndicator(
                            provenance: viewModel?.topCard?.priceProvenance,
                            size: .compact
                        )
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        appState.selectedTab = .portfolio
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "eye.fill")
                                .font(.caption)

                            if let count = viewModel?.watchlistCount, count > 0 {
                                Text("\(count)")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                            }
                        }
                        .foregroundColor(CosmicTheme.gold)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(CosmicTheme.cardBackground)
                        )
                    }
                }
            }
            .toolbarBackground(CosmicTheme.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .sheet(isPresented: showingFiltersBinding) {
                filterSheet
            }
            .sheet(isPresented: $showSearch) {
                SearchView()
                    .environment(appState)
            }
            .navigationDestination(item: detailStockBinding) { stock in
                StockDetailView(stock: stock)
            }
            .task {
                if viewModel == nil {
                    viewModel = DiscoverViewModel(appState: appState)
                }
                await viewModel?.refreshProviderQuotesForDeck()
                showProfileHintIfNeeded()
            }
            .onChange(of: viewModel?.isDeckEmpty ?? true) { _, isEmpty in
                if !isEmpty {
                    showProfileHintIfNeeded()
                }
            }
            .onAppear {
                consumeNavigationIntentIfNeeded()
            }
            .onChange(of: appState.pendingNavigationIntent) { _, _ in
                consumeNavigationIntentIfNeeded()
            }
            .overlay(alignment: .top) {
                VStack(spacing: 8) {
                    if let toast = watchlistToast {
                        watchlistToastView(toast)
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }

                    if showProfileHint {
                        profileHintToastView
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }
                }
                .zIndex(100)
                .allowsHitTesting(false)
            }
        }
    }

    private func consumeNavigationIntentIfNeeded() {
        guard appState.pendingNavigationIntent == .discoverSearch else { return }
        showSearch = true
        appState.pendingNavigationIntent = nil
    }

    // MARK: - Toasts

    private func watchlistToastView(_ message: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "eye.fill")
                .font(.caption)
                .foregroundColor(CosmicTheme.gold)

            Text(message)
                .font(TerminalFont.data(12, weight: .medium))
                .foregroundColor(CosmicTheme.textPrimary)

            Text("View in Portfolio")
                .font(TerminalFont.data(10))
                .foregroundColor(CosmicTheme.textMuted)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            Capsule()
                .fill(CosmicTheme.cardBackground)
                .shadow(color: Color.black.opacity(0.3), radius: 8, y: 4)
        )
        .overlay(
            Capsule()
                .stroke(CosmicTheme.gold.opacity(0.3), lineWidth: 1)
        )
        .padding(.top, 60)
    }

    private func showWatchlistToast(for symbol: String) {
        HapticFeedback.success()
        withAnimation(.spring(response: 0.3)) {
            watchlistToast = "\(symbol) added to watchlist"
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(.easeOut(duration: 0.2)) {
                watchlistToast = nil
            }
        }
    }

    private var profileHintToastView: some View {
        HStack(spacing: 8) {
            Image(systemName: "hand.tap.fill")
                .font(.caption)
                .foregroundColor(CosmicTheme.gold)

            Text("Tap the company name to open the full reading")
                .font(TerminalFont.data(12, weight: .medium))
                .foregroundColor(CosmicTheme.textPrimary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            Capsule()
                .fill(CosmicTheme.cardBackground)
                .shadow(color: Color.black.opacity(0.3), radius: 8, y: 4)
        )
        .overlay(
            Capsule()
                .stroke(CosmicTheme.gold.opacity(0.3), lineWidth: 1)
        )
        .padding(.top, 120)
        .padding(.horizontal, 20)
    }

    private func showProfileHintIfNeeded() {
        guard !AppState.isScreenshotMode else { return }
        guard !UserDefaults.standard.bool(forKey: profileHintKey) else { return }
        guard !showProfileHint else { return }
        guard !(viewModel?.isDeckEmpty ?? true) else { return }

        UserDefaults.standard.set(true, forKey: profileHintKey)
        withAnimation(.spring(response: 0.3)) {
            showProfileHint = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation(.easeOut(duration: 0.2)) {
                showProfileHint = false
            }
        }
    }

    private var showingFiltersBinding: Binding<Bool> {
        Binding(
            get: { viewModel?.showingFilters ?? false },
            set: { viewModel?.showingFilters = $0 }
        )
    }

    private var detailStockBinding: Binding<Stock?> {
        Binding(
            get: { viewModel?.detailStock },
            set: { viewModel?.detailStock = $0 }
        )
    }

    // MARK: - Context Caption (replaces heavy proof strip)

    /// A single muted line that signals what's driving the deck. On
    /// regular-class screens it sits above the filter chips like a
    /// breadcrumb. On compact screens it's hidden entirely so the card
    /// can claim that space.
    private var discoverContextCaption: some View {
        let holdingsCount = appState.currentUser?.portfolio.filter(\.isOwned).count ?? 0
        let holdingsLabel = holdingsCount > 0
            ? "\(holdingsCount) holdings shape the reading"
            : "Add holdings to sharpen context"

        // One Text composed via concatenation so the bullet stays on
        // the same line as the surrounding fragments (multiple Text
        // siblings inside an HStack let the first wrap independently).
        return HStack(spacing: 8) {
            Image(systemName: "scope")
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(CosmicTheme.gold.opacity(0.8))

            (
                Text("Ranked by cosmic match")
                    .foregroundColor(CosmicTheme.textSecondary)
                + Text("  ·  ")
                    .foregroundColor(CosmicTheme.textDisabled)
                + Text(holdingsLabel)
                    .foregroundColor(CosmicTheme.textMuted)
            )
            .font(TerminalFont.data(11))
            .lineLimit(1)
            .minimumScaleFactor(0.85)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Filter Chips

    /// A trimmed-down chip row. On regular: Contrarian + Filters + Sort.
    /// On compact: Contrarian + a single Filters button (with an active
    /// count badge so users still see what's set). Element chips moved
    /// into the Filters sheet — they were a third row of widgets before.
    private func filterChipRow(isCompact: Bool) -> some View {
        HStack(spacing: 10) {
            contrarianToggle

            Spacer()

            if !(viewModel?.cosmicContrarianMode ?? false) {
                filterButton
                if !isCompact {
                    sortButton
                }
            }
        }
        .padding(.horizontal, 20)
    }

    private var contrarianToggle: some View {
        let isActive = viewModel?.cosmicContrarianMode ?? false

        return Button(action: {
            guard isReady else { return }
            withAnimation(.spring(response: 0.3)) {
                viewModel?.toggleContrarianMode()
            }
        }) {
            HStack(spacing: 6) {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.caption)

                Text("Contrarian")
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .foregroundColor(isActive ? CosmicTheme.textPrimary : CosmicTheme.accentBlue)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(isActive ? CosmicTheme.terminalNavy : CosmicTheme.terminalNavy.opacity(0.32))
            )
            .overlay(
                Capsule()
                    .stroke(CosmicTheme.accentBlue.opacity(isActive ? 0.45 : 0.55), lineWidth: 1)
            )
        }
        .disabled(!isReady)
    }

    private var contrarianBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "arrow.triangle.2.circlepath")
                .font(.caption)
                .foregroundColor(CosmicTheme.accentBlue)

            Text(viewModel?.contrarianInsight ?? "Showing stocks outside your usual cosmic profile.")
                .font(TerminalFont.caption(11))
                .foregroundColor(CosmicTheme.textSecondary)
                .multilineTextAlignment(.leading)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(CosmicTheme.terminalNavy.opacity(0.32))
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(CosmicTheme.accentBlue.opacity(0.32), lineWidth: 1)
                )
        )
        .padding(.horizontal, 20)
    }

    /// The Filters button. Carries an active-count badge so the user can
    /// see at a glance what's set without us painting a row of chips.
    private var filterButton: some View {
        Button(action: {
            guard isReady else { return }
            viewModel?.showingFilters = true
        }) {
            HStack(spacing: 6) {
                Image(systemName: "slider.horizontal.3")
                    .font(.caption)

                Text("Filters")
                    .font(.caption)
                    .fontWeight(.medium)

                if activeFilterCount > 0 {
                    Text("\(activeFilterCount)")
                        .font(TerminalFont.data(9, weight: .bold))
                        .foregroundColor(CosmicTheme.background)
                        .frame(minWidth: 14, minHeight: 14)
                        .padding(.horizontal, 3)
                        .background(
                            Capsule()
                                .fill(CosmicTheme.gold)
                        )
                }
            }
            .foregroundColor(activeFilterCount > 0 ? CosmicTheme.textPrimary : CosmicTheme.textSecondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(CosmicTheme.cardBackground)
            )
            .overlay(
                Capsule()
                    .stroke(activeFilterCount > 0 ? CosmicTheme.gold.opacity(0.5) : CosmicTheme.border, lineWidth: 1)
            )
        }
        .disabled(!isReady)
    }

    private var sortButton: some View {
        Menu {
            ForEach(SortOption.allCases) { option in
                Button(action: {
                    guard isReady else { return }
                    withAnimation(.spring(response: 0.3)) {
                        viewModel?.setSortOption(option)
                    }
                }) {
                    Label(option.rawValue, systemImage: option.icon)
                }
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: viewModel?.sortOption.icon ?? "scope")
                    .font(.caption)

                Text(viewModel?.sortOption.rawValue ?? "Cosmic Match")
                    .font(.caption)
                    .fontWeight(.medium)

                Image(systemName: "chevron.down")
                    .font(.system(size: 8, weight: .bold))
            }
            .foregroundColor(CosmicTheme.textSecondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(CosmicTheme.cardBackground)
            )
            .overlay(
                Capsule()
                    .stroke(CosmicTheme.border, lineWidth: 1)
            )
        }
        .disabled(!isReady)
    }

    private var activeFilterCount: Int {
        var count = 0
        if viewModel?.selectedElement != nil { count += 1 }
        if viewModel?.selectedSector != nil { count += 1 }
        return count
    }

    // MARK: - Card Stack

    private func cardStack(height: CGFloat, isCompactLayout: Bool) -> some View {
        let deck = viewModel?.cardDeck ?? []
        return ZStack {
            ForEach(Array(deck.prefix(3).reversed().enumerated()), id: \.element.id) { index, card in
                let isTop = index == deck.prefix(3).count - 1
                let isActive = card.id == activeSwipeCardID
                let offset = CGFloat(deck.prefix(3).count - 1 - index) * 8
                let scale = 1.0 - CGFloat(deck.prefix(3).count - 1 - index) * 0.05
                let topScale: CGFloat = {
                    if isTop {
                        return isActive ? cardScale : 1.0
                    }
                    return scale
                }()

                StockCardView(
                    card: card,
                    cardOffset: isActive ? dragOffset : .zero,
                    isTopCard: isTop,
                    isCompact: isCompactLayout,
                    onOpenProfile: isTop ? { viewModel?.viewDetail(card.stock, source: "discover_card_tap") } : nil
                )
                .frame(height: height)
                .padding(.horizontal, isCompactLayout ? 16 : 20)
                .scaleEffect(topScale)
                .offset(y: offset)
                .offset(x: isActive ? dragOffset.width : 0, y: isActive ? dragOffset.height : 0)
                .rotationEffect(.degrees(isActive ? dragRotation : 0))
                .allowsHitTesting(isTop)
                .highPriorityGesture(dragGesture(for: card))
            }

            SwipeIndicatorOverlay(offset: dragOffset.width, threshold: swipeThreshold)
                .allowsHitTesting(false)
        }
    }

    private var cardScale: CGFloat {
        let progress = abs(dragOffset.width) / 200
        return 1.0 - (progress * 0.03)
    }

    // MARK: - Drag Gesture

    @State private var isSwipeAnimating: Bool = false

    private func dragGesture(for card: StockCard) -> some Gesture {
        DragGesture()
            .onChanged { value in
                guard isReady, !isSwipeAnimating else { return }

                let horizontalDrag = abs(value.translation.width)
                let verticalDrag = abs(value.translation.height)

                guard horizontalDrag > verticalDrag else { return }

                activeSwipeCardID = card.id
                dragOffset = CGSize(width: value.translation.width, height: 0)
                dragRotation = Double(value.translation.width / 20)
            }
            .onEnded { value in
                guard isReady, !isSwipeAnimating else {
                    resetCard()
                    return
                }

                let horizontalAmount = value.translation.width
                let verticalAmount = abs(value.translation.height)

                guard abs(horizontalAmount) > verticalAmount else {
                    resetCard()
                    return
                }

                if horizontalAmount > swipeThreshold {
                    swipeCard(direction: .right, card: card)
                } else if horizontalAmount < -swipeThreshold {
                    swipeCard(direction: .left, card: card)
                } else {
                    resetCard()
                }
            }
    }

    private enum SwipeDirection {
        case left, right
    }

    private func swipeCard(direction: SwipeDirection, card: StockCard) {
        guard !isSwipeAnimating else { return }
        isSwipeAnimating = true
        activeSwipeCardID = card.id

        let offscreenX: CGFloat = direction == .right ? 500 : -500
        let rotation: Double = direction == .right ? 15 : -15

        audioService.playSwipe(direction: direction == .right ? .right : .left)
        HapticFeedback.medium()

        withAnimation(.easeOut(duration: 0.25)) {
            dragOffset = CGSize(width: offscreenX, height: 0)
            dragRotation = rotation
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.28) {
            Task { @MainActor in
                await ReferralService.shared.qualifyReferralIfNeeded(
                    milestone: .firstSwipeSession,
                    storageKey: ReferralMilestone.firstSwipeSession.qualificationStorageKey
                )
            }

            if direction == .right {
                viewModel?.likeStock(card.stock)
                showWatchlistToast(for: card.stock.symbol)
            } else {
                viewModel?.skipStock(card.stock)
            }

            dragOffset = .zero
            dragRotation = 0
            activeSwipeCardID = nil

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                isSwipeAnimating = false
            }
        }
    }

    private func resetCard() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            dragOffset = .zero
            dragRotation = 0
            activeSwipeCardID = nil
        }
    }

    // MARK: - Layout

    /// New composition. Top-level GeometryReader gives us actual
    /// available height so we can:
    ///   1. decide compact vs regular layout density
    ///   2. let the card claim flex space without fighting the chips
    ///      and actions for fixed pixels
    @ViewBuilder
    private func discoverContent(viewModel: DiscoverViewModel) -> some View {
        GeometryReader { geo in
            let isCompact = isCompactLayout(totalHeight: geo.size.height)
            // Vertical rhythm: tight near the top (chips), generous
            // around the card, calm before the actions. Different gap
            // sizes are deliberate — uniform spacing was the source of
            // the "everything reads at the same weight" problem.
            let topInset: CGFloat = isCompact ? 6 : 14
            let chipsToCardGap: CGFloat = isCompact ? 12 : 20
            let cardToActionsGap: CGFloat = isCompact ? 16 : 24
            let actionsToBottomGap: CGFloat = isCompact ? 12 : 20
            let isRegularWidth = geo.size.width >= 700
            // On iPad we deliberately keep the card from ballooning to fill
            // the canvas — a 700pt+ card with our content density reads as
            // empty no matter how much we space out the internals. Capping
            // it ~620 lets the surrounding context caption + chips + action
            // row breathe instead of stranding the card in dead space.
            let cardHeight = isRegularWidth ? min(max(540, geo.size.height * 0.48), 640) : nil

            VStack(spacing: 0) {
                Color.clear.frame(height: topInset)

                // Context caption (regular only). Replaces the heavy
                // "WHY THIS NAME TODAY" panel that was eating prime
                // vertical space.
                if !isCompact {
                    discoverContextCaption
                    Color.clear.frame(height: 10)
                }

                filterChipRow(isCompact: isCompact)

                if viewModel.cosmicContrarianMode {
                    Color.clear.frame(height: 8)
                    contrarianBanner
                }

                Color.clear.frame(height: chipsToCardGap)

                // On iPad, absorb leftover vertical space into a flex spacer
                // above the card so the card+actions block centers in the
                // available area instead of top-anchoring with a giant
                // bottom void.
                if isRegularWidth {
                    Spacer(minLength: 0)
                }

                // Hero card area. Flex height — claims everything left.
                ZStack {
                    if viewModel.isDeckEmpty {
                        emptyStateView
                    } else {
                        GeometryReader { cardGeo in
                            cardStack(
                                height: cardGeo.size.height,
                                isCompactLayout: isCompact
                            )
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .frame(height: cardHeight)

                if !viewModel.isDeckEmpty {
                    Color.clear.frame(height: cardToActionsGap)
                    actionRow(isCompact: isCompact)
                    Color.clear.frame(height: actionsToBottomGap)
                }

                if isRegularWidth {
                    Spacer(minLength: 0)
                }
            }
            .iPadReadableContent(maxWidth: 820)
            .frame(height: geo.size.height)
        }
    }

    // MARK: - Action Row

    /// Action buttons + a small swipe hint underneath. Sized so the
    /// row reads as deliberate but doesn't compete with the card. The
    /// hint reinforces that swipe is the primary interaction and the
    /// buttons are secondary affordances.
    private func actionRow(isCompact: Bool) -> some View {
        let buttonSize: CGFloat = isCompact ? 50 : 56
        return VStack(spacing: isCompact ? 6 : 10) {
            HStack(spacing: isCompact ? 28 : 36) {
                actionButton(
                    icon: "xmark",
                    color: CosmicTheme.negative,
                    size: buttonSize,
                    accessibilityLabel: "Skip stock"
                ) {
                    guard isReady, !isSwipeAnimating, let card = viewModel?.topCard else { return }
                    HapticFeedback.light()
                    swipeCard(direction: .left, card: card)
                }

                actionButton(
                    icon: "book.closed.fill",
                    color: CosmicTheme.gold,
                    size: buttonSize - 8,
                    accessibilityLabel: "Open full reading"
                ) {
                    guard isReady, !isSwipeAnimating, let card = viewModel?.topCard else { return }
                    HapticFeedback.medium()
                    viewModel?.viewDetail(card.stock, source: "discover_profile_button")
                }

                actionButton(
                    icon: "eye.fill",
                    color: CosmicTheme.positive,
                    size: buttonSize,
                    accessibilityLabel: "Add to watchlist"
                ) {
                    guard isReady, !isSwipeAnimating, let card = viewModel?.topCard else { return }
                    HapticFeedback.medium()
                    swipeCard(direction: .right, card: card)
                }
            }

            if !isCompact {
                HStack(spacing: 12) {
                    Text("← skip")
                        .font(TerminalFont.data(10))
                        .foregroundColor(CosmicTheme.textMuted)
                        .tracking(0.5)

                    Text("·")
                        .font(TerminalFont.data(10))
                        .foregroundColor(CosmicTheme.textDisabled)

                    Text("swipe to save")
                        .font(TerminalFont.data(10, weight: .medium))
                        .foregroundColor(CosmicTheme.textSecondary)
                        .tracking(0.5)

                    Text("·")
                        .font(TerminalFont.data(10))
                        .foregroundColor(CosmicTheme.textDisabled)

                    Text("save →")
                        .font(TerminalFont.data(10))
                        .foregroundColor(CosmicTheme.textMuted)
                        .tracking(0.5)
                }
            }
        }
    }

    private func actionButton(
        icon: String,
        color: Color,
        size: CGFloat,
        accessibilityLabel: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(CosmicTheme.cardBackground)
                    .frame(width: size, height: size)

                Circle()
                    .stroke(color.opacity(0.5), lineWidth: 1.5)
                    .frame(width: size, height: size)

                Image(systemName: icon)
                    .font(.system(size: size * 0.36, weight: .semibold))
                    .foregroundColor(color)
            }
        }
        .buttonStyle(.bouncy)
        .accessibilityLabel(accessibilityLabel)
        .shadow(color: color.opacity(0.18), radius: 6, x: 0, y: 3)
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Image(systemName: "rectangle.stack")
                .font(.system(size: 60))
                .foregroundStyle(CosmicTheme.goldGradient)

            VStack(spacing: 8) {
                Text("All Caught Up")
                    .font(.system(size: 18, weight: .bold, design: .monospaced))
                    .foregroundColor(CosmicTheme.textPrimary)

                Text("You've seen all available stocks.\nCheck back tomorrow for new candidates.")
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundColor(CosmicTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }

            HStack(spacing: 16) {
                Button(action: {
                    HapticFeedback.light()
                    withAnimation {
                        viewModel?.clearFilters()
                    }
                }) {
                    Text("Clear Filters")
                        .font(.system(size: 13, weight: .medium, design: .monospaced))
                        .foregroundColor(CosmicTheme.textSecondary)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(
                            Capsule()
                                .stroke(CosmicTheme.textMuted, lineWidth: 1)
                        )
                }

                Button(action: {
                    HapticFeedback.medium()
                    withAnimation {
                        viewModel?.resetSkipped()
                    }
                }) {
                    Text("Reset Skipped")
                        .font(.system(size: 13, weight: .medium, design: .monospaced))
                        .foregroundColor(CosmicTheme.background)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(
                            Capsule()
                                .fill(CosmicTheme.gold)
                        )
                }
            }
        }
        .padding(40)
    }

    // MARK: - Filter Sheet

    private var filterSheet: some View {
        NavigationStack {
            ZStack {
                CosmicTheme.background.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        filterSection(title: "Filter by Element") {
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                                ForEach(ZodiacSign.Element.allCases, id: \.self) { element in
                                    elementFilterOption(element)
                                }
                            }
                        }

                        filterSection(title: "Filter by Sector") {
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                                ForEach(viewModel?.availableSectors ?? [], id: \.self) { sector in
                                    sectorFilterOption(sector)
                                }
                            }
                        }

                        filterSection(title: "Sort By") {
                            VStack(spacing: 8) {
                                ForEach(SortOption.allCases) { option in
                                    sortOptionRow(option)
                                }
                            }
                        }

                        VStack(spacing: 12) {
                            Button(action: {
                                viewModel?.clearFilters()
                            }) {
                                HStack {
                                    Image(systemName: "arrow.counterclockwise")
                                    Text("Clear All Filters")
                                }
                                .font(.headline)
                                .foregroundColor(CosmicTheme.textSecondary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(CosmicTheme.textMuted, lineWidth: 1)
                                )
                            }

                            Button(action: {
                                viewModel?.resetSkipped()
                            }) {
                                HStack {
                                    Image(systemName: "arrow.uturn.backward")
                                    Text("Reset Skipped Stocks (\(viewModel?.skippedCount ?? 0))")
                                }
                                .font(.headline)
                                .foregroundColor(CosmicTheme.background)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(CosmicTheme.gold)
                                )
                            }
                        }
                        .padding(.top, 16)
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        viewModel?.showingFilters = false
                    }
                    .foregroundColor(CosmicTheme.gold)
                }
            }
            .toolbarBackground(CosmicTheme.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
        .presentationDetents([.medium, .large])
    }

    private func filterSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(CosmicTheme.textPrimary)

            content()
        }
    }

    private func elementFilterOption(_ element: ZodiacSign.Element) -> some View {
        let isSelected = viewModel?.selectedElement == element

        return Button(action: {
            withAnimation(.spring(response: 0.3)) {
                viewModel?.setElementFilter(isSelected ? nil : element)
            }
        }) {
            HStack {
                ElementSymbolView(element: element, size: 24)

                Text(element.displayName)
                    .font(TerminalFont.data(14))
                    .fontWeight(.medium)

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(elementColor(element))
                }
            }
            .foregroundColor(isSelected ? elementColor(element) : CosmicTheme.textSecondary)
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? elementColor(element).opacity(0.15) : CosmicTheme.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? elementColor(element).opacity(0.5) : Color.clear, lineWidth: 1)
            )
        }
    }

    private func sectorFilterOption(_ sector: String) -> some View {
        let isSelected = viewModel?.selectedSector == sector

        return Button(action: {
            withAnimation(.spring(response: 0.3)) {
                viewModel?.setSectorFilter(isSelected ? nil : sector)
            }
        }) {
            HStack {
                Text(sector)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(CosmicTheme.gold)
                }
            }
            .foregroundColor(isSelected ? CosmicTheme.gold : CosmicTheme.textSecondary)
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? CosmicTheme.gold.opacity(0.15) : CosmicTheme.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? CosmicTheme.gold.opacity(0.5) : Color.clear, lineWidth: 1)
            )
        }
    }

    private func sortOptionRow(_ option: SortOption) -> some View {
        let isSelected = viewModel?.sortOption == option

        return Button(action: {
            withAnimation(.spring(response: 0.3)) {
                viewModel?.setSortOption(option)
            }
        }) {
            HStack {
                Image(systemName: option.icon)
                    .font(.headline)
                    .foregroundColor(isSelected ? CosmicTheme.gold : CosmicTheme.textMuted)
                    .frame(width: 30)

                Text(option.rawValue)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundColor(CosmicTheme.gold)
                }
            }
            .foregroundColor(isSelected ? CosmicTheme.textPrimary : CosmicTheme.textSecondary)
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? CosmicTheme.gold.opacity(0.1) : CosmicTheme.cardBackground)
            )
        }
    }

    // MARK: - Helpers

    private func elementColor(_ element: ZodiacSign.Element) -> Color {
        switch element {
        case .fire:  return Color(red: 1.0, green: 0.4, blue: 0.3)
        case .earth: return Color(red: 0.4, green: 0.75, blue: 0.4)
        case .air:   return Color(red: 0.4, green: 0.6, blue: 0.9)
        case .water: return Color(red: 0.5, green: 0.3, blue: 0.8)
        }
    }
}

// MARK: - Preview

#Preview("Discover View") {
    DiscoverView()
        .environment(AppState.preview)
        .preferredColorScheme(.dark)
}
