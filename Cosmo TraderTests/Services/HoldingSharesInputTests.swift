import Foundation
import Testing
@testable import Cosmo_Trader

struct HoldingSharesInputTests {

    // MARK: - Share parsing

    @Test("Valid share counts parse", arguments: [
        ("1", 1.0),
        ("12", 12.0),
        (" 3 ", 3.0),
        ("2.5", 2.5),
        ("0.25", 0.25),
        ("2,5", 2.5),           // comma-locale decimal separator
        ("1,234.5", 1234.5),    // comma as grouping separator
        ("1000000000", 1_000_000_000.0)
    ])
    func validSharesParse(text: String, expected: Double) {
        #expect(HoldingSharesInput.parseShares(text) == expected)
    }

    @Test("Invalid share counts are rejected", arguments: [
        "", " ", "0", "-1", "-0.5", "abc", "1.2.3", "1e400", "inf", "nan",
        "1000000001"
    ])
    func invalidSharesRejected(text: String) {
        #expect(HoldingSharesInput.parseShares(text) == nil)
    }

    // MARK: - Cost basis parsing

    @Test("Empty cost basis means unknown, never invalid")
    func emptyCostBasisIsUnknown() {
        #expect(HoldingSharesInput.costBasis(from: "") == .unknown)
        #expect(HoldingSharesInput.costBasis(from: "   ") == .unknown)
    }

    @Test("Valid cost basis parses", arguments: [
        ("150", 150.0),
        ("150.50", 150.5),
        ("$150.50", 150.5),
        ("0", 0.0),             // gifted/award shares have a real zero basis
        ("1,234.56", 1234.56),
        ("2,5", 2.5)
    ])
    func validCostBasisParses(text: String, expected: Double) {
        #expect(HoldingSharesInput.costBasis(from: text) == .value(expected))
    }

    @Test("Invalid cost basis is flagged, not silently dropped", arguments: [
        "-1", "abc", "1.2.3", "10000000.01"
    ])
    func invalidCostBasisFlagged(text: String) {
        #expect(HoldingSharesInput.costBasis(from: text) == .invalid)
    }

    // MARK: - Display formatting

    @Test("Share display keeps whole counts whole and trims fractions", arguments: [
        (12.0, "12"),
        (2.5, "2.5"),
        (0.25, "0.25"),
        (1.2345, "1.2345"),
        (3.1000, "3.1")
    ])
    func displaySharesFormats(value: Double, expected: String) {
        #expect(HoldingSharesInput.displayShares(value) == expected)
    }

    @Test("Display and parse round-trip for prefilled fields")
    func displayParsesBack() {
        for value in [1.0, 2.5, 0.25, 12.0, 1234.5] {
            let text = HoldingSharesInput.displayShares(value)
            #expect(HoldingSharesInput.parseShares(text) == value)
        }
    }
}
