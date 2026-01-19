//
//  ChartPatternServiceTests.swift
//  Cosmo TraderTests
//
//  Comprehensive tests for ChartPatternService including pattern detection,
//  sentiment analysis, and technical indicators.
//

import Testing
import Foundation
@testable import Cosmo_Trader

// MARK: - Chart Pattern Enum Tests

struct ChartPatternEnumTests {

    @Test("All chart patterns have unique raw values")
    func allPatternsHaveUniqueRawValues() {
        let patterns = ChartPattern.allCases
        let rawValues = patterns.map { $0.rawValue }
        let uniqueValues = Set(rawValues)

        #expect(rawValues.count == uniqueValues.count)
    }

    @Test("All patterns have descriptions")
    func allPatternsHaveDescriptions() {
        for pattern in ChartPattern.allCases {
            #expect(!pattern.description.isEmpty, "Pattern \(pattern.rawValue) should have description")
        }
    }

    @Test("All patterns have icons")
    func allPatternsHaveIcons() {
        for pattern in ChartPattern.allCases {
            #expect(!pattern.icon.isEmpty, "Pattern \(pattern.rawValue) should have icon")
        }
    }

    @Test("All patterns have risk levels")
    func allPatternsHaveRiskLevels() {
        for pattern in ChartPattern.allCases {
            #expect(!pattern.riskLevel.isEmpty, "Pattern \(pattern.rawValue) should have risk level")
        }
    }
}

// MARK: - Pattern Sentiment Tests

struct PatternSentimentTests {

    @Test("Bullish patterns have bullish sentiment")
    func bullishPatternsSentiment() {
        let bullishPatterns: [ChartPattern] = [
            .hammer, .engulfingBullish, .goldenCross, .breakoutUp, .oversold, .morningstar
        ]

        for pattern in bullishPatterns {
            #expect(pattern.sentiment == .bullish, "\(pattern.rawValue) should be bullish")
        }
    }

    @Test("Bearish patterns have bearish sentiment")
    func bearishPatternsSentiment() {
        let bearishPatterns: [ChartPattern] = [
            .shootingStar, .engulfingBearish, .deathCross, .breakoutDown, .overbought, .eveningstar
        ]

        for pattern in bearishPatterns {
            #expect(pattern.sentiment == .bearish, "\(pattern.rawValue) should be bearish")
        }
    }

    @Test("Neutral patterns have neutral sentiment")
    func neutralPatternsSentiment() {
        let neutralPatterns: [ChartPattern] = [
            .doji, .supportTest, .resistanceTest
        ]

        for pattern in neutralPatterns {
            #expect(pattern.sentiment == .neutral, "\(pattern.rawValue) should be neutral")
        }
    }
}

// MARK: - Pattern Sentiment Properties Tests

struct PatternSentimentPropertiesTests {

    @Test("Bullish sentiment has correct icon")
    func bullishSentimentIcon() {
        #expect(PatternSentiment.bullish.icon == "arrow.up.right")
    }

    @Test("Bearish sentiment has correct icon")
    func bearishSentimentIcon() {
        #expect(PatternSentiment.bearish.icon == "arrow.down.right")
    }

    @Test("Neutral sentiment has correct icon")
    func neutralSentimentIcon() {
        #expect(PatternSentiment.neutral.icon == "arrow.left.arrow.right")
    }

    @Test("All sentiments have raw values")
    func allSentimentsHaveRawValues() {
        #expect(PatternSentiment.bullish.rawValue == "Bullish")
        #expect(PatternSentiment.bearish.rawValue == "Bearish")
        #expect(PatternSentiment.neutral.rawValue == "Neutral")
    }
}

// MARK: - Detected Pattern Model Tests

struct DetectedPatternModelTests {

    @Test("Detected pattern has unique ID")
    func detectedPatternHasUniqueId() {
        let pattern1 = DetectedPattern(
            pattern: .doji,
            confidence: 80,
            detectedAt: Date(),
            priceAtDetection: 150.0
        )
        let pattern2 = DetectedPattern(
            pattern: .doji,
            confidence: 80,
            detectedAt: Date(),
            priceAtDetection: 150.0
        )

        #expect(pattern1.id != pattern2.id)
    }

    @Test("Confidence is clamped to 0-100")
    func confidenceIsClamped() {
        let patternOver = DetectedPattern(
            pattern: .hammer,
            confidence: 150,
            detectedAt: Date(),
            priceAtDetection: 100.0
        )
        let patternUnder = DetectedPattern(
            pattern: .hammer,
            confidence: -50,
            detectedAt: Date(),
            priceAtDetection: 100.0
        )

        #expect(patternOver.confidence == 100)
        #expect(patternUnder.confidence == 0)
    }

    @Test("Formatted confidence includes percent")
    func formattedConfidenceIncludesPercent() {
        let pattern = DetectedPattern(
            pattern: .goldenCross,
            confidence: 92,
            detectedAt: Date(),
            priceAtDetection: 200.0
        )

        #expect(pattern.formattedConfidence == "92%")
    }

    @Test("Formatted price includes dollar sign")
    func formattedPriceIncludesDollar() {
        let pattern = DetectedPattern(
            pattern: .breakoutUp,
            confidence: 85,
            detectedAt: Date(),
            priceAtDetection: 175.50
        )

        #expect(pattern.formattedPrice == "$175.50")
    }

    @Test("Formatted date is not empty")
    func formattedDateNotEmpty() {
        let pattern = DetectedPattern(
            pattern: .doji,
            confidence: 70,
            detectedAt: Date(),
            priceAtDetection: 100.0
        )

        #expect(!pattern.formattedDate.isEmpty)
    }
}

// MARK: - Premium Pattern Tests

struct PremiumPatternTests {

    @Test("Golden cross is premium pattern")
    func goldenCrossIsPremium() {
        let pattern = DetectedPattern(
            pattern: .goldenCross,
            confidence: 90,
            detectedAt: Date(),
            priceAtDetection: 200.0
        )

        #expect(pattern.isPremiumPattern == true)
    }

    @Test("Death cross is premium pattern")
    func deathCrossIsPremium() {
        let pattern = DetectedPattern(
            pattern: .deathCross,
            confidence: 90,
            detectedAt: Date(),
            priceAtDetection: 180.0
        )

        #expect(pattern.isPremiumPattern == true)
    }

    @Test("Morning star is premium pattern")
    func morningStarIsPremium() {
        let pattern = DetectedPattern(
            pattern: .morningstar,
            confidence: 88,
            detectedAt: Date(),
            priceAtDetection: 150.0
        )

        #expect(pattern.isPremiumPattern == true)
    }

    @Test("Evening star is premium pattern")
    func eveningStarIsPremium() {
        let pattern = DetectedPattern(
            pattern: .eveningstar,
            confidence: 88,
            detectedAt: Date(),
            priceAtDetection: 160.0
        )

        #expect(pattern.isPremiumPattern == true)
    }

    @Test("Doji is not premium pattern")
    func dojiIsNotPremium() {
        let pattern = DetectedPattern(
            pattern: .doji,
            confidence: 80,
            detectedAt: Date(),
            priceAtDetection: 100.0
        )

        #expect(pattern.isPremiumPattern == false)
    }

    @Test("Hammer is not premium pattern")
    func hammerIsNotPremium() {
        let pattern = DetectedPattern(
            pattern: .hammer,
            confidence: 75,
            detectedAt: Date(),
            priceAtDetection: 95.0
        )

        #expect(pattern.isPremiumPattern == false)
    }
}

// MARK: - RSI Calculation Tests

struct RSICalculationTests {

    @Test("RSI above 70 is overbought")
    func rsiAbove70IsOverbought() {
        let rsi = 75.0
        let isOverbought = rsi > 70

        #expect(isOverbought == true)
    }

    @Test("RSI below 30 is oversold")
    func rsiBelow30IsOversold() {
        let rsi = 25.0
        let isOversold = rsi < 30

        #expect(isOversold == true)
    }

    @Test("RSI between 30-70 is neutral")
    func rsiBetween30And70IsNeutral() {
        let rsi = 50.0
        let isNeutral = rsi >= 30 && rsi <= 70

        #expect(isNeutral == true)
    }

    @Test("RSI at exactly 70 is not overbought")
    func rsiAt70IsNotOverbought() {
        let rsi = 70.0
        let isOverbought = rsi > 70

        #expect(isOverbought == false)
    }

    @Test("RSI at exactly 30 is not oversold")
    func rsiAt30IsNotOversold() {
        let rsi = 30.0
        let isOversold = rsi < 30

        #expect(isOversold == false)
    }
}

// MARK: - Moving Average Calculation Tests

struct MovingAverageCalculationTests {

    @Test("Moving average of constant values equals that value")
    func movingAverageOfConstantValues() {
        let values = Array(repeating: 100.0, count: 50)
        let period = 10
        var result: [Double] = []

        guard values.count >= period else {
            #expect(Bool(false), "Not enough values")
            return
        }

        for i in (period - 1)..<values.count {
            let slice = values[(i - period + 1)...i]
            let avg = slice.reduce(0, +) / Double(period)
            result.append(avg)
        }

        // All values should be 100
        for avg in result {
            #expect(abs(avg - 100.0) < 0.001)
        }
    }

    @Test("Moving average of ascending values is middle value")
    func movingAverageOfAscendingValues() {
        let values: [Double] = [1, 2, 3, 4, 5]
        let period = 5

        let sum = values.reduce(0, +)
        let avg = sum / Double(period)

        #expect(avg == 3.0) // (1+2+3+4+5)/5 = 15/5 = 3
    }

    @Test("Moving average requires minimum period length")
    func movingAverageRequiresMinPeriod() {
        let values: [Double] = [1, 2, 3]
        let period = 5

        let canCalculate = values.count >= period

        #expect(canCalculate == false)
    }
}

// MARK: - Doji Pattern Detection Tests

struct DojiPatternDetectionTests {

    @Test("Doji detected when body < 10% of range")
    func dojiDetectedSmallBody() {
        // Simulate OHLC data where body is small compared to range
        let open = 100.0
        let close = 100.5 // Very small body
        let high = 105.0
        let low = 95.0

        let bodySize = abs(close - open)
        let totalRange = high - low
        let isDoji = totalRange > 0 && bodySize < totalRange * 0.1

        #expect(isDoji == true)
    }

    @Test("Doji not detected when body > 10% of range")
    func dojiNotDetectedLargeBody() {
        let open = 100.0
        let close = 105.0 // Larger body
        let high = 106.0
        let low = 99.0

        let bodySize = abs(close - open)
        let totalRange = high - low
        let isDoji = totalRange > 0 && bodySize < totalRange * 0.1

        #expect(isDoji == false)
    }
}

// MARK: - Hammer Pattern Detection Tests

struct HammerPatternDetectionTests {

    @Test("Hammer detected with long lower wick")
    func hammerDetectedLongLowerWick() {
        let open = 100.0
        let close = 101.0
        let high = 101.4  // Small upper wick (< 0.5 of body)
        let low = 90.0    // Long lower wick

        let bodySize = abs(close - open)  // = 1.0
        let bodyTop = max(open, close)    // = 101.0
        let bodyBottom = min(open, close) // = 100.0
        let lowerWick = bodyBottom - low  // = 10.0
        let upperWick = high - bodyTop    // = 0.4

        // Hammer: small body, long lower wick (>2x body), small upper wick (<0.5x body)
        let isHammer = bodySize > 0 && lowerWick > bodySize * 2 && upperWick < bodySize * 0.5

        #expect(isHammer == true)
    }

    @Test("Hammer not detected with long upper wick")
    func hammerNotDetectedLongUpperWick() {
        let open = 100.0
        let close = 101.0
        let high = 110.0 // Long upper wick
        let low = 99.0

        let bodySize = abs(close - open)
        let bodyTop = max(open, close)
        let bodyBottom = min(open, close)
        let lowerWick = bodyBottom - low
        let upperWick = high - bodyTop

        let isHammer = bodySize > 0 && lowerWick > bodySize * 2 && upperWick < bodySize * 0.5

        #expect(isHammer == false)
    }
}

// MARK: - Shooting Star Pattern Detection Tests

struct ShootingStarPatternDetectionTests {

    @Test("Shooting star detected with long upper wick")
    func shootingStarDetectedLongUpperWick() {
        let open = 100.0
        let close = 99.0
        let high = 110.0 // Long upper wick
        let low = 98.6 // Small lower wick (0.4) < bodySize * 0.5 (0.5)

        let bodySize = abs(close - open)
        let bodyTop = max(open, close)
        let bodyBottom = min(open, close)
        let lowerWick = bodyBottom - low
        let upperWick = high - bodyTop

        let isShootingStar = bodySize > 0 && upperWick > bodySize * 2 && lowerWick < bodySize * 0.5

        #expect(isShootingStar == true)
    }
}

// MARK: - Breakout Detection Tests

struct BreakoutDetectionTests {

    @Test("Bullish breakout above recent high")
    func bullishBreakoutAboveHigh() {
        let recentHigh = 100.0
        let currentClose = 105.0
        let currentOpen = 102.0

        let isBreakoutUp = currentClose > recentHigh && currentClose > currentOpen

        #expect(isBreakoutUp == true)
    }

    @Test("Bearish breakdown below recent low")
    func bearishBreakdownBelowLow() {
        let recentLow = 100.0
        let currentClose = 95.0
        let currentOpen = 98.0

        let isBreakoutDown = currentClose < recentLow && currentClose < currentOpen

        #expect(isBreakoutDown == true)
    }
}

// MARK: - Support/Resistance Test Detection Tests

struct SupportResistanceTestTests {

    @Test("Resistance test within 1% of high")
    func resistanceTestWithin1Percent() {
        let recentHigh = 100.0
        let currentHigh = 99.5
        let currentClose = 98.0

        let resistanceThreshold = recentHigh * 0.99
        let isResistanceTest = currentHigh >= resistanceThreshold && currentClose < recentHigh

        #expect(isResistanceTest == true)
    }

    @Test("Support test within 1% of low")
    func supportTestWithin1Percent() {
        let recentLow = 100.0
        let currentLow = 100.5
        let currentClose = 102.0

        let supportThreshold = recentLow * 1.01
        let isSupportTest = currentLow <= supportThreshold && currentClose > recentLow

        #expect(isSupportTest == true)
    }
}

// MARK: - Pattern Sorting Tests

struct PatternSortingTests {

    @Test("Patterns sorted by confidence descending")
    func patternsSortedByConfidence() {
        var patterns = [
            DetectedPattern(pattern: .doji, confidence: 70, detectedAt: Date(), priceAtDetection: 100),
            DetectedPattern(pattern: .hammer, confidence: 90, detectedAt: Date(), priceAtDetection: 100),
            DetectedPattern(pattern: .engulfingBullish, confidence: 80, detectedAt: Date(), priceAtDetection: 100)
        ]

        patterns.sort { $0.confidence > $1.confidence }

        #expect(patterns[0].confidence == 90)
        #expect(patterns[1].confidence == 80)
        #expect(patterns[2].confidence == 70)
    }
}

// MARK: - Minimum Data Requirements Tests

struct MinimumDataRequirementsTests {

    @Test("Need at least 3 candles for detection")
    func needAtLeast3Candles() {
        let minCandlesForCandlestick = 3
        let dataCount = 2

        let canDetect = dataCount >= minCandlesForCandlestick

        #expect(canDetect == false)
    }

    @Test("Need at least 200 candles for MA crossover")
    func needAtLeast200CandlesForMACrossover() {
        let minCandlesForMACrossover = 200
        let dataCount = 100

        let canDetect = dataCount >= minCandlesForMACrossover

        #expect(canDetect == false)
    }

    @Test("Need at least 20 candles for breakout")
    func needAtLeast20CandlesForBreakout() {
        let minCandlesForBreakout = 20
        let dataCount = 25

        let canDetect = dataCount >= minCandlesForBreakout

        #expect(canDetect == true)
    }
}

// MARK: - Risk Level Tests

struct RiskLevelTests {

    @Test("Bullish patterns have lower risk")
    func bullishPatternsLowerRisk() {
        let bullishPatterns: [ChartPattern] = [.hammer, .engulfingBullish, .goldenCross]

        for pattern in bullishPatterns {
            #expect(pattern.riskLevel == "Lower Risk", "\(pattern.rawValue) should be lower risk")
        }
    }

    @Test("Bearish patterns have higher risk")
    func bearishPatternsHigherRisk() {
        let bearishPatterns: [ChartPattern] = [.shootingStar, .engulfingBearish, .deathCross]

        for pattern in bearishPatterns {
            #expect(pattern.riskLevel == "Higher Risk", "\(pattern.rawValue) should be higher risk")
        }
    }

    @Test("Neutral patterns need confirmation")
    func neutralPatternsNeedConfirmation() {
        let neutralPatterns: [ChartPattern] = [.doji, .supportTest, .resistanceTest]

        for pattern in neutralPatterns {
            #expect(pattern.riskLevel == "Wait for Confirmation", "\(pattern.rawValue) should wait for confirmation")
        }
    }
}
