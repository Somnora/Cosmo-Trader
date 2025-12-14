//
//  CompatibilityTests.swift
//  Cosmo TraderTests
//
//  Comprehensive tests for the compatibility scoring system including
//  element bonuses, trine/sextile/opposition relationships.
//

import Testing
import Foundation
@testable import Cosmo_Trader

// MARK: - Compatibility Score Tests

struct CompatibilityScoreTests {

    @Test("Same sign gives high score")
    func sameSignHighScore() {
        let result = CompatibilityCalculator.calculate(userSign: .leo, stockSign: .leo)
        #expect(result.score >= 75)
    }

    @Test("Compatible fire signs give high score")
    func compatibleFireSignsHighScore() {
        let result = CompatibilityCalculator.calculate(userSign: .aries, stockSign: .leo)
        #expect(result.score >= 65)
    }

    @Test("Same element gives bonus")
    func sameElementGivesBonus() {
        // Both fire signs
        let fireResult = CompatibilityCalculator.calculate(userSign: .aries, stockSign: .sagittarius)
        // Different elements (fire vs water)
        let mixedResult = CompatibilityCalculator.calculate(userSign: .aries, stockSign: .cancer)

        #expect(fireResult.score > mixedResult.score)
    }

    @Test("Score is clamped between 0 and 100")
    func scoreClampedRange() {
        for userSign in ZodiacSign.allCases {
            for stockSign in ZodiacSign.allCases {
                let result = CompatibilityCalculator.calculate(userSign: userSign, stockSign: stockSign)
                #expect(result.score >= 0)
                #expect(result.score <= 100)
            }
        }
    }

    @Test("All same-element pairs have above-average scores")
    func sameElementAboveAverage() {
        let elementPairs: [(ZodiacSign, ZodiacSign)] = [
            // Fire
            (.aries, .leo), (.aries, .sagittarius), (.leo, .sagittarius),
            // Earth
            (.taurus, .virgo), (.taurus, .capricorn), (.virgo, .capricorn),
            // Air
            (.gemini, .libra), (.gemini, .aquarius), (.libra, .aquarius),
            // Water
            (.cancer, .scorpio), (.cancer, .pisces), (.scorpio, .pisces)
        ]

        for (sign1, sign2) in elementPairs {
            let result = CompatibilityCalculator.calculate(userSign: sign1, stockSign: sign2)
            #expect(result.score >= 50, "Expected \(sign1) and \(sign2) to have score >= 50, got \(result.score)")
        }
    }
}

// MARK: - Compatibility Rating Tests

struct CompatibilityRatingTests {

    @Test("Cosmic soulmates rating for score 85-100")
    func cosmicSoulmatesRating() {
        #expect(CompatibilityRating.from(score: 85) == .cosmicSoulmates)
        #expect(CompatibilityRating.from(score: 100) == .cosmicSoulmates)
        #expect(CompatibilityRating.from(score: 92) == .cosmicSoulmates)
    }

    @Test("High compatibility rating for score 65-84")
    func highCompatibilityRating() {
        #expect(CompatibilityRating.from(score: 65) == .highCompatibility)
        #expect(CompatibilityRating.from(score: 84) == .highCompatibility)
        #expect(CompatibilityRating.from(score: 75) == .highCompatibility)
    }

    @Test("Neutral rating for score 40-64")
    func neutralRating() {
        #expect(CompatibilityRating.from(score: 40) == .neutral)
        #expect(CompatibilityRating.from(score: 64) == .neutral)
        #expect(CompatibilityRating.from(score: 50) == .neutral)
    }

    @Test("Challenging rating for score 20-39")
    func challengingRating() {
        #expect(CompatibilityRating.from(score: 20) == .challenging)
        #expect(CompatibilityRating.from(score: 39) == .challenging)
        #expect(CompatibilityRating.from(score: 30) == .challenging)
    }

    @Test("Cosmic clash rating for score 0-19")
    func cosmicClashRating() {
        #expect(CompatibilityRating.from(score: 0) == .cosmicClash)
        #expect(CompatibilityRating.from(score: 19) == .cosmicClash)
        #expect(CompatibilityRating.from(score: 10) == .cosmicClash)
    }

    @Test("Each rating has display properties")
    func ratingsHaveDisplayProperties() {
        for rating in CompatibilityRating.allCases {
            #expect(!rating.displayName.isEmpty)
            #expect(!rating.tagline.isEmpty)
            #expect(!rating.emoji.isEmpty)
            #expect(!rating.colorName.isEmpty)
        }
    }
}

// MARK: - Trine Relationship Tests (Same Element)

struct TrineRelationshipTests {

    @Test("Fire trine - Aries, Leo, Sagittarius")
    func fireTrineHighCompatibility() {
        let ariesLeo = CompatibilityCalculator.calculate(userSign: .aries, stockSign: .leo)
        let ariesSag = CompatibilityCalculator.calculate(userSign: .aries, stockSign: .sagittarius)
        let leoSag = CompatibilityCalculator.calculate(userSign: .leo, stockSign: .sagittarius)

        #expect(ariesLeo.score >= 60)
        #expect(ariesSag.score >= 60)
        #expect(leoSag.score >= 60)
    }

    @Test("Earth trine - Taurus, Virgo, Capricorn")
    func earthTrineHighCompatibility() {
        let taurusVirgo = CompatibilityCalculator.calculate(userSign: .taurus, stockSign: .virgo)
        let taurusCap = CompatibilityCalculator.calculate(userSign: .taurus, stockSign: .capricorn)
        let virgoCap = CompatibilityCalculator.calculate(userSign: .virgo, stockSign: .capricorn)

        #expect(taurusVirgo.score >= 60)
        #expect(taurusCap.score >= 60)
        #expect(virgoCap.score >= 60)
    }

    @Test("Air trine - Gemini, Libra, Aquarius")
    func airTrineHighCompatibility() {
        let geminiLibra = CompatibilityCalculator.calculate(userSign: .gemini, stockSign: .libra)
        let geminiAquarius = CompatibilityCalculator.calculate(userSign: .gemini, stockSign: .aquarius)
        let libraAquarius = CompatibilityCalculator.calculate(userSign: .libra, stockSign: .aquarius)

        #expect(geminiLibra.score >= 60)
        #expect(geminiAquarius.score >= 60)
        #expect(libraAquarius.score >= 60)
    }

    @Test("Water trine - Cancer, Scorpio, Pisces")
    func waterTrineHighCompatibility() {
        let cancerScorpio = CompatibilityCalculator.calculate(userSign: .cancer, stockSign: .scorpio)
        let cancerPisces = CompatibilityCalculator.calculate(userSign: .cancer, stockSign: .pisces)
        let scorpioPisces = CompatibilityCalculator.calculate(userSign: .scorpio, stockSign: .pisces)

        #expect(cancerScorpio.score >= 60)
        #expect(cancerPisces.score >= 60)
        #expect(scorpioPisces.score >= 60)
    }
}

// MARK: - Sextile Relationship Tests (Complementary Elements)

struct SextileRelationshipTests {

    @Test("Fire-Air sextile gives bonus")
    func fireAirSextileBonus() {
        // Fire and Air are complementary
        let ariesGemini = CompatibilityCalculator.calculate(userSign: .aries, stockSign: .gemini)
        let leoLibra = CompatibilityCalculator.calculate(userSign: .leo, stockSign: .libra)

        #expect(ariesGemini.score >= 50)
        #expect(leoLibra.score >= 50)
    }

    @Test("Earth-Water sextile gives bonus")
    func earthWaterSextileBonus() {
        // Earth and Water are complementary
        let taurusCancer = CompatibilityCalculator.calculate(userSign: .taurus, stockSign: .cancer)
        let virgoScorpio = CompatibilityCalculator.calculate(userSign: .virgo, stockSign: .scorpio)

        #expect(taurusCancer.score >= 50)
        #expect(virgoScorpio.score >= 50)
    }
}

// MARK: - Opposition Relationship Tests

struct OppositionRelationshipTests {

    @Test("Opposite signs have tension but still score")
    func oppositeSignsTension() {
        let ariesLibra = CompatibilityCalculator.calculate(userSign: .aries, stockSign: .libra)
        let taurusScorpio = CompatibilityCalculator.calculate(userSign: .taurus, stockSign: .scorpio)
        let leoAquarius = CompatibilityCalculator.calculate(userSign: .leo, stockSign: .aquarius)

        // Opposites should have some score but with tension penalty
        #expect(ariesLibra.score > 0)
        #expect(taurusScorpio.score > 0)
        #expect(leoAquarius.score > 0)
    }

    @Test("All six oppositions are represented")
    func allOppositionsRepresented() {
        let oppositions: [(ZodiacSign, ZodiacSign)] = [
            (.aries, .libra),
            (.taurus, .scorpio),
            (.gemini, .sagittarius),
            (.cancer, .capricorn),
            (.leo, .aquarius),
            (.virgo, .pisces)
        ]

        for (sign1, sign2) in oppositions {
            #expect(sign1.oppositeSign == sign2)
            #expect(sign2.oppositeSign == sign1)
        }
    }
}

// MARK: - Square Relationship Tests (Challenging)

struct SquareRelationshipTests {

    @Test("Square aspects (3 signs apart) have lower scores")
    func squareAspectsLowerScores() {
        // Aries squares Cancer and Capricorn
        let ariesCancer = CompatibilityCalculator.calculate(userSign: .aries, stockSign: .cancer)
        let ariesCapricorn = CompatibilityCalculator.calculate(userSign: .aries, stockSign: .capricorn)

        // Same element should score higher
        let ariesLeo = CompatibilityCalculator.calculate(userSign: .aries, stockSign: .leo)

        #expect(ariesLeo.score > ariesCancer.score)
        #expect(ariesLeo.score > ariesCapricorn.score)
    }
}

// MARK: - Challenging Element Tests

struct ChallengingElementTests {

    @Test("Fire-Water elements are challenging")
    func fireWaterChallenging() {
        let ariesCancer = CompatibilityCalculator.calculate(userSign: .aries, stockSign: .cancer)
        let leoScorpio = CompatibilityCalculator.calculate(userSign: .leo, stockSign: .scorpio)

        // Should be lower than same-element
        let ariesLeo = CompatibilityCalculator.calculate(userSign: .aries, stockSign: .leo)

        #expect(ariesLeo.score > ariesCancer.score)
        #expect(ariesLeo.score > leoScorpio.score)
    }

    @Test("Earth-Air elements are challenging")
    func earthAirChallenging() {
        let taurusGemini = CompatibilityCalculator.calculate(userSign: .taurus, stockSign: .gemini)
        let virgoAquarius = CompatibilityCalculator.calculate(userSign: .virgo, stockSign: .aquarius)

        // Should be lower than same-element
        let taurusVirgo = CompatibilityCalculator.calculate(userSign: .taurus, stockSign: .virgo)

        #expect(taurusVirgo.score > taurusGemini.score)
        #expect(taurusVirgo.score > virgoAquarius.score)
    }
}

// MARK: - Compatibility Result Tests

struct CompatibilityResultTests {

    @Test("Result contains all required fields")
    func resultHasAllFields() {
        let result = CompatibilityCalculator.calculate(userSign: .leo, stockSign: .aries)

        #expect(result.userSign == .leo)
        #expect(result.stockSign == .aries)
        #expect(!result.description.isEmpty)
        #expect(!result.advice.isEmpty)
        #expect(!result.elementDynamic.isEmpty)
    }

    @Test("Formatted score includes percent")
    func formattedScoreIncludesPercent() {
        let result = CompatibilityCalculator.calculate(userSign: .leo, stockSign: .aries)
        #expect(result.formattedScore.contains("%"))
    }

    @Test("isPositive reflects score >= 50")
    func isPositiveReflectsScore() {
        // Same sign should be positive
        let highResult = CompatibilityCalculator.calculate(userSign: .leo, stockSign: .leo)
        #expect(highResult.isPositive == true)
    }

    @Test("Rating matches score range")
    func ratingMatchesScoreRange() {
        for userSign in ZodiacSign.allCases {
            for stockSign in ZodiacSign.allCases {
                let result = CompatibilityCalculator.calculate(userSign: userSign, stockSign: stockSign)
                let expectedRating = CompatibilityRating.from(score: result.score)
                #expect(result.rating == expectedRating)
            }
        }
    }
}

// MARK: - User Profile Compatibility Extension Tests

struct UserProfileCompatibilityExtensionTests {

    @Test("User compatibility with stock")
    func userCompatibilityWithStock() {
        let user = UserProfile.sample // Leo
        let stock = Stock.sample // Apple = Aries

        let result = user.compatibility(with: stock)

        #expect(result.userSign == .leo)
        #expect(result.stockSign == .aries)
    }

    @Test("Portfolio compatibility sorted by score")
    func portfolioCompatibilitySorted() {
        let user = UserProfile.sample

        let results = user.portfolioCompatibility

        for i in 0..<(results.count - 1) {
            #expect(results[i].score >= results[i + 1].score)
        }
    }

    @Test("Average portfolio compatibility calculated")
    func averagePortfolioCompatibility() {
        let user = UserProfile.sample

        let average = user.averagePortfolioCompatibility

        #expect(average >= 0)
        #expect(average <= 100)
    }

    @Test("Empty portfolio has zero average compatibility")
    func emptyPortfolioZeroCompatibility() {
        let user = UserProfile.newUser

        #expect(user.averagePortfolioCompatibility == 0)
    }
}

// MARK: - Stock Compatibility Extension Tests

struct StockCompatibilityExtensionTests {

    @Test("Stock compatibility with zodiac sign")
    func stockCompatibilityWithSign() {
        let stock = Stock.sample // Apple = Aries

        let result = stock.compatibility(with: .leo)

        #expect(result.stockSign == .aries)
        #expect(result.userSign == .leo)
    }
}

// MARK: - ZodiacSign Compatibility Extension Tests

struct ZodiacSignCompatibilityExtensionTests {

    @Test("ZodiacSign compatibility method")
    func zodiacSignCompatibilityMethod() {
        let result = ZodiacSign.leo.compatibility(with: .aquarius)

        #expect(result.userSign == .leo)
        #expect(result.stockSign == .aquarius)
    }
}

// MARK: - All Combinations Test

struct AllCombinationsTests {

    @Test("All 144 sign combinations produce valid results")
    func allCombinationsValid() {
        for userSign in ZodiacSign.allCases {
            for stockSign in ZodiacSign.allCases {
                let result = CompatibilityCalculator.calculate(userSign: userSign, stockSign: stockSign)

                #expect(result.score >= 0)
                #expect(result.score <= 100)
                #expect(!result.description.isEmpty)
                #expect(!result.advice.isEmpty)
            }
        }
    }
}
