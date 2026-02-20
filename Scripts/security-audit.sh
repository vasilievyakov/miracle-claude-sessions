#!/bin/bash
# Master security audit — runs all checks
# Exit code 0 = all passed, 1 = any failure

SCRIPT_DIR="$(dirname "$0")"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
FAILED=0

echo "╔══════════════════════════════════════════════════╗"
echo "║     ClaudeSessions Enterprise Security Audit     ║"
echo "╚══════════════════════════════════════════════════╝"
echo ""

run_check() {
    local name="$1"
    local script="$2"
    echo "── $name ──"
    if bash "$script"; then
        echo "✓ $name: PASSED"
    else
        echo "✗ $name: FAILED"
        FAILED=1
    fi
    echo ""
}

run_check "Network Isolation" "$SCRIPT_DIR/verify-no-network.sh"
run_check "Hardcoded Paths"   "$SCRIPT_DIR/verify-no-hardcoded-paths.sh"
run_check "Credentials Check" "$SCRIPT_DIR/verify-no-credentials.sh"

echo "── Entitlements ──"
if [ -f "$REPO_ROOT/ClaudeSessions.entitlements" ]; then
    if grep -A1 "network.client" "$REPO_ROOT/ClaudeSessions.entitlements" | grep -q "false"; then
        echo "✓ Entitlements: network.client=false"
    else
        echo "✗ Entitlements: network.client not false"
        FAILED=1
    fi
else
    echo "✗ Entitlements file missing"
    FAILED=1
fi
echo ""

echo "── SBOM ──"
if [ -f "$REPO_ROOT/sbom.spdx.json" ]; then
    if python3 -c "import json; json.load(open('$REPO_ROOT/sbom.spdx.json')); print('Valid JSON')" 2>/dev/null; then
        echo "✓ SBOM: valid"
    else
        echo "✗ SBOM: invalid JSON"
        FAILED=1
    fi
else
    echo "✗ SBOM missing (run Scripts/generate-sbom.sh)"
    FAILED=1
fi
echo ""

echo "── Required Documents ──"
for doc in PRIVACY.md SECURITY.md LICENSE CONTRIBUTING.md CODE_OF_CONDUCT.md; do
    if [ -f "$REPO_ROOT/$doc" ]; then
        echo "✓ $doc exists"
    else
        echo "✗ $doc missing"
        FAILED=1
    fi
done
echo ""

echo "── Source Metrics ──"
FILE_COUNT=$(find "$REPO_ROOT/Sources" -name "*.swift" | wc -l | tr -d ' ')
LINE_COUNT=$(cat "$REPO_ROOT/Sources"/*.swift 2>/dev/null | wc -l | tr -d ' ')
echo "  Swift files: $FILE_COUNT"
echo "  Lines of code: $LINE_COUNT"
if [ "$FILE_COUNT" -gt 15 ]; then
    echo "✗ WARNING: More than 15 Swift files — review for auditability"
fi
if [ "$LINE_COUNT" -gt 2000 ]; then
    echo "✗ WARNING: More than 2000 lines — review for auditability"
fi
echo ""

echo "╔══════════════════════════════════════════════════╗"
if [ $FAILED -eq 0 ]; then
    echo "║           ALL CHECKS PASSED ✓                   ║"
else
    echo "║           SOME CHECKS FAILED ✗                  ║"
fi
echo "╚══════════════════════════════════════════════════╝"
exit $FAILED
