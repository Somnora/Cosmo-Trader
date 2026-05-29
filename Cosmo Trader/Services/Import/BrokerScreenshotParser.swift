import Foundation

protocol BrokerScreenshotParser {
    var brokerName: String { get }

    /// Returns parser confidence for the OCR text. Values are clamped to 0...1.
    func canParse(_ rawText: [String]) -> Double

    func parse(_ rawText: [String]) throws -> ParsedPortfolio
}

struct ParsedHolding: Equatable {
    let symbol: String
    let shares: Double
    let marketValue: Double?
    let confidence: Double
    let rawSource: String
}

struct ParsedPortfolio: Equatable {
    let broker: String
    let holdings: [ParsedHolding]
    let unparsedLines: [String]
    let overallConfidence: Double
}
