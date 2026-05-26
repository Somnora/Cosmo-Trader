import Foundation
import SwiftUI

// MARK: - ZodiacSign

/// Represents one of the 12 zodiac signs in Western astrology.
///
/// `ZodiacSign` is a core model used throughout the app to determine user profiles,
/// stock "personalities" (based on IPO date), and compatibility calculations.
///
/// ## Usage
///
/// ```swift
/// // Get user's sign from birth date
/// let userSign = ZodiacSign.from(date: user.birthDate)
///
/// // Access sign properties
/// print(userSign.symbol)        // "♈"
/// print(userSign.displayName)   // "Aries"
/// print(userSign.element)       // .fire
///
/// // Calculate compatibility
/// let score = CompatibilityCalculator.calculate(
///     userSign: userSign,
///     stockSign: stock.zodiacSign
/// )
/// ```
///
/// ## Elements
///
/// Each sign belongs to one of four elements that influence compatibility:
///
/// | Element | Signs | Traits |
/// |---------|-------|--------|
/// | Fire | Aries, Leo, Sagittarius | Passionate, energetic |
/// | Earth | Taurus, Virgo, Capricorn | Practical, grounded |
/// | Air | Gemini, Libra, Aquarius | Intellectual, analytical |
/// | Water | Cancer, Scorpio, Pisces | Intuitive, emotional |
///
/// ## Why an Enum?
///
/// 1. **Fixed set**: Exactly 12 signs that never change
/// 2. **Type safety**: Can't create invalid signs
/// 3. **Exhaustive**: Swift enforces handling all cases
/// 4. **Efficient**: Value type with minimal memory footprint
enum ZodiacSign: String, CaseIterable, Identifiable, Codable {
    /// The Ram (Mar 21 - Apr 19) - Fire sign
    case aries
    /// The Bull (Apr 20 - May 20) - Earth sign
    case taurus
    /// The Twins (May 21 - Jun 20) - Air sign
    case gemini
    /// The Crab (Jun 21 - Jul 22) - Water sign
    case cancer
    /// The Lion (Jul 23 - Aug 22) - Fire sign
    case leo
    /// The Maiden (Aug 23 - Sep 22) - Earth sign
    case virgo
    /// The Scales (Sep 23 - Oct 22) - Air sign
    case libra
    /// The Scorpion (Oct 23 - Nov 21) - Water sign
    case scorpio
    /// The Archer (Nov 22 - Dec 21) - Fire sign
    case sagittarius
    /// The Goat (Dec 22 - Jan 19) - Earth sign
    case capricorn
    /// The Water Bearer (Jan 20 - Feb 18) - Air sign
    case aquarius
    /// The Fish (Feb 19 - Mar 20) - Water sign
    case pisces

    // MARK: - Identifiable Conformance

    /// Unique identifier for SwiftUI lists
    /// WHY: SwiftUI's ForEach needs to know which item is which
    var id: String { rawValue }

    // MARK: - Display Properties

    /// The astrological symbol for this sign
    /// WHY: Visual representation in the UI - these are Unicode characters
    var symbol: String {
        switch self {
        case .aries:       return "♈"  // The Ram
        case .taurus:      return "♉"  // The Bull
        case .gemini:      return "♊"  // The Twins
        case .cancer:      return "♋"  // The Crab
        case .leo:         return "♌"  // The Lion
        case .virgo:       return "♍"  // The Maiden
        case .libra:       return "♎"  // The Scales
        case .scorpio:     return "♏"  // The Scorpion
        case .sagittarius: return "♐"  // The Archer
        case .capricorn:   return "♑"  // The Goat
        case .aquarius:    return "♒"  // The Water Bearer
        case .pisces:      return "♓"  // The Fish
        }
    }

    /// Text presentation variant of the symbol (prevents emoji rendering)
    var textSymbol: String {
        symbol + "\u{FE0E}"
    }

    /// Human-readable name with proper capitalization
    /// WHY: "aries" looks ugly, "Aries" looks proper
    var displayName: String {
        rawValue.capitalized
    }

    /// Human-readable date range string for display
    /// WHY: Users want to see when each sign starts and ends
    var dateRangeDescription: String {
        switch self {
        case .aries:       return "Mar 21 - Apr 19"
        case .taurus:      return "Apr 20 - May 20"
        case .gemini:      return "May 21 - Jun 20"
        case .cancer:      return "Jun 21 - Jul 22"
        case .leo:         return "Jul 23 - Aug 22"
        case .virgo:       return "Aug 23 - Sep 22"
        case .libra:       return "Sep 23 - Oct 22"
        case .scorpio:     return "Oct 23 - Nov 21"
        case .sagittarius: return "Nov 22 - Dec 21"
        case .capricorn:   return "Dec 22 - Jan 19"
        case .aquarius:    return "Jan 20 - Feb 18"
        case .pisces:      return "Feb 19 - Mar 20"
        }
    }

    // MARK: - Elements
    // ================
    // In astrology, each sign belongs to one of four elements.
    // Signs of the same element share personality traits.
    //
    // FIRE SIGNS (Aries, Leo, Sagittarius):
    //   - Passionate, energetic, bold
    //   - Trading style: Aggressive, risk-taking
    //
    // EARTH SIGNS (Taurus, Virgo, Capricorn):
    //   - Practical, grounded, patient
    //   - Trading style: Long-term, value investing
    //
    // AIR SIGNS (Gemini, Libra, Aquarius):
    //   - Intellectual, communicative, analytical
    //   - Trading style: Research-heavy, diversified
    //
    // WATER SIGNS (Cancer, Scorpio, Pisces):
    //   - Intuitive, emotional, perceptive
    //   - Trading style: Gut-feeling, contrarian

    var element: Element {
        switch self {
        case .aries, .leo, .sagittarius:
            return .fire
        case .taurus, .virgo, .capricorn:
            return .earth
        case .gemini, .libra, .aquarius:
            return .air
        case .cancer, .scorpio, .pisces:
            return .water
        }
    }

    // MARK: - Date Range (for calculations)
    // =====================================
    // These tuples store the START date of each sign as (month, day).
    // We use this to calculate which sign a date falls under.
    //
    // WHY A TUPLE (month: Int, day: Int)?
    // -----------------------------------
    // - We only need month and day (year doesn't matter for zodiac)
    // - Tuples are simple and efficient
    // - Easy to compare: is (month, day) >= sign's start date?

    /// The start date of this zodiac sign as (month, day)
    /// WHY: Needed to calculate which sign a date falls under
    var startDate: (month: Int, day: Int) {
        switch self {
        case .aries:       return (month: 3, day: 21)   // March 21
        case .taurus:      return (month: 4, day: 20)   // April 20
        case .gemini:      return (month: 5, day: 21)   // May 21
        case .cancer:      return (month: 6, day: 21)   // June 21
        case .leo:         return (month: 7, day: 23)   // July 23
        case .virgo:       return (month: 8, day: 23)   // August 23
        case .libra:       return (month: 9, day: 23)   // September 23
        case .scorpio:     return (month: 10, day: 23)  // October 23
        case .sagittarius: return (month: 11, day: 22)  // November 22
        case .capricorn:   return (month: 12, day: 22)  // December 22
        case .aquarius:    return (month: 1, day: 20)   // January 20
        case .pisces:      return (month: 2, day: 19)   // February 19
        }
    }

    /// The end date of this zodiac sign as (month, day)
    /// WHY: Useful for displaying complete date ranges
    var endDate: (month: Int, day: Int) {
        switch self {
        case .aries:       return (month: 4, day: 19)   // April 19
        case .taurus:      return (month: 5, day: 20)   // May 20
        case .gemini:      return (month: 6, day: 20)   // June 20
        case .cancer:      return (month: 7, day: 22)   // July 22
        case .leo:         return (month: 8, day: 22)   // August 22
        case .virgo:       return (month: 9, day: 22)   // September 22
        case .libra:       return (month: 10, day: 22)  // October 22
        case .scorpio:     return (month: 11, day: 21)  // November 21
        case .sagittarius: return (month: 12, day: 21)  // December 21
        case .capricorn:   return (month: 1, day: 19)   // January 19
        case .aquarius:    return (month: 2, day: 18)   // February 18
        case .pisces:      return (month: 3, day: 20)   // March 20
        }
    }

    // MARK: - Date to Sign Calculation
    // ================================
    // This is the CORE LOGIC for determining zodiac signs!
    //
    // HOW IT WORKS (step by step):
    // ----------------------------
    // 1. Extract the month and day from the input date
    // 2. Create a "comparison value" = month * 100 + day
    //    Example: March 15 = 3 * 100 + 15 = 315
    //    Example: December 25 = 12 * 100 + 25 = 1225
    // 3. Compare this value against each sign's date range
    //
    // WHY month * 100 + day?
    // ----------------------
    // This creates a sortable number where:
    // - January 1 = 101, January 31 = 131
    // - February 1 = 201, February 28 = 228
    // - December 31 = 1231
    // This lets us compare dates with simple < and >= operators!
    //
    // SPECIAL CASE: Capricorn
    // -----------------------
    // Capricorn spans Dec 22 - Jan 19 (crosses year boundary!)
    // We handle this by checking Capricorn FIRST.

    /// Calculate the zodiac sign for any given date
    /// - Parameter date: Any date (birthday, founding date, etc.)
    /// - Returns: The zodiac sign for that date
    static func from(date: Date) -> ZodiacSign {
        // Step 1: Extract month and day from the date
        let calendar = Calendar.current
        let month = calendar.component(.month, from: date)
        let day = calendar.component(.day, from: date)

        // Step 2: Use our helper function with extracted values
        return from(month: month, day: day)
    }

    /// Calculate zodiac sign from month and day numbers
    /// - Parameters:
    ///   - month: Month number (1-12)
    ///   - day: Day of month (1-31)
    /// - Returns: The zodiac sign for that date
    ///
    /// This overload is useful when you already have month/day as integers
    static func from(month: Int, day: Int) -> ZodiacSign {
        // Create our comparison value
        // Example: July 4 = 7 * 100 + 4 = 704
        let dateValue = month * 100 + day

        // SPECIAL CASE: Capricorn crosses the year boundary (Dec 22 - Jan 19)
        // We must check this FIRST, otherwise the logic breaks
        //
        // Why? Because:
        // - Dec 25 (1225) is >= Dec 22 (1222) ✓ → Capricorn
        // - Jan 10 (110) is NOT >= Dec 22 (1222) ✗ → Would miss it!
        //
        // So we check: is it Dec 22+ OR Jan 1-19?
        if dateValue >= 1222 || dateValue <= 119 {
            return .capricorn
        }

        // For all other signs, we check if the date falls within their range
        // We go through the zodiac in order (Aquarius → Pisces → ... → Sagittarius)

        // Aquarius: Jan 20 (120) - Feb 18 (218)
        if dateValue >= 120 && dateValue <= 218 {
            return .aquarius
        }

        // Pisces: Feb 19 (219) - Mar 20 (320)
        if dateValue >= 219 && dateValue <= 320 {
            return .pisces
        }

        // Aries: Mar 21 (321) - Apr 19 (419)
        if dateValue >= 321 && dateValue <= 419 {
            return .aries
        }

        // Taurus: Apr 20 (420) - May 20 (520)
        if dateValue >= 420 && dateValue <= 520 {
            return .taurus
        }

        // Gemini: May 21 (521) - Jun 20 (620)
        if dateValue >= 521 && dateValue <= 620 {
            return .gemini
        }

        // Cancer: Jun 21 (621) - Jul 22 (722)
        if dateValue >= 621 && dateValue <= 722 {
            return .cancer
        }

        // Leo: Jul 23 (723) - Aug 22 (822)
        if dateValue >= 723 && dateValue <= 822 {
            return .leo
        }

        // Virgo: Aug 23 (823) - Sep 22 (922)
        if dateValue >= 823 && dateValue <= 922 {
            return .virgo
        }

        // Libra: Sep 23 (923) - Oct 22 (1022)
        if dateValue >= 923 && dateValue <= 1022 {
            return .libra
        }

        // Scorpio: Oct 23 (1023) - Nov 21 (1121)
        if dateValue >= 1023 && dateValue <= 1121 {
            return .scorpio
        }

        // Sagittarius: Nov 22 (1122) - Dec 21 (1221)
        // This is the default case - if we got here, it must be Sagittarius
        return .sagittarius
    }
}

// MARK: - Element Enum
// ====================
// The four classical elements from Greek philosophy.
// Each has unique traits that influence personality and (in our app) trading style.

extension ZodiacSign {

    enum Element: String, CaseIterable, Identifiable, Codable {
        case fire
        case earth
        case air
        case water

        var id: String { rawValue }

        /// Display name with capitalization
        var displayName: String {
            rawValue.capitalized
        }

        /// SF Symbol representation of the element
        var sfSymbol: String {
            switch self {
            case .fire:  return "flame.fill"
            case .earth: return "leaf.fill"
            case .air:   return "wind"
            case .water: return "drop.fill"
            }
        }

        /// Color associated with this element (for UI theming)
        var colorName: String {
            switch self {
            case .fire:  return "red"
            case .earth: return "green"
            case .air:   return "yellow"
            case .water: return "blue"
            }
        }

        /// SwiftUI Color for this element
        var color: Color {
            switch self {
            case .fire:  return Color(red: 1.0, green: 0.4, blue: 0.3)   // Warm orange-red
            case .earth: return Color(red: 0.4, green: 0.8, blue: 0.4)   // Forest green
            case .air:   return Color(red: 0.9, green: 0.85, blue: 0.4)  // Golden yellow
            case .water: return Color(red: 0.4, green: 0.6, blue: 0.9)   // Ocean blue
            }
        }

        /// Personality traits associated with this element
        var traits: [String] {
            switch self {
            case .fire:
                return ["Passionate", "Energetic", "Bold", "Impulsive", "Confident"]
            case .earth:
                return ["Practical", "Grounded", "Patient", "Reliable", "Stubborn"]
            case .air:
                return ["Intellectual", "Communicative", "Analytical", "Social", "Detached"]
            case .water:
                return ["Intuitive", "Emotional", "Perceptive", "Nurturing", "Sensitive"]
            }
        }

        /// Suggested trading style for this element (for our cosmic theme!)
        var tradingStyle: String {
            switch self {
            case .fire:
                return "Aggressive growth investing. You thrive on high-risk, high-reward opportunities."
            case .earth:
                return "Value investing with patience. You prefer stable, dividend-paying blue chips."
            case .air:
                return "Research-driven diversification. You analyze data before every move."
            case .water:
                return "Intuitive contrarian plays. You sense market shifts before others."
            }
        }

        /// All zodiac signs that belong to this element
        var signs: [ZodiacSign] {
            ZodiacSign.allCases.filter { $0.element == self }
        }
    }
}

// MARK: - Compatibility (Bonus Feature!)
// ======================================
// In astrology, some signs are more compatible than others.
// We can use this for fun features like "compatible stocks"!

extension ZodiacSign {

    /// Signs that are highly compatible with this sign
    /// Based on traditional astrological compatibility
    var compatibleSigns: [ZodiacSign] {
        switch self {
        case .aries:       return [.leo, .sagittarius, .gemini, .aquarius]
        case .taurus:      return [.virgo, .capricorn, .cancer, .pisces]
        case .gemini:      return [.libra, .aquarius, .aries, .leo]
        case .cancer:      return [.scorpio, .pisces, .taurus, .virgo]
        case .leo:         return [.aries, .sagittarius, .gemini, .libra]
        case .virgo:       return [.taurus, .capricorn, .cancer, .scorpio]
        case .libra:       return [.gemini, .aquarius, .leo, .sagittarius]
        case .scorpio:     return [.cancer, .pisces, .virgo, .capricorn]
        case .sagittarius: return [.aries, .leo, .libra, .aquarius]
        case .capricorn:   return [.taurus, .virgo, .scorpio, .pisces]
        case .aquarius:    return [.gemini, .libra, .aries, .sagittarius]
        case .pisces:      return [.cancer, .scorpio, .taurus, .capricorn]
        }
    }

    /// Check if this sign is compatible with another
    func isCompatible(with other: ZodiacSign) -> Bool {
        compatibleSigns.contains(other)
    }

    /// Calculate a compatibility score (0-100) with another sign
    /// Uses multiple factors: same sign, same element, traditional compatibility, opposition
    func compatibilityScore(with other: ZodiacSign) -> Int {
        // Same sign = highest compatibility
        if self == other {
            return 95
        }

        // Same element = very high compatibility
        if self.element == other.element {
            return 88
        }

        // Traditional compatibility (from compatibleSigns)
        if compatibleSigns.contains(other) {
            return 78
        }

        // Opposition signs = cosmic tension but potential
        if oppositeSign == other {
            return 45
        }

        // Neutral compatibility
        return 55
    }

    // MARK: - Cosmic Rivals (Opposition)
    // ==================================
    // In astrology, signs 180° apart on the zodiac wheel are in "opposition".
    // These opposing pairs represent complementary but often conflicting energies.
    //
    // THE SIX OPPOSING PAIRS:
    // - Aries ↔ Libra (Self vs Partnership)
    // - Taurus ↔ Scorpio (Security vs Transformation)
    // - Gemini ↔ Sagittarius (Details vs Big Picture)
    // - Cancer ↔ Capricorn (Home vs Career)
    // - Leo ↔ Aquarius (Individual vs Collective)
    // - Virgo ↔ Pisces (Logic vs Intuition)

    /// The zodiac sign directly opposite this one (180° apart)
    /// These are "cosmic rivals" - complementary yet opposing energies
    var oppositeSign: ZodiacSign {
        switch self {
        case .aries:       return .libra
        case .taurus:      return .scorpio
        case .gemini:      return .sagittarius
        case .cancer:      return .capricorn
        case .leo:         return .aquarius
        case .virgo:       return .pisces
        case .libra:       return .aries
        case .scorpio:     return .taurus
        case .sagittarius: return .gemini
        case .capricorn:   return .cancer
        case .aquarius:    return .leo
        case .pisces:      return .virgo
        }
    }

    /// Check if this sign is in opposition to another
    func isOpposite(to other: ZodiacSign) -> Bool {
        oppositeSign == other
    }

    /// The cosmic tension description for this opposition pair
    var oppositionTheme: String {
        switch self {
        case .aries, .libra:
            return "Self vs Partnership"
        case .taurus, .scorpio:
            return "Security vs Transformation"
        case .gemini, .sagittarius:
            return "Details vs Big Picture"
        case .cancer, .capricorn:
            return "Home vs Career"
        case .leo, .aquarius:
            return "Individual vs Collective"
        case .virgo, .pisces:
            return "Logic vs Intuition"
        }
    }

    /// Detailed description of this opposition's dynamic
    var oppositionDescription: String {
        switch self {
        case .aries:
            return "Aries charges forward independently while Libra seeks balance through partnership. Together they teach us to balance self-assertion with cooperation."
        case .libra:
            return "Libra harmonizes through relationships while Aries leads with bold independence. Together they teach us to balance cooperation with self-assertion."
        case .taurus:
            return "Taurus builds stable foundations while Scorpio embraces deep transformation. Together they teach us to balance security with necessary change."
        case .scorpio:
            return "Scorpio transforms through intensity while Taurus maintains steady comfort. Together they teach us to balance transformation with stability."
        case .gemini:
            return "Gemini gathers diverse information while Sagittarius seeks universal truth. Together they teach us to balance facts with meaning."
        case .sagittarius:
            return "Sagittarius explores grand philosophies while Gemini focuses on immediate details. Together they teach us to balance vision with practicality."
        case .cancer:
            return "Cancer nurtures home and family while Capricorn builds worldly achievement. Together they teach us to balance personal life with professional ambition."
        case .capricorn:
            return "Capricorn climbs toward public success while Cancer tends to private emotional needs. Together they teach us to balance career with family."
        case .leo:
            return "Leo shines through personal creativity while Aquarius innovates for the collective. Together they teach us to balance individual expression with group consciousness."
        case .aquarius:
            return "Aquarius revolutionizes for humanity while Leo expresses unique individuality. Together they teach us to balance social progress with personal pride."
        case .virgo:
            return "Virgo analyzes practical details while Pisces flows with intuitive wisdom. Together they teach us to balance logic with faith."
        case .pisces:
            return "Pisces dissolves into universal compassion while Virgo organizes tangible reality. Together they teach us to balance dreams with discipline."
        }
    }
}

// MARK: - Modality
// =================
// Each sign has a modality that describes how they approach action.

extension ZodiacSign {

    /// The three modalities in astrology
    enum Modality: String, CaseIterable, Identifiable, Codable {
        case cardinal  // Initiators - start things
        case fixed     // Stabilizers - maintain things
        case mutable   // Adapters - change things

        var id: String { rawValue }

        var displayName: String { rawValue.capitalized }

        var description: String {
            switch self {
            case .cardinal:
                return "Initiators who start new ventures and lead the way"
            case .fixed:
                return "Stabilizers who maintain and build upon foundations"
            case .mutable:
                return "Adapters who embrace change and flexibility"
            }
        }

        var tradingImplication: String {
            switch self {
            case .cardinal:
                return "First-mover companies that pioneer new markets"
            case .fixed:
                return "Established companies with staying power"
            case .mutable:
                return "Adaptive companies that pivot with market trends"
            }
        }
    }

    /// The modality of this sign
    var modality: Modality {
        switch self {
        case .aries, .cancer, .libra, .capricorn:
            return .cardinal
        case .taurus, .leo, .scorpio, .aquarius:
            return .fixed
        case .gemini, .virgo, .sagittarius, .pisces:
            return .mutable
        }
    }

    /// Full description of this sign's personality
    var personalityDescription: String {
        switch self {
        case .aries:
            return "Bold, ambitious, and unafraid to dive headfirst into challenging situations. Aries leads with confidence and thrives on competition."
        case .taurus:
            return "Grounded, patient, and devoted to building lasting value. Taurus appreciates quality and takes a steady, reliable approach."
        case .gemini:
            return "Curious, adaptable, and intellectually agile. Gemini thrives on variety and excels at communication and quick thinking."
        case .cancer:
            return "Intuitive, protective, and deeply connected to emotional currents. Cancer nurtures growth and values security above all."
        case .leo:
            return "Charismatic, creative, and born to lead. Leo commands attention and brings warmth and generosity to everything they touch."
        case .virgo:
            return "Analytical, practical, and detail-oriented. Virgo excels at optimization and brings order to chaos through careful planning."
        case .libra:
            return "Harmonious, diplomatic, and aesthetically inclined. Libra seeks balance and creates partnerships built on fairness."
        case .scorpio:
            return "Intense, strategic, and deeply perceptive. Scorpio sees beneath the surface and transforms everything they commit to."
        case .sagittarius:
            return "Adventurous, optimistic, and philosophically minded. Sagittarius aims for expansion and embraces bold possibilities."
        case .capricorn:
            return "Ambitious, disciplined, and built for the long game. Capricorn climbs steadily toward success through hard work and patience."
        case .aquarius:
            return "Innovative, independent, and future-focused. Aquarius breaks conventions and champions progressive ideas."
        case .pisces:
            return "Empathic, creative, and spiritually attuned. Pisces flows with intuition and connects deeply with the intangible."
        }
    }

    /// How this sign operates as a company/investment
    var corporatePersonality: String {
        switch self {
        case .aries:
            return "A pioneer that moves fast and breaks things. This company leads markets rather than follows them, favoring bold innovation over careful iteration."
        case .taurus:
            return "A steady accumulator of value that prioritizes sustainable growth over quick wins. This company builds empires brick by brick."
        case .gemini:
            return "A versatile communicator that adapts quickly to market shifts. This company excels at pivoting and maintaining multiple revenue streams."
        case .cancer:
            return "A protector of stakeholders that prioritizes security and loyalty. This company nurtures long-term relationships over short-term gains."
        case .leo:
            return "A bold brand builder that commands market attention. This company leads with vision and isn't afraid to make dramatic moves."
        case .virgo:
            return "A meticulous optimizer focused on efficiency and quality. This company sweats the details that others overlook."
        case .libra:
            return "A partnership-oriented entity that thrives on collaboration. This company builds value through strategic alliances and fair dealing."
        case .scorpio:
            return "A transformative force that reinvents industries. This company operates with intensity and isn't afraid of creative destruction."
        case .sagittarius:
            return "An expansionist with global ambitions. This company thinks big, takes risks, and isn't satisfied with incremental growth."
        case .capricorn:
            return "A disciplined institution built for generational success. This company values tradition, hierarchy, and proven strategies."
        case .aquarius:
            return "A disruptor that challenges industry norms. This company prioritizes innovation and social impact over conventional metrics."
        case .pisces:
            return "An intuitive creator that operates on vision rather than spreadsheets. This company connects emotionally with its audience."
        }
    }
}

// MARK: - Usage Examples
// ======================
// Here's how to use the zodiac calculation in practice:

/*
 EXAMPLE 1: Get sign from a Date object
 --------------------------------------
 let birthday = Date() // or any date
 let sign = ZodiacSign.from(date: birthday)
 print(sign.displayName) // "Sagittarius"

 EXAMPLE 2: Get sign from month/day directly
 -------------------------------------------
 let sign = ZodiacSign.from(month: 7, day: 4) // July 4th
 print(sign.displayName) // "Cancer"
 print(sign.symbol)      // "♋"
 print(sign.element)     // .water

 EXAMPLE 3: Check element traits
 -------------------------------
 let sign = ZodiacSign.leo
 print(sign.element.sfSymbol)     // "flame.fill"
 print(sign.element.tradingStyle) // "Aggressive growth investing..."

 EXAMPLE 4: Check compatibility
 ------------------------------
 let mySign = ZodiacSign.aries
 let stockSign = ZodiacSign.leo
 if mySign.isCompatible(with: stockSign) {
     print("This stock aligns with your cosmic energy!")
 }
*/
