#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

PROJECT="${PROJECT:-Cosmo Trader.xcodeproj}"
SCHEME="${SCHEME:-Cosmo Trader}"
DESTINATION="${DESTINATION:-platform=iOS Simulator,name=iPhone 17 Pro}"
TEST_SELECTOR="${TEST_SELECTOR:-Cosmo TraderTests/ComplianceCopyGuardTests}"
LOG_FILE="${LOG_FILE:-$(mktemp -t cosmo-compliance-copy-guard.XXXXXX.log)}"

bash Scripts/production_mock_guard.sh

failures=0

require_absent() {
  local file="$1"
  local needle="$2"
  if grep -Fq "$needle" "$file"; then
    echo "FAIL: '$needle' is still present in $file" >&2
    failures=$((failures + 1))
  fi
}

require_absent "Cosmo Trader/Models/CosmicEvent.swift" "Consider reducing position sizes"
require_absent "Cosmo Trader/Models/CosmicEvent.swift" "Avoid starting new high-risk positions"
require_absent "Cosmo Trader/Services/CosmicPatternInterpreter.swift" "consider delaying major decisions"
require_absent "Cosmo Trader/Services/CosmicPatternInterpreter.swift" "using smaller position sizes"
require_absent "Cosmo Trader/Services/CosmicMoodService.swift" "potential contrarian buy/sell signal"
require_absent "Cosmo Trader/Services/CosmicMoodService.swift" "potential contrarian buy signal"
require_absent "Cosmo Trader/Services/CosmicMoodService.swift" "potential contrarian sell signal"
require_absent "Cosmo Trader/Services/DailyRitualService.swift" "case hold = \"Hold\""
require_absent "Cosmo Trader/Services/DailyRitualService.swift" "case buy = \"Buy\""
require_absent "Cosmo Trader/Services/DailyRitualService.swift" "case sell = \"Sell\""
require_absent "Cosmo Trader/Services/DailyRitualService.swift" "Maintain current positions"
require_absent "Cosmo Trader/Services/DailyRitualService.swift" "Look for opportunities to add"
require_absent "Cosmo Trader/Services/DailyRitualService.swift" "Consider taking profits"
require_absent "Cosmo Trader Widget/MoonPhaseWidget.swift" "Take Profit"
require_absent "Cosmo Trader Widget/MoonPhaseWidget.swift" "Build Position"
require_absent "Cosmo Trader Widget/SharedWidgetData.swift" "Good for new positions"
require_absent "Cosmo Trader Widget/SharedWidgetData.swift" "Secure your gains"
require_absent "Cosmo Trader Widget/SharedWidgetData.swift" "Trim underperformers"
require_absent "Cosmo Trader/Utils/WidgetDataManager.swift" "Good for new positions"
require_absent "Cosmo Trader/Utils/WidgetDataManager.swift" "Secure your gains"
require_absent "Cosmo Trader/Utils/WidgetDataManager.swift" "Trim underperformers"
require_absent "Cosmo Trader/Views/Components/VOCMoonViews.swift" "avoid initiating new positions"
require_absent "Cosmo Trader/Views/Components/VOCMoonViews.swift" "Opening new positions"
require_absent "Cosmo Trader/Views/Components/VOCMoonViews.swift" "Closing positions"
require_absent "Cosmo Trader/Services/DailyBriefService.swift" "Review existing positions"
require_absent "Cosmo Trader/Services/DailyBriefService.swift" "Avoid major new commitments"
require_absent "Cosmo Trader/Services/DailyBriefService.swift" "Resume normal trading activity"
require_absent "Cosmo Trader/Services/DailyBriefService.swift" "Review volatile exposure"

if [[ "$failures" -gt 0 ]]; then
  echo "compliance_copy_guard: source scan failed with ${failures} issue(s)" >&2
  exit 1
fi

echo "compliance_copy_guard: running focused Xcode tests"
echo "  selector: ${TEST_SELECTOR}"
echo "  destination: ${DESTINATION}"
echo "  log: ${LOG_FILE}"

set +e
xcodebuild test \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -destination "$DESTINATION" \
  -parallel-testing-enabled NO \
  -maximum-concurrent-test-simulator-destinations 1 \
  -only-testing:"$TEST_SELECTOR" \
  2>&1 | tee "$LOG_FILE"
xcode_status=${PIPESTATUS[0]}
set -e

if ! grep -Eq "ComplianceCopyGuardTests|Displayed product copy avoids trading-instruction phrases|Scanner catches known trading-instruction phrases" "$LOG_FILE"; then
  echo "compliance_copy_guard: failed - focused test output did not mention ComplianceCopyGuardTests" >&2
  exit 3
fi

swift_testing_count="$(
  sed -nE 's/.*Test run with ([0-9]+) tests? .*/\1/p' "$LOG_FILE" | tail -1
)"

if [[ -n "$swift_testing_count" ]]; then
  if [[ "$swift_testing_count" -eq 0 ]]; then
    echo "compliance_copy_guard: failed - Swift Testing reported 0 tests: ${TEST_SELECTOR}" >&2
    exit 2
  fi
else
  if grep -Eq "Executed 0 tests|0 tests, with 0 failures" "$LOG_FILE"; then
    echo "compliance_copy_guard: failed - selector selected 0 tests: ${TEST_SELECTOR}" >&2
    exit 2
  fi
fi

if [[ "$xcode_status" -ne 0 ]]; then
  if grep -Eq "NSMachErrorDomain|Failed to install or launch|Failed to launch|Simulator|iOSSimulator|Timed out" "$LOG_FILE"; then
    echo "compliance_copy_guard: Xcode selected the focused compliance suite, but simulator infrastructure failed." >&2
  else
    echo "compliance_copy_guard: focused Xcode compliance tests failed." >&2
  fi
  exit "$xcode_status"
fi

if [[ -n "$swift_testing_count" ]]; then
  echo "compliance_copy_guard: passed (${swift_testing_count} Swift Testing tests)"
else
  echo "compliance_copy_guard: passed"
fi
