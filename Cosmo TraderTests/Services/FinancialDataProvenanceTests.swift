import Foundation
import Testing
@testable import Cosmo_Trader

struct FinancialDataProvenanceTests {

    @Test("Cached provenance records provider, timestamp, and age")
    func cachedProvenanceTracksFreshness() {
        let fetchedAt = Date(timeIntervalSince1970: 1_000)
        let now = Date(timeIntervalSince1970: 1_120)
        let provenance = FinancialDataProvenance.cached(
            provider: FinancialDataProvenance.finnhubProvider,
            fetchedAt: fetchedAt,
            now: now
        )

        #expect(provenance.isProviderBacked)
        #expect(provenance.isCached)
        #expect(provenance.provider == "Finnhub")
        #expect(provenance.fetchedAt == fetchedAt)

        if case .cached(_, _, let age) = provenance {
            #expect(age == 120)
        } else {
            Issue.record("Expected cached provenance")
        }
    }

    @Test("Mixed provenance is not treated as pure provider-backed data")
    func mixedProvenanceLabelsDerivedFields() {
        let provenance = FinancialDataProvenance.mixed(reason: "Portfolio values combine live and stored quote fields")

        #expect(!provenance.isProviderBacked)
        #expect(!provenance.isCached)
        #expect(provenance.provider == nil)
        #expect(provenance.fetchedAt == nil)
        #expect(provenance.shortLabel == "Mixed")
        #expect(provenance.indicatorLabel == "Mixed data")
    }

    @Test("Unavailable key stats stay unavailable and carry field-level reasons")
    func stockKeyStatsUnavailableFieldsAreExplicit() {
        let unavailable = FinancialDataProvenance.unavailable(reason: "Provider fundamentals unavailable")
        let stats = StockKeyStats(
            open: nil,
            dayHigh: nil,
            dayLow: nil,
            volume: nil,
            avgVolume: nil,
            marketCap: nil,
            peRatio: nil,
            weekHigh52: nil,
            weekLow52: nil,
            dividendYield: nil,
            fieldProvenance: [.marketCap: unavailable]
        )

        #expect(!stats.hasAnyAvailableField)
        #expect(stats.formattedOpen == "Unavailable")
        #expect(stats.formattedMarketCap == "Unavailable")
        #expect(stats.formattedVolume == "Unavailable")
        #expect(stats.provenance(for: .marketCap) == unavailable)
        #expect(stats.provenance(for: .open) == .unavailable(reason: "Provider field unavailable"))
    }

    @Test("Finnhub basic financials decoding tolerates sparse metric payloads")
    func basicFinancialsDecoderIgnoresNullMetrics() throws {
        let json = """
        {
          "metric": {
            "marketCapitalization": 2850.5,
            "peBasicExclExtraTTM": null,
            "52WeekHigh": "199.62",
            "employeeTotal": 161000
          }
        }
        """.data(using: .utf8)!

        let decoded = try JSONDecoder().decode(FinnhubBasicFinancialsResponse.self, from: json)

        #expect(decoded.metric["marketCapitalization"] == 2850.5)
        #expect(decoded.metric["52WeekHigh"] == 199.62)
        #expect(decoded.metric["employeeTotal"] == 161_000)
        #expect(decoded.metric["peBasicExclExtraTTM"] == nil)
    }

    @MainActor
    @Test("Calendar services start as unavailable instead of sample data")
    func calendarServicesStartUnavailableWithoutCache() {
        let ipoService = IPOService.testingInstance(loadCache: false)
        let earningsService = EarningsService.testingInstance(loadCache: false)

        #expect(ipoService.dataProvenance == .unavailable(reason: "IPO calendar unavailable"))
        #expect(earningsService.dataProvenance == .unavailable(reason: "Earnings calendar unavailable"))
    }

    @MainActor
    @Test("Search service labels idle search as unavailable")
    func searchServiceStartsWithExplicitUnavailableProvenance() {
        let service = SearchService.shared
        service.clearSearch()

        #expect(service.dataProvenance == .unavailable(reason: "Enter a symbol or company name to search Finnhub"))
    }
}
