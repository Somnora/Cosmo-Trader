import Foundation

protocol BrokerCSVParser {
    var formatName: String { get }

    /// Returns parser confidence for the raw CSV text. Values are clamped to 0...1.
    func canParse(_ csvText: String) -> Double

    func parse(_ csvText: String) throws -> ParsedPortfolio
}

enum BrokerCSVParsing {
    nonisolated static func rows(from csvText: String) -> [[String]] {
        lines(from: csvText).map(splitRow)
    }

    nonisolated static func lines(from csvText: String) -> [String] {
        csvText
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
            .components(separatedBy: "\n")
    }

    nonisolated static func splitRow(_ row: String) -> [String] {
        var values: [String] = []
        var current = ""
        var inQuotes = false
        var index = row.startIndex

        while index < row.endIndex {
            let character = row[index]

            if character == "\"" {
                let next = row.index(after: index)
                if inQuotes, next < row.endIndex, row[next] == "\"" {
                    current.append("\"")
                    index = row.index(after: next)
                    continue
                }
                inQuotes.toggle()
            } else if character == "," && !inQuotes {
                values.append(cleanCell(current))
                current = ""
            } else {
                current.append(character)
            }

            index = row.index(after: index)
        }

        values.append(cleanCell(current))
        return values
    }

    nonisolated static func cleanCell(_ cell: String) -> String {
        var trimmed = cell.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.hasPrefix("\""), trimmed.hasSuffix("\""), trimmed.count >= 2 {
            trimmed.removeFirst()
            trimmed.removeLast()
        }
        return trimmed.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    nonisolated static func normalizedHeader(_ value: String) -> String {
        value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .replacingOccurrences(of: "  ", with: " ")
    }

    nonisolated static func columnMap(for header: [String]) -> [String: Int] {
        var map: [String: Int] = [:]
        for (index, cell) in header.enumerated() {
            map[normalizedHeader(cell)] = index
        }
        return map
    }

    nonisolated static func firstColumnIndex(in map: [String: Int], matching names: [String]) -> Int? {
        for name in names {
            if let index = map[normalizedHeader(name)] {
                return index
            }
        }
        return nil
    }

    nonisolated static func value(in row: [String], at index: Int?) -> String {
        guard let index, row.indices.contains(index) else { return "" }
        return row[index].trimmingCharacters(in: .whitespacesAndNewlines)
    }

    nonisolated static func parseDouble(_ value: String) -> Double? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed != "--", trimmed != "-" else { return nil }

        let isParenthesized = trimmed.hasPrefix("(") && trimmed.hasSuffix(")")
        let isLeadingNegative = trimmed.hasPrefix("-")
        let cleaned = trimmed
            .replacingOccurrences(of: "$", with: "")
            .replacingOccurrences(of: ",", with: "")
            .replacingOccurrences(of: "%", with: "")
            .replacingOccurrences(of: "(", with: "")
            .replacingOccurrences(of: ")", with: "")
            .replacingOccurrences(of: "+", with: "")
            .replacingOccurrences(of: "-", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let number = Double(cleaned), number.isFinite else { return nil }
        return (isParenthesized || isLeadingNegative) ? -number : number
    }

    nonisolated static func cleanSymbol(_ value: String) -> String {
        var symbol = value
            .uppercased()
            .trimmingCharacters(in: CharacterSet(charactersIn: " \t\n\r\"':;()[]{}"))

        let suffixes = [".US", ".NYSE", ".NASDAQ", ".OTC", " US", " NYSE", " NASDAQ"]
        for suffix in suffixes where symbol.hasSuffix(suffix) {
            symbol = String(symbol.dropLast(suffix.count))
        }

        return symbol.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    nonisolated static func isValidSymbol(_ symbol: String) -> Bool {
        symbol.range(of: #"^[A-Z]{1,5}(\.[A-Z])?$"#, options: .regularExpression) != nil
    }

    static func isKnownSymbol(_ symbol: String) -> Bool {
        knownSymbols.contains(symbol.uppercased())
    }

    static var knownSymbols: Set<String> {
        Set(MockStockData.knownStocks.map { $0.symbol.uppercased() })
    }

    static func rowConfidence(
        symbol: String,
        shares: Double?,
        marketValue: Double?,
        hasContextSignal: Bool
    ) -> Double {
        var score = isKnownSymbol(symbol) ? 0.40 : 0.20
        if shares != nil { score += 0.35 }
        if marketValue != nil { score += 0.20 }
        if hasContextSignal { score += 0.05 }
        return roundedConfidence(min(score, 1))
    }

    static func overallConfidence(holdings: [ParsedHolding], unparsedLines: [String]) -> Double {
        guard !holdings.isEmpty else { return 0 }
        let meanConfidence = holdings.reduce(0) { $0 + $1.confidence } / Double(holdings.count)
        let denominator = holdings.count + unparsedLines.count
        let unparsedRatio = denominator > 0 ? Double(unparsedLines.count) / Double(denominator) : 0
        let unparsedPenalty = max(0.75, 1.0 - (unparsedRatio * 0.25))
        return roundedConfidence(meanConfidence * unparsedPenalty)
    }

    nonisolated static func roundedConfidence(_ value: Double) -> Double {
        (min(max(value, 0), 1) * 10_000).rounded() / 10_000
    }
}
