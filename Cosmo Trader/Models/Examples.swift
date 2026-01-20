import Foundation

// MARK: - Zodiac Calculation Examples
// ====================================
// This file demonstrates how the zodiac calculations work step-by-step.
// You can run these in a Swift Playground or as unit tests.

// ============================================================================
// HOW THE ZODIAC CALCULATION WORKS
// ============================================================================
//
// The core algorithm converts any date into a zodiac sign using this process:
//
// STEP 1: Extract the month and day from the date
// ------------------------------------------------
// We only care about month and day - the year doesn't matter for zodiac signs.
// Someone born July 4, 1990 is the same sign as someone born July 4, 2005.
//
// STEP 2: Create a comparison value
// ---------------------------------
// We convert month/day into a single number for easy comparison:
//
//   dateValue = month × 100 + day
//
// This creates values like:
//   - January 1   = 1 × 100 + 1   = 101
//   - January 31  = 1 × 100 + 31  = 131
//   - February 14 = 2 × 100 + 14  = 214
//   - July 4      = 7 × 100 + 4   = 704
//   - December 31 = 12 × 100 + 31 = 1231
//
// WHY THIS WORKS:
// Because month × 100 puts the month in the "hundreds place", dates naturally
// sort correctly. 704 (July 4) is greater than 315 (March 15), which is what
// we want for comparison.
//
// STEP 3: Compare against zodiac date ranges
// ------------------------------------------
// Each zodiac sign has a start and end date (as dateValues):
//
//   Capricorn:   1222 (Dec 22) - 119 (Jan 19)  ← Special case!
//   Aquarius:    120 (Jan 20)  - 218 (Feb 18)
//   Pisces:      219 (Feb 19)  - 320 (Mar 20)
//   Aries:       321 (Mar 21)  - 419 (Apr 19)
//   Taurus:      420 (Apr 20)  - 520 (May 20)
//   Gemini:      521 (May 21)  - 620 (Jun 20)
//   Cancer:      621 (Jun 21)  - 722 (Jul 22)
//   Leo:         723 (Jul 23)  - 822 (Aug 22)
//   Virgo:       823 (Aug 23)  - 922 (Sep 22)
//   Libra:       923 (Sep 23)  - 1022 (Oct 22)
//   Scorpio:     1023 (Oct 23) - 1121 (Nov 21)
//   Sagittarius: 1122 (Nov 22) - 1221 (Dec 21)
//
// STEP 4: Handle the Capricorn edge case
// --------------------------------------
// Capricorn is tricky because it spans the year boundary (Dec 22 - Jan 19).
// We handle this by checking Capricorn FIRST:
//
//   if dateValue >= 1222 OR dateValue <= 119 → Capricorn
//
// This catches both December dates (1222-1231) and January dates (101-119).
//
// ============================================================================

enum ZodiacExamples {

    // MARK: - Step-by-Step Demonstration

    /// Demonstrates the full calculation for a specific date (DEBUG only)
    static func demonstrateCalculation(month: Int, day: Int) {
        #if DEBUG
        print("═══════════════════════════════════════════════════════════")
        print("ZODIAC CALCULATION FOR: \(monthName(month)) \(day)")
        print("═══════════════════════════════════════════════════════════")

        // Step 1: Show the input
        print("\n📅 STEP 1: Input")
        print("   Month: \(month) (\(monthName(month)))")
        print("   Day: \(day)")

        // Step 2: Calculate the comparison value
        let dateValue = month * 100 + day
        print("\n🔢 STEP 2: Calculate comparison value")
        print("   Formula: month × 100 + day")
        print("   Calculation: \(month) × 100 + \(day) = \(dateValue)")

        // Step 3: Check each zodiac range
        print("\n🔍 STEP 3: Find matching zodiac range")

        // Check Capricorn first (special case)
        if dateValue >= 1222 || dateValue <= 119 {
            print("   ✓ Capricorn: Dec 22 (1222) - Jan 19 (119)")
            print("     \(dateValue) >= 1222 OR \(dateValue) <= 119 → TRUE")
            print("\n⭐ RESULT: CAPRICORN ♑")
            return
        }

        let ranges: [(ZodiacSign, Int, Int)] = [
            (.aquarius, 120, 218),
            (.pisces, 219, 320),
            (.aries, 321, 419),
            (.taurus, 420, 520),
            (.gemini, 521, 620),
            (.cancer, 621, 722),
            (.leo, 723, 822),
            (.virgo, 823, 922),
            (.libra, 923, 1022),
            (.scorpio, 1023, 1121),
            (.sagittarius, 1122, 1221)
        ]

        for (sign, start, end) in ranges {
            let matches = dateValue >= start && dateValue <= end
            let symbol = matches ? "✓" : "✗"
            print("   \(symbol) \(sign.displayName): \(start) - \(end)")

            if matches {
                print("     \(dateValue) >= \(start) AND \(dateValue) <= \(end) → TRUE")
                print("\n⭐ RESULT: \(sign.displayName.uppercased()) \(sign.symbol)")
                return
            }
        }
        #endif
    }

    /// Helper to get month name
    private static func monthName(_ month: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        var components = DateComponents()
        components.month = month
        components.day = 1
        let date = Calendar.current.date(from: components) ?? Date()
        return formatter.string(from: date)
    }

    // MARK: - Verification Examples

    /// Famous birthdays to verify the calculation (DEBUG only)
    static func verifyFamousBirthdays() {
        #if DEBUG
        print("\n")
        print("═══════════════════════════════════════════════════════════")
        print("FAMOUS BIRTHDAYS - ZODIAC VERIFICATION")
        print("═══════════════════════════════════════════════════════════")

        let famousPeople: [(name: String, month: Int, day: Int, expectedSign: ZodiacSign)] = [
            ("Albert Einstein", 3, 14, .pisces),        // March 14
            ("Steve Jobs", 2, 24, .pisces),             // February 24
            ("Taylor Swift", 12, 13, .sagittarius),    // December 13
            ("Beyoncé", 9, 4, .virgo),                  // September 4
            ("Leonardo DiCaprio", 11, 11, .scorpio),   // November 11
            ("Oprah Winfrey", 1, 29, .aquarius),       // January 29
            ("Elon Musk", 6, 28, .cancer),             // June 28
            ("Rihanna", 2, 20, .pisces),               // February 20
            ("LeBron James", 12, 30, .capricorn),      // December 30
            ("Ariana Grande", 6, 26, .cancer),         // June 26
        ]

        for person in famousPeople {
            let calculatedSign = ZodiacSign.from(month: person.month, day: person.day)
            let matches = calculatedSign == person.expectedSign
            let symbol = matches ? "✓" : "✗"

            print("\(symbol) \(person.name)")
            print("   Birthday: \(monthName(person.month)) \(person.day)")
            print("   Expected: \(person.expectedSign.displayName) \(person.expectedSign.symbol)")
            print("   Calculated: \(calculatedSign.displayName) \(calculatedSign.symbol)")
            print("")
        }
        #endif
    }

    /// Company founding dates to verify stock zodiac signs (DEBUG only)
    static func verifyCompanyZodiacs() {
        #if DEBUG
        print("\n")
        print("═══════════════════════════════════════════════════════════")
        print("TECH COMPANIES - ZODIAC SIGNS BY FOUNDING DATE")
        print("═══════════════════════════════════════════════════════════")

        let companies: [(name: String, symbol: String, month: Int, day: Int, year: Int)] = [
            ("Apple", "AAPL", 4, 1, 1976),
            ("Microsoft", "MSFT", 4, 4, 1975),
            ("Google", "GOOGL", 9, 4, 1998),
            ("Amazon", "AMZN", 7, 5, 1994),
            ("Tesla", "TSLA", 7, 1, 2003),
            ("Meta/Facebook", "META", 2, 4, 2004),
            ("Netflix", "NFLX", 8, 29, 1997),
            ("NVIDIA", "NVDA", 1, 25, 1993),
        ]

        for company in companies {
            let sign = ZodiacSign.from(month: company.month, day: company.day)
            print("\(company.name) (\(company.symbol))")
            print("   Founded: \(monthName(company.month)) \(company.day), \(company.year)")
            print("   Zodiac: \(sign.displayName) \(sign.symbol) (\(sign.element.displayName) \(sign.element.emoji))")
            print("")
        }
        #endif
    }

    // MARK: - Edge Case Testing

    /// Test the Capricorn boundary (year crossover) (DEBUG only)
    static func testCapricornBoundary() {
        #if DEBUG
        print("\n")
        print("═══════════════════════════════════════════════════════════")
        print("CAPRICORN BOUNDARY TEST (Year Crossover)")
        print("═══════════════════════════════════════════════════════════")

        let boundaryDates: [(month: Int, day: Int, expected: ZodiacSign)] = [
            (12, 21, .sagittarius),  // Last day of Sagittarius
            (12, 22, .capricorn),    // First day of Capricorn
            (12, 31, .capricorn),    // New Year's Eve
            (1, 1, .capricorn),      // New Year's Day
            (1, 19, .capricorn),     // Last day of Capricorn
            (1, 20, .aquarius),      // First day of Aquarius
        ]

        for test in boundaryDates {
            let calculated = ZodiacSign.from(month: test.month, day: test.day)
            let matches = calculated == test.expected
            let symbol = matches ? "✓" : "✗"

            print("\(symbol) \(monthName(test.month)) \(test.day)")
            print("   Expected: \(test.expected.displayName)")
            print("   Got: \(calculated.displayName)")
            print("")
        }
        #endif
    }

    // MARK: - Run All Examples

    /// Run all demonstration examples
    static func runAllExamples() {
        // Demonstrate calculation for a few dates
        demonstrateCalculation(month: 7, day: 4)    // Cancer
        demonstrateCalculation(month: 12, day: 25)  // Capricorn
        demonstrateCalculation(month: 3, day: 21)   // Aries (first day)

        // Verify famous birthdays
        verifyFamousBirthdays()

        // Verify company zodiacs
        verifyCompanyZodiacs()

        // Test Capricorn boundary
        testCapricornBoundary()
    }
}

// MARK: - Portfolio Compatibility Example
// =======================================

enum PortfolioCompatibilityExample {

    /// Demonstrate how portfolio compatibility works (DEBUG only)
    static func demonstrateCompatibility() {
        #if DEBUG
        print("\n")
        print("═══════════════════════════════════════════════════════════")
        print("PORTFOLIO COMPATIBILITY EXAMPLE")
        print("═══════════════════════════════════════════════════════════")

        // Create a Leo user (born August 15)
        let user = UserProfile(
            displayName: "Sarah",
            email: "sarah@example.com",
            birthMonth: 8,
            birthDay: 15,
            birthYear: 1990,
            portfolio: Stock.samples
        )

        print("\n👤 USER PROFILE")
        print("   Name: \(user.displayName)")
        print("   Birthday: \(user.formattedBirthDate)")
        print("   Sun Sign: \(user.sunSign.displayName) \(user.sunSign.symbol)")
        print("   Element: \(user.element.displayName) \(user.element.emoji)")

        print("\n🌟 LEO'S COMPATIBLE SIGNS:")
        for sign in user.sunSign.compatibleSigns {
            print("   • \(sign.displayName) \(sign.symbol)")
        }

        print("\n💼 PORTFOLIO ANALYSIS")
        for stock in user.portfolio {
            let compatible = stock.isCompatible(with: user.sunSign)
            let sameElement = stock.sharesElement(with: user.sunSign)
            let icon = compatible ? "✨" : (sameElement ? "🔥" : "  ")

            print("\(icon) \(stock.symbol) - \(stock.zodiacSign.displayName) \(stock.zodiacSign.symbol)")
            print("     Element: \(stock.element.displayName)")
            print("     Compatible: \(compatible ? "Yes" : "No")")
        }

        print("\n📊 SUMMARY")
        print("   Compatible stocks: \(user.compatibleStocks.count)/\(user.portfolio.count)")
        print("   Same element stocks: \(user.sameElementStocks.count)/\(user.portfolio.count)")
        print("\n💫 COSMIC INSIGHT:")
        print("   \(user.cosmicInsight)")
        #endif
    }
}

/*
 To run these examples, call:

 ZodiacExamples.runAllExamples()
 PortfolioCompatibilityExample.demonstrateCompatibility()

 Or in a SwiftUI preview/app initialization for testing.
*/
