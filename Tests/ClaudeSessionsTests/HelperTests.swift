import Testing
import SwiftUI
@testable import ClaudeSessions

private let home = NSHomeDirectory()

// MARK: - projectIcon tests

@Suite("projectIcon")
struct ProjectIconTests {

    @Test("Chat → bubble.left.fill")
    func chatIcon() { #expect(projectIcon("Chat") == "bubble.left.fill") }

    @Test("skills → wand.and.stars")
    func skillsIcon() { #expect(projectIcon("skills") == "wand.and.stars") }

    @Test("rules → list.bullet.rectangle")
    func rulesIcon() { #expect(projectIcon("rules") == "list.bullet.rectangle") }

    @Test("memory → brain")
    func memoryIcon() { #expect(projectIcon("memory") == "brain") }

    @Test(".claude → gearshape.fill")
    func claudeIcon() { #expect(projectIcon(".claude") == "gearshape.fill") }

    @Test("Home → house.fill")
    func homeIcon() { #expect(projectIcon("Home") == "house.fill") }

    @Test("unknown project → circle.fill")
    func defaultIcon() { #expect(projectIcon("MyRandomProject") == "circle.fill") }
}

// MARK: - projectColor tests

@Suite("projectColor")
struct ProjectColorTests {

    @Test("deterministic: same input → same color")
    func deterministic() {
        let c1 = projectColor("TestProject")
        let c2 = projectColor("TestProject")
        #expect(c1 == c2)
    }

    @Test("different inputs → likely different colors")
    func differentInputs() {
        let c1 = projectColor("Alpha")
        let c2 = projectColor("Beta")
        let c3 = projectColor("Gamma")
        let allSame = (c1 == c2) && (c2 == c3)
        #expect(!allSame)
    }
}

// MARK: - formatDateHeader tests

@Suite("formatDateHeader")
struct FormatDateHeaderTests {

    @Test("today's date → Today")
    func today() {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        let todayStr = df.string(from: Date())
        #expect(formatDateHeader(todayStr) == "Today")
    }

    @Test("yesterday's date → Yesterday")
    func yesterday() {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        let yesterdayDate = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let str = df.string(from: yesterdayDate)
        #expect(formatDateHeader(str) == "Yesterday")
    }

    @Test("older date → formatted date string")
    func olderDate() {
        let result = formatDateHeader("2025-01-15")
        #expect(result.contains("January"))
        #expect(result.contains("15"))
    }

    @Test("invalid date → returns input")
    func invalidDate() {
        #expect(formatDateHeader("not-a-date") == "not-a-date")
    }
}

// MARK: - shortPath tests

@Suite("shortPath")
struct ShortPathTests {

    @Test("replaces home dir with ~")
    func homeReplacement() {
        let result = shortPath(home + "/Projects/App")
        #expect(result == "~/Projects/App")
    }

    @Test("non-home path unchanged")
    func nonHomePath() {
        #expect(shortPath("/var/log/app") == "/var/log/app")
    }

    @Test("exact home path → ~")
    func exactHome() {
        #expect(shortPath(home) == "~")
    }
}

// MARK: - toolIcon tests

@Suite("toolIcon")
struct ToolIconTests {

    @Test("known tools return specific icons")
    func knownTools() {
        #expect(toolIcon("Read") == "doc.text")
        #expect(toolIcon("write") == "square.and.pencil")
        #expect(toolIcon("Edit") == "pencil.line")
        #expect(toolIcon("bash") == "terminal")
        #expect(toolIcon("Grep") == "magnifyingglass")
        #expect(toolIcon("Glob") == "folder.badge.questionmark")
        #expect(toolIcon("WebSearch") == "globe")
    }

    @Test("MCP tools → globe")
    func mcpTools() { #expect(toolIcon("mcp__server__tool") == "globe") }

    @Test("unknown tool → wrench")
    func unknownTool() { #expect(toolIcon("SomeRandomTool") == "wrench") }
}

// MARK: - toolColor tests

@Suite("toolColor")
struct ToolColorTests {

    @Test("file tools → blue")
    func fileTools() {
        #expect(toolColor("Read") == .blue)
        #expect(toolColor("write") == .blue)
        #expect(toolColor("edit") == .blue)
        #expect(toolColor("glob") == .blue)
    }

    @Test("search tools → purple")
    func searchTools() {
        #expect(toolColor("grep") == .purple)
        #expect(toolColor("websearch") == .purple)
    }

    @Test("bash → orange")
    func bashTool() { #expect(toolColor("bash") == .orange) }

    @Test("MCP tools → teal")
    func mcpTools() { #expect(toolColor("mcp__exa__search") == .teal) }

    @Test("unknown → gray")
    func unknownTool() { #expect(toolColor("SomeUnknown") == .gray) }
}

// MARK: - cleanToolName tests

@Suite("cleanToolName")
struct CleanToolNameTests {

    @Test("MCP tool → last component")
    func mcpClean() { #expect(cleanToolName("mcp__server__web_search_exa") == "web_search_exa") }

    @Test("MCP with 2 parts → strip prefix")
    func mcpTwoParts() { #expect(cleanToolName("mcp__search") == "search") }

    @Test("regular tool → unchanged")
    func regularTool() {
        #expect(cleanToolName("Read") == "Read")
        #expect(cleanToolName("Bash") == "Bash")
    }
}

// MARK: - humanSize tests

@Suite("humanSize")
struct HumanSizeTests {

    @Test("bytes")
    func bytes() { #expect(humanSize(512) == "512B") }

    @Test("kilobytes")
    func kb() { #expect(humanSize(4096) == "4K") }

    @Test("megabytes")
    func mb() { #expect(humanSize(2_500_000) == "2.4M") }
}
