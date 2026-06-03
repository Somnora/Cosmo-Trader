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
    let costBasisPerShare: Double?
    let confidence: Double
    let rawSource: String

    init(
        symbol: String,
        shares: Double,
        marketValue: Double?,
        costBasisPerShare: Double? = nil,
        confidence: Double,
        rawSource: String
    ) {
        self.symbol = symbol
        self.shares = shares
        self.marketValue = marketValue
        self.costBasisPerShare = costBasisPerShare
        self.confidence = confidence
        self.rawSource = rawSource
    }
}

struct ParsedPortfolio: Equatable {
    let broker: String
    let holdings: [ParsedHolding]
    let unparsedLines: [String]
    let overallConfidence: Double
}
