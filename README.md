# Claude Sessions

A native macOS app for browsing your [Claude Code](https://docs.anthropic.com/en/docs/claude-code) session history.

![macOS](https://img.shields.io/badge/macOS-14%2B-blue) ![Swift](https://img.shields.io/badge/Swift-6.0-orange) ![License](https://img.shields.io/badge/license-MIT-green)

![ClaudeSessions — three-column session browser](screenshot.png)

## What Is This?

Claude Code stores every conversation as a JSONL file in `~/.claude/projects/`. These files contain rich data — token counts, tool calls, model info, costs, durations — but there's no built-in way to browse them.

Claude Sessions is a lightweight SwiftUI browser that turns those raw files into a readable, searchable interface. Think [NetNewsWire](https://netnewswire.com/), but for your AI conversations.

## Why?

Claude Code is a CLI tool. It has `--resume` and `--continue`, but no way to:
- See all your sessions across projects at a glance
- Know how much each session cost
- Find that conversation from three days ago where you fixed the auth bug
- Understand which tools Claude used and how often

This app fills that gap.

## Features

### Three-Column Layout
NetNewsWire-inspired navigation: sidebar with smart collections, timeline with session cards, and a detail view with full session info.

### Smart Collections
- **All Sessions** — everything in one view
- **Today / This Week** — temporal filters
- **Large Sessions (>100K tokens)** — find the expensive ones
- **Per-Project** — auto-detected from your directory structure

### Stat Cards
Two rows of metrics for each session:
- Cost estimate (based on model pricing)
- Token breakdown (input, output, cache read, cache write)
- Duration (sum of turn durations)
- Model (Opus/Sonnet/Haiku with version)
- Message counts (user + assistant)
- File size and working directory

### Tool Visualization
Colored badges showing every tool Claude used — Read, Write, Bash, Grep, Task, MCP tools — with call counts. At a glance, you can tell if a session was mostly reading, mostly coding, or a deep research dive.

### Activity Heatmap
GitHub-style contribution grid in the sidebar, showing your Claude Code activity over the last 12 weeks. Reads from `~/.claude/stats-cache.json`.

### Quick Open (Cmd+P)
Spotlight-like fuzzy search across all sessions. Type a few characters, arrow through results, hit Enter to jump.

### Smart Project Detection
Projects are detected automatically — no configuration needed. Detection cascade:
1. **File paths** from tool calls (most reliable — what files did Claude actually touch?)
2. **Working directory** (if not home)
3. **Session directory** name (encoded in `~/.claude/projects/`)
4. **Content analysis** — GitHub URLs and file paths mentioned in your first messages
5. **Fallback** — "Chat" for pure conversations, "Home" for everything else

Special handling for `.claude/` subfolders: sessions working on skills, rules, or memory get their own project names.

### Cost Estimation
Per-session cost estimates based on [Anthropic pricing](https://www.anthropic.com/pricing) (Claude 4.5 series):

| Model | Input | Output | Cache Read | Cache Write |
|-------|-------|--------|------------|-------------|
| Opus | $5/M | $25/M | $0.50/M | $6.25/M |
| Sonnet | $3/M | $15/M | $0.30/M | $3.75/M |
| Haiku | $1/M | $5/M | $0.10/M | $1.25/M |

## Build & Install

Requirements: macOS 14+ and Swift 6.0 (comes with Xcode 16).

```bash
# Clone
git clone https://github.com/vasilievyakov/ClaudeSessions.git
cd ClaudeSessions

# Build
swift build -c release

# Install (optional — copies binary to ~/Applications/)
make install

# Or just run directly
make run
```

## Architecture

Five Swift files, ~700 lines total:

```
Sources/
├── ClaudeSessionsApp.swift   # App entry point, window config, Cmd+R / Cmd+P shortcuts
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

**Project detection** uses a 5-level cascade (file paths → cwd → session dir → content → fallback), with special handling for `.claude/` subfolders and a shared `extractProjectFromPath()` that skips common container directories (Projects, Developer, Documents, etc.).

## JSONL Format

Claude Code's session format is undocumented. Here's what we discovered by reverse-engineering the files:

Each `.jsonl` file contains one JSON object per line. Key record types:

### `type: "user"` — User messages
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

### `type: "assistant"` — Claude's responses
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

### `type: "system"`, `subtype: "turn_duration"` — Timing
```json
{
  "type": "system",
  "subtype": "turn_duration",
  "durationMs": 394705
}
```

### Other types (not parsed)
- `file-history-snapshot` — file state tracking
- `progress` — streaming progress indicators
- `system` with `subtype: "stop_hook_summary"` — hook execution logs

## Built in 32 Minutes

This entire app — from blank file to working macOS application — was built in a single Claude Code session. Not a prototype. Not a mockup. A real three-column SwiftUI app that parses undocumented file formats, estimates costs, visualizes tool usage, and auto-detects projects.

Here's the process that made it possible.

### Research Before Code (3.7 min)

Instead of jumping into implementation, a research agent analyzed UX patterns across 10+ existing tools: ChatGPT's conversation browser, Cursor's session history, Console.app, Bear, Obsidian, and four open-source Claude Code viewers. It cataloged **40+ features** with implementation notes and precedents.

This took 224 seconds and consumed 70K tokens. The result: a prioritized feature list where 6 high-impact features were selected for a single implementation pass.

**This is the key insight.** Spending 4 minutes on research saved hours of wrong turns. The agent already knew which UI patterns work, which features matter, and which are noise — before writing a single line of Swift.

### Reverse-Engineering an Undocumented Format (1 min)

Claude Code's JSONL session format isn't documented anywhere. The agent had to discover it empirically:

1. Ran a Python script over real JSONL files to catalog all record types
2. Discovered that `usage` data is nested inside `message.usage`, not at the top level (the obvious assumption was wrong)
3. Found that timing data lives in `type: "system"` records with `subtype: "turn_duration"`
4. Learned that `gitBranch` is at the top level but often empty or "HEAD"

This kind of exploratory work — reading real files, forming hypotheses, testing them — is exactly where AI agents shine.

### Implementation (4 min)

All 5 Swift files were written in a single pass. Zero compilation errors on the first build.

That's not magic — it's the compounding effect of good research. The agent knew the data format, knew the UI patterns, and knew which SwiftUI components to use. There was nothing left to guess.

### From Personal Tool to Open Source

The first version worked perfectly — for one person. It had hardcoded usernames, manual project-to-color mappings, and paths that only made sense on one machine.

Making it universal required rethinking project detection entirely. The current version uses a 5-level detection cascade (file paths → working directory → session directory → content analysis → fallback) that works for any user without configuration.

### Timeline

| Phase | Duration | What happened |
|-------|----------|--------------|
| UX Research | 3.7 min | 40+ features cataloged from 10+ reference apps |
| Prioritization | — | 6 features selected for implementation |
| JSONL Discovery | 1 min | Format reverse-engineered from real session files |
| Implementation | 4 min | 5 files, ~700 lines, 0 compilation errors |
| Testing & polish | 17 min | Manual testing, all features confirmed working |
| Open-source prep | — | Universal project detection, hash-based colors |

**Total: ~32 minutes from research to a deployed, working macOS app.**

The methodology matters more than the speed: research the problem space, understand the data, prioritize ruthlessly, then implement in one focused pass. This works for a session browser. It works for most tools.

## License

MIT License. See [LICENSE](LICENSE) for details.
