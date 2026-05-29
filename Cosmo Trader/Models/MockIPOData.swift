import Foundation

// MARK: - Mock IPO Data
// =====================
// Fictional upcoming IPOs for SwiftUI previews and tests only.
// Production IPOService must use provider/cache data or an unavailable state.
// Each IPO date is carefully chosen to span different zodiac signs.

struct MockIPOData {

    /// All mock IPOs
    static let all: [IPO] = [
        // Aries IPO (March 21 - April 19) - Tech disruptor
        IPO(
            companyName: "FlareRocket AI",
            ticker: "FLAI",
            expectedDate: createDate(month: 4, day: 8),
            priceRangeLow: 22,
            priceRangeHigh: 26,
            sector: "Technology",
            industry: "Artificial Intelligence",
            description: "Enterprise AI platform automating complex business workflows. Known for aggressive expansion into new markets and first-mover positioning in generative AI infrastructure.",
            headquarters: "Austin, TX",
            foundedYear: 2021,
            employeeCount: 450,
            estimatedValuation: 2_800_000_000
        ),

        // Taurus IPO (April 20 - May 20) - Stable consumer goods
        IPO(
            companyName: "Evergreen Provisions",
            ticker: "EGRN",
            expectedDate: createDate(month: 5, day: 5),
            priceRangeLow: 18,
            priceRangeHigh: 21,
            sector: "Consumer Goods",
            industry: "Food & Beverage",
            description: "Premium organic food company with vertically integrated supply chain. Focused on sustainable farming and long-term brand value over rapid growth.",
            headquarters: "Portland, OR",
            foundedYear: 2018,
            employeeCount: 1200,
            estimatedValuation: 950_000_000
        ),

        // Gemini IPO (May 21 - June 20) - Communications platform
        IPO(
            companyName: "DualStream Media",
            ticker: "DSTM",
            expectedDate: createDate(month: 6, day: 10),
            priceRangeLow: 28,
            priceRangeHigh: 32,
            sector: "Technology",
            industry: "Social Media",
            description: "Next-generation creator platform enabling dual-format content creation. Pivoted twice to find product-market fit, now leading in short-form professional content.",
            headquarters: "Los Angeles, CA",
            foundedYear: 2020,
            employeeCount: 380,
            estimatedValuation: 4_200_000_000
        ),

        // Cancer IPO (June 21 - July 22) - Healthcare focus
        IPO(
            companyName: "NestCare Health",
            ticker: nil,  // Ticker TBA
            expectedDate: createDate(month: 7, day: 8),
            priceRangeLow: 15,
            priceRangeHigh: 18,
            sector: "Healthcare",
            industry: "Home Healthcare",
            description: "In-home healthcare platform connecting families with vetted caregivers. Strong customer loyalty and emotional brand connection driving 95% retention.",
            headquarters: "Boston, MA",
            foundedYear: 2019,
            employeeCount: 2800,
            estimatedValuation: 1_600_000_000
        ),

        // Leo IPO (July 23 - August 22) - Luxury brand
        IPO(
            companyName: "Aurelius Brands",
            ticker: "AURS",
            expectedDate: createDate(month: 8, day: 12),
            priceRangeLow: 42,
            priceRangeHigh: 48,
            sector: "Consumer Goods",
            industry: "Luxury Goods",
            description: "Digital-native luxury holding company with bold marketing approach. Portfolio of premium lifestyle brands targeting affluent millennials.",
            headquarters: "New York, NY",
            foundedYear: 2017,
            employeeCount: 650,
            estimatedValuation: 3_500_000_000
        ),

        // Virgo IPO (August 23 - September 22) - Fintech
        IPO(
            companyName: "PrecisionLedger",
            ticker: "PLDG",
            expectedDate: createDate(month: 9, day: 5),
            priceRangeLow: 24,
            priceRangeHigh: 28,
            sector: "Financial Services",
            industry: "Fintech",
            description: "Enterprise accounting automation with meticulous audit trails. Known for detail-oriented approach and zero-error tolerance in financial workflows.",
            headquarters: "Chicago, IL",
            foundedYear: 2019,
            employeeCount: 520,
            estimatedValuation: 2_100_000_000
        ),

        // Libra IPO (September 23 - October 22) - Partnership platform
        IPO(
            companyName: "BalancePoint Ventures",
            ticker: nil,
            expectedDate: createDate(month: 10, day: 8),
            priceRangeLow: 19,
            priceRangeHigh: 23,
            sector: "Financial Services",
            industry: "Investment Platform",
            description: "Collaborative investment platform enabling strategic partnerships between retail and institutional investors. Heavy focus on M&A advisory services.",
            headquarters: "San Francisco, CA",
            foundedYear: 2020,
            employeeCount: 180,
            estimatedValuation: 850_000_000
        ),

        // Scorpio IPO (October 23 - November 21) - Cybersecurity
        IPO(
            companyName: "DeepVault Security",
            ticker: "DVLT",
            expectedDate: createDate(month: 11, day: 8),
            priceRangeLow: 35,
            priceRangeHigh: 40,
            sector: "Technology",
            industry: "Cybersecurity",
            description: "Enterprise security platform specializing in detecting hidden threats. Emerged from stealth mode after surviving major industry downturn stronger than before.",
            headquarters: "Seattle, WA",
            foundedYear: 2018,
            employeeCount: 720,
            estimatedValuation: 5_800_000_000
        ),

        // Sagittarius IPO (November 22 - December 21) - Travel
        IPO(
            companyName: "Wanderlux Travel",
            ticker: "WLUX",
            expectedDate: createDate(month: 12, day: 5),
            priceRangeLow: 16,
            priceRangeHigh: 20,
            sector: "Travel & Leisure",
            industry: "Travel Technology",
            description: "Global adventure travel marketplace with optimistic growth outlook. Expanding aggressively into emerging markets with premium experience focus.",
            headquarters: "Denver, CO",
            foundedYear: 2019,
            employeeCount: 340,
            estimatedValuation: 1_200_000_000
        ),

        // Capricorn IPO (December 22 - January 19) - Industrial
        IPO(
            companyName: "SteadyBuild Infrastructure",
            ticker: "SBLD",
            expectedDate: createDate(month: 1, day: 10),
            priceRangeLow: 30,
            priceRangeHigh: 34,
            sector: "Industrials",
            industry: "Infrastructure",
            description: "Industrial infrastructure company with disciplined capital allocation. Long-term institutional investor appeal with focus on consistent, measured growth.",
            headquarters: "Dallas, TX",
            foundedYear: 2015,
            employeeCount: 4200,
            estimatedValuation: 8_500_000_000
        ),

        // Aquarius IPO (January 20 - February 18) - Cleantech
        IPO(
            companyName: "AetherGrid Energy",
            ticker: "AGRD",
            expectedDate: createDate(month: 2, day: 5),
            priceRangeLow: 25,
            priceRangeHigh: 30,
            sector: "Energy",
            industry: "Clean Technology",
            description: "Revolutionary distributed energy grid challenging traditional utilities. Innovation-driven approach with proprietary technology disrupting industry norms.",
            headquarters: "Boulder, CO",
            foundedYear: 2020,
            employeeCount: 290,
            estimatedValuation: 3_200_000_000
        ),

        // Pisces IPO (February 19 - March 20) - Wellness
        IPO(
            companyName: "DreamFlow Wellness",
            ticker: nil,
            expectedDate: createDate(month: 3, day: 8),
            priceRangeLow: 12,
            priceRangeHigh: 15,
            sector: "Healthcare",
            industry: "Mental Wellness",
            description: "Intuitive mental wellness platform combining therapy access with creative expression tools. Strong in emotional connection with users through empathetic design.",
            headquarters: "Miami, FL",
            foundedYear: 2021,
            employeeCount: 210,
            estimatedValuation: 680_000_000
        )
    ]

    /// Featured IPOs (highest valuations)
    static var featured: [IPO] {
        all.sorted { ($0.estimatedValuation ?? 0) > ($1.estimatedValuation ?? 0) }.prefix(4).map { $0 }
    }

    /// IPOs this month
    static var thisMonth: [IPO] {
        all.filter { $0.isThisMonth }
    }

    /// IPOs this week
    static var thisWeek: [IPO] {
        all.filter { $0.isThisWeek }
    }

    /// Upcoming IPOs (not yet launched)
    static var upcoming: [IPO] {
        all.filter { !$0.hasLaunched }.sorted { $0.expectedDate < $1.expectedDate }
    }

    /// IPOs by sector
    static func bySector(_ sector: String) -> [IPO] {
        all.filter { $0.sector == sector }
    }

    /// Get highly compatible IPOs for a user
    static func highlyCompatible(for user: UserProfile) -> [IPO] {
        all.filter { $0.compatibility(with: user).isHighlyCompatible }
            .sorted { $0.compatibility(with: user).score > $1.compatibility(with: user).score }
    }

    /// Get IPOs by zodiac sign
    static func byZodiacSign(_ sign: ZodiacSign) -> [IPO] {
        all.filter { $0.zodiacSign == sign }
    }

    /// Get upcoming IPOs for alerting (highly compatible, within 7 days)
    static func upcomingAlerts(for user: UserProfile) -> [IPO] {
        all.filter { ipo in
            ipo.isThisWeek &&
            !ipo.hasLaunched &&
            ipo.compatibility(with: user).score >= 80
        }.sorted { $0.expectedDate < $1.expectedDate }
    }

    // MARK: - Helper

    /// Create a date for the current or next occurrence of month/day
    private static func createDate(month: Int, day: Int) -> Date {
        let calendar = Calendar.current
        let now = Date()
        let currentYear = calendar.component(.year, from: now)

        var components = DateComponents()
        components.year = currentYear
        components.month = month
        components.day = day

        if let date = calendar.date(from: components) {
            // If date is in the past, use next year
            if date < now {
                components.year = currentYear + 1
                return calendar.date(from: components) ?? date
            }
            return date
        }

        return now
    }
}

// MARK: - Sector List

extension MockIPOData {

    /// All unique sectors in the IPO data
    static var sectors: [String] {
        Array(Set(all.map { $0.sector })).sorted()
    }
}
