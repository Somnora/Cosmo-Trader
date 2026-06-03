import Foundation
import Testing
@testable import Cosmo_Trader

struct ThinkOrSwimPositionStatementParserTests {

    @Test("Clean Position Statement parses two groups and six holdings")
    func cleanPositionStatementParsesTwoGroupsAndSixHoldings() throws {
        let parser = ThinkOrSwimPositionStatementParser()

        #expect(parser.canParse(cleanPositionStatement) >= 0.8)

        let portfolio = try parser.parse(cleanPositionStatement)

        #expect(portfolio.broker == "thinkorswim Position Statement")
        #expect(portfolio.holdings.map(\.symbol) == ["AAPL", "MSFT", "NVDA", "TSLA", "GOOGL", "AMZN"])
        #expect(portfolio.holdings.map(\.shares) == [10, 5, 2, 3, 4, 1])
        #expect(portfolio.holdings.compactMap(\.marketValue) == [3108.50, 1894.55, 935.60, 745.50, 567.20, 180.00])
        #expect(portfolio.holdings.compactMap(\.costBasisPerShare) == [150, 300, 300, 200, 120, 170])
        #expect(portfolio.holdings.allSatisfy { $0.confidence == 1.0 })
        #expect(portfolio.holdings.first?.rawSource.hasPrefix("group: (Stocks) | ") == true)
        #expect(portfolio.holdings.last?.rawSource.hasPrefix("group: (Tech) | ") == true)
    }

    @Test("Cash and Sweep Vehicle rows are skipped")
    func cashAndSweepVehicleRowsAreSkipped() throws {
        let parser = ThinkOrSwimPositionStatementParser()
        let portfolio = try parser.parse("""
        Position Statement for account ...1234
        (Stocks)
        Instrument,Qty,Trade Price,Mark,Net Liq,P/L %,BP Effect
        Cash & Sweep Vehicle,100,1.00,1.00,$100.00,0.00%,$100.00
        AAPL,10,150.00,310.85,"$3,108.50",1.00%,"$3,108.50"
        OVERALL TOTALS,,,,,$3,208.50
        """)

        #expect(portfolio.holdings.map(\.symbol) == ["AAPL"])
        #expect(portfolio.unparsedLines.contains { $0.contains("Cash & Sweep Vehicle") })
    }

    @Test("Negative quantity short position parses without crashing")
    func negativeQuantityShortPositionParses() throws {
        let parser = ThinkOrSwimPositionStatementParser()
        let portfolio = try parser.parse("""
        Position Statement for account ...1234
        (Stocks)
        Instrument,Qty,Trade Price,Mark,Net Liq,P/L %,BP Effect
        TSLA,-2,248.50,250.00,"(500.00)",-1.00%,"(500.00)"
        """)

        let holding = try #require(portfolio.holdings.first)
        #expect(holding.symbol == "TSLA")
        #expect(holding.shares == -2)
        #expect(holding.marketValue == -500)
    }

    @Test("Dotted BRK.B instrument parses")
    func dottedBRKBInstrumentParses() throws {
        let parser = ThinkOrSwimPositionStatementParser()
        let portfolio = try parser.parse("""
        Position Statement for account ...1234
        (Stocks)
        Instrument,Qty,Trade Price,Mark,Net Liq,P/L %,BP Effect
        BRK.B,2,350.00,363.45,$726.90,2.00%,$726.90
        """)

        let holding = try #require(portfolio.holdings.first)
        #expect(holding.symbol == "BRK.B")
        #expect(holding.shares == 2)
        #expect(holding.marketValue == 726.90)
    }

    @Test("Subtotals and overall totals do not become holdings")
    func subtotalsAndOverallTotalsAreSkipped() throws {
        let parser = ThinkOrSwimPositionStatementParser()
        let portfolio = try parser.parse("""
        Position Statement for account ...1234
        (Stocks)
        Instrument,Qty,Trade Price,Mark,Net Liq,P/L %,BP Effect
        Subtotals,,,,,$1,000.00
        AAPL,1,150.00,310.85,$310.85,1.00%,$310.85
        OVERALL TOTALS,,,,,$1,310.85
        """)

        #expect(portfolio.holdings.map(\.symbol) == ["AAPL"])
        #expect(!portfolio.holdings.contains { $0.symbol == "SUBTOTALS" })
        #expect(!portfolio.holdings.contains { $0.symbol == "OVERALL" })
    }

    @Test("Customized column set parses by header names")
    func customizedColumnSetParsesByHeaderNames() throws {
        let parser = ThinkOrSwimPositionStatementParser()
        let portfolio = try parser.parse("""
        Position Statement for account ...1234
        (Dividend Income)
        Instrument,Net Liq,Qty,Trade Price,P/L Day,P/L %,BP Effect
        MSFT,"$1,894.55",5,300.00,$12.00,4.00%,"$1,894.55"
        AAPL,"$3,108.50",10,150.00,$20.00,8.00%,"$3,108.50"
        """)

        #expect(portfolio.holdings.map(\.symbol) == ["MSFT", "AAPL"])
        #expect(portfolio.holdings.map(\.shares) == [5, 10])
        #expect(portfolio.holdings.compactMap(\.marketValue) == [1894.55, 3108.50])
    }

    private var cleanPositionStatement: String {
        """
        Position Statement for account ...1234
        (Stocks)
        Instrument,Qty,Trade Price,Mark,Mrk Chng,Net Liq,P/L %,P/L Open,P/L Day,BP Effect
        AAPL,10,150.00,310.85,2.52,"$3,108.50",10.00%,"$1,608.50",$25.20,"$3,108.50"
        MSFT,5,300.00,378.91,1.10,"$1,894.55",12.00%,$394.55,$5.50,"$1,894.55"
        NVDA,2,300.00,467.80,3.50,$935.60,20.00%,$335.60,$7.00,$935.60
        Subtotals,,,,,$5,938.65,,,,,
        (Tech)
        Instrument,Qty,Trade Price,Mark,Mrk Chng,Net Liq,P/L %,P/L Open,P/L Day,BP Effect
        TSLA,3,200.00,248.50,1.25,$745.50,24.00%,$145.50,$3.75,$745.50
        GOOGL,4,120.00,141.80,0.80,$567.20,18.00%,$87.20,$3.20,$567.20
        AMZN,1,170.00,180.00,0.20,$180.00,5.00%,$10.00,$0.20,$180.00
        OVERALL TOTALS,,,,,$7,431.35,,,,,
        """
    }
}
