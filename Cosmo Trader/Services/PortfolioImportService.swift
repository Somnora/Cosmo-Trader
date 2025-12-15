import Foundation
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
        MockStockData.all.first { $0.symbol.uppercased() == symbol.uppercased() }
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
        }
    }
}

// MARK: - Service

enum PortfolioImportService {

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

        return try parseCSV(contents)
    }

    /// Import from CSV string content directly
    static func importFromCSVString(_ contents: String) throws -> PortfolioImportResult {
        guard !contents.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw PortfolioImportError.emptyFile
        }
        return try parseCSV(contents)
    }

    // MARK: - CSV Parsing

    private static func parseCSV(_ contents: String) throws -> PortfolioImportResult {
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

    /// Apply imported holdings to the app state
    static func applyImport(
        holdings: [ImportedHolding],
        to appState: AppState,
        replaceExisting: Bool = false
    ) {
        guard var user = appState.currentUser else { return }

        if replaceExisting {
            // Clear existing portfolio
            user.portfolio = []
        }

        for holding in holdings {
            if let existingStock = holding.matchedStock {
                // Update with import data
                var stockToAdd = existingStock
                stockToAdd.sharesOwned = holding.quantity
                stockToAdd.purchasePrice = holding.averageCost
                stockToAdd.purchaseDate = Date()

                // Add or update in portfolio
                if let index = user.portfolio.firstIndex(where: { $0.symbol == stockToAdd.symbol }) {
                    if replaceExisting {
                        user.portfolio[index] = stockToAdd
                    } else {
                        // Add to existing shares
                        user.portfolio[index].sharesOwned += holding.quantity
                    }
                } else {
                    user.portfolio.append(stockToAdd)
                }
            }
            // Note: Unrecognized symbols are skipped for now
            // In a production app, you might create placeholder stocks
        }

        appState.currentUser = user
        appState.saveUserToStorage()
    }

    // MARK: - Sample CSV

    /// Generate sample CSV for testing
    static func generateSampleCSV() -> String {
        """
        Symbol,Quantity,Average Cost,Current Price,Total Value
        AAPL,10,150.00,178.52,1785.20
        GOOGL,5,135.00,141.80,709.00
        TSLA,3,200.00,248.50,745.50
        MSFT,8,350.00,378.91,3031.28
        NVDA,2,300.00,467.80,935.60
        """
    }
}
