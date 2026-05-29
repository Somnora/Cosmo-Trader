import Foundation
import Testing
@testable import Cosmo_Trader

struct SchwabMobileParserTests {

    @Test("Clean Schwab screenshot extracts five holdings")
    func cleanSchwabScreenshotExtractsFiveHoldings() throws {
        let parser = SchwabMobileParser()

        #expect(parser.canParse(cleanFiveHoldingFixture) == 1.0)

        let portfolio = try parser.parse(cleanFiveHoldingFixture)

        #expect(portfolio.broker == "Charles Schwab")
        #expect(portfolio.holdings.map(\.symbol) == ["AAPL", "MSFT", "NVDA", "TSLA", "GOOGL"])
        #expect(portfolio.holdings.map(\.shares) == [10, 5, 2, 3, 4])
        #expect(portfolio.holdings.compactMap(\.marketValue) == [1785.20, 1894.55, 935.60, 745.50, 567.20])
        #expect(portfolio.holdings.allSatisfy { $0.confidence == 1.0 })
        #expect(portfolio.overallConfidence > 0.9)
    }

    @Test("Schwab parser supports fractional shares")
    func fractionalShareParses() throws {
        let parser = SchwabMobileParser()
        let portfolio = try parser.parse([
            "Schwab",
            "Positions",
            "Symbol Qty Last Mkt Value",
            "TSLA",
            "0.247 $248.50 $61.38"
        ])

        let holding = try #require(portfolio.holdings.first)
        #expect(holding.symbol == "TSLA")
        #expect(holding.shares == 0.247)
        #expect(holding.marketValue == 61.38)
        #expect(holding.confidence == 1.0)
    }

    @Test("Schwab parser supports dotted symbols")
    func dottedSymbolParses() throws {
        let parser = SchwabMobileParser()
        let portfolio = try parser.parse([
            "Charles Schwab",
            "Positions",
            "Symbol Qty Last Mkt Value",
            "BRK.B Berkshire Hathaway Inc.",
            "2.5 $363.45 $908.63"
        ])

        let holding = try #require(portfolio.holdings.first)
        #expect(holding.symbol == "BRK.B")
        #expect(holding.shares == 2.5)
        #expect(holding.marketValue == 908.63)
        #expect(holding.confidence == 1.0)
    }

    @Test("Unknown syntactically valid ticker is kept with lower confidence")
    func unknownTickerIsAcceptedWithLowerConfidence() throws {
        let parser = SchwabMobileParser()
        let portfolio = try parser.parse([
            "Schwab",
            "Positions",
            "Symbol Qty Last Mkt Value",
            "ZZZZ",
            "12 $10.00 $120.00"
        ])

        let holding = try #require(portfolio.holdings.first)
        #expect(holding.symbol == "ZZZZ")
        #expect(holding.shares == 12)
        #expect(holding.marketValue == 120)
        #expect(holding.confidence == 0.8)
        #expect(portfolio.overallConfidence == 0.8)
    }

    @Test("Schwab account summary lines do not become holdings")
    func accountSummaryTopHalfIsIgnoredForHoldings() throws {
        let parser = SchwabMobileParser()
        let portfolio = try parser.parse([
            "Schwab",
            "Accounts",
            "Individual Brokerage ...1234",
            "Total Account Value",
            "$42,000.00",
            "Day Change",
            "$120.00",
            "Cash & Cash Investments",
            "$500.00",
            "Positions",
            "Symbol Qty Last Mkt Value",
            "AAPL 10 $178.52 $1,785.20",
            "MSFT 5 $378.91 $1,894.55",
            "NVDA 2 $467.80 $935.60"
        ])

        #expect(portfolio.holdings.map(\.symbol) == ["AAPL", "MSFT", "NVDA"])
        #expect(portfolio.unparsedLines.contains("Total Account Value"))
        #expect(!portfolio.holdings.contains { $0.symbol == "CASH" })
        #expect(portfolio.overallConfidence > 0.75)
    }

    @Test("Non-Schwab screenshot scores below parser threshold")
    func nonSchwabScreenshotCanParseLowConfidence() {
        let parser = SchwabMobileParser()
        let confidence = parser.canParse([
            "Fidelity",
            "Positions",
            "Symbol Quantity Last Price Current Value",
            "AAPL",
            "10 $178.52 $1,785.20"
        ])

        #expect(confidence < 0.4)
    }

    @Test("Generic portfolio text without Schwab marker scores below parser threshold")
    func genericPortfolioTextWithoutSchwabMarkerScoresLowConfidence() {
        let parser = SchwabMobileParser()
        let confidence = parser.canParse([
            "Positions",
            "Symbol Qty Last Market Value",
            "AAPL",
            "10 $178.52 $1,785.20",
            "MSFT",
            "5 $378.91 $1,894.55"
        ])

        #expect(confidence < 0.4)
    }

    private var cleanFiveHoldingFixture: [String] {
        [
            "Schwab",
            "Positions",
            "Individual Brokerage ...1234",
            "Symbol Qty Last Mkt Value",
            "AAPL",
            "10 $178.52 $1,785.20",
            "MSFT",
            "5 $378.91 $1,894.55",
            "NVDA",
            "2 $467.80 $935.60",
            "TSLA",
            "3 $248.50 $745.50",
            "GOOGL",
            "4 $141.80 $567.20"
        ]
    }
}
