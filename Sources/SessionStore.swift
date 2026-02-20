import Foundation
import Combine

@MainActor
class SessionStore: ObservableObject {
    @Published var sessions: [Session] = []
    @Published var isLoading = false
    @Published var searchText = ""
    @Published var selectedCollection: SidebarItem? = .all
    @Published var selectedDays: Int = 7

    private let projectsRoot = NSString(string: "~/.claude/projects").expandingTildeInPath

    var projects: [String] {
        let all = Set(sessions.map(\.project))
        return all.sorted()
    }

    var filteredSessions: [Session] {
        let cal = Calendar.current
        let now = Date()

        return sessions.filter { session in
            // Collection filter
            let matchCollection: Bool
            switch selectedCollection {
            case .all, nil:
                matchCollection = true
            case .today:
                matchCollection = cal.isDateInToday(session.timestamp)
            case .thisWeek:
                matchCollection = cal.isDate(session.timestamp, equalTo: now, toGranularity: .weekOfYear)
            case .largeSessions:
                matchCollection = session.totalTokens > 100_000
            case .project(let p):
                matchCollection = session.project == p
            }

            // Search filter
            let matchSearch = searchText.isEmpty ||
                session.title.localizedCaseInsensitiveContains(searchText) ||
                session.summary.localizedCaseInsensitiveContains(searchText) ||
                session.project.localizedCaseInsensitiveContains(searchText)

            return matchCollection && matchSearch
        }
    }

    func sessionCount(for project: String) -> Int {
        sessions.filter { $0.project == project }.count
    }

    var todayCount: Int {
        let cal = Calendar.current
        return sessions.filter { cal.isDateInToday($0.timestamp) }.count
    }

    var thisWeekCount: Int {
        let cal = Calendar.current
        let now = Date()
        return sessions.filter { cal.isDate($0.timestamp, equalTo: now, toGranularity: .weekOfYear) }.count
    }

    var largeSessionCount: Int {
        sessions.filter { $0.totalTokens > 100_000 }.count
    }

    var groupedByDate: [(date: String, sessions: [Session])] {
        let grouped = Dictionary(grouping: filteredSessions, by: \.dateString)
        return grouped.sorted { $0.key > $1.key }
            .map { (date: $0.key, sessions: $0.value.sorted { $0.timestamp > $1.timestamp }) }
    }

    var totalSize: Int { filteredSessions.reduce(0) { $0 + $1.sizeBytes } }
    var totalMessages: Int { filteredSessions.reduce(0) { $0 + $1.userMsgCount } }

    init() {
        scan()
    }

    func scan() {
        isLoading = true
        let root = projectsRoot
        let days = selectedDays
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()

        Task.detached(priority: .userInitiated) {
            var allFiles: [(path: String, sessionDir: String)] = []
            let fm = FileManager.default

            // Auto-discover all subdirectories under ~/.claude/projects/
            guard let subdirs = try? fm.contentsOfDirectory(atPath: root) else {
                await MainActor.run { self.isLoading = false }
                return
            }

            for subdir in subdirs {
                let dirPath = (root as NSString).appendingPathComponent(subdir)
                var isDir: ObjCBool = false
                guard fm.fileExists(atPath: dirPath, isDirectory: &isDir), isDir.boolValue else { continue }

                guard let entries = try? fm.contentsOfDirectory(atPath: dirPath) else { continue }
                for entry in entries where entry.hasSuffix(".jsonl") {
                    let fullPath = (dirPath as NSString).appendingPathComponent(entry)
                    // Quick mtime filter
                    if let attrs = try? fm.attributesOfItem(atPath: fullPath),
                       let mtime = attrs[.modificationDate] as? Date,
                       days > 0 && mtime < cutoff {
                        continue
                    }
                    allFiles.append((path: fullPath, sessionDir: subdir))
                }
            }

            let parsed = allFiles.compactMap { parseSession(at: $0.path, sessionDir: $0.sessionDir) }
                .filter { days == 0 || $0.timestamp >= cutoff }
                .sorted { $0.timestamp > $1.timestamp }

            await MainActor.run {
                self.sessions = parsed
                self.isLoading = false
            }
        }
    }

    func scanAll() {
        selectedDays = 0
        scan()
    }
}
