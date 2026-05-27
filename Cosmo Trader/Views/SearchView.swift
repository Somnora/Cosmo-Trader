//
//  SearchView.swift
//  Cosmo Trader
//
//  Stock symbol search with terminal aesthetic.
//  Shows search results, recent searches, and popular suggestions.
//

import SwiftUI

// MARK: - Search View

struct SearchView: View {

    // MARK: - Environment

    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    // MARK: - State

    @State private var searchService = SearchService.shared
    @State private var navPath = NavigationPath()
    @FocusState private var isSearchFieldFocused: Bool

    // MARK: - Body

    var body: some View {
        NavigationStack(path: $navPath) {
            ZStack {
                // Background
                CosmicTheme.background
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Search header
                    searchHeader

                    // Divider
                    Rectangle()
                        .fill(CosmicTheme.border)
                        .frame(height: 1)

                    // Content
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: 0) {
                            if searchService.isSearching {
                                searchingIndicator
                            } else if let error = searchService.errorMessage {
                                errorView(error)
                            } else if !searchService.results.isEmpty {
                                searchResults
                            } else if searchService.searchQuery.isEmpty {
                                emptyStateContent
                            } else {
                                noResultsView
                            }
                        }
                    }
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                isSearchFieldFocused = true
                AnalyticsService.shared.trackSearchOpened()
            }
            .navigationDestination(for: Stock.self) { stock in
                StockDetailView(stock: stock)
                    .environment(appState)
            }
        }
    }

    // MARK: - Search Header

    private var searchHeader: some View {
        VStack(spacing: 12) {
            // Title row with close button
            HStack {
                Text("SEARCH")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(CosmicTheme.textMuted)

                Spacer()

                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(CosmicTheme.textSecondary)
                }
            }

            // Search field
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 14))
                    .foregroundColor(CosmicTheme.textMuted)

                TextField("Symbol or company name...", text: $searchService.searchQuery)
                    .font(.system(size: 15, weight: .medium, design: .monospaced))
                    .foregroundColor(CosmicTheme.textPrimary)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.characters)
                    .focused($isSearchFieldFocused)

                if !searchService.searchQuery.isEmpty {
                    Button {
                        searchService.clearSearch()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(CosmicTheme.textMuted)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(CosmicTheme.cardBackground)
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(CosmicTheme.border, lineWidth: 1)
            )
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - Search Results

    private var searchResults: some View {
        VStack(spacing: 0) {
            // Results header
            HStack {
                Text("RESULTS")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(CosmicTheme.textMuted)

                Text("(\(searchService.results.count))")
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(CosmicTheme.textMuted.opacity(0.6))

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)

            // Results list
            ForEach(searchService.results) { result in
                SearchResultRow(result: result) {
                    selectSearchResult(result)
                }
            }
        }
    }

    // MARK: - Empty State Content

    private var emptyStateContent: some View {
        VStack(spacing: 24) {
            if searchService.recentSearches.isEmpty {
                setupPrimer
            }

            // Recent searches
            if !searchService.recentSearches.isEmpty {
                recentSearchesSection
            }

            // Popular suggestions
            popularSuggestionsSection
        }
        .padding(.top, 8)
    }

    private var setupPrimer: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "scope")
                    .font(.caption)
                    .foregroundColor(CosmicTheme.gold)

                Text("BUILD THE READING")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(CosmicTheme.gold)
                    .tracking(1)
            }

            Text("Search a symbol, open the stock detail, then add it to Portfolio. Start with 3-5 tickers; shares can be refined later.")
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundColor(CosmicTheme.textSecondary)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(CosmicTheme.cardBackground)
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(CosmicTheme.border, lineWidth: 1)
        )
        .padding(.horizontal, 16)
    }

    // MARK: - Recent Searches

    private var recentSearchesSection: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("RECENT")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(CosmicTheme.textMuted)

                Spacer()

                Button {
                    searchService.clearRecentSearches()
                } label: {
                    Text("CLEAR")
                        .font(.system(size: 9, weight: .semibold, design: .monospaced))
                        .foregroundColor(CosmicTheme.gold)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)

            // Recent items
            ForEach(searchService.recentSearches) { recent in
                RecentSearchRow(recent: recent) {
                    selectRecentSearch(recent)
                } onRemove: {
                    searchService.removeRecentSearch(recent)
                }
            }
        }
    }

    // MARK: - Popular Suggestions

    private var popularSuggestionsSection: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("POPULAR")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(CosmicTheme.textMuted)

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)

            // Suggestions grid
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 8),
                GridItem(.flexible(), spacing: 8)
            ], spacing: 8) {
                ForEach(SearchService.popularSuggestions, id: \.symbol) { suggestion in
                    PopularSuggestionButton(symbol: suggestion.symbol, name: suggestion.name) {
                        selectPopularSuggestion(symbol: suggestion.symbol, name: suggestion.name)
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }

    // MARK: - Loading & Error States

    private var searchingIndicator: some View {
        VStack(spacing: 12) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: CosmicTheme.gold))

            Text("Searching...")
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundColor(CosmicTheme.textMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 24))
                .foregroundColor(CosmicTheme.negative)

            Text(message)
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundColor(CosmicTheme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .padding(.horizontal, 32)
    }

    private var noResultsView: some View {
        VStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 24))
                .foregroundColor(CosmicTheme.textMuted)

            Text("No results for \"\(searchService.searchQuery)\"")
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundColor(CosmicTheme.textSecondary)

            Text("Try a different symbol or add a popular ticker to begin portfolio setup")
                .font(.system(size: 10, weight: .regular, design: .monospaced))
                .foregroundColor(CosmicTheme.textMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    // MARK: - Actions

    private func selectSearchResult(_ result: SymbolMatch) {
        // Add to recent searches
        searchService.addToRecentSearches(symbol: result.symbol, name: result.description)

        // Find stock in mock data or create a placeholder
        if let knownStock = knownStock(symbol: result.symbol) {
            navPath.append(knownStock)
        } else {
            // Create placeholder stock for non-mock symbols
            navPath.append(createPlaceholderStock(symbol: result.symbol, name: result.description))
        }
    }

    private func selectRecentSearch(_ recent: RecentSearch) {
        if let knownStock = knownStock(symbol: recent.symbol) {
            navPath.append(knownStock)
        } else {
            navPath.append(createPlaceholderStock(symbol: recent.symbol, name: recent.name))
        }
    }

    private func selectPopularSuggestion(symbol: String, name: String) {
        searchService.addToRecentSearches(symbol: symbol, name: name)

        if let knownStock = knownStock(symbol: symbol) {
            navPath.append(knownStock)
        } else {
            navPath.append(createPlaceholderStock(symbol: symbol, name: name))
        }
    }

    private func knownStock(symbol: String) -> Stock? {
        let normalized = symbol.uppercased()
        return Stock.samples.first { $0.symbol.uppercased() == normalized }
            ?? MockStockData.all.first { $0.symbol.uppercased() == normalized }
    }

    /// Create a placeholder stock for symbols not in mock data
    private func createPlaceholderStock(symbol: String, name: String) -> Stock {
        Stock(
            symbol: symbol,
            name: name,
            currentPrice: 0,
            priceChange: 0,
            percentageChange: 0,
            foundedDate: nil,
            sector: "Unknown"
        )
    }
}

// MARK: - Search Result Row

struct SearchResultRow: View {
    let result: SymbolMatch
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Symbol badge
                Text(result.displaySymbol)
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .foregroundColor(CosmicTheme.gold)
                    .frame(width: 60, alignment: .leading)

                // Company name
                Text(result.description)
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundColor(CosmicTheme.textPrimary)
                    .lineLimit(1)

                Spacer()

                // Chevron
                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(CosmicTheme.textMuted)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(CosmicTheme.background)
        }
        .buttonStyle(PlainButtonStyle())

        // Divider
        Rectangle()
            .fill(CosmicTheme.border)
            .frame(height: 1)
            .padding(.leading, 88)
    }
}

// MARK: - Recent Search Row

struct RecentSearchRow: View {
    let recent: RecentSearch
    let onTap: () -> Void
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onTap) {
                HStack(spacing: 12) {
                    // Clock icon
                    Image(systemName: "clock")
                        .font(.system(size: 11))
                        .foregroundColor(CosmicTheme.textMuted)

                    // Symbol
                    Text(recent.symbol)
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .foregroundColor(CosmicTheme.textPrimary)

                    // Name
                    Text(recent.name)
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundColor(CosmicTheme.textSecondary)
                        .lineLimit(1)

                    Spacer()
                }
            }
            .buttonStyle(PlainButtonStyle())

            // Remove button
            Button(action: onRemove) {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(CosmicTheme.textMuted)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)

        // Divider
        Rectangle()
            .fill(CosmicTheme.border)
            .frame(height: 1)
            .padding(.leading, 44)
    }
}

// MARK: - Popular Suggestion Button

struct PopularSuggestionButton: View {
    let symbol: String
    let name: String
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 4) {
                Text(symbol)
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .foregroundColor(CosmicTheme.gold)

                Text(name)
                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                    .foregroundColor(CosmicTheme.textMuted)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(CosmicTheme.cardBackground)
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(CosmicTheme.border, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview

#Preview {
    SearchView()
        .environment(AppState.preview)
        .preferredColorScheme(.dark)
}
