import Foundation
import Vision
import UIKit

// MARK: - VisionOCRService
// ========================
// Extracts portfolio holdings from brokerage screenshots using Vision framework OCR.
// Supports auto-detection of broker apps and parsing of stock symbols, quantities, and prices.

// MARK: - OCR Extracted Portfolio

struct OCRExtractedPortfolio {
    let holdings: [OCRExtractedHolding]
    let rawText: String
    let confidence: Double
    let detectedBroker: DetectedBroker?
    let warnings: [String]

    var isEmpty: Bool {
        holdings.isEmpty
    }

    var recognizedCount: Int {
        holdings.filter { $0.isRecognized }.count
    }

    var summary: String {
        if holdings.isEmpty {
            return "No holdings detected in image"
        }
        return "Found \(holdings.count) potential holdings (\(recognizedCount) recognized)"
    }
}

// MARK: - OCR Extracted Holding

struct OCRExtractedHolding: Identifiable {
    let id = UUID()
    let symbol: String
    var quantity: Double?
    var price: Double?
    var totalValue: Double?
    let confidence: Double

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
        guard let qty = quantity else { return "-" }
        if qty == floor(qty) {
            return String(format: "%.0f", qty)
        }
        return String(format: "%.4f", qty)
    }

    /// Formatted price
    var formattedPrice: String {
        guard let p = price else { return "-" }
        return String(format: "$%.2f", p)
    }

    /// Confidence level description
    var confidenceLevel: String {
        switch confidence {
        case 0.75...: return "High"
        case 0.5..<0.75: return "Medium"
        default: return "Low"
        }
    }
}

// MARK: - Detected Broker

enum DetectedBroker: String, CaseIterable {
    case robinhood = "Robinhood"
    case fidelity = "Fidelity"
    case schwab = "Charles Schwab"
    case etrade = "E*TRADE"
    case tdAmeritrade = "TD Ameritrade"
    case webull = "Webull"
    case coinbase = "Coinbase"
    case unknown = "Unknown"

    var icon: String {
        switch self {
        case .robinhood: return "leaf.fill"
        case .fidelity: return "building.columns.fill"
        case .schwab: return "s.circle.fill"
        case .etrade: return "e.circle.fill"
        case .tdAmeritrade: return "t.circle.fill"
        case .webull: return "w.circle.fill"
        case .coinbase: return "bitcoinsign.circle.fill"
        case .unknown: return "questionmark.circle.fill"
        }
    }
}

// MARK: - OCR Error

enum VisionOCRError: Error, LocalizedError {
    case imageConversionFailed
    case noTextFound
    case processingFailed(String)
    case noHoldingsDetected

    var errorDescription: String? {
        switch self {
        case .imageConversionFailed:
            return "Failed to process the image"
        case .noTextFound:
            return "No text could be detected in the image"
        case .processingFailed(let details):
            return "OCR processing failed: \(details)"
        case .noHoldingsDetected:
            return "No stock holdings could be identified in the image"
        }
    }
}

// MARK: - Service

final class VisionOCRService {

    // MARK: - Singleton

    static let shared = VisionOCRService()

    private init() {}

    // MARK: - Main Extraction

    /// Extract portfolio holdings from a screenshot image
    func extractPortfolio(from image: UIImage) async throws -> OCRExtractedPortfolio {
        // Convert UIImage to CGImage
        guard let cgImage = image.cgImage else {
            throw VisionOCRError.imageConversionFailed
        }

        // Perform OCR
        let recognizedText = try await performOCR(on: cgImage)

        guard !recognizedText.isEmpty else {
            throw VisionOCRError.noTextFound
        }

        // Detect broker from text patterns
        let broker = detectBroker(from: recognizedText)

        // Parse holdings from text
        let (holdings, warnings) = parseHoldings(from: recognizedText, broker: broker)

        // Calculate overall confidence
        let overallConfidence = holdings.isEmpty ? 0.0 :
            holdings.reduce(0.0) { $0 + $1.confidence } / Double(holdings.count)

        return OCRExtractedPortfolio(
            holdings: holdings,
            rawText: recognizedText,
            confidence: overallConfidence,
            detectedBroker: broker,
            warnings: warnings
        )
    }

    // MARK: - Vision OCR

    private func performOCR(on cgImage: CGImage) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: VisionOCRError.processingFailed(error.localizedDescription))
                    return
                }

                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(returning: "")
                    return
                }

                // Combine all recognized text
                let recognizedStrings = observations.compactMap { observation in
                    observation.topCandidates(1).first?.string
                }

                let fullText = recognizedStrings.joined(separator: "\n")
                continuation.resume(returning: fullText)
            }

            // Configure for accuracy
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            request.recognitionLanguages = ["en-US"]

            // Perform request
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: VisionOCRError.processingFailed(error.localizedDescription))
            }
        }
    }

    // MARK: - Broker Detection

    private func detectBroker(from text: String) -> DetectedBroker? {
        let lowerText = text.lowercased()

        // Check for broker-specific patterns
        if lowerText.contains("robinhood") || lowerText.contains("buying power") && lowerText.contains("investing") {
            return .robinhood
        }

        if lowerText.contains("fidelity") || lowerText.contains("fidelity investments") {
            return .fidelity
        }

        if lowerText.contains("schwab") || lowerText.contains("charles schwab") {
            return .schwab
        }

        if lowerText.contains("e*trade") || lowerText.contains("etrade") {
            return .etrade
        }

        if lowerText.contains("td ameritrade") || lowerText.contains("tdameritrade") || lowerText.contains("thinkorswim") {
            return .tdAmeritrade
        }

        if lowerText.contains("webull") {
            return .webull
        }

        if lowerText.contains("coinbase") {
            return .coinbase
        }

        return nil
    }

    // MARK: - Holdings Parsing

    private func parseHoldings(from text: String, broker: DetectedBroker?) -> ([OCRExtractedHolding], [String]) {
        var holdings: [OCRExtractedHolding] = []
        var warnings: [String] = []

        let lines = text.components(separatedBy: .newlines)

        // Stock symbol pattern: 1-5 uppercase letters, optionally followed by .X (e.g., BRK.B)
        let symbolPattern = "^[A-Z]{1,5}(\\.[A-Z])?$"
        let symbolRegex = try? NSRegularExpression(pattern: symbolPattern, options: [])

        // Number pattern for quantities/prices
        let numberPattern = "[\\$]?[0-9,]+\\.?[0-9]*"
        let numberRegex = try? NSRegularExpression(pattern: numberPattern, options: [])

        var foundSymbols: Set<String> = []

        for (index, line) in lines.enumerated() {
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)

            // Look for potential stock symbols
            let words = trimmedLine.components(separatedBy: .whitespaces)

            for word in words {
                let cleanedWord = word.uppercased().trimmingCharacters(in: CharacterSet.alphanumerics.inverted)

                // Check if it matches stock symbol pattern
                let range = NSRange(cleanedWord.startIndex..., in: cleanedWord)
                if let symbolRegex = symbolRegex,
                   symbolRegex.firstMatch(in: cleanedWord, options: [], range: range) != nil,
                   cleanedWord.count >= 1,
                   cleanedWord.count <= 5,
                   !isCommonWord(cleanedWord),
                   !foundSymbols.contains(cleanedWord) {

                    foundSymbols.insert(cleanedWord)

                    // Extract numbers from nearby context (current line and next line)
                    var contextText = trimmedLine
                    if index + 1 < lines.count {
                        contextText += " " + lines[index + 1]
                    }

                    let (quantity, price, value) = extractNumbers(from: contextText, using: numberRegex)

                    // Calculate confidence
                    var confidence = 0.0
                    let isKnownSymbol = MockStockData.knownStocks.contains { $0.symbol == cleanedWord }
                    if isKnownSymbol { confidence += 0.5 }
                    if quantity != nil { confidence += 0.25 }
                    if price != nil { confidence += 0.25 }

                    // Only include if we have some confidence
                    if confidence > 0 || isKnownSymbol {
                        holdings.append(OCRExtractedHolding(
                            symbol: cleanedWord,
                            quantity: quantity,
                            price: price,
                            totalValue: value,
                            confidence: confidence
                        ))
                    }
                }
            }
        }

        // Add warnings
        if holdings.isEmpty {
            warnings.append("No stock symbols detected. Try a clearer screenshot.")
        } else {
            let unrecognizedCount = holdings.filter { !$0.isRecognized }.count
            if unrecognizedCount > 0 {
                warnings.append("\(unrecognizedCount) symbol(s) not in database - verify manually")
            }

            let lowConfidenceCount = holdings.filter { $0.confidence < 0.5 }.count
            if lowConfidenceCount > 0 {
                warnings.append("\(lowConfidenceCount) holding(s) with low confidence - review carefully")
            }
        }

        if broker == nil {
            warnings.append("Could not identify broker app - data may need manual review")
        }

        return (holdings, warnings)
    }

    // MARK: - Number Extraction

    private func extractNumbers(from text: String, using regex: NSRegularExpression?) -> (quantity: Double?, price: Double?, value: Double?) {
        guard let regex = regex else { return (nil, nil, nil) }

        let range = NSRange(text.startIndex..., in: text)
        let matches = regex.matches(in: text, options: [], range: range)

        var numbers: [Double] = []

        for match in matches {
            if let matchRange = Range(match.range, in: text) {
                let matchedString = String(text[matchRange])
                let cleaned = matchedString
                    .replacingOccurrences(of: "$", with: "")
                    .replacingOccurrences(of: ",", with: "")

                if let number = Double(cleaned), number > 0 {
                    numbers.append(number)
                }
            }
        }

        // Heuristic: smaller numbers are likely quantities, larger ones are prices/values
        numbers.sort()

        var quantity: Double?
        var price: Double?
        var value: Double?

        if numbers.count >= 1 {
            // First number could be quantity if small, or price if moderate
            if numbers[0] < 10000 {
                quantity = numbers[0]
            }
        }

        if numbers.count >= 2 {
            // Second number is likely price or value
            if numbers[1] < 10000 {
                price = numbers[1]
            } else {
                value = numbers[1]
            }
        }

        if numbers.count >= 3 {
            // Third number is likely total value
            value = numbers[2]
        }

        return (quantity, price, value)
    }

    // MARK: - Helpers

    private func isCommonWord(_ word: String) -> Bool {
        let commonWords: Set<String> = [
            "THE", "AND", "FOR", "ARE", "BUT", "NOT", "YOU", "ALL",
            "CAN", "HER", "WAS", "ONE", "OUR", "OUT", "DAY", "GET",
            "HAS", "HIM", "HIS", "HOW", "ITS", "MAY", "NEW", "NOW",
            "OLD", "SEE", "WAY", "WHO", "BOY", "DID", "OWN", "SAY",
            "SHE", "TOO", "USE", "BUY", "SELL", "USD", "ETF", "IPO",
            "AVG", "QTY", "VOL", "MKT", "BID", "ASK", "COST", "GAIN",
            "LOSS", "TOTAL", "VALUE", "SHARE", "PRICE", "TODAY"
        ]
        return commonWords.contains(word)
    }

    // MARK: - Conversion to ImportedHolding

    /// Convert OCR holdings to ImportedHolding format for import
    func convertToImportedHoldings(_ ocrHoldings: [OCRExtractedHolding]) -> [ImportedHolding] {
        return ocrHoldings.compactMap { ocr in
            // Only convert if we have at least a quantity
            guard let quantity = ocr.quantity, quantity > 0 else {
                // If no quantity but recognized, assume 1 share for review
                if ocr.isRecognized {
                    return ImportedHolding(
                        symbol: ocr.symbol,
                        quantity: 1,
                        averageCost: ocr.price,
                        currentPrice: ocr.price,
                        totalValue: ocr.totalValue
                    )
                }
                return nil
            }

            return ImportedHolding(
                symbol: ocr.symbol,
                quantity: quantity,
                averageCost: ocr.price,
                currentPrice: ocr.price,
                totalValue: ocr.totalValue
            )
        }
    }
}
