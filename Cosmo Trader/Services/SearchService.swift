//
//  SearchService.swift
//  Cosmo Trader
//

import Foundation
import Combine

// MARK: - SearchService

/// A service that manages stock symbol search with debouncing and result caching.
///
/// `SearchService` provides a responsive search experience by debouncing user input
/// and managing search state. It integrates with ``StockAPIService`` for the actual
/// API calls and maintains a history of recent searches.
///
/// ## Usage
///
/// The service is designed to be bound directly to a SwiftUI `TextField`:
///
/// ```swift
/// @State private var searchService = SearchService.shared
///
/// TextField("Search", text: $searchService.searchQuery)
///
/// ForEach(searchService.results) { result in
///     Text(result.symbol)
/// }
/// ```
///
/// ## Debouncing
///
/// Search requests are debounced by 300ms to prevent excessive API calls:
/// - User types "APP" → waits 300ms → search executes
/// - User types "APPL" before 300ms → previous search cancelled
/// - Only the final query is sent to the API
///
/// ## Recent Searches
///
/// The service maintains a persistent list of recent searches:
/// - Limited to 10 most recent searches
/// - Automatically deduplicated (same symbol moves to top)
/// - Persisted to UserDefaults
///
/// ## Thread Safety
///
/// This service is `@MainActor` isolated. All state changes occur on the main thread,
/// making it safe to bind directly to SwiftUI views.
@MainActor
@Observable
final class SearchService {

    // MARK: - Singleton

    /// Shared singleton instance for app-wide use.
    static let shared = SearchService()

    // MARK: - Observable State

    /// Current search results from the Finnhub API.
    ///
    /// Updated automatically when ``searchQuery`` changes (after debounce).
    /// Empty when no search is active or query is cleared.
    var results: [SymbolMatch] = []

    /// Whether a search request is currently in flight.
    ///
    /// Use this to show loading indicators in the UI.
    var isSearching: Bool = false

    /// Current error message, if any.
    ///
    /// Set when a search fails (network error, rate limit, etc.).
    /// Cleared when a new search starts.
    var errorMessage: String?

    /// Source state for the current symbol-search result set.
    var dataProvenance: FinancialDataProvenance = .unavailable(reason: "Enter a symbol or company name to search Finnhub")

    /// The current search query text.
    ///
    /// Setting this property triggers a debounced search. The search executes
    /// 300ms after the last change, allowing the user to finish typing.
    ///
    /// - Note: Empty or whitespace-only queries clear results immediately.
    var searchQuery: String = "" {
        didSet {
            debounceSearch()
        }
    }

    // MARK: - Recent Searches

    /// Recently searched stock symbols, persisted across app launches.
    ///
    /// Most recent search is at index 0. Limited to ``maxRecentSearches`` entries.
    var recentSearches: [RecentSearch] = []

    /// Maximum number of recent searches to retain (default: 10).
    private let maxRecentSearches = 10

    /// UserDefaults key for persisting recent searches.
    private let recentSearchesKey = "recentStockSearches"

    // MARK: - Private Properties

    /// Debounce delay in nanoseconds (300ms).
    private let debounceDelay: UInt64 = 300_000_000

    /// Current search task, used for cancellation when query changes.
    private var searchTask: Task<Void, Never>?

    /// Reference to the stock API service for search requests.
    private let stockAPI = StockAPIService.shared

    // MARK: - Initialization

    private init() {
        loadRecentSearches()
    }

    // MARK: - Public Methods

    /// Clears all search state and cancels any pending search.
    ///
    /// Call this when dismissing the search interface or when the user
    /// explicitly clears the search field.
    func clearSearch() {
        searchTask?.cancel()
        searchQuery = ""
        results = []
        errorMessage = nil
        dataProvenance = .unavailable(reason: "Enter a symbol or company name to search Finnhub")
        isSearching = false
    }

    /// Performs an immediate search, bypassing the debounce delay.
    ///
    /// Use this for programmatic searches where immediate results are needed,
    /// such as deep linking or restoring search state.
    ///
    /// - Parameter query: The search query to execute.
    func searchNow(_ query: String) async {
        searchTask?.cancel()
        searchQuery = query
        await performSearch(query: query)
    }

    /// Adds a stock to the recent searches list.
    ///
    /// If the symbol already exists in recent searches, it's moved to the top.
    /// The list is automatically trimmed to ``maxRecentSearches`` entries.
    ///
    /// - Parameters:
    ///   - symbol: The stock ticker symbol (e.g., "AAPL").
    ///   - name: The company name (e.g., "Apple Inc.").
    func addToRecentSearches(symbol: String, name: String) {
        // Remove if already exists (will be re-added at front)
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

    /// Removes all recent searches.
    func clearRecentSearches() {
        recentSearches = []
        saveRecentSearches()
    }

    /// Removes a specific entry from recent searches.
    ///
    /// - Parameter search: The ``RecentSearch`` entry to remove.
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
            dataProvenance = .unavailable(reason: "Enter a symbol or company name to search Finnhub")
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
                dataProvenance = .live(provider: FinancialDataProvenance.finnhubProvider, fetchedAt: Date())
            }
        } catch let error as NetworkError {
            // Check if still relevant
            if searchQuery.trimmingCharacters(in: .whitespacesAndNewlines) == query {
                errorMessage = error.cosmicMessage
                dataProvenance = .unavailable(reason: error.cosmicMessage)
                results = []
            }
        } catch {
            if !Task.isCancelled {
                errorMessage = "Search failed. Please try again."
                dataProvenance = .unavailable(reason: "Search failed. Please try again.")
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

// MARK: - RecentSearch

/// A persisted record of a stock the user has previously searched for.
///
/// `RecentSearch` entries are displayed in the search interface when
/// the search field is empty, providing quick access to previously
/// viewed stocks.
struct RecentSearch: Codable, Identifiable, Hashable {
    /// Unique identifier for this search entry.
    let id: UUID

    /// The stock ticker symbol (e.g., "AAPL").
    let symbol: String

    /// The company name (e.g., "Apple Inc.").
    let name: String

    /// When this search was performed.
    let date: Date

    /// Creates a new recent search entry.
    ///
    /// - Parameters:
    ///   - symbol: The stock ticker symbol.
    ///   - name: The company name.
    ///   - date: When the search occurred.
    init(symbol: String, name: String, date: Date) {
        self.id = UUID()
        self.symbol = symbol
        self.name = name
        self.date = date
    }

    /// Human-readable relative time string (e.g., "2h ago", "yesterday").
    var formattedDate: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Popular Suggestions

extension SearchService {

    /// Popular stock suggestions displayed when search field is empty.
    ///
    /// These represent commonly traded stocks that users frequently search for.
    /// Used as fallback suggestions when the user has no recent searches.
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
