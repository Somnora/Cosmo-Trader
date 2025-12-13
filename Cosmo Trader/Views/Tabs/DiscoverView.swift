import SwiftUI

// MARK: - DiscoverView
// =====================
// A "dating app for stocks" experience with swipeable cards.
//
// FEATURES:
// - Swipeable stock cards with gesture handling
// - Filter by element and sector
// - Sort by compatibility, performance, price
// - Action buttons: Skip (✕), Like (♥), View Detail (★)
// - "Cosmic Match" badges for 85%+ compatibility
//
// DESIGN: Premium dating app aesthetic with cosmic theme

struct DiscoverView: View {

    // MARK: - Environment

    @Environment(AppState.self) private var appState

    // MARK: - State

    @State private var viewModel: DiscoverViewModel?

    /// Current drag offset for top card
    @State private var dragOffset: CGSize = .zero

    /// Rotation angle based on drag
    @State private var dragRotation: Double = 0

    /// Swipe threshold
    private let swipeThreshold: CGFloat = 100

    // MARK: - Body

    /// Get the active view model (create if needed)
    private var vm: DiscoverViewModel {
        viewModel ?? DiscoverViewModel(appState: appState)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                CosmicTheme.background.ignoresSafeArea()

                if let viewModel = viewModel {
                    VStack(spacing: 0) {
                        // Filter controls
                        filterBar

                        // Contrarian mode banner
                        if viewModel.cosmicContrarianMode {
                            contrarianBanner
                        }

                        // Card stack area
                        ZStack {
                            if viewModel.isDeckEmpty {
                                emptyStateView
                            } else {
                                cardStack
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)

                        // Action buttons
                        if !viewModel.isDeckEmpty {
                            actionButtons
                        }
                    }
                } else {
                    ProgressView()
                        .tint(CosmicTheme.gold)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 6) {
                        Image(systemName: "safari.fill")
                            .foregroundColor(CosmicTheme.gold)
                        Text("Discover")
                            .font(.headline)
                            .foregroundColor(CosmicTheme.textPrimary)
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    // Watchlist count badge
                    Button(action: {}) {
                        HStack(spacing: 4) {
                            Image(systemName: "heart.fill")
                                .font(.caption)

                            Text("\(viewModel?.watchlistCount ?? 0)")
                                .font(.caption)
                                .fontWeight(.semibold)
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
            .navigationDestination(item: detailStockBinding) { stock in
                StockDetailView(stock: stock)
            }
            .onAppear {
                if viewModel == nil {
                    viewModel = DiscoverViewModel(appState: appState)
                }
            }
        }
    }

    // Bindings for optional viewModel
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

    // MARK: - Filter Bar

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                // Cosmic Contrarian toggle
                contrarianToggle

                // Filter button
                filterButton

                // Element filters (hide when in contrarian mode)
                if !(viewModel?.cosmicContrarianMode ?? false) {
                    ForEach(ZodiacSign.Element.allCases, id: \.self) { element in
                        elementFilterChip(element)
                    }
                }

                // Sort button (hide when in contrarian mode)
                if !(viewModel?.cosmicContrarianMode ?? false) {
                    sortButton
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(CosmicTheme.background)
    }

    private var contrarianToggle: some View {
        let isActive = viewModel?.cosmicContrarianMode ?? false

        return Button(action: {
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
            .foregroundColor(isActive ? CosmicTheme.background : .purple)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(isActive ? Color.purple : Color.purple.opacity(0.15))
            )
            .overlay(
                Capsule()
                    .stroke(Color.purple.opacity(isActive ? 0 : 0.5), lineWidth: 1)
            )
        }
    }

    private var contrarianBanner: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.body)
                    .foregroundColor(.purple)

                Text("Cosmic Contrarian Mode")
                    .font(TerminalFont.body(14, weight: .semibold))
                    .foregroundColor(.purple)

                Spacer()

                // Challenge badge
                Text("CHALLENGE")
                    .font(TerminalFont.caption(9, weight: .bold))
                    .foregroundColor(CosmicTheme.background)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(
                        Capsule()
                            .fill(Color.purple)
                    )
            }

            Text(viewModel?.contrarianInsight ?? "Showing stocks that challenge your cosmic comfort zone.")
                .font(TerminalFont.caption(12))
                .foregroundColor(CosmicTheme.textSecondary)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.purple.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.purple.opacity(0.3), lineWidth: 1)
                )
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }

    private var filterButton: some View {
        Button(action: { viewModel?.showingFilters = true }) {
            HStack(spacing: 6) {
                Image(systemName: "slider.horizontal.3")
                    .font(.caption)

                Text("Filters")
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .foregroundColor(hasActiveFilters ? CosmicTheme.background : CosmicTheme.textSecondary)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(hasActiveFilters ? CosmicTheme.gold : CosmicTheme.cardBackground)
            )
        }
    }

    private func elementFilterChip(_ element: ZodiacSign.Element) -> some View {
        let isSelected = viewModel?.selectedElement == element

        return Button(action: {
            withAnimation(.spring(response: 0.3)) {
                viewModel?.setElementFilter(isSelected ? nil : element)
            }
        }) {
            HStack(spacing: 4) {
                ElementSymbolView(
                    element: element,
                    size: 12,
                    color: isSelected ? CosmicTheme.background : elementColor(element)
                )

                Text(element.displayName)
                    .font(TerminalFont.data(11))
                    .fontWeight(.medium)
            }
            .foregroundColor(isSelected ? CosmicTheme.background : CosmicTheme.textSecondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(isSelected ? elementColor(element) : CosmicTheme.cardBackground)
            )
        }
    }

    private var sortButton: some View {
        Menu {
            ForEach(SortOption.allCases) { option in
                Button(action: {
                    withAnimation(.spring(response: 0.3)) {
                        viewModel?.setSortOption(option)
                    }
                }) {
                    Label(option.rawValue, systemImage: option.icon)
                }
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: viewModel?.sortOption.icon ?? "sparkles")
                    .font(.caption)

                Text(viewModel?.sortOption.rawValue ?? "Cosmic Match")
                    .font(.caption)
                    .fontWeight(.medium)

                Image(systemName: "chevron.down")
                    .font(.system(size: 8, weight: .bold))
            }
            .foregroundColor(CosmicTheme.textSecondary)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(CosmicTheme.cardBackground)
            )
        }
    }

    private var hasActiveFilters: Bool {
        viewModel?.selectedElement != nil || viewModel?.selectedSector != nil
    }

    // MARK: - Card Stack

    private var cardStack: some View {
        let deck = viewModel?.cardDeck ?? []
        return ZStack {
            // Show up to 3 cards stacked
            ForEach(Array(deck.prefix(3).reversed().enumerated()), id: \.element.id) { index, card in
                let isTop = index == deck.prefix(3).count - 1
                let offset = CGFloat(deck.prefix(3).count - 1 - index) * 8
                let scale = 1.0 - CGFloat(deck.prefix(3).count - 1 - index) * 0.05

                StockCardView(
                    card: card,
                    cardOffset: isTop ? dragOffset : .zero,
                    isTopCard: isTop
                )
                .frame(height: 560)
                .padding(.horizontal, 20)
                .scaleEffect(scale)
                .offset(y: offset)
                .offset(x: isTop ? dragOffset.width : 0, y: isTop ? dragOffset.height : 0)
                .rotationEffect(.degrees(isTop ? dragRotation : 0))
                .gesture(isTop ? dragGesture(for: card) : nil)
                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: dragOffset)
            }
        }
        .padding(.top, 8)
    }

    // MARK: - Drag Gesture

    private func dragGesture(for card: StockCard) -> some Gesture {
        DragGesture()
            .onChanged { value in
                dragOffset = value.translation
                // Rotation based on horizontal drag
                dragRotation = Double(value.translation.width / 20)
            }
            .onEnded { value in
                let horizontalAmount = value.translation.width
                let verticalAmount = value.translation.height

                // Check for swipe up (view detail)
                if verticalAmount < -swipeThreshold {
                    withAnimation(.spring(response: 0.4)) {
                        dragOffset = CGSize(width: 0, height: -600)
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        viewModel?.viewDetail(card.stock)
                        resetCard()
                    }
                }
                // Check for swipe right (like)
                else if horizontalAmount > swipeThreshold {
                    withAnimation(.spring(response: 0.4)) {
                        dragOffset = CGSize(width: 500, height: 0)
                        dragRotation = 15
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        viewModel?.likeStock(card.stock)
                        resetCard()
                    }
                }
                // Check for swipe left (skip)
                else if horizontalAmount < -swipeThreshold {
                    withAnimation(.spring(response: 0.4)) {
                        dragOffset = CGSize(width: -500, height: 0)
                        dragRotation = -15
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        viewModel?.skipStock(card.stock)
                        resetCard()
                    }
                }
                // Return to center
                else {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        resetCard()
                    }
                }
            }
    }

    private func resetCard() {
        dragOffset = .zero
        dragRotation = 0
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        HStack(spacing: 24) {
            // Skip button
            actionButton(
                icon: "xmark",
                color: CosmicTheme.negative,
                size: 54
            ) {
                if let card = viewModel?.topCard {
                    withAnimation(.spring(response: 0.4)) {
                        dragOffset = CGSize(width: -500, height: 0)
                        dragRotation = -15
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        viewModel?.skipStock(card.stock)
                        resetCard()
                    }
                }
            }

            // View detail button
            actionButton(
                icon: "star.fill",
                color: CosmicTheme.gold,
                size: 64
            ) {
                if let card = viewModel?.topCard {
                    withAnimation(.spring(response: 0.4)) {
                        dragOffset = CGSize(width: 0, height: -600)
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        viewModel?.viewDetail(card.stock)
                        resetCard()
                    }
                }
            }

            // Like button
            actionButton(
                icon: "heart.fill",
                color: CosmicTheme.positive,
                size: 54
            ) {
                if let card = viewModel?.topCard {
                    withAnimation(.spring(response: 0.4)) {
                        dragOffset = CGSize(width: 500, height: 0)
                        dragRotation = 15
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        viewModel?.likeStock(card.stock)
                        resetCard()
                    }
                }
            }
        }
        .padding(.vertical, 20)
        .padding(.bottom, 10)
    }

    private func actionButton(
        icon: String,
        color: Color,
        size: CGFloat,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(CosmicTheme.cardBackground)
                    .frame(width: size, height: size)

                Circle()
                    .stroke(color.opacity(0.5), lineWidth: 2)
                    .frame(width: size, height: size)

                Image(systemName: icon)
                    .font(.system(size: size * 0.35, weight: .semibold))
                    .foregroundColor(color)
            }
        }
        .shadow(color: color.opacity(0.2), radius: 8, x: 0, y: 4)
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Image(systemName: "sparkles")
                .font(.system(size: 60))
                .foregroundStyle(CosmicTheme.goldGradient)

            VStack(spacing: 8) {
                Text("No More Stocks")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(CosmicTheme.textPrimary)

                Text("You've seen all available stocks.\nTry adjusting your filters or reset skipped stocks.")
                    .font(.subheadline)
                    .foregroundColor(CosmicTheme.textSecondary)
                    .multilineTextAlignment(.center)
            }

            HStack(spacing: 16) {
                Button(action: {
                    withAnimation {
                        viewModel?.clearFilters()
                    }
                }) {
                    Text("Clear Filters")
                        .font(.headline)
                        .foregroundColor(CosmicTheme.textSecondary)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(
                            Capsule()
                                .stroke(CosmicTheme.textMuted, lineWidth: 1)
                        )
                }

                Button(action: {
                    withAnimation {
                        viewModel?.resetSkipped()
                    }
                }) {
                    Text("Reset Skipped")
                        .font(.headline)
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
                        // Element filter section
                        filterSection(title: "Filter by Element") {
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                                ForEach(ZodiacSign.Element.allCases, id: \.self) { element in
                                    elementFilterOption(element)
                                }
                            }
                        }

                        // Sector filter section
                        filterSection(title: "Filter by Sector") {
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                                ForEach(viewModel?.availableSectors ?? [], id: \.self) { sector in
                                    sectorFilterOption(sector)
                                }
                            }
                        }

                        // Sort section
                        filterSection(title: "Sort By") {
                            VStack(spacing: 8) {
                                ForEach(SortOption.allCases) { option in
                                    sortOptionRow(option)
                                }
                            }
                        }

                        // Reset actions
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
