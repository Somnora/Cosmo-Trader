import Foundation
import UIKit

// MARK: - PortfolioImportService
// ===============================
// Imports portfolio holdings from broker positions CSVs and screenshots.
// Format detection lives in the registered BrokerCSVParser /
// BrokerScreenshotParser implementations; everything routes through
// ParsedPortfolio review before committing.

// MARK: - Import Error

enum PortfolioImportError: Error, LocalizedError {
    case fileNotFound
    case invalidFormat
    case emptyFile
    case noValidHoldings
    case parseError(String)
    case accessDenied
    case unrecognizedBroker
    case unrecognizedFormat

    var errorDescription: String? {
        switch self {
        case .fileNotFound:
            return "Could not find the file"
        case .invalidFormat:
            return "File format not recognized as CSV"
        case .emptyFile:
            return "The file appears to be empty"
        case .noValidHoldings:
            return "No valid holdings found in the file"
        case .parseError(let details):
            return "Parse error: \(details)"
        case .accessDenied:
            return "Permission denied to read file"
        case .unrecognizedBroker:
            return "Could not read holdings from this screenshot. Screenshot import currently works with Schwab mobile positions screens. You can add holdings manually or import a positions CSV instead."
        case .unrecognizedFormat:
            return "Could not read this file as a positions CSV. Export a positions file that includes Symbol and Quantity columns, or add holdings manually. Transaction history exports are not positions files."
        }
    }
}

// MARK: - Service

enum PortfolioImportCommitMode: Equatable {
    case replace
    case append
}

enum PortfolioImportService {

    private static let screenshotParsers: [BrokerScreenshotParser] = [
        SchwabMobileParser()
    ]

    // Ordered specialized-first: the generic fallback's confidence is capped
    // below the specialized parsers' full-signal scores (see
    // GenericPositionsCSVParser) so broker-specific formats keep routing to
    // their own parser.
    private static let csvParsers: [BrokerCSVParser] = [
        ThinkOrSwimPositionStatementParser(),
        SchwabWebPositionsParser(),
        GenericPositionsCSVParser()
    ]

    // MARK: - Main Import

    /// Parse a brokerage screenshot into structured holdings using registered broker parsers.
    static func parseScreenshot(_ image: UIImage) async throws -> ParsedPortfolio {
        let rawText = try await VisionOCRService.shared.recognizeText(from: image)
        let rawLines = rawText.components(separatedBy: .newlines)

        guard let bestParser = screenshotParsers
            .map({ parser in (parser: parser, confidence: parser.canParse(rawLines)) })
            .max(by: { $0.confidence < $1.confidence }),
              bestParser.confidence >= 0.4 else {
            throw PortfolioImportError.unrecognizedBroker
        }

        return try bestParser.parser.parse(rawLines)
    }

    /// Parse a broker CSV into structured holdings for review before committing.
    static func parseCSV(_ csvText: String) async throws -> ParsedPortfolio {
        guard !csvText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw PortfolioImportError.emptyFile
        }

        guard let bestParser = csvParsers
            .map({ parser in (parser: parser, confidence: parser.canParse(csvText)) })
            .max(by: { $0.confidence < $1.confidence }),
              bestParser.confidence >= 0.4 else {
            throw PortfolioImportError.unrecognizedFormat
        }

        return try bestParser.parser.parse(csvText)
    }

    /// Read and parse a broker CSV file for review before committing.
    static func parseCSVFile(_ url: URL) async throws -> ParsedPortfolio {
        guard url.startAccessingSecurityScopedResource() else {
            throw PortfolioImportError.accessDenied
        }
        defer { url.stopAccessingSecurityScopedResource() }

        let contents: String
        do {
            contents = try String(contentsOf: url, encoding: .utf8)
        } catch {
            do {
                contents = try String(contentsOf: url, encoding: .ascii)
            } catch {
                throw PortfolioImportError.parseError("Could not read file contents")
            }
        }

        return try await parseCSV(contents)
    }

    // MARK: - Helpers

    private static func cleanSymbol(_ symbol: String) -> String {
        var cleaned = symbol
            .replacingOccurrences(of: "\"", with: "")
            .trimmingCharacters(in: .whitespaces)

        // Remove common suffixes
        let suffixes = [".US", ".NYSE", ".NASDAQ", ".OTC", " US", " NYSE"]
        for suffix in suffixes {
            if cleaned.uppercased().hasSuffix(suffix.uppercased()) {
                cleaned = String(cleaned.dropLast(suffix.count))
            }
        }

        return cleaned
    }

    // MARK: - Apply Import

    static func stocks(
        from parsedHoldings: [ParsedHolding],
        livePrices: [String: Double] = [:]
    ) -> [Stock] {
        mergeDuplicateStocks(parsedHoldings.compactMap { stock(from: $0, livePrices: livePrices) })
    }

    static func replacePortfolio(
        with parsedHoldings: [ParsedHolding],
        in appState: AppState,
        livePrices: [String: Double] = [:]
    ) {
        commitPortfolio(
            with: parsedHoldings,
            in: appState,
            mode: .replace,
            livePrices: livePrices
        )
    }

    static func appendPortfolio(
        with parsedHoldings: [ParsedHolding],
        in appState: AppState,
        livePrices: [String: Double] = [:]
    ) {
        commitPortfolio(
            with: parsedHoldings,
            in: appState,
            mode: .append,
            livePrices: livePrices
        )
    }

    static func commitPortfolio(
        with parsedHoldings: [ParsedHolding],
        in appState: AppState,
        mode: PortfolioImportCommitMode,
        livePrices: [String: Double] = [:]
    ) {
        guard var user = appState.currentUser else { return }
        let importedStocks = stocks(from: parsedHoldings, livePrices: livePrices)

        switch mode {
        case .replace:
            user.portfolio = importedStocks
        case .append:
            user.portfolio = mergeDuplicateStocks(user.portfolio + importedStocks)
        }

        appState.currentUser = user
        appState.saveUserToStorage()
        appState.selectedTab = .portfolio
        appState.portfolioImportFeedback = PortfolioImportFeedback(
            mode: mode,
            importedCount: importedStocks.count,
            totalHoldings: user.portfolio.count
        )
    }

    private static func stock(
        from parsedHolding: ParsedHolding,
        livePrices: [String: Double]
    ) -> Stock? {
        let symbol = cleanSymbol(parsedHolding.symbol).uppercased()
        guard !symbol.isEmpty, parsedHolding.shares > 0 else { return nil }

        let marketValuePerShare: Double? = {
            guard let marketValue = parsedHolding.marketValue,
                  parsedHolding.shares != 0 else { return nil }
            let unitValue = abs(marketValue / parsedHolding.shares)
            return unitValue.isFinite && unitValue > 0 ? unitValue : nil
        }()

        let costBasisPerShare = parsedHolding.costBasisPerShare.flatMap { value in
            value.isFinite && value > 0 ? value : nil
        }
        let livePrice = livePrices[symbol].flatMap { $0 > 0 ? $0 : nil }
        let importedOrProviderPrice = livePrice ?? marketValuePerShare ?? 0

        if let knownStock = MockStockData.knownStocks.first(where: { $0.symbol.uppercased() == symbol }) {
            var stock = knownStock
            stock.sharesOwned = parsedHolding.shares
            stock.currentPrice = importedOrProviderPrice
            stock.priceChange = 0
            stock.percentageChange = 0
            stock.purchasePrice = costBasisPerShare
            stock.purchaseDate = Date()
            return stock
        }

        return Stock(
            symbol: symbol,
            name: symbol,
            currentPrice: importedOrProviderPrice,
            priceChange: 0,
            percentageChange: 0,
            sharesOwned: parsedHolding.shares,
            purchasePrice: costBasisPerShare,
            purchaseDate: Date(),
            foundedDate: nil,
            sector: "Unknown"
        )
    }

    private static func mergeDuplicateStocks(_ stocks: [Stock]) -> [Stock] {
        var merged: [String: Stock] = [:]
        var order: [String] = []

        for stock in stocks {
            let symbol = stock.symbol.uppercased()
            guard stock.sharesOwned > 0 else { continue }

            if var existing = merged[symbol] {
                let combinedShares = existing.sharesOwned + stock.sharesOwned
                existing.purchasePrice = weightedAverageCost(
                    existingCost: existing.purchasePrice,
                    existingShares: existing.sharesOwned,
                    incomingCost: stock.purchasePrice,
                    incomingShares: stock.sharesOwned
                )
                existing.sharesOwned = combinedShares

                if stock.currentPrice > 0 {
                    existing.currentPrice = stock.currentPrice
                    existing.priceChange = stock.priceChange
                    existing.percentageChange = stock.percentageChange
                }

                merged[symbol] = existing
            } else {
                merged[symbol] = stock
                order.append(symbol)
            }
        }

        return order.compactMap { merged[$0] }
    }

    private static func weightedAverageCost(
        existingCost: Double?,
        existingShares: Double,
        incomingCost: Double?,
        incomingShares: Double
    ) -> Double? {
        switch (existingCost, incomingCost) {
        case let (.some(existingCost), .some(incomingCost)):
            let totalShares = existingShares + incomingShares
            guard totalShares > 0 else { return nil }
            return ((existingCost * existingShares) + (incomingCost * incomingShares)) / totalShares
        case let (.some(existingCost), .none):
            return existingCost
        case let (.none, .some(incomingCost)):
            return incomingCost
        case (.none, .none):
            return nil
        }
    }

    #if DEBUG
    // MARK: - Debug Sample CSV

    /// Generate sample CSV for previews and debug-only manual testing.
    static func generateSampleCSV() -> String {
        """
        Symbol,Description,Quantity,Price,Market Value,Cost Basis
        AAPL,Apple Inc,10,178.52,1785.20,1500.00
        GOOGL,Alphabet Inc,5,141.80,709.00,675.00
        TSLA,Tesla Inc,3,248.50,745.50,600.00
        MSFT,Microsoft Corp,8,378.91,3031.28,2800.00
        NVDA,NVIDIA Corp,2,467.80,935.60,600.00
        """
    }
    #endif
}
