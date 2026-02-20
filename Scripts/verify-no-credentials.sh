#!/bin/bash
set -e

SOURCES_DIR="$(dirname "$0")/../Sources"
FAILED=0

echo "=== ClaudeSessions Security Audit: Credentials Check ==="
echo ""

PATTERNS=("api_key" "apiKey" "API_KEY" "sk-ant-" "bearer " "password =" "passwd" "secret =" "access_token" "auth_token")

for pattern in "${PATTERNS[@]}"; do
    results=$(grep -rni "$pattern" "$SOURCES_DIR" | grep -v "^.*//.*$pattern" || true)
    if [ -n "$results" ]; then
        echo "FAIL: Potential credential '$pattern' found:"
        echo "$results"
        FAILED=1
    else
        echo "PASS: No '$pattern'"
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
