//
//  SearchService.swift
//  Cosmo Trader
//
//  Manages stock symbol search with debouncing and cancellation.
//  Provides a clean interface for the SearchView to consume.
//

import Foundation
import Combine

// MARK: - Search Service

@MainActor
@Observable
final class SearchService {

    // MARK: - Singleton

    static let shared = SearchService()

    // MARK: - Published State

    /// Current search results
    var results: [SymbolMatch] = []

    /// Whether a search is in progress
    var isSearching: Bool = false

    /// Current error message, if any
    var errorMessage: String?

    /// The current search query
    var searchQuery: String = "" {
        didSet {
            debounceSearch()
        }
    }

    // MARK: - Recent Searches

    /// Recently searched symbols (persisted)
    var recentSearches: [RecentSearch] = []

    /// Maximum number of recent searches to keep
    private let maxRecentSearches = 10

    /// UserDefaults key for recent searches
    private let recentSearchesKey = "recentStockSearches"

    // MARK: - Private Properties

    /// Debounce delay in milliseconds
    private let debounceDelay: UInt64 = 300_000_000 // 300ms in nanoseconds

    /// Current search task (for cancellation)
    private var searchTask: Task<Void, Never>?

    /// Stock API service
    private let stockAPI = StockAPIService.shared

    // MARK: - Init

    private init() {
        loadRecentSearches()
    }

    // MARK: - Public Methods

    /// Clear all search results and query
    func clearSearch() {
        searchTask?.cancel()
        searchQuery = ""
        results = []
        errorMessage = nil
        isSearching = false
    }

    /// Perform an immediate search (no debouncing)
    func searchNow(_ query: String) async {
        searchTask?.cancel()
        searchQuery = query
        await performSearch(query: query)
    }

    /// Add a symbol to recent searches
    func addToRecentSearches(symbol: String, name: String) {
        // Remove if already exists
        recentSearches.removeAll { $0.symbol == symbol }

        // Add to front
        let recent = RecentSearch(symbol: symbol, name: name, date: Date())
        recentSearches.insert(recent, at: 0)

        // Trim to max
        if recentSearches.count > maxRecentSearches {
            recentSearches = Array(recentSearches.prefix(maxRecentSearches))
        }

        saveRecentSearches()
    }

    /// Clear all recent searches
    func clearRecentSearches() {
        recentSearches = []
        saveRecentSearches()
    }

    /// Remove a single recent search
    func removeRecentSearch(_ search: RecentSearch) {
        recentSearches.removeAll { $0.id == search.id }
        saveRecentSearches()
    }

    // MARK: - Private Methods

    /// Debounce the search query
    private func debounceSearch() {
        // Cancel existing search
        searchTask?.cancel()

        let query = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)

        // Clear results if query is empty
        if query.isEmpty {
            results = []
            errorMessage = nil
            isSearching = false
            return
        }

        // Start new debounced search
        searchTask = Task {
            // Wait for debounce delay
            do {
                try await Task.sleep(nanoseconds: debounceDelay)
            } catch {
                // Task was cancelled
                return
            }

            // Check if task was cancelled during sleep
            if Task.isCancelled { return }

            await performSearch(query: query)
        }
    }

    /// Execute the actual search
    private func performSearch(query: String) async {
        // Don't search very short queries
        guard query.count >= 1 else {
            results = []
            return
        }

        isSearching = true
        errorMessage = nil

        do {
            let searchResults = try await stockAPI.searchSymbols(query: query)

            // Check if still relevant (query hasn't changed)
            if searchQuery.trimmingCharacters(in: .whitespacesAndNewlines) == query {
                results = searchResults
            }
        } catch let error as NetworkError {
            // Check if still relevant
            if searchQuery.trimmingCharacters(in: .whitespacesAndNewlines) == query {
                errorMessage = error.cosmicMessage
                results = []
            }
        } catch {
            if !Task.isCancelled {
                errorMessage = "Search failed. Please try again."
                results = []
            }
        }

        isSearching = false
    }

    // MARK: - Persistence

    private func loadRecentSearches() {
        guard let data = UserDefaults.standard.data(forKey: recentSearchesKey),
              let searches = try? JSONDecoder().decode([RecentSearch].self, from: data) else {
            return
        }
        recentSearches = searches
    }

    private func saveRecentSearches() {
        guard let data = try? JSONEncoder().encode(recentSearches) else { return }
        UserDefaults.standard.set(data, forKey: recentSearchesKey)
    }
}

// MARK: - Recent Search Model

struct RecentSearch: Codable, Identifiable, Hashable {
    let id: UUID
    let symbol: String
    let name: String
    let date: Date

    init(symbol: String, name: String, date: Date) {
        self.id = UUID()
        self.symbol = symbol
        self.name = name
        self.date = date
    }

    var formattedDate: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Popular Suggestions

extension SearchService {

    /// Popular stock suggestions for when search is empty
    static let popularSuggestions: [(symbol: String, name: String)] = [
        ("AAPL", "Apple Inc."),
        ("MSFT", "Microsoft Corp."),
        ("GOOGL", "Alphabet Inc."),
        ("AMZN", "Amazon.com Inc."),
        ("NVDA", "NVIDIA Corp."),
        ("TSLA", "Tesla Inc."),
        ("META", "Meta Platforms"),
        ("BRK.B", "Berkshire Hathaway"),
        ("JPM", "JPMorgan Chase"),
        ("V", "Visa Inc.")
    ]
}
