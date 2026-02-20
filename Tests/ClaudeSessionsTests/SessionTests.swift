import Testing
@testable import ClaudeSessions

// Helper to get home directory without importing Foundation directly
private let home = NSHomeDirectory()

// MARK: - extractProjectFromPath tests

@Suite("extractProjectFromPath")
struct ExtractProjectTests {

    @Test("returns nil for non-home paths")
    func nonHomePath() {
        #expect(extractProjectFromPath("/etc/config") == nil)
        #expect(extractProjectFromPath("/var/log/app") == nil)
    }

    @Test("extracts project from ~/Projects/Foo/file")
    func projectsContainer() {
        #expect(extractProjectFromPath(home + "/Projects/MyApp/Sources/main.swift") == "MyApp")
    }

    @Test("skips multiple container dirs")
    func multipleContainers() {
        #expect(extractProjectFromPath(home + "/Developer/MyLib/Package.swift") == "MyLib")
    }

    @Test("handles tilde paths")
    func tildePaths() {
        #expect(extractProjectFromPath("~/Projects/TildeApp/file.txt") == "TildeApp")
    }

    @Test(".claude/skills → skills")
    func claudeSkills() {
        #expect(extractProjectFromPath(home + "/.claude/skills/my-skill.md") == "skills")
    }

    @Test(".claude/rules → rules")
    func claudeRules() {
        #expect(extractProjectFromPath(home + "/.claude/rules/auto-observe.md") == "rules")
    }

    @Test(".claude/memory → memory")
    func claudeMemory() {
        #expect(extractProjectFromPath(home + "/.claude/memory/projects/foo.md") == "memory")
    }

    @Test(".claude/projects/*/memory/* → memory")
    func claudeProjectMemory() {
        #expect(extractProjectFromPath(home + "/.claude/projects/abc/memory/data.json") == "memory")
    }

    @Test(".claude/projects → .claude")
    func claudeProjects() {
        #expect(extractProjectFromPath(home + "/.claude/projects/something/file.jsonl") == ".claude")
    }

    @Test(".claude/other → .claude")
    func claudeOther() {
        #expect(extractProjectFromPath(home + "/.claude/settings.json") == ".claude")
    }

    @Test("requireChildren: true skips leaf paths")
    func requireChildren() {
        #expect(extractProjectFromPath(home + "/Projects/MyApp", requireChildren: true) == nil)
        #expect(extractProjectFromPath(home + "/Projects/MyApp/file.txt", requireChildren: true) == "MyApp")
    }

    @Test("returns nil for empty relative path")
    func emptyRelative() {
        #expect(extractProjectFromPath(home + "/") == nil)
    }

    @Test("first non-container component becomes project")
    func firstNonContainer() {
        #expect(extractProjectFromPath(home + "/myproject/src/file.swift") == "myproject")
    }
}

// MARK: - detectProjectFromPaths tests

@Suite("detectProjectFromPaths")
struct DetectProjectFromPathsTests {

    @Test("returns nil for empty input")
    func emptyPaths() {
        #expect(detectProjectFromPaths([]) == nil)
    }

    @Test("returns nil for single file (below threshold)")
    func singleFile() {
        #expect(detectProjectFromPaths([home + "/Projects/App/file.swift"]) == nil)
    }

    @Test("returns project with 2+ file accesses")
    func twoFiles() {
        let paths = [
            home + "/Projects/MyApp/Sources/main.swift",
            home + "/Projects/MyApp/Sources/model.swift"
        ]
        #expect(detectProjectFromPaths(paths) == "MyApp")
    }

    @Test("returns most common project")
    func mostCommon() {
        let paths = [
            home + "/Projects/AppA/file1.swift",
            home + "/Projects/AppA/file2.swift",
            home + "/Projects/AppA/file3.swift",
            home + "/Projects/AppB/file1.swift",
            home + "/Projects/AppB/file2.swift",
        ]
        #expect(detectProjectFromPaths(paths) == "AppA")
    }
}

// MARK: - detectProjectFromContent tests

@Suite("detectProjectFromContent")
struct DetectProjectFromContentTests {

    @Test("detects GitHub URL")
    func githubUrl() {
        let result = detectProjectFromContent(["Check https://github.com/user/my-repo/issues/1"])
        #expect(result == "my-repo")
    }

    @Test("detects GitLab URL")
    func gitlabUrl() {
        let result = detectProjectFromContent(["See gitlab.com/org/cool-project for details"])
        #expect(result == "cool-project")
    }

    @Test("strips .git suffix from URLs")
    func gitSuffix() {
        let result = detectProjectFromContent(["Clone from https://github.com/user/repo.git"])
        #expect(result == "repo")
    }

    @Test("detects file paths in content")
    func filePaths() {
        let result = detectProjectFromContent(["Open ~/Projects/AwesomeApp/Sources/main.swift"])
        #expect(result == "AwesomeApp")
    }

    @Test("returns nil for no matches")
    func noMatches() {
        let result = detectProjectFromContent(["Hello, how are you?"])
        #expect(result == nil)
    }

    @Test("returns most frequent project")
    func mostFrequent() {
        let messages = [
            "Working on https://github.com/user/alpha",
            "Also check https://github.com/user/alpha/pulls",
            "And https://github.com/user/beta"
        ]
        #expect(detectProjectFromContent(messages) == "alpha")
    }
}

// MARK: - detectProject tests

@Suite("detectProject")
struct DetectProjectTests {

    @Test("extracts from cwd when not home")
    func cwdNotHome() {
        let result = detectProject(cwd: home + "/Projects/SomeApp", sessionDir: "")
        #expect(result == "SomeApp")
    }

    @Test("decodes session directory name")
    func sessionDirDecode() {
        let encoded = home.replacingOccurrences(of: "/", with: "-") + "-Projects-FooBar"
        let result = detectProject(cwd: home, sessionDir: encoded)
        #expect(result == "FooBar")
    }

    @Test("fallback to Home when no info")
    func fallbackHome() {
        let result = detectProject(cwd: home, sessionDir: "")
        #expect(result == "Home")
    }

    @Test("empty cwd falls through to sessionDir")
    func emptyCwd() {
        let encoded = home.replacingOccurrences(of: "/", with: "-") + "-Projects-SessionApp"
        let result = detectProject(cwd: "", sessionDir: encoded)
        #expect(result == "SessionApp")
    }
}

// MARK: - shortModelDisplay tests

@Suite("shortModelDisplay")
struct ShortModelDisplayTests {

    @Test("Opus 4.6")
    func opus46() {
        #expect(shortModelDisplay("claude-opus-4-6-20261001") == "Opus 4.6")
        #expect(shortModelDisplay("claude-opus-4.6") == "Opus 4.6")
    }

    @Test("Opus 4.5")
    func opus45() {
        #expect(shortModelDisplay("claude-opus-4-5-20251101") == "Opus 4.5")
    }

    @Test("generic Opus")
    func opusGeneric() {
        #expect(shortModelDisplay("claude-opus-latest") == "Opus")
    }

    @Test("Sonnet 4.6")
    func sonnet46() {
        #expect(shortModelDisplay("claude-sonnet-4-6-20261001") == "Sonnet 4.6")
    }

    @Test("Sonnet 4.5")
    func sonnet45() {
        #expect(shortModelDisplay("claude-sonnet-4-5-20251101") == "Sonnet 4.5")
    }

    @Test("generic Sonnet")
    func sonnetGeneric() {
        #expect(shortModelDisplay("claude-sonnet-latest") == "Sonnet")
    }

    @Test("Haiku")
    func haiku() {
        #expect(shortModelDisplay("claude-haiku-4-5-20251001") == "Haiku")
    }

    @Test("empty string → dash")
    func emptyModel() {
        #expect(shortModelDisplay("") == "—")
    }

    @Test("unknown model → raw string")
    func unknownModel() {
        #expect(shortModelDisplay("gpt-4o") == "gpt-4o")
    }
}

// MARK: - Computed properties tests

@Suite("Session computed properties")
struct SessionComputedTests {

    private func makeSession(
        sizeBytes: Int = 0,
        inputTokens: Int = 0,
        outputTokens: Int = 0,
        cacheReadTokens: Int = 0,
        cacheCreationTokens: Int = 0,
        durationMs: Int = 0,
        model: String = "claude-sonnet-4-5-20251101",
        toolCounts: [String: Int] = [:],
        summary: String = ""
    ) -> Session {
        Session(
            id: "test-id",
            timestamp: Date(),
            project: "TestProject",
            cwd: "~/test",
            title: "Test",
            summary: summary,
            sizeBytes: sizeBytes,
            userMsgCount: 1,
            assistantMsgCount: 1,
            inputTokens: inputTokens,
            outputTokens: outputTokens,
            cacheReadTokens: cacheReadTokens,
            cacheCreationTokens: cacheCreationTokens,
            toolCounts: toolCounts,
            model: model,
            durationMs: durationMs,
            gitBranch: ""
        )
    }

    @Test("sizeString: bytes")
    func sizeBytes() {
        #expect(makeSession(sizeBytes: 500).sizeString == "500B")
    }

    @Test("sizeString: kilobytes")
    func sizeKB() {
        #expect(makeSession(sizeBytes: 2048).sizeString == "2K")
    }

    @Test("sizeString: megabytes")
    func sizeMB() {
        #expect(makeSession(sizeBytes: 1_500_000).sizeString == "1.4M")
    }

    @Test("durationString: seconds")
    func durationSeconds() {
        #expect(makeSession(durationMs: 45000).durationString == "45s")
    }

    @Test("durationString: minutes")
    func durationMinutes() {
        #expect(makeSession(durationMs: 180_000).durationString == "3m")
    }

    @Test("durationString: hours with minutes")
    func durationHoursMinutes() {
        #expect(makeSession(durationMs: 5_400_000).durationString == "1h 30m")
    }

    @Test("durationString: exact hours")
    func durationExactHours() {
        #expect(makeSession(durationMs: 3_600_000).durationString == "1h")
    }

    @Test("costString: less than a cent")
    func costSubCent() {
        #expect(makeSession(inputTokens: 10, outputTokens: 5).costString == "<$0.01")
    }

    @Test("costString: normal cost")
    func costNormal() {
        let s = makeSession(inputTokens: 100_000, outputTokens: 10_000)
        #expect(s.costString == "$0.45")
    }

    @Test("tokenString: small")
    func tokenSmall() {
        #expect(makeSession(inputTokens: 500).tokenString == "500")
    }

    @Test("tokenString: thousands")
    func tokenThousands() {
        #expect(makeSession(inputTokens: 50_000).tokenString == "50K")
    }

    @Test("tokenString: millions")
    func tokenMillions() {
        #expect(makeSession(inputTokens: 1_500_000).tokenString == "1.5M")
    }

    @Test("totalTokens sums all token types")
    func totalTokens() {
        let s = makeSession(inputTokens: 100, outputTokens: 200, cacheReadTokens: 300, cacheCreationTokens: 400)
        #expect(s.totalTokens == 1000)
    }

    @Test("topTools sorted by count descending")
    func topToolsSorted() {
        let s = makeSession(toolCounts: ["Read": 5, "Bash": 10, "Write": 3])
        let names = s.topTools.map(\.name)
        #expect(names.first == "Bash")
        #expect(names.last == "Write")
    }

    @Test("preview extracts text after arrow")
    func previewExtract() {
        let s = makeSession(summary: "Fix login bug → Add tests → Commit")
        #expect(s.preview == "Add tests → Commit")
    }

    @Test("preview returns empty when no arrow")
    func previewEmpty() {
        let s = makeSession(summary: "Just one message")
        #expect(s.preview == "")
    }
}

// MARK: - Pricing tests

@Suite("Pricing")
struct PricingTests {

    @Test("Opus pricing constants")
    func opusPricing() {
        let p = Pricing.opus
        #expect(p.inputPer1M == 5.0)
        #expect(p.outputPer1M == 25.0)
        #expect(p.cacheReadPer1M == 0.5)
        #expect(p.cacheCreatePer1M == 6.25)
    }

    @Test("Sonnet pricing constants")
    func sonnetPricing() {
        let p = Pricing.sonnet
        #expect(p.inputPer1M == 3.0)
        #expect(p.outputPer1M == 15.0)
    }

    @Test("Haiku pricing constants")
    func haikuPricing() {
        let p = Pricing.haiku
        #expect(p.inputPer1M == 1.0)
        #expect(p.outputPer1M == 5.0)
    }

    @Test("forModel selects correct pricing")
    func forModel() {
        #expect(Pricing.forModel("claude-opus-4-5-20251101").inputPer1M == 5.0)
        #expect(Pricing.forModel("claude-sonnet-4-5-20251101").inputPer1M == 3.0)
        #expect(Pricing.forModel("claude-haiku-4-5-20251001").inputPer1M == 1.0)
        #expect(Pricing.forModel("unknown-model").inputPer1M == 3.0)
    }

    @Test("estimateCost calculation")
    func costCalc() {
        let cost = estimateCost(model: "claude-opus-4-5", input: 1_000_000, output: 1_000_000,
                                cacheRead: 0, cacheCreation: 0)
        #expect(abs(cost - 30.0) < 0.001)
    }

    @Test("estimateCost with cache")
    func costWithCache() {
        let cost = estimateCost(model: "claude-sonnet-4-5", input: 0, output: 0,
                                cacheRead: 1_000_000, cacheCreation: 1_000_000)
        #expect(abs(cost - 4.05) < 0.001)
    }
}
