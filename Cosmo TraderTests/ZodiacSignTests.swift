//
//  ZodiacSignTests.swift
//  Cosmo TraderTests
//
//  Comprehensive tests for ZodiacSign model including date calculations,
//  element properties, and compatibility checks.
//

import Testing
import Foundation
@testable import Cosmo_Trader

// MARK: - ZodiacSign Date Calculation Tests

struct ZodiacSignFromDateTests {

    // MARK: - Aries (Mar 21 - Apr 19)

    @Test("Aries start boundary - March 21")
    func ariesStartBoundary() {
        let sign = ZodiacSign.from(month: 3, day: 21)
        #expect(sign == .aries)
    }

    @Test("Aries end boundary - April 19")
    func ariesEndBoundary() {
        let sign = ZodiacSign.from(month: 4, day: 19)
        #expect(sign == .aries)
    }

    @Test("Aries middle date - April 1")
    func ariesMiddleDate() {
        let sign = ZodiacSign.from(month: 4, day: 1)
        #expect(sign == .aries)
    }

    // MARK: - Taurus (Apr 20 - May 20)

    @Test("Taurus start boundary - April 20")
    func taurusStartBoundary() {
        let sign = ZodiacSign.from(month: 4, day: 20)
        #expect(sign == .taurus)
    }

    @Test("Taurus end boundary - May 20")
    func taurusEndBoundary() {
        let sign = ZodiacSign.from(month: 5, day: 20)
        #expect(sign == .taurus)
    }

    // MARK: - Gemini (May 21 - Jun 20)

    @Test("Gemini start boundary - May 21")
    func geminiStartBoundary() {
        let sign = ZodiacSign.from(month: 5, day: 21)
        #expect(sign == .gemini)
    }

    @Test("Gemini end boundary - June 20")
    func geminiEndBoundary() {
        let sign = ZodiacSign.from(month: 6, day: 20)
        #expect(sign == .gemini)
    }

    // MARK: - Cancer (Jun 21 - Jul 22)

    @Test("Cancer start boundary - June 21")
    func cancerStartBoundary() {
        let sign = ZodiacSign.from(month: 6, day: 21)
        #expect(sign == .cancer)
    }

    @Test("Cancer end boundary - July 22")
    func cancerEndBoundary() {
        let sign = ZodiacSign.from(month: 7, day: 22)
        #expect(sign == .cancer)
    }

    // MARK: - Leo (Jul 23 - Aug 22)

    @Test("Leo start boundary - July 23")
    func leoStartBoundary() {
        let sign = ZodiacSign.from(month: 7, day: 23)
        #expect(sign == .leo)
    }

    @Test("Leo end boundary - August 22")
    func leoEndBoundary() {
        let sign = ZodiacSign.from(month: 8, day: 22)
        #expect(sign == .leo)
    }

    // MARK: - Virgo (Aug 23 - Sep 22)

    @Test("Virgo start boundary - August 23")
    func virgoStartBoundary() {
        let sign = ZodiacSign.from(month: 8, day: 23)
        #expect(sign == .virgo)
    }

    @Test("Virgo end boundary - September 22")
    func virgoEndBoundary() {
        let sign = ZodiacSign.from(month: 9, day: 22)
        #expect(sign == .virgo)
    }

    // MARK: - Libra (Sep 23 - Oct 22)

    @Test("Libra start boundary - September 23")
    func libraStartBoundary() {
        let sign = ZodiacSign.from(month: 9, day: 23)
        #expect(sign == .libra)
    }

    @Test("Libra end boundary - October 22")
    func libraEndBoundary() {
        let sign = ZodiacSign.from(month: 10, day: 22)
        #expect(sign == .libra)
    }

    // MARK: - Scorpio (Oct 23 - Nov 21)

    @Test("Scorpio start boundary - October 23")
    func scorpioStartBoundary() {
        let sign = ZodiacSign.from(month: 10, day: 23)
        #expect(sign == .scorpio)
    }

    @Test("Scorpio end boundary - November 21")
    func scorpioEndBoundary() {
        let sign = ZodiacSign.from(month: 11, day: 21)
        #expect(sign == .scorpio)
    }

    // MARK: - Sagittarius (Nov 22 - Dec 21)

    @Test("Sagittarius start boundary - November 22")
    func sagittariusStartBoundary() {
        let sign = ZodiacSign.from(month: 11, day: 22)
        #expect(sign == .sagittarius)
    }

    @Test("Sagittarius end boundary - December 21")
    func sagittariusEndBoundary() {
        let sign = ZodiacSign.from(month: 12, day: 21)
        #expect(sign == .sagittarius)
    }

    // MARK: - Capricorn (Dec 22 - Jan 19) - Year Boundary

    @Test("Capricorn start boundary - December 22")
    func capricornStartBoundary() {
        let sign = ZodiacSign.from(month: 12, day: 22)
        #expect(sign == .capricorn)
    }

    @Test("Capricorn end boundary - January 19")
    func capricornEndBoundary() {
        let sign = ZodiacSign.from(month: 1, day: 19)
        #expect(sign == .capricorn)
    }

    @Test("Capricorn December date - December 25")
    func capricornDecemberDate() {
        let sign = ZodiacSign.from(month: 12, day: 25)
        #expect(sign == .capricorn)
    }

    @Test("Capricorn January date - January 1")
    func capricornJanuaryDate() {
        let sign = ZodiacSign.from(month: 1, day: 1)
        #expect(sign == .capricorn)
    }

    // MARK: - Aquarius (Jan 20 - Feb 18)

    @Test("Aquarius start boundary - January 20")
    func aquariusStartBoundary() {
        let sign = ZodiacSign.from(month: 1, day: 20)
        #expect(sign == .aquarius)
    }

    @Test("Aquarius end boundary - February 18")
    func aquariusEndBoundary() {
        let sign = ZodiacSign.from(month: 2, day: 18)
        #expect(sign == .aquarius)
    }

    // MARK: - Pisces (Feb 19 - Mar 20)

    @Test("Pisces start boundary - February 19")
    func piscesStartBoundary() {
        let sign = ZodiacSign.from(month: 2, day: 19)
        #expect(sign == .pisces)
    }

    @Test("Pisces end boundary - March 20")
    func piscesEndBoundary() {
        let sign = ZodiacSign.from(month: 3, day: 20)
        #expect(sign == .pisces)
    }

    // MARK: - From Date Object

    @Test("From Date object - Apple founding date is Aries")
    func fromDateObjectApple() {
        var components = DateComponents()
        components.year = 1976
        components.month = 4
        components.day = 1
        let date = Calendar.current.date(from: components)!

        let sign = ZodiacSign.from(date: date)
        #expect(sign == .aries)
    }

    @Test("From Date object - Google founding date is Virgo")
    func fromDateObjectGoogle() {
        var components = DateComponents()
        components.year = 1998
        components.month = 9
        components.day = 4
        let date = Calendar.current.date(from: components)!

        let sign = ZodiacSign.from(date: date)
        #expect(sign == .virgo)
    }
}

// MARK: - Element Property Tests

struct ZodiacSignElementTests {

    @Test("Fire signs have fire element")
    func fireSignsElement() {
        #expect(ZodiacSign.aries.element == .fire)
        #expect(ZodiacSign.leo.element == .fire)
        #expect(ZodiacSign.sagittarius.element == .fire)
    }

    @Test("Earth signs have earth element")
    func earthSignsElement() {
        #expect(ZodiacSign.taurus.element == .earth)
        #expect(ZodiacSign.virgo.element == .earth)
        #expect(ZodiacSign.capricorn.element == .earth)
    }

    @Test("Air signs have air element")
    func airSignsElement() {
        #expect(ZodiacSign.gemini.element == .air)
        #expect(ZodiacSign.libra.element == .air)
        #expect(ZodiacSign.aquarius.element == .air)
    }

    @Test("Water signs have water element")
    func waterSignsElement() {
        #expect(ZodiacSign.cancer.element == .water)
        #expect(ZodiacSign.scorpio.element == .water)
        #expect(ZodiacSign.pisces.element == .water)
    }

    @Test("Each element has exactly 3 signs")
    func elementSignCount() {
        for element in ZodiacSign.Element.allCases {
            let signs = ZodiacSign.allCases.filter { $0.element == element }
            #expect(signs.count == 3)
        }
    }
}

// MARK: - Compatibility Tests

struct ZodiacSignCompatibilityTests {

    @Test("Aries compatible with Leo (fellow fire sign)")
    func ariesCompatibleWithLeo() {
        #expect(ZodiacSign.aries.isCompatible(with: .leo) == true)
    }

    @Test("Aries compatible with Sagittarius (fellow fire sign)")
    func ariesCompatibleWithSagittarius() {
        #expect(ZodiacSign.aries.isCompatible(with: .sagittarius) == true)
    }

    @Test("Taurus compatible with Virgo (fellow earth sign)")
    func taurusCompatibleWithVirgo() {
        #expect(ZodiacSign.taurus.isCompatible(with: .virgo) == true)
    }

    @Test("Gemini compatible with Aquarius (fellow air sign)")
    func geminiCompatibleWithAquarius() {
        #expect(ZodiacSign.gemini.isCompatible(with: .aquarius) == true)
    }

    @Test("Cancer compatible with Scorpio (fellow water sign)")
    func cancerCompatibleWithScorpio() {
        #expect(ZodiacSign.cancer.isCompatible(with: .scorpio) == true)
    }

    @Test("Compatible signs list contains expected signs")
    func compatibleSignsListComplete() {
        let leoCompatible = ZodiacSign.leo.compatibleSigns
        #expect(leoCompatible.contains(.aries))
        #expect(leoCompatible.contains(.sagittarius))
        #expect(leoCompatible.contains(.gemini))
        #expect(leoCompatible.contains(.libra))
    }

    @Test("Each sign has 4 compatible signs")
    func eachSignHasFourCompatible() {
        for sign in ZodiacSign.allCases {
            #expect(sign.compatibleSigns.count == 4)
        }
    }
}

// MARK: - Opposition Tests

struct ZodiacSignOppositionTests {

    @Test("Aries opposite is Libra")
    func ariesOppositeLibra() {
        #expect(ZodiacSign.aries.oppositeSign == .libra)
        #expect(ZodiacSign.libra.oppositeSign == .aries)
    }

    @Test("Taurus opposite is Scorpio")
    func taurusOppositeScorpio() {
        #expect(ZodiacSign.taurus.oppositeSign == .scorpio)
        #expect(ZodiacSign.scorpio.oppositeSign == .taurus)
    }

    @Test("Gemini opposite is Sagittarius")
    func geminiOppositeSagittarius() {
        #expect(ZodiacSign.gemini.oppositeSign == .sagittarius)
        #expect(ZodiacSign.sagittarius.oppositeSign == .gemini)
    }

    @Test("Cancer opposite is Capricorn")
    func cancerOppositeCapricorn() {
        #expect(ZodiacSign.cancer.oppositeSign == .capricorn)
        #expect(ZodiacSign.capricorn.oppositeSign == .cancer)
    }

    @Test("Leo opposite is Aquarius")
    func leoOppositeAquarius() {
        #expect(ZodiacSign.leo.oppositeSign == .aquarius)
        #expect(ZodiacSign.aquarius.oppositeSign == .leo)
    }

    @Test("Virgo opposite is Pisces")
    func virgoOppositePisces() {
        #expect(ZodiacSign.virgo.oppositeSign == .pisces)
        #expect(ZodiacSign.pisces.oppositeSign == .virgo)
    }

    @Test("isOpposite returns true for opposite signs")
    func isOppositeReturnsTrue() {
        #expect(ZodiacSign.aries.isOpposite(to: .libra) == true)
        #expect(ZodiacSign.leo.isOpposite(to: .aquarius) == true)
    }

    @Test("isOpposite returns false for non-opposite signs")
    func isOppositeReturnsFalse() {
        #expect(ZodiacSign.aries.isOpposite(to: .taurus) == false)
        #expect(ZodiacSign.leo.isOpposite(to: .virgo) == false)
    }
}

// MARK: - Modality Tests

struct ZodiacSignModalityTests {

    @Test("Cardinal signs have cardinal modality")
    func cardinalSignsModality() {
        #expect(ZodiacSign.aries.modality == .cardinal)
        #expect(ZodiacSign.cancer.modality == .cardinal)
        #expect(ZodiacSign.libra.modality == .cardinal)
        #expect(ZodiacSign.capricorn.modality == .cardinal)
    }

    @Test("Fixed signs have fixed modality")
    func fixedSignsModality() {
        #expect(ZodiacSign.taurus.modality == .fixed)
        #expect(ZodiacSign.leo.modality == .fixed)
        #expect(ZodiacSign.scorpio.modality == .fixed)
        #expect(ZodiacSign.aquarius.modality == .fixed)
    }

    @Test("Mutable signs have mutable modality")
    func mutableSignsModality() {
        #expect(ZodiacSign.gemini.modality == .mutable)
        #expect(ZodiacSign.virgo.modality == .mutable)
        #expect(ZodiacSign.sagittarius.modality == .mutable)
        #expect(ZodiacSign.pisces.modality == .mutable)
    }
}

// MARK: - Display Property Tests

struct ZodiacSignDisplayTests {

    @Test("All signs have unique symbols")
    func allSignsHaveUniqueSymbols() {
        let symbols = ZodiacSign.allCases.map { $0.symbol }
        let uniqueSymbols = Set(symbols)
        #expect(symbols.count == uniqueSymbols.count)
    }

    @Test("Display names are capitalized")
    func displayNamesCapitalized() {
        for sign in ZodiacSign.allCases {
            let firstChar = sign.displayName.first!
            #expect(firstChar.isUppercase)
        }
    }

    @Test("All signs have date range descriptions")
    func allSignsHaveDateRanges() {
        for sign in ZodiacSign.allCases {
            #expect(!sign.dateRangeDescription.isEmpty)
            #expect(sign.dateRangeDescription.contains("-"))
        }
    }
}
