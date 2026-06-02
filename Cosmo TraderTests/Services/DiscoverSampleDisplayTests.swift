import Foundation
import Testing
@testable import Cosmo_Trader

struct DiscoverSampleDisplayTests {
    @Test("Sample Discover quote does not render as provider performance")
    func sampleDiscoverQuoteDoesNotRenderAsProviderPerformance() {
        let card = stockCard(
            percentageChange: 8.4,
            priceProvenance: .sample(reason: "Curated sample price")
        )

        #expect(card.priceMoveDisplay.label == "Sample quote")
        #expect(card.priceMoveDisplay.tone == .neutral)
        #expect(card.priceMoveDisplay.isProviderPerformance == false)
        #expect(!card.priceMoveDisplay.label.contains("%"))
    }

    @Test("Unavailable Discover quote does not render as provider performance")
    func unavailableDiscoverQuoteDoesNotRenderAsProviderPerformance() {
        let card = stockCard(
            percentageChange: -6.2,
            priceProvenance: .unavailable(reason: "Provider quote unavailable")
        )

        #expect(card.priceMoveDisplay.label == "Quote unavailable")
        #expect(card.priceMoveDisplay.tone == .neutral)
        #expect(card.priceMoveDisplay.isProviderPerformance == false)
        #expect(!card.priceMoveDisplay.label.contains("%"))
    }

    @Test("Provider-backed Discover quote can render percentage movement")
    func providerBackedDiscoverQuoteCanRenderPercentageMovement() {
        let card = stockCard(
            percentageChange: 2.4,
            priceProvenance: .live(provider: FinancialDataProvenance.finnhubProvider, fetchedAt: Date())
        )

        #expect(card.priceMoveDisplay.label == "+2.40%")
        #expect(card.priceMoveDisplay.tone == .positive)
        #expect(card.priceMoveDisplay.isProviderPerformance)
    }

    private func stockCard(
        percentageChange: Double,
        priceProvenance: FinancialDataProvenance
    ) -> StockCard {
        StockCard(
            stock: Stock(
                symbol: "TEST",
                name: "Test Holding",
                currentPrice: 100,
                priceChange: percentageChange,
                percentageChange: percentageChange,
                sharesOwned: 0,
                purchasePrice: 0,
                foundedDate: Date(),
                sector: "Technology"
            ),
            compatibility: CompatibilityResult(
                userSign: .leo,
                stockSign: .aries,
                score: 80,
                description: "Strong cosmic context.",
                advice: "Review as context only.",
                elementDynamic: "Fire plus fire."
            ),
            priceProvenance: priceProvenance
        )
    }
}
