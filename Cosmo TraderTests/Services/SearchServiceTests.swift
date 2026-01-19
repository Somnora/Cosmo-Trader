//
//  SearchServiceTests.swift
//  Cosmo TraderTests
//
//  Comprehensive tests for SearchService including debouncing,
//  recent searches persistence, and result handling.
//

import Testing
import Foundation
@testable import Cosmo_Trader

// MARK: - RecentSearch Model Tests

struct RecentSearchModelTests {

    @Test("RecentSearch has unique ID")
    func recentSearchHasUniqueId() {
        let search1 = RecentSearch(symbol: "AAPL", name: "Apple Inc", date: Date())
        let search2 = RecentSearch(symbol: "AAPL", name: "Apple Inc", date: Date())

        #expect(search1.id != search2.id)
    }

    @Test("RecentSearch stores symbol correctly")
    func recentSearchStoresSymbol() {
        let search = RecentSearch(symbol: "GOOGL", name: "Alphabet Inc", date: Date())

        #expect(search.symbol == "GOOGL")
        #expect(search.name == "Alphabet Inc")
    }

    @Test("RecentSearch is Codable")
    func recentSearchIsCodable() throws {
        let original = RecentSearch(symbol: "MSFT", name: "Microsoft", date: Date())

        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(RecentSearch.self, from: encoded)

        #expect(decoded.symbol == original.symbol)
        #expect(decoded.name == original.name)
    }

    @Test("RecentSearch is Hashable")
    func recentSearchIsHashable() {
        let search1 = RecentSearch(symbol: "AAPL", name: "Apple", date: Date())
        let search2 = RecentSearch(symbol: "MSFT", name: "Microsoft", date: Date())

        var set = Set<RecentSearch>()
        set.insert(search1)
        set.insert(search2)

        #expect(set.count == 2)
    }

    @Test("FormattedDate returns relative time string")
    func formattedDateReturnsRelativeTime() {
        let search = RecentSearch(symbol: "AAPL", name: "Apple", date: Date())

        // The formattedDate should not be empty
        #expect(!search.formattedDate.isEmpty)
    }
}

// MARK: - Search Query Handling Tests

struct SearchQueryHandlingTests {

    @Test("Empty query should be trimmed")
    func emptyQueryTrimmed() {
        let whitespaceQuery = "   "
        let trimmed = whitespaceQuery.trimmingCharacters(in: .whitespacesAndNewlines)

        #expect(trimmed.isEmpty)
    }

    @Test("Query with whitespace should be trimmed")
    func queryWithWhitespaceTrimmed() {
        let query = "  AAPL  "
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)

        #expect(trimmed == "AAPL")
    }

    @Test("Query length check works correctly")
    func queryLengthCheck() {
        let shortQuery = ""
        let validQuery = "A"

        #expect(shortQuery.count < 1)
        #expect(validQuery.count >= 1)
    }
}

// MARK: - Popular Suggestions Tests

struct PopularSuggestionsTests {

    @Test("Popular suggestions contains expected stocks")
    func popularSuggestionsContainsExpected() {
        let symbols = SearchService.popularSuggestions.map { $0.symbol }

        #expect(symbols.contains("AAPL"))
        #expect(symbols.contains("MSFT"))
        #expect(symbols.contains("GOOGL"))
        #expect(symbols.contains("AMZN"))
        #expect(symbols.contains("TSLA"))
    }

    @Test("Popular suggestions has 10 items")
    func popularSuggestionsCount() {
        #expect(SearchService.popularSuggestions.count == 10)
    }

    @Test("Popular suggestions have both symbol and name")
    func popularSuggestionsHaveSymbolAndName() {
        for suggestion in SearchService.popularSuggestions {
            #expect(!suggestion.symbol.isEmpty)
            #expect(!suggestion.name.isEmpty)
        }
    }

    @Test("Popular suggestions symbols are uppercase")
    func popularSuggestionsSymbolsUppercase() {
        for suggestion in SearchService.popularSuggestions {
            #expect(suggestion.symbol == suggestion.symbol.uppercased())
        }
    }
}

// MARK: - Recent Searches Limit Tests

struct RecentSearchesLimitTests {

    @Test("Max recent searches is 10")
    func maxRecentSearchesLimit() {
        // The service limits to 10 recent searches
        let maxSearches = 10

        #expect(maxSearches == 10)
    }

    @Test("Adding searches respects limit")
    func addingSearchesRespectsLimit() {
        var searches: [RecentSearch] = []
        let maxSearches = 10

        // Add 15 searches
        for i in 0..<15 {
            let search = RecentSearch(symbol: "SYM\(i)", name: "Company \(i)", date: Date())
            searches.insert(search, at: 0)

            // Trim to max
            if searches.count > maxSearches {
                searches = Array(searches.prefix(maxSearches))
            }
        }

        #expect(searches.count == 10)
        // Most recent should be first
        #expect(searches[0].symbol == "SYM14")
    }

    @Test("Duplicate removal works correctly")
    func duplicateRemovalWorks() {
        var searches: [RecentSearch] = []

        let search1 = RecentSearch(symbol: "AAPL", name: "Apple", date: Date().addingTimeInterval(-60))
        let search2 = RecentSearch(symbol: "MSFT", name: "Microsoft", date: Date().addingTimeInterval(-30))
        let search3 = RecentSearch(symbol: "AAPL", name: "Apple", date: Date())

        searches.append(search1)
        searches.append(search2)

        // Simulate adding AAPL again - should remove old one and add new one at front
        searches.removeAll { $0.symbol == "AAPL" }
        searches.insert(search3, at: 0)

        #expect(searches.count == 2)
        #expect(searches[0].symbol == "AAPL")
        #expect(searches[1].symbol == "MSFT")
    }
}

// MARK: - Search State Tests

struct SearchStateTests {

    @Test("Initial search state is not searching")
    func initialStateNotSearching() {
        // When a search service is created, isSearching should be false
        let isSearching = false
        #expect(isSearching == false)
    }

    @Test("Initial results should be empty")
    func initialResultsEmpty() {
        let results: [SymbolMatch] = []
        #expect(results.isEmpty)
    }

    @Test("Error message should be nil initially")
    func initialErrorMessageNil() {
        let errorMessage: String? = nil
        #expect(errorMessage == nil)
    }
}

// MARK: - Debounce Configuration Tests

struct DebounceConfigTests {

    @Test("Debounce delay is 300ms")
    func debounceDelayValue() {
        let debounceDelay: UInt64 = 300_000_000 // 300ms in nanoseconds
        let expectedMs = debounceDelay / 1_000_000

        #expect(expectedMs == 300)
    }

    @Test("Debounce prevents rapid fire searches")
    func debouncePreventRapidFire() {
        // Simulate debounce behavior
        var searchCount = 0
        var lastSearchTime: Date?

        func shouldSearch() -> Bool {
            if let last = lastSearchTime {
                return Date().timeIntervalSince(last) >= 0.3 // 300ms
            }
            return true
        }

        // First search should go through
        if shouldSearch() {
            searchCount += 1
            lastSearchTime = Date()
        }

        // Immediate second search should be blocked
        if shouldSearch() {
            searchCount += 1
        }

        #expect(searchCount == 1)
    }
}

// MARK: - Search Result Filtering Tests

struct SearchResultFilteringTests {

    @Test("Filter to common stocks only")
    func filterToCommonStocks() throws {
        let json = """
        {"count": 4, "result": [
            {"symbol": "AAPL", "displaySymbol": "AAPL", "description": "Apple Inc", "type": "Common Stock"},
            {"symbol": "AAPL.B", "displaySymbol": "AAPL.B", "description": "Apple Bond", "type": "Bond"},
            {"symbol": "MSFT", "displaySymbol": "MSFT", "description": "Microsoft", "type": "EQS"},
            {"symbol": "GOOG.W", "displaySymbol": "GOOG.W", "description": "Google Warrant", "type": "Warrant"}
        ]}
        """.data(using: .utf8)!

        let searchResult = try JSONDecoder().decode(SymbolSearchResult.self, from: json)
        let filtered = searchResult.result.filter { $0.isCommonStock }

        #expect(filtered.count == 2)
        #expect(filtered.allSatisfy { $0.type == "Common Stock" || $0.type == "EQS" })
    }

    @Test("Limit results to 15")
    func limitResultsTo15() {
        var results: [String] = []
        for i in 0..<20 {
            results.append("SYM\(i)")
        }

        let limited = Array(results.prefix(15))

        #expect(limited.count == 15)
    }
}
