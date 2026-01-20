import Foundation
import SwiftUI

// MARK: - Referral Service
// =========================
// Handles referral code generation, tracking, and rewards.
// Currently stores data locally. Ready for backend integration.

@MainActor
@Observable
final class ReferralService {

    // MARK: - Singleton

    static let shared = ReferralService()

    // MARK: - Storage Keys

    private enum StorageKeys {
        static let myReferralCode = "referral_myCode"
        static let usedReferralCode = "referral_usedCode"
        static let referredUsers = "referral_referredUsers"
        static let earnedRewardDays = "referral_earnedRewardDays"
        static let redeemedRewardDays = "referral_redeemedRewardDays"
    }

    // MARK: - Properties

    /// The current user's unique referral code
    private(set) var myReferralCode: String = ""

    /// The referral code this user signed up with (if any)
    private(set) var usedReferralCode: String?

    /// List of users this user has referred (stored as codes/identifiers)
    private(set) var referredUsers: [ReferredUser] = []

    /// Total reward days earned from referrals
    private(set) var earnedRewardDays: Int = 0

    /// Reward days already applied/redeemed
    private(set) var redeemedRewardDays: Int = 0

    // MARK: - Constants

    /// Days of free Oracle Tier per successful referral
    static let rewardDaysPerReferral = 7

    /// Maximum stackable reward days (1 year)
    static let maxRewardDays = 365

    // MARK: - Computed Properties

    /// Number of successful referrals
    var referralCount: Int {
        referredUsers.count
    }

    /// Available reward days (earned but not yet redeemed)
    var availableRewardDays: Int {
        max(0, earnedRewardDays - redeemedRewardDays)
    }

    /// Whether user has pending rewards to claim
    var hasPendingRewards: Bool {
        availableRewardDays > 0
    }

    /// Formatted referral count text
    var referralCountText: String {
        switch referralCount {
        case 0:
            return "No referrals yet"
        case 1:
            return "1 cosmic traveler recruited"
        default:
            return "\(referralCount) cosmic travelers recruited"
        }
    }

    // MARK: - Initialization

    private init() {
        loadFromStorage()
        if myReferralCode.isEmpty {
            myReferralCode = generateReferralCode()
            saveToStorage()
        }
    }

    // MARK: - Code Generation

    /// Generate a unique referral code for the user
    func generateReferralCode(forName name: String? = nil) -> String {
        if let name = name, !name.isEmpty {
            // Use name-based code: JAMES-COSMOS or SARAH-STARS
            let cleanName = name
                .uppercased()
                .components(separatedBy: .whitespaces).first ?? "USER"
            let suffixes = ["COSMOS", "STARS", "LUNAR", "ASTRO", "ORBIT"]
            let suffix = suffixes.randomElement() ?? "COSMOS"
            let code = "\(cleanName)-\(suffix)"

            // Add random digits if needed for uniqueness
            let randomDigits = String(format: "%03d", Int.random(in: 0...999))
            return "\(code)-\(randomDigits)"
        } else {
            // Generate random code: CT-XXXXXX
            let characters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
            let randomPart = String((0..<6).map { _ in characters.randomElement()! })
            return "CT-\(randomPart)"
        }
    }

    /// Regenerate the user's referral code with their name
    func regenerateCode(withName name: String) {
        myReferralCode = generateReferralCode(forName: name)
        saveToStorage()
    }

    // MARK: - Referral Application

    /// Apply a referral code during signup
    /// Returns success/failure with message
    func applyReferralCode(_ code: String) -> ReferralResult {
        let cleanCode = code.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()

        // Validation
        guard !cleanCode.isEmpty else {
            return .failure("Please enter a referral code")
        }

        guard cleanCode != myReferralCode else {
            return .failure("You can't use your own referral code")
        }

        guard usedReferralCode == nil else {
            return .failure("You've already used a referral code")
        }

        // Validate code format (basic check)
        guard isValidCodeFormat(cleanCode) else {
            return .failure("Invalid referral code format")
        }

        // Apply the code
        usedReferralCode = cleanCode

        // Award the new user their bonus
        earnedRewardDays = min(earnedRewardDays + Self.rewardDaysPerReferral, Self.maxRewardDays)

        saveToStorage()

        // Track analytics
        AnalyticsService.shared.track(.referralCodeUsed, params: AnalyticsParameters([
            "code": cleanCode
        ]))

        return .success("Welcome! You've earned \(Self.rewardDaysPerReferral) days of Oracle Tier!")
    }

    /// Record that someone used our referral code
    /// Called when backend confirms a referral (or simulated locally)
    func recordReferral(userIdentifier: String, date: Date = Date()) {
        let referredUser = ReferredUser(
            identifier: userIdentifier,
            date: date
        )

        // Check for duplicates
        guard !referredUsers.contains(where: { $0.identifier == userIdentifier }) else {
            return
        }

        referredUsers.append(referredUser)

        // Award referrer bonus
        earnedRewardDays = min(earnedRewardDays + Self.rewardDaysPerReferral, Self.maxRewardDays)

        saveToStorage()

        // Track analytics
        AnalyticsService.shared.track(.referralCompleted, params: AnalyticsParameters([
            "total_referrals": referralCount
        ]))
    }

    /// Redeem available reward days (apply to subscription)
    func redeemRewardDays(_ days: Int) -> Bool {
        guard days > 0, days <= availableRewardDays else {
            return false
        }

        redeemedRewardDays += days
        saveToStorage()

        // Extend the user's trial/subscription with the referral reward
        SubscriptionManager.shared.extendTrial(byDays: days)

        AnalyticsService.shared.track(.referralRewardRedeemed, params: AnalyticsParameters([
            "days_redeemed": days
        ]))

        return true
    }

    // MARK: - Validation

    private func isValidCodeFormat(_ code: String) -> Bool {
        // Valid formats: CT-XXXXXX or NAME-SUFFIX-XXX
        let ctPattern = "^CT-[A-Z0-9]{6}$"
        let namePattern = "^[A-Z]+-[A-Z]+-[0-9]{3}$"

        let ctRegex = try? NSRegularExpression(pattern: ctPattern)
        let nameRegex = try? NSRegularExpression(pattern: namePattern)

        let range = NSRange(code.startIndex..., in: code)

        let ctMatch = ctRegex?.firstMatch(in: code, range: range) != nil
        let nameMatch = nameRegex?.firstMatch(in: code, range: range) != nil

        return ctMatch || nameMatch
    }

    // MARK: - Share Text

    /// Generate share text for inviting friends
    func generateShareText(appStoreLink: String = "[App Store Link]") -> String {
        """
        I'm tracking my portfolio with the stars on Cosmo Trader ✨

        It assigns zodiac signs to stocks and tells you your cosmic compatibility. Plus you can get roasted by the universe.

        Use my code \(myReferralCode) for a free week of Oracle Tier!

        \(appStoreLink)
        """
    }

    // MARK: - Persistence

    private func saveToStorage() {
        let defaults = UserDefaults.standard
        defaults.set(myReferralCode, forKey: StorageKeys.myReferralCode)
        defaults.set(usedReferralCode, forKey: StorageKeys.usedReferralCode)
        defaults.set(earnedRewardDays, forKey: StorageKeys.earnedRewardDays)
        defaults.set(redeemedRewardDays, forKey: StorageKeys.redeemedRewardDays)

        // Encode referred users
        if let encoded = try? JSONEncoder().encode(referredUsers) {
            defaults.set(encoded, forKey: StorageKeys.referredUsers)
        }
    }

    private func loadFromStorage() {
        let defaults = UserDefaults.standard
        myReferralCode = defaults.string(forKey: StorageKeys.myReferralCode) ?? ""
        usedReferralCode = defaults.string(forKey: StorageKeys.usedReferralCode)
        earnedRewardDays = defaults.integer(forKey: StorageKeys.earnedRewardDays)
        redeemedRewardDays = defaults.integer(forKey: StorageKeys.redeemedRewardDays)

        // Decode referred users
        if let data = defaults.data(forKey: StorageKeys.referredUsers),
           let decoded = try? JSONDecoder().decode([ReferredUser].self, from: data) {
            referredUsers = decoded
        }
    }

    // MARK: - Debug/Testing

    #if DEBUG
    func simulateReferral() {
        let fakeId = "user_\(Int.random(in: 1000...9999))"
        recordReferral(userIdentifier: fakeId)
    }

    func resetReferralData() {
        myReferralCode = generateReferralCode()
        usedReferralCode = nil
        referredUsers = []
        earnedRewardDays = 0
        redeemedRewardDays = 0
        saveToStorage()
    }
    #endif
}

// MARK: - Supporting Types

struct ReferredUser: Codable, Identifiable {
    let id: UUID
    let identifier: String
    let date: Date

    init(identifier: String, date: Date = Date()) {
        self.id = UUID()
        self.identifier = identifier
        self.date = date
    }

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }

    /// Anonymized display (first 4 chars + ****)
    var anonymizedIdentifier: String {
        let prefix = String(identifier.prefix(4))
        return "\(prefix)****"
    }
}

enum ReferralResult {
    case success(String)
    case failure(String)

    var isSuccess: Bool {
        if case .success = self { return true }
        return false
    }

    var message: String {
        switch self {
        case .success(let msg), .failure(let msg):
            return msg
        }
    }
}

// MARK: - Leaderboard (Mock Data for Now)

struct ReferralLeaderboard {

    struct LeaderboardEntry: Identifiable {
        let id = UUID()
        let rank: Int
        let anonymizedName: String
        let referralCount: Int
        let zodiacSign: ZodiacSign

        var badge: String {
            switch rank {
            case 1: return "🥇"
            case 2: return "🥈"
            case 3: return "🥉"
            default: return "⭐"
            }
        }
    }

    /// Mock leaderboard data (would come from backend in production)
    static let mockTopRecruiters: [LeaderboardEntry] = [
        LeaderboardEntry(rank: 1, anonymizedName: "Cosmic****", referralCount: 47, zodiacSign: .leo),
        LeaderboardEntry(rank: 2, anonymizedName: "Star_****", referralCount: 38, zodiacSign: .sagittarius),
        LeaderboardEntry(rank: 3, anonymizedName: "Luna****", referralCount: 31, zodiacSign: .cancer),
        LeaderboardEntry(rank: 4, anonymizedName: "Astro****", referralCount: 24, zodiacSign: .aquarius),
        LeaderboardEntry(rank: 5, anonymizedName: "Orbit****", referralCount: 19, zodiacSign: .aries),
        LeaderboardEntry(rank: 6, anonymizedName: "Nebul****", referralCount: 15, zodiacSign: .pisces),
        LeaderboardEntry(rank: 7, anonymizedName: "Solar****", referralCount: 12, zodiacSign: .virgo),
        LeaderboardEntry(rank: 8, anonymizedName: "Comet****", referralCount: 9, zodiacSign: .gemini),
        LeaderboardEntry(rank: 9, anonymizedName: "Galax****", referralCount: 7, zodiacSign: .scorpio),
        LeaderboardEntry(rank: 10, anonymizedName: "Plane****", referralCount: 5, zodiacSign: .taurus),
    ]
}
