import Foundation

struct SchwabMobileParser: BrokerScreenshotParser {
    let brokerName = "Charles Schwab"

    private struct IndexedLine {
        let sourceIndex: Int
        let text: String
    }

    private struct NumberToken {
        let value: Double
        let isMoney: Bool
    }

    func canParse(_ rawText: [String]) -> Double {
        let lines = normalizedLines(rawText)
        guard !lines.isEmpty else { return 0 }

        let combined = lines.joined(separator: " ").lowercased()
        let hasSchwabMarker = combined.contains("schwab") || combined.contains("charles schwab")
        let hasKnownCompetitor = ["fidelity", "robinhood", "etrade", "e*trade", "vanguard", "webull"]
            .contains { combined.contains($0) }
        let hasColumnHeader = hasSchwabColumnHeader(in: lines)
        let hasAccountNumber = hasAccountNumberShape(in: combined)

        var score = 0.0
        if hasSchwabMarker { score += 0.35 }
        if combined.contains("positions") { score += 0.18 }
        if hasColumnHeader { score += 0.22 }
        if combined.contains("market value") || combined.contains("mkt value") || combined.contains("% of account") {
            score += 0.15
        }
        if hasAccountNumber { score += 0.05 }
        if lines.filter({ $0.contains("$") }).count >= 2 { score += 0.05 }

        if hasKnownCompetitor && !hasSchwabMarker {
            score = min(score, 0.25)
        } else if !hasSchwabMarker && hasColumnHeader && hasAccountNumber {
            score = min(score, 0.45)
        } else if !hasSchwabMarker {
            score = min(score, 0.35)
        }

        return min(max(score, 0), 1)
    }

    func parse(_ rawText: [String]) throws -> ParsedPortfolio {
        let lines = rawText.enumerated().compactMap { index, rawLine -> IndexedLine? in
            let normalized = normalizeLine(rawLine)
            guard !normalized.isEmpty else { return nil }
            return IndexedLine(sourceIndex: index, text: normalized)
        }

        var holdings: [ParsedHolding] = []
        var consumedLineIndexes: Set<Int> = []

        var index = 0
        while index < lines.count {
            let line = lines[index]

            if isIgnoredLine(line.text) {
                index += 1
                continue
            }

            guard let symbol = leadingSymbol(in: line.text) else {
                index += 1
                continue
            }

            var candidateLines = [line]
            var lookahead = index + 1

            while lookahead < lines.count && candidateLines.count < 4 {
                let next = lines[lookahead]

                if isIgnoredLine(next.text) {
                    lookahead += 1
                    continue
                }

                if leadingSymbol(in: next.text) != nil {
                    break
                }

                candidateLines.append(next)

                if parseNumbers(from: candidateLines.map(\.text).joined(separator: " ")).shares != nil {
                    break
                }

                lookahead += 1
            }

            if let holding = parseHolding(symbol: symbol, candidateLines: candidateLines) {
                holdings.append(holding)
                for candidateLine in candidateLines {
                    consumedLineIndexes.insert(candidateLine.sourceIndex)
                }
                index = max(index + 1, lookahead)
            } else {
                index += 1
            }
        }

        guard !holdings.isEmpty else {
            throw PortfolioImportError.noValidHoldings
        }

        let unparsedLines = lines
            .filter { !consumedLineIndexes.contains($0.sourceIndex) && !isIgnoredLine($0.text) }
            .map(\.text)

        let meanConfidence = holdings.reduce(0) { $0 + $1.confidence } / Double(holdings.count)
        let denominator = holdings.count + unparsedLines.count
        let unparsedRatio = denominator > 0 ? Double(unparsedLines.count) / Double(denominator) : 0
        let unparsedPenalty = max(0.75, 1.0 - (unparsedRatio * 0.25))
        let overallConfidence = meanConfidence * unparsedPenalty

        return ParsedPortfolio(
            broker: brokerName,
            holdings: holdings,
            unparsedLines: unparsedLines,
            overallConfidence: roundedConfidence(overallConfidence)
        )
    }

    /// Row confidence is deterministic:
    /// - 0.40 when the symbol is found in `MockStockData.knownStocks`, otherwise
    ///   0.20 for a syntactically valid unknown ticker.
    /// - 0.35 when share quantity parses and passes range checks.
    /// - 0.20 when market value parses and passes range checks.
    /// - 0.05 when the row has Schwab-like symbol-plus-numeric structure.
    /// The sum is clamped to 0...1 and rounded to four decimals for stable tests.
    private func confidence(symbol: String, shares: Double?, marketValue: Double?, source: String) -> Double {
        var score = isKnownSymbol(symbol) ? 0.40 : 0.20
        if shares != nil { score += 0.35 }
        if marketValue != nil { score += 0.20 }
        if containsNumericToken(source) { score += 0.05 }
        return roundedConfidence(min(score, 1))
    }

    private func parseHolding(symbol: String, candidateLines: [IndexedLine]) -> ParsedHolding? {
        let source = candidateLines.map(\.text).joined(separator: " ")
        let parsed = parseNumbers(from: source)

        guard let shares = parsed.shares else {
            return nil
        }

        return ParsedHolding(
            symbol: symbol,
            shares: shares,
            marketValue: parsed.marketValue,
            confidence: confidence(
                symbol: symbol,
                shares: shares,
                marketValue: parsed.marketValue,
                source: source
            ),
            rawSource: source
        )
    }

    private func parseNumbers(from source: String) -> (shares: Double?, marketValue: Double?) {
        let numberTokens = extractNumberTokens(from: source)
        let shareCandidates = numberTokens.filter { !$0.isMoney && isValidShareCount($0.value) }
        let moneyCandidates = numberTokens.filter { $0.isMoney && isValidMarketValue($0.value) }

        let shares = shareCandidates.first?.value
        let marketValue: Double?
        if let lastMoney = moneyCandidates.last {
            marketValue = lastMoney.value
        } else if numberTokens.count >= 3,
                  let lastNumber = numberTokens.last?.value,
                  isValidMarketValue(lastNumber) {
            marketValue = lastNumber
        } else {
            marketValue = nil
        }

        return (shares, marketValue)
    }

    private func extractNumberTokens(from source: String) -> [NumberToken] {
        let pattern = #"\$?\s*\(?\d[\d,]*(?:\.\d+)?\)?%?"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }

        let range = NSRange(source.startIndex..., in: source)
        return regex.matches(in: source, range: range).compactMap { match in
            guard let matchRange = Range(match.range, in: source) else { return nil }
            let token = String(source[matchRange])
            guard !token.contains("%") else { return nil }

            let cleaned = token
                .replacingOccurrences(of: "$", with: "")
                .replacingOccurrences(of: ",", with: "")
                .replacingOccurrences(of: "(", with: "")
                .replacingOccurrences(of: ")", with: "")
                .replacingOccurrences(of: " ", with: "")

            guard let value = Double(cleaned), value > 0 else { return nil }
            return NumberToken(value: value, isMoney: token.contains("$"))
        }
    }

    private func leadingSymbol(in line: String) -> String? {
        guard let firstToken = line.split(separator: " ").first else { return nil }
        let symbol = cleanSymbolToken(String(firstToken))
        guard isValidSymbol(symbol), !commonNonSymbols.contains(symbol) else { return nil }
        return symbol
    }

    private func cleanSymbolToken(_ token: String) -> String {
        token
            .uppercased()
            .trimmingCharacters(in: CharacterSet(charactersIn: " \t\n\r:;,-()[]{}"))
    }

    private func isValidSymbol(_ symbol: String) -> Bool {
        let pattern = #"^[A-Z]{1,5}(\.[A-Z])?$"#
        return symbol.range(of: pattern, options: .regularExpression) != nil
    }

    private func isKnownSymbol(_ symbol: String) -> Bool {
        knownSymbols.contains(symbol.uppercased())
    }

    private var knownSymbols: Set<String> {
        Set(MockStockData.knownStocks.map { $0.symbol.uppercased() })
    }

    private func isValidShareCount(_ value: Double) -> Bool {
        value > 0 && value < 1_000_000
    }

    private func isValidMarketValue(_ value: Double) -> Bool {
        value > 0 && value < 100_000_000
    }

    private func containsNumericToken(_ source: String) -> Bool {
        source.range(of: #"\d"#, options: .regularExpression) != nil
    }

    private func normalizedLines(_ rawText: [String]) -> [String] {
        rawText.map(normalizeLine).filter { !$0.isEmpty }
    }

    private func normalizeLine(_ line: String) -> String {
        line
            .replacingOccurrences(of: "\t", with: " ")
            .split(separator: " ")
            .joined(separator: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func hasSchwabColumnHeader(in lines: [String]) -> Bool {
        lines.contains { line in
            let normalized = line.lowercased()
            return normalized.contains("symbol")
                && (normalized.contains("qty") || normalized.contains("quantity"))
                && (normalized.contains("mkt value") || normalized.contains("market value") || normalized.contains("value"))
        }
    }

    private func hasAccountNumberShape(in text: String) -> Bool {
        let patterns = [
            #"(\*|x){2,}\d{4}"#,
            #"\.{2,}\d{4}"#,
            #"\b\d{3,4}-\d{4,8}\b"#,
            #"\baccount(?:\s+ending)?\s+\d{4}\b"#
        ]

        return patterns.contains { pattern in
            text.range(of: pattern, options: [.regularExpression, .caseInsensitive]) != nil
        }
    }

    private func isIgnoredLine(_ line: String) -> Bool {
        let normalized = line.lowercased()
        if normalized == "schwab" || normalized == "charles schwab" || normalized == "positions" {
            return true
        }
        if hasSchwabColumnHeader(in: [line]) {
            return true
        }
        if !containsNumericToken(line)
            && (normalized.contains("symbol")
                || normalized.contains("qty")
                || normalized.contains("mkt value")
                || normalized.contains("market value")) {
            return true
        }
        return false
    }

    private func roundedConfidence(_ value: Double) -> Double {
        (min(max(value, 0), 1) * 10_000).rounded() / 10_000
    }

    private let commonNonSymbols: Set<String> = [
        "ACCOUNT", "ACCOUNTS", "ACTIVITY", "ALL", "AS", "BALANCE", "BUY",
        "CASH", "CHANGE", "COST", "DAY", "ETF", "GAIN", "GAINS", "HOLDINGS",
        "LAST", "LOSS", "LOSSES", "MARKET", "MKT", "NEWS", "OPTION", "OPTIONS",
        "ORDER", "ORDERS", "POSITIONS", "PRICE", "QTY", "QUANTITY", "SELL",
        "SHARE", "SHARES", "STOCK", "SUMMARY", "SYMBOL", "TODAY", "TOTAL",
        "VALUE", "WATCHLIST"
    ]
}
