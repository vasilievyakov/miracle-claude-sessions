import Testing
@testable import ClaudeSessions

// MARK: - Helpers

private func fixturePath(_ name: String) -> String {
    guard let url = Bundle.module.url(forResource: name, withExtension: "jsonl", subdirectory: "Fixtures") else {
        fatalError("Fixture \(name).jsonl not found in bundle")
    }
    return url.path
}

// MARK: - parseSession tests

@Suite("parseSession")
struct ParserTests {

    // MARK: - Valid session

    @Test("valid session parses all fields")
    func validSession() {
        let path = fixturePath("valid_session")
        let session = parseSession(at: path, sessionDir: "test-dir")
        #expect(session != nil)
        guard let s = session else { return }

        #expect(s.userMsgCount == 2)
        #expect(s.assistantMsgCount == 2)
        #expect(s.model == "claude-sonnet-4-5-20251101")
        #expect(s.gitBranch == "main")
        #expect(s.cwd == "/Users/testuser/Projects/myapp")
    }

    @Test("valid session — correct token counts")
    func validSessionTokens() {
        let path = fixturePath("valid_session")
        guard let s = parseSession(at: path, sessionDir: "test-dir") else {
            Issue.record("Failed to parse")
            return
        }
        // 100 + 50 = 150 input
        #expect(s.inputTokens == 150)
        // 200 + 30 = 230 output
        #expect(s.outputTokens == 230)
        // 50 + 150 = 200 cache read
        #expect(s.cacheReadTokens == 200)
        // 25 + 0 = 25 cache creation
        #expect(s.cacheCreationTokens == 25)
    }

    @Test("valid session — correct duration")
    func validSessionDuration() {
        let path = fixturePath("valid_session")
        guard let s = parseSession(at: path, sessionDir: "test-dir") else {
            Issue.record("Failed to parse")
            return
        }
        // 5000 + 2000 = 7000
        #expect(s.durationMs == 7000)
    }

    @Test("valid session — correct tool detection")
    func validSessionTools() {
        let path = fixturePath("valid_session")
        guard let s = parseSession(at: path, sessionDir: "test-dir") else {
            Issue.record("Failed to parse")
            return
        }
        #expect(s.toolCounts["Read"] == 1)
    }

    @Test("valid session — title from first message")
    func validSessionTitle() {
        let path = fixturePath("valid_session")
        guard let s = parseSession(at: path, sessionDir: "test-dir") else {
            Issue.record("Failed to parse")
            return
        }
        #expect(s.title == "Fix the login bug")
    }

    @Test("valid session — summary with arrows")
    func validSessionSummary() {
        let path = fixturePath("valid_session")
        guard let s = parseSession(at: path, sessionDir: "test-dir") else {
            Issue.record("Failed to parse")
            return
        }
        #expect(s.summary.contains("Fix the login bug"))
        #expect(s.summary.contains("→"))
    }

    @Test("valid session — shortModelDisplay Sonnet 4.5")
    func validSessionModel() {
        let path = fixturePath("valid_session")
        guard let s = parseSession(at: path, sessionDir: "test-dir") else {
            Issue.record("Failed to parse")
            return
        }
        #expect(s.shortModelName == "Sonnet 4.5")
    }

    @Test("valid session — Sonnet cost calculation")
    func validSessionCost() {
        let path = fixturePath("valid_session")
        guard let s = parseSession(at: path, sessionDir: "test-dir") else {
            Issue.record("Failed to parse")
            return
        }
        // Sonnet: 150 input * $3/M + 230 output * $15/M + 200 cache_read * $0.30/M + 25 cache_create * $3.75/M
        // = 0.00045 + 0.00345 + 0.00006 + 0.00009375 = 0.00405375
        #expect(s.estimatedCostUSD > 0.004)
        #expect(s.estimatedCostUSD < 0.005)
    }

    @Test("valid session — ID is filename")
    func sessionId() {
        let path = fixturePath("valid_session")
        guard let s = parseSession(at: path, sessionDir: "test-dir") else {
            Issue.record("Failed to parse")
            return
        }
        #expect(s.id == "valid_session")
    }

    @Test("valid session — timestamp parsed correctly")
    func timestampParsing() {
        let path = fixturePath("valid_session")
        guard let s = parseSession(at: path, sessionDir: "test-dir") else {
            Issue.record("Failed to parse")
            return
        }
        let cal = Calendar.current
        let utc = TimeZone(identifier: "UTC")!
        let components = cal.dateComponents(in: utc, from: s.timestamp)
        #expect(components.year == 2026)
        #expect(components.month == 1)
        #expect(components.day == 15)
    }

    // MARK: - Minimal session

    @Test("minimal session with one user message")
    func minimalSession() {
        let path = fixturePath("minimal_session")
        let session = parseSession(at: path, sessionDir: "test-dir")
        #expect(session != nil)
        guard let s = session else { return }

        #expect(s.userMsgCount == 1)
        #expect(s.assistantMsgCount == 0)
        #expect(s.title == "Hello, what is Swift?")
        #expect(s.inputTokens == 0)
        #expect(s.model.isEmpty)
        #expect(s.toolCounts.isEmpty)
        #expect(s.estimatedCostUSD == 0.0)
    }

    // MARK: - Empty session

    @Test("empty file returns nil")
    func emptyFile() {
        let path = fixturePath("empty_session")
        let session = parseSession(at: path, sessionDir: "test-dir")
        #expect(session == nil)
    }

    // MARK: - Malformed session

    @Test("malformed JSON lines are skipped gracefully")
    func malformedSession() {
        let path = fixturePath("malformed_session")
        let session = parseSession(at: path, sessionDir: "test-dir")
        #expect(session != nil)
        guard let s = session else { return }

        #expect(s.userMsgCount == 1)
        #expect(s.assistantMsgCount == 1)
        #expect(s.model == "claude-sonnet-4-5-20251101")
        #expect(s.durationMs == 3000)
    }

    // MARK: - Future fields (graceful degradation)

    @Test("future fields — does not crash")
    func futureFields() {
        let path = fixturePath("future_fields")
        let session = parseSession(at: path, sessionDir: "test-dir")
        #expect(session != nil)
    }

    @Test("future fields — unknown type skipped")
    func futureFieldsUnknownType() {
        let path = fixturePath("future_fields")
        guard let s = parseSession(at: path, sessionDir: "test-dir") else {
            Issue.record("Failed to parse")
            return
        }
        #expect(s.userMsgCount == 1)
        #expect(s.assistantMsgCount == 1)
    }

    @Test("future fields — unknown model returns raw string")
    func futureFieldsUnknownModel() {
        let path = fixturePath("future_fields")
        guard let s = parseSession(at: path, sessionDir: "test-dir") else {
            Issue.record("Failed to parse")
            return
        }
        #expect(s.model == "claude-future-model-99")
        #expect(s.shortModelName == "claude-future-model-99")
    }

    // MARK: - Unicode paths

    @Test("unicode paths — does not crash")
    func unicodePaths() {
        let path = fixturePath("unicode_paths")
        let session = parseSession(at: path, sessionDir: "test-dir")
        #expect(session != nil)
    }

    @Test("unicode paths — cwd preserved")
    func unicodePathsCwd() {
        let path = fixturePath("unicode_paths")
        guard let s = parseSession(at: path, sessionDir: "test-dir") else {
            Issue.record("Failed to parse")
            return
        }
        #expect(s.cwd.contains("Проекты"))
    }

    @Test("unicode paths — content with emoji parsed")
    func unicodeEmoji() {
        let path = fixturePath("unicode_paths")
        guard let s = parseSession(at: path, sessionDir: "test-dir") else {
            Issue.record("Failed to parse")
            return
        }
        #expect(s.title.contains("🚀"))
    }

    // MARK: - Cost calculation accuracy

    @Test("cost calculation — Opus exact values")
    func costOpus() {
        let path = fixturePath("cost_opus")
        guard let s = parseSession(at: path, sessionDir: "test-dir") else {
            Issue.record("Failed to parse")
            return
        }
        // Opus: 1M input * $5 + 1M output * $25 + 1M cacheRead * $0.50 + 1M cacheCreate * $6.25
        // = 5.0 + 25.0 + 0.5 + 6.25 = 36.75
        #expect(abs(s.estimatedCostUSD - 36.75) < 0.001)
    }

    @Test("cost calculation — Sonnet exact values")
    func costSonnet() {
        let path = fixturePath("cost_sonnet")
        guard let s = parseSession(at: path, sessionDir: "test-dir") else {
            Issue.record("Failed to parse")
            return
        }
        // Sonnet: 1M input * $3 + 1M output * $15 + 1M cacheRead * $0.30 + 1M cacheCreate * $3.75
        // = 3.0 + 15.0 + 0.3 + 3.75 = 22.05
        #expect(abs(s.estimatedCostUSD - 22.05) < 0.001)
    }

    @Test("cost calculation — Haiku exact values")
    func costHaiku() {
        let path = fixturePath("cost_haiku")
        guard let s = parseSession(at: path, sessionDir: "test-dir") else {
            Issue.record("Failed to parse")
            return
        }
        // Haiku: 1M input * $1 + 1M output * $5 + 1M cacheRead * $0.10 + 1M cacheCreate * $1.25
        // = 1.0 + 5.0 + 0.1 + 1.25 = 7.35
        #expect(abs(s.estimatedCostUSD - 7.35) < 0.001)
    }

    // MARK: - Large session

    @Test("large session — 500 messages parsed")
    func largeSession() {
        let path = fixturePath("large_session")
        let session = parseSession(at: path, sessionDir: "test-dir")
        #expect(session != nil)
        guard let s = session else { return }
        #expect(s.userMsgCount == 250)
        #expect(s.assistantMsgCount == 250)
    }
}
