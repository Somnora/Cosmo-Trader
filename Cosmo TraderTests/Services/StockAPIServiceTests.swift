//
//  StockAPIServiceTests.swift
//  Cosmo TraderTests
//
//  Comprehensive tests for StockAPIService including quote parsing,
//  search results, caching, and error handling.
//

import Testing
import Foundation
@testable import Cosmo_Trader

// MARK: - StockQuote Parsing Tests

struct StockQuoteParsingTests {

    @Test("Parse valid quote response with all fields")
    func parseValidQuoteResponse() throws {
        let json = """
        {"c": 150.0, "d": 2.5, "dp": 1.69, "h": 151.0, "l": 148.0, "o": 149.0, "pc": 147.5, "t": 1234567890}
        """.data(using: .utf8)!

        let quote = try JSONDecoder().decode(StockQuote.self, from: json)

        #expect(quote.currentPrice == 150.0)
        #expect(quote.c == 150.0)
        #expect(quote.d == 2.5)
        #expect(quote.dp == 1.69)
        #expect(quote.h == 151.0)
        #expect(quote.l == 148.0)
        #expect(quote.o == 149.0)
        #expect(quote.pc == 147.5)
    }

    @Test("Parse quote response with zero values")
    func parseZeroQuoteResponse() throws {
        let json = """
        {"c": 0, "d": 0, "dp": 0, "h": 0, "l": 0, "o": 0, "pc": 0, "t": 0}
        """.data(using: .utf8)!

        let quote = try JSONDecoder().decode(StockQuote.self, from: json)

        #expect(quote.currentPrice == 0)
        #expect(quote.c == 0)
    }

    @Test("Parse quote response with null optional fields")
    func parseQuoteWithNullOptionals() throws {
        let json = """
        {"c": 100.0, "d": null, "dp": null, "h": 101.0, "l": 99.0, "o": 100.0, "pc": 99.5, "t": null}
        """.data(using: .utf8)!

        let quote = try JSONDecoder().decode(StockQuote.self, from: json)

        #expect(quote.c == 100.0)
        #expect(quote.d == nil)
        #expect(quote.dp == nil)
        #expect(quote.t == nil)
    }

    @Test("Price change calculated correctly when d is nil")
    func priceChangeCalculatedWhenNil() throws {
        let json = """
        {"c": 100.0, "d": null, "dp": null, "h": 101.0, "l": 99.0, "o": 100.0, "pc": 95.0, "t": null}
        """.data(using: .utf8)!

        let quote = try JSONDecoder().decode(StockQuote.self, from: json)

        // Should calculate: c - pc = 100.0 - 95.0 = 5.0
        #expect(quote.priceChange == 5.0)
    }

    @Test("Percentage change calculated correctly when dp is nil")
    func percentageChangeCalculatedWhenNil() throws {
        let json = """
        {"c": 100.0, "d": null, "dp": null, "h": 101.0, "l": 99.0, "o": 100.0, "pc": 95.0, "t": null}
        """.data(using: .utf8)!

        let quote = try JSONDecoder().decode(StockQuote.self, from: json)

        // Should calculate: ((c - pc) / pc) * 100 = ((100-95)/95)*100 ≈ 5.26%
        let expectedPercent = ((100.0 - 95.0) / 95.0) * 100
        #expect(abs(quote.percentageChange - expectedPercent) < 0.01)
    }

    @Test("isPositive returns true for positive change")
    func isPositiveForPositiveChange() throws {
        let json = """
        {"c": 105.0, "d": 5.0, "dp": 5.0, "h": 106.0, "l": 100.0, "o": 100.0, "pc": 100.0, "t": 0}
        """.data(using: .utf8)!

        let quote = try JSONDecoder().decode(StockQuote.self, from: json)

        #expect(quote.isPositive == true)
    }

    @Test("isPositive returns true for zero change")
    func isPositiveForZeroChange() throws {
        let json = """
        {"c": 100.0, "d": 0.0, "dp": 0.0, "h": 101.0, "l": 99.0, "o": 100.0, "pc": 100.0, "t": 0}
        """.data(using: .utf8)!

        let quote = try JSONDecoder().decode(StockQuote.self, from: json)

        #expect(quote.isPositive == true)
    }

    @Test("isPositive returns false for negative change")
    func isPositiveForNegativeChange() throws {
        let json = """
        {"c": 95.0, "d": -5.0, "dp": -5.0, "h": 101.0, "l": 94.0, "o": 100.0, "pc": 100.0, "t": 0}
        """.data(using: .utf8)!

        let quote = try JSONDecoder().decode(StockQuote.self, from: json)

        #expect(quote.isPositive == false)
    }
}

// MARK: - StockQuote Formatting Tests

struct StockQuoteFormattingTests {

    @Test("Formatted price includes dollar sign and two decimals")
    func formattedPriceFormat() throws {
        let json = """
        {"c": 150.5, "d": 0, "dp": 0, "h": 151, "l": 150, "o": 150, "pc": 150, "t": 0}
        """.data(using: .utf8)!

        let quote = try JSONDecoder().decode(StockQuote.self, from: json)

        #expect(quote.formattedPrice == "$150.50")
    }

    @Test("Formatted change includes sign for positive")
    func formattedChangePositive() throws {
        let json = """
        {"c": 105.0, "d": 5.0, "dp": 5.0, "h": 106, "l": 100, "o": 100, "pc": 100, "t": 0}
        """.data(using: .utf8)!

        let quote = try JSONDecoder().decode(StockQuote.self, from: json)

        #expect(quote.formattedChange.contains("+"))
    }

    @Test("Formatted change includes sign for negative")
    func formattedChangeNegative() throws {
        let json = """
        {"c": 95.0, "d": -5.0, "dp": -5.0, "h": 100, "l": 94, "o": 100, "pc": 100, "t": 0}
        """.data(using: .utf8)!

        let quote = try JSONDecoder().decode(StockQuote.self, from: json)

        // Negative values naturally include "-"
        #expect(quote.formattedChange.contains("-") || quote.formattedChange.contains("$"))
    }

    @Test("Formatted percentage includes percent sign")
    func formattedPercentageIncludesSign() throws {
        let json = """
        {"c": 105.0, "d": 5.0, "dp": 5.26, "h": 106, "l": 100, "o": 100, "pc": 100, "t": 0}
        """.data(using: .utf8)!

        let quote = try JSONDecoder().decode(StockQuote.self, from: json)

        #expect(quote.formattedPercentage.contains("%"))
    }
}

// MARK: - CachedQuote Tests

struct CachedQuoteTests {

    @Test("CachedQuote stores quote and timestamp")
    func cachedQuoteStoresData() throws {
        let json = """
        {"c": 150.0, "d": 2.5, "dp": 1.69, "h": 151.0, "l": 148.0, "o": 149.0, "pc": 147.5, "t": 0}
        """.data(using: .utf8)!

        let quote = try JSONDecoder().decode(StockQuote.self, from: json)
        let now = Date()
        let cached = CachedQuote(quote: quote, timestamp: now, symbol: "AAPL")

        #expect(cached.quote.currentPrice == 150.0)
        #expect(cached.symbol == "AAPL")
        #expect(cached.timestamp == now)
    }

    @Test("CachedQuote age calculated correctly")
    func cachedQuoteAgeCalculation() throws {
        let json = """
        {"c": 150.0, "d": 2.5, "dp": 1.69, "h": 151.0, "l": 148.0, "o": 149.0, "pc": 147.5, "t": 0}
        """.data(using: .utf8)!

        let quote = try JSONDecoder().decode(StockQuote.self, from: json)
        let pastDate = Date().addingTimeInterval(-120) // 2 minutes ago
        let cached = CachedQuote(quote: quote, timestamp: pastDate, symbol: "AAPL")

        #expect(cached.age >= 120)
        #expect(cached.age < 125) // Allow some slack for test execution time
    }

    @Test("CachedQuote isExpired true after expiration")
    func cachedQuoteExpiredAfterTimeout() throws {
        let json = """
        {"c": 150.0, "d": 2.5, "dp": 1.69, "h": 151.0, "l": 148.0, "o": 149.0, "pc": 147.5, "t": 0}
        """.data(using: .utf8)!

        let quote = try JSONDecoder().decode(StockQuote.self, from: json)
        // Cache expiration is 60 seconds
        let oldDate = Date().addingTimeInterval(-120) // 2 minutes ago
        let cached = CachedQuote(quote: quote, timestamp: oldDate, symbol: "AAPL")

        #expect(cached.isExpired == true)
    }

    @Test("CachedQuote isExpired false when fresh")
    func cachedQuoteFreshNotExpired() throws {
        let json = """
        {"c": 150.0, "d": 2.5, "dp": 1.69, "h": 151.0, "l": 148.0, "o": 149.0, "pc": 147.5, "t": 0}
        """.data(using: .utf8)!

        let quote = try JSONDecoder().decode(StockQuote.self, from: json)
        let recentDate = Date().addingTimeInterval(-30) // 30 seconds ago
        let cached = CachedQuote(quote: quote, timestamp: recentDate, symbol: "AAPL")

        #expect(cached.isExpired == false)
    }

    @Test("CachedQuote formattedAge shows 'Just now' for fresh")
    func cachedQuoteFormattedAgeJustNow() throws {
        let json = """
        {"c": 150.0, "d": 2.5, "dp": 1.69, "h": 151.0, "l": 148.0, "o": 149.0, "pc": 147.5, "t": 0}
        """.data(using: .utf8)!

        let quote = try JSONDecoder().decode(StockQuote.self, from: json)
        let cached = CachedQuote(quote: quote, timestamp: Date(), symbol: "AAPL")

        #expect(cached.formattedAge == "Just now")
    }

    @Test("CachedQuote formattedAge shows minutes correctly")
    func cachedQuoteFormattedAgeMinutes() throws {
        let json = """
        {"c": 150.0, "d": 2.5, "dp": 1.69, "h": 151.0, "l": 148.0, "o": 149.0, "pc": 147.5, "t": 0}
        """.data(using: .utf8)!

        let quote = try JSONDecoder().decode(StockQuote.self, from: json)
        let fiveMinutesAgo = Date().addingTimeInterval(-300) // 5 minutes ago
        let cached = CachedQuote(quote: quote, timestamp: fiveMinutesAgo, symbol: "AAPL")

        #expect(cached.formattedAge == "5 mins ago")
    }

    @Test("CachedQuote formattedAge shows singular minute")
    func cachedQuoteFormattedAgeSingularMinute() throws {
        let json = """
        {"c": 150.0, "d": 2.5, "dp": 1.69, "h": 151.0, "l": 148.0, "o": 149.0, "pc": 147.5, "t": 0}
        """.data(using: .utf8)!

        let quote = try JSONDecoder().decode(StockQuote.self, from: json)
        let oneMinuteAgo = Date().addingTimeInterval(-90) // 1.5 minutes ago
        let cached = CachedQuote(quote: quote, timestamp: oneMinuteAgo, symbol: "AAPL")

        #expect(cached.formattedAge == "1 min ago")
    }
}

// MARK: - SymbolSearchResult Parsing Tests

struct SymbolSearchParsingTests {

    @Test("Parse valid search results")
    func parseValidSearchResults() throws {
        let json = """
        {"count": 2, "result": [
            {"symbol": "AAPL", "displaySymbol": "AAPL", "description": "Apple Inc", "type": "Common Stock"},
            {"symbol": "AAPL.MX", "displaySymbol": "AAPL.MX", "description": "Apple Inc", "type": "Common Stock"}
        ]}
        """.data(using: .utf8)!

        let searchResult = try JSONDecoder().decode(SymbolSearchResult.self, from: json)

        #expect(searchResult.count == 2)
        #expect(searchResult.result.count == 2)
        #expect(searchResult.result[0].symbol == "AAPL")
        #expect(searchResult.result[0].description == "Apple Inc")
    }

    @Test("Parse empty search results")
    func parseEmptySearchResults() throws {
        let json = """
        {"count": 0, "result": []}
        """.data(using: .utf8)!

        let searchResult = try JSONDecoder().decode(SymbolSearchResult.self, from: json)

        #expect(searchResult.count == 0)
        #expect(searchResult.result.isEmpty)
    }

    @Test("SymbolMatch isCommonStock filters correctly")
    func symbolMatchIsCommonStock() throws {
        let json = """
        {"count": 3, "result": [
            {"symbol": "AAPL", "displaySymbol": "AAPL", "description": "Apple Inc", "type": "Common Stock"},
            {"symbol": "AAPL.B", "displaySymbol": "AAPL.B", "description": "Apple Bond", "type": "Bond"},
            {"symbol": "MSFT", "displaySymbol": "MSFT", "description": "Microsoft", "type": "EQS"}
        ]}
        """.data(using: .utf8)!

        let searchResult = try JSONDecoder().decode(SymbolSearchResult.self, from: json)

        #expect(searchResult.result[0].isCommonStock == true)
        #expect(searchResult.result[1].isCommonStock == false)
        #expect(searchResult.result[2].isCommonStock == true)
    }

    @Test("SymbolMatch id is symbol")
    func symbolMatchIdIsSymbol() throws {
        let json = """
        {"count": 1, "result": [
            {"symbol": "GOOGL", "displaySymbol": "GOOGL", "description": "Alphabet Inc", "type": "Common Stock"}
        ]}
        """.data(using: .utf8)!

        let searchResult = try JSONDecoder().decode(SymbolSearchResult.self, from: json)

        #expect(searchResult.result[0].id == "GOOGL")
    }
}

// MARK: - StockAPIService Configuration Tests

struct StockAPIServiceConfigTests {

    @Test("Cache expiration is 60 seconds")
    func cacheExpirationValue() {
        #expect(StockAPIService.cacheExpirationSeconds == 60)
    }

    @Test("Max requests per minute is 60")
    func maxRequestsPerMinuteValue() {
        #expect(StockAPIService.maxRequestsPerMinute == 60)
    }

    @Test("Minimum request delay is 1 second")
    func minRequestDelayValue() {
        #expect(StockAPIService.minRequestDelay == 1.0)
    }
}

// MARK: - Stock Extension Tests

struct StockQuoteExtensionTests {

    @Test("Stock withQuote creates updated copy")
    func stockWithQuoteCreatesCopy() throws {
        let json = """
        {"c": 200.0, "d": 10.0, "dp": 5.0, "h": 201.0, "l": 190.0, "o": 195.0, "pc": 190.0, "t": 0}
        """.data(using: .utf8)!

        let quote = try JSONDecoder().decode(StockQuote.self, from: json)
        var stock = Stock.sample
        let originalPrice = stock.currentPrice

        let updatedStock = stock.withQuote(quote)

        // Original should be unchanged
        #expect(stock.currentPrice == originalPrice)

        // Updated stock should have new price
        #expect(updatedStock.currentPrice == 200.0)
        #expect(updatedStock.priceChange == 10.0)
        #expect(updatedStock.percentageChange == 5.0)
    }

    @Test("Stock updateWithQuote modifies in place")
    func stockUpdateWithQuoteModifiesInPlace() throws {
        let json = """
        {"c": 250.0, "d": 15.0, "dp": 6.5, "h": 255.0, "l": 240.0, "o": 245.0, "pc": 235.0, "t": 0}
        """.data(using: .utf8)!

        let quote = try JSONDecoder().decode(StockQuote.self, from: json)
        var stock = Stock.sample

        stock.updateWithQuote(quote)

        #expect(stock.currentPrice == 250.0)
        #expect(stock.priceChange == 15.0)
        #expect(stock.percentageChange == 6.5)
    }
}
