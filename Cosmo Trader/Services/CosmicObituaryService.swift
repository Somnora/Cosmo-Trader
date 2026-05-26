import Foundation
import SwiftUI

// MARK: - Cosmic Obituary Service
// ================================
// When a stock gets delisted or goes bankrupt, generate a cosmic obituary.
//
// "FTX (Taurus, 2019-2022). Born stubborn, died stubborn. The bull
// refused to pivot. May its lessons compound eternally."
//
// WHY IT WORKS: Dark humor. Memorable. Educational. Shareable.

@MainActor
@Observable
final class CosmicObituaryService {

    // MARK: - Singleton

    static let shared = CosmicObituaryService()

    // MARK: - Storage Keys

    private enum StorageKeys {
        static let userObituaries = "cosmicObituary_userObituaries"
        static let viewedObituaries = "cosmicObituary_viewed"
    }

    // MARK: - State

    /// User's personal obituaries (stocks they held that died)
    private(set) var userObituaries: [CosmicObituary] = []

    /// Set of obituary IDs the user has viewed
    private var viewedObituaryIds: Set<String> = []

    /// Famous obituaries from market history
    private(set) var famousObituaries: [CosmicObituary] = []

    // MARK: - Initialization

    private init() {
        loadFromStorage()
        loadFamousObituaries()
    }

    // MARK: - Public Methods

    /// Generate an obituary for a delisted/bankrupt stock
    func generateObituary(
        symbol: String,
        name: String,
        zodiacSign: ZodiacSign,
        ipoYear: Int,
        deathYear: Int,
        causeOfDeath: CauseOfDeath,
        peakPrice: Double? = nil,
        finalPrice: Double? = nil
    ) -> CosmicObituary {
        let obituary = CosmicObituary(
            symbol: symbol,
            name: name,
            zodiacSign: zodiacSign,
            ipoYear: ipoYear,
            deathYear: deathYear,
            causeOfDeath: causeOfDeath,
            peakPrice: peakPrice,
            finalPrice: finalPrice,
            epitaph: generateEpitaph(sign: zodiacSign, cause: causeOfDeath),
            cosmicLesson: generateCosmicLesson(sign: zodiacSign, cause: causeOfDeath),
            eulogy: generateEulogy(name: name, sign: zodiacSign, cause: causeOfDeath, years: deathYear - ipoYear)
        )

        return obituary
    }

    /// Add a stock obituary to user's collection (when they held a stock that died)
    func addUserObituary(_ obituary: CosmicObituary) {
        guard !userObituaries.contains(where: { $0.symbol == obituary.symbol }) else { return }
        userObituaries.append(obituary)
        saveToStorage()

        AnalyticsService.shared.track(.cosmicObituaryAdded)
    }

    /// Mark an obituary as viewed
    func markAsViewed(_ obituary: CosmicObituary) {
        viewedObituaryIds.insert(obituary.id.uuidString)
        saveViewedIds()
    }

    /// Check if user has unviewed obituaries
    var hasUnviewedObituaries: Bool {
        userObituaries.contains { !viewedObituaryIds.contains($0.id.uuidString) }
    }

    /// Get all obituaries (user's + famous)
    var allObituaries: [CosmicObituary] {
        (userObituaries + famousObituaries).sorted { $0.deathYear > $1.deathYear }
    }

    // MARK: - Epitaph Generation

    private func generateEpitaph(sign: ZodiacSign, cause: CauseOfDeath) -> String {
        let signEpitaphs: [ZodiacSign: [String]] = [
            .aries: [
                "Charged ahead. Forgot to look.",
                "First to market, first to grave.",
                "The ram that ran off the cliff.",
                "Burned bright. Burned out."
            ],
            .taurus: [
                "Born stubborn, died stubborn.",
                "The bull refused to pivot.",
                "Held ground until ground gave way.",
                "Stable until it wasn't."
            ],
            .gemini: [
                "Two-faced until the end.",
                "Couldn't decide which way to fall.",
                "Talked a good game. Too good.",
                "The story changed. The ending didn't."
            ],
            .cancer: [
                "Retreated into its shell. Forever.",
                "Protected everyone except shareholders.",
                "Home is where the heart stopped.",
                "Nurtured dreams into nightmares."
            ],
            .leo: [
                "The spotlight found the cracks.",
                "Roared until the silence.",
                "Pride goeth before the delisting.",
                "The king is dead. Long live the lesson."
            ],
            .virgo: [
                "Perfected its own destruction.",
                "Analyzed everything except the obvious.",
                "Details perfect. Direction fatal.",
                "The spreadsheet was immaculate."
            ],
            .libra: [
                "Balanced until it tipped.",
                "Sought harmony. Found bankruptcy.",
                "Weighed options until options expired.",
                "Fair to all. Profitable to none."
            ],
            .scorpio: [
                "Secrets don't stay buried forever.",
                "Transformed into a cautionary tale.",
                "Stung itself in the end.",
                "Deep waters hide shallow graves."
            ],
            .sagittarius: [
                "Aimed for the stars. Hit rock bottom.",
                "The archer missed the target.",
                "Adventure ended at the courthouse.",
                "Optimism without execution."
            ],
            .capricorn: [
                "Built an empire on sand.",
                "Climbed the wrong mountain.",
                "Discipline couldn't save it.",
                "The goat reached the peak. It was a cliff."
            ],
            .aquarius: [
                "Too far ahead of its time.",
                "Revolutionary. Until the revolution failed.",
                "Disrupted itself into oblivion.",
                "The future arrived. It wasn't invited."
            ],
            .pisces: [
                "Dreamed too deeply to wake.",
                "Swam against the current. Drowned.",
                "Intuition forgot about math.",
                "The vision was clear. The execution murky."
            ]
        ]

        let causeModifiers: [CauseOfDeath: String] = [
            .fraud: "Truth eventually surfaces.",
            .bankruptcy: "The numbers never lie for long.",
            .acquisition: "Consumed by a bigger fish.",
            .delisting: "Fell below the line. Stayed there.",
            .regulatoryAction: "The rules caught up.",
            .marketConditions: "Wrong place. Wrong time. Wrong stock."
        ]

        var epitaphs = signEpitaphs[sign] ?? ["Gone but not forgotten."]
        if let modifier = causeModifiers[cause], Bool.random() {
            epitaphs.append(modifier)
        }

        return epitaphs.randomElement() ?? "May its lessons compound eternally."
    }

    private func generateCosmicLesson(sign: ZodiacSign, cause: CauseOfDeath) -> String {
        let lessons: [ZodiacSign: [String]] = [
            .aries: [
                "Speed without direction is just chaos.",
                "First-mover advantage requires actually moving somewhere.",
                "Courage is not a substitute for due diligence."
            ],
            .taurus: [
                "Stubbornness is not the same as conviction.",
                "Even bulls need to know when to retreat.",
                "Stability requires a foundation, not just inertia."
            ],
            .gemini: [
                "Communication only works if it's honest.",
                "Versatility without integrity is manipulation.",
                "Two stories can't both be true forever."
            ],
            .cancer: [
                "Protecting the past can prevent the future.",
                "Emotional attachment clouds financial judgment.",
                "Not every loss is a lesson in holding on."
            ],
            .leo: [
                "Confidence without competence is dangerous.",
                "The spotlight reveals flaws as well as glory.",
                "Leadership means accepting responsibility."
            ],
            .virgo: [
                "Perfect execution of the wrong strategy is still failure.",
                "Analysis paralysis kills as surely as recklessness.",
                "The devil is in the details, but so is the exit."
            ],
            .libra: [
                "Seeking balance can mean standing for nothing.",
                "Fairness doesn't guarantee survival.",
                "Partnerships require more than good intentions."
            ],
            .scorpio: [
                "What's hidden eventually surfaces.",
                "Intensity without transparency breeds suspicion.",
                "Transformation requires survival first."
            ],
            .sagittarius: [
                "Optimism needs a reality check sometimes.",
                "The journey matters, but so does the destination.",
                "Philosophy doesn't pay the bills."
            ],
            .capricorn: [
                "Climbing the wrong ladder gets you nowhere good.",
                "Discipline applied to the wrong goals compounds losses.",
                "Not every mountain is worth climbing."
            ],
            .aquarius: [
                "Being ahead of your time can mean dying before it arrives.",
                "Innovation without adoption is just invention.",
                "The world isn't always ready for what you're selling."
            ],
            .pisces: [
                "Dreams require execution to become reality.",
                "Intuition is not a business plan.",
                "Imagination without grounding floats away."
            ]
        ]

        return lessons[sign]?.randomElement() ?? "Every ending teaches something."
    }

    private func generateEulogy(name: String, sign: ZodiacSign, cause: CauseOfDeath, years: Int) -> String {
        let lifespan = years == 1 ? "1 year" : "\(years) years"

        let causeText: String
        switch cause {
        case .fraud:
            causeText = "succumbed to its own deceptions"
        case .bankruptcy:
            causeText = "ran out of runway and excuses"
        case .acquisition:
            causeText = "was absorbed into the corporate beyond"
        case .delisting:
            causeText = "faded from the exchange into memory"
        case .regulatoryAction:
            causeText = "was claimed by the regulatory reaper"
        case .marketConditions:
            causeText = "was swept away by market tides"
        }

        let signTrait = sign.corporatePersonality.components(separatedBy: ".").first ?? "a memorable presence"

        return "After \(lifespan) of trading, \(name) \(causeText). Known for being \(signTrait.lowercased()), it leaves behind lessons for all who witnessed its journey. A \(sign.displayName) to the end."
    }

    // MARK: - Famous Obituaries

    private func loadFamousObituaries() {
        famousObituaries = [
            CosmicObituary(
                symbol: "FTX",
                name: "FTX Trading",
                zodiacSign: .taurus,
                ipoYear: 2019,
                deathYear: 2022,
                causeOfDeath: .fraud,
                peakPrice: nil,
                finalPrice: 0,
                epitaph: "Born stubborn, died stubborn. The bull refused to pivot.",
                cosmicLesson: "Trust, but verify. Then verify again.",
                eulogy: "FTX rose like a Taurus — steadily, confidently, with an air of inevitability. It fell the same way, refusing to acknowledge reality until reality acknowledged it with handcuffs. May its lessons compound eternally."
            ),
            CosmicObituary(
                symbol: "ENRON",
                name: "Enron Corporation",
                zodiacSign: .scorpio,
                ipoYear: 1985,
                deathYear: 2001,
                causeOfDeath: .fraud,
                peakPrice: 90.75,
                finalPrice: 0.26,
                epitaph: "Secrets don't stay buried forever.",
                cosmicLesson: "Complexity is often a disguise for deception.",
                eulogy: "The Scorpio of energy trading, Enron mastered the art of hidden depths. Those depths turned out to be a bottomless pit of fraud. From $90 to pennies, it taught a generation that if you can't explain how a company makes money, maybe it doesn't."
            ),
            CosmicObituary(
                symbol: "LHMN",
                name: "Lehman Brothers",
                zodiacSign: .capricorn,
                ipoYear: 1850,
                deathYear: 2008,
                causeOfDeath: .bankruptcy,
                peakPrice: 86.18,
                finalPrice: 0.03,
                epitaph: "Climbed the wrong mountain.",
                cosmicLesson: "158 years of reputation can vanish in 158 hours.",
                eulogy: "The mountain goat of Wall Street, Lehman Brothers spent over a century climbing to the top. It chose to build its peak on subprime mortgages. The fall was as Capricorn as the climb — methodical, inevitable, and devastating."
            ),
            CosmicObituary(
                symbol: "WCOM",
                name: "WorldCom",
                zodiacSign: .gemini,
                ipoYear: 1983,
                deathYear: 2002,
                causeOfDeath: .fraud,
                peakPrice: 64.50,
                finalPrice: 0.06,
                epitaph: "The story changed. The ending didn't.",
                cosmicLesson: "$11 billion in accounting fraud is still fraud.",
                eulogy: "WorldCom talked its way to telecom dominance, a true Gemini spinning narratives faster than fiber optic cables. When the stories unraveled, so did $180 billion in market cap. The twin faces of growth and fraud were the same face all along."
            ),
            CosmicObituary(
                symbol: "BKRPT",
                name: "Blockbuster",
                zodiacSign: .taurus,
                ipoYear: 1985,
                deathYear: 2010,
                causeOfDeath: .bankruptcy,
                peakPrice: 30.00,
                finalPrice: 0.01,
                epitaph: "Held ground until ground gave way.",
                cosmicLesson: "Stability is not a strategy when the world is changing.",
                eulogy: "The bull of video rental stood firm as the streaming tsunami approached. Taurus energy at its finest — and worst. It passed on buying Netflix for $50 million, choosing instead to die with 9,000 stores of conviction."
            ),
            CosmicObituary(
                symbol: "THRQ",
                name: "Theranos",
                zodiacSign: .aquarius,
                ipoYear: 2003,
                deathYear: 2018,
                causeOfDeath: .fraud,
                peakPrice: nil,
                finalPrice: 0,
                epitaph: "Too far ahead of its time. Because it didn't exist.",
                cosmicLesson: "Disruption requires something to actually disrupt with.",
                eulogy: "The most Aquarian of all frauds — selling a future that was technologically impossible. Elizabeth Holmes channeled water-bearer energy: visionary, detached from reality, convinced the universe would bend to her will. It didn't."
            ),
            CosmicObituary(
                symbol: "PETS",
                name: "Pets.com",
                zodiacSign: .aries,
                ipoYear: 2000,
                deathYear: 2000,
                causeOfDeath: .bankruptcy,
                peakPrice: 14.00,
                finalPrice: 0.19,
                epitaph: "Charged ahead. Forgot to look.",
                cosmicLesson: "First-mover advantage requires actually surviving.",
                eulogy: "The ram of the dot-com era, Pets.com charged into the internet with Super Bowl ads and a sock puppet. 268 days from IPO to liquidation — a speed run through the corporate lifecycle. The Aries died as it lived: fast, bold, and broke."
            ),
            CosmicObituary(
                symbol: "BS",
                name: "Bear Stearns",
                zodiacSign: .aries,
                ipoYear: 1985,
                deathYear: 2008,
                causeOfDeath: .acquisition,
                peakPrice: 172.69,
                finalPrice: 10.00,
                epitaph: "The bear became prey.",
                cosmicLesson: "Even predators can become victims.",
                eulogy: "From $172 to $2 (eventually $10) in days. Bear Stearns charged through 85 years of markets, an Aries institution of aggression and risk. When the mortgage crisis attacked, the ram discovered that sometimes the bear gets hunted."
            ),
            CosmicObituary(
                symbol: "LUNA",
                name: "Terra Luna",
                zodiacSign: .pisces,
                ipoYear: 2019,
                deathYear: 2022,
                causeOfDeath: .marketConditions,
                peakPrice: 119.18,
                finalPrice: 0.0001,
                epitaph: "Dreamed too deeply to wake.",
                cosmicLesson: "Algorithmic stability is still just an algorithm.",
                eulogy: "The Pisces of crypto dreamed of a stablecoin utopia. $40 billion in market cap evaporated in 72 hours when the dream became a death spiral. Luna's descent was as poetic as its name — beautiful, inevitable, and utterly devastating."
            ),
            CosmicObituary(
                symbol: "NOK",
                name: "Nokia (Mobile Division)",
                zodiacSign: .cancer,
                ipoYear: 1998,
                deathYear: 2014,
                causeOfDeath: .acquisition,
                peakPrice: 62.50,
                finalPrice: 7.17,
                epitaph: "Protected everyone except shareholders.",
                cosmicLesson: "Nurturing the past kills the future.",
                eulogy: "The Cancer of mobile phones clung to its shell of Symbian as the smartphone tsunami approached. Nokia nurtured its legacy until Microsoft put it out of its misery. The phone that connected the world couldn't connect to the future."
            ),
        ]
    }

    // MARK: - Persistence

    private func saveToStorage() {
        if let data = try? JSONEncoder().encode(userObituaries) {
            UserDefaults.standard.set(data, forKey: StorageKeys.userObituaries)
        }
    }

    private func loadFromStorage() {
        if let data = UserDefaults.standard.data(forKey: StorageKeys.userObituaries),
           let obituaries = try? JSONDecoder().decode([CosmicObituary].self, from: data) {
            userObituaries = obituaries
        }

        if let viewedIds = UserDefaults.standard.array(forKey: StorageKeys.viewedObituaries) as? [String] {
            viewedObituaryIds = Set(viewedIds)
        }
    }

    private func saveViewedIds() {
        UserDefaults.standard.set(Array(viewedObituaryIds), forKey: StorageKeys.viewedObituaries)
    }
}

// MARK: - Cosmic Obituary Model

struct CosmicObituary: Identifiable, Codable {
    let id: UUID
    let symbol: String
    let name: String
    let zodiacSign: ZodiacSign
    let ipoYear: Int
    let deathYear: Int
    let causeOfDeath: CauseOfDeath
    let peakPrice: Double?
    let finalPrice: Double?
    let epitaph: String
    let cosmicLesson: String
    let eulogy: String
    let dateAdded: Date

    init(
        id: UUID = UUID(),
        symbol: String,
        name: String,
        zodiacSign: ZodiacSign,
        ipoYear: Int,
        deathYear: Int,
        causeOfDeath: CauseOfDeath,
        peakPrice: Double?,
        finalPrice: Double?,
        epitaph: String,
        cosmicLesson: String,
        eulogy: String,
        dateAdded: Date = Date()
    ) {
        self.id = id
        self.symbol = symbol
        self.name = name
        self.zodiacSign = zodiacSign
        self.ipoYear = ipoYear
        self.deathYear = deathYear
        self.causeOfDeath = causeOfDeath
        self.peakPrice = peakPrice
        self.finalPrice = finalPrice
        self.epitaph = epitaph
        self.cosmicLesson = cosmicLesson
        self.eulogy = eulogy
        self.dateAdded = dateAdded
    }

    /// Lifespan in years
    var lifespanYears: Int {
        deathYear - ipoYear
    }

    /// Formatted lifespan
    var formattedLifespan: String {
        "\(ipoYear)-\(deathYear)"
    }

    /// Percentage loss from peak (if available)
    var percentageLoss: Double? {
        guard let peak = peakPrice, let final = finalPrice, peak > 0 else { return nil }
        return ((peak - final) / peak) * 100
    }

    /// Shareable text
    var shareableText: String {
        """
        ⚰️ COSMIC OBITUARY

        \(symbol) (\(zodiacSign.textSymbol) \(zodiacSign.displayName), \(formattedLifespan))

        "\(epitaph)"

        \(eulogy)

        Cosmic Lesson: \(cosmicLesson)

        — Cosmo Trader 🌙
        """
    }

    /// Short format for cards
    var shortFormat: String {
        "\(symbol) (\(zodiacSign.displayName), \(formattedLifespan)). \(epitaph)"
    }
}

// MARK: - Cause of Death

enum CauseOfDeath: String, Codable, CaseIterable {
    case fraud = "Fraud"
    case bankruptcy = "Bankruptcy"
    case acquisition = "Acquired"
    case delisting = "Delisted"
    case regulatoryAction = "Regulatory Action"
    case marketConditions = "Market Conditions"

    var icon: String {
        switch self {
        case .fraud: return "eye.slash.fill"
        case .bankruptcy: return "dollarsign.circle.fill"
        case .acquisition: return "arrow.triangle.merge"
        case .delisting: return "xmark.circle.fill"
        case .regulatoryAction: return "building.columns.fill"
        case .marketConditions: return "chart.line.downtrend.xyaxis"
        }
    }

    var color: Color {
        switch self {
        case .fraud: return .red
        case .bankruptcy: return .orange
        case .acquisition: return .purple
        case .delisting: return .gray
        case .regulatoryAction: return .blue
        case .marketConditions: return .yellow
        }
    }
}
