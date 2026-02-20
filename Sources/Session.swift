@_exported import Foundation

struct Session: Identifiable, Hashable {
    let id: String          // session UUID (filename)
    let timestamp: Date
    let project: String
    let cwd: String
    let title: String       // first user message, truncated to ~60 chars
    let summary: String     // first 3 user messages joined
    let sizeBytes: Int
    let userMsgCount: Int
    let assistantMsgCount: Int

    // Enhanced fields (Step 1)
    let inputTokens: Int
    let outputTokens: Int
    let cacheReadTokens: Int
    let cacheCreationTokens: Int
    let toolCounts: [String: Int]   // tool name → call count
    let model: String               // from first assistant message
    let durationMs: Int             // sum of turn_duration records
    let gitBranch: String

    var timeString: String {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f.string(from: timestamp)
    }

    var dateString: String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: timestamp)
    }

    var sizeString: String {
        if sizeBytes < 1024 { return "\(sizeBytes)B" }
        else if sizeBytes < 1024 * 1024 { return "\(sizeBytes / 1024)K" }
        else { return String(format: "%.1fM", Double(sizeBytes) / (1024 * 1024)) }
    }

    var resumeCommand: String {
        "claude --resume \(id)"
    }

    /// Preview text for timeline second line — second+ user messages
    var preview: String {
        if let range = summary.range(of: " → ") {
            return String(summary[range.upperBound...])
        }
        return ""
    }

    // MARK: - Computed properties (Enhanced)

    var totalTokens: Int {
        inputTokens + outputTokens + cacheReadTokens + cacheCreationTokens
    }

    var estimatedCostUSD: Double {
        estimateCost(model: model, input: inputTokens, output: outputTokens,
                     cacheRead: cacheReadTokens, cacheCreation: cacheCreationTokens)
    }

    var durationString: String {
        let totalSeconds = durationMs / 1000
        if totalSeconds < 60 { return "\(totalSeconds)s" }
        let minutes = totalSeconds / 60
        if minutes < 60 { return "\(minutes)m" }
        let hours = minutes / 60
        let remainMinutes = minutes % 60
        if remainMinutes == 0 { return "\(hours)h" }
        return "\(hours)h \(remainMinutes)m"
    }

    var costString: String {
        if estimatedCostUSD < 0.01 { return "<$0.01" }
        return String(format: "$%.2f", estimatedCostUSD)
    }

    var tokenString: String {
        let t = totalTokens
        if t < 1000 { return "\(t)" }
        else if t < 1_000_000 { return "\(t / 1000)K" }
        else { return String(format: "%.1fM", Double(t) / 1_000_000) }
    }

    var topTools: [(name: String, count: Int)] {
        toolCounts.sorted { $0.value > $1.value }
            .map { (name: $0.key, count: $0.value) }
    }

    var shortModelName: String {
        shortModelDisplay(model)
    }
}

// MARK: - Cost estimation

/// Pricing per million tokens (Claude 4.5 series, Nov 2025)
struct Pricing {
    let inputPer1M: Double
    let outputPer1M: Double

    var cacheReadPer1M: Double { inputPer1M * 0.1 }     // 90% discount
    var cacheCreatePer1M: Double { inputPer1M * 1.25 }   // 25% surcharge

    static let opus = Pricing(inputPer1M: 5.0, outputPer1M: 25.0)
    static let sonnet = Pricing(inputPer1M: 3.0, outputPer1M: 15.0)
    static let haiku = Pricing(inputPer1M: 1.0, outputPer1M: 5.0)

    static func forModel(_ model: String) -> Pricing {
        let m = model.lowercased()
        if m.contains("opus") { return .opus }
        if m.contains("sonnet") { return .sonnet }
        if m.contains("haiku") { return .haiku }
        return .sonnet // default
    }
}

func estimateCost(model: String, input: Int, output: Int,
                  cacheRead: Int, cacheCreation: Int) -> Double {
    let p = Pricing.forModel(model)

    let cost = (Double(input) * p.inputPer1M
              + Double(output) * p.outputPer1M
              + Double(cacheRead) * p.cacheReadPer1M
              + Double(cacheCreation) * p.cacheCreatePer1M) / 1_000_000.0

    return cost
}

func shortModelDisplay(_ model: String) -> String {
    let m = model.lowercased()
    if m.contains("opus-4-6") || m.contains("opus-4.6") { return "Opus 4.6" }
    if m.contains("opus-4-5") || m.contains("opus-4.5") { return "Opus 4.5" }
    if m.contains("opus") { return "Opus" }
    if m.contains("sonnet-4-6") || m.contains("sonnet-4.6") { return "Sonnet 4.6" }
    if m.contains("sonnet-4-5") || m.contains("sonnet-4.5") { return "Sonnet 4.5" }
    if m.contains("sonnet") { return "Sonnet" }
    if m.contains("haiku") { return "Haiku" }
    if model.isEmpty { return "—" }
    return model
}

// MARK: - Project detection

let containerDirs: Set<String> = [
    "Projects", "Developer", "Documents", "Desktop",
    "Code", "repos", "src", "work"
]

/// Extract project name from an absolute file path.
/// Special-cases .claude/ subfolders; skips common container directories.
/// Returns nil if path is not under home or yields no meaningful project.
/// Set `requireChildren` to true to only match directories (path has components after project).
func extractProjectFromPath(_ path: String, requireChildren: Bool = false) -> String? {
    let home = NSHomeDirectory()
    let relative: String
    if path.hasPrefix(home + "/") {
        relative = String(path.dropFirst(home.count + 1))
    } else if path.hasPrefix("~/") {
        relative = String(path.dropFirst(2))
    } else {
        return nil
    }

    let components = relative.split(separator: "/").map(String.init)
    guard !components.isEmpty else { return nil }

    // Special handling for .claude/ subfolders
    if components.first == ".claude" && components.count >= 2 {
        let sub = components[1]
        switch sub {
        case "skills":  return "skills"
        case "rules":   return "rules"
        case "memory":  return "memory"
        case "projects":
            // ~/.claude/projects/*/memory/* → "memory"
            if components.count >= 4 && components[3] == "memory" {
                return "memory"
            }
            return ".claude"
        default:        return ".claude"
        }
    }

    // General case: skip containers, find first meaningful component
    for (i, component) in components.enumerated() where !containerDirs.contains(component) {
        if requireChildren && i >= components.count - 1 {
            return nil
        }
        return component
    }

    return nil
}

/// Detect project name from cwd path or session directory name.
/// 1. If cwd ≠ home → extract from path (skip common container dirs)
/// 2. Try session directory name
/// 3. Fallback → "Home"
func detectProject(cwd: String, sessionDir: String) -> String {
    let home = NSHomeDirectory()

    // Case 1: cwd is a specific directory (not home) — extract project from path
    if !cwd.isEmpty && cwd != home && cwd != "~" {
        if let project = extractProjectFromPath(cwd) {
            return project
        }
    }

    // Case 2: cwd is home or empty — try session directory name
    // Session dirs are encoded paths: /Users/foo/bar → -Users-foo-bar
    if !sessionDir.isEmpty {
        let encodedHome = home.replacingOccurrences(of: "/", with: "-")
        var remainder = sessionDir
        if remainder.hasPrefix(encodedHome) {
            remainder = String(remainder.dropFirst(encodedHome.count))
        }
        if remainder.hasPrefix("-") {
            remainder = String(remainder.dropFirst())
        }
        if !remainder.isEmpty {
            // Decode: convert dashes to slashes, apply extractProjectFromPath
            let decoded = home + "/" + remainder.replacingOccurrences(of: "-", with: "/")
            if let project = extractProjectFromPath(decoded) {
                return project
            }
            return remainder
        }
    }

    return "Home"
}

/// Detect project by analyzing file paths from tool_use calls.
/// Finds the most common project directory across all accessed files.
func detectProjectFromPaths(_ paths: [String]) -> String? {
    var projectCounts: [String: Int] = [:]

    for path in paths {
        if let project = extractProjectFromPath(path, requireChildren: true) {
            projectCounts[project, default: 0] += 1
        }
    }

    // Return the most common project (minimum 2 file accesses to avoid noise)
    guard let best = projectCounts.max(by: { $0.value < $1.value }),
          best.value >= 2 else { return nil }
    return best.key
}

// Detect project from content of first N user messages.
// swiftlint:disable force_try
private let urlRegex = try! NSRegularExpression(
    pattern: #"(?:github|gitlab)\.com/[^/\s]+/([^/\s?#]+)"#)
private let pathRegex = try! NSRegularExpression(
    pattern: #"(?:~/|/Users/[^/\s]+/)[^\s,;\"'\]\)>]+"#)
// swiftlint:enable force_try

/// Looks for GitHub/GitLab URLs and file paths in text.
func detectProjectFromContent(_ messages: [String]) -> String? {
    var projectCounts: [String: Int] = [:]

    for msg in messages {
        // GitHub/GitLab URLs: github.com/user/repo or gitlab.com/user/repo
        let urlMatches = urlRegex.matches(in: msg, range: NSRange(msg.startIndex..., in: msg))
        for match in urlMatches {
            if let range = Range(match.range(at: 1), in: msg) {
                var repo = String(msg[range])
                // Strip .git suffix if present
                if repo.hasSuffix(".git") { repo = String(repo.dropLast(4)) }
                projectCounts[repo, default: 0] += 1
            }
        }

        // File paths in text: ~/path or /Users/*/path
        let pathMatches = pathRegex.matches(in: msg, range: NSRange(msg.startIndex..., in: msg))
        for match in pathMatches {
            if let range = Range(match.range, in: msg) {
                let path = String(msg[range])
                if let project = extractProjectFromPath(path) {
                    projectCounts[project, default: 0] += 1
                }
            }
        }
    }

    // Return most frequent, no minimum threshold (content mentions are intentional)
    guard let best = projectCounts.max(by: { $0.value < $1.value }) else { return nil }
    return best.key
}

// MARK: - JSONL parsing

func parseSession(at path: String, sessionDir: String) -> Session? {
    let url = URL(fileURLWithPath: path)
    let sessionId = url.deletingPathExtension().lastPathComponent

    guard let attrs = try? FileManager.default.attributesOfItem(atPath: path),
          let fileSize = attrs[.size] as? Int else { return nil }

    guard let data = FileManager.default.contents(atPath: path),
          let text = String(data: data, encoding: .utf8) else { return nil }

    var firstTimestamp: Date?
    var cwd: String?
    var userMessages: [String] = []
    var userCount = 0
    var assistantCount = 0

    // Enhanced parsing state
    var inputTokens = 0
    var outputTokens = 0
    var cacheReadTokens = 0
    var cacheCreationTokens = 0
    var toolCounts: [String: Int] = [:]
    var model = ""
    var durationMs = 0
    var gitBranch = ""
    var filePaths: [String] = []

    let iso = ISO8601DateFormatter()
    iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

    let isoBasic = ISO8601DateFormatter()
    isoBasic.formatOptions = [.withInternetDateTime]

    for line in text.components(separatedBy: "\n") {
        guard !line.isEmpty,
              let lineData = line.data(using: .utf8),
              let obj = try? JSONSerialization.jsonObject(with: lineData) as? [String: Any]
        else { continue }

        // Timestamp
        if firstTimestamp == nil, let ts = obj["timestamp"] as? String {
            firstTimestamp = iso.date(from: ts) ?? isoBasic.date(from: ts)
        }

        // CWD
        if cwd == nil, let c = obj["cwd"] as? String {
            cwd = c
        }

        // Git branch — first non-empty, non-HEAD value
        if gitBranch.isEmpty, let gb = obj["gitBranch"] as? String,
           !gb.isEmpty, gb != "HEAD" {
            gitBranch = gb
        }

        // Message type
        guard let type = obj["type"] as? String else { continue }

        if type == "user" {
            userCount += 1
            if userMessages.count < 5,
               let msg = obj["message"] as? [String: Any] {
                if let content = msg["content"] as? String, !content.isEmpty {
                    userMessages.append(content)
                } else if let blocks = msg["content"] as? [[String: Any]] {
                    for block in blocks {
                        if block["type"] as? String == "text",
                           let t = block["text"] as? String, !t.isEmpty {
                            userMessages.append(t)
                            break
                        }
                    }
                }
            }
        } else if type == "assistant" {
            assistantCount += 1

            if let msg = obj["message"] as? [String: Any] {
                // Model — from first assistant message
                if model.isEmpty, let m = msg["model"] as? String {
                    model = m
                }

                // Usage — token counts
                if let usage = msg["usage"] as? [String: Any] {
                    inputTokens += usage["input_tokens"] as? Int ?? 0
                    outputTokens += usage["output_tokens"] as? Int ?? 0
                    cacheReadTokens += usage["cache_read_input_tokens"] as? Int ?? 0
                    cacheCreationTokens += usage["cache_creation_input_tokens"] as? Int ?? 0
                }

                // Tool use — count tool calls + collect file paths
                if let content = msg["content"] as? [[String: Any]] {
                    for block in content {
                        if block["type"] as? String == "tool_use",
                           let toolName = block["name"] as? String {
                            toolCounts[toolName, default: 0] += 1

                            // Extract file paths from tool inputs
                            if let input = block["input"] as? [String: Any] {
                                for key in ["file_path", "path", "notebook_path"] {
                                    if let fp = input[key] as? String, fp.hasPrefix("/") {
                                        filePaths.append(fp)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        } else if type == "system" {
            // Turn duration
            if let subtype = obj["subtype"] as? String,
               subtype == "turn_duration",
               let dur = obj["durationMs"] as? Int {
                durationMs += dur
            }
        }
    }

    guard let ts = firstTimestamp else { return nil }

    // Project detection cascade: filePaths → cwd → sessionDir → content → fallback
    let detectedProject: String
    if let fromPaths = detectProjectFromPaths(filePaths) {
        detectedProject = fromPaths
    } else {
        let cwdProject = detectProject(cwd: cwd ?? "", sessionDir: sessionDir)
        if cwdProject != "Home" {
            detectedProject = cwdProject
        } else if let fromContent = detectProjectFromContent(Array(userMessages.prefix(5))) {
            detectedProject = fromContent
        } else if filePaths.isEmpty && toolCounts.isEmpty {
            detectedProject = "Chat"
        } else {
            detectedProject = "Home"
        }
    }

    // Build summary
    let summary = userMessages.prefix(3).map { msg in
        var cleaned = msg
        // Remove system-reminder tags
        while let range = cleaned.range(of: "<system-reminder>.*?</system-reminder>",
                                         options: .regularExpression) {
            cleaned.removeSubrange(range)
        }
        // Remove other HTML tags
        while let range = cleaned.range(of: "<[^>]+>", options: .regularExpression) {
            cleaned.removeSubrange(range)
        }
        cleaned = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleaned.count > 120 {
            return String(cleaned.prefix(120)) + "..."
        }
        return cleaned
    }
    .filter { !$0.isEmpty }
    .joined(separator: " → ")

    // Title: extract from first markdown heading, or truncate first message
    let firstMsg = userMessages.first.map { msg -> String in
        var cleaned = msg
        while let range = cleaned.range(of: "<system-reminder>.*?</system-reminder>",
                                         options: .regularExpression) {
            cleaned.removeSubrange(range)
        }
        while let range = cleaned.range(of: "<[^>]+>", options: .regularExpression) {
            cleaned.removeSubrange(range)
        }
        cleaned = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)

        // If the message contains a markdown heading, use it as title
        for line in cleaned.components(separatedBy: "\n") {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("# ") || trimmed.hasPrefix("## ") || trimmed.hasPrefix("### ") {
                var heading = trimmed
                while heading.hasPrefix("#") { heading = String(heading.dropFirst()) }
                heading = heading.trimmingCharacters(in: .whitespaces)
                if !heading.isEmpty {
                    if heading.count > 80 {
                        return String(heading.prefix(80)) + "..."
                    }
                    return heading
                }
            }
        }

        if cleaned.count > 60 {
            return String(cleaned.prefix(60)) + "..."
        }
        return cleaned
    } ?? ""

    return Session(
        id: sessionId,
        timestamp: ts,
        project: detectedProject,
        cwd: cwd ?? "~",
        title: firstMsg.isEmpty ? "Untitled" : firstMsg,
        summary: summary.isEmpty ? "—" : summary,
        sizeBytes: fileSize,
        userMsgCount: userCount,
        assistantMsgCount: assistantCount,
        inputTokens: inputTokens,
        outputTokens: outputTokens,
        cacheReadTokens: cacheReadTokens,
        cacheCreationTokens: cacheCreationTokens,
        toolCounts: toolCounts,
        model: model,
        durationMs: durationMs,
        gitBranch: gitBranch
    )
}
