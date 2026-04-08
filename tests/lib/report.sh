#!/usr/bin/env bash
# report.sh — Test result output (JSON + colored terminal)

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# Output test result
test_result() {
  local status="$1"
  local test_name="$2"
  local details="${3:-}"
  
  case "$status" in
    pass)
      echo -e "${GREEN}✓ $test_name${NC}"
      [[ -n "$details" ]] && echo "  $details"
      ;;
    fail)
      echo -e "${RED}✗ $test_name${NC}"
      [[ -n "$details" ]] && echo "  $details"
      ;;
    skip)
      echo -e "${YELLOW}⊘ $test_name${NC}"
      [[ -n "$details" ]] && echo "  $details"
      ;;
  esac
}

# Generate JSON report
json_report() {
  local output_file="${1:-test-results.json}"
  
  cat > "$output_file" <<EOF
{
  "timestamp": "$(date -Iseconds)",
  "total": $TOTAL,
  "passed": $PASSED,
  "failed": $FAILED,
  "results": [
    $RESULTS
  ]
}
EOF
  
  echo "JSON report: $output_file"
}

# Print section header
section() {
  echo ""
  echo -e "${CYAN}═════ $1 ═════${NC}"
}

# Print summary
summary() {
  echo ""
  echo -e "═══════════════════════════════════"
  echo -e "  Tests: $PASSED/$TOTAL passed"
  if [[ $FAILED -gt 0 ]]; then
    echo -e "  ${RED}Failed: $FAILED${NC}"
  else
    echo -e "  ${GREEN}All passed!${NC}"
  fi
  echo -e "═══════════════════════════════════"
}