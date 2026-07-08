import Foundation
import Testing
@testable import Cosmo_Trader

// Fixtures are synthetic samples shaped like real broker exports
// (header names and row layout match the brokers' published formats).
struct GenericPositionsCSVParserTests {

    @Test("Fidelity-style positions export parses with per-share cost preferred")
    func fidelityStyleExportParses() throws {
        let parser = GenericPositionsCSVParser()

        #expect(parser.canParse(fidelityStyleExport) == 0.6)

        let portfolio = try parser.parse(fidelityStyleExport)

        #expect(portfolio.broker == "Positions CSV")
        #expect(portfolio.holdings.map(\.symbol) == ["AAPL", "MSFT", "NVDA"])
        #expect(portfolio.holdings.map(\.shares) == [10, 5, 2])
        #expect(portfolio.holdings.compactMap(\.marketValue) == [3108.50, 1894.55, 935.60])
        // Average Cost Basis column wins over Cost Basis Total.
        #expect(portfolio.holdings.compactMap(\.costBasisPerShare) == [150, 300, 300])
        #expect(portfolio.unparsedLines.contains { $0.contains("SPAXX") })
        #expect(portfolio.unparsedLines.contains { $0.contains("Pending Activity") })
    }

    @Test("ETrade-style export with preamble parses using Price Paid and Value columns")
    func etradeStyleExportParses() throws {
        let parser = GenericPositionsCSVParser()

        #expect(parser.canParse(etradeStyleExport) == 0.6)

        let portfolio = try parser.parse(etradeStyleExport)

        #expect(portfolio.holdings.map(\.symbol) == ["TSLA", "GOOGL"])
        #expect(portfolio.holdings.map(\.shares) == [3, 4])
        #expect(portfolio.holdings.compactMap(\.marketValue) == [745.50, 567.20])
        #expect(portfolio.holdings.compactMap(\.costBasisPerShare) == [200, 120])
    }

    @Test("Minimal Symbol and Quantity CSV parses at base confidence")
    func minimalSymbolQuantityCSVParses() throws {
        let parser = GenericPositionsCSVParser()
        let csv = """
        Symbol,Shares
        AAPL,10
        MSFT,5
        """

        #expect(parser.canParse(csv) == 0.45)

        let portfolio = try parser.parse(csv)

        #expect(portfolio.holdings.map(\.symbol) == ["AAPL", "MSFT"])
        #expect(portfolio.holdings.map(\.shares) == [10, 5])
        #expect(portfolio.holdings.allSatisfy { $0.marketValue == nil })
        #expect(portfolio.holdings.allSatisfy { $0.costBasisPerShare == nil })
    }

    @Test("Total cost basis column is divided by shares")
    func totalCostBasisDividedByShares() throws {
        let parser = GenericPositionsCSVParser()
        let portfolio = try parser.parse("""
        Symbol,Quantity,Market Value,Cost Basis
        AAPL,10,"$3,108.50","$1,500.00"
        """)

        let holding = try #require(portfolio.holdings.first)
        #expect(holding.costBasisPerShare == 150)
    }

    @Test("Transactions ledgers are refused")
    func transactionsLedgersAreRefused() {
        let parser = GenericPositionsCSVParser()

        let fidelityTransactions = """
        Run Date,Action,Symbol,Description,Type,Quantity,Price ($),Commission ($),Fees ($),Amount ($)
        07/01/2026,YOU BOUGHT,AAPL,APPLE INC,Cash,10,205.00,0,0,-2050.00
        """
        #expect(parser.canParse(fidelityTransactions) == 0)

        let schwabTransactions = """
        Date,Action,Symbol,Description,Quantity,Price,Fees & Comm,Amount
        07/01/2026,Buy,AAPL,APPLE INC,10,$205.00,$0.00,-$2050.00
        """
        #expect(parser.canParse(schwabTransactions) == 0)
    }

    @Test("thinkorswim position statement is not claimed")
    func thinkOrSwimStatementNotClaimed() {
        let parser = GenericPositionsCSVParser()
        let confidence = parser.canParse("""
        Position Statement for account ...1234
        (Stocks)
        Instrument,Qty,Trade Price,Mark,Net Liq,P/L %,BP Effect
        AAPL,10,150.00,310.85,"$3,108.50",1.00%,"$3,108.50"
        """)

        #expect(confidence == 0)
    }

    @Test("Cash, sweep, and total rows are skipped")
    func cashSweepAndTotalRowsAreSkipped() throws {
        let parser = GenericPositionsCSVParser()
        let portfolio = try parser.parse("""
        Symbol,Quantity,Current Value
        Cash & Money Market,500.00,$500.00
        AAPL,10,"$3,108.50"
        Account Total,,"$3,608.50"
        """)

        #expect(portfolio.holdings.map(\.symbol) == ["AAPL"])
        #expect(portfolio.unparsedLines.contains { $0.contains("Cash & Money Market") })
        #expect(portfolio.unparsedLines.contains { $0.contains("Account Total") })
    }

    // MARK: - Routing through PortfolioImportService

    @Test("Schwab web export still routes to the Schwab parser")
    func schwabExportRoutesToSchwabParser() async throws {
        let portfolio = try await PortfolioImportService.parseCSV("""
        Symbol,Description,Quantity,Price,Market Value,Cost Basis
        AAPL,"Apple, Inc.",10,310.85,"$3,108.50","$1,500.00"
        """)

        #expect(portfolio.broker == "Schwab Web Positions")
    }

    @Test("thinkorswim export still routes to the thinkorswim parser")
    func thinkOrSwimExportRoutesToThinkOrSwimParser() async throws {
        let portfolio = try await PortfolioImportService.parseCSV("""
        Position Statement for account ...1234
        (Stocks)
        Instrument,Qty,Trade Price,Mark,Net Liq,P/L %,BP Effect
        AAPL,10,150.00,310.85,"$3,108.50",1.00%,"$3,108.50"
        """)

        #expect(portfolio.broker == "thinkorswim Position Statement")
    }

    @Test("Fidelity-style export routes to the generic parser")
    func fidelityExportRoutesToGenericParser() async throws {
        let portfolio = try await PortfolioImportService.parseCSV(fidelityStyleExport)

        #expect(portfolio.broker == "Positions CSV")
    }

    @Test("Transactions ledger fails as unrecognized instead of importing garbage")
    func transactionsLedgerFailsAsUnrecognized() async {
        await #expect(throws: PortfolioImportError.self) {
            try await PortfolioImportService.parseCSV("""
            Date,Action,Symbol,Description,Quantity,Price,Fees & Comm,Amount
            07/01/2026,Buy,AAPL,APPLE INC,10,$205.00,$0.00,-$2050.00
            """)
        }
    }

    // MARK: - Fixtures

    private var fidelityStyleExport: String {
        """
        Account Number,Account Name,Symbol,Description,Quantity,Last Price,Last Price Change,Current Value,Today's Gain/Loss Dollar,Today's Gain/Loss Percent,Total Gain/Loss Dollar,Total Gain/Loss Percent,Percent Of Account,Cost Basis Total,Average Cost Basis,Type
        X12345678,Individual,AAPL,APPLE INC,10,310.85,+2.52,"$3,108.50",+$25.20,+0.81%,"+$1,608.50",+107.23%,40.00%,"$1,500.00",$150.00,Cash
        X12345678,Individual,MSFT,MICROSOFT CORP,5,378.91,+1.10,"$1,894.55",+$5.50,+0.29%,+$394.55,+26.30%,24.00%,"$1,500.00",$300.00,Cash
        X12345678,Individual,NVDA,NVIDIA CORP,2,467.80,+3.50,$935.60,+$7.00,+0.75%,+$335.60,+55.93%,12.00%,$600.00,$300.00,Cash
        X12345678,Individual,SPAXX**,FIDELITY GOVERNMENT MONEY MARKET,500.00,1.00,0.00,$500.00,$0.00,0.00%,$0.00,0.00%,6.00%,$500.00,$1.00,Cash
        X12345678,Individual,Pending Activity,,,,,$25.00,,,,,,,,
        "The data and information in this spreadsheet is provided for informational purposes only."
        """
    }

    private var etradeStyleExport: String {
        """
        Account Summary
        Individual Brokerage,-1234
        Positions as of 07/07/2026

        Symbol,Last Price $,Change $,Change %,Quantity,Price Paid $,Day's Gain $,Total Gain $,Total Gain %,Value $
        TSLA,248.50,1.25,0.50,3,200.00,3.75,145.50,24.25,745.50
        GOOGL,141.80,0.80,0.56,4,120.00,3.20,87.20,18.17,567.20
        """
    }
}
