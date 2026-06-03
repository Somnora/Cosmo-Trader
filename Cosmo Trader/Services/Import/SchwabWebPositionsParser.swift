import Foundation

struct SchwabWebPositionsParser: BrokerCSVParser {
    let formatName = "Schwab Web Positions"

    private struct ColumnIndexes {
        let symbol: Int
        let quantity: Int
        let marketValue: Int?
        let costBasis: Int?
    }

    func canParse(_ csvText: String) -> Double {
        let rows = BrokerCSVParsing.rows(from: csvText)
        guard let header = rows.first(where: { row in
            let normalized = Set(row.map(BrokerCSVParsing.normalizedHeader))
            return normalized.contains("symbol")
                && (normalized.contains("quantity") || normalized.contains("qty"))
        }) else {
            return 0
        }

        let normalized = Set(header.map(BrokerCSVParsing.normalizedHeader))
        let signals = [
            normalized.contains("symbol"),
            normalized.contains("quantity") || normalized.contains("qty"),
            normalized.contains("market value"),
            normalized.contains("cost basis")
        ].filter { $0 }.count

        switch signals {
        case 4:
            return 0.7
        case 3:
            return 0.4
        default:
            return 0
        }
    }

    func parse(_ csvText: String) throws -> ParsedPortfolio {
        let rawLines = BrokerCSVParsing.lines(from: csvText)
        let rows = rawLines.map(BrokerCSVParsing.splitRow)

        guard let headerIndex = rows.firstIndex(where: isHeaderRow),
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
            let totalCostBasis = BrokerCSVParsing.parseDouble(BrokerCSVParsing.value(in: row, at: columns.costBasis))
            let costBasisPerShare = Self.costBasisPerShare(totalCostBasis: totalCostBasis, shares: shares)

            holdings.append(ParsedHolding(
                symbol: symbol,
                shares: shares,
                marketValue: marketValue,
                costBasisPerShare: costBasisPerShare,
                confidence: BrokerCSVParsing.rowConfidence(
                    symbol: symbol,
                    shares: shares,
                    marketValue: marketValue,
                    hasContextSignal: true
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
        let normalized = Set(row.map(BrokerCSVParsing.normalizedHeader))
        return normalized.contains("symbol")
            && (normalized.contains("quantity") || normalized.contains("qty"))
    }

    private func columnIndexes(from header: [String]) -> ColumnIndexes? {
        let map = BrokerCSVParsing.columnMap(for: header)
        guard let symbol = BrokerCSVParsing.firstColumnIndex(in: map, matching: ["Symbol"]),
              let quantity = BrokerCSVParsing.firstColumnIndex(in: map, matching: ["Quantity", "Qty"]) else {
            return nil
        }

        return ColumnIndexes(
            symbol: symbol,
            quantity: quantity,
            marketValue: BrokerCSVParsing.firstColumnIndex(in: map, matching: ["Market Value"]),
            costBasis: BrokerCSVParsing.firstColumnIndex(in: map, matching: ["Cost Basis"])
        )
    }

    private static func costBasisPerShare(totalCostBasis: Double?, shares: Double) -> Double? {
        guard let totalCostBasis, shares != 0 else { return nil }
        let value = abs(totalCostBasis / shares)
        return value.isFinite && value > 0 ? value : nil
    }

    private func shouldSkip(symbol: String, row: [String]) -> Bool {
        let normalizedSymbol = symbol.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let normalizedRow = row.joined(separator: " ").lowercased()

        return normalizedSymbol.isEmpty
            || normalizedSymbol.contains("cash")
            || normalizedSymbol.contains("money market")
            || normalizedSymbol.contains("sweep")
            || normalizedRow.contains("cash & money market")
            || normalizedRow.contains("money market")
            || normalizedRow.contains("sweep")
            || normalizedRow.contains("account total")
            || normalizedRow.contains("account totals")
            || normalizedRow.contains("subtotal")
            || normalizedRow.contains("total account")
    }
}
