import SwiftUI

// MARK: - Sidebar selection model

enum SidebarItem: Hashable {
    case all
    case today
    case thisWeek
    case largeSessions
    case project(String)
}

// MARK: - Quick Open notification

extension Notification.Name {
    static let quickOpen = Notification.Name("quickOpen")
}

// MARK: - Root: 3-column layout (NNW-style)

struct ContentView: View {
    @EnvironmentObject var store: SessionStore
    @State private var sidebarSelection: SidebarItem? = .all
    @State private var selectedSession: Session?
    @State private var showQuickOpen = false

    var body: some View {
        NavigationSplitView {
            FeedSidebar(selection: $sidebarSelection)
        } content: {
            TimelineList(selectedSession: $selectedSession)
        } detail: {
            if let session = selectedSession {
                ArticleDetail(session: session)
            } else {
                ContentUnavailableView {
                    Label("Нет выбранной сессии", systemImage: "bubble.left.and.text.bubble.right")
                } description: {
                    Text("Выбери сессию из списка")
                }
            }
        }
        .navigationSplitViewColumnWidth(min: 200, ideal: 220, max: 280)
        .onChange(of: sidebarSelection) { _, newValue in
            store.selectedCollection = newValue ?? .all
            selectedSession = nil
        }
        .onReceive(NotificationCenter.default.publisher(for: .quickOpen)) { _ in
            showQuickOpen.toggle()
        }
        .sheet(isPresented: $showQuickOpen) {
            QuickOpenSheet(selectedSession: $selectedSession, isPresented: $showQuickOpen)
                .environmentObject(store)
        }
        .toolbar {
            ToolbarItemGroup(placement: .automatic) {
                HStack(spacing: 4) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.tertiary)
                        .font(.system(size: 10))
                    TextField("Поиск...", text: $store.searchText)
                        .textFieldStyle(.plain)
                        .font(.system(size: 12))
                        .frame(width: 140)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.quaternary.opacity(0.5))
                .clipShape(RoundedRectangle(cornerRadius: 6))

                Picker("Период", selection: $store.selectedDays) {
                    Text("1д").tag(1)
                    Text("7д").tag(7)
                    Text("30д").tag(30)
                    Text("Все").tag(0)
                }
                .pickerStyle(.segmented)
                .frame(width: 170)
                .help("Период: 1 день, неделя, месяц или все")
                .onChange(of: store.selectedDays) { _, _ in
                    store.scan()
                }

                Button {
                    store.scan()
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .help("Обновить (⌘R)")
            }
        }
    }
}

// MARK: - Column 1: Feed Sidebar (NNW SidebarViewController style)

struct FeedSidebar: View {
    @EnvironmentObject var store: SessionStore
    @Binding var selection: SidebarItem?

    var body: some View {
        VStack(spacing: 0) {
            List(selection: $selection) {
                // Smart collections
                Section("Фильтры") {
                    Label {
                        Text("Все сессии")
                    } icon: {
                        Image(systemName: "tray.full.fill")
                            .foregroundStyle(Color.accentColor)
                    }
                    .badge(store.sessions.count)
                    .tag(SidebarItem.all)

                    Label {
                        Text("Сегодня")
                    } icon: {
                        Image(systemName: "sun.max.fill")
                            .foregroundStyle(.orange)
                    }
                    .badge(store.todayCount)
                    .tag(SidebarItem.today)

                    Label {
                        Text("Эта неделя")
                    } icon: {
                        Image(systemName: "calendar")
                            .foregroundStyle(.purple)
                    }
                    .badge(store.thisWeekCount)
                    .tag(SidebarItem.thisWeek)

                    Label {
                        Text("Большие >100K")
                    } icon: {
                        Image(systemName: "scalemass.fill")
                            .foregroundStyle(.red)
                    }
                    .badge(store.largeSessionCount)
                    .tag(SidebarItem.largeSessions)
                }

                // Project feeds
                Section("Проекты") {
                    ForEach(store.projects, id: \.self) { project in
                        Label {
                            Text(project)
                        } icon: {
                            Image(systemName: projectIcon(project))
                                .foregroundStyle(projectColor(project))
                                .font(.system(size: project == "Chat" ? 11 : 9))
                        }
                        .badge(store.sessionCount(for: project))
                        .tag(SidebarItem.project(project))
                    }
                }
            }
            .listStyle(.sidebar)

            // Activity heatmap at bottom
            ActivityHeatmap()
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
        }
        .navigationTitle("Claude Sessions")
    }
}

// MARK: - Column 2: Timeline

struct TimelineList: View {
    @EnvironmentObject var store: SessionStore
    @Binding var selectedSession: Session?

    var body: some View {
        List(selection: $selectedSession) {
            ForEach(store.groupedByDate, id: \.date) { group in
                Section {
                    ForEach(group.sessions) { session in
                        TimelineCell(session: session)
                            .tag(session)
                    }
                } header: {
                    Text(formatDateHeader(group.date))
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .textCase(nil)
                }
            }
        }
        .listStyle(.inset)
        .frame(minWidth: 280, idealWidth: 340)
        .overlay(alignment: .bottom) {
            HStack {
                Text("\(store.filteredSessions.count) сессий")
                Spacer()
                Text(humanSize(store.totalSize))
            }
            .font(.system(size: 10))
            .foregroundStyle(.tertiary)
            .padding(.horizontal, 12)
            .padding(.vertical, 5)
            .background(.bar)
        }
    }
}

// MARK: - Timeline Cell

struct TimelineCell: View {
    let session: Session

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(session.title)
                .font(.system(size: 13, weight: .semibold))
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)

            if !session.preview.isEmpty {
                Text(session.preview)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            HStack {
                Text(session.project)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(projectColor(session.project))

                if session.estimatedCostUSD >= 0.01 {
                    Text("· \(session.costString)")
                        .font(.system(size: 10))
                        .foregroundStyle(.green)
                } else {
                    Text("· \(session.sizeString)")
                        .font(.system(size: 10))
                        .foregroundStyle(.quaternary)
                }

                Spacer()

                Text(session.timeString)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Column 3: Article Detail

struct ArticleDetail: View {
    let session: Session
    @State private var copied = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Article header
                VStack(alignment: .leading, spacing: 6) {
                    Text(session.title)
                        .font(.title)
                        .fontWeight(.bold)
                        .lineLimit(3)
                        .textSelection(.enabled)

                    HStack(spacing: 6) {
                        Image(systemName: "circle.fill")
                            .font(.system(size: 8))
                            .foregroundStyle(projectColor(session.project))
                        Text(session.project)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(projectColor(session.project))

                        Text("·")
                            .foregroundStyle(.quaternary)

                        Text(formatDetailDate(session.timestamp) + ", " + session.timeString)
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)

                        if !session.gitBranch.isEmpty {
                            Text("·")
                                .foregroundStyle(.quaternary)
                            Label(session.gitBranch, systemImage: "arrow.triangle.branch")
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 16)

                Divider()

                // Stat Cards — Row 1: cost, tokens, duration, model
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 4), spacing: 10) {
                    StatCard(icon: "dollarsign.circle.fill", color: .green,
                             value: session.costString, label: "Стоимость")
                    StatCard(icon: "number.circle.fill", color: .blue,
                             value: session.tokenString, label: "Токены",
                             tooltip: "In: \(session.inputTokens), Out: \(session.outputTokens), Cache Read: \(session.cacheReadTokens), Cache Write: \(session.cacheCreationTokens)")
                    StatCard(icon: "clock.fill", color: .orange,
                             value: session.durationString, label: "Время")
                    StatCard(icon: "cpu.fill", color: .purple,
                             value: session.shortModelName, label: "Модель")
                }
                .padding(.horizontal, 24)
                .padding(.top, 12)

                // Stat Cards — Row 2: messages, size, folder
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 4), spacing: 10) {
                    StatCard(icon: "person.fill", color: .cyan,
                             value: "\(session.userMsgCount)", label: "Мои")
                    StatCard(icon: "sparkle", color: .indigo,
                             value: "\(session.assistantMsgCount)", label: "Claude")
                    StatCard(icon: "doc.fill", color: .gray,
                             value: session.sizeString, label: "Размер")
                    StatCard(icon: "folder.fill", color: .brown,
                             value: shortPath(session.cwd), label: "Папка")
                }
                .padding(.horizontal, 24)
                .padding(.top, 4)
                .padding(.bottom, 12)

                // Tool visualization
                if !session.toolCounts.isEmpty {
                    Divider()
                    ToolGrid(tools: session.topTools)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                }

                Divider()

                // Article body — session summary
                VStack(alignment: .leading, spacing: 12) {
                    if !session.summary.isEmpty && session.summary != "—" {
                        Text(session.summary)
                            .font(.system(size: 14))
                            .lineSpacing(5)
                            .foregroundStyle(.primary.opacity(0.85))
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 20)

                Divider()

                // Resume command
                HStack(spacing: 8) {
                    Text(session.resumeCommand)
                        .font(.system(size: 12, design: .monospaced))
                        .textSelection(.enabled)
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.primary.opacity(0.03))
                        .clipShape(RoundedRectangle(cornerRadius: 6))

                    Button {
                        copyToClipboard(session.resumeCommand)
                        copied = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { copied = false }
                    } label: {
                        Image(systemName: copied ? "checkmark" : "doc.on.doc")
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .help("Скопировать команду")
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 16)

                Spacer()
            }
        }
        .background(Color(nsColor: .controlBackgroundColor))
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    copyToClipboard(session.resumeCommand)
                    copied = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) { copied = false }
                } label: {
                    Label(copied ? "Скопировано" : "Resume",
                          systemImage: copied ? "checkmark" : "play.fill")
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.regular)
            }
        }
    }
}

// MARK: - Stat Card

struct StatCard: View {
    let icon: String
    let color: Color
    let value: String
    let label: String
    var tooltip: String? = nil

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(color)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 1) {
                Text(value)
                    .font(.system(size: 12, weight: .semibold))
                    .lineLimit(1)
                    .truncationMode(.middle)
                Text(label)
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .help(tooltip ?? "")
    }
}

// MARK: - Tool Grid (Step 4)

struct ToolGrid: View {
    let tools: [(name: String, count: Int)]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Инструменты")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.secondary)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 110), spacing: 6)], spacing: 6) {
                ForEach(tools, id: \.name) { tool in
                    ToolBadge(name: tool.name, count: tool.count)
                }
            }
        }
    }
}

struct ToolBadge: View {
    let name: String
    let count: Int

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: toolIcon(name))
                .font(.system(size: 10))
                .foregroundStyle(toolColor(name))
            Text(cleanToolName(name))
                .font(.system(size: 11))
                .lineLimit(1)
            if count > 1 {
                Text("(\(count))")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(toolColor(name).opacity(0.08))
        .clipShape(Capsule())
    }
}

private func toolIcon(_ name: String) -> String {
    let n = name.lowercased()
    if n == "read" { return "doc.text" }
    if n == "write" { return "square.and.pencil" }
    if n == "edit" { return "pencil.line" }
    if n == "bash" { return "terminal" }
    if n == "grep" { return "magnifyingglass" }
    if n == "glob" { return "folder.badge.questionmark" }
    if n == "websearch" || n == "webfetch" { return "globe" }
    if n == "task" || n == "taskcreate" || n == "taskupdate" || n == "tasklist" || n == "taskoutput" || n == "taskstop" { return "checklist" }
    if n == "skill" { return "wand.and.stars" }
    if n == "todowrite" { return "list.bullet" }
    if n == "askuserquestion" { return "questionmark.bubble" }
    if n == "enterplanmode" || n == "exitplanmode" { return "map" }
    if n.hasPrefix("mcp__") { return "globe" }
    return "wrench"
}

private func toolColor(_ name: String) -> Color {
    let n = name.lowercased()
    if n == "read" || n == "write" || n == "edit" || n == "glob" { return .blue }
    if n == "grep" || n == "websearch" || n == "webfetch" { return .purple }
    if n == "bash" { return .orange }
    if n.hasPrefix("mcp__") { return .teal }
    if n.hasPrefix("task") { return .indigo }
    return .gray
}

private func cleanToolName(_ name: String) -> String {
    // Strip "mcp__server__" prefix for display
    if name.hasPrefix("mcp__") {
        let parts = name.split(separator: "__")
        if parts.count >= 3 {
            return String(parts.last!)
        }
        return String(name.dropFirst(5))
    }
    return name
}

// MARK: - Quick Open Sheet (Step 5)

struct QuickOpenSheet: View {
    @EnvironmentObject var store: SessionStore
    @Binding var selectedSession: Session?
    @Binding var isPresented: Bool
    @State private var query = ""
    @State private var highlightedIndex = 0

    private var results: [Session] {
        if query.isEmpty { return Array(store.sessions.prefix(20)) }
        return store.sessions.filter { session in
            session.title.localizedCaseInsensitiveContains(query) ||
            session.project.localizedCaseInsensitiveContains(query) ||
            session.summary.localizedCaseInsensitiveContains(query)
        }
        .prefix(20)
        .map { $0 }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Search field
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Поиск сессий...", text: $query)
                    .textFieldStyle(.plain)
                    .font(.system(size: 16))
                    .onSubmit { selectCurrent() }

                if !query.isEmpty {
                    Button {
                        query = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.tertiary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(12)

            Divider()

            // Results list
            if results.isEmpty {
                ContentUnavailableView("Ничего не найдено", systemImage: "magnifyingglass")
                    .frame(maxHeight: .infinity)
            } else {
                ScrollViewReader { proxy in
                    List(Array(results.enumerated()), id: \.element.id) { index, session in
                        QuickOpenRow(session: session, isHighlighted: index == highlightedIndex)
                            .id(index)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedSession = session
                                isPresented = false
                            }
                    }
                    .listStyle(.plain)
                    .onChange(of: highlightedIndex) { _, newValue in
                        proxy.scrollTo(newValue)
                    }
                }
            }
        }
        .frame(width: 500, height: 400)
        .background(.regularMaterial)
        .onExitCommand { isPresented = false }
        .onChange(of: query) { _, _ in highlightedIndex = 0 }
        .onKeyPress(.upArrow) {
            if highlightedIndex > 0 { highlightedIndex -= 1 }
            return .handled
        }
        .onKeyPress(.downArrow) {
            if highlightedIndex < results.count - 1 { highlightedIndex += 1 }
            return .handled
        }
    }

    private func selectCurrent() {
        guard highlightedIndex < results.count else { return }
        selectedSession = results[highlightedIndex]
        isPresented = false
    }
}

struct QuickOpenRow: View {
    let session: Session
    let isHighlighted: Bool

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(session.title)
                    .font(.system(size: 13, weight: .medium))
                    .lineLimit(1)

                HStack(spacing: 6) {
                    Text(session.project)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(projectColor(session.project))

                    if session.estimatedCostUSD >= 0.01 {
                        Text(session.costString)
                            .font(.system(size: 10))
                            .foregroundStyle(.green)
                    }
                }
            }

            Spacer()

            Text(formatDetailDate(session.timestamp))
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
        .listRowBackground(isHighlighted ? Color.accentColor.opacity(0.15) : Color.clear)
    }
}

// MARK: - Helpers

func projectIcon(_ project: String) -> String {
    switch project {
    case "Chat":    return "bubble.left.fill"
    case "skills":  return "wand.and.stars"
    case "rules":   return "list.bullet.rectangle"
    case "memory":  return "brain"
    case ".claude": return "gearshape.fill"
    case "Home":    return "house.fill"
    default:        return "circle.fill"
    }
}

func projectColor(_ project: String) -> Color {
    let palette: [Color] = [
        .blue, .green, .orange, .purple, .red, .pink,
        .teal, .indigo, .cyan, .brown, .mint, .yellow
    ]
    let hash = project.utf8.reduce(0) { ($0 &* 31) &+ Int($1) }
    return palette[abs(hash) % palette.count]
}

func humanSize(_ bytes: Int) -> String {
    if bytes < 1024 { return "\(bytes)B" }
    else if bytes < 1024 * 1024 { return "\(bytes / 1024)K" }
    else { return String(format: "%.1fM", Double(bytes) / (1024 * 1024)) }
}

func copyToClipboard(_ text: String) {
    let pb = NSPasteboard.general
    pb.clearContents()
    pb.setString(text, forType: .string)
}

func formatDateHeader(_ dateStr: String) -> String {
    let df = DateFormatter()
    df.dateFormat = "yyyy-MM-dd"
    guard let date = df.date(from: dateStr) else { return dateStr }

    let cal = Calendar.current
    if cal.isDateInToday(date) { return "Сегодня" }
    if cal.isDateInYesterday(date) { return "Вчера" }

    df.dateFormat = "EEEE, d MMMM"
    df.locale = Locale(identifier: "ru_RU")
    return df.string(from: date)
}

func formatDetailDate(_ date: Date) -> String {
    let df = DateFormatter()
    df.dateFormat = "d MMMM yyyy"
    df.locale = Locale(identifier: "ru_RU")
    return df.string(from: date)
}

func shortPath(_ path: String) -> String {
    let home = NSHomeDirectory()
    if path.hasPrefix(home) {
        return "~" + path.dropFirst(home.count)
    }
    return path
}
