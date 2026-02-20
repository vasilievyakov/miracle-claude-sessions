# Privacy Policy

ClaudeSessions has no server, no backend, no accounts.

## What the App Reads

| Path | Purpose |
|------|---------|
| `~/.claude/projects/*/*.jsonl` | Claude Code session history files |
| `~/.claude/stats-cache.json` | Activity data for the heatmap |

These files are created by [Claude Code](https://docs.anthropic.com/en/docs/claude-code) and contain your conversation history with Claude.

## What the App Does NOT Do

| Category | Status |
|----------|--------|
| Telemetry / analytics | None |
| Crash reporting | None |
| Network requests | Zero |
| Data transmission | Zero |
| Data storage (beyond reading) | None |
| Writing to `~/.claude/` | Never |
| Clipboard access | Only when user explicitly clicks "Copy" |

## Regulatory Compliance

- **GDPR:** Compliant. No personal data leaves the device.
- **SOC 2:** No data collection or transmission occurs.
- **HIPAA:** No PHI is processed, stored, or transmitted.
- **CCPA:** No personal information collected.

## How to Verify

```bash
# 1. Static analysis — no network APIs in source
bash Scripts/verify-no-network.sh

# 2. Check sandbox entitlements (network.client must be false)
cat ClaudeSessions.entitlements

# 3. Verify only ~/.claude is accessed
grep -r "\.claude" Sources/

# 4. Check for write operations (should be empty)
grep -rn "createFile\|write(to\|createDirectory" Sources/

# 5. Verify zero dependencies
swift package show-dependencies
```

## Data Residency

All data remains on the local machine. No data is sent anywhere, ever.
