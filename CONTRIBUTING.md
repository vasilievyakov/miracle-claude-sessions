# Contributing

Thank you for your interest in contributing to Claude Sessions!

## Prerequisites

- macOS 14 (Sonoma) or later
- Swift 6.0+ (included with Xcode or Command Line Tools)

## Getting Started

```bash
git clone https://github.com/vasilievyakov/ClaudeSessions.git
cd ClaudeSessions
swift build
```

## Running Tests

```bash
# With Xcode installed:
swift test

# With Command Line Tools only:
make test
```

Tests use Swift Testing framework (`import Testing`) and are located in `Tests/ClaudeSessionsTests/`.

## Security Audit

```bash
# Run full security audit
bash Scripts/security-audit.sh

# Individual checks
bash Scripts/verify-no-network.sh
bash Scripts/verify-no-hardcoded-paths.sh
bash Scripts/verify-no-credentials.sh
```

## Project Structure

```
Sources/
├── ClaudeSessionsApp.swift   # App entry point, window config
├── Session.swift              # Data model, JSONL parser, cost estimation
├── SessionStore.swift         # Observable store: scanning, filtering
├── ContentView.swift          # All UI views
└── ActivityHeatmap.swift      # GitHub-style heatmap

Tests/ClaudeSessionsTests/
├── SessionTests.swift         # Model and detection logic
├── ParserTests.swift          # JSONL parsing with fixtures
├── HelperTests.swift          # UI helpers and formatters
├── SecurityTests.swift        # 3-layer security verification
├── PerformanceTests.swift     # Speed and idempotency tests
└── Fixtures/                  # Test data files

Scripts/
├── security-audit.sh          # Master audit runner
├── verify-no-network.sh       # Zero network APIs check
├── verify-no-hardcoded-paths.sh
├── verify-no-credentials.sh
└── generate-sbom.sh           # SPDX SBOM generator
```

## Code Style

- Follow existing patterns in the codebase
- SwiftLint is configured (`.swiftlint.yml`) and runs in CI
- Keep functions focused and concise
- **No external dependencies** — this is a core design principle

## Before Submitting a PR

1. `swift build -c release` — zero errors
2. `swift test` or `make test` — all tests pass
3. `bash Scripts/security-audit.sh` — all checks pass
4. No new network APIs introduced
5. No hardcoded paths or credentials

## Submitting Changes

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/my-change`)
3. Make your changes
4. Run tests and security audit
5. Commit with a descriptive message
6. Push and open a Pull Request

## Reporting Issues

Open an issue on GitHub with:
- macOS version
- Steps to reproduce
- Expected vs actual behavior
