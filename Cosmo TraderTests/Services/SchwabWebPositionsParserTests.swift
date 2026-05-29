import Foundation
import Testing
@testable import Cosmo_Trader

struct SchwabWebPositionsParserTests {

    @Test("Clean Schwab web export parses five holdings")
    func cleanSchwabWebExportParsesFiveHoldings() throws {
        let parser = SchwabWebPositionsParser()

        #expect(parser.canParse(cleanSchwabExport) == 0.7)

        let portfolio = try parser.parse(cleanSchwabExport)

        #expect(portfolio.broker == "Schwab Web Positions")
        #expect(portfolio.holdings.map(\.symbol) == ["AAPL", "MSFT", "NVDA", "TSLA", "GOOGL"])
        #expect(portfolio.holdings.map(\.shares) == [10, 5, 2, 3, 4])
        #expect(portfolio.holdings.compactMap(\.marketValue) == [3108.50, 1894.55, 935.60, 745.50, 567.20])
        #expect(portfolio.holdings.allSatisfy { $0.confidence == 1.0 })
    }

    @Test("Cash and Money Market row is skipped")
    func cashAndMoneyMarketRowIsSkipped() throws {
        let parser = SchwabWebPositionsParser()
        let portfolio = try parser.parse("""
        Symbol,Description,Quantity,Price,Market Value,Cost Basis
        Cash & Money Market,Cash & Money Market,500.00,1.00,$500.00,$500.00
        AAPL,"Apple, Inc.",10,310.85,"$3,108.50","$1,500.00"
        """)

        #expect(portfolio.holdings.map(\.symbol) == ["AAPL"])
        #expect(portfolio.unparsedLines.contains { $0.contains("Cash & Money Market") })
    }

    @Test("Parenthesized market value parses as negative")
    func parenthesizedMarketValueParsesAsNegative() throws {
        let parser = SchwabWebPositionsParser()
        let portfolio = try parser.parse("""
        Symbol,Description,Quantity,Price,Market Value,Cost Basis
        AAPL,"Apple, Inc.",1,310.85,"(1,234.56)","$1,500.00"
        """)

        let holding = try #require(portfolio.holdings.first)
        #expect(holding.symbol == "AAPL")
        #expect(holding.marketValue == -1234.56)
    }

    @Test("Non-Schwab CSV scores below threshold")
    func nonSchwabCSVCanParseLowConfidence() {
        let parser = SchwabWebPositionsParser()
        let confidence = parser.canParse("""
        Account,Symbol,Description,Shares,Last Price,Current Value
        1234,AAPL,"Apple, Inc.",10,310.85,"$3,108.50"
        """)

        #expect(confidence < 0.4)
    }

    private var cleanSchwabExport: String {
        """
        Symbol,Description,Quantity,Price,Price Change %,Price Change $,Market Value,Day Change %,Day Change $,Cost Basis,Gain/Loss %,Gain/Loss $,% of Account
        AAPL,"Apple, Inc.",10,310.85,0.81%,2.52,"$3,108.50",0.81%,$25.20,"$1,500.00",107.23%,"$1,608.50",40.0%
        MSFT,Microsoft Corp,5,378.91,0.29%,1.10,"$1,894.55",0.29%,$5.50,"$1,500.00",26.30%,$394.55,24.0%
        NVDA,NVIDIA Corp,2,467.80,0.75%,3.50,$935.60,0.75%,$7.00,$600.00,55.93%,$335.60,12.0%
        TSLA,Tesla Inc,3,248.50,0.50%,1.25,$745.50,0.50%,$3.75,$600.00,24.25%,$145.50,10.0%
        GOOGL,Alphabet Inc,4,141.80,0.56%,0.80,$567.20,0.56%,$3.20,$480.00,18.17%,$87.20,7.0%
        Account Total,,,,,"$7,251.35",,,,,,,
        """
    }
}
