# Claude Sessions

A native macOS app that turns your Claude Code conversation history into a browsable, searchable interface — with cost tracking, tool visualization, and automatic project detection.

**Built from scratch in 32 minutes using Claude Code.** [Here's how.](#built-in-32-minutes)

[![CI](https://github.com/vasilievyakov/ClaudeSessions/actions/workflows/ci.yml/badge.svg)](https://github.com/vasilievyakov/ClaudeSessions/actions/workflows/ci.yml) ![macOS](https://img.shields.io/badge/macOS-14%2B-blue) ![Swift](https://img.shields.io/badge/Swift-6.0-orange) ![License](https://img.shields.io/badge/license-MIT-green) ![Zero Dependencies](https://img.shields.io/badge/dependencies-0-brightgreen) ![Tests](https://img.shields.io/badge/tests-120%2B-brightgreen)

![ClaudeSessions — three-column session browser](screenshot.png)

## Why

Claude Code stores every conversation as a JSONL file in `~/.claude/projects/`. These files contain rich data — token counts, tool calls, model info, costs, durations — but there's no built-in way to browse them. You can `--resume` a session if you remember its ID, but you can't:

- See all sessions across projects at a glance
- Know how much each session cost you
- Find that conversation from Tuesday where you fixed the auth bug
- Understand which tools Claude used and how often

This app fills that gap. Think [NetNewsWire](https://netnewswire.com/), but for your AI conversations.

## Features

- **See where your money goes** — per-session cost estimates based on current Anthropic pricing, with token breakdowns (input, output, cache read, cache write)
- **Find any conversation instantly** — full-text search across all sessions, plus smart filters: Today, This Week, Large >100K, per-project
- **Understand how Claude works** — colored tool badges show Read/Write/Bash/Grep/Task call counts at a glance
- **Auto-detected projects** — 5-level detection cascade analyzes file paths, working directory, and message content. No configuration needed
- **Quick Open (⌘P)** — Spotlight-like fuzzy search to jump to any session
- **Activity heatmap** — GitHub-style contribution grid showing your Claude Code usage over 12 weeks
- **Privacy-first** — everything stays local, reads only from files on your machine

## Install

Requires macOS 14 (Sonoma) or later.

**Homebrew (recommended):**

```bash
brew install --cask vasilievyakov/tap/claude-sessions
```

**From source:**

```bash
git clone https://github.com/vasilievyakov/ClaudeSessions.git
cd ClaudeSessions
make install   # builds and copies to ~/Applications/
```

## Security

ClaudeSessions is designed for enterprise environments where verifiability matters.

| Property | Status | How to verify |
|----------|--------|---------------|
| Zero network access | Sandbox enforced | `cat ClaudeSessions.entitlements` |
| Read-only file access | No write APIs | `grep -rn "createFile\|write(to:" Sources/` |
| Zero dependencies | Verified | `swift package show-dependencies` |
| No hardcoded credentials | Verified | `bash Scripts/verify-no-credentials.sh` |
| SBOM available | In every release | `sbom.spdx.json` |

```bash
# One-command security audit
bash Scripts/security-audit.sh
```

## Privacy

- **Reads:** `~/.claude/projects/*.jsonl`, `~/.claude/stats-cache.json`
- **Writes:** Nothing. **Transmits:** Nothing. **Collects:** Nothing.
- GDPR compliant. SOC 2 compatible. No telemetry.

[Full privacy documentation](PRIVACY.md) | [Security policy](SECURITY.md)

## Built in 32 Minutes

This entire app — from blank file to working macOS application — was built in a single Claude Code session. Not a prototype. Not a mockup. A real three-column SwiftUI app that parses an undocumented file format, estimates costs, visualizes tool usage, and auto-detects projects.

Here's the process that made it possible.

### Research before code (3.7 min)

Instead of jumping into implementation, a research agent studied UX patterns across 10+ existing tools: ChatGPT's conversation browser, Cursor's session history, Console.app, Bear, Obsidian, and four open-source Claude Code viewers. It cataloged **40+ features** across 8 categories, with implementation notes and precedents for each.

This took 224 seconds and consumed 70K tokens. The result: a prioritized feature list where 6 high-impact features were selected for a single implementation pass.

**This is the key insight.** 4 minutes of research eliminated hours of wrong turns. The agent already knew which UI patterns work, which features matter, and which are noise — before writing a single line of Swift.

### Reverse-engineering an undocumented format (1 min)

Claude Code's JSONL session format isn't documented anywhere. The agent discovered the structure empirically — running a Python script over real files, forming hypotheses, and testing them:

- `usage` data is nested inside `message.usage`, not at the top level (the obvious assumption was wrong)
- Timing data lives in `type: "system"` records with `subtype: "turn_duration"`
- `gitBranch` exists at the top level but is often empty or "HEAD"

This kind of exploratory work — reading real data, finding patterns, handling edge cases — is exactly where AI agents shine.

### Implementation (4 min)

All 5 Swift files were written in a single pass. Zero compilation errors on the first `swift build`.

That's not magic — it's the compounding effect of good research. The agent knew the data format, knew the UI patterns, and knew which SwiftUI components to use. There was nothing left to guess.

### From personal tool to open source

The first version worked perfectly — for one person. It had hardcoded usernames, manual project-to-color mappings, and paths that only made sense on one machine.

Making it universal required rethinking project detection entirely: a 5-level cascade (file paths → working directory → session directory → content analysis → fallback) that works for any user without configuration.

### Timeline

| Phase | Duration | What happened |
|-------|----------|--------------|
| UX Research | 3.7 min | 40+ features cataloged from 10+ reference apps |
| Prioritization | — | 6 features cherry-picked for single implementation pass |
| JSONL Discovery | 1 min | Undocumented format reverse-engineered from real files |
| Implementation | 4 min | 5 files, ~700 lines, 0 compilation errors |
| Testing & polish | 17 min | Manual testing, all features confirmed working |
| Open-source prep | — | Universal project detection, hash-based colors |

**Total: ~32 minutes from research to a deployed, working macOS app.**

The methodology matters more than the speed: research the problem space, understand the data, prioritize ruthlessly, implement in one focused pass. This works for a session browser. It works for most tools.

<details>
<summary><strong>Architecture</strong></summary>

Five Swift files, ~700 lines total:

```
Sources/
├── ClaudeSessionsApp.swift   # App entry point, window config, ⌘R / ⌘P shortcuts
├── Session.swift              # Data model, JSONL parser, cost estimation, project detection
├── SessionStore.swift         # Observable store: scanning, filtering, grouping, search
├── ContentView.swift          # All UI: sidebar, timeline, detail view, quick open
└── ActivityHeatmap.swift      # GitHub-style heatmap using Swift Charts
```

**Data flow:**
1. `SessionStore` scans `~/.claude/projects/*/` for `.jsonl` files
2. `parseSession()` reads each file line-by-line, extracting metadata
3. Sessions are grouped by date and filtered by the active collection/search
4. Views observe `SessionStore` via `@EnvironmentObject`

**Project detection** uses a 5-level cascade (file paths → cwd → session dir → content → fallback), with special handling for `.claude/` subfolders and a shared `extractProjectFromPath()` that skips common container directories.

**Cost estimation** based on [Anthropic pricing](https://www.anthropic.com/pricing) (Claude 4.5 series):

| Model | Input | Output | Cache Read | Cache Write |
|-------|-------|--------|------------|-------------|
| Opus | $5/M | $25/M | $0.50/M | $6.25/M |
| Sonnet | $3/M | $15/M | $0.30/M | $3.75/M |
| Haiku | $1/M | $5/M | $0.10/M | $1.25/M |

</details>

<details>
<summary><strong>JSONL Format Reference</strong></summary>

Claude Code's session format is undocumented. Here's what we discovered by reverse-engineering the files.

Each `.jsonl` file contains one JSON object per line. Key record types:

**`type: "user"` — User messages**
```json
{
  "type": "user",
  "timestamp": "2026-02-19T19:09:30.123Z",
  "cwd": "/Users/you/Projects/app",
  "gitBranch": "main",
  "message": {
    "role": "user",
    "content": "Fix the login bug"
  }
}
```

**`type: "assistant"` — Claude's responses**
```json
{
  "type": "assistant",
  "message": {
    "role": "assistant",
    "model": "claude-opus-4-5-20251101",
    "usage": {
      "input_tokens": 9,
      "output_tokens": 256,
      "cache_read_input_tokens": 25611,
      "cache_creation_input_tokens": 1347
    },
    "content": [
      { "type": "text", "text": "I'll fix that..." },
      { "type": "tool_use", "name": "Read", "input": { "file_path": "..." } }
    ]
  }
}
```

Key detail: `usage` and `model` are nested inside `message`, not at the top level.

**`type: "system"`, `subtype: "turn_duration"` — Timing**
```json
{
  "type": "system",
  "subtype": "turn_duration",
  "durationMs": 394705
}
```

**Other types (not parsed):** `file-history-snapshot`, `progress`, `system` with `subtype: "stop_hook_summary"`

</details>

## License

MIT License. See [LICENSE](LICENSE) for details.
