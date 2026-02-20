#!/bin/bash
set -e

SOURCES_DIR="$(dirname "$0")/../Sources"
FAILED=0

echo "=== ClaudeSessions Security Audit: Network Verification ==="
echo ""

PATTERNS=("URLSession" "URLRequest" "import Network" "NWConnection" "NWPathMonitor" "WKWebView" "CFNetwork" "NSURLConnection")

for pattern in "${PATTERNS[@]}"; do
    results=$(grep -rn "$pattern" "$SOURCES_DIR" 2>/dev/null || true)
    if [ -n "$results" ]; then
        echo "FAIL: Found '$pattern':"
        echo "$results"
        FAILED=1
    else
        echo "PASS: No '$pattern' in source code"
    fi
done

echo ""
if [ $FAILED -eq 1 ]; then
    echo "=== AUDIT FAILED: Network APIs detected in source code ==="
    exit 1
else
    echo "=== AUDIT PASSED: Zero network calls verified ==="
    exit 0
fi
