# Prompt Stack: How This App Was Built

This document describes the exact setup, methodology, and prompt sequence used to build Claude Sessions — a native macOS SwiftUI app — from inspiration to published GitHub repo.

The goal isn't to give you copy-paste prompts. It's to show a **repeatable workflow** for building real software with AI, so you can adapt it to your own projects.

## Setup

### Hardware
- MacBook Pro M4 Max, 48GB RAM, macOS 15 (Sequoia)
- Overkill for a 700-line app, but the RAM helps when Claude Code runs parallel research agents alongside Swift compilation

### Subscription
- **Claude Max** ($200/month) — this matters because:
  - Access to **Claude Opus** — the model that can write 5 coherent Swift files in a single pass
  - Higher rate limits — parallel research agents burn through tokens fast (70K tokens in 224 seconds during the research phase alone)
  - Extended context — large JSONL files + multi-file codebases need room

You could likely build something similar with Claude Pro ($20/month) using Sonnet, but the parallel research phase and single-pass implementation quality depend on Opus-level capability.

### Software
- **Claude Code** — Anthropic's CLI tool (`claude` command)
- **Swift 6.0** — comes with Xcode 16 (or `xcode-select --install`)
- **No IDE** — everything was done through Claude Code in the terminal
- **MCP servers:** [Exa](https://exa.ai) (web search) + [Tabstack](https://tabstack.com) (web extraction) — for the research phase

That's it. No frameworks, no boilerplate generators, no UI libraries beyond what ships with macOS.

## The Methodology

### Principle: Inspiration → Data → Research → Prioritize → Implement

The app didn't start with "I want to build a session browser." It started with curiosity about someone else's work, which led to analyzing my own data, which revealed a gap that became the app.

This organic path — from inspiration to data to product — is more repeatable than it looks. Here's the full sequence.

## Prompt Sequence

Each phase represents a **turning point** — a moment where the project moved forward significantly.

---

### Phase 0: Inspiration — Parse Everything, Decide Later

It started with a friend's blog. [Sereja](https://sereja.tech) writes about building a "personal corporation" — systems for managing yourself as a one-person company. I wanted to study his approach:

> **Parse this entire blog. Every article. Then we'll decide which practices to adopt.**

Claude launched 6 parallel agents, each fetching ~12 articles. All 76 posts were parsed, categorized into 11 themes, and presented as a structured knowledge base. This took about 10 minutes.

The key word was **"entire."** Not "summarize the blog" or "find the best articles." Parse everything, then decide. This exhaustive approach surfaced patterns I wouldn't have found by skimming.

**What emerged:** The "personal corporation" concept — treating your data, tools, and workflows as a system to be analyzed and optimized. Which led directly to the next step.

**Adapt this:** When you find someone doing interesting work, don't cherry-pick. Parse everything they've published. Let patterns emerge from complete data, not from your assumptions about what's important.

---

### Phase 1: Analyze Your Own Data

Inspired by the "personal corporation" idea, I pointed Claude at my own data:

> **Let's start by analyzing all our logs. Everything we've accumulated. Then we'll figure out what we can do with them.**

Claude analyzed 1,169 Claude Code sessions — 707MB of JSONL files. It found patterns: which projects consume the most tokens, which tools get used most, how session costs distribute over time.

But there was no good way to **browse** this data. The files existed, the insights were there, but the interface was `ls` and `cat`. That gap became the app.

**Why it works:** The best tools come from scratching your own itch. Analyzing your real data reveals real problems that are worth solving.

**Adapt this:** Before building anything, look at the data you already have. What's there but hard to access? What questions can you answer programmatically but not visually?

---

### Phase 2: Throwaway Prototype → "I Want a Real App"

The first version was an HTML dashboard — quick, disposable, proof-of-concept. It worked, but felt like a report, not a tool.

> **I want to build a standalone Mac app for this — with a proper interface.**

Claude presented three options: SwiftUI (native), Tauri (Rust+web), Electron (JS). I picked SwiftUI — native performance, no dependencies, ships with macOS.

The first SwiftUI build was rough. The UI lacked hierarchy, colors clashed, the layout felt like a spreadsheet. But it compiled and ran. That was enough to iterate from.

**Adapt this:** Start with a throwaway prototype. Don't optimize the first version. Its only job is to prove the concept and give you something to react to.

---

### Phase 3: Reference Architecture

Instead of describing the UI I wanted from scratch, I pointed to an existing app:

> **Use NetNewsWire's UI architecture as reference. Clone their NavigationSplitView structure, sidebar list style, and detail view layout. Replace their RSS data model with our JSONL session data model.**

This was the architectural breakthrough. Claude cloned the [NetNewsWire](https://github.com/Ranchero-Software/NetNewsWire) repo, read 12+ source files, and adopted the three-column layout. The result looked professional from the first build.

**Why it works:** You're not asking the AI to invent a UI. You're pointing it at a proven, open-source implementation and saying "do this, but for my data." The AI reads real production code and understands the patterns at a deep level.

**Adapt this:** Find an open-source app with the UX you want. Point Claude Code at it. "Use X as reference. Replace their data model with mine."

---

### Phase 4: Parallel Research

Before writing features, I commissioned research:

> **Check the best possible approaches for a system like this — what can be extracted, what filtering makes sense, etc. Run web research to find the ultimate solution.**

Claude launched 4 parallel research agents, each analyzing a different category: AI conversation browsers (ChatGPT, Cursor), developer log viewers (Console.app, LogUI), note-taking apps (Bear, Obsidian), and existing Claude Code viewers. The result: a catalog of **40+ features** with implementation notes and precedents.

This took 224 seconds and consumed 70K tokens. One research agent cost roughly what a coffee costs. The output would have taken a human 3-4 hours to compile.

**Why it works:** Parallel agents let you survey an entire problem space in minutes. You get a comprehensive feature list instead of building whatever comes to mind first.

**Adapt this:** Before building anything, ask Claude to research existing solutions in parallel. "Survey 10+ tools that solve this problem. Catalog their features. Tell me what's essential vs nice-to-have."

---

### Phase 5: Feature Tiers → Single-Pass Implementation

40+ features is too many. The key was ruthless prioritization:

> **Implement the following plan:**
> **Tier 1: 6 features in a single pass**
>
> *[Detailed spec: Enhanced Parsing, Smart Collections, Stat Cards + Cost Estimation, Tool Visualization, Quick Open (⌘P), Activity Heatmap]*
>
> *[For each feature: exact file changes, data models, computed properties, pricing formulas]*

The implementation prompt was a **structured specification**, not a vague request. It named every file, every data model, every computed property. Claude executed the entire plan in one pass — 5 files, ~700 lines, zero compilation errors.

**Why it works:** A detailed spec removes ambiguity. The AI doesn't have to make architectural decisions mid-implementation — they're all pre-decided by the research phase.

**Adapt this:** Don't say "build me an app." Write (or have Claude write in plan mode) a spec that names files, data models, and key functions. Then say "implement this plan."

---

### Phase 6: Structured UI Feedback

After the first build, give specific, organized feedback:

> **SIDEBAR:**
> - Bold session title (.headline weight), secondary gray metadata
> - Two-line rows like Mail.app: title + truncated first message as preview
>
> **DETAIL PANEL:**
> - Session title: .largeTitle, bold, max 2 lines
> - Metadata block: use Form(.insetGrouped) with RoundedRectangle background
>
> **TOOLBAR:**
> - Move "993 sessions / 380.7M" to bottom status bar
> - Project selector as proper .menu Picker

**Why it works:** Vague feedback ("make it look better") produces vague results. Naming specific SwiftUI modifiers, referencing system apps (Mail.app), and organizing feedback by UI region gives the AI concrete targets.

**Adapt this:** Organize feedback by region (sidebar, toolbar, detail). Reference system apps. Name specific framework APIs when you know them.

---

### Phase 7: Collaborative Design for Hard Problems

When the first approach fails, switch to collaborative mode:

> **Enter planning mode. Ask me at least 5-6 questions so we can precisely determine how projects should be split.**

The initial project detection (based on working directory) put 99.6% of sessions into "Home." Instead of patching, Claude entered planning mode and asked 6 structured questions. The answers led to a completely new algorithm: a 5-level detection cascade with content analysis.

**Why it works:** Some problems need human judgment. By asking the AI to ask *you* questions, you surface the constraints and preferences that the AI can't guess.

**Adapt this:** When something isn't working, don't iterate blindly. Say "enter planning mode, ask me questions about X." Let the AI interview you, then design a solution based on your answers.

---

### Phase 8: Open-Source Preparation

> **Are there any personal data issues if I share this on GitHub?**
> *Claude: "Yes — hardcoded paths, usernames, and project mappings."*
> **Prepare it for publication.**

This triggered a separate pass: removing hardcoded data, generalizing detection logic, writing a comprehensive README, translating the UI to English.

**Why it works:** Treating open-source prep as a discrete phase (not an afterthought) ensures nothing leaks. The AI audits its own code for personal data.

**Adapt this:** Before publishing, explicitly ask "is there personal data in this codebase?" Then say "prepare for publication."

---

## The Full Timeline

| Phase | Duration | What happened |
|-------|----------|--------------|
| Inspiration | 10 min | Parsed 76 blog posts → "personal corporation" concept |
| Data Analysis | 5 min | Analyzed 1,169 own sessions → discovered the gap |
| HTML Prototype | 3 min | Throwaway proof of concept |
| Reference Architecture | — | "Use NetNewsWire as reference" → 3-column app |
| UX Research | 3.7 min | 4 parallel agents → 40+ feature catalog |
| Prioritization | — | 6 features selected for single pass |
| JSONL Discovery | 1 min | Undocumented format reverse-engineered |
| Implementation | 4 min | 5 files, ~700 lines, 0 errors |
| UI Feedback | 5 min | Structured per-region refinement |
| Testing & Polish | 17 min | Manual testing, all features working |
| Hard Problem (Detection) | 10 min | Collaborative Q&A → new algorithm |
| Open-Source Prep | 15 min | Remove personal data, English UI, README |

**Total: ~32 minutes of implementation. ~75 minutes end-to-end including research, inspiration, and polish.**

> **A note on efficiency:** The entire process from idea to working binary took ~75 minutes. Shoutout to everyone whose "change button color" ticket has been sitting in JIRA for two weeks. I feel your pain, but I can't share it.

## Key Techniques

1. **Parse everything, decide later** — Exhaustive data collection reveals patterns that selective sampling misses
2. **Analyze your own data first** — The best tools come from real problems you already have
3. **Throwaway prototype** — Build something ugly fast, then react to it
4. **Reference, don't invent** — Point to an existing open-source app's architecture instead of describing UI from scratch
5. **Research in parallel** — Launch multiple agents to survey the problem space before writing code
6. **Tier your features** — Catalog everything, then ruthlessly select Tier 1 for a single pass
7. **Spec before code** — Write a detailed plan naming every file, model, and function
8. **Structured feedback** — Organize UI feedback by region, reference system apps, name APIs
9. **Collaborative design** — When stuck, ask the AI to interview you with structured questions
10. **Separate open-source pass** — Audit for personal data, generalize hardcoded logic, write README

## Reproducibility

This workflow was tested on macOS with Swift/SwiftUI, but the methodology is language-agnostic:
- **Web apps** — Reference a Next.js/SvelteKit template instead of NetNewsWire
- **CLI tools** — Reference a well-structured Go/Rust CLI instead of a GUI app
- **APIs** — Research existing API designs in parallel, spec your endpoints, implement in one pass

The critical factor isn't the hardware or the subscription tier — it's the **inspiration → data → research → spec → implement** pipeline that eliminates guesswork before code is written.

The hardware and Opus access make it faster. The methodology makes it work.
