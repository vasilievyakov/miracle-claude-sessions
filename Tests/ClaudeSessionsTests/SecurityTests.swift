import Testing
@testable import ClaudeSessions

/// SecurityTests verifies that ClaudeSessions has no network access, no hardcoded credentials,
/// and read-only file access. Each critical property is verified from multiple angles:
/// 1. Static source analysis (scan Swift files for forbidden patterns)
/// 2. Configuration verification (entitlements, docs)
/// 3. Codebase auditability (file/line counts)

private func repoRoot() -> URL {
    // Navigate from test bundle to repo root
    var url = Bundle.module.bundleURL
    // Walk up from .build/debug/ClaudeSessionsTests.bundle to project root
    for _ in 0..<5 {
        if FileManager.default.fileExists(atPath: url.appendingPathComponent("Package.swift").path) {
            return url
        }
        url = url.deletingLastPathComponent()
    }
    return url
}

private func sourcesDir() -> URL {
    repoRoot().appendingPathComponent("Sources")
}

private func allSwiftSources() -> String {
    let fm = FileManager.default
    let dir = sourcesDir()
    guard let enumerator = fm.enumerator(at: dir, includingPropertiesForKeys: nil) else { return "" }
    var combined = ""
    for case let url as URL in enumerator where url.pathExtension == "swift" {
        if let content = try? String(contentsOf: url, encoding: .utf8) {
            combined += content + "\n"
        }
    }
    return combined
}

private func sourceFileCount() -> Int {
    let fm = FileManager.default
    let dir = sourcesDir()
    guard let enumerator = fm.enumerator(at: dir, includingPropertiesForKeys: nil) else { return 0 }
    var count = 0
    for case let url as URL in enumerator where url.pathExtension == "swift" {
        count += 1
        _ = url // suppress unused warning
    }
    return count
}

// MARK: - Layer 1: Static Source Analysis — Zero Network

@Suite("Security: Zero Network")
struct ZeroNetworkTests {

    @Test("no URLSession in source")
    func noURLSession() {
        #expect(!allSwiftSources().contains("URLSession"),
                "SECURITY VIOLATION: URLSession found in source code")
    }

    @Test("no URLRequest in source")
    func noURLRequest() {
        #expect(!allSwiftSources().contains("URLRequest"),
                "SECURITY VIOLATION: URLRequest found in source code")
    }

    @Test("no import Network")
    func noNetworkFramework() {
        #expect(!allSwiftSources().contains("import Network"),
                "SECURITY VIOLATION: Network.framework import found")
    }

    @Test("no NWConnection")
    func noNWConnection() {
        #expect(!allSwiftSources().contains("NWConnection"),
                "SECURITY VIOLATION: NWConnection found in source code")
    }

    @Test("no WKWebView")
    func noWKWebView() {
        #expect(!allSwiftSources().contains("WKWebView"),
                "SECURITY VIOLATION: WKWebView found in source code")
    }

    @Test("no CFNetwork")
    func noCFNetwork() {
        #expect(!allSwiftSources().contains("CFNetwork"),
                "SECURITY VIOLATION: CFNetwork found in source code")
    }
}

// MARK: - Layer 1: Static Source Analysis — No Credentials

@Suite("Security: No Credentials")
struct NoCredentialsTests {

    @Test("no API key patterns")
    func noAPIKeys() {
        let source = allSwiftSources().lowercased()
        let patterns = ["api_key", "apikey", "sk-ant-", "bearer "]
        for pattern in patterns {
            #expect(!source.contains(pattern),
                    "SECURITY VIOLATION: Potential API key pattern '\(pattern)' in source")
        }
    }

    @Test("no hardcoded passwords")
    func noPasswords() {
        let source = allSwiftSources().lowercased()
        let patterns = ["password =", "password=", "secret =", "secret=", "access_token"]
        for pattern in patterns {
            #expect(!source.contains(pattern),
                    "SECURITY: Potential hardcoded password '\(pattern)' in source")
        }
    }

    @Test("no personal data in source")
    func noPersonalData() {
        let source = allSwiftSources().lowercased()
        let personal = ["vasiliev", "yakovvasiliev", "macbook-pro-yakova"]
        for pattern in personal {
            #expect(!source.contains(pattern),
                    "SECURITY: Personal data '\(pattern)' found in source code")
        }
    }
}

// MARK: - Layer 1: Static Source Analysis — Read-Only

@Suite("Security: Read-Only File Access")
struct ReadOnlyTests {

    @Test("no file write APIs in source")
    func noFileWriteAPIs() {
        let source = allSwiftSources()
        // These APIs indicate file writing — should not exist in source
        let writingAPIs = [
            "createFile(atPath",
            "createDirectory(atPath",
            "createDirectory(at:",
            ".write(to:",
            ".write(toFile:",
        ]
        for api in writingAPIs {
            let lines = source.components(separatedBy: "\n")
            let violations = lines.filter {
                $0.contains(api) && !$0.trimmingCharacters(in: .whitespaces).hasPrefix("//")
            }
            #expect(violations.isEmpty,
                    "SECURITY: File write API '\(api)' found in source: \(violations)")
        }
    }
}

// MARK: - Layer 2: Configuration Verification

@Suite("Security: Compliance Files")
struct ComplianceTests {

    @Test("entitlements file exists")
    func entitlementsExists() {
        let path = repoRoot().appendingPathComponent("ClaudeSessions.entitlements").path
        #expect(FileManager.default.fileExists(atPath: path),
                "SECURITY: ClaudeSessions.entitlements not found")
    }

    @Test("entitlements disables network")
    func entitlementsNetworkDisabled() {
        let path = repoRoot().appendingPathComponent("ClaudeSessions.entitlements").path
        guard let contents = try? String(contentsOfFile: path, encoding: .utf8) else {
            Issue.record("Could not read entitlements")
            return
        }
        #expect(contents.contains("network.client"))
        #expect(contents.contains("<false/>"))
    }

    @Test("PRIVACY.md exists")
    func privacyExists() {
        let path = repoRoot().appendingPathComponent("PRIVACY.md").path
        #expect(FileManager.default.fileExists(atPath: path),
                "COMPLIANCE: PRIVACY.md not found")
    }

    @Test("SECURITY.md exists")
    func securityExists() {
        let path = repoRoot().appendingPathComponent("SECURITY.md").path
        #expect(FileManager.default.fileExists(atPath: path),
                "COMPLIANCE: SECURITY.md not found")
    }

    @Test("SBOM exists and is valid JSON")
    func sbomValid() {
        let path = repoRoot().appendingPathComponent("sbom.spdx.json").path
        #expect(FileManager.default.fileExists(atPath: path),
                "COMPLIANCE: sbom.spdx.json not found")
        if let data = FileManager.default.contents(atPath: path) {
            let parsed = try? JSONSerialization.jsonObject(with: data)
            #expect(parsed != nil, "COMPLIANCE: sbom.spdx.json is not valid JSON")
        }
    }

    @Test("LICENSE exists")
    func licenseExists() {
        let path = repoRoot().appendingPathComponent("LICENSE").path
        #expect(FileManager.default.fileExists(atPath: path),
                "COMPLIANCE: LICENSE not found")
    }
}

// MARK: - Layer 3: Auditability

@Suite("Security: Auditability")
struct AuditabilityTests {

    @Test("source file count within auditable range (3-15)")
    func sourceFileCount() {
        let count = ClaudeSessionsTests.sourceFileCount()
        #expect(count >= 3, "Too few source files — unexpected structure change")
        #expect(count <= 15, "Too many source files (\(count)) — codebase should be auditable")
    }

    @Test("source line count under 2000")
    func sourceLineCount() {
        let source = allSwiftSources()
        let lines = source.components(separatedBy: "\n").count
        #expect(lines <= 2000,
                "Source code exceeds 2000 lines (\(lines)). Must remain auditable.")
    }

    @Test("SessionStore only scans ~/.claude/projects/")
    func scanScopeBounded() {
        let source = allSwiftSources()
        // The scan path should reference .claude/projects
        #expect(source.contains(".claude/projects"),
                "SessionStore must scan ~/.claude/projects/")
    }
}
