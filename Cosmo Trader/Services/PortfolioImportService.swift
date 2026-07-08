import Foundation
import UIKit
import UniformTypeIdentifiers

// MARK: - PortfolioImportService
// ===============================
// Imports portfolio holdings from CSV files exported by brokers.
// Supports Robinhood, Fidelity, Schwab, and generic CSV formats.

// MARK: - Import Result

struct PortfolioImportResult {
    let holdings: [ImportedHolding]
    let format: CSVFormat
    let warnings: [ImportWarning]
    let skippedRows: Int

    var totalShares: Double {
        holdings.reduce(0) { $0 + $1.quantity }
    }

    var totalValue: Double {
        holdings.reduce(0) { $0 + ($1.quantity * ($1.averageCost ?? 0)) }
    }

    var isSuccessful: Bool {
        !holdings.isEmpty
    }

    var summary: String {
        if holdings.isEmpty {
            return "No holdings found in file"
        }
        return "Found \(holdings.count) stocks totaling \(String(format: "%.0f", totalShares)) shares"
    }
}

// MARK: - Imported Holding

struct ImportedHolding: Identifiable {
    let id = UUID()
    let symbol: String
    let quantity: Double
    let averageCost: Double?
    let currentPrice: Double?
    let totalValue: Double?

    /// Matched stock from our database (if found)
    var matchedStock: Stock? {
        MockStockData.knownStocks.first { $0.symbol.uppercased() == symbol.uppercased() }
    }

    /// Whether we have this stock in our database
    var isRecognized: Bool {
        matchedStock != nil
    }

    /// Formatted quantity
    var formattedQuantity: String {
        if quantity == floor(quantity) {
            return String(format: "%.0f", quantity)
        }
        return String(format: "%.4f", quantity)
    }

    /// Formatted average cost
    var formattedAverageCost: String? {
        guard let cost = averageCost else { return nil }
        return String(format: "$%.2f", cost)
    }
}

// MARK: - Import Warning

struct ImportWarning: Identifiable {
    let id = UUID()
    let type: WarningType
    let message: String
    let row: Int?

    enum WarningType {
        case unknownSymbol
        case invalidQuantity
        case missingData
        case formatGuess
    }
}

// MARK: - CSV Format

enum CSVFormat: String, CaseIterable {
    case robinhood = "Robinhood"
    case fidelity = "Fidelity"
    case schwab = "Charles Schwab"
    case etrade = "E*TRADE"
    case tdAmeritrade = "TD Ameritrade"
    case generic = "Generic CSV"

    var description: String {
        switch self {
        case .robinhood:
            return "Robinhood export format"
        case .fidelity:
            return "Fidelity Investments format"
        case .schwab:
            return "Charles Schwab format"
        case .etrade:
            return "E*TRADE format"
        case .tdAmeritrade:
            return "TD Ameritrade format"
        case .generic:
            return "Standard CSV with Symbol and Quantity columns"
        }
    }

    var exportInstructions: String {
        switch self {
        case .robinhood:
            return "Account → Statements & History → Export"
        case .fidelity:
            return "Accounts → Positions → Download"
        case .schwab:
            return "Accounts → Positions → Export"
        case .etrade:
            return "Accounts → Positions → Download"
        case .tdAmeritrade:
            return "My Account → Positions → Export"
        case .generic:
            return "Export positions as CSV from your broker"
        }
    }
}

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
            return "Could not recognize a supported broker screenshot"
        case .unrecognizedFormat:
            return "Could not recognize a supported portfolio CSV format"
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

    /// Import holdings from a CSV file URL
    static func importFromCSV(fileURL: URL) throws -> PortfolioImportResult {
        // Start accessing security-scoped resource
        guard fileURL.startAccessingSecurityScopedResource() else {
            throw PortfolioImportError.accessDenied
        }
        defer { fileURL.stopAccessingSecurityScopedResource() }

        // Read file contents
        let contents: String
        do {
            contents = try String(contentsOf: fileURL, encoding: .utf8)
        } catch {
            // Try other encodings
            do {
                contents = try String(contentsOf: fileURL, encoding: .ascii)
            } catch {
                throw PortfolioImportError.parseError("Could not read file contents")
            }
        }

        guard !contents.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw PortfolioImportError.emptyFile
        }

        return try parseLegacyCSV(contents)
    }

    /// Import from CSV string content directly
    static func importFromCSVString(_ contents: String) throws -> PortfolioImportResult {
        guard !contents.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw PortfolioImportError.emptyFile
        }
        return try parseLegacyCSV(contents)
    }

    /// Parse a brokerage screenshot into structured holdings using registered broker parsers.
    static func parseScreenshot(_ image: UIImage) async throws -> ParsedPortfolio {
        let ocrPortfolio = try await VisionOCRService.shared.extractPortfolio(from: image)
        let rawLines = ocrPortfolio.rawText.components(separatedBy: .newlines)

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

    // MARK: - CSV Parsing

    private static func parseLegacyCSV(_ contents: String) throws -> PortfolioImportResult {
        // Split into rows
        let rows = contents.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        guard !rows.isEmpty else {
            throw PortfolioImportError.emptyFile
        }

        // Detect format from header
        let headerRow = rows[0]
        let format = detectCSVFormat(headers: headerRow)

        // Get column indices
        let columns = parseHeader(headerRow)

        // Parse data rows
        var holdings: [ImportedHolding] = []
        var warnings: [ImportWarning] = []
        var skippedRows = 0

        for (index, row) in rows.dropFirst().enumerated() {
            if row.isEmpty { continue }

            if let holding = parseRow(row, columns: columns, format: format) {
                // Check if symbol is recognized
                if !holding.isRecognized {
                    warnings.append(ImportWarning(
                        type: .unknownSymbol,
                        message: "\(holding.symbol) not in database - will be added as custom holding",
                        row: index + 2
                    ))
                }
                holdings.append(holding)
            } else {
                skippedRows += 1
            }
        }

        if holdings.isEmpty {
            throw PortfolioImportError.noValidHoldings
        }

        // Add format guess warning if using generic
        if format == .generic {
            warnings.insert(ImportWarning(
                type: .formatGuess,
                message: "Format auto-detected. Please verify the imported data.",
                row: nil
            ), at: 0)
        }

        return PortfolioImportResult(
            holdings: holdings,
            format: format,
            warnings: warnings,
            skippedRows: skippedRows
        )
    }

    // MARK: - Format Detection

    private static func detectCSVFormat(headers: String) -> CSVFormat {
        let headerLower = headers.lowercased()

        // Robinhood: typically has "instrument" or specific headers
        if headerLower.contains("instrument") || headerLower.contains("average cost") {
            return .robinhood
        }

        // Fidelity: has "account" and "description" columns
        if headerLower.contains("account") && headerLower.contains("description") {
            return .fidelity
        }

        // Schwab: has "symbol" and "price" with specific ordering
        if headerLower.contains("action") || headerLower.contains("schwab") {
            return .schwab
        }

        // E*TRADE
        if headerLower.contains("etrade") || headerLower.contains("e*trade") {
            return .etrade
        }

        // TD Ameritrade
        if headerLower.contains("td ameritrade") || headerLower.contains("tdameritrade") {
            return .tdAmeritrade
        }

        return .generic
    }

    // MARK: - Header Parsing

    private struct ColumnIndices {
        var symbol: Int?
        var quantity: Int?
        var averageCost: Int?
        var currentPrice: Int?
        var totalValue: Int?
    }

    private static func parseHeader(_ header: String) -> ColumnIndices {
        let columns = splitCSVRow(header).map { $0.lowercased().trimmingCharacters(in: .whitespaces) }
        var indices = ColumnIndices()

        for (index, column) in columns.enumerated() {
            // Symbol detection
            if column.contains("symbol") || column.contains("ticker") || column == "stock" {
                indices.symbol = index
            }

            // Quantity detection
            if column.contains("quantity") || column.contains("shares") || column == "qty" || column.contains("units") {
                indices.quantity = index
            }

            // Average cost detection
            if column.contains("average") || column.contains("avg cost") || column.contains("cost basis") || column.contains("purchase price") {
                indices.averageCost = index
            }

            // Current price detection
            if column.contains("current price") || column.contains("last price") || column.contains("market price") || column == "price" {
                indices.currentPrice = index
            }

            // Total value detection
            if column.contains("market value") || column.contains("total value") || column.contains("value") {
                indices.totalValue = index
            }
        }

        // If no explicit symbol column, try first column
        if indices.symbol == nil && !columns.isEmpty {
            // Check if first column looks like symbols
            indices.symbol = 0
        }

        // If no explicit quantity column, try second column
        if indices.quantity == nil && columns.count > 1 {
            indices.quantity = 1
        }

        return indices
    }

    // MARK: - Row Parsing

    private static func parseRow(_ row: String, columns: ColumnIndices, format: CSVFormat) -> ImportedHolding? {
        let values = splitCSVRow(row)

        guard !values.isEmpty else { return nil }

        // Get symbol
        guard let symbolIndex = columns.symbol, symbolIndex < values.count else { return nil }
        var symbol = values[symbolIndex].trimmingCharacters(in: .whitespaces)

        // Clean up symbol
        symbol = cleanSymbol(symbol)

        // Skip if symbol is empty or looks like a header
        guard !symbol.isEmpty,
              symbol.count <= 10,
              !symbol.lowercased().contains("symbol"),
              !symbol.lowercased().contains("ticker") else {
            return nil
        }

        // Get quantity
        var quantity: Double = 0
        if let quantityIndex = columns.quantity, quantityIndex < values.count {
            let quantityStr = values[quantityIndex]
                .replacingOccurrences(of: ",", with: "")
                .trimmingCharacters(in: .whitespaces)
            quantity = Double(quantityStr) ?? 0
        }

        // Skip if quantity is 0 or negative
        guard quantity > 0 else { return nil }

        // Get optional values
        var averageCost: Double?
        if let costIndex = columns.averageCost, costIndex < values.count {
            averageCost = parseMoneyValue(values[costIndex])
        }

        var currentPrice: Double?
        if let priceIndex = columns.currentPrice, priceIndex < values.count {
            currentPrice = parseMoneyValue(values[priceIndex])
        }

        var totalValue: Double?
        if let valueIndex = columns.totalValue, valueIndex < values.count {
            totalValue = parseMoneyValue(values[valueIndex])
        }

        return ImportedHolding(
            symbol: symbol.uppercased(),
            quantity: quantity,
            averageCost: averageCost,
            currentPrice: currentPrice,
            totalValue: totalValue
        )
    }

    // MARK: - Helpers

    private static func splitCSVRow(_ row: String) -> [String] {
        var values: [String] = []
        var current = ""
        var inQuotes = false

        for char in row {
            if char == "\"" {
                inQuotes.toggle()
            } else if char == "," && !inQuotes {
                values.append(current)
                current = ""
            } else {
                current.append(char)
            }
        }
        values.append(current)

        return values.map { $0.trimmingCharacters(in: CharacterSet(charactersIn: "\"").union(.whitespaces)) }
    }

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

    private static func parseMoneyValue(_ value: String) -> Double? {
        let cleaned = value
            .replacingOccurrences(of: "$", with: "")
            .replacingOccurrences(of: ",", with: "")
            .replacingOccurrences(of: "(", with: "-")
            .replacingOccurrences(of: ")", with: "")
            .trimmingCharacters(in: .whitespaces)

        return Double(cleaned)
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
