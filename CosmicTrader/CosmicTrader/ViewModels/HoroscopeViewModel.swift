import Foundation

/// HoroscopeViewModel
/// ------------------
/// The "brain" for the Horoscope tab - our unique astrological feature!
///
/// This combines astrology with trading insights (for fun, not real advice!)

@Observable
class HoroscopeViewModel {

    // MARK: - Properties

    /// The user's zodiac sign
    var userSign: ZodiacSign = .sagittarius

    /// Today's horoscope reading
    var dailyHoroscope: Horoscope?

    /// All zodiac signs (for browsing)
    var allSigns: [ZodiacSign] = ZodiacSign.allCases

    /// Is horoscope loading?
    var isLoading: Bool = false

    /// Currently selected sign to view
    var selectedSign: ZodiacSign?

    // MARK: - Methods

    /// Load today's horoscope for the user's sign
    func loadDailyHoroscope() async {
        isLoading = true

        // Simulate loading
        try? await Task.sleep(nanoseconds: 800_000_000)

        // Generate sample horoscope
        dailyHoroscope = Horoscope.generateDaily(for: userSign)
        isLoading = false
    }

    /// Get horoscope for a specific sign
    func getHoroscope(for sign: ZodiacSign) -> Horoscope {
        Horoscope.generateDaily(for: sign)
    }
}

// MARK: - Horoscope Model

/// A daily horoscope reading
struct Horoscope: Identifiable {
    let id = UUID()
    let sign: ZodiacSign
    let date: Date
    let generalReading: String
    let tradingInsight: String
    let luckyNumber: Int
    let luckyStock: String
    let moodRating: Int // 1-5 stars

    /// Generate a daily horoscope (in real app, this would come from an API)
    static func generateDaily(for sign: ZodiacSign) -> Horoscope {
        // Sample readings - in a real app, these would be fetched
        let readings: [ZodiacSign: (general: String, trading: String, stock: String)] = [
            .aries: (
                "Your fiery energy is perfect for bold moves today. Trust your instincts but don't rush important decisions.",
                "High-risk, high-reward opportunities catch your eye. Consider tech startups.",
                "TSLA"
            ),
            .taurus: (
                "Stability is your strength today. Focus on building long-term foundations.",
                "Blue-chip stocks align with your energy. Think dividends and steady growth.",
                "JNJ"
            ),
            .gemini: (
                "Your dual nature helps you see both sides of every deal. Communication brings opportunities.",
                "Media and communication stocks favor you. Stay informed on market news.",
                "META"
            ),
            .cancer: (
                "Trust your intuition about home and security matters. Emotional intelligence is high.",
                "Real estate and consumer goods resonate with your energy today.",
                "HD"
            ),
            .leo: (
                "Your natural leadership shines bright. Others look to you for guidance.",
                "Entertainment and luxury brands align with your royal energy.",
                "AAPL"
            ),
            .virgo: (
                "Attention to detail pays off. Perfect day for analysis and planning.",
                "Healthcare and precision industries favor your meticulous nature.",
                "UNH"
            ),
            .libra: (
                "Balance in all things brings harmony. Partnerships are favored.",
                "Consider balanced portfolios. Financial sector stocks catch your eye.",
                "JPM"
            ),
            .scorpio: (
                "Your intensity helps uncover hidden truths. Research deeply.",
                "Look beneath the surface at undervalued stocks. Biotechs intrigue you.",
                "MRNA"
            ),
            .sagittarius: (
                "Adventure calls! Expand your horizons and take calculated risks.",
                "International markets and travel stocks align with your wanderlust.",
                "ABNB"
            ),
            .capricorn: (
                "Discipline and patience are your superpowers today. Build for the future.",
                "Traditional industries and established companies match your steady approach.",
                "BRK.B"
            ),
            .aquarius: (
                "Innovation and unconventional thinking lead the way. Embrace the future.",
                "Tech innovation and clean energy stocks resonate with your visionary nature.",
                "GOOGL"
            ),
            .pisces: (
                "Your intuition is especially strong. Dreams may hold insights.",
                "Creative industries and streaming services flow with your imaginative energy.",
                "DIS"
            )
        ]

        let data = readings[sign] ?? readings[.aries]!

        return Horoscope(
            sign: sign,
            date: Date(),
            generalReading: data.general,
            tradingInsight: data.trading,
            luckyNumber: Int.random(in: 1...99),
            luckyStock: data.stock,
            moodRating: Int.random(in: 3...5)
        )
    }
}
