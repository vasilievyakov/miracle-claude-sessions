import Testing
@testable import ClaudeSessions

private func fixturePath(_ name: String) -> String {
    guard let url = Bundle.module.url(forResource: name, withExtension: "jsonl", subdirectory: "Fixtures") else {
        fatalError("Fixture \(name).jsonl not found in bundle")
    }
    return url.path
}

// MARK: - Performance tests

@Suite("Performance")
struct PerformanceTests {

    @Test("large session (500 messages) parses under 1 second")
    func largeSessionParseTime() {
        let path = fixturePath("large_session")
        let start = Date()
        let session = parseSession(at: path, sessionDir: "test-dir")
        let elapsed = Date().timeIntervalSince(start)
        #expect(session != nil, "Large session should parse successfully")
        #expect(elapsed < 1.0, "Large session must parse in under 1s. Took: \(elapsed)s")
    }

    @Test("search over 500 sessions under 100ms")
    func searchPerformance() {
        let sessions = (0..<500).map { i in
            Session(
                id: "session-\(i)",
                timestamp: Date(),
                project: "project\(i % 10)",
                cwd: "/tmp/project\(i % 10)",
                title: "Fix the authentication bug in session \(i)",
                summary: "Fix the auth bug → Add tests → Commit changes",
                sizeBytes: 1024,
                userMsgCount: 1,
                assistantMsgCount: 1,
                inputTokens: 100,
                outputTokens: 100,
                cacheReadTokens: 0,
                cacheCreationTokens: 0,
                toolCounts: [:],
                model: "claude-sonnet-4-5-20251101",
                durationMs: 1000,
                gitBranch: "main"
            )
        }
        let query = "auth"
        let start = Date()
        let results = sessions.filter {
            $0.title.localizedCaseInsensitiveContains(query) ||
            $0.summary.localizedCaseInsensitiveContains(query) ||
            $0.project.localizedCaseInsensitiveContains(query)
        }
        let elapsed = Date().timeIntervalSince(start)
        #expect(elapsed < 0.1, "Search over 500 sessions must complete in under 100ms. Took: \(elapsed)s")
        #expect(!results.isEmpty, "Search should find results")
    }
}

// MARK: - Idempotency tests

@Suite("Idempotency")
struct IdempotencyTests {

    @Test("parsing is idempotent over 100 runs")
    func parsingIdempotent() {
        let path = fixturePath("valid_session")
        guard let first = parseSession(at: path, sessionDir: "test-dir") else {
            Issue.record("Failed to parse first time")
            return
        }
        for i in 0..<100 {
            guard let repeated = parseSession(at: path, sessionDir: "test-dir") else {
                Issue.record("Failed to parse on run \(i)")
                return
            }
            #expect(first.inputTokens == repeated.inputTokens,
                    "Run \(i): inputTokens changed")
            #expect(first.outputTokens == repeated.outputTokens,
                    "Run \(i): outputTokens changed")
            #expect(first.model == repeated.model,
                    "Run \(i): model changed")
            #expect(abs(first.estimatedCostUSD - repeated.estimatedCostUSD) < 0.000001,
                    "Run \(i): cost changed")
        }
    }

    @Test("projectColor is deterministic over 100 calls")
    func projectColorDeterministic() {
        let name = "myapp"
        let first = projectColor(name)
        for i in 0..<100 {
            let result = projectColor(name)
            #expect(result == first, "projectColor not deterministic on call \(i)")
        }
    }

    @Test("different projects get different colors (mostly)")
    func projectColorDistribution() {
        let projects = ["myapp", "backend", "frontend", "database", "api", "mobile", "infra"]
        let colors = projects.map { "\(projectColor($0))" }
        let unique = Set(colors)
        #expect(unique.count > 1, "All projects got same color — hash function broken")
    }
}
