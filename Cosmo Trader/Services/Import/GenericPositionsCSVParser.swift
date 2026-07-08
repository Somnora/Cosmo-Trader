import Foundation

/// Fallback parser for broker positions CSVs that no specialized parser
/// claims: Fidelity, E*TRADE, Vanguard, Merrill, and any export with a
/// symbol column and a share-count column. Registered after the
/// specialized parsers, and its confidence is capped below their
/// full-signal scores so they win their own formats.
struct GenericPositionsCSVParser: BrokerCSVParser {
    let formatName = "Positions CSV"

    /// Confidence stays under SchwabWebPositionsParser's full-header 0.7
    /// so a real Schwab file routes to the Schwab parser.
    private static let baseConfidence = 0.45
    private static let marketValueBonus = 0.10
    private static let costBasisBonus = 0.05

    private static let symbolHeaders = ["Symbol", "Ticker", "Ticker Symbol", "Stock"]
    private static let quantityHeaders = ["Quantity", "Qty", "Shares", "Share Quantity", "Units"]
    private static let marketValueHeaders = [
        "Market Value", "Current Value", "Mkt Value", "Market Value $", "Value $", "Total Value", "Value"
    ]
    // Per-share cost columns are preferred; total-cost columns are divided
    // by shares. "Cost Basis" alone is a total in every broker export seen.
    private static let perShareCostHeaders = [
        "Average Cost Basis", "Average Cost", "Avg Cost", "Average Price", "Avg Price",
        "Price Paid", "Price Paid $", "Cost Per Share", "Cost/Share", "Unit Cost"
    ]
    private static let totalCostHeaders = [
        "Cost Basis Total", "Cost Basis", "Total Cost Basis", "Total Cost"
    ]

    // Headers that mark a transactions/activity ledger rather than a
    // positions export. Importing a ledger as positions would fabricate
    // holdings, so the generic parser refuses these files outright.
    private static let transactionHeaders = [
        "date", "trade date", "run date", "activity date", "process date", "settle date",
        "action", "trans code", "transaction type", "amount", "amount ($)"
    ]

    private struct ColumnIndexes {
        let symbol: Int
        let quantity: Int
        let marketValue: Int?
        let perShareCost: Int?
        let totalCost: Int?
    }

    func canParse(_ csvText: String) -> Double {
        let rows = BrokerCSVParsing.rows(from: csvText)
        guard let header = rows.first(where: isHeaderRow(_:)) else { return 0 }

        let normalized = Set(header.map(BrokerCSVParsing.normalizedHeader))
        guard !Self.transactionHeaders.contains(where: { normalized.contains($0) }) else {
            return 0
        }

        let map = BrokerCSVParsing.columnMap(for: header)
        var score = Self.baseConfidence
        if BrokerCSVParsing.firstColumnIndex(in: map, matching: Self.marketValueHeaders) != nil {
            score += Self.marketValueBonus
        }
        if BrokerCSVParsing.firstColumnIndex(in: map, matching: Self.perShareCostHeaders + Self.totalCostHeaders) != nil {
            score += Self.costBasisBonus
        }
        return BrokerCSVParsing.roundedConfidence(score)
    }

    func parse(_ csvText: String) throws -> ParsedPortfolio {
        let rawLines = BrokerCSVParsing.lines(from: csvText)
        let rows = rawLines.map(BrokerCSVParsing.splitRow)

        guard let headerIndex = rows.firstIndex(where: isHeaderRow(_:)),
              let columns = columnIndexes(from: rows[headerIndex]) else {
            throw PortfolioImportError.invalidFormat
        }

        var holdings: [ParsedHolding] = []
        var unparsedLines: [String] = []

        for index in rows.indices where index > headerIndex {
            let rawLine = rawLines[index].trimmingCharacters(in: .whitespacesAndNewlines)
            let row = rows[index]
            guard !row.allSatisfy({ $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) else { continue }
            guard !isHeaderRow(row) else { continue }

            let rawSymbol = BrokerCSVParsing.value(in: row, at: columns.symbol)
            if shouldSkip(symbol: rawSymbol, row: row) {
                if !rawLine.isEmpty { unparsedLines.append(rawLine) }
                continue
            }

            let symbol = BrokerCSVParsing.cleanSymbol(rawSymbol)
            guard BrokerCSVParsing.isValidSymbol(symbol) else {
                if !rawLine.isEmpty { unparsedLines.append(rawLine) }
                continue
            }

            let shares = BrokerCSVParsing.parseDouble(BrokerCSVParsing.value(in: row, at: columns.quantity))
            guard let shares, shares != 0 else {
                if !rawLine.isEmpty { unparsedLines.append(rawLine) }
                continue
            }

            let marketValue = BrokerCSVParsing.parseDouble(BrokerCSVParsing.value(in: row, at: columns.marketValue))
            let costBasisPerShare = Self.costBasisPerShare(
                perShareCost: BrokerCSVParsing.parseDouble(BrokerCSVParsing.value(in: row, at: columns.perShareCost)),
                totalCost: BrokerCSVParsing.parseDouble(BrokerCSVParsing.value(in: row, at: columns.totalCost)),
                shares: shares
            )

            holdings.append(ParsedHolding(
                symbol: symbol,
                shares: shares,
                marketValue: marketValue,
                costBasisPerShare: costBasisPerShare,
                confidence: BrokerCSVParsing.rowConfidence(
                    symbol: symbol,
                    shares: shares,
                    marketValue: marketValue,
                    hasContextSignal: costBasisPerShare != nil
                ),
                rawSource: rawLine
            ))
        }

        guard !holdings.isEmpty else {
            throw PortfolioImportError.noValidHoldings
        }

        return ParsedPortfolio(
            broker: formatName,
            holdings: holdings,
            unparsedLines: unparsedLines,
            overallConfidence: BrokerCSVParsing.overallConfidence(
                holdings: holdings,
                unparsedLines: unparsedLines
            )
        )
    }

    private func isHeaderRow(_ row: [String]) -> Bool {
        let map = BrokerCSVParsing.columnMap(for: row)
        return BrokerCSVParsing.firstColumnIndex(in: map, matching: Self.symbolHeaders) != nil
            && BrokerCSVParsing.firstColumnIndex(in: map, matching: Self.quantityHeaders) != nil
    }

    private func columnIndexes(from header: [String]) -> ColumnIndexes? {
        let map = BrokerCSVParsing.columnMap(for: header)
        guard let symbol = BrokerCSVParsing.firstColumnIndex(in: map, matching: Self.symbolHeaders),
              let quantity = BrokerCSVParsing.firstColumnIndex(in: map, matching: Self.quantityHeaders) else {
            return nil
        }

        return ColumnIndexes(
            symbol: symbol,
            quantity: quantity,
            marketValue: BrokerCSVParsing.firstColumnIndex(in: map, matching: Self.marketValueHeaders),
            perShareCost: BrokerCSVParsing.firstColumnIndex(in: map, matching: Self.perShareCostHeaders),
            totalCost: BrokerCSVParsing.firstColumnIndex(in: map, matching: Self.totalCostHeaders)
        )
    }

    private static func costBasisPerShare(
        perShareCost: Double?,
        totalCost: Double?,
        shares: Double
    ) -> Double? {
        if let perShareCost {
            let value = abs(perShareCost)
            if value.isFinite && value > 0 { return value }
        }
        guard let totalCost, shares != 0 else { return nil }
        let value = abs(totalCost / shares)
        return value.isFinite && value > 0 ? value : nil
    }

    private func shouldSkip(symbol: String, row: [String]) -> Bool {
        let normalizedSymbol = symbol.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let normalizedRow = row.joined(separator: " ").lowercased()

        return normalizedSymbol.isEmpty
            || normalizedSymbol.contains("cash")
            || normalizedSymbol.contains("money market")
            || normalizedSymbol.contains("sweep")
            || normalizedSymbol.contains("pending")
            || normalizedSymbol.contains("total")
            || normalizedRow.contains("cash & money market")
            || normalizedRow.contains("money market")
            || normalizedRow.contains("sweep")
            || normalizedRow.contains("pending activity")
            || normalizedRow.contains("account total")
            || normalizedRow.contains("account totals")
            || normalizedRow.contains("subtotal")
            || normalizedRow.contains("total account")
    }
}
