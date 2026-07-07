#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

# View-size ratchet
# =================
# The largest SwiftUI views in this app accumulated data loading, service
# orchestration, and business logic inline, which is why every feature PR
# used to collide in the same 2,000-line files. The standing rule (see
# AGENTS.md) is: views render state and forward intents; loading and
# orchestration live in a view model.
#
# This script enforces the rule as a ratchet: each listed view may shrink
# freely, but may not grow past its recorded baseline. If your change trips
# it, extract the logic you are adding (plus ideally some it touches) into
# the screen's view model — StockDetailViewModel is the reference example —
# and lower the baseline to the new line count. Raising a baseline is only
# appropriate for pure view code that genuinely cannot live elsewhere, and
# should be called out in the PR description.

failures=0

check_max_lines() {
  local file="$1"
  local max="$2"
  if [[ ! -f "$file" ]]; then
    echo "FAIL: ratcheted file missing: $file (update Scripts/view_size_ratchet.sh)" >&2
    failures=$((failures + 1))
    return
  fi
  local actual
  actual=$(wc -l < "$file" | tr -d ' ')
  if (( actual > max )); then
    echo "FAIL: $file is $actual lines (ratchet baseline: $max)." >&2
    echo "      Extract logic into the screen's view model instead of growing the view (see AGENTS.md)." >&2
    failures=$((failures + 1))
  fi
}

check_max_lines "Cosmo Trader/Views/Tabs/ProfileView.swift" 2442
# StockDetailView baseline raised 1900→1914 for pure view code: the
# conditional render + card styling of the extracted StockPositionSummaryView
# (all P/L logic lives in the component and Stock model).
check_max_lines "Cosmo Trader/Views/StockDetailView.swift" 1914
# PortfolioView baseline raised 1983→1991 for the tap-gesture context-menu
# fix, →2002 for the extracted PortfolioAllTimePLRow render + summary
# assembly, then →2005 for the network-free guard on fetchLivePrices (a
# view-owned .task fetch that cannot move to a view model).
check_max_lines "Cosmo Trader/Views/Tabs/PortfolioView.swift" 2005
check_max_lines "Cosmo Trader/Views/Tabs/CosmosView.swift" 1902
check_max_lines "Cosmo Trader/Views/Components/TodayMarketHoroscopeView.swift" 1211
check_max_lines "Cosmo Trader/Views/Onboarding/OnboardingView.swift" 1203
check_max_lines "Cosmo Trader/Views/Tabs/DiscoverView.swift" 1125

if (( failures > 0 )); then
  echo "view_size_ratchet: failed with ${failures} issue(s)" >&2
  exit 1
fi

echo "view_size_ratchet: passed"
