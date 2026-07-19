import WidgetKit
import SwiftUI

/// 월간 캘린더 — 홈 대형. 달력 그리드(이벤트 도트) + 오늘 일정 목록.
struct MonthCalendarWidget: Widget {
    let kind = "MonthCalendarWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: JdayTimelineProvider()) { entry in
            MonthCalendarWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("월간 캘린더")
        .description("이번 달 일정과 오늘 일정을 한눈에 봐요.")
        .supportedFamilies([.systemLarge])
    }
}

struct MonthCalendarWidgetView: View {
    let entry: JdayTimelineEntry

    private var calendar: Calendar {
        var calendar = Calendar.current
        // 앱 설정(주 시작 요일)과 동일하게 표시
        calendar.firstWeekday = AppGroup.defaults.bool(forKey: "weekStartsOnMonday") ? 2 : 1
        return calendar
    }

    /// 달력 그리드용 날짜 배열 — 앞쪽 빈 칸은 nil.
    private var gridDays: [Int?] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: entry.date),
              let dayRange = calendar.range(of: .day, in: .month, for: entry.date) else { return [] }
        let firstWeekday = calendar.component(.weekday, from: monthInterval.start)
        let leadingBlanks = (firstWeekday - calendar.firstWeekday + 7) % 7
        return Array(repeating: nil, count: leadingBlanks) + dayRange.map { $0 }
    }

    private var weekdaySymbols: [String] {
        let symbols = calendar.veryShortWeekdaySymbols
        let start = calendar.firstWeekday - 1
        return Array(symbols[start...] + symbols[..<start])
    }

    private var today: Int {
        calendar.component(.day, from: entry.date)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(entry.date.monthLabel)
                .font(.headline)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 2), count: 7), spacing: 3) {
                ForEach(Array(weekdaySymbols.enumerated()), id: \.offset) { _, symbol in
                    Text(symbol)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                ForEach(Array(gridDays.enumerated()), id: \.offset) { _, day in
                    if let day {
                        VStack(spacing: 1) {
                            Text("\(day)")
                                .font(.caption2)
                                .fontWeight(day == today ? .bold : .regular)
                                .foregroundStyle(day == today ? Color.white : Color.primary)
                                .frame(width: 18, height: 18)
                                .background {
                                    if day == today {
                                        Circle().fill(Color.accentColor)
                                    }
                                }
                            Circle()
                                .fill(entry.eventDays.contains(day) ? Color.accentColor : Color.clear)
                                .frame(width: 3, height: 3)
                        }
                    } else {
                        Color.clear.frame(height: 18)
                    }
                }
            }

            Divider()

            VStack(alignment: .leading, spacing: 4) {
                Text("오늘 일정")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if entry.schedules.isEmpty {
                    Text("일정 없음")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                } else {
                    ForEach(entry.schedules.prefix(3)) { schedule in
                        HStack(spacing: 6) {
                            Text(schedule.startTime.hourMinuteLabel)
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(.secondary)
                            Text(schedule.title)
                                .font(.caption)
                                .lineLimit(1)
                        }
                        .opacity(schedule.endTime < entry.date ? 0.4 : 1)
                    }
                }
            }
            Spacer(minLength: 0)
        }
        .accessibilityLabel(Text("월간 캘린더"))
    }
}

#Preview(as: .systemLarge) {
    MonthCalendarWidget()
} timeline: {
    JdayTimelineEntry.preview
}
