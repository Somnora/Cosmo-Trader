#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

failures=0

require_absent() {
  local file="$1"
  local needle="$2"
  if grep -Fq "$needle" "$ROOT/$file"; then
    echo "FAIL: '$needle' is still present in $file"
    failures=$((failures + 1))
  fi
}

require_present() {
  local file="$1"
  local needle="$2"
  if ! grep -Fq "$needle" "$ROOT/$file"; then
    echo "FAIL: '$needle' is missing from $file"
    failures=$((failures + 1))
  fi
}

require_file_absent() {
  local file="$1"
  if [[ -e "$ROOT/$file" ]]; then
    echo "FAIL: legacy file should not exist: $file"
    failures=$((failures + 1))
  fi
}

require_absent "Cosmo Trader/Views/Components/StockChartView.swift" "stock.chartData(for:"
require_present "Cosmo Trader/Views/Components/StockChartView.swift" "Historical price data unavailable"
require_present "Cosmo Trader/Views/Components/StockChartView.swift" "Key statistics unavailable"

require_absent "Cosmo Trader/Views/StockDetailView.swift" "generateMockChartData"
require_absent "Cosmo Trader/Views/StockDetailView.swift" "MiniChartView.sampleData"
require_absent "Cosmo Trader/Views/StockDetailView.swift" "formatted52Week"
require_absent "Cosmo Trader/Views/StockDetailView.swift" "stock.formattedMarketCap"
require_present "Cosmo Trader/Views/StockDetailView.swift" "DataSourceIndicator(provenance: priceProvenance"
require_present "Cosmo Trader/Views/StockDetailView.swift" "Fundamentals such as market cap"

require_absent "Cosmo Trader/Services/ChartPatternService.swift" "MockOHLCGenerator.generate"
require_present "Cosmo Trader/Services/ChartPatternService.swift" "pattern analysis unavailable"

require_absent "Cosmo Trader/Services/IPOService.swift" "MockIPOData"
require_absent "Cosmo Trader/Services/IPOService.swift" "loadMockData"
require_present "Cosmo Trader/Services/IPOService.swift" "dataProvenance"
require_present "Cosmo Trader/Views/IPO/IPOListView.swift" "DataSourceIndicator(provenance: ipoService.dataProvenance"

require_absent "Cosmo Trader/Services/EarningsService.swift" "generateMockEarningsData"
require_absent "Cosmo Trader/Services/EarningsService.swift" "Double.random"
require_present "Cosmo Trader/Services/EarningsService.swift" "dataProvenance"
require_present "Cosmo Trader/Views/Components/EarningsViews.swift" "DataSourceIndicator(provenance: earningsService.dataProvenance"

require_absent "Cosmo Trader/Views/Components/PortfolioChartView.swift" "generatePortfolioData"
require_absent "Cosmo Trader/Views/Components/PortfolioChartView.swift" "generateBenchmarkData"
require_present "Cosmo Trader/Views/Components/PortfolioChartView.swift" "Portfolio performance history unavailable"

require_absent "Cosmo Trader/Services/CosmicMoodService.swift" "simulateWeeklyReturn"
require_absent "Cosmo Trader/Services/CosmicMoodService.swift" "generateMockHistory"
require_present "Cosmo Trader/Services/CosmicMoodService.swift" "Provider-backed market trend unavailable"
require_present "Cosmo Trader/Services/CosmicMoodService.swift" "minimumMarketCoverageForScore"
# CosmicMoodData must publish enough metadata for consumers to refuse to
# quote a cosmic-only score as a market measurement.
require_present "Cosmo Trader/Models/CosmicMoodIndex.swift" "enum CosmicMoodDisplayMode"
require_present "Cosmo Trader/Models/CosmicMoodIndex.swift" "marketDataCoverage"
require_present "Cosmo Trader/Models/CosmicMoodIndex.swift" "var isMarketBacked"
require_present "Cosmo Trader/Models/CosmicMoodIndex.swift" "Cosmic context only"
# Daily Brief must not leak the partial-astro score as a market reading.
require_present "Cosmo Trader/Services/DailyFinancialReadingService.swift" "cosmic context only"
require_present "Cosmo Trader/Services/DailyFinancialReadingService.swift" "marketBackedScore(from:"
require_present "Cosmo Trader/Services/DailyFinancialReadingService.swift" "marketToneProvenance: mood.provenance"
require_present "Cosmo Trader/Models/DailyFinancialReading.swift" "marketToneProvenance"
require_present "Cosmo Trader/Views/Components/DailyFinancialReadingCockpitView.swift" "marketToneCell"
require_present "Cosmo Trader/Views/Components/DailyFinancialReadingCockpitView.swift" "MARKET TONE (COSMIC)"
# Discover must not quote a cosmic-only mood as a market claim.
require_present "Cosmo Trader/ViewModels/DiscoverViewModel.swift" "mood.isMarketBacked, let value = mood.value"
# Gauge surfaces honest unavailable / cosmic-only states.
require_present "Cosmo Trader/Views/Components/CosmicMoodGauge.swift" "N/A"
require_present "Cosmo Trader/Views/Components/CosmicMoodGauge.swift" "COSMIC ONLY"

require_present "Cosmo Trader/Views/Tabs/PortfolioView.swift" "portfolioDailyPLProvenance"
require_present "Cosmo Trader/Views/Tabs/PortfolioView.swift" "changeCell(for:"
require_present "Cosmo Trader/Views/Tabs/PortfolioView.swift" ".mixed(reason:"
require_present "Cosmo Trader/Views/Components/DataSourceIndicator.swift" "Mixed data"

require_absent "Cosmo Trader/Services/CosmicTickerService.swift" "stocks ?? MockStockData"
require_absent "Cosmo Trader/Services/CosmicTickerService.swift" "FULL MOON: VOLATILITY ELEVATED"
require_absent "Cosmo Trader/Services/CosmicTickerService.swift" "WANING MOON: DE-RISKING WINDOW"
require_absent "Cosmo Trader/Services/CosmicTickerService.swift" "SIGNAL CONFIRMED"
require_present "Cosmo Trader/Services/CosmicTickerService.swift" "MARKET DATA UNAVAILABLE"

require_absent "Cosmo Trader/Views/Components/VolumeLeadersView.swift" "from: MockStockData.knownStocks"
require_present "Cosmo Trader/Views/Components/VolumeLeadersView.swift" "Volume leaders unavailable"

require_absent "Cosmo Trader/Services/DailyBriefService.swift" "let knownStocks = Stock.samples + MockStockData.all"
require_absent "Cosmo Trader/Services/DailyBriefService.swift" "for stock in user.portfolio where abs"
require_present "Cosmo Trader/Services/DailyBriefService.swift" "daily highlights must stay empty"

require_file_absent "Cosmo Trader/Views/Tabs/DailyBriefView.swift"
require_present "Cosmo Trader/Views/ContentView.swift" "DailyBriefBackendView()"
require_present "Cosmo Trader/Views/Settings/DailyBriefBackendView.swift" "TodayMarketHoroscopeView(viewModel:"
require_present "Cosmo Trader/Views/Settings/DailyBriefBackendView.swift" "await todayViewModel.load(user: appState.currentUser)"
require_present "Cosmo Trader/Views/Settings/DailyBriefBackendView.swift" "await todayViewModel.reload(user: appState.currentUser)"
require_present "Cosmo Trader/Views/Components/TodayMarketHoroscopeView.swift" "accessibilityIdentifier(\"today.marketHoroscope\")"
require_present "Cosmo Trader/Views/Components/TodayMarketHoroscopeView.swift" "DataSourceIndicator(provenance: summary.provenance"
require_present "Cosmo Trader/Views/Components/TodayMarketHoroscopeView.swift" "DATA COVERAGE"
require_present "Cosmo Trader/Views/Components/TodayMarketHoroscopeView.swift" "if !context.metrics.isEmpty"
require_present "Cosmo Trader/Services/TodayMarketHoroscopeComposer.swift" "numericPortfolioCoverageThreshold = 0.70"
require_present "Cosmo Trader/Services/TodayMarketHoroscopeComposer.swift" "displayMode == .marketBacked ? portfolioMetrics(for: summary) : []"
require_present "Cosmo Trader/Services/TodayMarketHoroscopeComposer.swift" "displayMode == .marketBacked ? stockMetrics(for: summary) : []"
require_present "Cosmo Trader/Services/TodayMarketHoroscopeComposer.swift" "Coverage must reach 70% before headline return metrics appear."
require_present "Cosmo Trader/Services/TodayMarketHoroscopeComposer.swift" "Today stays in cosmic or unavailable mode until provider-backed history clears"
require_present "Cosmo Trader/Services/TodayMarketHoroscopeComposer.swift" "Correlation does not imply causation"
require_present "Cosmo TraderTests/Services/TodayMarketHoroscopeComposerTests.swift" "Partial portfolio coverage stays context-only below seventy percent"
require_present "Cosmo TraderTests/Services/TodayMarketHoroscopeComposerTests.swift" "Sample and unavailable stock context cannot produce numeric metrics"
require_absent "Cosmo Trader/Services/TodayMarketHoroscopeComposer.swift" "Double.random"

require_present "Cosmo Trader/Models/FinancialDataProvenance.swift" "enum FinancialDataProvenance"
require_present "Cosmo Trader/Services/StockAPIService.swift" "getQuoteWithProvenance"
require_present "Cosmo Trader/Services/StockAPIService.swift" "fetchKeyStatsResult"
require_present "Cosmo Trader/Views/Components/DataSourceIndicator.swift" "var provenance: FinancialDataProvenance?"

require_present "Cosmo Trader/Services/AstroCorrelationService.swift" "struct StockCosmicCorrelationSummary"
require_present "Cosmo Trader/Services/AstroCorrelationService.swift" "minimumSampleSize"
require_present "Cosmo Trader/Services/AstroCorrelationService.swift" "provenance.isProviderBacked"
require_present "Cosmo Trader/Services/AstroCorrelationService.swift" "Correlation does not imply causation"
require_present "Cosmo Trader/ViewModels/HistoricalAstroChartViewModel.swift" "CorrelationDatasetStore.shared.dataset"
require_present "Cosmo Trader/ViewModels/HistoricalAstroChartViewModel.swift" "historicalPriceProvenance"
require_present "Cosmo Trader/Views/Components/HistoricalAstroChartView.swift" "DataSourceIndicator(provenance: viewModel.historicalPriceProvenance"
require_present "Cosmo Trader/Views/Components/HistoricalAstroChartView.swift" "Provider-backed history is required before event-window metrics are shown"
require_present "Cosmo Trader/Views/Components/AstroCorrelationSummaryView.swift" "Historical price data unavailable"
require_present "Cosmo Trader/Views/Components/AstroCorrelationSummaryView.swift" "Correlation does not imply causation"
require_present "Cosmo Trader/Views/Components/AstroCorrelationSummaryView.swift" "displayMode == .marketBackedResult"
require_present "Cosmo Trader/Services/PortfolioCosmicCorrelationService.swift" "struct PortfolioCosmicCorrelationSummary"
require_present "Cosmo Trader/Services/PortfolioCosmicCorrelationService.swift" "provenance.isProviderBacked"
require_present "Cosmo Trader/Services/PortfolioCosmicCorrelationService.swift" "includedPortfolioWeight"
require_present "Cosmo Trader/Services/PortfolioCosmicCorrelationService.swift" "minimumSampleSize"
require_present "Cosmo Trader/ViewModels/PortfolioCorrelationViewModel.swift" "CorrelationDatasetStore.shared.datasets"
require_present "Cosmo Trader/Views/Components/PortfolioCosmicCorrelationView.swift" "DataSourceIndicator(provenance: viewModel.historicalPriceProvenance"
require_present "Cosmo Trader/Views/Components/PortfolioCosmicCorrelationView.swift" "displayMode == .marketBackedResult"
require_present "Cosmo Trader/Views/Tabs/PortfolioView.swift" "PortfolioCosmicCorrelationView"
require_present "Cosmo TraderTests/Services/PortfolioCosmicCorrelationServiceTests.swift" "Portfolio correlation is weighted by market value"
require_present "Cosmo Trader/Models/HistoricalPriceDataset.swift" "struct HistoricalPriceDataset"
require_present "Cosmo Trader/Services/HistoricalPriceCache.swift" "final class HistoricalPriceCache"
require_present "Cosmo Trader/Services/HistoricalPriceCache.swift" "dataset.provenance.isProviderBacked"
require_present "Cosmo Trader/Services/CorrelationDatasetStore.swift" "final class CorrelationDatasetStore"

require_absent "Cosmo Trader/Models/CosmicEvent.swift" "Consider reducing position sizes"
require_absent "Cosmo Trader/Models/CosmicEvent.swift" "Avoid starting new high-risk positions"
require_absent "Cosmo Trader/Models/CosmicEvent.swift" "Avoid large discretionary purchases"
require_absent "Cosmo Trader/Services/CosmicPatternInterpreter.swift" "consider delaying major decisions"
require_absent "Cosmo Trader/Services/CosmicPatternInterpreter.swift" "using smaller position sizes"
require_absent "Cosmo Trader/Services/CosmicMoodService.swift" "potential contrarian buy signal"
require_absent "Cosmo Trader/Services/CosmicMoodService.swift" "potential contrarian sell signal"
require_absent "Cosmo Trader/Views/Components/CosmicSignalCard.swift" "AVOID"
require_absent "Cosmo Trader/Models/DailyFinancialReading.swift" "Avoid chasing"
require_absent "Cosmo Trader/Models/DailyFinancialReading.swift" "Reduce risk"
require_absent "Cosmo Trader/Models/DailyFinancialReading.swift" "case hold = \"Hold\""
require_absent "Cosmo Trader Widget/SharedWidgetData.swift" "Good for new positions"
require_absent "Cosmo Trader Widget/SharedWidgetData.swift" "Secure your gains"
require_absent "Cosmo Trader Widget/SharedWidgetData.swift" "Trim underperformers"
require_absent "Cosmo Trader Widget/MoonPhaseWidget.swift" "Take Profit"
require_absent "Cosmo Trader Widget/MoonPhaseWidget.swift" "Build Position"
require_present "Cosmo TraderTests/Services/ComplianceCopyGuardTests.swift" "Scanner catches known trading-instruction phrases"

if [[ "$failures" -gt 0 ]]; then
  echo "production_mock_guard: failed with $failures issue(s)"
  exit 1
fi

echo "production_mock_guard: passed"
