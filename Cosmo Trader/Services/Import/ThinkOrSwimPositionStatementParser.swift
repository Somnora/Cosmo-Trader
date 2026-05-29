import Foundation

struct ThinkOrSwimPositionStatementParser: BrokerCSVParser {
    let formatName = "thinkorswim Position Statement"

    private struct ColumnIndexes {
        let instrument: Int
        let quantity: Int
        let marketValue: Int?
    }

    func canParse(_ csvText: String) -> Double {
        let lines = BrokerCSVParsing.lines(from: csvText)
        let combined = csvText.lowercased()
        let hasPositionStatement = combined.contains("position statement")
        let hasInstrument = combined.contains("instrument")
        let hasBPEffect = combined.contains("bp effect")
        let hasGroupLabel = lines.contains { isGroupLabel($0.trimmingCharacters(in: .whitespacesAndNewlines)) }

        let signalCount = [hasPositionStatement, hasInstrument, hasBPEffect, hasGroupLabel].filter { $0 }.count
        guard signalCount > 0 else { return 0 }
        if signalCount == 1 { return 0.4 }

        return BrokerCSVParsing.roundedConfidence(min(0.65 + (Double(signalCount - 2) * 0.1), 0.95))
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
        var currentGroup: String?

        for index in rows.indices {
            let rawLine = rawLines[index].trimmingCharacters(in: .whitespacesAndNewlines)
            let row = rows[index]
            guard !row.allSatisfy({ $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) else { continue }

            if isGroupLabel(rawLine) {
                currentGroup = rawLine
                continue
            }

            if index <= headerIndex || isHeaderRow(row) {
                continue
            }

            let instrument = BrokerCSVParsing.value(in: row, at: columns.instrument)
            if shouldSkip(instrument: instrument, row: row) {
                if !rawLine.isEmpty, !isSummaryRow(instrument) {
                    unparsedLines.append(rawLine)
                }
                continue
            }

            let symbol = BrokerCSVParsing.cleanSymbol(instrument)
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
            let source = [
                currentGroup.map { "group: \($0) | " } ?? "",
                rawLine
            ].joined()

            holdings.append(ParsedHolding(
                symbol: symbol,
                shares: shares,
                marketValue: marketValue,
                confidence: BrokerCSVParsing.rowConfidence(
                    symbol: symbol,
                    shares: shares,
                    marketValue: marketValue,
                    hasContextSignal: currentGroup != nil
                ),
                rawSource: source
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
        guard normalized.contains("instrument") else { return false }

        let requiredSignals = [
            "qty",
            "mark",
            "net liq",
            "p/l %",
            "bp effect"
        ]
        return requiredSignals.filter { normalized.contains($0) }.count >= 3
    }

    private func columnIndexes(from header: [String]) -> ColumnIndexes? {
        let map = BrokerCSVParsing.columnMap(for: header)
        guard let instrument = BrokerCSVParsing.firstColumnIndex(in: map, matching: ["Instrument"]),
              let quantity = BrokerCSVParsing.firstColumnIndex(in: map, matching: ["Qty"]) else {
            return nil
        }

        return ColumnIndexes(
            instrument: instrument,
            quantity: quantity,
            marketValue: BrokerCSVParsing.firstColumnIndex(in: map, matching: ["Net Liq", "Net Liquidity"])
        )
    }

    private func shouldSkip(instrument: String, row: [String]) -> Bool {
        let normalizedInstrument = instrument.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let normalizedRow = row.joined(separator: " ").lowercased()

        return normalizedInstrument.isEmpty
            || normalizedInstrument.hasPrefix("----")
            || isSummaryRow(instrument)
            || normalizedRow.contains("cash & sweep")
            || normalizedRow.contains("cash and sweep")
            || normalizedRow.contains("sweep vehicle")
    }

    private func isSummaryRow(_ instrument: String) -> Bool {
        let normalized = instrument.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return normalized.contains("subtotals")
            || normalized.contains("overall totals")
            || normalized.contains("overall total")
    }

    private func isGroupLabel(_ line: String) -> Bool {
        line.range(of: #"^\([A-Za-z][^)]*\)$"#, options: .regularExpression) != nil
    }
}
