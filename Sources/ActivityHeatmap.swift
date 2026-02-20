import SwiftUI
import Charts

// MARK: - Stats Cache models

struct DailyActivity: Codable {
    let date: String
    let messageCount: Int
    let sessionCount: Int
    let toolCallCount: Int
}

struct StatsCache: Codable {
    let dailyActivity: [DailyActivity]?
    let totalSessions: Int?
    let totalMessages: Int?
}

// MARK: - Heatmap data

struct HeatmapCell: Identifiable {
    let id: String
    let weekIndex: Int   // 0 = oldest week
    let weekday: Int     // 1=Mon ... 7=Sun
    let count: Int
    let date: Date
}

// MARK: - Activity Heatmap View

struct ActivityHeatmap: View {
    @State private var cells: [HeatmapCell] = []
    @State private var maxCount: Int = 1

    private let weekCount = 12
    private let statsCachePath = NSString(string: "~/.claude/stats-cache.json").expandingTildeInPath

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Activity")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.secondary)

            if cells.isEmpty {
                Text("No data")
                    .font(.system(size: 9))
                    .foregroundStyle(.tertiary)
                    .frame(height: 70)
            } else {
                HStack(alignment: .top, spacing: 2) {
                    // Weekday labels
                    VStack(alignment: .trailing, spacing: 0) {
                        ForEach(1...7, id: \.self) { day in
                            if day == 1 || day == 3 || day == 5 {
                                Text(weekdayLabel(day))
                                    .font(.system(size: 8))
                                    .foregroundStyle(.tertiary)
                                    .frame(height: 10)
                            } else {
                                Spacer().frame(height: 10)
                            }
                        }
                    }
                    .frame(width: 16)

                    // Grid
                    Chart(cells) { cell in
                        RectangleMark(
                            xStart: .value("Week", cell.weekIndex),
                            xEnd: .value("WeekEnd", cell.weekIndex + 1),
                            yStart: .value("Day", cell.weekday - 1),
                            yEnd: .value("DayEnd", cell.weekday)
                        )
                        .foregroundStyle(cellColor(cell.count))
                        .cornerRadius(1.5)
                    }
                    .chartXAxis(.hidden)
                    .chartYAxis(.hidden)
                    .chartXScale(domain: 0...weekCount)
                    .chartYScale(domain: 0...7)
                    .frame(height: 70)
                }
            }
        }
        .onAppear { loadData() }
    }

    private func cellColor(_ count: Int) -> Color {
        if count == 0 { return Color.primary.opacity(0.04) }
        let ratio = Double(count) / Double(max(maxCount, 1))
        if ratio < 0.25 { return Color.green.opacity(0.3) }
        if ratio < 0.50 { return Color.green.opacity(0.5) }
        if ratio < 0.75 { return Color.green.opacity(0.7) }
        return Color.green.opacity(0.9)
    }

    private func weekdayLabel(_ day: Int) -> String {
        switch day {
        case 1: return "Mo"
        case 3: return "We"
        case 5: return "Fr"
        default: return ""
        }
    }

    private func loadData() {
        guard let data = FileManager.default.contents(atPath: statsCachePath),
              let cache = try? JSONDecoder().decode(StatsCache.self, from: data),
              let daily = cache.dailyActivity else { return }

        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())

        // Build date → count map
        var dateMap: [Date: Int] = [:]
        for entry in daily {
            if let date = df.date(from: entry.date) {
                dateMap[cal.startOfDay(for: date)] = entry.sessionCount
            }
        }

        // Generate grid: last 12 weeks
        guard let startDate = cal.date(byAdding: .weekOfYear, value: -weekCount, to: today) else { return }
        // Align to Monday
        let startWeekday = cal.component(.weekday, from: startDate)
        let mondayOffset = startWeekday == 1 ? -6 : 2 - startWeekday  // ISO: Mon=1
        guard let gridStart = cal.date(byAdding: .day, value: mondayOffset, to: startDate) else { return }

        var result: [HeatmapCell] = []
        var localMax = 0
        var current = gridStart

        while current <= today {
            let daysSinceStart = cal.dateComponents([.day], from: gridStart, to: current).day ?? 0
            let weekIndex = daysSinceStart / 7
            let isoWeekday = cal.component(.weekday, from: current)
            // Convert from Calendar weekday (Sun=1..Sat=7) to ISO (Mon=1..Sun=7)
            let day = isoWeekday == 1 ? 7 : isoWeekday - 1

            let count = dateMap[current] ?? 0
            if count > localMax { localMax = count }

            result.append(HeatmapCell(
                id: df.string(from: current),
                weekIndex: weekIndex,
                weekday: day,
                count: count,
                date: current
            ))

            current = cal.date(byAdding: .day, value: 1, to: current) ?? current.addingTimeInterval(86400)
        }

        cells = result
        maxCount = max(localMax, 1)
    }
}
