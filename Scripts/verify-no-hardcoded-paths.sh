#!/bin/bash
set -e

SOURCES_DIR="$(dirname "$0")/../Sources"
FAILED=0

echo "=== ClaudeSessions Security Audit: Hardcoded Paths ==="
echo ""

# Find /Users/[anything] that isn't NSHomeDirectory or a comment
results=$(grep -rn "/Users/" "$SOURCES_DIR" | grep -v "NSHomeDirectory\|~/\|//.*/Users\|#.*Users" || true)

if [ -n "$results" ]; then
    echo "FAIL: Hardcoded user paths found:"
    echo "$results"
    FAILED=1
else
    echo "PASS: No hardcoded user paths"
fi

# Check for personal identifiers
PERSONAL=("vasiliev" "yakovvasiliev" "MacBook-Pro-Yakova")
for pattern in "${PERSONAL[@]}"; do
    r=$(grep -rni "$pattern" "$SOURCES_DIR" 2>/dev/null || true)
    if [ -n "$r" ]; then
        echo "FAIL: Personal identifier '$pattern' found:"
        echo "$r"
        FAILED=1
    else
        echo "PASS: No personal identifier '$pattern'"
    fi
done

echo ""
if [ $FAILED -eq 1 ]; then
    echo "=== AUDIT FAILED ==="
    exit 1
else
    echo "=== AUDIT PASSED ==="
    exit 0
fi
