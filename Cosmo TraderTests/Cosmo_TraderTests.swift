//
//  Cosmo_TraderTests.swift
//  Cosmo TraderTests
//
//  Created by James McShane on 12/9/25.
//
//  Main test file - see individual test files for comprehensive coverage:
//  - ZodiacSignTests.swift: Zodiac date calculations, elements, compatibility
//  - StockTests.swift: Stock model, zodiac signs, value calculations
//  - UserProfileTests.swift: Profile management, portfolio, watchlist
//  - InputValidatorTests.swift: Input validation for names, dates, amounts
//  - CompatibilityTests.swift: Compatibility scoring algorithm
//

import Testing
@testable import Cosmo_Trader

struct Cosmo_TraderTests {

    // MARK: - Basic Sanity Tests

    @Test("App has 12 zodiac signs")
    func appHasTwelveZodiacSigns() {
        #expect(ZodiacSign.allCases.count == 12)
    }

    @Test("App has 4 elements")
    func appHasFourElements() {
        #expect(ZodiacSign.Element.allCases.count == 4)
    }

    @Test("Sample stocks exist")
    func sampleStocksExist() {
        #expect(!Stock.samples.isEmpty)
    }

    @Test("Sample user profile exists")
    func sampleUserProfileExists() {
        let sample = UserProfile.sample
        #expect(!sample.displayName.isEmpty)
    }

    @Test("Compatibility ratings have 5 levels")
    func compatibilityRatingsHaveFiveLevels() {
        #expect(CompatibilityRating.allCases.count == 5)
    }
}
