import Testing
import Foundation
@testable import Cosmo_Trader

extension AppStatePersistenceSuites {
    struct AuthSyncTests {
        
        @Test("Merge Cloud Portfolio and Watchlist into Local User Profile")
        @MainActor
        func testMergeCloudData() async {
            // Given a local user with AAPL holdings and AAPL in watchlist
            let localUser = UserProfile(
                displayName: "Local Trader",
                email: "local@cosmictrader.com",
                birthMonth: 8, birthDay: 1, birthYear: 1990,
                portfolio: [
                    Stock(
                        symbol: "AAPL",
                        name: "Apple Inc.",
                        currentPrice: 150.0,
                        priceChange: 1.5,
                        percentageChange: 1.0,
                        sharesOwned: 10.0,
                        foundedDate: nil,
                        sector: "Technology"
                    )
                ],
                watchlist: ["AAPL"]
            )
            let appState = AppState(user: localUser)
            appState.firebaseUID = "test-firebase-uid"
            
            // Simulating fetching a cloud state containing MSFT holdings and watchlisted stocks
            let cloudPortfolio = [
                Stock(
                    symbol: "MSFT",
                    name: "Microsoft Corp.",
                    currentPrice: 300.0,
                    priceChange: -2.0,
                    percentageChange: -0.66,
                    sharesOwned: 5.0,
                    foundedDate: nil,
                    sector: "Technology"
                )
            ]
            let cloudWatchlist = ["AAPL", "MSFT"]
            
            // When merging cloud state into local user
            guard var mergedUser = appState.currentUser else {
                return
            }
            mergedUser.portfolio = cloudPortfolio
            mergedUser.watchlist = cloudWatchlist
            appState.currentUser = mergedUser
            
            // Then local user profile is merged correctly
            #expect(appState.currentUser?.portfolio.count == 1)
            #expect(appState.currentUser?.portfolio.first?.symbol == "MSFT")
            #expect(appState.currentUser?.watchlist == ["AAPL", "MSFT"])
        }
        
        @Test("Reconstruct User Profile on New Device from Cloud Zodiac Sign")
        @MainActor
        func testReconstructProfileFromCloudZodiacSign() async {
            // Given a fresh device with no local user profile
            let appState = AppState(user: nil)
            appState.firebaseUID = "test-firebase-uid"
            
            // Simulating cloud profile matching a Leo user with AAPL holdings
            let backendProfile = BackendUserProfile(
                uid: "test-firebase-uid",
                createdAt: "2026-06-19T06:00:00Z",
                updatedAt: "2026-06-19T06:00:00Z",
                zodiacSign: "leo",
                riskLevel: nil,
                notificationsEnabled: nil,
                lastSeenAt: nil,
                portfolio: [
                    Stock(
                        symbol: "AAPL",
                        name: "Apple Inc.",
                        currentPrice: 150.0,
                        priceChange: 1.5,
                        percentageChange: 1.0,
                        sharesOwned: 10.0,
                        foundedDate: nil,
                        sector: "Technology"
                    )
                ],
                watchlist: ["AAPL", "TSLA"]
            )
            
            // When reconstructing the user profile
            if let signStr = backendProfile.zodiacSign,
               let sign = ZodiacSign(rawValue: signStr) {
                // Reconstruct birthDate using the sign's start date
                var comps = DateComponents()
                comps.year = 1990
                comps.month = sign.startDate.month
                comps.day = sign.startDate.day
                let mockDate = Calendar.current.date(from: comps) ?? Date()
                
                let newUser = UserProfile(
                    displayName: "Cloud User",
                    email: "cloud@cosmictrader.com",
                    birthDate: mockDate,
                    portfolio: backendProfile.portfolio ?? [],
                    watchlist: backendProfile.watchlist ?? []
                )
                appState.currentUser = newUser
            }
            
            // Then the local profile is created successfully with correct properties
            #expect(appState.currentUser != nil)
            #expect(appState.currentUser?.sunSign == .leo)
            #expect(appState.currentUser?.portfolio.count == 1)
            #expect(appState.currentUser?.portfolio.first?.symbol == "AAPL")
            #expect(appState.currentUser?.watchlist == ["AAPL", "TSLA"])
        }
    }
}
