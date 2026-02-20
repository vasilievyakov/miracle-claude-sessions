# Security Policy

## Supported Versions

| Version | Supported |
|---------|-----------|
| Latest  | Yes       |

## Security Model

ClaudeSessions is designed to be **verifiably safe**:

- **Zero network access** — sandbox entitlements set `com.apple.security.network.client = false`. macOS physically prevents any outbound connections.
- **Read-only** — the app reads `~/.claude/` and never writes, modifies, or deletes any files.
- **Zero dependencies** — no third-party code. The entire codebase is 5 files, ~700 lines of Swift.
- **No telemetry** — no analytics, crash reporting, or usage tracking of any kind.

## How to Verify

Each claim is backed by automated verification:

```bash
# Full security audit (all checks in one command)
bash Scripts/security-audit.sh

# Individual checks:
bash Scripts/verify-no-network.sh        # No network APIs in source
bash Scripts/verify-no-hardcoded-paths.sh # No personal data in source
bash Scripts/verify-no-credentials.sh     # No API keys or passwords

# Verify sandbox entitlements
cat ClaudeSessions.entitlements           # network.client = false

# Verify zero dependencies
swift package show-dependencies           # Empty
```

## Reporting a Vulnerability

**Contact:** Telegram [@yakovvasiliev](https://t.me/yakovvasiliev)

**Response SLA:**
- Acknowledgment: within 48 hours
- Status update: within 7 days
- Patch for critical issues: within 14 days

Please do **not** open a public GitHub issue for security vulnerabilities.

## Scope

**In scope:** parser logic, file path traversal, data exposure, information leakage.

**Out of scope:** social engineering, physical access to device, issues in Apple's macOS APIs.

## Threat Model

Given the architecture (local-only, read-only, no network, no dependencies), the primary attack surface is:

1. **Malicious JSONL files** — crafted session files could attempt to exploit the JSON parser
2. **Path traversal** — file paths in session data are displayed but never executed

Both are mitigated by using Apple's built-in `JSONSerialization` (battle-tested) and treating all file content as display-only data.
